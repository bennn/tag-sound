#lang mf-apply racket/base

;; Forgetful lazy natural embedding
;; ... same soundness
;;     fewer errors
;;     "contracts exist to make partial operations safe"

(require
  "little-lazy.rkt"
  "little-mixed.rkt"
  (only-in redex-abbrevs
    make--->*)
  redex/reduction-semantics)

(module+ test
  (require rackunit))

;; =============================================================================

(define-extended-language LM-forgetful
  LM-lazy)

(define (LM-forgetful=? t0 t1)
  (alpha-equivalent? LM-forgetful t0 t1))

(define-metafunction LM-forgetful
  static->dynamic : τ v -> A
  [(static->dynamic τ v)
   #{dynamic->static τ v}])

(define-metafunction LM-forgetful
  dynamic->static : τ v -> A
  [(dynamic->static Nat natural)
   natural]
  [(dynamic->static Nat v)
   (Boundary-Error v "Nat")]
  [(dynamic->static Int integer)
   integer]
  [(dynamic->static Int v)
   (Boundary-Error v "Int")]
  [(dynamic->static (× τ_0 τ_1) (mon (× _ _) v))
   (mon (× τ_0 τ_1) v)]
  [(dynamic->static (× τ_0 τ_1) (× v_0 v_1))
   (mon (× τ_0 τ_1) (× v_0 v_1))]
  [(dynamic->static (× τ_0 τ_1) v)
   (Boundary-Error v ,(format "~a" (term (× τ_0 τ_1))))]
  [(dynamic->static (→ τ_dom-new τ_cod-new)
                    (mon (→ _ _) Λ))
   (mon (→ τ_dom-new τ_cod-new) Λ)]
  [(dynamic->static (→ τ_dom τ_cod) Λ)
   (mon (→ τ_dom τ_cod) Λ)]
  [(dynamic->static (→ τ_dom τ_cod) v)
   (Boundary-Error v ,(format "~a" (term (→ τ_dom τ_cod))))])

;; -----------------------------------------------------------------------------

;; hang on this monitor stuff, can I just do this ... ughm 
;; without monitors at all?
;; just use the τ on a lambda? thats more whats actually happening

(define dyn-step
  (reduction-relation LM-forgetful
    #:domain A
    (--> (v_0 v_1)
         e_subst
         E-App-0
         (where (λ (x) e) v_0)
         (where e_subst (substitute e x v_1)))
    (--> (v_0 v_1)
         e_subst
         E-App-1
         (where (mon _ (λ (x) e)) v_0)
         (where e_subst (substitute e x v_1)))
    (--> (v_0 v_1)
         (static τ_cod ((λ (x : τ_dom) e) v_+))
         E-App-2.0
         (where (mon (→ _ τ_cod) (λ (x : τ_dom) e)) v_0)
         (where v_+ #{static->dynamic τ_dom v_1}))
    (--> (v_0 v_1)
         BE
         E-App-2.1
         (where (mon (→ _ τ_cod) (λ (x : τ_dom) e)) v_0)
         (where BE #{static->dynamic τ_dom v_1}))
    (--> (v_0 v_1)
         (Type-Error v_0 "procedure?")
         E-App-3
         (where #false (procedure? v_0)))
    (--> (+ v_0 v_1)
         integer_2
         E-+-0
         (where integer_0 v_0)
         (where integer_1 v_1)
         (where integer_2 ,(+ (term integer_0) (term integer_1))))
    (--> (+ v_0 v_1)
         (Type-Error ,(if (redex-match? LM-forgetful integer (term v_0)) (term v_1) (term v_0)) "integer")
         E-+-1
         (side-condition (not (and (redex-match? LM-forgetful integer (term v_0))
                                   (redex-match? LM-forgetful integer (term v_1))))))
    (--> (/ v_0 v_1)
         integer_2
         E-/-0
         (where integer_0 v_0)
         (where integer_1 v_1)
         (side-condition (not (zero? (term integer_1))))
         (where integer_2 ,(quotient (term integer_0) (term integer_1))))
    (--> (/ v_0 v_1)
         (Boundary-Error v_1 "non-zero integer")
         E-/-1
         (where integer_0 v_0)
         (where integer_1 v_1)
         (side-condition (zero? (term integer_1))))
    (--> (/ v_0 v_1)
         (Type-Error ,(if (redex-match? LM-forgetful integer (term v_0)) (term v_1) (term v_0)) "integer")
         E-/-2
         (side-condition (not (and (redex-match? LM-forgetful integer (term v_0))
                                   (redex-match? LM-forgetful integer (term v_1))))))
    (--> (fst v)
         v_0
         E-fst-0
         (where (× v_0 v_1) v))
    (--> (fst v)
         #{static->dynamic τ_0 v_0}
         E-fst-1
         (where (mon (× τ_0 τ_1) (× v_0 v_1)) v))
    (--> (fst v)
         (Type-Error v "pair?")
         E-fst-2
         (where #false #{pair? v}))
    (--> (snd v)
         v_1
         E-snd-0
         (where (× v_0 v_1) v))
    (--> (snd v)
         #{static->dynamic τ_1 v_1}
         E-snd-1
         (where (mon (× τ_0 τ_1) (× v_0 v_1)) v))
    (--> (snd v)
         (Type-Error v "pair?")
         E-snd-2
         (where #false #{pair? v}))))

(define sta-step
  (reduction-relation LM-forgetful
    #:domain A
    (--> (v_0 v_1)
         e_subst
         E-App-0
         (where (λ (x : τ) e) v_0)
         (where e_subst (substitute e x v_1)))
    (--> (v_0 v_1)
         (maybe-in-hole ((λ (x : τ_dom) e) hole) A)
         E-App-1
         (where (mon (→ _ τ_cod) (λ (x : τ_dom) e)) v_0)
         (where A #{dynamic->static τ_dom v_1}))
    (--> (v_0 v_1)
         (dynamic τ_cod ((λ (x) e) (static τ_dom v_1)))
         E-App-2
         (where (mon (→ τ_dom τ_cod) (λ (x) e)) v_0))
    (--> (+ v_0 v_1)
         integer_2
         E-+
         (where integer_0 v_0)
         (where integer_1 v_1)
         (where integer_2 ,(+ (term integer_0) (term integer_1))))
    (--> (/ v_0 v_1)
         integer_2
         E-/-0
         (where integer_0 v_0)
         (where integer_1 v_1)
         (side-condition (not (zero? (term integer_1))))
         (where integer_2 ,(quotient (term integer_0) (term integer_1))))
    (--> (/ v_0 v_1)
         (Boundary-Error v_1 "non-zero integer")
         E-/-1
         (where integer_0 v_0)
         (where integer_1 v_1)
         (side-condition (zero? (term integer_1))))
    (--> (fst v)
         v_0
         E-fst-0
         (where (× v_0 v_1) v))
    (--> (fst v)
         #{dynamic->static τ_0 v_0}
         E-fst-1
         (where (mon (× τ_0 τ_1) (× v_0 v_1)) v))
    (--> (snd v)
         v_1
         E-snd-0
         (where (× v_0 v_1) v))
    (--> (snd v)
         #{dynamic->static τ_1 v_1}
         E-snd-1
         (where (mon (× τ_0 τ_1) (× v_0 v_1)) v))))

(module+ test
  (test-case "dyn-step"
    (check LM-forgetful=?
      (apply-reduction-relation dyn-step
        (term ((mon (→ Int Int) (λ (x : Int) x)) 4)))
      (list (term (static Int ((λ (x : Int) x) 4)))))
    (check-true (redex-match? LM-forgetful BE
      (car (apply-reduction-relation dyn-step
             (term ((mon (→ Int Int) (λ (x : Int) x)) (× 4 4)))))))
  )

  (test-case "sta-step"
    (check LM-forgetful=?
      (apply-reduction-relation sta-step
        (term ((mon (→ Nat Int) (λ (x : Int) x)) 4)))
      (list (term ((λ (x : Int) x) 4))))
    (check-true (redex-match? LM-forgetful BE
      (car (apply-reduction-relation sta-step
             (term ((mon (→ Nat Int) (λ (x : Int) x)) (× 4 4)))))))
  )
)

;; what's the point of `dynamic->static t v`
;; when could just do `(dynamic t v)` because that will reduce in one
;;  step to v again, or error, using dynamic->static anyway . . .
;; ok the problem is `(dynamic t v)` needs to be well-typed,
;;  so v needs to be well-dyn
;;  but v might NOT be a dynamic value, might be a typed value!!!!

(define dyn-boundary-step
  (reduction-relation LM-forgetful
    #:domain A
    (--> (in-hole E (static τ v))
         (maybe-in-hole E A)
         E-Cross-Boundary
         (where A (static->dynamic τ v)))
    (--> (in-hole E (static τ e))
         (in-hole E (static τ e_+))
         E-Advance-0
         (where (e_+) ,(apply-reduction-relation sta-boundary-step (term e))))
    (--> (in-hole E (static τ e))
         BE
         E-Advance-1
         (where (BE) ,(apply-reduction-relation sta-boundary-step (term e))))
    (--> (in-hole E e)
         (maybe-in-hole E A)
         E-Dyn
         (where #false (boundary? e))
         (where (A) ,(apply-reduction-relation dyn-step (term e))))))

(define sta-boundary-step
  (reduction-relation LM-forgetful
    #:domain A
    (--> (in-hole E (dynamic τ v))
         (maybe-in-hole E A)
         E-Cross-Boundary
         (where A (dynamic->static τ v)))
    (--> (in-hole E (dynamic τ e))
         (in-hole E (dynamic τ e_+))
         E-Advance-0
         (where (e_+) ,(apply-reduction-relation dyn-boundary-step (term e))))
    (--> (in-hole E (dynamic τ e))
         BE
         E-Advance-1
         (where (BE) ,(apply-reduction-relation dyn-boundary-step (term e))))
    (--> (in-hole E e)
         (maybe-in-hole E A)
         E-Sta
         (where #false (boundary? e))
         (where (A) ,(apply-reduction-relation sta-step (term e))))))

(module+ test

  (test-case "dyn-boundary-step"
    (check-equal? (apply-reduction-relation dyn-boundary-step (term (+ 2 2)))
                  '(4))
    (check-equal? (apply-reduction-relation dyn-boundary-step (term (static Int 3)))
                  '(3))
    (check-true (redex-match? LM-forgetful A
      (term (in-hole hole (static Int (+ 1 2))))))
    (check-equal? (apply-reduction-relation dyn-boundary-step (term (static Int (+ 1 2))))
                  (list (term (static Int 3))))
    (check-true (redex-match? LM-forgetful BE
      (car (apply-reduction-relation dyn-boundary-step (term (/ 1 0))))))
    (check-true (redex-match? LM-forgetful BE
      (car (apply-reduction-relation dyn-boundary-step (term (static Int (/ 1 0)))))))

    (check-true (stuck? dyn-boundary-step (term (dynamic Int 3))))

    (check-equal? (apply-reduction-relation dyn-boundary-step
                    (term (static Nat ((λ (x : Nat) (+ x x)) (dynamic Nat 7)))))
                  (list (term (static Nat ((λ (x : Nat) (+ x x)) 7)))))
    (check-equal? (apply-reduction-relation dyn-boundary-step
                    (term (static Nat ((λ (x : Nat) (+ x x)) 7))))
                  (list (term (static Nat (+ 7 7)))))
    (check-equal? (apply-reduction-relation dyn-boundary-step
                    (term (static Nat (+ 7 7))))
                  (list (term (static Nat 14))))
    (check-equal? (apply-reduction-relation dyn-boundary-step
                    (term (static (× Nat Int) (× 1 -1))))
                  (list (term (mon (× Nat Int) (× 1 -1)))))
  )

  (test-case "sta-boundary-step"
    (check-equal? (apply-reduction-relation sta-boundary-step (term (+ 2 2)))
                  '(4))
    (check-equal? (apply-reduction-relation sta-boundary-step (term (dynamic Nat 3)))
                  '(3))
    (check-equal? (apply-reduction-relation sta-boundary-step (term (dynamic Nat (+ 1 2))))
                  (list (term (dynamic Nat 3))))
    (check-true (redex-match? LM-forgetful BE
      (car (apply-reduction-relation sta-boundary-step (term (/ 1 0))))))
    (check-true (redex-match? LM-forgetful BE
      (car (apply-reduction-relation sta-boundary-step (term (dynamic Int (/ 1 0)))))))
    (check-true (redex-match? LM-forgetful BE
      (car (apply-reduction-relation sta-boundary-step (term (dynamic Int (λ (x) x)))))))
    (check-true (redex-match? LM-forgetful BE
      (car (apply-reduction-relation sta-boundary-step (term (dynamic Int (× 0 0)))))))
    (check-true (redex-match? LM-forgetful BE
      (car (apply-reduction-relation sta-boundary-step (term (dynamic Nat -1))))))

    (check-true (stuck? sta-boundary-step (term (static Int 3))))
    (check-equal? (apply-reduction-relation sta-boundary-step
                    (term (dynamic (× Nat Int) (× 1 -1))))
                  (list (term (mon (× Nat Int) (× 1 -1)))))
  )
)

;; -----------------------------------------------------------------------------

(define-judgment-form LM-forgetful
  #:mode (well-dyn/forgetful I I)
  #:contract (well-dyn/forgetful Γ e)
  [
   --- D-Int
   (well-dyn/forgetful Γ integer)]
  [
   (well-dyn/forgetful Γ e_0)
   (well-dyn/forgetful Γ e_1)
   --- D-Pair
   (well-dyn/forgetful Γ (× e_0 e_1))]
  [
   (where Γ_x (x Γ))
   (well-dyn/forgetful Γ_x e)
   --- D-Fun
   (well-dyn/forgetful Γ (λ (x) e))]
  [
   (where #true (type-env-contains Γ x))
   --- D-Var
   (well-dyn/forgetful Γ x)]
  [
   (well-dyn/forgetful Γ e_0)
   (well-dyn/forgetful Γ e_1)
   --- D-App
   (well-dyn/forgetful Γ (e_0 e_1))]
  [
   (well-dyn/forgetful Γ e_0)
   (well-dyn/forgetful Γ e_1)
   --- D-Binop
   (well-dyn/forgetful Γ (BINOP e_0 e_1))]
  [
   (well-dyn/forgetful Γ e)
   --- D-Unop
   (well-dyn/forgetful Γ (UNOP e))]
  [
   (well-typed/forgetful Γ e τ)
   --- D-Static
   (well-dyn/forgetful Γ (static τ e))]
  [
   ;; TRUST ME
   --- D-Mon
   (well-dyn/forgetful Γ (mon τ v))])

(define-judgment-form LM-lazy
  #:mode (well-typed/forgetful I I I)
  #:contract (well-typed/forgetful Γ e τ)
  [
   (infer-type Γ e τ_infer)
   (subtype τ_infer τ)
   ---
   (well-typed/forgetful Γ e τ)])

(define-judgment-form LM-lazy
  #:mode (infer-type I I O)
  #:contract (infer-type Γ e τ)
  [
   (where #true #{negative? integer})
   --- I-Int
   (infer-type Γ integer Int)]
  [
   --- I-Nat
   (infer-type Γ natural Nat)]
  [
   (infer-type Γ e_0 τ_0)
   (infer-type Γ e_1 τ_1)
   --- I-Pair
   (infer-type Γ (× e_0 e_1) (× τ_0 τ_1))]
  [
   (where Γ_x ((x : τ_0) Γ))
   (infer-type Γ_x e τ_1)
   --- I-Fun
   (infer-type Γ (λ (x : τ_0) e) (→ τ_0 τ_1))]
  [
   (where τ (type-env-ref Γ x))
   --- I-Var
   (infer-type Γ x τ)]
  [
   (infer-type Γ e_0 (→ τ_dom τ_cod))
   (infer-type Γ e_1 τ_1)
   (subtype τ_1 τ_dom)
   --- I-App
   (infer-type Γ (e_0 e_1) τ_cod)]
  [
   (infer-type Γ e_0 τ_0)
   (infer-type Γ e_1 τ_1)
   (subtype τ_0 Int)
   (subtype τ_1 Int)
   (where τ (type-join τ_0 τ_1))
   --- I-+
   (infer-type Γ (+ e_0 e_1) τ)]
  [
   (infer-type Γ e_0 τ_0)
   (infer-type Γ e_1 τ_1)
   (subtype τ_0 Int)
   (subtype τ_1 Int)
   (where τ (type-join τ_0 τ_1))
   --- I-/
   (infer-type Γ (/ e_0 e_1) τ)]
  [
   (infer-type Γ e (× τ_0 τ_1))
   --- I-Fst
   (infer-type Γ (fst e) τ_0)]
  [
   (infer-type Γ e (× τ_0 τ_1))
   --- I-Snd
   (infer-type Γ (snd e) τ_1)]
  [
   (well-dyn/forgetful Γ e)
   --- I-Dynamic
   (infer-type Γ (dynamic τ e) τ)]
  [
   ;; TRUST ME
   --- I-Mon
   (infer-type Γ (mon τ v) τ)])

(module+ test
  (test-case "well-dyn"
    (check-true (judgment-holds
      (well-dyn/forgetful ()
        (static (→ (→ Nat (→ Int Nat)) Int)
          ((dynamic (→ (→ Nat Int) (→ (→ Nat (→ Nat Int)) Nat)) (λ (bs) bs))
           (λ (C : Int) C))))))
    (check-true (judgment-holds
      (well-dyn/forgetful ()
        (mon (→ Int Int) (λ (b«43726») 0)))))
    (check-true (judgment-holds
      (well-dyn/forgetful ()
        (mon (→ (× Int Int) (→ Nat Int))
             (λ (p) (λ (Okp) 2))))))
  )

  (test-case "well-typed"
    (check-true (judgment-holds (subtype (→ Int Nat) (→ Nat Int))))
    (check-true (judgment-holds
      (subtype (→ Nat Nat) (→ Nat Int))))
    (check-true (judgment-holds
      (subtype (→ (→ Nat (→ Nat Int)) Nat)
               (→ (→ Nat (→ Int Nat)) Int))))
    (check-true (judgment-holds
      (subtype
        (→ (→ Nat Int) Nat)
        (→ (→ Nat Nat) Nat))))
    (check-true (judgment-holds
      (subtype
        (× (→ (→ Nat Int) Nat) (→ Int Nat))
        (× (→ (→ Nat Nat) Nat) (→ Nat Int)))))
    (check-true (judgment-holds
      (well-typed/forgetful ()
        ((dynamic (→ (→ Nat Int) (→ (→ Nat (→ Nat Int)) Nat)) (λ (bs) bs))
         (λ (C : Int) C))
        (→ (→ Nat (→ Int Nat)) Int))))

    (check-false (judgment-holds
      (well-typed/forgetful ()
        (mon (→ Nat Int) (λ (C : Int) C))
        (→ (→ Nat (→ Nat Int)) Int))))
    (check-true (judgment-holds
      (well-typed/forgetful ()
        (dynamic (× (→ (→ Nat Int) Nat) (→ Int Nat)) 3)
        (× (→ (→ Nat Nat) Nat)
           (→ Nat Int)))))
    (check-true (judgment-holds
      (well-typed/forgetful ()
        (mon (→ Int Nat) (λ (t : Int) 4))
        (→ Int Nat))))
    (check-true (judgment-holds
      (well-typed/forgetful ()
        (mon (→ Int Nat) (λ (t : Int) 4))
        (→ Nat Int))))
    (check-true (judgment-holds
      (well-typed/forgetful ()
        (λ (z : (→ (× Nat Int) Nat)) 0)
        (→ (→ (× Nat Int) Nat) Int))))

    (check-true (judgment-holds (well-typed/forgetful ()
      ((dynamic (→ (× (× Int Int) (→ Nat Nat)) Nat)
         (static (→ Int Nat) (λ (Z : Int) 1)))
       (× (dynamic (× Nat Nat) (fst (λ (C) 0)))
          (dynamic (→ Nat Nat) (static Int 0))))
      Nat)))

    (check-true (judgment-holds (well-typed/forgetful ()
      ((dynamic (→ (× Int Nat) Nat)
        (static (→ Int Nat) (λ (Z : Int) 1)))
       (× 0 0))
      Nat)))

    (check-false (judgment-holds (well-typed/forgetful ()
      ((mon (→ Int Nat) (λ (Z : Int) 1))
       (× 0 0))
      Nat)))

    (check-true (judgment-holds (well-typed/forgetful ()
      (fst (fst (dynamic (× (× Int (× (→ Nat Int) Int)) Int) 3)))
      Int)))

    (check-true (judgment-holds (well-typed/forgetful ()
      (snd (dynamic (× (→ (× Nat Int) (→ Int Nat)) (→ Int (→ Nat Nat))) (static Int 0)))
      (→ Nat (→ Nat Nat)))))

    (check-true (judgment-holds (well-typed/forgetful ()
      ((λ (h : (× Int (→ Nat (→ Nat Nat))))
         (fst ((fst (dynamic (× (→ (× Int (→ Nat (→ Nat Nat))) (× Nat (× Nat Int))) (× Int Int)) 0)) h)))
       (× (fst (fst (dynamic (× (× Int (× (→ Nat Int) Int)) Int) 3)))
          (snd (dynamic (× (→ (× Nat Int) (→ Int Nat)) (→ Int (→ Nat Nat))) (static Int 0)))))
      Int)))

  )
)

(define (assert-well-dyn t dont-care)
  (unless (judgment-holds (well-dyn/forgetful () ,t))
    (raise-arguments-error 'current-runtime-invariant "expected well-dyn" "term" t)))

(define (assert-well-typed t ty)
  (unless (judgment-holds (well-typed/forgetful () ,t ,ty))
    (raise-arguments-error 'current-runtime-invariant "expected well-typed"
      "term" t
      "type" ty)))

(define (is-error? t)
  (or (redex-match? LM-forgetful TE t)
      (redex-match? LM-forgetful BE t)))

;; -----------------------------------------------------------------------------

(define-metafunction LM-forgetful
  theorem:forgetful-safety : e MAYBE-τ -> any
  [(theorem:forgetful-safety e #f)
   ,(or (not (judgment-holds (well-dyn () e)))
        (safe-step* (term e) #f is-error? assert-well-dyn dyn-boundary-step))]
  [(theorem:forgetful-safety e τ)
   ,(or (not (judgment-holds (well-typed () e τ)))
        (safe-step* (term e) (term τ) is-error? assert-well-typed sta-boundary-step))])

(module+ test

  (define (safe? t ty)
    (with-handlers ([exn:fail:contract? (λ (e) (exn-message e))])
      (and (term #{theorem:forgetful-safety ,t ,ty}) #true)))

  (test-case "forgetful-safety"
    (check-true (safe? (term ((× 0 2) (× 2 1))) #f))
    (check-true (safe? (term (λ (n) (× 0 0))) #f))
    (check-true (safe? (term (λ (n : Nat) (× 0 0))) (term (→ Nat (× Nat Nat)))))
    (check-true (safe? (term (+ (fst (fst (fst (dynamic (× (× (× Int Nat) (→ Nat (× Int Int))) Int) 0)))) (fst (dynamic (× Int (× (× Int Int) Nat)) 0)))) (term Int)))
    (check-true (safe? (term (dynamic (→ Int Int) (λ (x) x))) (term (→ Int Int))))
    (check-true (safe? (term (static (× (→ (× (→ Int Int) Int) Nat) (→ Int Nat)) (× (λ (R : (× (→ Int Int) Int)) 2) (λ (r : Int) 2)))) #f))
    (check-true (safe? (term (/ ((snd (dynamic (× Int (→ (× (× Int Int) Int) Nat)) (× 0 1))) (snd (fst (fst (snd (dynamic (× Nat (× (× (× Int (× (× Nat Nat) Nat)) (→ Nat Int)) Nat)) 1)))))) ((snd (fst (fst (dynamic (× (× (× Int (→ (→ Nat Int) Int)) (→ Nat Int)) (× (× Int Int) (→ Int Int))) 1)))) (fst (snd (× 0 (snd (fst (dynamic (× (× Int (× (→ Int Int) (→ (→ Int Int) Nat))) Nat) 3))))))))) (term Int)))
    (check-true (safe?
      (term
        ((((static (→ (→ (× Nat Int) Nat) Nat) (λ (z : (→ (× Nat Int) Nat)) 0))
           (static (→ Int Nat) (λ (t : Int) 4)))
          (× (+ (snd (λ (eF) 2)) (λ (X) (static Int 0))) (λ (C) (static Nat 2))))
         (/ ((static (× Nat (→ Nat Int)) (dynamic (× Nat (→ Nat Int)) 1))
             (fst (λ (z) (fst 1))))
            (× (static Int
                 (snd (fst (fst
                   (dynamic (× (× (× (× Int Int) Nat) (→ (× Int Int) Int)) Nat) 2)))))
               ((fst (snd 0))
                (λ (F) (λ (j) 0))))))) #f))
    (check-true (safe? (term (static (→ (× Nat (× Nat (→ Nat (× Int Int)))) (→ (× Int Int) Int)) ((λ (Z : (→ Nat Int)) (dynamic (→ (× Int (× Int (→ Nat (× Int Int)))) (→ (× Int Int) Nat)) (λ (b) 0))) (λ (b : Int) (dynamic Nat (λ (w) 0)))))) (term #f)))
    (check-true (safe? (term
      (static (× (→ (→ Nat Nat) Nat) (→ Nat Int))
        ((dynamic (→ (→ (× Nat Nat) (→ Nat Int)) (× (→ (→ Nat Int) Nat) (→ Int Nat))) (λ (Qgk) (λ (IQ) 1)))
          (dynamic (→ (× Int Int) (→ Int Nat)) (λ (p) (λ (Okp) 2))))))
      (term #f)))

    (check-true (safe? (term
      (static (→ Int Int)
        (dynamic (→ Int Int)
          (static (→ (× Int Int) Int)
            (λ (z : (× Int Int)) (fst z))))))
      (term #f)))

    (check-true (safe? (term
      ((static (→ (→ Int Int) Int)
         (λ (g : (→ Int Int)) (g 3)))
       (static (→ Int Int)
         (dynamic (→ Int Int)
           (static (→ (× Int Int) Int)
             (λ (z : (× Int Int)) (fst z))))))) (term #f)))

    (check-true (safe? (term
      (static (→ (→ Nat (→ Int Nat)) Int)
        ((dynamic (→ (→ Nat Int) (→ (→ Nat (→ Nat Int)) Nat)) (λ (bs) bs)) (λ (C : Int) C))))
      (term #f)))

    (check-true (safe? (term
      ((dynamic (→ (× (× Int Int) (→ Nat Nat)) Nat)
         (static (→ Int Nat) (λ (Z : Int) 1)))
       (× (dynamic (× Nat Nat) (fst (λ (C) 0)))
          (dynamic (→ Nat Nat) (static Int 0)))))
      (term Nat)))

    (check-true (safe? (term
      (+ ((dynamic (→ (× (× Int Int) (→ Nat Nat)) Nat)
            (static (→ Int Nat) (λ (Z : Int) 1)))
          (× (dynamic (× Nat Nat) (fst (λ (C) 0)))
             (dynamic (→ Nat Nat) (static Int 0))))
         ((λ (h : (× Int (→ Nat (→ Nat Nat)))) (fst ((fst (dynamic (× (→ (× Int (→ Nat (→ Nat Nat))) (× Nat (× Nat Int))) (× Int Int)) 0)) h)))
          (× (fst (fst (dynamic (× (× Int (× (→ Nat Int) Int)) Int) 3)))
             (snd (dynamic (× (→ (× Nat Int) (→ Int Nat)) (→ Int (→ Nat Nat))) (static Int 0)))))))
      (term Nat)))

  )

  #;(test-case "forgetful-safety:auto"
    (check-true
      (redex-check LM-forgetful #:satisfying (well-dyn () e)
        (term (theorem:forgetful-safety e #f))
        #:attempts 1000
        #:print? #f))
    (check-true
      (redex-check LM-forgetful #:satisfying (well-typed () e τ)
        (term (theorem:forgetful-safety e τ))
        #:attempts 1000
        #:print? #f)))
)
