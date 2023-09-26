{
FindSCN: function (Heading,Rule,AuxRule) {
_ruleEnter ("FindSCN");
Heading = Heading.rwr ();
Rule = Rule.rwr ().join ('');
AuxRule = AuxRule.rwr ().join ('');

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

    _terminal: function () { return this.sourceString; },
    _iter: function (...children) { return children.map(c => c.rwr ()); },
    spaces: function (x) { return this.sourceString; },
    space: function (x) { return this.sourceString; }
}
