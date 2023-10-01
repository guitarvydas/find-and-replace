package zd

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
    p.data = string.clone (src.s)
    p.clone = src.clone
    p.reclaim = src.reclaim
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
    return make_datum_bang ()
}

reclaim_datum_bang :: proc (src: ^Datum) {
}

