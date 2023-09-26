{
    input : function (items) {
	return items.rwr ().join(''); },
    item : function (x) { return x.rwr ();},
    word : function (legalchars) { return "❲" + legalchars.rwr ().join ('') + "❳"; },
    hashSpace : function (khashSpace) { return "# %20 "; },
    integer : function (ds) { return ds.rwr ().join (''); },
    separator: function (c) { return c.rwr () },
    comment: function (kcomment, cs, nl) { return kcomment.rwr () + cs.rwr ().join ('') + nl.rwr (); },
    space : function (spc) { return spc.rwr (); },
    string : function (dq1, cs, dq2) { return dq1.rwr () + cs.rwr ().join ('') + dq2.rwr (); },
    dq : function (dq) { return dq.rwr (); },
    tagChar: function (c) { return c.rwr (); },

    _terminal: function() { return this.sourceString; },
    _iter: function (...children) { return children.map(c => c.rwr ()); }
}
