package leaf0d

import "core:fmt"
import "core:log"
import "core:strings"
import "core:slice"
import "core:os"
import "core:unicode/utf8"

import reg "../registry0d"
import "../process"
import "../syntax"
import zd "../0d"

stdout_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    return zd.make_leaf(name, owner, nil, stdout_proc)
}

stdout_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fmt.printf("%#v", msg.datum)
}

process_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    command_string := strings.clone(strings.trim_left(name, "$ "))
    command_string_ptr := new_clone(command_string)
    return zd.make_leaf(name, owner, command_string_ptr, process_proc)
}

process_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {

    utf8_string :: proc(bytes: []byte) -> (s: string, ok: bool) {
        s = string(bytes)
        ok = utf8.valid_string(s)
        return
    }
    
    send_output :: proc(eh: ^zd.Eh, port: string, output: []byte, causingMsg: zd.Message) {
        if len(output) > 0 {
            str, ok := utf8_string(output)
            if ok {
                zd.send(eh, port, str, causingMsg)
            } else {
                zd.send(eh, port, output, causingMsg)
            }
        }
    }

    switch msg.port {
    case "stdin":
        handle := process.process_start(eh.instance_data.(string))
        defer process.process_destroy_handle(handle)

        // write input, wait for finish
        {
            switch value in msg.datum {
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

        // breaks bootstrap error check, thus, removed line: zd.send(eh, "done", Bang{})

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
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("command[%d]", counter)
    inst := new (Command_Instance_Data)
    return zd.make_leaf (name_with_id, owner, inst, command_proc)
}

command_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := eh.instance_data.(Command_Instance_Data)
    switch msg.port {
    case "command":
        inst.buffer = msg.datum.(string)
        received_input := msg.datum.(string)
        captured_output, _ := process.run_command (inst.buffer, received_input)
        zd.send(eh, "stdout", captured_output, msg)
    case:
        fmt.assertf (false, "!!! ERROR: command got an illegal message port %v", msg.port)
    }
}

icommand_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("icommand[%d]", counter)
    inst := new (Command_Instance_Data)
    return zd.make_leaf (name_with_id, owner, inst, icommand_proc)
}

icommand_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := eh.instance_data.(Command_Instance_Data)
    switch msg.port {
    case "command":
        inst.buffer = msg.datum.(string)
    case "stdin":
        received_input := msg.datum.(string)
        captured_output, _ := process.run_command (inst.buffer, received_input)
        zd.send(eh, "stdout", captured_output, msg)
    case:
        fmt.assertf (false, "!!! ERROR: command got an illegal message port %v", msg.port)
    }
}


TwoAnys :: struct {
    first : zd.Message,
    second : zd.Message
}


Deracer_States :: enum { idle, waitingForFirst, waitingForSecond }

Deracer_Instance_Data :: struct {
    state : Deracer_States,
    buffer : TwoAnys
}

reclaim_Buffers_from_heap :: proc (inst : Deracer_Instance_Data) {
    zd.destroy_message (inst.buffer.first)
    zd.destroy_message (inst.buffer.second)
}

deracer_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("deracer[%d]", counter)
    inst := new (Deracer_Instance_Data) // allocate in the heap
    eh := zd.make_leaf (name_with_id, owner, inst, deracer_proc)
    inst.state = .idle
    return eh
}

send_first_then_second :: proc (eh : ^zd.Eh, inst: Deracer_Instance_Data) {
    zd.send(eh, "1", inst.buffer.first.datum, cause=inst.buffer.first)
    zd.send(eh, "2", inst.buffer.second.datum, cause=inst.buffer.second)
    reclaim_Buffers_from_heap (inst)
}

deracer_proc :: proc(eh: ^zd.Eh,  msg: ^zd.Message) {
    inst := eh.instance_data.(Deracer_Instance_Data)
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
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("?%d", counter)
    return zd.make_leaf (name_with_id, owner, nil, probe_proc)
}

probe_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fmt.eprintln (eh.name, msg.datum)
}

trash_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("trash%d", counter)
    return zd.make_leaf (name_with_id, owner, nil, trash_proc)
}

trash_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    // to appease dumped-on-floor checker
}

nulltester_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("nulltester[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, nulltester_proc)
}

