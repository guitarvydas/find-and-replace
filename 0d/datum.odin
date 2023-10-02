package zd

import "core:strings"
import "core:mem"
import "core:os"

Datum :: struct {
    data: any,
    clone: #type proc (^Datum) -> ^Datum,
    reclaim: #type proc (^Datum),
}

new_datum_string :: proc (s : string) -> ^Datum {
    p := new (Datum)
    p.data = strings.clone (s)
    p.clone = clone_datum_string
    p.reclaim = reclaim_datum_string
    return p
}

clone_datum_string :: proc (src: ^Datum) -> ^Datum {
    p := new (Datum)
    p.data = strings.clone (src.data.(string))
    p.clone = src.clone
    p.reclaim = src.reclaim
    return p
}

reclaim_datum_string :: proc (src: ^Datum) {
    // TODO
    // Q: do we ever need to reclaim the string, or is the Biblical Flood method of GC enough?
}

new_datum_bang :: proc () -> ^Datum {
    p := new (Datum)
    p.data = true
    p.clone = clone_datum_bang
    p.reclaim = reclaim_datum_bang
    return p
}

clone_datum_bang :: proc (src: ^Datum) -> ^Datum {
    return new_datum_bang ()
}

reclaim_datum_bang :: proc (src: ^Datum) {
}


///
new_datum_bytes :: proc (b : []byte) -> ^Datum {
    p := new (Datum)
    p.data = clone_bytes (b)
    p.clone = clone_datum_bytes
    p.reclaim = reclaim_datum_bytes
    return p
}

clone_datum_bytes :: proc (src: ^Datum) -> ^Datum {
    p := new (Datum)
    p.data = clone_bytes (src.data.([]byte))
    p.clone = src.clone
    p.reclaim = src.reclaim
    return p
}

reclaim_datum_bytes :: proc (src: ^Datum) {
    // TODO
}

clone_bytes :: proc(b: any) -> any {
    b_ti := type_info_of(b.id)

    new_b_ptr := mem.alloc(b_ti.size, b_ti.align) or_else panic("data_ptr alloc")
    mem.copy_non_overlapping(new_b_ptr, b.data, b_ti.size)

    return any{new_b_ptr, b.id},
}

//
new_datum_handle :: proc (h : os.Handle) -> ^Datum {
    p := new (Datum)
    p.data = h
    p.clone = clone_handle
    p.reclaim = reclaim_handle
    return p
}

clone_handle :: proc (src: ^Datum) -> ^Datum {
    p := new (Datum)
    p.data = src.data.(os.Handle)
    p.clone = src.clone
    p.reclaim = src.reclaim
    return p
}

reclaim_handle :: proc (src: ^Datum) {
    // TODO
}
