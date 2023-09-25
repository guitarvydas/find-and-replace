Program [fv+ main] = ‛«fv»«main»’

Function [kfunction id lp formals? rp lb statements rb] = ‛\n«kfunction» «id» «lp»«formals»«rp» «lb»«statements»\n«rb»\n’

Variable [kvar id keq operations ksemi] = ‛\n«kvar» «id» «keq» «operations»«ksemi»’

Assignment [id keq operation ksemi] = ‛\n«id» «keq» «operation»«ksemi»’

Main [s] = ‛«s»’

Formals_nonlastformal [id kcomma more] = ‛«id»«kcomma» «more»’
Formals_lastformal [id kcomma] = ‛«id»’

Statements_if [s more?] = ‛«s»«more»’
Statements_let [s more?] = ‛«s»«more»’
Statements_op [s more?] = ‛«s»«more»’

OperationStatement [op ksemi] = ‛\n«op»«ksemi»’
LetStatement [klet id keq op ksemi] = ‛\n«klet» «id» «keq» «op»«ksemi»’
IfStatement [kif lp op rp lb s rb elsif* els?] = ‛\n«kif» «lp»«op»«rp»«lb»«s»\n«rb»«elsif»«els»’

Elsif [kelse kif lp op rp lb s rb elsif*] = ‛ «kelse» «kif» «lp»«op»«rp»«lb»«s»\n«rb»«elsif»’
Els [kelse lb s rb] = ‛ «kelse» «lb»«s»\n«rb»’

Operation_infix [op1 infixop op2] = ‛«op1» «infixop» «op2»’
Operation_unary [uop op] = ‛«uop»«op»’
Operation_parenthesized [lp op rp] = ‛«lp»«op»«rp»’
Operation_invoke [x] = ‛«x»’
Operation_atom [a] = ‛«a»’

InvokeOperation [id lp args? rp] = ‛«id»«lp»«args»«rp»’

Args [a+] = ‛«a»’

Arg_op [op acomma] = ‛«op»«acomma»’
Arg_atom [a acomma] = ‛«a»«acomma»’

Atom_string [x vcomma?] = ‛«x»«vcomma»’
Atom_number [x vcomma?] = ‛«x»«vcomma»’
Atom_symbol [x vcomma?] = ‛«x»«vcomma»’

String [ldq c* rdq] = ‛«ldq»«c»«rdq»’
dq [c] = ‛«c»’
Number [n] = ‛«n»’
Integer [d+] = ‛«d»’
Symbol [id] = ‛«id»’

InfixOperator_eqv [x] = ‛«x»’
InfixOperator_eq [x] = ‛«x»’
InfixOperator_branchingand [x] = ‛«x»’
InfixOperator_branchingor [x] = ‛«x»’
InfixOperator_plus [x] = ‛«x»’

UnaryOperator [opr] = ‛«opr»’

ID [c cs*] = ‛«c»«cs»’
legalCharacterFirst [c] = ‛«c»’
legalCharacterRest [c] = ‛«c»’

sym [s vcomma?] = ‛«s»«vcomma»’