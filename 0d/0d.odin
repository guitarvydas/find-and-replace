package zd

import "core:container/queue"
import "core:fmt"
import "core:mem"
import "core:runtime"
import "core:strings"
import "core:intrinsics"
import "core:log"

Bang :: struct {}


// Data for an asyncronous component - effectively, a function with input
// and output queues of messages.
//
// Components can either be a user-supplied function ("leaf"), or a "container"
// that routes messages to child components according to a list of connections
// that serve as a message routing table.
//
// Child components themselves can be leaves or other containers.
//
// `handler` invokes the code that is attached to this component.
//
// `instance_data` is a pointer to instance data that the `leaf_handler`
// function may want whenever it is invoked again.
//
Eh_States :: enum { idle, active }
Eh :: struct {
    name:         string,
    input:        FIFO,
    output:       FIFO,
    owner:        ^Eh,
    children:     []^Eh,
    connections:  []Connector,
    handler:      #type proc(eh: ^Eh, message: ^Message),
    instance_data: any,
    state:       Eh_States,
    kind: enum { container, leaf, }, // for debug
}


// Creates a component that acts as a container. It is the same as a `Eh` instance
// whose handler function is `container_handler`.
make_container :: proc(name: string, owner : ^Eh) -> ^Eh {
    eh := new(Eh)
    eh.name = name
    eh.owner = owner
    eh.handler = container_handler
    eh.state = .idle
    eh.kind = .container
    return eh
}

// Creates a new leaf component out of a handler function, and optionally a user
// data parameter that will be passed back to your handler when it is run.

make_leaf_with_no_instance_data :: proc(name: string, owner : ^Eh, handler: proc(^Eh, ^Message)) -> ^Eh {
    return make_leaf (name, owner, nil, handler)
}

// Creates a new leaf component out of a handler function, and a data parameter
// that will be passed back to your handler when called.
make_leaf :: proc(name: string, owner: ^Eh, instance_data: any, handler: proc(^Eh, ^Message)) -> ^Eh {
    eh := new(Eh)
    eh.name = name
    eh.handler = handler
    // want eh.instance_data to be exact duplicate of instance_data
    fmt.printf ("make_leaf instance_data in %v %v\n", (transmute(runtime.Raw_Any)eh.instance_data).id, transmute([2]rawptr)instance_data )
    rp := (transmute(runtime.Raw_Any)instance_data).data
    id := (transmute(runtime.Raw_Any)instance_data).id
    eh.instance_data = transmute(type_of(instance_data))(runtime.Raw_Any{rp,id})
    fmt.printf ("make_leaf eh.instance_data in %v %v\n", (transmute(runtime.Raw_Any)eh.instance_data).id, transmute([2]rawptr)eh.instance_data )
//    (transmute(runtime.Raw_Any)eh.instance_data).id = (transmute(runtime.Raw_Any)instance_data).id

    eh.state = .idle
    eh.kind = .leaf
    return eh
}

// Sends a message on the given `port` with `data`, placing it on the output
// of the given component.
send :: proc(eh: ^Eh, port: string, datum: ^Datum, cause : ^Message) {
    sendf("SEND 0x%p %s(%s)[%v]", eh, eh.name, port, cause^)
    msg := make_message(port, datum, eh, cause)
    fifo_push(&eh.output, msg)
}

send_string :: proc(eh: ^Eh, port: string, s : string, cause : ^Message) {
    sendf("SEND 0x%p %s(%s)[%v]", eh, eh.name, port, cause.port)
    datum := new_datum_string (s)
    msg := make_message(port, datum, eh, cause)
    fifo_push(&eh.output, msg)
}

forward :: proc(eh: ^Eh, port: string, msg: ^Message) {
    sendf("FORWARD 0x%p %s->%v", eh, eh.name, msg.port)
    fmsg := make_message(port, msg.datum, eh, msg)
    fifo_push(&eh.output, fmsg)
}

// Returns a list of all output messages on a container.
// For testing / debugging purposes.
output_list :: proc(eh: ^Eh, allocator := context.allocator) -> []^Message {
    list := make([]^Message, eh.output.len)

    iter := make_fifo_iterator(&eh.output)
    for msg, i in fifo_iterate(&iter) {
        list[i] = msg
    }

    return list
}

// The default handler for container components.
container_handler :: proc(eh: ^Eh, message: ^Message) {
    route(eh, nil, message)
    for any_child_ready(eh) {
        step_children(eh, message)
    }
}

// Frees the given container and associated data.
destroy_container :: proc(eh: ^Eh) {
    drain_fifo :: proc(fifo: ^FIFO) {
        for fifo.len > 0 {
            msg, _ := fifo_pop(fifo)
            destroy_message(msg)
        }
    }
    drain_fifo(&eh.input)
    drain_fifo(&eh.output)
    free(eh)
}

// Wrapper for corelib `queue.Queue` with FIFO semantics.
FIFO       :: queue.Queue(^Message)
fifo_push  :: queue.push_back
fifo_pop   :: queue.pop_front_safe

fifo_is_empty :: proc(fifo: FIFO) -> bool {
    return fifo.len == 0
}

FIFO_Iterator :: struct {
    q:   ^FIFO,
    idx: uint,
}

make_fifo_iterator :: proc(q: ^FIFO) -> FIFO_Iterator {
    return {q, 0}
}

