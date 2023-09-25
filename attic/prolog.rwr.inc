  Program [Sexpr+] = ‛«Sexpr»’
  Sexpr_list [lp Sexpr+ rp] = ‛«lp»«Sexpr»«rp»’
  Sexpr_quoted [q Sexpr] = ‛«q»«Sexpr»’
  Sexpr_symbol [Symbol] = ‛«Symbol»’

  // separator [c] = ‛«c»’
  // vcomma [c] = ‛«c»’
  Symbol [symchar+ vcomma?] = ‛«symchar»«vcomma»’
  // symchar [c] = ‛«c»’
  
  string [dq1 cs* dq2] = ‛«dq1»«cs»«dq2»’
  number [ds+ vcomma?] = ‛«ds»«vcomma»’
  semiColonComment [ksemi cs* nl] = ‛’
