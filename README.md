- debugging odd behaviour of Ohm-JS using a script ./dev.bash
- it appears that Ohm-JS is calling sem.js rule "Name" with undefined parameters
- in the past, all problems have devolved into being my errors, which implies that this problem is probably something caused by my code
- see README.md in https://github.com/guitarvydas/find-and-replace/tree/debugrwr
- I haven't whittled this down to something simpler yet
- running ./dev.bash results in:
  - a list of names of valid operations `[ 'rwr' ]`
	  - `rwr` is my mnemonic for `rewrite`
  - the name of the operation being invoked `rwr`
  - 3 outputs regarding the the undefined-edness of the 3 parameters to the JavaScript function 'Name'
  - a dump of argv for this invocation of ohmjs.js
  - a trace of the semantic rules being called (`[1] ... [5]`)
  - 3 outputs (again) regarding the 3 parameters `Name: function (lb,cs,rb) {...}`




Demonstration of a combination of a number of simple concepts ostensibly to play with new syntax:
- 0D
- drawware
- RWR - an SCN (nano-DSL) for rewriting text
- macros for any language
- preserving whitespace in comments and strings
- identifiers containing whitespace
- Ohm-JS
- RT (recursive text)
- debugging using probes
- syntax-driven translation
- explicit stacks
- DOWN calls in RWR
- mechanisms

- syntactic vs. Lexical grammars

- Loop in the modern age

see loop-syntax.drawio

see Makefile