fifo_iterate :: proc(iter: ^FIFO_Iterator) -> (item: ^Message, idx: uint, ok: bool) {
    if iter.q.len == 0 {
        ok = false
        return
    }

    i := (uint(iter.idx)+iter.q.offset) % len(iter.q.data)
    if iter.idx < iter.q.len {
        ok = true
        idx = iter.idx
        iter.idx += 1
        #no_bounds_check item = iter.q.data[i]
    }
    return
}

// Routing connection for a container component. The `direction` field has
// no affect on the default message routing system - it is there for debugging
// purposes, or for reading by other tools.
Connector :: struct {
    direction: Direction,
    sender:    Sender,
    receiver:  Receiver,
}

Direction :: enum {
    Down,
    Across,
    Up,
    Through,
}

// `Sender` is used to "pattern match" which `Receiver` a message should go to,
// based on component ID (pointer) and port name.
Sender :: struct {
    name: string,
    component: ^Eh,
    port:      Port_Type,
}

// `Receiver` is a handle to a destination queue, and a `port` name to assign
// to incoming messages to this queue.
Receiver :: struct {
    name: string,
    queue: ^FIFO,
    port:  Port_Type,
}

// Checks if two senders match, by pointer equality and port name matching.
sender_eq :: proc(s1, s2: Sender) -> bool {
    return s1.component == s2.component && s1.port == s2.port
}

// Delivers the given message to the receiver of this connector.
deposit :: proc(c: Connector, message: ^Message) {
    new_message := message_clone(message)
    new_message.port = c.receiver.port
    fifo_push(c.receiver.queue, new_message)
}

receivef :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	log.logf(.Debug,   fmt_str, ..args, location=location)
}

sendf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	log.logf(.Debug,   fmt_str, ..args, location=location)
}

outputf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	log.logf(.Debug,   fmt_str, ..args, location=location)
}

step_children :: proc(container: ^Eh, cause: ^Message) {
    container.state = .idle
    for child in container.children {
        msg: ^Message = make_message ("?", new_datum_bang (), container, cause)
        ok: bool

        switch {
        case child.input.len > 0:
            msg, ok = fifo_pop(&child.input)
	case child.state != .idle:
	    ok = true
	    msg = make_message (".", new_datum_bang (), container, cause)
        }

        if ok {
            receivef("HANDLE  0x%p %s/%s(%s)", child, container.name, child.name, msg.port)
            child.handler(child, msg)
            destroy_message(msg)
        }

	if child.state == .active {
	    container.state = .active
	}

        for child.output.len > 0 {
            msg, _ = fifo_pop(&child.output)
            outputf("OUTPUT 0x%p %s/%s(%s)", child, container.name, child.name, msg.port)
            route(container, child, msg)
            destroy_message(msg)
        }
    }
}

tick :: proc (eh: ^Eh, cause: ^Message) {
    if eh.state != .idle {
	tick_msg := make_message (".", new_datum_bang (), eh, cause)
	fifo_push (&eh.input, tick_msg)
    }
}

// Routes a single message to all matching destinations, according to
// the container's connection network.
route :: proc(container: ^Eh, from: ^Eh, message: ^Message) {
    was_sent := false // for checking that output went somewhere (at least during bootstrap)
    if message.port == "." {
	for child in container.children {
	    tick (child, message)
	}
	was_sent = true
    } else {
	fname := ""
	if from != nil  {
	    fname = from.name
	}
	from_sender := Sender{fname, from, message.port}
	
	for connector in container.connections {
            if sender_eq(from_sender, connector.sender) {
		deposit(connector, message)
		was_sent = true
            }
	}
    }
    fmt.assertf (was_sent, "\n\n!!! message from %v dropped on floor: %v %v [%v/%v]\n\n", from.name, message.port, message.datum, message.cause)
}

any_child_ready :: proc(container: ^Eh) -> (ready: bool) {
    for child in container.children {
        if child_is_ready(child) {
            return true
        }
    }
    return false
}

child_is_ready :: proc(eh: ^Eh) -> bool {
    return !fifo_is_empty(eh.output) || !fifo_is_empty(eh.input) || eh.state!= .idle || any_child_ready (eh)
}

any_of_my_children_ready :: proc (eh: ^Eh) -> bool {
    return any_child_ready (eh)
}

// Utility for printing an array of messages.
print_output_list :: proc(eh: ^Eh) {
    write_rune   :: strings.write_rune
    write_string :: strings.write_string

    sb: strings.Builder
    defer strings.builder_destroy(&sb)

    write_rune(&sb, '[')

    iter := make_fifo_iterator(&eh.output)
    for msg, idx in fifo_iterate(&iter) {
        if idx > 0 {
            write_string(&sb, ", ")
        }
        fmt.sbprintf(&sb, "{{%s, %v, [%v]}", msg.port, msg.datum, msg.cause)
    }
    strings.write_rune(&sb, ']')

    fmt.println(strings.to_string(sb))
}

set_active :: proc (eh: ^Eh) {
    eh.state = .active
}

set_idle :: proc (eh: ^Eh) {
    eh.state = .idle
}

// Utility for printing a specific output message.
fetch_first_output_mustbestring :: proc (eh :^Eh, port: Port_Type) -> string {
    iter := make_fifo_iterator(&eh.output)
    for msg, idx in fifo_iterate(&iter) {
	if msg.port == port {
	    return msg.datum.data.(string)
	}
    }
    return ""
}

print_specific_output :: proc(eh: ^Eh, port: string) {
    sb: strings.Builder
    defer strings.builder_destroy(&sb)

    datum := fetch_first_output_mustbestring (eh, port)
    fmt.sbprintf(&sb, "%v", datum)
    fmt.println(strings.to_string(sb))
}

