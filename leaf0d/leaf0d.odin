package leaf0d

import "core:fmt"
import "core:runtime"
import "core:log"
import "core:strings"
import "core:slice"
import "core:os"
import "core:unicode/utf8"

import reg "../registry0d"
import "../process"
import "../syntax"
import zd "../0d"

gensym :: proc (s : string) -> string {
    @(static) counter := 0
    counter += 1
    name_with_id := fmt.aprintf("%s◦%d", s, counter)
    return name_with_id
}


stdout_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    return zd.make_leaf(name, owner, nil, stdout_proc)
}

stdout_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fmt.printf("%#v", msg.datum)
}

process_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    command_string := strings.clone(strings.trim_left(name, "$ "))
    command_string_ptr := new_clone(command_string)
    return zd.make_leaf(name, owner, command_string_ptr^, process_proc)
}

process_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    
    utf8_string :: proc(bytes: []byte) -> (s: string, ok: bool) {
        s = string(bytes)
        ok = utf8.valid_string(s)
        return
    }
    
    send_output :: proc(eh: ^zd.Eh, port: string, output: []byte, causingMsg: ^zd.Message) {
        if len(output) > 0 {
            str, ok := utf8_string(output)
            if ok {
                zd.send_string (eh, port, str, causingMsg)
            } else {
                zd.send (eh, port, zd.new_datum_bytes (output), causingMsg)
            }
        }
    }

    switch msg.port {
    case "stdin":
        handle := process.process_start(eh.instance_data.(string))
        defer process.process_destroy_handle(handle)

        // write input, wait for finish
        {
            switch value in msg.datum.data {
            case string:
                bytes := transmute([]byte)value
                os.write(handle.input, bytes)
            case []byte:
                os.write(handle.input, value)
            case zd.Bang:
                // OK, no input, just run it
	    case:
                log.errorf("%s: Shell leaf input can handle string, bytes, or bang (got: %v)", eh.name, value.id)
            }
            os.close(handle.input)
            process.process_wait(handle)
        }

        // breaks bootstrap error check, thus, removed line: zd.send_string (eh, "done", Bang{})

        // stdout handling
        {
            stdout, ok := process.process_read_handle(handle.output)
            if ok {
                send_output(eh, "stdout", stdout, msg)
            }
        }

        // stderr handling
        {
            stderr, ok := process.process_read_handle(handle.error)
            if ok {
                send_output(eh, "stderr", stderr, msg)
            }

            if len(stderr) > 0 {
                str := string(stderr)
                str = strings.trim_right_space(str)
                log.error(str)
            }
        }
    }
}

collect_process_leaves :: proc(path: string, leaves: ^[dynamic]reg.Leaf_Instantiator) {
    ref_is_container :: proc(decls: []syntax.Container_Decl, name: string) -> bool {
        for d in decls {
            if d.name == name {
                return true
            }
        }
        return false
    }

    decls, err := syntax.parse_drawio_mxgraph(path)
    assert(err == nil)
    defer delete(decls)

    // TODO(z64): while harmless, this doesn't ignore duplicate process decls yet.

    for decl in decls {
        for child in decl.children {
            if ref_is_container(decls[:], child.name) {
                continue
            }

            if strings.has_prefix(child.name, "$") {
                leaf_instantiate := reg.Leaf_Instantiator {
                    name = child.name,
                    instantiate = process_instantiate,
                }
                append(leaves, leaf_instantiate)
            }
        }
    }
}

////

Command_Instance_Data :: struct {
    buffer : string
}

command_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("command")
    instp := new (Command_Instance_Data)
    return zd.make_leaf (name_with_id, owner, instp^, command_proc)
}

command_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := eh.instance_data.(Command_Instance_Data)
    switch msg.port {
    case "command":
        inst.buffer = msg.datum.data.(string)
        received_input := msg.datum.data.(string)
        captured_output, _ := process.run_command (inst.buffer, received_input)
        zd.send_string (eh, "stdout", captured_output, msg)
	case:
        fmt.assertf (false, "!!! ERROR: command got an illegal message port %v", msg.port)
    }
}

icommand_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("icommand[%d]")
    instp := new (Command_Instance_Data)
    return zd.make_leaf (name_with_id, owner, instp^, icommand_proc)
}

