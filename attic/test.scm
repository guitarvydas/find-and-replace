(define (var? x)
  (and (pair? x)
       (string? (car x))
       (string=? "?" (car x))))

;; (define (call-foreign expr bindings)
;;     (cond 
;; 	  ((b g)
;; 	   (f 4))
;; 	  ))

;; (define (call-foreign expr bindings)
;;   (let ((func (cadr expr))
;; 	(args (cddr expr)))

;;     (cond ((string=? "unity" func)
;; 	   (car args))

;; 	  ((string=? "add" func)
;; 	   (let ((resolved-args (resolveArgs args bindings)))
;; 	     (+ (car resolved-args) (cadr resolved-args))))

;; 	  ((string=? "display" func)
;; 	   (let ((a (value (car args) bindings)))
;; 	     (display a)))
	  
;; 	  ((string=? "newline" func)
;; 	   (newline))
	  
;; 	  (else (error "call-foreign called with unknown operator" func)))))

;; (define (junk2)
;;   (if x
;;       y
;;       z))

;; (define (junk1)
;;   (p6 
;;       (and 1 n)
;;       (+ 1 n)
;;       ))

;; (define pqr (funk x)) ;; wrong var assign

;; (define uvw (+ 2 3)) ;; wrong var assign

;; (define (clear_result) (set! result_ '()))
;; (newline)

;; always needed for testing
;; 8
;; (9)
;; (e)
;; (e d)
;; (f g)
(mutate r 7)


