package srv

import (
	"net/http"
	"testing"
	"time"

	"github.com/gavv/httpexpect/v2"
)

func TestRun(t *testing.T) {
	// 配置初始化
	e := runTest(t)
	// 测试版本
	version(e)

}

// 启动服务
func runTest(t *testing.T) *httpexpect.Expect {
	// 启动服务
	port := "60000"
	go func() {
		Run(port)
	}()
	url := "http://127.0.0.1:" + port
	e := httpexpect.New(t, url)
	i := 5
	isConn := false
	for i > 0 {
		rsp, err := http.Get(url + "/version")
		if err == nil && rsp.StatusCode == http.StatusOK {
			isConn = true
			break
		}
		time.Sleep(time.Second * 1)
		i--
	}
	if !isConn {
		t.Logf("Conn fail  port:%+v", port)
	}
	return e
}

// 测试版本
func version(e *httpexpect.Expect) {
	e.GET("/version").Expect().Status(http.StatusOK).Body().Contains("version")
}
