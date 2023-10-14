_ = {
    bindingstack: [],
    popbindings: function () {
	_.bindingstack = _.bindingstack.rest ();
	return "";
    },
    pushnewbindings: function () {
	_.bindingstack.push (new Map ());
    },
    bind: function (name, value) {
	_.bindingstack.top ().set (name, value);
    },
    top: function () {
	return _bindingstack.top ();
    },
    fetch: function (name) {
	return _.fetchbinding (name, _.bindingstack);
    },
    fetchbinding: function (name, stack) {
	if ([] === stack) {
	    return "";
	} else {
	    let top = stack.top ();
	    let v = top.get (name);
	    if (undefined != v) {
		return v;
	    } else {
		let rest = stack.rest ();
		return fetchbinding (name, rest);
	    }
	}
    },
},

// stack
function top (stack) {
    let r = stack.pop ();
    stack.push (r);
    return r;
}

function rest (stack) {
    let r = stack;
    r.pop ()
    return r;
}

function push (stack, v) {
    stack.push (v);
    return stack;
}

function isEmpty (stack) {
    return stack === [];
}
