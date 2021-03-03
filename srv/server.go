package srv

import (
	"context"
	"github.com/xiaomeng79/grpc-example/srv/conf"

	pb "github.com/xiaomeng79/grpc-example/srv/proto/gen"
	"google.golang.org/protobuf/types/known/emptypb"
)

type server struct {
	pb.UnimplementedMatchServiceServer
}

func NewServer() *server {
	return &server{}
}

func (c *server) Version(ctx context.Context, in *emptypb.Empty) (out *pb.Version, outerr error) {
	out = &pb.Version{
		Version:   conf.Version,
		GoVersion: conf.GoVersion,
		GitCommit: conf.GitCommit,
		BuiltTime: conf.BuiltTime,
	}
	return
}
