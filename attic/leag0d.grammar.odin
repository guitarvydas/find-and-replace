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

