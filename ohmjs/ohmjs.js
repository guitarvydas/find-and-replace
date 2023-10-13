#!/usr/bin/env node
//'use strict'

// Ohm-JS as a command-line command
//
// an Ohm-JS application consists of 2 operations in sequence
// 1. pattern match
// 2. if the pattern match was successful, then tree-walk the result and apply semantics

const fs = require ('fs');
const ohm = require ('ohm-js');

let argv;

let src = String.raw`
Find
`;

let grammarText = String.raw`
Find {
  FindSCN = Heading

  Heading = "Find"

    character = ~"<" ~">" ~"❲" ~"❳" ~"↺" ~"#" ~"-" ~space any

      Tag = "#" Name

      word<s> = "❲" s "❳"
      string<s> = dq s dq


	Name = "❲" NameChar+ "❳"
	NameChar =
	  | "❲" NameChar* "❳" -- rec
	  | ~"❲" ~"❳" any  -- other

	Line = "---"

	dq = "\""
}
`;

let semanticsObject = {
    FindSCN: function (Heading) {
	_ruleEnter ("FindSCN");
	console.error (`A ${Heading === undefined}`);
	Heading = Heading.rwr ();
	console.error ('B');
	Rule = " <N/A> ";
	AuxRule = " <N/A> ";

	_ruleExit ("FindSCN");
	return `${Heading}${Rule}${AuxRule}`;
    },
    Heading: function (id) {
	_ruleEnter ("Heading");
	id = id.rwr ();
	_ruleExit ("Heading");
	return `${id}`;
    },
    character: function (c) {
	_ruleEnter ("character");
	c = c.rwr ();

	_ruleExit ("character");
	return `${c}`;
    },
    Tag: function (koctothorpe,Name) {
	_ruleEnter ("Tag");
	koctothorpe = koctothorpe.rwr ();
	Name = Name.rwr ();

	_ruleExit ("Tag");
	return `${koctothorpe}${Name}`;
    },
    word: function (lb,s,rb) {
	_ruleEnter ("word");
	lb = lb.rwr ();
	s = s.rwr ();
	rb = rb.rwr ();

	_ruleExit ("word");
	return `${lb}${s}${rb}`;
    },
    string: function (dq1,s,dq2) {
	_ruleEnter ("string");
	dq1 = dq1.rwr ();
	s = s.rwr ();
	dq2 = dq2.rwr ();

	_ruleExit ("string");
	return `${dq1}${s}${dq2}`;
    },



    Name: function (lb,cs,rb) {
	_ruleEnter ("Name");

	console.error (`lb is undefined ${lb === undefined}`);
	console.error (`cs is undefined ${cs === undefined}`);
	console.error (`rb is undefined ${rb === undefined}`);

	lb = lb.rwr ();
	cs = cs.rwr ().join ('');
	rb = rb.rwr ();

	_ruleExit ("Name");
	return `${lb}${cs}${rb}`;
    },




    NameChar_rec: function (lb,cs,rb) {
	_ruleEnter ("NameChar_rec");
	lb = lb.rwr ();
	cs = cs.rwr ().join ('');
	rb = rb.rwr ();

	_ruleExit ("NameChar_rec");
	return `${lb}${cs}${rb}`;
    },
    NameChar_other: function (c) {
	_ruleEnter ("NameChar_other");
	c = c.rwr ();

	_ruleExit ("NameChar_other");
	return `${c}`;
    },
    Line: function (c) {
	_ruleEnter ("Line");
	c = c.rwr ();

	_ruleExit ("Line");
	return `${c}`;
    },
    space: function (c) {
	_ruleEnter ("space");
	c = c.rwr ();

	_ruleExit ("space");
	return `${c}`;
    },
    dq: function (c) {
	_ruleEnter ("dq");
	c = c.rwr ();

	_ruleExit ("dq");
	return `${c}`;
    },

    _terminal: function () { return this.sourceString; },
    _iter: function (...children) { return children.map(c => c.rwr ()); },
    spaces: function (x) { return this.sourceString; },
    space: function (x) { return this.sourceString; },


};



