package debug

import "core:runtime"

TwoQuads :: struct {
    a: rawptr,
    b: rawptr,
}

RawStr :: runtime.Raw_String

/* Raw_String :: struct { */
/* 	data: [^]byte, */
/* 	len:  int, */
/* } */