nulltester_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    if "" == msg.datum.(string) {
	zd.send(eh, "null", "", msg)
    } else {
	zd.send(eh, "str", msg.datum.(string), msg)
    }
}

literalvsh_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("literalvsh[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, literalvsh_proc)
}

literalvsh_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "literal", "vsh", msg)
}

literalgrep_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("literalgrep[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, literalgrep_proc)
}

literalgrep_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "literal", "grep ", msg)
}

///

StringConcat_Instance_Data :: struct {
    buffer : string
}

stringconcat_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("stringconcat[%d]", counter)
    inst := new (StringConcat_Instance_Data)
    return zd.make_leaf (name_with_id, owner, inst, stringconcat_proc)
}

stringconcat_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := eh.instance_data.(StringConcat_Instance_Data)
    switch msg.port {
    case "1":
	inst.buffer = strings.clone (msg.datum.(string))
    case "2":
	s := strings.clone (msg.datum.(string))
	if 0 == len (inst.buffer) || 0 == len (s) {
	    fmt.printf ("stringconcat %d %d\n", len (inst.buffer), len (s))
	    fmt.assertf (false, "TODO: something is wrong, 0 length string passed to stringconcat\n")
	}
	concatenated_string := fmt.aprintf ("%s%s", inst.buffer, s)
	zd.send(eh, "str", concatenated_string, msg)
    case:
        fmt.assertf (false, "bad msg.port for stringconcat: %v\n", msg.port)
    }
}

////////

read_text_file_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("Read Text File[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, read_text_file_proc)
}

read_text_file_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fname := msg.datum.(string)
    fd, errnum := os.open (fname)
    if errnum == 0 {
	data, success := os.read_entire_file_from_handle (fd)
	if success {
	    zd.send(eh, "str", transmute(string)data, msg)
	} else {
            emsg := fmt.aprintf("read error on file %s", msg.datum.(string))
	    zd.send(eh, "error", emsg, msg)
	}
    } else {
        emsg := fmt.aprintf("open error on file %s with error code %v", msg.datum.(string), errnum)
	zd.send(eh, "error", emsg, msg)
    }
}

////////

panic_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("panic[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, panic_proc)
}

panic_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fmt.println ("PANIC: ", msg.datum.(string))
    // assert (false, msg.datum.(string))
}

////

open_text_file_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("Open Text File[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, open_text_file_proc)
}

open_text_file_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fd, errnum := os.open (msg.datum.(string))
    if errnum == 0 {
	zd.send(eh, "fd", fd, msg)
    } else {
        emsg := fmt.aprintf("open error on file %s with error code %v", msg.datum.(string), errnum)
	zd.send(eh, "error", emsg, msg)
    }
}

////////

read_text_from_fd_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("Read Text From FD[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, read_text_from_fd_proc)
}

read_text_from_fd_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    fd := msg.datum.(os.Handle)
    data, success := os.read_entire_file_from_handle (fd)
    if success {
	zd.send(eh, "str", transmute(string)data, msg)
    } else {
        emsg := fmt.aprintf("read error on file %s", msg.datum.(string))
	zd.send(eh, "error", emsg, msg)
    }
}

//////////

Transpile_Instance_Data :: struct {
    grammar_name : string,
    fab_name : string,
    support_name : string
}

transpiler_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("Transpiler[%d]", counter)
    inst := new (Transpile_Instance_Data)
    return zd.make_leaf (name_with_id, owner, inst, transpiler_leaf_proc)
}

transpiler_leaf_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := eh.instance_data.(Transpile_Instance_Data)
    switch msg.port {
    case "grammar":
        inst.grammar_name = msg.datum.(string)
    case "fab":
        inst.fab_name = msg.datum.(string)
    case "support":
        inst.support_name = msg.datum.(string)
    case "stdin":
        received_input := msg.datum.(string)
        cmd := fmt.aprintf ("./transpile %s %s %s", inst.grammar_name, inst.fab_name, inst.support_name)
	captured_output, captured_stderr := process.run_command (cmd, received_input)
	if string (captured_stderr) != "" {
            zd.send(eh, "error", captured_stderr, msg)
	} else {
            zd.send(eh, "output", captured_output, msg)
	}
     case:
        emsg := fmt.aprintf("!!! ERROR: transpile got an illegal message port %v", msg.port)
	zd.send(eh, "error", emsg, msg)
    }
}

