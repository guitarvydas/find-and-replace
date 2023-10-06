package zd

import "core:strings"
import "core:mem"
import "core:runtime"
import "core:os"
import "core:fmt"

Datum :: struct {
    data: any,
    clone: #type proc (^Datum) -> ^Datum,
    reclaim: #type proc (^Datum),
}

new_datum_string :: proc (s : string) -> ^Datum {
    fmt.printf ("new_datum_string\n")
    string_in_heap := new (string)
    string_in_heap^ = strings.clone (s)
    datum_in_heap := new (Datum)
    fmt.printf ("string_in_heap type=%v\n", typeid_of (type_of (string_in_heap)))
    datum_in_heap.data = string_in_heap
    fmt.printf ("datum_in_heap.data type=%v\n", typeid_of (type_of (datum_in_heap.data)))
    datum_in_heap.clone = clone_datum_string
    datum_in_heap.reclaim = reclaim_datum_string    
    fmt.printf ("datum_in_heap.data.(string) type=%v\n", typeid_of (type_of (datum_in_heap.data.(string))))
    return datum_in_heap
}

clone_datum_string :: proc (src: ^Datum) -> ^Datum {
    fmt.printf ("clone_datum_string src.data.(string)=%s\n", src.data.(string))
    string_in_heap := new (string)
    string_in_heap^ = strings.clone (src.data.(string))
    datum_in_heap := new (Datum)
    datum_in_heap.data = string_in_heap
    datum_in_heap.clone = src.clone
    datum_in_heap.reclaim = src.reclaim
    return datum_in_heap
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