icommand_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := eh.instance_data.(Command_Instance_Data)
    switch msg.port {
    case "command":
        inst.buffer = msg.datum.data.(string)
    case "stdin":
        received_input := msg.datum.data.(string)
        captured_output, _ := process.run_command (inst.buffer, received_input)
        zd.send_string (eh, "stdout", captured_output, msg)
	case:
        fmt.assertf (false, "!!! ERROR: command got an illegal message port %v", msg.port)
    }
}


TwoMessages :: struct {
    first : ^zd.Message,
    second : ^zd.Message
}


Deracer_States :: enum { idle, waitingForFirst, waitingForSecond }

Deracer_Instance_Data :: struct {
    state : Deracer_States,
    buffer : TwoMessages
}

reclaim_Buffers_from_heap :: proc (inst : ^Deracer_Instance_Data) {
    zd.destroy_message (inst.buffer.first)
    zd.destroy_message (inst.buffer.second)
}

deracer_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym ("deracer")
    inst := new (Deracer_Instance_Data) // allocate in the heap
    inst.state = .idle
    eh := zd.make_leaf (name_with_id, owner, inst^, deracer_proc)
    return eh
}

send_first_then_second :: proc (eh : ^zd.Eh, inst: ^Deracer_Instance_Data) {
    zd.forward (eh, "1", inst.buffer.first)
    zd.forward (eh, "2", inst.buffer.second)
    reclaim_Buffers_from_heap (inst)
}

deracer_proc :: proc(eh: ^zd.Eh,  msg: ^zd.Message) {
    inst := &eh.instance_data.(Deracer_Instance_Data)
    fmt.printf ("deracer inst=%v msg=%v\n", inst, msg)
    switch (inst.state) {
    case .idle:
        switch msg.port {
        case "1":
            inst.buffer.first = msg
            inst.state = .waitingForSecond
        case "2":
            inst.buffer.second = msg
            inst.state = .waitingForFirst
        case:
            fmt.assertf (false, "bad msg.port A for deracer %v\n", msg.port)
        }
    case .waitingForFirst:
        switch msg.port {
        case "1":
            inst.buffer.first = msg
            send_first_then_second (eh, inst)
            inst.state = .idle
        case:
            fmt.assertf (false, "bad msg.port B for deracer %v\n", msg.port)
        }
    case .waitingForSecond:
        switch msg.port {
        case "2":
            inst.buffer.second = msg
            send_first_then_second (eh, inst)
            inst.state = .idle
        case:
            fmt.assertf (false, "bad msg.port C for deracer %v\n", msg.port)
        }
    case:
        fmt.assertf (false, "bad state for deracer %v\n", eh.state)
    }
}

/////////

probe_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("?")
    return zd.make_leaf (name_with_id, owner, nil, probe_proc)
}

probe_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fmt.eprintln (eh.name, msg.datum)
}

trash_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("trash")
    return zd.make_leaf (name_with_id, owner, nil, trash_proc)
}

trash_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    // to appease dumped-on-floor checker
}

nulltester_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("nulltester")
    return zd.make_leaf (name_with_id, owner, nil, nulltester_proc)
}

nulltester_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    if "" == msg.datum.data.(string) {
	zd.send_string (eh, "null", "", msg)
    } else {
	zd.send_string (eh, "str", msg.datum.data.(string), msg)
    }
}

literalvsh_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("literalvsh")
    return zd.make_leaf (name_with_id, owner, nil, literalvsh_proc)
}

literalvsh_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "literal", "vsh", msg)
}

literalgrep_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("literalgrep")
    return zd.make_leaf (name_with_id, owner, nil, literalgrep_proc)
}

literalgrep_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "literal", "grep ", msg)
}

///

StringConcat_Instance_Data :: struct {
    buffer : string
}

stringconcat_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("stringconcat")
    instp := new (StringConcat_Instance_Data)
    return zd.make_leaf (name_with_id, owner, instp^, stringconcat_proc)
}

