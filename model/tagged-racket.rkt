#lang mf-apply racket/base

;; Tagged Racket
;; "you can trust the tags"
;;
;; Check any value that enters typed code from "untyped" code
;; - check imports from untyped code
;; - check input to typed functions
;; - check reads from untyped data (calling untyped function, read from box/list)
;; For now, be conservative. Anything might be untyped.
;;
;; This is dynamic typing, where every type annotation represents a boundary.

;; Soundness = tag soundness

;; TODO
;; - support Nat types
;; - polymorphic primitives
;; - blame for dynamic checks
;; - remove unnecessary checks
;; - optimize

;; -----------------------------------------------------------------------------

(require
  racket/set
  redex/reduction-semantics
  redex-abbrevs
  redex-abbrevs/unstable
  (only-in racket/string string-split))

(define *debug* (make-parameter #f))

(define (debug msg . arg*)
  (when (*debug*)
    (apply printf msg arg*)))

(module+ test
  (require rackunit-abbrevs rackunit syntax/macro-testing
           (for-syntax racket/base racket/syntax syntax/parse)))

;; =============================================================================

(define-language++ TAG #:alpha-equivalent? α=?
;; τ = specification language
  (τ ::= k0 (k1 τ) (k2 τ τ))
  (k ::= k0 k1 k2)
  (k0 ::= Nat Int Bool)
  (k1 ::= Box)
  (k2 ::= Pair →)
  (K ::= k) ;; types we can check at runtime, O(1)
  (Γ ::= ((x τ) ...))

;; v = values
  (v ::= (box x) integer boolean Λ (cons v v))
  (Λ ::= (fun x (x) e))

;; e = implicitly typed source language, allows untyped terms
;;     needs explicit types for functions
;;      and embedded untyped terms
  (e ::= v x (e e) (if e e e)
         (let (x e) e)
         (:: Λ τ) ;; not allowed in untyped code
         (require (x τ e) e) ;; not allowed in untyped code
         (unop e) (binop e e) (cons e e))
  (primop ::= unop binop)
  (unop ::= car cdr make-box unbox)
  (binop ::= + * - = set-box!)

;; t = explicitly typed intermediate language, still allows untyped (source) terms
  (t ::= (:: v τ) (:: x τ) (:: (t t) τ) (:: (if t t t) τ)
         (:: (fun x (x) t) τ)
         (:: (let (x t) t) τ)
         (:: (require (x τ e) t) τ)
         (:: (unop t) τ)
         (:: (binop t t) τ)
         (:: (cons t t) τ))

;; c = type-erased, explicitly checked core language
  (c ::= v x (c c) (if c c c) (let (x c) c) (unop c) (binop c c) (cons c c) (check K c))
  (σ ::= ((x v) ...))
  (E ::= hole (E c) (v E) (if E c c) (let (x E) c) (unop E) (binop E c) (binop v E) (cons E c) (cons v E) (check K E))
  (RuntimeError ::= (CheckError K v))
  (A ::= [σ e] RuntimeError)

  (x* ::= (x ...))
  (x ::= variable-not-otherwise-mentioned)
#:binding-forms
  (let (x e) e_1 #:refers-to x)
  (require (x τ e) e_1 #:refers-to x)
  (fun x_f (x) e #:refers-to (shadow x_f x))
  (fun x_f (x) t #:refers-to (shadow x_f x))
  (let (x t) t_1 #:refers-to x)
  (require (x τ_x e) t_1 #:refers-to x)
  (let (x c) c_1 #:refers-to x))

;; =============================================================================

(define-metafunction TAG
  theorem:type-soundness : e -> boolean
  [(theorem:type-soundness e)
   boolean_sound
   (judgment-holds (well-formed e))
   (where t #{type-check# e})
   (where τ #{type-annotation t})
   (where c #{completion# t})
   (where A #{eval# c})
   (where K #{tag# τ})
   (where boolean_ok #{value-check# A K})])

(module+ test
  (test-case "type-soundness:basic"
    (check-true (term (theorem:type-soundness
      (+ 2 2))))
    (check-true (term (theorem:type-soundness
      ((:: (fun factorial (n)
             (if (= n 1) 1 (* n (factorial (- n 1))))) (→ Int Int))
       5))))
    (void)))

;; -----------------------------------------------------------------------------

(define-metafunction TAG
  type-check# : e -> t
  [(type-check# e)
   t
   (judgment-holds (type-check () e t))
   (judgment-holds (sound-elaboration e t))]
  [(type-check# e)
   ,(raise-argument-error 'type-check# "well-typed expression" (term e))])

(module+ test
  (test-case "type-check:basic"
    (check-mf-apply*
     [(type-check# (+ 2 2))
      (:: (+ (:: 2 Int) (:: 2 Int)) Int)]
     [(type-check# (:: (fun f (x) #true) (→ Int Bool)))
      (:: (fun f (x) (:: #true Bool)) (→ Int Bool))])
    (void)))

;; -----------------------------------------------------------------------------

(define-metafunction TAG
  completion# : t -> c
  [(completion# t)
   c
   (judgment-holds (completion t c))
   (side-condition (term #{sound-completion# t c}))]
  [(completion# t)
   ,(raise-argument-error 'completion# "(completable) type-annotated term" (term t))])

(module+ test
  (test-case "completion:basic"
    (check-mf-apply*
     [(completion# (:: (+ (:: 2 Int) (:: 2 Int)) Int))
      (+ 2 2)]
     [(completion# (:: (let (x (:: 2 Int)) (:: (+ (:: x Int) (:: 2 Int)) Int)) Int))
      (let (x 2) (+ x 2))]
     [(completion# (:: (let (f (:: (fun f (x) x) (→ Int Int))) (:: ((:: f (→ Int Int)) (:: 2 Int)) Int)) Int))
      (let (f (fun f (x) x)) (check Int (f x)))]
     [(completion# (:: (car (:: (cons 2 2) (Pair Int Int))) Int))
      (check Int (car (cons x 2)))])
    (void)))

;; -----------------------------------------------------------------------------

(define-metafunction TAG
  eval# : c -> A
  [(eval# c)
   A_1
   (where A_0 #{load# c})
   (where A_1 ,(eval* (term A_0)))]
  [(eval# c)
   ,(raise-argument-error 'eval# "core term" (term c))])

(define-metafunction TAG
  load# : c -> A
  [(load# c)
   [() c]])

(define-metafunction TAG
  unload# : A -> any
  [(unload# RuntimeError)
   RuntimeError]
  [(unload# [σ (box x)])
   (box v)
   (where v #{runtime-env-ref σ x})]
  [(unload# [σ v])
   v])

(module+ test
  (test-case "eval:basic"
    (check-mf-apply*
     [(unload# (eval# (+ 2 2)))
      4]
     [(unload# (eval# ((fun fact (n) (if (= n 1) 1 (* n (fact (- n 1))))) 5)))
      120])
    (void)))

;; -----------------------------------------------------------------------------

(define-metafunction TAG
  value-check# : A K -> boolean
  [(value-check# A K)
   #true
   (judgment-holds (value-check A K))]
  [(value-check# A K)
   #false])

(module+ test
  (test-case "value-check:basic"
    (check-mf-apply*
     [(value-check# [() 4] Int)
      #true]
     [(value-check# [() 4] Bool)
      #false]
     [(value-check# [() (fun f (x) #false)] →)
      #true]
     [(value-check# [((x 4)) (box x)] Box)
      #true]
     [(value-check# [() (cons 1 1)] Pair)
      #true])
    (void)))

;; =============================================================================
;; === type check

(define-judgment-form TAG
  #:mode (type-check I I O)
  #:contract (type-check Γ e t)
  [
   ---
   (type-check Γ integer (:: integer Int))]
  [
   ---
   (type-check Γ boolean (:: boolean Bool))]
  [
   (where (fun x_f (x) e) Λ)
   (where Γ_f #{type-env-set Γ (x_f (→ τ_0 τ_1))})
   (where Γ_x #{type-env-set Γ_f (x τ_0)})
   (type-check Γ_x e t)
   (where τ_1 #{type-annotation t})
   (where t_Λ (:: (fun x_f (x) t) (→ τ_0 τ_1)))
   ---
   (type-check Γ (:: Λ (→ τ_0 τ_1)) t_Λ)]
  [
   (where τ #{type-env-ref Γ x})
   ---
   (type-check Γ x (:: x τ))]
  [
   (type-check Γ e_0 t_0)
   (type-check Γ e_1 t_1)
   (where τ_0 #{type-annotation t_0})
   (where τ_1 #{type-annotation t_1})
   ---
   (type-check Γ (cons e_0 e_1) (:: (cons t_0 t_1) (Pair τ_0 τ_1)))]
  [
   (type-check Γ e_0 t_0)
   (type-check Γ e_1 t_1)
   (where (→ τ_dom τ_cod) #{type-annotation t_0})
   (where τ_dom #{type-annotation t_1})
   ---
   (type-check Γ (e_0 e_1) (:: (t_0 t_1) τ_cod))]
  [
   (type-check Γ e_0 t_0)
   (type-check Γ e_1 t_1)
   (type-check Γ e_2 t_2)
   (where τ #{type-annotation t_1})
   (where τ #{type-annotation t_2})
   ---
   (type-check Γ (if e_0 e_1 e_2) (:: (if t_0 t_1 t_2) τ))]
  [
   (type-check Γ e_x t_x)
   (where τ_x #{type-annotation t_x})
   (where Γ_x #{type-env-set Γ (x τ_x)})
   (type-check Γ_x e_1 t_1)
   (where τ_1 #{type-annotation t_1})
   ---
   (type-check Γ (let (x e_x) e_1) (:: (let (x t_x) t_1) τ_1))]
  [
   (where Γ_x #{type-env-set Γ (x τ_x)})
   (type-check Γ_x e t)
   (where τ #{type-annotation t})
   ---
   (type-check Γ (require (x τ_x e_x) e) (:: (require (x τ_x e_x) t) τ))]
  [
   (where (→ τ_dom τ_cod) #{primop-type unop})
   (type-check Γ e t)
   (where τ_dom #{type-annotation t})
   ---
   (type-check Γ (unop e) (:: (unop t) τ_cod))]
  [
   (where (→ τ_dom0 (→ τ_dom1 τ_cod)) #{primop-type binop})
   (type-check Γ e_0 t_0)
   (type-check Γ e_1 t_1)
   (where τ_dom0 #{type-annotation t_0})
   (where τ_dom1 #{type-annotation t_1})
   ---
   (type-check Γ (binop e_0 e_1) (:: (binop t_0 t_1) τ_cod))])

(define-judgment-form TAG
  #:mode (sound-elaboration I I)
  #:contract (sound-elaboration e t)
  [
   (where any_0 #{erase-types# e})
   (where any_1 #{erase-types# t})
   (side-condition ,(α=? (term any_0) (term any_1)))
   ---
   (sound-elaboration e t)])

(define-metafunction TAG
  erase-types# : any -> any
  [(erase-types# (:: any τ))
   #{erase-types# any}]
  [(erase-types# (any ...))
   (#{erase-types# any} ...)]
  [(erase-types# any)
   any])

;; =============================================================================
;; === completion

(define-judgment-form TAG
  #:mode (completion I O)
  #:contract (completion t c)
  [
   ---
   (completion t 0)])

(define-metafunction TAG
  sound-completion# : t c -> boolean
  [(sound-completion# t c)
   ,(raise-user-error 'sound-completion# "not implemented")])

;; =============================================================================
;; === eval

(define -->TAG
  (reduction-relation TAG
   #:domain A
   [-->
    [σ (in-hole E (Λ v))]
    [σ (in-hole E c_v)]
    E-Beta
    (where (fun x_f (x) c) Λ)
    (where c_f (substitute c x_f Λ))
    (where c_v (substitute c_f x v))]
   [-->
    [σ (in-hole E (if v c_0 c_1))]
    [σ (in-hole E c_next)]
    E-If
    (where c_next ,(if (term v) (term c_0) (term c_1)))]
   [-->
    [σ (in-hole E (let (x v) c))]
    [σ (in-hole E c_x)]
    E-Let
    (where c_x (substitute c x v))]
   [-->
    [σ (in-hole E (primop v ...))]
    #{maybe-in-hole E A}
    E-PrimOp
    (where A (apply-primop [σ (primop v ...)]))]
   [-->
    [σ (check K v)]
    #{maybe-in-hole E A}
    E-Check
    (where A #{apply-check [σ (check K v)]})]))

(define-metafunction TAG
  maybe-in-hole : E A -> A
  [(maybe-in-hole E RuntimeError)
   Runtime-Error]
  [(maybe-in-hole E [σ c])
   [σ (in-hole E c)]])

(define eval*
  (make--->* -->TAG))

;; =============================================================================
;; === value-check

(define-judgment-form TAG
  #:mode (value-check I I)
  #:contract (value-check A K)
  [
   ---
   (value-check RuntimeError K)]
  [
   ---
   (value-check [σ (box _)] Box)]
  [
   ---
   (value-check [σ natural] Nat)]
  [
   ---
   (value-check [σ integer] Int)]
  [
   ---
   (value-check [σ Λ] →)]
  [
   ---
   (value-check [σ (cons _ _)] Pair)])

(define-metafunction TAG
  tag# : τ -> K
  [(tag# τ)
   K
   (judgment-holds (tag-of τ K))])

(define-judgment-form TAG
  #:mode (tag-of I O)
  #:contract (tag-of τ K)
  [
   ---
   (tag-of K K)]
  [
   ---
   (tag-of (Box _) Box)]
  [
   ---
   (tag-of (Pair _ _) Pair)]
  [
   ---
   (tag-of (→ _ _) →)])

;; =============================================================================
;; =============================================================================

;; =============================================================================
;; === grammar

(define-judgment-form TAG
  #:mode (well-formed I)
  #:contract (well-formed e)
  [
   (no-free-variables e)
   (enough-annotations e)
   ---
   (well-formed e)])

(module+ test
  (test-case "well-formed:basic"
    (check-judgment-holds*
     (well-formed (+ 2 2))
     (well-formed (:: (fun f (x) 2) (→ Int Int)))
     (well-formed (let (x (:: (fun f (x) 2) (→ Int Int))) x))
     (well-formed (require (x (→ Int Int) (fun f (x) 2)) x))
    )
    (check-not-judgment-holds*
     (well-formed (+ x 2))
     (well-formed (fun f (x) 2))
     (well-formed (let (x (fun f (x) 2)) x))
     (well-formed (require (x (→ Int Int) (:: (fun f (x) 2) (→ Int Int))) x))
    )
    (void)))

;; -----------------------------------------------------------------------------

(define-judgment-form TAG
  #:mode (no-free-variables I)
  #:contract (no-free-variables e)
  [
   (free-variables e ())
   ---
   (no-free-variables e)]
  [
   (free-variables e x*)
   (side-condition #false)
   ---
   (no-free-variables e)])

(define-judgment-form TAG
  #:mode (free-variables I O)
  #:contract (free-variables e x*)
  [
   (free-variables x x*)
   ---
   (free-variables (box x) x*)]
  [
   ---
   (free-variables integer ())]
  [
   ---
   (free-variables boolean ())]
  [
   (where (fun x_f (x) e) Λ)
   (free-variables e x*_Λ)
   (where x* ,(set-subtract (term x*_Λ) (term (x_f x))))
   ---
   (free-variables Λ x*)]
  [
   (free-variables e_0 x*_0)
   (free-variables e_1 x*_1)
   (where x* ,(set-union (term x*_0) (term x*_1)))
   ---
   (free-variables (cons e_0 e_1) x*)]
  [
   ---
   (free-variables x (x))]
  [
   (free-variables e_0 x*_0)
   (free-variables e_1 x*_1)
   (where x* ,(set-union (term x*_0) (term x*_1)))
   ---
   (free-variables (e_0 e_1) x*)]
  [
   (free-variables e_0 x*_0)
   (free-variables e_1 x*_1)
   (free-variables e_2 x*_2)
   (where x* ,(set-union (term x*_0) (term x*_1) (term x*_2)))
   ---
   (free-variables (if e_0 e_1 e_2) x*)]
  [
   (free-variables e_0 x*_0)
   (free-variables e_1 x*_pre1)
   (where x*_1 ,(set-remove (term x*_pre1) (term x)))
   (where x* ,(set-union (term x*_0) (term x*_1)))
   ---
   (free-variables (let (x e_0) e_1) x*)]
  [
   (free-variables Λ x*)
   ---
   (free-variables (:: Λ τ) x*)]
  [
   (free-variables e_0 x*_0)
   (free-variables e_1 x*_pre1)
   (where x*_1 ,(set-remove (term x*_pre1) (term x)))
   (where x* ,(set-union (term x*_0) (term x*_1)))
   ---
   (free-variables (require (x τ e_0) e_1) x*)]
  [
   (free-variables e x*)
   ---
   (free-variables (unop e) x*)]
  [
   (free-variables e_0 x*_0)
   (free-variables e_1 x*_1)
   (where x* ,(set-union (term x*_0) (term x*_1)))
   ---
   (free-variables (binop e_0 e_1) x*)])

(module+ test
  (test-case "closed:basic"
    (check-not-judgment-holds*
     (no-free-variables (+ x 5))
     (no-free-variables (if (= x 1) 1 (* x (fact (- x 1))))))
    (check-judgment-holds*
     (no-free-variables 3)
     (no-free-variables (fun f (x) 2))
     (no-free-variables (fun f (x) x))
     (no-free-variables (fun fact (x) (if (= x 1) 1 (* x (fact (- x 1))))))
     (no-free-variables (let (y (:: (fun f (x) x) (→ Int Int))) (y 4)))
     (no-free-variables (+ 3 3)))
    (void)))

;; -----------------------------------------------------------------------------

(define-judgment-form TAG
  #:mode (enough-annotations I)
  #:contract (enough-annotations e)
  [
   (enough-annotations/typed e)
   ---
   (enough-annotations e)])

(define-judgment-form TAG
  #:mode (enough-annotations/typed I)
  #:contract (enough-annotations/typed e)
  [
   ---
   (enough-annotations/typed (box x))]
  [
   ---
   (enough-annotations/typed integer)]
  [
   ---
   (enough-annotations/typed boolean)]
  [
   (side-condition #false)
   ---
   (enough-annotations/typed Λ)]
  [
   (enough-annotations/typed e_0)
   (enough-annotations/typed e_1)
   ---
   (enough-annotations/typed (cons e_0 e_1))]
  [
   ---
   (enough-annotations/typed x)]
  [
   (enough-annotations/typed e_0)
   (enough-annotations/typed e_1)
   ---
   (enough-annotations/typed (e_0 e_1))]
  [
   (enough-annotations/typed e_0)
   (enough-annotations/typed e_1)
   (enough-annotations/typed e_2)
   ---
   (enough-annotations/typed (if e_0 e_1 e_2))]
  [
   (enough-annotations/typed e_0)
   (enough-annotations/typed e_1)
   ---
   (enough-annotations/typed (let (x e_0) e_1))]
  [
   (where (fun x_f (x) e) Λ)
   (enough-annotations/typed e)
   ---
   (enough-annotations/typed (:: Λ τ))]
  [
   (enough-annotations/untyped e_0)
   (enough-annotations/typed e_1)
   ---
   (enough-annotations/typed (require (x τ e_0) e_1))]
  [
   (enough-annotations/typed e)
   ---
   (enough-annotations/typed (unop e))]
  [
   (enough-annotations/typed e_0)
   (enough-annotations/typed e_1)
   ---
   (enough-annotations/typed (binop e_0 e_1))])

(define-judgment-form TAG
  #:mode (enough-annotations/untyped I)
  #:contract (enough-annotations/untyped e)
  [
   ---
   (enough-annotations/untyped (box x))]
  [
   ---
   (enough-annotations/untyped integer)]
  [
   ---
   (enough-annotations/untyped boolean)]
  [
   (where (fun x_f (x) e) Λ)
   (enough-annotations/untyped e)
   ---
   (enough-annotations/untyped Λ)]
  [
   (enough-annotations/untyped e_0)
   (enough-annotations/untyped e_1)
   ---
   (enough-annotations/untyped (cons e_0 e_1))]
  [
   ---
   (enough-annotations/untyped x)]
  [
   (enough-annotations/untyped e_0)
   (enough-annotations/untyped e_1)
   ---
   (enough-annotations/untyped (e_0 e_1))]
  [
   (enough-annotations/untyped e_0)
   (enough-annotations/untyped e_1)
   (enough-annotations/untyped e_2)
   ---
   (enough-annotations/untyped (if e_0 e_1 e_2))]
  [
   (enough-annotations/untyped e_0)
   (enough-annotations/untyped e_1)
   ---
   (enough-annotations/untyped (let (x e_0) e_1))]
  [
   (enough-annotations/untyped e)
   ---
   (enough-annotations/untyped (unop e))]
  [
   (enough-annotations/untyped e_0)
   (enough-annotations/untyped e_1)
   ---
   (enough-annotations/untyped (binop e_0 e_1))])

(module+ test
  (test-case "enough-annotations"
    (check-judgment-holds*
     (enough-annotations (+ 1 1))
     (enough-annotations (:: (fun f (x) x) (→ Int Int)))
     (enough-annotations (let (x 4) (+ x x)))
     (enough-annotations (require (x Int ((fun f (x) 1) 0)) x)))
    (check-not-judgment-holds*
     (enough-annotations (fun f (x) x))
     (enough-annotations (let (x (fun f (y) y)) (x 1))))
    (void)))

;; =============================================================================
;; === misc / helpers / util

(define-metafunction TAG
  type-env-ref : Γ x -> τ
  [(type-env-ref Γ x)
   ,(or
      (for/first ([xt (in-list (term Γ))]
                  #:when (equal? (term x) (car xt)))
        (cadr xt))
      (raise-arguments-error 'type-env-ref "unbound variable" "var" (term x) "env" (term Γ)))])

(define-metafunction TAG
  type-env-set : Γ (x τ) -> Γ
  [(type-env-set Γ (x τ))
   ,(cons (term (x τ)) (term Γ))])

(define-metafunction TAG
  type-annotation : t -> τ
  [(type-annotation (:: _ τ))
   τ])

(define-metafunction TAG
  primop-type : primop -> τ
  [(primop-type +)
   (→ Int (→ Int Int))]
  [(primop-type -)
   (→ Int (→ Int Int))]
  [(primop-type *)
   (→ Int (→ Int Int))]
  [(primop-type =)
   (→ Int (→ Int Bool))]
  [(primop-type set-box!)
   (→ (Box Int) (→ Int Int))]
  [(primop-type car)
   (→ (Pair Int Int) Int)]
  [(primop-type cdr)
   (→ (Pair Int Int) Int)]
  [(primop-type make-box)
   (→ Int (Box Int))]
  [(primop-type unbox)
   (→ (Box Int) Int)])

(define-metafunction TAG
  apply-primop : [σ (primop v ...)] -> A
  [(apply-primop [σ (car (cons v_0 _))])
   [σ v_0]]
  [(apply-primop [σ (cdr (cons _ v_1))])
   [σ v_1]]
  [(apply-primop [σ (make-box v)])
   [σ_x (box x)]
   (where x #{fresh-location σ})
   (where σ_x #{runtime-env-set σ (x v)})]
  [(apply-primop [σ (unbox (box x))])
   [σ v]
   (where v #{runtime-env-ref σ x})]
  [(apply-primop [σ (+ integer_0 integer_1)])
   [σ v]
   (where v ,(+ (term integer_0) (term integer_1)))]
  [(apply-primop [σ (- integer_0 integer_1)])
   [σ v]
   (where v ,(- (term integer_0) (term integer_1)))]
  [(apply-primop [σ (* integer_0 integer_1)])
   [σ v]
   (where v ,(* (term integer_0) (term integer_1)))]
  [(apply-primop [σ (= integer_0 integer_1)])
   [σ v]
   (where v ,(= (term integer_0) (term integer_1)))]
  [(apply-primop [σ (set-box! (box x) v)])
   [σ_x v]
   (where σ_x #{runtime-env-update σ (x v)})])

(define-metafunction TAG
  apply-check : [σ (check K v)] -> A
  [(apply-check [σ (check K v)])
   A_next
   (where A_next [σ v])
   (judgment-holds (value-check A_next K))]
  [(apply-check [σ (check K v)])
   (CheckError K v)])

(define-metafunction TAG
  runtime-env-set : σ (x v) -> σ
  [(runtime-env-set σ (x v))
   ,(cons (term (x v)) (term σ))])

(define-metafunction TAG
  runtime-env-ref : σ x -> v
  [(runtime-env-ref σ x)
   ,(or
      (for/first ([xv (in-list (term σ))]
                  #:when (equal? (car xv) (term x)))
        (cadr xv))
      (raise-arguments-error 'runtime-env-ref "unbound variable" "var" (term x) "env" (term σ)))])

(define-metafunction TAG
  runtime-env-update : σ (x v) -> σ
  [(runtime-env-update σ (x v))
   ,(let* ([success? (box #f)]
           [σ+ (for/list ([xv (in-list (term σ))])
                 (if (equal? (term x) (car xv))
                   (begin (set-box! success? #true) (term (x v)))
                   xv))])
      (if (unbox success?)
        σ+
        (raise-arguments-error 'runtime-env-update "unbound variable" "var" (term x) "env" (term σ))))])

(define-metafunction TAG
  fresh-location : σ -> x
  [(fresh-location σ)
   any_0
   (where any_0 ,(variable-not-in (term σ) 'loc))])

;; =============================================================================
;; === test

(module+ test
  (check α=?
    (term (:: (fun f (x) (:: x (Box Int))) (→ (Box Int) (Box Int))))
    (term (:: (fun f (x) (:: x (Box Int))) (→ (Box Int) (Box Int)))))

  (test-case "type-check"
    (check-mf-apply* #:is-equal? α=?
     [(type-check# 4)
      (:: 4 Int)]
     [(type-check# #false)
      (:: #false Bool)]
     [(type-check# #true)
      (:: #true Bool)]
     [(type-check# (:: (fun f (x) x) (→ (Box Int) (Box Int))))
      (:: (fun f (x) (:: x (Box Int))) (→ (Box Int) (Box Int)))]
     ;[(type-check# (:: (fun f (x) x) (→ (Box Bool) (Box Bool))))
     ; (:: (fun f (x) (:: x (Box Bool))) (→ (Box Bool) (Box Bool)))]
     [(type-check# (cons 1 1))
      (:: (cons (:: 1 Int) (:: 1 Int)) (Pair Int Int))]
     [(type-check# ((:: (fun f (x) 4) (→ Int Int)) 3))
      (:: ((:: (fun f (x) (:: 4 Int)) (→ Int Int)) (:: 3 Int)) Int)]
     [(type-check# (if 1 2 3))
      (:: (if (:: 1 Int) (:: 2 Int) (:: 3 Int)) Int)]
     [(type-check# (let (x 4) x))
      (:: (let (x (:: 4 Int)) (:: x Int)) Int)]
     [(type-check# (require (x Int 1) x))
      (:: (require (x Int 1) (:: x Int)) Int)]
     [(type-check# (car (cons 1 2)))
      (:: (car (:: (cons (:: 1 Int) (:: 2 Int)) (Pair Int Int))) Int)]
     [(type-check# (cdr (cons 2 1)))
      (:: (cdr (:: (cons (:: 2 Int) (:: 1 Int)) (Pair Int Int))) Int)]
     [(type-check# (make-box 3))
      (:: (make-box (:: 3 Int)) (Box Int))]
     [(type-check# (unbox (make-box 3)))
      (:: (unbox (:: (make-box (:: 3 Int)) (Box Int))) Int)]
     [(type-check# (+ 1 1))
      (:: (+ (:: 1 Int) (:: 1 Int)) Int)]
     [(type-check# (- 1 1))
      (:: (- (:: 1 Int) (:: 1 Int)) Int)]
     [(type-check# (* 1 1))
      (:: (* (:: 1 Int) (:: 1 Int)) Int)]
     [(type-check# (= 1 1))
      (:: (= (:: 1 Int) (:: 1 Int)) Bool)]
     [(type-check# (set-box! (make-box 2) 3))
      (:: (set-box! (:: (make-box (:: 2 Int)) (Box Int)) (:: 3 Int)) Int)])
    (void))

  (test-case "sound-elaboration"
    (check-judgment-holds*
     (sound-elaboration 4 (:: 4 Int))
     (sound-elaboration (:: (fun f (x) x) (→ Int Int))
                        (:: (fun f (x) (:: x Int)) (→ Int Int)))
     (sound-elaboration (+ 2 2) (:: (+ (:: 2 Int) (:: 2 Int)) Int))
     (sound-elaboration (make-box 3) (:: (make-box (:: 3 Int)) (Box Int))))
    (void))

  (test-case "erase-types"
    (check-mf-apply* #:is-equal? α=?
     [(erase-types# (:: 3 Int))
      3]
     [(erase-types# (:: (fun f (x) (:: 4 Int)) (→ Int Int)))
      (fun f (x) 4)])
    (void))
)

(module+ test
  (test-case "eval:basic"
    (check-mf-apply*
     [(unload# (eval# 2))
      2]
     [(unload# (eval# ((fun f (x) x) 3)))
      3]
     [(unload# (eval# (if 1 2 3)))
      2]
     [(unload# (eval# (if #false 2 3)))
      3]
     [(unload# (eval# (let (x 2) x)))
      2]
     [(unload# (eval# (car (cons 1 2))))
      1]
     [(unload# (eval# (cdr (cons 1 2))))
      2]
     [(unload# (eval# (make-box 1)))
      (box 1)]
     [(unload# (eval# (unbox (make-box 1))))
      1]
     [(unload# (eval# (+ 2 2)))
      4]
     [(unload# (eval# (- 3 1)))
      2]
     [(unload# (eval# (* 4 4)))
      16]
     [(unload# (eval# (= 2 2)))
      #true]
     [(unload# (eval# (set-box! (make-box 3) 4)))
      4])
  (void)))
