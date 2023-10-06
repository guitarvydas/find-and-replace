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
    datum: ^Datum,
    from: ^Eh,
    cause: ^Message, // message that caused this message
}

Port_Type :: string


clone_port :: proc (s : string) -> Port_Type {
    p : Port_Type = strings.clone (s) // clone to heap
    return p
}


// Utility for making a `Message`. Used to safely "seed" messages
// entering the very top of a network.

make_message :: proc(port: Port_Type, datum: ^Datum, who : ^Eh, cause: ^Message) -> ^Message {
    p := clone_port (port)
    m := new (Message)
    m.port  = p
    m.datum = datum.clone (datum)
    m.from = who
    m.cause = cause
    return m
}

// Clones a message. Primarily used internally for "fanning out" a message to multiple destinations.
message_clone :: proc(message: ^Message) -> ^Message {
    fmt.printf ("\nmessage_clone message=%p message contents=%v\n", message, message)
    m := new (Message)
    m.port = clone_port (message.port)
    fmt.printf ("\nmessage_clone message.datum=%p message.data/contents=%v\n",
		message.datum,
		message.datum
	       )
    m.datum = message.datum.clone (message.datum)
    m.from = message.from
    m.cause = message.cause
    return m
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