stringconcat_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := &eh.instance_data.(StringConcat_Instance_Data)
    switch msg.port {
    case "1":
	inst.buffer = strings.clone (msg.datum.data.(string))
    case "2":
	s := strings.clone (msg.datum.data.(string))
	if 0 == len (inst.buffer) || 0 == len (s) {
	    fmt.printf ("stringconcat %d %d\n", len (inst.buffer), len (s))
	    fmt.assertf (false, "TODO: something is wrong, 0 length string passed to stringconcat\n")
	}
	concatenated_string := fmt.aprintf ("%s%s", inst.buffer, s)
	zd.send_string (eh, "str", concatenated_string, msg)
	case:
        fmt.assertf (false, "bad msg.port for stringconcat: %v\n", msg.port)
    }
}

////////

low_level_read_text_file_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("Low Level Read Text File")
    return zd.make_leaf (name_with_id, owner, nil, low_level_read_text_file_proc)
}

low_level_read_text_file_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fname := msg.datum.data.(string)
    fd, errnum := os.open (fname)
    if errnum == 0 {
	data, success := os.read_entire_file_from_handle (fd)
	if success {
	    zd.send_string (eh, "str", transmute(string)data, msg)
	} else {
            emsg := fmt.aprintf("read error on file %s", msg.datum.data.(string))
	    zd.send_string (eh, "error", emsg, msg)
	}
    } else {
        emsg := fmt.aprintf("open error on file %s with error code %v", msg.datum.data.(string), errnum)
	zd.send_string (eh, "error", emsg, msg)
    }
}

////////

panic_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("panic")
    return zd.make_leaf (name_with_id, owner, nil, panic_proc)
}

panic_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fmt.println ("PANIC: ", msg.datum.data.(string))
    // assert (false, msg.datum.data.(string))
}

////

open_text_file_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("Open Text File")
    return zd.make_leaf (name_with_id, owner, nil, open_text_file_proc)
}

open_text_file_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fd, errnum := os.open (msg.datum.data.(string))
    if errnum == 0 {
	zd.send (eh, "fd", zd.new_datum_handle (fd), msg)
    } else {
        emsg := fmt.aprintf("open error on file %s with error code %v", msg.datum.data.(string), errnum)
	zd.send_string (eh, "error", emsg, msg)
    }
}

////////

read_text_from_fd_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("Low Level Read Text From FD")
    return zd.make_leaf (name_with_id, owner, nil, low_level_read_text_from_fd_proc)
}

low_level_read_text_from_fd_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fd := msg.datum.data.(os.Handle)
    data, success := os.read_entire_file_from_handle (fd)
    if success {
	zd.send_string (eh, "str", transmute(string)data, msg)
    } else {
        emsg := fmt.aprintf("read error on file %s", msg.datum.data.(string))
	zd.send_string (eh, "error", emsg, msg)
    }
}

//////////

Transpile_Instance_Data :: struct {
    grammar_name : string,
    fab_name : string,
    support_name : string
}

transpiler_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("Transpiler")
    instp := new (Transpile_Instance_Data)
    return zd.make_leaf (name_with_id, owner, instp^, transpiler_leaf_proc)
}

transpiler_leaf_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := &eh.instance_data.(Transpile_Instance_Data)
    switch msg.port {
    case "grammar":
        inst.grammar_name = msg.datum.data.(string)
    case "fab":
        inst.fab_name = msg.datum.data.(string)
    case "support":
        inst.support_name = msg.datum.data.(string)
    case "stdin":
        received_input := msg.datum.data.(string)
        cmd := fmt.aprintf ("./transpile %s %s %s", inst.grammar_name, inst.fab_name, inst.support_name)
	captured_output, captured_stderr := process.run_command (cmd, received_input)
	if string (captured_stderr) != "" {
            zd.send_string (eh, "error", captured_stderr, msg)
	} else {
            zd.send_string (eh, "output", captured_output, msg)
	}
	case:
        emsg := fmt.aprintf("!!! ERROR: transpile got an illegal message port %v", msg.port)
	zd.send_string (eh, "error", emsg, msg)
    }
}

////////

Syncfilewrite_Data :: struct {
    filename : string
}

syncfilewrite_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("syncfilewrite")
    instp := new (Syncfilewrite_Data)
    return zd.make_leaf (name_with_id, owner, instp^, syncfilewrite_proc)
}

