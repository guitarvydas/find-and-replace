_ = {
    // first-cut version (no optimization yet)
    //
    // a Cons cell is an object {car, cdr, isPair, toString}
    // nil is "nil"
    //
    // a List is a chain of Cons cells, the data for a cell is stored in the car, and a pointer to the next cell is in the cdr
    // the last cell in a chain contains "nil" as its cdr
    /////

    Cons: function(first,remaining) { 
	this.car = first;
	this.cdr = remaining;
	this.isPair = true;
	this.toString = function() {  // returns string (a b) or (a . b) with appropriate trailing space in the possible presence of javascript errors (null and undefined)
	    return _.cellToStr(this);
	}
    },

    car: function(cell) {
	return cell.car;
    },
    cdr: function(cell) {
	return cell.cdr;
    },
    cddr: function(cell) {
	return _.cdr(_.cdr(cell));
    },
    cdddr: function(cell) {
	return _.cdr(_.cdr(_.cdr(cell)));
    },
    cddddr: function(cell) {
	return _.cdr(_.cdr(_.cdr(_.cdr(cell))));
    },
    cdddddr: function(cell) {
	return _.cdr(_.cdr(_.cdr(_.cdr(_.cdr(cell)))))
    },
    caar: function (cell) {
	return _.car(_.car(cell));
    },
    cadr: function (cell) {
	return _.car(_.cdr(cell));
    },
    caddr: function (cell) {
	return _.car(_.cddr(cell));
    },
    cadddr: function (cell) {
	return _.car(_.cdddr(cell));
    },
    caddddr: function (cell) {
	return _.car(_.cddddr(cell));
    },
    cadaar: function (cell) {
	return _.car(_.cdr(_.car(_.car(cell))));
    },
    cons: function(x,y) {
	if (x == undefined && y == undefined) {
	    return "nil";
	} else if (y == undefined) {
	    return new _.Cons(x,"nil");
	} else {
	    return new _.Cons(x,y);
	}
    },
    list: function() {
	var result = "nil";
	for(var i = (arguments.length-1); i >= 0 ; i--) {
	    result = _.cons (arguments[i], result);
	}
	return result;
    },
    isEmptyList: function (x) {
	if (x == "nil") {
	    return true;
	} else if (x.isPair) {
	    return false;
	} else {
	    return false;
	}
    },
    isPair : function(x) {
	// Scheme doesn't like truthiness or falsiness, it wants true or false
	if (!x) {
	    return false;
	} else if (x.isPair) {
	    return true;
	} else {
	    return false;
	}
    },
    toDebug : function(x) {
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
    },
    isString : function(s) {
	return s && ("string" == typeof(s));
    },
    mutate_car : function(l,v) { l.car = v; },
    newline : function() { process.stdout.write("\n"); },
    display: function(x) { 
	if (x == "nil") {
	    process.stdout.write("nil");
	} else if (x == undefined) {
	    process.stdout.write("undefined");
	} else {
	    process.stdout.write(x.toString()); 
	}
    },

    /// additions Sept. 12, 2023

    constant_nil : function() { return "nil"; },
    constant_list : function () { return _.list (); },
    constant_string : function(s) { return s; },
    constant_symbol : function(s) { return _.constant_string (s); },
    constant_integer : function(s) { return parseInt (s); },

    ////



    // utility functions for Cons.toString()
    isNil: function(x) {
	if ("string" == typeof(x)) {
	    if ("nil" == x) {
		return true;
	    } else {
		return false;
	    }
	} else {
	    return false;
	}
    },
    isCons: function (maybeCell) {
	if ("object" == typeof(maybeCell)) {
	    if (maybeCell.isPair) {
		return true;
	    } else {
		return false;
	    }
	} else {
	    return false;
	}
    },
    carItemToString: function(x) {
	if (x == undefined) {
	    return "error(undefined)";
	} else if (x == null) {
	    return "error(null)";
	} else if (_.isNil(x)) {
	    return "nil";
	} else if (_.isCons(x)) {
	    return x.toString();
	} else {
	    return x.toString();
	}
    },
    cdrItemToString: function(x) {
	if (x == undefined) {
	    return "error(undefined)";
	} else if (x == null) {
	    return "error(null)";
	} else if (_.isNil(x)) {
	    return "";
	} else if (_.isCons(x)) {
	    return "";
	} else {
	    return x.toString();
	}
    },

    toSpacer: function(x) {
	// return " . " if cell contains a non-nil/non-next-cell item,
	// return space if end-of-list, else return empty string
	// more edge cases than Lisp or Scheme because of undefined and null,
	// and because I've decided to make nil be "nil"
	if (x == undefined) {
	    return " ";
	} else if (x == null) {
	    return " ";
	} else if ( ("object" == typeof(x) && x.isPair) ) {
	    if ( ("object" == typeof(x.cdr)) ) {
		return " ";
	    } else if (_.isNil(x.cdr)) {
		return "";
	    } else {
		return " . ";
	    }
	} else {
	    throw "can't happen";
	}
    },
    toTrailingSpace: function(x) { // return " " if end of list, else ""
	// more edge cases than Lisp or Scheme because of undefined and null, and I've decided to make nil be "nil"
	if (x == undefined) {
	    return " ";
	} else if (x == null) {
	    return " ";
	} else if ( ("object" == typeof(x) && x.isPair) ) {
	    if ( ("object" == typeof(x.cdr)) ) {
		return " ";
	    } else if (_.isNil(x.cdr)) {
		return "";
	    } else {
		return "";
	    }
	} else {
	    throw "can't happen";
	}
    },
    continueCDRing: function(maybeCell) {  // if x.cdr is another Cons, return true, if it's "nil" return false, if it's a primitive return false, else return false
	// more edge cases than Lisp or Scheme because of undefined and null, and I've decided to make nil be "nil"
	// x should be a Cons cell or "nil" or a primitive, but it might be null or undefined (an internal error that I want to see)
	if (maybeCell == undefined) {
	    return false;
	} else if (maybeCell == null) {
	    return false;
	} else if (_.isNil(maybeCell)) {
	    return false;
	} else if (_.isCons(maybeCell)) {  // a Cons cell
	    let next = _.cdr(maybeCell);
	    if (_.isCons(next)) {
		return true;
	    } else {
		return false;
	    }
	} else if ("object" == typeof(maybeCell)) {
	    return false;
	} else {
	    return false;
	}
    },
    nextCell: function(maybeCell) { // return cdr of cell if we are to continue (determined by continueCDRing function, above), else return undefined
	// more edge cases than Lisp or Scheme because of undefined and null, and I've decided to make nil be "nil"
	// x should be a Cons cell or "nil" or a primitive, but it might be null or undefined (an internal error that I want to see)
	if (maybeCell == undefined) {
	    return undefined;
	} else if (maybeCell == null) {
	    return undefined;
	} else if (_.isNil(maybeCell)) {
	    return undefined;
	} else if (_.isCons(maybeCell)) {
	    return _.cdr(maybeCell);  // this will return a Cons or might return "nil" if at end of list
	} else if ("object" == typeof(maybeCell)) {
	    return undefined;
	} else {
	    return undefined;
	}
    },
    cellToStr: function(cell) {
	let str = "(";
	let keepGoing = true;
	while (keepGoing) {
	    let a = _.carItemToString(_.car(cell));
	    let d = _.cdrItemToString(_.cdr(cell));
	    let spacer = _.toSpacer(cell);
	    let trailer = _.toTrailingSpace(cell);
	    str = str + a + spacer + d + trailer;
	    keepGoing = _.continueCDRing(cell);
	    cell = _.nextCell(cell);
	}
	return str + ")";
    },
    undef: function () { return undefined; },


    ///// stack
    push: function (stack, v) {
	return _.cons (v, stack);
    },
    init: function () {
	return _.constant_nil ();
    },
    isEmpty: function (stack) {
	return _.isEmptyList (stack);
    },
    top: function (stack) {
	if (_.isEmptyList (stack)){
	    return _.constant_nil ();
	} else {
	    return _.car (stack);
	}
    },
    rest: function (stack) {
	if (_.isEmptyList (stack)){
	    return _.constant_nil ();
	} else {
	    return _.cdr (stack);
	}
    },


    // binding stack for RWR
    debug (x, y, z) {
	return;
	if (y === undefined) {
	    console.log (x);
	} else if (z === undefined) {
	    console.log (x, y);
	} else {
	    console.log (x, y, z); 
	}
    },

    
    bindingstack: "nil",
    popbindings: function () {
	_.debug ("popbindings");
	_.bindingstack = _.rest (_.bindingstack);
	return "";
    },
    pushnewbindings: function () {
	_.debug ("pushnewbindings");
	_.bindingstack = _.push (_.bindingstack.push, new Map ());
	return "";
    },
    bind: function (name, value) {
	_.debug ("bind 1a", _.bindingstack);
	let item = _.top (_.bindingstack);
	_.debug ("bind 1b", item);
	item.set (name, value);
	_.debug ("bind 1c", item);
	_.debug ("bind 1d", _.bindingstack);
	return "";
    },
    top: function () {
	_.debug ("top");
	return _.car (_.bindingstack);
    },
    fetch: function (name) {
	_.debug ("00000", _.bindingstack);
	_.debug ("fetch", _.bindingstack);
	return _.fetchbinding (name, _.bindingstack);
    },
    fetchbinding: function (name, stack) {
	_.debug ("fetchbinding", name, stack);
	if (_.isEmpty (stack)) {
	    return "<empty>";
	} else {
	    let item0 = _.top (_.bindingstack);
	    _.debug ("fetchbinding 2a", _.bindingstack);
	    _.debug ("fetchbinding 2b", item0);
	    let v = item0.get (name);
	    _.debug ("fetchbinding 3", v);
	    if (undefined != v) {
		return v;
	    } else {
		let rest = _rest (_.bindingstack);
		return _.fetchbinding (name, rest);
	    }
	}
    }

	
},
