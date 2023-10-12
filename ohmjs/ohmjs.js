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
## %20 ❲Find❳
<❲mark❳>❲Loop❳</❲mark❳>
      ❲loop❳ ❲over❳ <❲sub❳><❲i❳>❲SymbolListName❳</❲i❳></❲sub❳> ⇒ <❲sub❳><❲i❳>❲SingleSymbolName❳</❲i❳></❲sub❳> {
          <❲sub❳><❲i❳>❲TerminationClause❳</❲i❳></❲sub❳> <❲sub❳><❲i❳>❲Iteration❳</❲i❳></❲sub❳> <❲sub❳><❲i❳>❲Clause❳</❲i❳></❲sub❳>
      }



  ---

 - <❲mark❳>❲TerminationClause❳</❲mark❳>    ❲termination❳ : <❲sub❳><❲i❳>❲Clause❳</❲i❳></❲sub❳> ;
 - <❲mark❳>❲IterationClause❳</❲mark❳>           ❲iteration❳ : <❲u❳><❲sub❳><❲i❳>❲Statement❳</❲i❳></❲sub❳></❲u❳><❲sub❳>?</❲sub❳>
 - <❲mark❳>❲Clause❳</❲mark❳>
	- #❲nested❳                        { <❲sub❳><❲i❳>❲Statement❳</❲i❳></❲sub❳> } ↺
	- #❲other❳                         <❲u❳><❲span❳ ❲style❳="color%3A%20%23FF76C1%3B">;<❲sup❳>≠</❲sup❳></❲span❳> <❲span❳ ❲style❳="color%3A%20%23FF76C1%3B">{<❲sup❳>≠</❲sup❳></❲span❳> <❲span❳ ❲style❳="color%3A%20%23FF76C1%3B">}<❲sup❳>≠</❲sup❳></❲span❳> <❲span❳ ❲style❳="color%3A%2300B040%3B">✓</❲span❳></❲u❳><❲sub❳>1...</❲sub❳>  ↺

- <❲mark❳>❲Statement❳</❲mark❳>                   <❲sub❳><❲i❳>❲Clause❳</❲i❳></❲sub❳> ;

- <❲mark❳>❲SymbolListName❳</❲mark❳>       \`=\` <❲sub❳><❲i❳>❲word❳</❲i❳></❲sub❳>
- <❲mark❳>❲SingleSymbolName❳</❲mark❳>  \`=\` <❲sub❳><❲i❳>❲word❳</❲i❳></❲sub❳>
`;

let grammarText = String.raw`
Find {
  FindSCN = Heading Rule+ AuxRule*

  Heading = "#"+ "%20" Name

  Rule =        RuleName RuleBody
  AuxRule = "-" RuleName RuleBody

  RuleBody = Branch+
  Branch =
    | "-" Tag MatchItem+ -- tagged
    | MatchItem+         -- untagged

  RuleName = "<" word<"mark"> ">" Name "</" word<"mark"> ">"

  MatchItem =
    | RuleApplication -- ruleapplication
    | Recursion       -- opRecursion
    | NegativeMatch   -- negativeMatch
    | Iteration       -- iteration
    | Any             -- any
    | Name            -- name
    | character       -- character
    
  RuleApplication = "<" word<"sub"> ">" "<" word<"i"> ">" Name "</" word<"i"> ">"  "</" word<"sub"> ">"
  Recursion = "↺"
  NegativeMatch = "<" word<"span"> word<"style"> "=" string<"color%3A%20%23FF76C1%3B"> ">" (Name | RuleApplication | character) "<" word<"sup"> ">" "≠" "</" word<"sup"> ">" "</" word<"span"> ">" 
  Iteration = OneOrMore | ZeroOrMore | Optional
  OneOrMore = Vinculum "<" word<"sub"> ">" "1..." "</" word<"sub"> ">"
  ZeroOrMore = Vinculum "<" word<"sub"> ">" "0..." "</" word<"sub"> ">"
  Optional = Vinculum "<" word<"sub"> ">" "?" "</" word<"sub"> ">"
  Vinculum = "<" word<"u"> ">" MatchItem+ "</" word<"u"> ">"
  Any = "<" word<"span"> word<"style"> "=" string<"color%3A%2300B040%3B"> ">" "✓" "</" word<"span"> ">"

    character = ~"<" ~">" ~"❲" ~"❳" ~"↺" ~"#" ~"-" ~space any

      Tag = "#" Name

      word<s> = "❲" s "❳"
      string<s> = dq s dq


	Name = "❲" NameChar+ "❳"
	NameChar =
	  | "❲" NameChar* "❳" -- rec
	  | ~"❲" ~"❳" any  -- other

	Line = "---"
	space += applySyntactic<Line>

	dq = "\""
}
`;