syncfilewrite_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := &eh.instance_data.(Syncfilewrite_Data)
    switch msg.port {
    case "filename":
	inst.filename = msg.datum.data.(string)
    case "stdin":
	contents := msg.datum.data.(string)
	ok := os.write_entire_file (inst.filename, transmute([]u8)contents, true)
	if !ok {
	    zd.send_string (eh, "stderr", "write error", msg)
	}
    }
}

////////

Suffix_Data :: struct {
    suffix : string
}

suffix_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("suffix")
    instp := new (Suffix_Data)
    instp.suffix = ""
    return zd.make_leaf (name_with_id, owner, instp^, suffix_proc)
}

suffix_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := &eh.instance_data.(Suffix_Data)
    switch msg.port {
    case "suffix":
	inst.suffix = msg.datum.data.(string)
    case "str":
	s := fmt.aprintf ("%v%v", msg.datum.data.(string), inst.suffix)
	zd.send_string (eh, "str", s, msg)
	case:
	zd.send_string (eh, "error", fmt.aprintf ("illegal port for suffix: ~v", msg.port), msg)
    }
}



rwr_grammar := ""
rwr_semobject := ""
rwr_support_js := ""

hard_coded_rwr_grammar_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("hard_coded_rwr_grammar")
    return zd.make_leaf (name_with_id, owner, nil, hard_coded_rwr_grammar_proc)
}

hard_coded_rwr_semantics_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("hard_coded_rwr_semantics")
    return zd.make_leaf (name_with_id, owner, nil, hard_coded_rwr_semantics_proc)
}

hard_coded_rwr_support_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("hard_coded_rwr_support")
    return zd.make_leaf (name_with_id, owner, nil, hard_coded_rwr_support_proc)
}

hard_coded_rwr_grammar_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", rwr_grammar, msg)
}
hard_coded_rwr_semantics_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", rwr_semobject, msg)
}
hard_coded_rwr_support_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", rwr_support_js, msg)
}

///
bang_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("bang[%d]")
    return zd.make_leaf (name_with_id, owner, nil, bang_proc)
}

bang_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send (eh, "output", zd.new_datum_bang (), msg)
}

///
Concat_Instance_Data :: struct {
    buffer : string,
}

empty_string := ""

concat_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("concat")
    instp := new (Concat_Instance_Data)
    instp.buffer = strings.clone (empty_string)
    return zd.make_leaf (name_with_id, owner, instp^, concat_proc)
}

concat_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := &eh.instance_data.(Concat_Instance_Data)
    switch (msg.port) {
    case "str":
	delete (inst.buffer)
	inst.buffer = fmt.aprintf ("%s%s", inst.buffer, msg.datum.data.(string))
    case "flush":
	zd.send_string (eh, "str", inst.buffer, msg)
	delete (inst.buffer)
	inst.buffer = ""
    }
}

////

word_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("word")
    return zd.make_leaf (name_with_id, owner, nil, word_proc)
}

word_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", "Word", msg)
}


wordohm_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("word")
    return zd.make_leaf (name_with_id, owner, nil, wordohm_proc)
}

wordohm_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", "rt/word.ohm", msg)
}

wordjs_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("wordjs")
    return zd.make_leaf (name_with_id, owner, nil, wordjs_proc)
}

wordjs_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", "rt/word.sem.js", msg)
}

OhmJS_Instance_Data :: struct {
    grammarname : string, // grammar name
    grammarfilename : string, // file name of grammar in ohm-js format
    semanticsfilename : string, // file name of source text of semantics support code JavaScript namespace
    input : string, // source file to be parsed
}

ohmjs_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("OhmJS")
    inst := new (OhmJS_Instance_Data) // all fields have zero value before any messages are received
    return zd.make_leaf (name_with_id, owner, inst^, ohmjs_proc)
}

ohmjs_maybe :: proc (eh: ^zd.Eh, inst: ^OhmJS_Instance_Data, causingMsg: ^zd.Message) {
    if "" != inst.grammarname && "" != inst.grammarfilename && "" != inst.semanticsfilename && "" != inst.input {

        cmd := fmt.aprintf ("ohmjs/ohmjs.js %s %s %s", inst.grammarname, inst.grammarfilename, inst.semanticsfilename)
	captured_output, err := process.run_command (cmd, inst.input)
        zd.send_string (eh, "output", captured_output, cause=causingMsg)
	zd.send_string (eh, "error", err, cause=causingMsg)
    }
}

