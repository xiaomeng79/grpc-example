# GRPC-EXAMPLE

## 环境依赖

1. go >=1.13

## 快速开始

1. 设置代理
```shell script
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.cn,direct
```

2. 克隆项目
```shell script
git clone https://github.com/xiaomeng79/grpc-example
```

3. 安装依赖工具和编译
```shell script
make install && make build
```

4. 启动服务
```shell script
target/bin/grpc-example
```

5. 查看接口文档(浏览器)

http://127.0.0.1:8080/swagger-ui/