////////

Syncfilewrite_Data :: struct {
    filename : string
}

syncfilewrite_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("syncfilewrite[%d]", counter)
    inst := new (Syncfilewrite_Data)
    return zd.make_leaf (name_with_id, owner, inst, syncfilewrite_proc)
}

syncfilewrite_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := eh.instance_data.(Syncfilewrite_Data)
    switch msg.port {
    case "filename":
	inst.filename = msg.datum.(string)
    case "stdin":
	contents := msg.datum.(string)
	ok := os.write_entire_file (inst.filename, transmute([]u8)contents, true)
	if !ok {
	    zd.send (eh, "stderr", "write error", msg)
	}
    }
}

////////

Suffix_Data :: struct {
    suffix : string
}

suffix_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1
    name_with_id := fmt.aprintf("suffix[%d]", counter)
    inst := new (Suffix_Data)
    inst.suffix = ""
    return zd.make_leaf (name_with_id, owner, inst, suffix_proc)
}

suffix_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := eh.instance_data.(Suffix_Data)
    switch msg.port {
    case "suffix":
	inst.suffix = msg.datum.(string)
    case "str":
	s := fmt.aprintf ("%v%v", msg.datum.(string), inst.suffix)
	zd.send (eh, "str", s, msg)
    case:
	zd.send (eh, "error", fmt.aprintf ("illegal port for suffix: ~v", msg.port), msg)
    }
}



/////

/*

rwr_grammar := "
RWR {
top = spaces name spaces \"{\" spaces rule+ spaces \"}\" spaces more*
more = name spaces \"{\" spaces rule* spaces \"}\" spaces
rule = applySyntactic<RuleLHS> spaces \"=\" spaces rewriteString -- up
RuleLHS = 
  | name \"[\" Param* \"]\" spaces downString spaces -- down
  | name \"[\" Param* \"]\" -- nodown
rewriteString = \"‛\" char* \"’\" spaces
downString = \"‛\" char* \"’\"
char =
  | \"«\" nonBracketChar* \"»\" -- eval
  | \"\\\" \"n\" -- newline
  | \"\\\" any -- esc
  | ~\"’\" ~\"]]\" any     -- raw
nonBracketChar = ~\"»\" ~\"«\"  ~\"’\" ~\"]]\" any
name = nameFirst nameRest*
nameFirst = \"_\" | letter
nameRest = \"_\" | alnum
Param =
  | name \"+\" -- plus
  | name \"*\" -- star
  | name \"?\" -- opt
  | name     -- flat
comment = \"//\" (~\"\n\" any)* \"\n\"
space += comment
}
"

*/

