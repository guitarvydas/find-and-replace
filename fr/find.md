## Find
<mark>Loop</mark>
      loop over <sub><i>SymbolListName</i></sub> ⇒ <sub><i>SingleSymbolName</i></sub> {
          <sub><i>TerminationClause</i></sub> <sub><i>Iteration</i></sub> <sub><i>Clause</i></sub>
      }



  ---

 - <mark>TerminationClause</mark>    termination : <sub><i>Clause</i></sub> ;
 - <mark>IterationClause</mark>           iteration : <u><sub><i>Statement</i></sub></u><sub>?</sub>
 - <mark>Clause</mark>
	- #nested                        { <sub><i>Statement</i></sub> } ↺
	- #other                         <u><span style="color: #FF76C1;">;<sup>≠</sup></span> <span style="color: #FF76C1;">{<sup>≠</sup></span> <span style="color: #FF76C1;">}<sup>≠</sup></span> <span style="color:#00B040;">✓</span></u><sub>1...</sub>  ↺

- <mark>Statement</mark>                   <sub><i>Clause</i></sub> ;

- <mark>SymbolListName</mark>       ≡ <sub><i>⎣word⎦</i></sub>
- <mark>SingleSymbolName</mark>   ≡ <sub><i>⎣word⎦</i></sub>