ohmjs_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := &eh.instance_data.(OhmJS_Instance_Data)
    switch (msg.port) {
    case "grammar name":
	inst.grammarname = strings.clone (msg.datum.data.(string))
	ohmjs_maybe (eh, inst, msg)
    case "grammar":
	inst.grammarfilename = strings.clone (msg.datum.data.(string))
	ohmjs_maybe (eh, inst, msg)
    case "semantics":
	inst.semanticsfilename = strings.clone (msg.datum.data.(string))
	ohmjs_maybe (eh, inst, msg)
    case "input":
	inst.input = strings.clone (msg.datum.data.(string))
	ohmjs_maybe (eh, inst, msg)
	case:
        emsg := fmt.aprintf("!!! ERROR: OhmJS got an illegal message port %v", msg.port)
	zd.send_string (eh, "error", emsg, msg)
    }
}

////

/// RWR rewriter generates semantics from .rwr spec

rwr_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("rwr")
    return zd.make_leaf (name_with_id, owner, nil, rwr_proc)
}
rwr_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", "RWR", msg)
}
rwrohm_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("rwrohm")
    return zd.make_leaf (name_with_id, owner, nil, rwrohm_proc)
}
rwrohm_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", "rwr/rwr.ohm", msg)
}
rwrsemjs_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("rwrsemjs")
    return zd.make_leaf (name_with_id, owner, nil, rwrsemjs_proc)
}
rwrsemjs_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", "rwr/rwr.sem.js", msg)
}

///
escapes_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("escapes")
    return zd.make_leaf (name_with_id, owner, nil, escapes_proc)
}
escapes_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", "Escapes", msg)
}
escapesohm_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("escapesohm")
    return zd.make_leaf (name_with_id, owner, nil, escapesohm_proc)
}
escapesohm_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", "rt/escapes.ohm", msg)
}
escapesrwr_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("escapesrwr")
    return zd.make_leaf (name_with_id, owner, nil, escapesrwr_proc)
}
escapesrwr_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", "rt/escapes.rwr", msg)
}

//

/* Syncfilewrite_Data :: struct { */
/*     filename : string */
/* } */

// temp copy for bootstrap, sends "done" (error during bootstrap if not wired)

syncfilewrite2_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("syncfilewrite2")
    inst := new (Syncfilewrite_Data)
    return zd.make_leaf (name_with_id, owner, inst^, syncfilewrite2_proc)
}

syncfilewrite2_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := &eh.instance_data.(Syncfilewrite_Data)
    switch msg.port {
    case "filename":
	inst.filename = msg.datum.data.(string)
    case "input":
	contents := msg.datum.data.(string)
	ok := os.write_entire_file (inst.filename, transmute([]u8)contents, true)
	if !ok {
	    zd.send_string (eh, "error", "write error", msg)
	} else {
	    zd.send (eh, "done", zd.new_datum_bang (), msg)
	}
    }
}

fakepipename_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("fakepipename")
    return zd.make_leaf (name_with_id, owner, nil, fakepipename_proc)
}

fakepipename_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    @(static) rand := 0
    rand += 1
    zd.send_string (eh, "output", fmt.aprintf ("/tmp/fakepipename%d", rand), msg)
}


///


colonspc_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("colonspc")
    return zd.make_leaf (name_with_id, owner, nil, colonspc_proc)
}
colonspc_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", ": ", msg)
}

///
find_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("find")
    return zd.make_leaf (name_with_id, owner, nil, find_proc)
}
find_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send_string (eh, "output", "Find", msg)
}

///

ensure_string_datum_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    name_with_id := gensym("Ensure String Datum")
    return zd.make_leaf (name_with_id, owner, nil, ensure_string_datum_proc)
}

ensure_string_datum_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    switch x in msg.datum.data {
    case string:
	zd.forward (eh, "output", msg)
    case:
	zd.send_string (eh, "error", "ensure: type error (expected a string datum)", msg)
    }
}