/*

rwr_semobject := "

    top : function (_ws1,_name,_ws2,_lb,_ws4,_rule,_ws5,_rb,_ws3,_more) { 
        _ruleEnter (\"top\");

        var ws1 = _ws1._rwr ();
        var name = _name._rwr ();
        var ws2 = _ws2._rwr ();
        var lb = _lb._rwr ();
        var ws4 = _ws4._rwr ();
        var rule = _rule._rwr ().join (\'\');
        var ws5 = _ws5._rwr ();
        var rb = _rb._rwr ();
        var ws3 = _ws3._rwr ();
        var more = _more._rwr ().join (\'\');
        var _result = `{
${rule}${more}
    _terminal: function () { return this.sourceString; },
    _iter: function (...children) { return children.map(c => c._rwr ()); },
    spaces: function (x) { return this.sourceString; },
    space: function (x) { return this.sourceString; }
}
`; 
        _ruleExit (\"top\");
        return _result; 
    },

    more : function (_name,_ws2,_lb,_ws4,_rule,_ws5,_rb,_ws3) { 
        _ruleEnter (\"top\");

        var name = _name._rwr ();
        var ws2 = _ws2._rwr ();
        var lb = _lb._rwr ();
        var ws4 = _ws4._rwr ();
        var rule = _rule._rwr ().join (\'\');
        var ws5 = _ws5._rwr ();
        var rb = _rb._rwr ();
        var ws3 = _ws3._rwr ();
        var _result = `
${rule}
`; 
        _ruleExit (\"top\");
        return _result; 
    },


    ////
    


    rule_up : function (_lhs,_ws1,_keq,_ws2,_rws) { 
        _ruleEnter (\"rule_up\");

        var lhs = _lhs._rwr ();
        var ws1 = _ws1._rwr ();
        var keq = _keq._rwr ();
        var ws2 = _ws2._rwr ();
        var rws = _rws._rwr ();
        var _result = `${lhs}
_ruleExit (\"${getRuleName ()}\");
return ${rws}
},
`; 
        _ruleExit (\"rule_up\");
        return _result; 
    },
    ////
    
    // RuleLHS [name lb @Params rb] = [[${name}: function (${extractFormals(Params)}) {\\n_ruleEnter (\"${name}\");${setRuleName (name)}${Params}
    // ]]
    RuleLHS_nodown : function (_name,_lb,_Params,_rb) { 
        _ruleEnter (\"RuleLHS_nodown\");

        var name = _name._rwr ();
        var lb = _lb._rwr ();
        var Params = _Params._rwr ().join (\'\');
        var rb = _rb._rwr ();
        var _result = `${name}: function (${extractFormals(Params)}) {\\n_ruleEnter (\"${name}\");${setRuleName (name)}${Params}
`; 
        _ruleExit (\"RuleLHS_nodown\");
        return _result; 
    },
    
    RuleLHS_down : function (_name,_lb,_Params,_rb, _ws1, _downstring, _ws2) { 
        _ruleEnter (\"RuleLHS_down\");

        var name = _name._rwr ();
        var lb = _lb._rwr ();
        var Params = _Params._rwr ().join (\'\');
        var rb = _rb._rwr ();
        var _result = `${name}: function (${extractFormals(Params)}) {\\n_ruleEnter (\"${name}\");${setRuleName (name)}\\nvar _0 = ${_downstring._rwr ()};\\n${Params}
`; 
        _ruleExit (\"RuleLHS_down\");
        return _result; 
    },

    ////


    // rewriteString [sb @cs se ws] = [[return \\`${cs}\\`;]]
    rewriteString : function (_sb,_cs,_se,_ws) { 
        _ruleEnter (\"rewriteString\");

        var sb = _sb._rwr ();
        var cs = _cs._rwr ().join (\'\');
        var se = _se._rwr ();
        var ws = _ws._rwr ();
        var _result = `\\`${cs}\\`;`; 
        _ruleExit (\"rewriteString\");
        return _result; 
    },

    downString : function (_sb,_cs,_se) { 
        _ruleEnter (\"downString\");

        var sb = _sb._rwr ();
        var cs = _cs._rwr ().join (\'\');
        var se = _se._rwr ();
        var _result = `\\`${cs}\\``; 
        _ruleExit (\"downString\");
        return _result; 
    },


    ////
    // char_eval [lb name rb] = [[\\$\\{${name}\\}]]
    // char_raw [c] = [[${c}]]
    char_eval : function (_lb,_cs,_rb) { 
        _ruleEnter (\"char_eval\");

        var lb = _lb._rwr ();
        var name = _cs._rwr ().join (\'\');
        var rb = _rb._rwr ();
        var _result = `\\$\\{${name}\\}`; 
        _ruleExit (\"char_eval\");
        return _result; 
    },
    
    char_newline : function (_slash, _c) { 
        _ruleEnter (\"char_newline\");

        var slash = _slash._rwr ();
        var c = _c._rwr ();
        var _result = `\\n`; 
        _ruleExit (\"char_newline\");
        return _result; 
    },
    char_esc : function (_slash, _c) { 
        _ruleEnter (\"char_esc\");

        var slash = _slash._rwr ();
        var c = _c._rwr ();
        var _result = `${c}`; 
        _ruleExit (\"char_esc\");
        return _result; 
    },
    char_raw : function (_c) { 
        _ruleEnter (\"char_raw\");

        var c = _c._rwr ();
        var _result = `${c}`; 
        _ruleExit (\"char_raw\");
        return _result; 
    },
    ////
    
    // name [c @cs] = [[${c}${cs}]]
    // nameRest [c] = [[${c}]]

    name : function (_c,_cs) { 
        _ruleEnter (\"name\");

        var c = _c._rwr ();
        var cs = _cs._rwr ().join (\'\');
        var _result = `${c}${cs}`; 
        _ruleExit (\"name\");
        return _result; 
    },
    
    nameFirst : function (_c) { 
        _ruleEnter (\"nameFirst\");

        var c = _c._rwr ();
        var _result = `${c}`; 
        _ruleExit (\"nameFirst\");
        return _result; 
    },

    nameRest : function (_c) { 
        _ruleEnter (\"nameRest\");

        var c = _c._rwr ();
        var _result = `${c}`; 
        _ruleExit (\"nameRest\");
        return _result; 
    },

    ////


    // Param_plus [name k] = [[\\nvar ${name} = _${name}._rwr ().join (\'\');]]
    // Param_star [name k] = [[\\nvar ${name} = _${name}._rwr ().join (\'\');]]
    // Param_opt [name k] = [[\\nvar ${name} = _${name}._rwr ().join (\'\');]]
    // Param_flat [name] = [[\\nvar ${name} = _${name}._rwr ();]]


    Param_plus : function (_name,_k) { 
        _ruleEnter (\"Param_plus\");

        var name = _name._rwr ();
        var k = _k._rwr ();
        var _result = `\\n${name} = ${name}._rwr ().join (\'\');`; 
        _ruleExit (\"Param_plus\");
        return _result; 
    },
    
    Param_star : function (_name,_k) { 
        _ruleEnter (\"Param_star\");

        var name = _name._rwr ();
        var k = _k._rwr ();
        var _result = `\\n${name} = ${name}._rwr ().join (\'\');`; 
        _ruleExit (\"Param_star\");
        return _result; 
    },
    
    Param_opt : function (_name,_k) { 
        _ruleEnter (\"Param_opt\");

        var name = _name._rwr ();
        var k = _k._rwr ();
        var _result = `\\n${name} = ${name}._rwr ().join (\'\');`; 
        _ruleExit (\"Param_opt\");
        return _result; 
    },
    
    Param_flat : function (_name) { 
        _ruleEnter (\"Param_flat\");

        var name = _name._rwr ();
        var _result = `\\n${name} = ${name}._rwr ();`; 
        _ruleExit (\"Param_flat\");
        return _result; 
    },
    
    ////

    _terminal: function () { return this.sourceString; },
    _iter: function (...children) { return children.map(c => c._rwr ()); },
    spaces: function (x) { return this.sourceString; },
    space: function (x) { return this.sourceString; }
};
"

*/

