include(`prolog/prolog.ohm.inc')

Constants <: Prolog {
  Sexpr += "(" sym<"quote"> CSexpr ")" -- beginconstantlist

  CSexpr = 
    | "(" ")" -- constantnil
    | "(" CSexpr+ ")" -- constantlist
    | string -- constantstring
    | integer -- constantinteger
    | Symbol -- constantsymbol

  integer = number
  sym<s> = s vcomma?
}
