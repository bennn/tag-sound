#lang mf-apply racket/base

;; TODO
;; - no check between typed (trusted codomain)

;; Soundness for Tagged Racket semantics
;; i.e. theorems connecting the typechecker to the reduction semantics

;; Theorems:
;; - program soundness
;;   * if PROGRAM well-typed at TYPE-ENV
;;   * then well-tagged
;;   * and reduces to a VAL-ENV
;;   * and VAL-ENV models TYPE-ENV
;;   * (ignore the σ)
;; - module-soundness
;;   * if Γ ⊢ MODULE well-typed at Γ+
;;   * then well-tagged
;;   * and for any ρ that models Γ
;;   * and module reduces to a ρ+
;;   * and ρ+ models Γ+
;;   * (ignore the σ ... sort of)
;; - require soundness
;;   * if Γ ⊢ require at Γ+
;;   * then for any ρ that models Γ
;;   * requires reduce to ρ
;;   * and ρ+ models Γ+
;; - define soudness
;;   * if Γ ⊢ define at Γ+
;;   * then for any ρ that models Γ
;;   * defines reduce to ρ+
;;   * and ρ+ models Γ+
;; - provide soundness
;;   * if Γ ⊢ provide at Γ+
;;   * then for any ρ that models Γ
;;   * provides reduce to ρ+
;;   * and ρ+ models Γ+
;; - expression soundness
;;   * if Γ ⊢ e : τ
;;   * then forall ρ models Γ
;;   * ⊢ ρ(e) : τ
;;   * either:
;;     + reduces to value, ⊢ v : τ
;;     + diverges, raises value error
;;     + raises type error in untyped code
;;     + raises boundary error
;;   * via progress and preservation
;; - type error soundness
;;   * E[e] where E is typed context
;;     cannot possibly step to TypeError

;; -----------------------------------------------------------------------------

(require
  "eval-common.rkt"
  "eval-tagged.rkt"
  "lang.rkt"
  "grammar.rkt"
  "metafunctions.rkt"
  "typecheck.rkt"
  racket/set
  redex/reduction-semantics
  redex-abbrevs)

;; =============================================================================

(define-judgment-form μTR
  #:mode (sound-eval-program I)
  #:contract (sound-eval-program PROGRAM)
  [
   (well-typed-program PROGRAM TYPE-ENV)
   (sound-eval-module* () () () PROGRAM TYPE-ENV_N σ_N VAL-ENV_N)
   (side-condition ,(equal? (term TYPE-ENV) (term TYPE-ENV_N)))
   (toplevel-value-env-models σ_N VAL-ENV_N TYPE-ENV_N)
   ---
   (sound-eval-program PROGRAM)])

(define-judgment-form μTR
  #:mode (sound-eval-module* I I I I O O O)
  #:contract (sound-eval-module* TYPE-ENV σ VAL-ENV (MODULE ...) TYPE-ENV σ VAL-ENV)
  [
   ---
   (sound-eval-module* TYPE-ENV σ VAL-ENV () TYPE-ENV σ VAL-ENV)]
  [
   (where (MODULE_0 MODULE_rest ...) PROGRAM)
   (sound-eval-module TYPE-ENV_0 σ_0 VAL-ENV_0 MODULE_0 TYPE-ENV_1 σ_1 VAL-ENV_1)
   (sound-eval-module* TYPE-ENV_1 σ_1 VAL-ENV_1 (MODULE_rest ...) TYPE-ENV_N σ_N VAL-ENV_N)
   ---
   (sound-eval-module* TYPE-ENV_0 σ_0 VAL-ENV_0 PROGRAM TYPE-ENV_N σ_N VAL-ENV_N)])

