package errcode

import "fmt"

//go:generate stringer -type=ErrCode -linecomment

type ErrCode int

func Err(e ErrCode) error {
	return fmt.Errorf("%s", e)
}

var (
	ERR_OK = Err(OK)
)

const (
	OK ErrCode = iota // Success
)