rwr_grammar := ""
rwr_semobject := ""
rwr_support_js := ""

hard_coded_rwr_grammar_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("hard_coded_rwr_grammar[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, hard_coded_rwr_grammar_proc)
}

hard_coded_rwr_semantics_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("hard_coded_rwr_semantics[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, hard_coded_rwr_semantics_proc)
}

hard_coded_rwr_support_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("hard_coded_rwr_support[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, hard_coded_rwr_support_proc)
}

hard_coded_rwr_grammar_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", rwr_grammar, msg)
}
hard_coded_rwr_semantics_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", rwr_semobject, msg)
}
hard_coded_rwr_support_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", rwr_support_js, msg)
}

///
bang_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("bang[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, bang_proc)
}

bang_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", true, msg)
}

///
Concat_Instance_Data :: struct {
    buffer : string,
}

empty_string := ""

concat_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("concat[%d]", counter)
    inst := new (Concat_Instance_Data)
    inst.buffer = strings.clone (empty_string)
    return zd.make_leaf (name_with_id, owner, inst, concat_proc)
}

concat_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := eh.instance_data.(Concat_Instance_Data)
    switch (msg.port) {
    case "str":
	delete (inst.buffer)
	inst.buffer = fmt.aprintf ("%s%s", inst.buffer, msg.datum.(string))
    case "flush":
	zd.send(eh, "str", inst.buffer, msg)
	delete (inst.buffer)
	inst.buffer = ""
    }
}

////

word_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("word[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, word_proc)
}

word_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", "Word", msg)
}


wordohm_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("word[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, wordohm_proc)
}

wordohm_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", "rt/word.ohm", msg)
}

wordjs_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("wordjs[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, wordjs_proc)
}

wordjs_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", "rt/word.sem.js", msg)
}

OhmJS_Instance_Data :: struct {
    grammarname : string, // grammar name
    grammarfilename : string, // file name of grammar in ohm-js format
    semanticsfilename : string, // file name of source text of semantics support code JavaScript namespace
    input : string, // source file to be parsed
}