let semanticsObject = {
    FindSCN: function (Heading,Rule,AuxRule) {
	_ruleEnter ("FindSCN");
	console.error (`A ${Heading === undefined} ${Rule === undefined} ${AuxRule === undefined}`);
	Heading = Heading.rwr ();
	console.error ('B');
	Rule = Rule.rwr ().join ('');
	console.error ('C');
	AuxRule = AuxRule.rwr ().join ('');
	console.error ('D');

	_ruleExit ("FindSCN");
	return `${Heading}${Rule}${AuxRule}`;
    },
    Heading: function (koctothorpe,kblank,Name) {
	_ruleEnter ("Heading");
	koctothorpe = koctothorpe.rwr ().join ('');
	kblank = kblank.rwr ();
	Name = Name.rwr ();

	_ruleExit ("Heading");
	return `${koctothorpe}${kblank}${Name}`;
    },
    Rule: function (RuleName,RuleBody) {
	_ruleEnter ("Rule");
	RuleName = RuleName.rwr ();
	RuleBody = RuleBody.rwr ();

	_ruleExit ("Rule");
	return `${RuleName}${RuleBody}`;
    },
    AuxRule: function (kdash,RuleName,RuleBody) {
	_ruleEnter ("AuxRule");
	kdash = kdash.rwr ();
	RuleName = RuleName.rwr ();
	RuleBody = RuleBody.rwr ();

	_ruleExit ("AuxRule");
	return `${kdash}${RuleName}${RuleBody}`;
    },
    RuleBody: function (RuleBranch) {
	_ruleEnter ("RuleBody");
	RuleBranch = RuleBranch.rwr ().join ('');

	_ruleExit ("RuleBody");
	return `${RuleBranch}`;
    },
    Branch_tagged: function (kdash,Tag,MatchItems) {
	_ruleEnter ("Branch_tagged");
	kdash = kdash.rwr ();
	Tag = Tag.rwr ();
	MatchItems = MatchItems.rwr ().join ('');

	_ruleExit ("Branch_tagged");
	return `${kdash}${Tag}${MatchItems}`;
    },
    Branch_untagged: function (MatchItems) {
	_ruleEnter ("Branch_untagged");
	MatchItems = MatchItems.rwr ().join ('');

	_ruleExit ("Branch_untagged");
	return `${MatchItems}`;
    },
    RuleName: function (lt,kmark,gt,Name,lts,kmark2,gt2) {
	_ruleEnter ("RuleName");
	lt = lt.rwr ();
	kmark = kmark.rwr ();
	gt = gt.rwr ();
	Name = Name.rwr ();
	lts = lts.rwr ();
	kmark2 = kmark2.rwr ();
	gt2 = gt2.rwr ();

	_ruleExit ("RuleName");
	return `${lt}${kmark}${gt}${Name}${lts}${mark2}${gt2}`;
    },
    RuleApplication: function (lt,ksub,gt,lt,ki,gt,Name,lts,ki,gt,lts,ksub,gt) {
	_ruleEnter ("RuleApplication");
	lt = lt.rwr ();
	ksub = ksub.rwr ();
	gt = gt.rwr ();
	lt = lt.rwr ();
	ki = ki.rwr ();
	gt = gt.rwr ();
	Name = Name.rwr ();
	lts = lts.rwr ();
	ki = ki.rwr ();
	gt = gt.rwr ();
	lts = lts.rwr ();
	ksub = ksub.rwr ();
	gt = gt.rwr ();

	_ruleExit ("RuleApplication");
	return `${lt}${ksub}${gt}${lt}${ki}${gt}${Name}${lts}${ki}${gt}${lts}${ksub}${gt}`;
    },
    Recursion: function (krec) {
	_ruleEnter ("Recursion");
	krec = krec.rwr ();

	_ruleExit ("Recursion");
	return `${krec}`;
    },
    NegativeMatch: function (lt,kspan,kstyle,keq,red,gt,item,lt,ksup,gt,kne,lts,ksup,gt,lts,kspan,gt) {
	_ruleEnter ("NegativeMatch");
	lt = lt.rwr ();
	kspan = kspan.rwr ();
	kstyle = kstyle.rwr ();
	keq = keq.rwr ();
	red = red.rwr ();
	gt = gt.rwr ();
	item = item.rwr ();
	lt = lt.rwr ();
	ksup = ksup.rwr ();
	gt = gt.rwr ();
	kne = kne.rwr ();
	lts = lts.rwr ();
	ksup = ksup.rwr ();
	gt = gt.rwr ();
	lts = lts.rwr ();
	kspan = kspan.rwr ();
	gt = gt.rwr ();

	_ruleExit ("NegativeMatch");
	return `${lt}${kspan}${kstyle}${keq}${red}${gt}${item}${lt}${ksup}${gt}${kne}${lts}${ksup}${gt}${lts}${kspan}${gt}`;
    },
    OneOrMore: function (Vinculum,lt,ksub,gt,k1,lts,ksub,gt) {
	_ruleEnter ("OneOrMore");
	Vinculum = Vinculum.rwr ();
	lt = lt.rwr ();
	ksub = ksub.rwr ();
	gt = gt.rwr ();
	k1 = k1.rwr ();
	lts = lts.rwr ();
	ksub = ksub.rwr ();
	gt = gt.rwr ();

	_ruleExit ("OneOrMore");
	return `${Vinculum}${lt}${ksub}${gt}${k1}${lts}${ksub}${gt}`;
    },
    ZeroOrMore: function (Vinculum,lt,ksub,gt,k0,lts,ksub,gt) {
	_ruleEnter ("ZeroOrMore");
	Vinculum = Vinculum.rwr ();
	lt = lt.rwr ();
	ksub = ksub.rwr ();
	gt = gt.rwr ();
	k0 = k0.rwr ();
	lts = lts.rwr ();
	ksub = ksub.rwr ();
	gt = gt.rwr ();

	_ruleExit ("ZeroOrMore");
	return `${Vinculum}${lt}${ksub}${gt}${k0}${lts}${ksub}${gt}`;
    },
    Optional: function (Vinculum,lt,ksub,gt,kq,lts,ksub,gt) {
	_ruleEnter ("Optional");
	Vinculum = Vinculum.rwr ();
	lt = lt.rwr ();
	ksub = ksub.rwr ();
	gt = gt.rwr ();
	kq = kq.rwr ();
	lts = lts.rwr ();
	ksub = ksub.rwr ();
	gt = gt.rwr ();

	_ruleExit ("Optional");
	return `${inculum}${lt}${ksub}${gt}${kq}${lts}${ksub}${gt}`;
    },
    Vinculum: function (lt,ku,gt,MatchItem,lts,ku,gt) {
	_ruleEnter ("Vinculum");
	lt = lt.rwr ();
	ku = ku.rwr ();
	gt = gt.rwr ();
	MatchItem = MatchItem.rwr ().join ('');
	lts = lts.rwr ();
	ku = ku.rwr ();
	gt = gt.rwr ();

	_ruleExit ("Vinculum");
	return `${lt}${ku}${gt}${MatchItem}${lts}${ku}${gt}`;
    },
    Any: function (lt,kspan,kstyle,keq,green,gt,kcheckmark,lts,kspan,gt) {
	_ruleEnter ("Any");
	lt = lt.rwr ();
	kspan = kspan.rwr ();
	kstyle = kstyle.rwr ();
	keq = keq.rwr ();
	green = green.rwr ();
	gt = gt.rwr ();
	kcheckmark = kcheckmark.rwr ();
	lts = lts.rwr ();
	kspan = kspan.rwr ();
	gt = gt.rwr ();

	_ruleExit ("Any");
	return `${lt}${kspan}${kstyle}${keq}${green}${gt}${kcheckmark}${lts}${kspan}${gt}`;
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


    // manually added
    MatchItem : function (x) {
	_ruleEnter ("MatchItem");
	x = x.rwr ();

	_ruleExit ("MatchItem");
	return `${x}`;
    }
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
var _tracing = false;

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
    console.error ('0');
//    semanticsFunctionsAsNamespaceString = fs.readFileSync (opFileName, 'utf-8');
    console.error ('1');
//    let evalableSemanticsFunctionsString = '(' + semanticsFunctionsAsNamespaceString + ')';
    console.error ('2');
    try {
    console.error ('3');
//	console.error (evalableSemanticsFunctionsString);
//	compiledSemantics = eval (evalableSemanticsFunctionsString);
    console.error ('4');
//	let sem = asst.addOperation (opName, compiledSemantics);
	let sem = asst.addOperation (opName, semanticsObject);
    console.error ('4a');
	return sem;
    } catch (e) {
    console.error ('5');
	throw Error (`while loading operation ${opName}: ${evalableSemanticsFunctionsString}: ${e.message}`);
    }
    console.error ('6');
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
//	let grammarName = argv._[0];
	let grammarFileName = argv._[1];
	let rwrFileName = argv._[2];
//	src = fs.readFileSync ('/dev/fd/0', 'utf-8');

	_traceDepth = 0;
//	if (argv.trace) {
	    _tracing = true;
//	}

	// let grammarText = fs.readFileSync (grammarFileName, 'utf-8');
	// let rwr = fs.readFileSync (rwrFileName, 'utf-8');

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
