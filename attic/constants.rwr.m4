Constants {
include(`prolog/prolog.rwr.inc')

  Sexpr_beginconstantlist [lp q sexpr rp] = ‛«sexpr»’

  CSexpr_constantnil [lp rp] = ‛(constant-nilₓ)’
  CSexpr_constantlist [lp Sexprs* rp] = ‛(constant-listₓ «Sexprs»)’
  CSexpr_constantstring [k] = ‛(constant-stringₓ «k»)’
  CSexpr_constantinteger [k] = ‛(constant-integerₓ "«k»")’
  CSexpr_constantsymbol [k] = ‛(constant-symbolₓ "«k»")’

  sym [s vcomma?] = ‛«s»«vcomma»’
}
