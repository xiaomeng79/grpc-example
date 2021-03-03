package srv

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"path"
	"strings"
	"syscall"

	"github.com/xiaomeng79/grpc-example/internal/middleware"
	pb "github.com/xiaomeng79/grpc-example/srv/proto/gen"
	"github.com/xiaomeng79/grpc-example/srv/proto/gen/swagger"
	"github.com/xiaomeng79/grpc-example/srv/proto/gen/swaggerui"

	assetfs "github.com/elazarl/go-bindata-assetfs"
	grpc_middleware "github.com/grpc-ecosystem/go-grpc-middleware"
	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	log "github.com/sirupsen/logrus"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"google.golang.org/protobuf/encoding/protojson"
)

func Run(port string) {
	ctx := context.Background()
	RunServer(ctx, port)
}

func RunServer(ctx context.Context, port string) {
	handler := RunServerHandle(port)
	addr := ":" + port
	server := &http.Server{Addr: addr, Handler: handler}
	go func() {
		err := server.ListenAndServe()
		if err != nil {
			log.Warnf("http error:%+v", err)
		}
	}()
	listenSignal(ctx, server)
}

func RunServerHandle(port string) http.Handler {
	httpMux := runHttpServer()
	grpcS := runGrpcServer()

	endpoint := "0.0.0.0:" + port
	log.Infof("Serving on %s", endpoint)
	gwmux := runtime.NewServeMux(runtime.WithMarshalerOption(runtime.MIMEWildcard,
		&runtime.JSONPb{MarshalOptions: protojson.MarshalOptions{
			UseEnumNumbers:  true,
			EmitUnpopulated: true,
			UseProtoNames:   true,
		}, UnmarshalOptions: protojson.UnmarshalOptions{
			DiscardUnknown: true,
		}},
	))
	dopts := []grpc.DialOption{grpc.WithInsecure()}
	_ = pb.RegisterMatchServiceHandlerFromEndpoint(context.Background(), gwmux, endpoint, dopts)
	httpMux.Handle("/", gwmux)
	return grpcHandlerFunc(grpcS, httpMux)
}

func runGrpcServer() *grpc.Server {
	opts := []grpc.ServerOption{
		grpc.UnaryInterceptor(grpc_middleware.ChainUnaryServer(
			middleware.AccessLog,
			middleware.ErrorLog,
			middleware.Recovery,
		)),
	}
	s := grpc.NewServer(opts...)
	pb.RegisterMatchServiceServer(s, &server{})
	reflection.Register(s)
	return s
}

func runHttpServer() *http.ServeMux {
	serveMux := http.NewServeMux()
	serveMux.HandleFunc("/ping", func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`pong`))
	})
	prefix := "/swagger-ui/"
	fileServer := http.FileServer(&assetfs.AssetFS{
		Asset:    swaggerui.Asset,
		AssetDir: swaggerui.AssetDir,
		Prefix:   "third_party/swagger-ui/dist",
	})

	serveMux.Handle(prefix, http.StripPrefix(prefix, fileServer))
	swaggerFileServer := http.FileServer(&assetfs.AssetFS{
		Asset:    swagger.Asset,
		AssetDir: swagger.AssetDir,
		Prefix:   "target/protoc-json",
	})
	serveMux.HandleFunc("/swagger/", func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasSuffix(r.URL.Path, "swagger.json") {
			http.NotFound(w, r)
			return
		}
		p := strings.TrimPrefix(r.URL.Path, "/swagger/")
		p = path.Join("srv/proto", p)
		r.URL.Path = p
		swaggerFileServer.ServeHTTP(w, r)
	})
	return serveMux
}

func grpcHandlerFunc(grpcServer *grpc.Server, otherHandler http.Handler) http.Handler {
	return h2c.NewHandler(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.ProtoMajor == 2 && strings.Contains(r.Header.Get("Content-Type"), "application/grpc") {
			grpcServer.ServeHTTP(w, r)
		} else {
			otherHandler.ServeHTTP(w, r)
		}
	}), &http2.Server{})
}

func listenSignal(ctx context.Context, httpSrv *http.Server) {
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)
	<-sigs
	log.Info("server is closed...")
	err := httpSrv.Shutdown(ctx)
	if err != nil {
		log.Warnf("shutdown error: %+v", err)
	}
	log.Info("http shutdown over...")
}
