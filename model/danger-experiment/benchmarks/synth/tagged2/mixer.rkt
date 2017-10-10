#lang typed/racket/base

(require
  "typed-data.rkt"
  (for-syntax racket/base)
  (only-in racket/list first second rest)
  "array-struct.rkt"
  "array-broadcast.rkt")

(provide mix)

;; -- array-pointwise
(define-syntax-rule (ensure-array name arr-expr)
  (let ([arr arr-expr])
    (if (array? arr) arr (raise-argument-error name "Array" arr))))

(define-syntax (inline-array-map stx)
  (syntax-case stx ()
    [(_ f arr-expr)
     (syntax/loc stx
       (let ([arr  (ensure-array 'array-map arr-expr)])
         (define ds (array-shape arr))
         (define proc (assert (unsafe-array-proc arr) procedure?))
         (define arr* (unsafe-build-array ds (λ ([js : Indexes]) (f (assert (proc js) real?)))))
         (array-default-strict! arr*)
         arr*))]
    [(_ f arr-expr arr-exprs ...)
     (with-syntax ([(arrs ...)   (generate-temporaries #'(arr-exprs ...))]
                   [(procs ...)  (generate-temporaries #'(arr-exprs ...))])
       (syntax/loc stx
         (let ([arr   (ensure-array 'array-map arr-expr)]
               [arrs  (ensure-array 'array-map arr-exprs)] ...)
           (define ds (array-shape-broadcast (list (array-shape arr) (array-shape arrs) ...)))
           (let ([arr   (array-broadcast arr ds)]
                 [arrs  (array-broadcast arrs ds)] ...)
             (define proc  (assert (unsafe-array-proc arr) procedure?))
             (define procs (assert (unsafe-array-proc arrs) procedure?)) ...
             (define arr* (unsafe-build-array ds (λ ([js : Indexes]) (f (assert (proc js) real?) (assert (procs js) real?) ...))))
             (array-default-strict! arr*)
             arr*))))]))

(: array-map
                  (case->
                   (-> (-> Float Float Float) Array Array Array)
                   (-> (-> Float Float) Array Array)))
(define array-map
  (case-lambda:
    [([f : (Float -> Float)] [arr : Array])
     (inline-array-map f arr)]
    [([f : (Float Float -> Float)] [arr0 : Array] [arr1 : Array])
     (inline-array-map f arr0 arr1)]))

;; Weighted sum of signals, receives a list of lists (signal weight).
;; Shorter signals are repeated to match the length of the longest.
;; Normalizes output to be within [-1,1].

(: mix (-> (Option Weighted-Signal) * Array))
(define (mix . ss)
  (: signals (Listof Array))
  (define signals
    (for/list : (Listof Array) ([s : (Option Weighted-Signal) ss])
      (assert (first (assert s list?)) array?)))
  (: weights (Listof Float))
  (define weights
    (for/list : (Listof Float) ([x : (Option Weighted-Signal) ss])
      (real->double-flonum (assert (second (assert x list?)) real?))))
  (: downscale-ratio Float)
  (define downscale-ratio (/ 1.0 (apply + weights)))
  (: scale-signal (Float -> (Float -> Float)))
  (define ((scale-signal w) x) (* x w downscale-ratio))
  (parameterize ([array-broadcasting 'permissive]) ; repeat short signals
    (for/fold ([res : Array (array-map (scale-signal (first weights))
                               (first signals))])
        ([s (in-list (rest signals))]
         [w (in-list (rest weights))])
      (define scale (scale-signal w))
      (array-map (lambda ([acc : Float]
                          [new : Float])
                   (+ acc (scale new)))
                 res s))))