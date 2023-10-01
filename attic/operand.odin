package zd

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"


make_operand :: proc {
    make_string_operand,
}

clone_operand :: proc {
    clone_string_operand,
}

reclaim_operand :: proc {
    reclaim_string_operand,
}

fetch :: proc {
    fetch_string_operand,
}

//

String_Operand :: struct {
    data : string,
    clone : #type proc (^String_Operand),
    reclaim : #type proc (^String_Operand),
}

make_string_operand :: proc (s : string) -> ^String_Operand {
    p := new (String_Operand)
    p.data = s
    p.clone = clone_string_operand
    p.reclaim = reclaim_string_operand
    return p
}


clone_string_operand :: proc (src : ^String_Operand) {
    p := new (String_Operand)
    p.data = strings.clone (src.value)
    p.clone = clone_string_operand
    p.reclaim = reclaim_string_operand
    return p
}

reclaim_string_operand :: proc (p : ^String_Operand) {
    // TODO
    // we want all messages to be persistent, during debug
    // hence, all operands to be persistent
    // this routine is only needed for Production Engineering
}

fetch_string :: proc (s : ^String_Operand) -> string {
    return s.data
}

//
    