(define-judgment-form μTR
  #:mode (sound-eval-module I I I I O O O)
  #:contract (sound-eval-module TYPE-ENV σ VAL-ENV MODULE TYPE-ENV σ VAL-ENV)
  [
   (where (module M _ REQUIRE ... DEFINE ... PROVIDE) MODULE)
   (where ρ #{require->local-value-env VAL-ENV (REQUIRE ...)})
   (where Γ #{local-type-env-append #{require->local-type-env TYPE-ENV (REQUIRE ...)}
                                    #{define->local-type-env (DEFINE ...)}})
   (sound-eval-define* Γ σ ρ (DEFINE ...) σ_+ ρ_+)
   (where Γ_provide #{local-type-env->provided Γ PROVIDE})
   (where TYPE-ENV_+ #{toplevel-type-env-set TYPE-ENV M Γ_provide})
   (where ρ_provide #{local-value-env->provided ρ_+ PROVIDE})
   (where VAL-ENV_+ #{toplevel-value-env-set VAL-ENV M ρ_provide})
   ---
   (sound-eval-module TYPE-ENV σ VAL-ENV MODULE TYPE-ENV_+ σ_+ VAL-ENV_+)])

(define-judgment-form μTR
  #:mode (sound-eval-define* I I I I O O)
  #:contract (sound-eval-define* Γ σ ρ (DEFINE ...) σ ρ)
  [
   ---
   (sound-eval-define* Γ σ ρ () σ ρ)]
  [
   (sound-eval-define Γ σ ρ DEFINE_0 σ_1 ρ_1)
   (sound-eval-define* Γ σ_1 ρ_1 (DEFINE_rest ...) σ_N ρ_N)
   ---
   (sound-eval-define* Γ σ ρ (DEFINE_0 DEFINE_rest ...) σ_N ρ_N)])

(define-judgment-form μTR
  #:mode (sound-eval-define I I I I O O)
  #:contract (sound-eval-define Γ σ ρ DEFINE σ ρ)
  [
   (where (define x e) UNTYPED-DEFINE)
   (where L UN)
   (sound-eval-expression Γ σ ρ L e TST A_+)
   (where (σ_+ v_+) #{unpack-answer A_+})
   (where ρ_+ #{local-value-env-set ρ x v_+})
   ---
   (sound-eval-define Γ σ ρ UNTYPED-DEFINE σ_+ ρ_+)]
  [
   (where (define x τ e) TYPED-DEFINE)
   (where L TY)
   (sound-eval-expression Γ σ ρ L e τ A_+)
   (where (σ_+ v_+) #{unpack-answer A_+})
   (where ρ_+ #{local-value-env-set ρ x v_+})
   ---
   (sound-eval-define Γ σ ρ TYPED-DEFINE σ_+ ρ_+)])

(define-metafunction μTR
  unpack-answer : A -> [σ v]
  [(unpack-answer Error)
   ,(raise-arguments-error 'sound-eval-expression "not implemented for errors"
     "answer" (term Error))]
  [(unpack-answer [σ v])
   [σ v]])

(define-judgment-form μTR
  #:mode (toplevel-value-env-models I I I)
  #:contract (toplevel-value-env-models σ VAL-ENV TYPE-ENV)
  [
   (same-domain VAL-ENV TYPE-ENV)
   (toplevel-value-env-models-aux σ VAL-ENV TYPE-ENV)
   ---
   (toplevel-value-env-models σ VAL-ENV TYPE-ENV)])

(define-judgment-form μTR
  #:mode (toplevel-value-env-models-aux I I I)
  #:contract (toplevel-value-env-models-aux σ VAL-ENV TYPE-ENV)
  [
   ---
   (toplevel-value-env-models-aux σ () TYPE-ENV)]
  [
   (where (_ Γ_0) #{toplevel-type-env-ref TYPE-ENV M_0})
   (local-value-env-models σ ρ_0 Γ_0)
   (toplevel-value-env-models-aux σ (M:ρ_rest ...) TYPE-ENV)
   ---
   (toplevel-value-env-models-aux σ ((M_0 ρ_0) M:ρ_rest ...) TYPE-ENV)])

(define-metafunction μTR
  sound-eval-expression# : Γ σ ρ L e τ -> A
  [(sound-eval-expression# Γ σ ρ L e τ)
   A
   (judgment-holds (sound-eval-expression Γ σ ρ L e τ A))]
  [(sound-eval-expression# Γ σ ρ L e τ)
   ,(raise-arguments-error 'sound-eval-expression "failed to eval"
     "type env" (term Γ)
     "store" (term σ)
     "value env" (term ρ)
     "lang" (term L)
     "expr" (term e)
     "type" (term τ))])

(define-judgment-form μTR
  #:mode (sound-eval-expression I I I I I I O)
  #:contract (sound-eval-expression Γ σ ρ L e τ A)
  [
   (well-typed-expression/TST Γ e τ)
   (where κ #{type->tag τ})
   (tagged-completion Γ e κ e_+)
   (well-tagged-expression Γ e_+ κ)
   (local-value-env-models σ ρ Γ)
   ;; Do checked evaluation
   (where Σ_0 #{load-expression L σ ρ e})
   (where A #{sound-step* Σ_0 κ})
   ---
   (sound-eval-expression Γ σ ρ L e τ A)])

(define-metafunction μTR
  sound-step* : Σ κ -> A
  [(sound-step* Σ κ)
   ,(if (term boolean_+)
      (term #{sound-step* A_+ κ})
      (term A_+))
   (judgment-holds (sound-step Σ κ A_+ boolean_+))]
  [(sound-step* A κ)
   ,(raise-arguments-error 'sound-step* "undefined for arguments"
      "config" (term A)
      "tag" (term κ))])

(define-judgment-form μTR
  #:mode (sound-step I I O O)
  #:contract (sound-step Σ κ A boolean)
  [
   (well-tagged-config Σ κ)
   (where (A boolean) ,(do-single-step (term Σ)))
   (well-tagged-answer Σ A κ)
   ---
   (sound-step Σ κ A boolean)])

(define-metafunction μTR
  sound-step# : Σ κ -> [A boolean]
  [(sound-step# Σ κ)
   (A boolean)
   (judgment-holds (sound-step Σ κ A boolean))]
  [(sound-step# Σ κ)
   ,(raise-arguments-error 'sound-step "undefined for arguments"
     "state" (term Σ)
     "tag" (term κ))])

;; Apply reduction relation, make sure get 1 thing out of it
(define (do-single-step Σ)
  (define A* (apply-reduction-relation single-step Σ))
  (cond
   [(null? A*)
    (list Σ #false)]
   [(not (null? (cdr A*)))
    (raise-arguments-error 'do-single-step "non-deterministic step"
      "config" Σ
      "next configs" A*)]
   [else
    (define Σ+ (car A*))
    (list Σ+ (not (redex-match? μTR Error Σ+)))]))

;; TODO ignores first argument ... either remove or stop ignoring.
;; (original idea was to check "no type errors from typed context",
;;  but maybe we show that with a different theorem)
(define-judgment-form μTR
  #:mode (well-tagged-answer I I I)
  #:contract (well-tagged-answer Σ A κ)
  [
   ---
   (well-tagged-answer _ BoundaryError _)]
  [
   ---
   (well-tagged-answer _ TypeError _)]
  [
   (well-tagged-config Σ_+ κ)
   ---
   (well-tagged-answer _ Σ_+ κ)])

(define-judgment-form μTR
  #:mode (well-tagged-config I I)
  #:contract (well-tagged-config Σ κ)
  [
   (where L UN)
   (WK σ () e TST)
   ---
   (well-tagged-config (L σ e) TST)]
  [
   (where L TY)
   (WK σ () e κ)
   ---
   (well-tagged-config (L σ e) κ)])

(define-judgment-form μTR
  #:mode (WK I I I I)
  #:contract (WK σ Γ e κ)
  [
   (or-TST Nat κ)
   --- T-Nat
   (WK σ Γ natural κ)]
  [
   (or-TST Int κ)
   --- T-Int
   (WK σ Γ integer κ)]
  [
   (where (_ τ) #{local-type-env-ref Γ x})
   (or-TST #{type->tag τ} κ)
   --- T-Var
   (WK σ Γ x κ)]
  [
   (or-TST → κ)
   (where (→ τ_dom τ_cod) #{coerce-arrow-type τ_fun})
   (tag-of τ_cod κ_cod)
   (where Γ_fun #{local-type-env-set Γ x_fun τ_fun})
   (where Γ_x #{local-type-env-set Γ_fun x_arg τ_dom})
   (WK σ Γ_x e κ_cod)
   --- T-FunT
   (WK σ Γ (fun x_fun τ_fun (x_arg) e) κ)]
  [
   (or-TST → κ)
   (where Γ_f #{local-type-env-set Γ x_f (→ TST TST)})
   (where Γ_x #{local-type-env-set Γ_f x_arg TST})
   (WK σ Γ_x e_body TST)
   --- T-FunU
   (WK σ Γ (fun x_f (x_arg) e_body) κ)]
  [
   (where (vector τ x) v)
   (WK σ Γ #{unload-store/expression v σ} τ)
   --- T-VecValT
   (WK σ Γ v κ)]
  [
   (where (vector x) v)
   (WK σ Γ #{unload-store/expression v σ} TST)
   --- T-VecValU
   (WK σ Γ v κ)]
  [
   (not-VV σ (vector τ_vec e ...))
   (or-TST #{type->tag τ_vec} κ)
   (WK σ Γ e TST) ...
   --- T-VecT
   (WK σ Γ (vector τ_vec e ...) κ)]
  [
   (or-TST Vector κ)
   (not-VV σ (vector e ...))
   (WK σ Γ e TST) ...
   --- T-VecU
   (WK σ Γ (vector e ...) κ)]
  [
   (or-TST List κ)
   (WK σ Γ e_0 TST)
   (WK σ Γ e_1 TST)
   --- T-Cons
   (WK σ Γ (cons e_0 e_1) κ)]
  [
   (or-TST List κ)
   --- T-Nil
   (WK σ Γ nil κ)]
  [
   (WK σ Γ e_fun →)
   (WK σ Γ e_arg TST)
   --- T-App
   (WK σ Γ (e_fun e_arg) TST)]
  [
   (WK σ Γ e_0 Int)
   (WK σ Γ e_1 κ)
   (WK σ Γ e_2 κ)
   --- T-Ifz
   (WK σ Γ (ifz e_0 e_1 e_2) κ)]
  [
   (or-TST Int κ)
   (WK σ Γ e_0 Int)
   (WK σ Γ e_1 Int)
   --- T-PlusT0
   (WK σ Γ (+ e_0 e_1) κ)]
  [
   (WK σ Γ e_0 Nat)
   (WK σ Γ e_1 Nat)
   --- T-PlusT1
   (WK σ Γ (+ e_0 e_1) Nat)]
  [
   (or-TST Int κ)
   (WK σ Γ e_0 Int)
   (WK σ Γ e_1 Int)
   --- T-MinusT
   (WK σ Γ (- e_0 e_1) κ)]
  [
   (or-TST Int κ)
   (WK σ Γ e_0 Int)
   (WK σ Γ e_1 Int)
   --- T-TimesT0
   (WK σ Γ (* e_0 e_1) κ)]
  [
   (WK σ Γ e_0 Nat)
   (WK σ Γ e_1 Nat)
   --- T-TimesT1
   (WK σ Γ (* e_0 e_1) Nat)]
  [
   (or-TST Int κ)
   (WK σ Γ e_0 Int)
   (WK σ Γ e_1 Int)
   --- T-DivideT0
   (WK σ Γ (% e_0 e_1) κ)]
  [
   (WK σ Γ e_0 Nat)
   (WK σ Γ e_1 Nat)
   --- T-DivideT1
   (WK σ Γ (% e_0 e_1) Nat)]
  [
   (WK σ Γ e_vec Vector)
   (WK σ Γ e_i Int)
   --- T-Ref
   (WK σ Γ (vector-ref e_vec e_i) TST)]
  [
   (WK σ Γ e_vec Vector)
   (WK σ Γ e_i Int)
   (WK σ Γ e_val κ)
   --- T-Set
   (WK σ Γ (vector-set! e_vec e_i e_val) κ)]
  [
   (WK σ Γ e List)
   --- T-First
   (WK σ Γ (first e) TST)]
  [
   (or-TST List κ)
   (WK σ Γ e List)
   --- T-Rest
   (WK σ Γ (rest e) κ)]
  [
   (WK σ Γ e κ)
   --- T-Union
   (WK σ Γ e (U κ_0 ... κ κ_1 ...))]
  [
   (WK σ Γ e TST)
   --- T-Tag
   (WK σ Γ (tag? κ e) κ)])

(define-judgment-form μTR
  #:mode (local-value-env-models I I I)
  #:contract (local-value-env-models σ ρ Γ)
  [
   (same-domain ρ Γ) ;; it's OK if Γ is missing some entries
   (local-value-env-models-aux σ ρ Γ)
   ---
   (local-value-env-models σ ρ Γ)])

(define-judgment-form μTR
  #:mode (local-value-env-models-aux I I I)
  #:contract (local-value-env-models-aux σ ρ Γ)
  [
   ---
   (local-value-env-models-aux σ () Γ)]
  [
   (where (x_0 κ) #{local-type-env-ref Γ x_0})
   (WK σ Γ v_0 κ)
   (local-value-env-models-aux σ (x:v_rest ...) Γ)
   ---
   (local-value-env-models-aux σ ((x_0 v_0) x:v_rest ...) Γ)])

(define-judgment-form μTR
  #:mode (not-VV I I)
  #:contract (not-VV σ e)
  [
   (side-condition ,(not (judgment-holds (VV σ e))))
   ---
   (not-VV σ e)])

(define-judgment-form μTR
  #:mode (VV I I)
  #:contract (VV σ e)
  [
   (where (x _) #{unsafe-env-ref σ x #false})
   ---
   (VV σ (vector x))]
  [
   (where (x _) #{unsafe-env-ref σ x #false})
   ---
   (VV σ (vector τ x))])

;; =============================================================================
;
;(module+ test
;  (require rackunit)
;
;  (test-case "not-VV"
;    (check-judgment-holds*
;     (not-VV () (vector (Vectorof Int) 1 2))))
;
;  (test-case "WK"
;    (check-judgment-holds*
;     (WK () () 4 Nat)
;     (WK () () 4 TST)
;     (WK () () -4 Int)
;     (WK () () -4 TST)
;     (WK () ((x Int)) x Int)
;     (WK () ((x TST)) x TST)
;     (WK () () (fun f (→ Nat Nat) (x) x) (→ Nat Nat))
;     (WK () () (fun f (x) x) TST)
;     (WK () () (vector (Vectorof Int) 1 2) (Vectorof Int))
;     (WK () () (vector 1 2) TST)
;     (WK () () (cons 1 nil) (Listof Nat))
;     (WK () () (cons 1 nil) TST)
;     (WK () () nil (Listof Nat))
;     (WK () () nil TST)
;     (WK () ((f (→ Int Int))) (f -6) Int)
;     (WK () ((f TST)) (f f) TST)
;     (WK () () (3 3) TST)
;     (WK () () (ifz 0 1 2) Nat)
;     (WK () () (ifz nil nil nil) TST)
;     (WK () () (+ -1 2) Int)
;     (WK () () (+ 3 2) Nat)
;     (WK () () (+ 4 4) TST)
;     (WK () () (+ nil nil) TST)
;     (WK () () (- 3 3) Int)
;     (WK () () (- 3 3) TST)
;     (WK () () (- 3 nil) TST)
;     (WK () () (* 3 -3) Int)
;     (WK () () (* 3 3) Nat)
;     (WK () () (* 3 3) TST)
;     (WK () () (* nil 4) TST)
;     (WK () () (% -6 2) Int)
;     (WK () () (% 6 2) Nat)
;     (WK () () (% 6 2) TST)
;     (WK () () (% nil nil) TST)
;     (WK () () (vector-ref (vector (Vectorof Int) 2 3) 0) Int)
;     (WK () () (vector-ref (vector 3) 0) TST)
;     (WK () () (vector-set! (vector (Vectorof Int) 2 3) 0 -3) Int)
;     (WK () () (vector-set! (vector 2) 0 nil) TST)
;     (WK () () (first nil) Nat)
;     (WK () () (first (cons 1 nil)) Int)
;     (WK () () (first 3) TST)
;     (WK () () (rest nil) (Listof Int))
;     (WK () () (rest (cons 1 nil)) (Listof Int))
;     (WK () () (rest 4) TST)
;     (WK () () 4 (U Nat (→ Nat Nat)))
;     (WK () () (fun f (∀ (α) (→ α α)) (x) x) (∀ (α) (→ α α)))
;     (WK () () (mon-fun (→ Nat Nat) (fun f (x) 3)) (→ Nat Nat))
;     (WK () () (mon-fun (→ Nat Nat) (fun f (→ Nat Nat) (x) 3)) TST)
;     (WK ((qq (1 2))) () (mon-vector (Vectorof Int) (vector qq)) (Vectorof Int))
;     (WK ((qq (2))) () (mon-vector (Vectorof Int) (vector (Vectorof Int) qq)) TST)
;     (WK () () (check Int (+ 3 3)) Int)
;     (WK () () (protect Int (+ 3 3)) TST)
;    )
;
;    (check-not-judgment-holds*
;     (WK () () -4 Nat)
;     (WK () () nil Int)
;     (WK () ((x Int)) x TST)
;     (WK () () (fun f (x) x) (→ Nat Nat)) ;; missing type annotation
;     (WK () () (vector 1 2) (Vectorof Nat))
;     (WK () ((f (→ Int Int))) (f -6) TST)
;     (WK () () (ifz nil 1 2) Nat)
;     (WK () () (- 3 0) Nat)
;     (WK () () (* -3 -3) Nat)
;     (WK () () (vector-ref (vector 3) 0) Int)
;     (WK () () (vector-set! (vector Nat 2 3) 0 -3) Int)
;     (WK () () (check Int (+ 3 3)) TST)
;     (WK () () (protect Int (+ 3 3)) Int)
;    )
;  )
;
;  (test-case "local-value-env-models"
;    (check-judgment-holds*
;     (local-value-env-models () () ())
;     (local-value-env-models () ((x 4)) ((x Int)))
;     (local-value-env-models () ((x 4) (y -1)) ((x Int) (y Int)))
;     (local-value-env-models () ((x 4) (y -1)) ((y Int) (x Int)))
;     (local-value-env-models () ((x nil)) ((x (Listof Nat))))
;     (local-value-env-models () ((x nil)) ((x TST)))
;     (local-value-env-models () ((x (fun f (z) z))) ((x TST)))
;     (local-value-env-models
;       ()
;       ((x (fun f (→ Nat Nat) (z) (+ z 3))))
;       ((x (→ Nat Nat))))
;     (local-value-env-models
;       ()
;       ((x (mon-fun (→ Nat Nat) (fun f (z) (+ z 3)))))
;       ((x (→ Nat Nat))))
;    )
;
;    (check-not-judgment-holds*
;     (local-value-env-models () () ((x Int)))
;     (local-value-env-models () ((x 4)) ((y Int)))
;     (local-value-env-models () ((x 4) (y -1)) ((x Int) (y Nat)))
;     (local-value-env-models () ((x (fun f (z) (+ z 3)))) ((x (→ Nat Nat))))
;    )
;  )
;
;  (test-case "well-typed-config"
;    (check-judgment-holds*
;     (well-typed-config (UN () (+ nil 2)) TST)
;     (well-typed-config (TY () (+ 2 2)) Nat)
;     (well-typed-config (TY ((qq (1 2))) (vector (Vectorof Nat) qq))
;                        (Vectorof Nat))
;     (well-typed-config (UN () (* 4 4)) TST)
;    )
;
;    (check-not-judgment-holds*
;     (well-typed-config (TY () (+ nil 2)) Int)
;     (well-typed-config (TY ((qq (1 -2))) (vector (Vectorof Nat) qq)) (Vectorof Nat))
;    )
;  )
;
;  (test-case "do-single-step"
;    (check-equal?
;      (do-single-step (term (UN () (* 4 4))))
;      (term ((UN () 16) #true)))
;    (check-equal?
;      (do-single-step (term (UN () 16)))
;      (term ((UN () 16) #false)))
;  )
;
;  (test-case "well-tagged-answer"
;    (define-term my-config (TY () 42))
;    (check-true (redex-match? μTR Σ (term my-config)))
;    (check-judgment-holds*
;     (well-tagged-answer my-config (BE Int nil) Int)
;     (well-tagged-answer my-config DivisionByZero Int)
;     (well-tagged-answer my-config EmptyList TST)
;     (well-tagged-answer my-config (TE 4 (Listof Int)) TST)
;     (well-tagged-answer my-config (TE 4 (Listof Int)) (Listof Int))
;     (well-tagged-answer my-config (UN () (+ 2 2)) TST)
;     (well-tagged-answer my-config (UN () (+ 2 nil)) TST)
;     (well-tagged-answer my-config (TY () (+ 2 2)) Int)
;     (well-tagged-answer my-config (UN () 16) TST)
;    )
;
;    (check-not-judgment-holds*
;     (well-tagged-answer my-config (UN () (+ 2 2)) Int)
;    )
;  )
;
;  (test-case "sound-step"
;    (check-mf-apply*
;     ((sound-step# (TY () (+ 4 4)) Int)
;      ((TY () 8) #true))
;     ((sound-step# (TY () (check Int (+ 2 2))) Int)
;      ((TY () (check Int 4)) #true))
;     ((sound-step# (TY () (check Int (+ 2 nil))) Int)
;      ((TE nil "integer?") #false))
;     ((sound-step# (UN () (* 4 4)) TST)
;      ((UN () 16) #true))
;     ((sound-step# (UN () 16) TST)
;      ((UN () 16) #false))
;    )
;  )
;
;  (test-case "sound-eval-expression"
;    (check-mf-apply*
;     ((sound-eval-expression# () () () TY (+ 2 2) Int)
;      (TY () 4))
;     ((sound-eval-expression# () () () UN (* 4 4) TST)
;      (UN () 16))
;     ((sound-eval-expression# () () () UN (* 4 nil) TST)
;      (TE nil "integer?"))
;     ((sound-eval-expression# () () () UN (4 4) TST)
;      (TE 4 "procedure?"))
;     ((sound-eval-expression# ((f (→ Int Nat))) () ((f (mon-fun (→ Int Nat) (fun f (x) x)))) TY (f 42) Nat)
;      (TY () 42))
;     ((sound-eval-expression# ((f (→ Int Nat))) () ((f (mon-fun (→ Int Nat) (fun f (x) (cons 1 nil))))) TY (f 42) Nat)
;      (BE Nat (cons 1 nil)))
;     ((sound-eval-expression# ((f (→ Int Nat))) () ((f (mon-fun (→ Int Nat) (fun f (x) (x x))))) TY (f 42) Nat)
;      (TE 42 "procedure?"))
;    )
;
;    ;; `check` is not part of the source language
;    (check-exn exn:fail:contract?
;      (λ () (term (sound-eval-expression# () () () TY (check Int nil) Int))))
;  )
;
;  (test-case "sound-eval-program"
;    (check-judgment-holds*
;     (sound-eval-program
;      ((module M0 untyped
;        (define f (fun a (x) (fun b (y) (fun c (z) (+ (+ a b) c)))))
;        (provide f))
;       (module M1 typed
;        (require M0 ((f (→ Int (→ Int Int)))))
;        (provide f))
;       (module M2 untyped
;        (require M1 f)
;        (define f2 (f 2))
;        (define f23 (f2 3))
;        (provide))))
;    )
;  )
;
;  (test-case "toplevel-value-env-models"
;  )
;
;  (test-case ""
;  )
;
;)