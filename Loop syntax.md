## Find
<mark><b>Loop</b></mark>
      loop over <sub><i>SymbolListName</i></sub> -> <sub><i>SingleSymbolName</i></sub> {
          <sub><i>TerminationClause</i></sub> <sub><i>Iteration</i></sub> <sub><i>Clause</i></sub>
      }



  ---

 - <mark>TerminationClause</mark>    termination : <sub><i>Clause</i></sub> ;
 - <mark>IterationClause</mark>           iteration : <sub><i>Statement</i></sub><sub>?</sub>
 - <mark>Clause</mark>
	- #nested                        { <sub><i>Statement</i></sub> } ↺
	- #other                          <u>≠; ≠{ ≠} ✓</u><sub>1...</sub>  ↺

- <mark>Statement</mark>                   <sub><i>Clause</i></sub> ;

- <mark>SymbolListName</mark>       `=` <sub><i>word</i></sub>
- <mark>SingleSymbolName</mark>  `=` <sub><i>word</i></sub>

  ---
## Replace

This:
```
// this is a comment
loop over operands -> operand {
    termination: operands empty;
    iteration: 
      do-something1-with (operand); // this is yet another comment
      do-something2-with (operand, "this is a string containing spaces");
  }
```
### RT

transpiles to RT:
```
(comment "this is a comment")
(loop (operand operands)
  (empty operands)
  (do-something1-with operand) (comment "this is yet another comment")
  (do-something2-with operand (string "this is a string containing spaces"))
)
```

  **Loop** 
  **TerminationClause**
  **IterationClause**
  **Clause**
  #nested
  #other
  **Statement**








### Lisp

transpiles to Common Lisp:

```
(defun f (items)
  (mapc #'(lambda (item) 
            (progn 
              (do-something1-with item) 
              (do-something2-with item)))
        items))
```

  **Loop** 
  **TerminationClause**
  **IterationClause**
  **Clause**
  #nested
  #other
  **Statement**

### JavaScript
```
function f (items) {
  items.forEach (item =>  {
      do_something1_with(item));
      do_something2_with(item));
    });
}
```

  **Loop** 
  **TerminationClause**
  **IterationClause**
  **Clause**
  #nested
  #other
  **Statement**

  ---

## Separators 
  ;
  :
  {
  }
  ->
  ,

# misc
≁✗✕✖︎✘✗× *Clause* ⟨?*Clause*⟩ ⟪?*Clause*⟫
⟪+ ≠; ≠{ ≠} ✓⟫ 
<u>≠; ≠{ ≠} ✓</u>
<mark>≠; ≠{ ≠} ✓</mark><sub>1...</sub>
<mark>≠; ≠{ ≠} ✓</mark><sub>0...</sub>
<mark>≠; ≠{ ≠} ✓</mark><sub>?</sub>
<u>≠; ≠{ ≠} ✓</u><sub>1...</sub>
*•*<sub>1...</sub>