ohmjs_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("OhmJS[%d]", counter)
    inst := new (OhmJS_Instance_Data) // all fields have zero value before any messages are received
    return zd.make_leaf (name_with_id, owner, inst, ohmjs_proc)
}

ohmjs_maybe :: proc (eh: ^zd.Eh, inst: OhmJS_Instance_Data, causingMsg: zd.Message) {
    if "" != inst.grammarname && "" != inst.grammarfilename && "" != inst.semanticsfilename && "" != inst.input {

        cmd := fmt.aprintf ("ohmjs/ohmjs.js %s %s %s", inst.grammarname, inst.grammarfilename, inst.semanticsfilename)
	captured_output, err := process.run_command (cmd, inst.input)
        zd.send (eh, "output", captured_output, cause=causingMsg)
	zd.send (eh, "error", err, cause=causingMsg)
    }
}

ohmjs_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := eh.instance_data.(OhmJS_Instance_Data)
    switch (msg.port) {
    case "grammar name":
	inst.grammarname = strings.clone (msg.datum.(string))
	ohmjs_maybe (eh, inst, msg)
    case "grammar":
	inst.grammarfilename = strings.clone (msg.datum.(string))
	ohmjs_maybe (eh, inst, msg)
    case "semantics":
	inst.semanticsfilename = strings.clone (msg.datum.(string))
	ohmjs_maybe (eh, inst, msg)
    case "input":
	inst.input = strings.clone (msg.datum.(string))
	ohmjs_maybe (eh, inst, msg)
     case:
        emsg := fmt.aprintf("!!! ERROR: OhmJS got an illegal message port %v", msg.port)
	zd.send(eh, "error", emsg, msg)
    }
}

////

/// RWR rewriter generates semantics from .rwr spec

rwr_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("rwr[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, rwr_proc)
}
rwr_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", "RWR", msg)
}
rwrohm_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("rwrohm[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, rwrohm_proc)
}
rwrohm_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", "rwr/rwr.ohm", msg)
}
rwrsemjs_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("rwrsemjs[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, rwrsemjs_proc)
}
rwrsemjs_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", "rwr/rwr.sem.js", msg)
}

///
escapes_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("escapes[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, escapes_proc)
}
escapes_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", "Escapes", msg)
}
escapesohm_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("escapesohm[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, escapesohm_proc)
}
escapesohm_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", "rt/escapes.ohm", msg)
}
escapesrwr_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("escapesrwr[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, escapesrwr_proc)
}
escapesrwr_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", "rt/escapes.rwr", msg)
}

//

/* Syncfilewrite_Data :: struct { */
/*     filename : string */
/* } */

// temp copy for bootstrap, sends "done" (error during bootstrap if not wired)

syncfilewrite2_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("syncfilewrite2[%d]", counter)
    inst := new (Syncfilewrite_Data)
    return zd.make_leaf (name_with_id, owner, inst, syncfilewrite2_proc)
}

syncfilewrite2_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    inst := eh.instance_data.(Syncfilewrite_Data)
    switch msg.port {
    case "filename":
	inst.filename = msg.datum.(string)
    case "input":
	contents := msg.datum.(string)
	ok := os.write_entire_file (inst.filename, transmute([]u8)contents, true)
	if !ok {
	    zd.send (eh, "error", "write error", msg)
	}
	zd.send (eh, "done", true, msg)
    }
}

fakepipename_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("fakepipename[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, fakepipename_proc)
}

fakepipename_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    @(static) rand := 0
    rand += 1
    zd.send (eh, "output", fmt.aprintf ("/tmp/fakepipename%d", rand), msg)
}


///


colonspc_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("colonspc[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, colonspc_proc)
}
colonspc_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", ": ", msg)
}

///
find_instantiate :: proc(name: string, owner : ^zd.Eh) -> ^zd.Eh {
    @(static) counter := 0
    counter += 1

    name_with_id := fmt.aprintf("find[%d]", counter)
    return zd.make_leaf (name_with_id, owner, nil, find_proc)
}
find_proc :: proc(eh: ^zd.Eh, msg: ^zd.Message) {
    zd.send(eh, "output", "Find", msg)
}
