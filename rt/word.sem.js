{
    input : function (cs) { return cs.rwr ().join(''); },
    item : function (x) {return x.rwr ();},
    word : function (legalchars) { return "❲" + legalchars.rwr ().join ('') + "❳"},
    separator: function (c) { return c.rwr () },
    comment: function (kcomment, cs, nl) { return kcomment.rwr () + cs.rwr ().join ('') + nl.rwr (); },
    space : function (spc) { return spc.rwr (); },
    string : function (dq1, cs, dq2) { return dq1.rwr () + cs.rwr ().join ('') + dq2.rwr (); },
    dq : function (dq) { return dq.rwr (); },

    _terminal: function() { return this.sourceString; },
    _iter: function (...children) { return children.map(c => c.rwr ()); }
}
