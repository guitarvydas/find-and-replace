package zd

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"

// Message passed to a leaf component.
//
// `port` refers to the name of the incoming or outgoing port of this component.
// `datum` is the data attached to this message.
Message :: struct {
    port:  Port_Type,
    datum: Datum_Type,
    from: ^Eh,
    cause: ^Message, // message that caused this message
}

Port_Type :: string
Datum_Type :: any


clone_port :: proc (s : string) -> Port_Type {
    p : Port_Type = strings.clone (s) // clone to heap
    return p
}


// Utility for making a `Message`. Used to safely "seed" messages
// entering the very top of a network.

make_message :: proc(port: Port_Type, data: Datum_Type, who : ^Eh, cause: ^Message) -> ^Message {
    p := clone_port (port)
    data_ptr := new_clone(data)
    data_id := typeid_of (type_of (data))

    m := new (Message)
    m.port  = p
    m.datum = any{data_ptr, data_id}
    m.from = who
    cloned_cause := message_clone (cause)
    m.cause = cloned_cause

    return m
}

// Clones a message. Primarily used internally for "fanning out" a message to multiple destinations.
message_clone :: proc(message: ^Message) -> ^Message {
    m := new (Message)
    m.port = clone_port (message.port)
    m.datum = clone_datum(message.datum)
    m.from = message.from
    m.cause = message.cause
    return m
}

// Clones the datum portion of the message.
clone_datum :: proc(datum: any) -> any {
    datum_ti := type_info_of(datum.id)

    new_datum_ptr := mem.alloc(datum_ti.size, datum_ti.align) or_else panic("data_ptr alloc")
    mem.copy_non_overlapping(new_datum_ptr, datum.data, datum_ti.size)

    return any{new_datum_ptr, datum.id},
}

// Frees a message.
destroy_message :: proc(msg: ^Message) {
    destroy_port (msg)
    destroy_datum (msg)
}

destroy_datum :: proc (msg: ^Message) {
    //log.errorf("TODO: destroy datum %v, but don't know how yet\n", typeid_of (type_of (d)))
}

destroy_port :: proc (msg: ^Message) {
    // TODO: implement GC or refcounting and avoid duplication of data when cloning
    // TODO: don't know how to destroy a string
}

