{
    input : function (items) {
	console.error ("input >>>");
	console.error (items.rwr ());
	console.error ("<<< input");
	return items.rwr ().join(''); },
    item_space : function (x) { 
	console.error ("item_space >>>");
	console.error (x.rwr ());
	console.error ("item_space <<<");
	return x.rwr ();},
    item_html : function (x) { 
	console.error ("item_html >>>");
	console.error (x.rwr ());
	console.error ("item_html <<<");
	return x.rwr ();},
    item_separator : function (x) { 
	console.error ("item_separator >>>");
	console.error (x.rwr ());
	console.error ("item_separator <<<");
	return x.rwr ();},
    item_string : function (x) { 
	console.error ("item_string >>>");
	console.error (x.rwr ());
	console.error ("item_string <<<");
	return x.rwr ();},
    item_word : function (x) { 
	console.error ("item_word >>>");
	console.error (x.rwr ());
	console.error ("item_word <<<");
	return x.rwr ();},
    word : function (legalchars) { return "❲" + legalchars.rwr ().join ('') + "❳";
    },
    html : function (lt, optslash, cs, gt) {
    	return lt.rwr () + optslash.rwr ().join ('') + cs.rwr ().join ('') + gt.rwr ();
    },
    separator: function (c) { return c.rwr () },
    comment: function (kcomment, cs, nl) { return kcomment.rwr () + cs.rwr ().join ('') + nl.rwr (); },
    space : function (spc) { return spc.rwr (); },
    string : function (dq1, cs, dq2) { return dq1.rwr () + cs.rwr ().join ('') + dq2.rwr (); },
    dq : function (dq) { return dq.rwr (); },

    _terminal: function() { return this.sourceString; },
    _iter: function (...children) { return children.map(c => c.rwr ()); }
}
