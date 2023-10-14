// first-cut version (no optimization yet)
//
// a Cons cell is an object {car, cdr, isPair, toString}
// nil is "nil"
//
// a List is a chain of Cons cells, the data for a cell is stored in the car, and a pointer to the next cell is in the cdr
// the last cell in a chain contains "nil" as its cdr
/////

function Cons(car,cdr) { 
    this.car = car;
    this.cdr = cdr;
    this.isPair = true;
    this.toString = function() {  // returns string (a b) or (a . b) with appropriate trailing space in the possible presence of javascript errors (null and undefined)
	return cellToStr(this);
   }
};

function car(cell) {
    return cell.car;
}
function cdr(cell) {
    return cell.cdr;
}
function cddr(cell) {
    return cdr(cdr(cell));
}
function cdddr(cell) {
    return cdr(cdr(cdr(cell)));
}
function cddddr(cell) {
    return cdr(cdr(cdr(cdr(cell))));
}
function cdddddr(cell) {
    return cdr(cdr(cdr(cdr(cdr(cell)))))
}

function caar (cell) {
    return car(car(cell));
}

function cadr (cell) {
    return car(cdr(cell));
}

function caddr (cell) {
    return car(cddr(cell));
}

function cadddr (cell) {
    return car(cdddr(cell));
}

function caddddr (cell) {
    return car(cddddr(cell));
}

function cadaar (cell) {
    return car(cdr(car(car(cell))));
}

function cons(x,y) {
    if (x == undefined && y == undefined) {
	return "nil";
    } else if (y == undefined) {
	return new Cons(x,"nil");
    } else {
	return new Cons(x,y);
    }
}

function list() {
    var result = "nil";
    for(var i = (arguments.length-1); i >= 0 ; i--) {
	result = cons (arguments[i], result);
    }
    return result;
}

function isEmptyList (x) {
    if (x == "nil") {
	return true;
    } else if (x.isPair) {
	return false;
    } else {
	return false;
    }
}


function isPair (x) {
    // Scheme doesn't like truthiness or falsiness, it wants true or false
    if (!x) {
	return false;
    } else if (x.isPair) {
	return true;
    } else {
	return false;
    }
}
function toDebug (x) {
    console.log("toDebug x=");
    console.log(x);
    if (x == "nil") {
	return "()";
    } else if (x == null) {
	return "NULL";
    } else if (x == undefined) {
	return "UNDEFINED";
    } else {
	return x.toString();
    }
}
function isString (s) {
    return s && ("string" == typeof(s));
}

function mutate_car (l,v) { l.car = v; }

function newline () { process.stdout.write("\n"); }
function display(x) { 
    if (x == "nil") {
	process.stdout.write("nil");
    } else if (x == undefined) {
	process.stdout.write("undefined");
    } else {
	process.stdout.write(x.toString()); 
    }
}

/// additions Sept. 12, 2023

function constant_nil () { return "nil"; }

var constant_list = list;

function constant_string (s) { return s; }

function constant_symbol (s) { return constant_string (s); }

function constant_integer (s) { return parseInt (s); }

////



// utility functions for Cons.toString()
function isNil(x) {
    if ("string" == typeof(x)) {
	if ("nil" == x) {
	    return true;
	} else {
	    return false;
	}
    } else {
	return false;
    }
}
function isCons (maybeCell) {
    if ("object" == typeof(maybeCell)) {
	if (maybeCell.isPair) {
	    return true;
	} else {
	    return false;
	}
    } else {
	return false;
    }
}
function carItemToString(x) {
    if (x == undefined) {
	return "error(undefined)";
    } else if (x == null) {
	return "error(null)";
    } else if (isNil(x)) {
	return "nil";
    } else if (isCons(x)) {
	return x.toString();
    } else {
	return x.toString();
    }
}
function cdrItemToString(x) {
    if (x == undefined) {
	return "error(undefined)";
    } else if (x == null) {
	return "error(null)";
    } else if (isNil(x)) {
	return "";
    } else if (isCons(x)) {
	return "";
    } else {
	return x.toString();
    }
}

function toSpacer(x) { // return " . " if cell contains a non-nil/non-next-cell item, return " " if end-of-list, else return ""
    // more edge cases than Lisp or Scheme because of undefined and null, and I've decided to make nil be "nil"
    if (x == undefined) {
	return " ";
    } else if (x == null) {
	return " ";
    } else if ( ("object" == typeof(x) && x.isPair) ) {
	if ( ("object" == typeof(x.cdr)) ) {
	    return " ";
	} else if (isNil(x.cdr)) {
	    return "";
	} else {
	    return " . ";
	}
    } else {
	throw "can't happen";
    }
}