function makeAST (grammarName, grammarText) {
    // returns an AST object or an error object
    // an AST is an Abstract Syntax Tree, which encodes ALL possible matches
    // in true OO fashion, the AST is further embellished with various methods and
    //  private data, then returned as an internal object
    // returns ast or throws error if any
    //
    // OhmJS converts the text for the grammar into an internal data structure,
    //  that internal data structure is needed for later operations
    // grammarName is used to select only one of the grammars, for matching
    // grammarText contains multiple grammars in textual format
    //
    // the use-case for multiple grammars is, most often, the fact that a grammar
    //  can inherit from other grammars, hence, a grammar text file can contain a number
    //  of uniquely named grammars, only one of which is meant to be used
    //
    let grammars = undefined;
    let ast = undefined;
    let emessage = '';
    try {
	grammars = ohm.grammars (grammarText);
	ast = grammars [grammarName];
	if (ast === undefined) { throw (Error (`can't find grammar ${grammarName}`)); }
	return ast
    } catch (e) {
	throw (e);
    }
}
/////
function patternMatch (src, ast) {
    // return cst or throw error if any
    try {
	matchResult = ast.match (src);
    } catch (e) {
	throw (e);
    }
    if (matchResult.failed ()) {
	throw (Error (matchResult.message));
    } else { 
	return matchResult;
    }
}
/////
function makeASST (ast) {
    return ast.createSemantics ();
}
/////
var _traceDepth = 0;
var _tracing = true;

function _ruleInit () {
}

function _traceSpaces () {
    var s = '';
    var n = _traceDepth;
    while (n > 0) {
        s += ' ';
        n -= 1;
    }
    s += `[${_traceDepth.toString ()}]`;
    return s;
}

function _ruleEnter (ruleName) {
    if (_tracing) {
        _traceDepth += 1;
        var s = _traceSpaces ();
        s += 'enter: ';
        s += ruleName.toString ();
        console.log (s);
    }
}

function _ruleExit (ruleName) {
    if (_tracing) {
        var s = _traceSpaces ();
        _traceDepth -= 1;
        s += 'exit: ';
        s += ruleName.toString ();
        console.log (s);
    }
}

function extractFormals (s) {
    var s0 = s
        .replace (/\n/g,',')
        .replace (/[A-Za-z0-9_]+ = /g,'')
        .replace (/\.[^;]+;/g,'')
        .replace (/,/,'')
	.replace (/var /g,'')
    ;
    return s0;
}

// helper functions
var ruleName = "???";
function setRuleName (s) { ruleName = s; return "";}
function getRuleName () { return ruleName; }




function hangOperationOntoAsst (asst, opName, opFileName) {
    try {
	let sem = asst.addOperation (opName, semanticsObject);
	return sem;
    } catch (e) {
	throw Error (`while loading operation ${opName}: ${e.message}`);
    }
}
/////

function processCST (opName, asst, cst) {
    console.error (asst.getOperationNames ())
    console.error (opName)
    try {
	return (asst (cst) [opName]) ();
    } catch (e) {
	_tracing = true;
	console.error ('error during processing of the AST, src written to /tmp/src');
	console.error (argv);
	fs.writeFileSync ('/tmp/src', src);
	try {
	    return (asst (cst) [opName]) ();
	} catch (eagain) {
	    throw eagain;
	}
    }
}
/////

function main () {
    console.error ('TESTING');
    
    // top level command, prints on stdout and stderr (if error) then exits with 0 or 1 (OK, or not OK, resp.)
    try {
	argv = require('yargs/yargs')(process.argv.slice(2)).argv;
	let grammarName = "Find";
	let grammarFileName = "";
	let rwrFileName = "";

	_traceDepth = 0;
	_tracing = true;

	let ast = makeAST (grammarName, grammarText);
	let cst = patternMatch (src, ast);
	console.error ('done patternMatch');
	let emptyAsst = makeASST (ast)
	let asst = hangOperationOntoAsst (emptyAsst, "rwr", rwrFileName);

	let walked = processCST ("rwr", asst, cst)
	return walked;
	
    } catch (e) {
	console.log ("");
	console.error (e.message.trim ());
	process.exit (1);
    }
}

var result = main ()
console.log (result.trim ());
console.error ("");