function toTrailingSpace(x) { // return " " if end of list, else ""
    // more edge cases than Lisp or Scheme because of undefined and null, and I've decided to make nil be "nil"
    if (x == undefined) {
	return " ";
    } else if (x == null) {
	return " ";
    } else if ( ("object" == typeof(x) && x.isPair) ) {
	if ( ("object" == typeof(x.cdr)) ) {
	    return " ";
	} else if (isNil(x.cdr)) {
	    return "";
	} else {
	    return "";
	}
    } else {
	throw "can't happen";
    }
}


function continueCDRing(maybeCell) {  // if x.cdr is another Cons, return true, if it's "nil" return false, if it's a primitive return false, else return false
    // more edge cases than Lisp or Scheme because of undefined and null, and I've decided to make nil be "nil"
    // x should be a Cons cell or "nil" or a primitive, but it might be null or undefined (an internal error that I want to see)
    if (maybeCell == undefined) {
	return false;
    } else if (maybeCell == null) {
	return false;
    } else if (isNil(maybeCell)) {
	return false;
    } else if (isCons(maybeCell)) {  // a Cons cell
	let next = cdr(maybeCell);
	if (isCons(next)) {
	    return true;
	} else {
	    return false;
	}
    } else if ("object" == typeof(maybeCell)) {
	return false;
    } else {
	return false;
    }
}
function nextCell(maybeCell) { // return cdr of cell if we are to continue (determined by continueCDRing function, above), else return undefined
    // more edge cases than Lisp or Scheme because of undefined and null, and I've decided to make nil be "nil"
    // x should be a Cons cell or "nil" or a primitive, but it might be null or undefined (an internal error that I want to see)
    if (maybeCell == undefined) {
	return undefined;
    } else if (maybeCell == null) {
	return undefined;
    } else if (isNil(maybeCell)) {
	return undefined;
    } else if (isCons(maybeCell)) {
	return cdr(maybeCell);  // this will return a Cons or might return "nil" if at end of list
    } else if ("object" == typeof(maybeCell)) {
	return undefined;
    } else {
	return undefined;
    }
}
function cellToStr(cell) {
    let str = "(";
    let keepGoing = true;
    while (keepGoing) {
	let a = carItemToString(car(cell));
	let d = cdrItemToString(cdr(cell));
	let spacer = toSpacer(cell);
	let trailer = toTrailingSpace(cell);
	str = str + a + spacer + d + trailer;
	keepGoing = continueCDRing(cell);
	cell = nextCell(cell);
    }
    return str + ")";
}

function undef () { return undefined; }


///// stack
function push (stack, v) {
    return cons (v, stack);
}

function init () {
    return constant_nil ();
}

function isEmpty (stack) {
    return isEmptyList (stack);
}

function top (stack) {
    if (isEmptyList (stack)){
	return constant_nil ();
    } else {
	return car (stack);
    }
}

function rest (stack) {
    if (isEmptyList (stack)){
	return constant_nil ();
    } else {
	return cdr (stack);
    }
}

// function explicit_asString (m) {
//     // return a string representation of a map (for debugging)
//     let r = [];
//     i = 0;
//     for (const [key, value] of m) {
// 	let str = `${key}: ${value.toString ()}`;
// 	r [i] = str;
// 	i += 1;
//     }
//     return r;
// }
	       
function mapAsString (m) {
    return Array.from (m);
}


function printable (s) {
    if (s === undefined) {
	return constant_nil ().toString ();
    } else if (s instanceof Map) {
	return mapAsString (s);
    } else {
	return s.toString ();
    }
}	

function pdebug (info, s) {
    console.log (info, 
		 printable (s), 
		 "is empty:", isEmpty (s), 
		 "top:", printable (car (s)),
		 "rest:", printable (rest (s))
		);
}




function test0 () {
    let stk = init ();
    pdebug ('A', stk);
    
    stk = push (stk, "Hello");
    pdebug ('B', stk);
    
    stk = push (stk, "item2");
    pdebug ('C',stk);
}

function testall () {
    let stk = init ();
    pdebug ('A', stk);

    let map1 = new Map ();
    map1.set('a', 1);
    map1.set('b', 2);
    map1.set('c', 3);
    stk = push (stk, map1);
    pdebug ('B', stk);
    
    let map2 = new Map ();
    map1.set('d', 4);
    stk = push (stk, map2);
    pdebug ('C',stk);
}

testall ();

let m = new Map ();
m.set('x', 97);
m.set('y', 98);
m.set('z', 99);
console.log (mapAsString (m));
console.log (typeof (m));
