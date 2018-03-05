#lang gf-icfp-2018
@require[(only-in "techreport.rkt" tr-theorem tr-lemma)]
@title[#:tag "sec:design"]{Apples-to-Apples Logic and Metatheory}

@; TODO
@; ? why do we call it embedding?
@; - A @mytech{migratory typing system} is XXX and must YYY
@; - define/explain "getting stuck", (a b) and (op1 a) and (op2 a b)

@; -----------------------------------------------------------------------------

In this section we equip one syntax for @mytech{mixed-typed programs} (@figure-ref{fig:multi-syntax})
 with one type system (@figure-ref{fig:multi-preservation}) and three semantics
 (sections @secref{sec:natural-embedding}, @secref{sec:locally-defensive-embedding},
 and @secref{sec:erasure-embedding}).
Each semantics satisfies a unique soundness condition.


@section{Illustration}
@; could be seeds / trees / fruits
@; - apple / plant / fruit soundness?
@; - harder to picture trees crossing boundaries,
@;   or trees & picked fruit coexisting
@;
@; TODO need to add food

Start with a special tank of fish and eggs.
The fishtank is special because every thing in the tank is either:
 an adult @emph{red snapper},
 a red snapper egg,
 or a box of red snapper food.
A red snapper fish has a beautiful red color and is precisely @~a[(/ 1 RED-SNAPPER-RATIO)]
 times as wide as it is tall.
Red snappers can only eat certified red snapper food, else they get sick and die.
A red snapper egg is certified to hatch into a red snapper (if it hatches at all).
Over time, as old fish die out and new fish hatch from eggs, this @emph{red snapper soundness}
 property always holds for this fishtank.

@inline-pict[fishtank-pict]

One day a pathway appears, linking our fishtank to the outside.
The red snapper soundness property is now at risk.
Anything might cross over the pathway, including but not limited to:
 a red snapper, a blue snapper, a mysterious egg, or a jack-o-lantern.
The question is, what to do about this pathway.

@inline-pict[fishtank/biohazard]

One option is to enforce the red snapper property.
If an adult thing arrives at the boundary, conduct a physical examination to
 check that it is an adult red snapper.
If a mysterious egg arrives at the boundary, check its color (all red snapper
 eggs are red, of course) and monitor it.
When the egg hatches, immediately conduct a physical exam.
If a box of food arrives, check that it is safe for red snappers.
Conducting the physicals and monitoring the eggs may be costly, but is guaranteed
 to let all incoming red snappers into the tank and keep all non-red-snappers
 out.

@inline-pict[fishtank/biohazard/natural]

A second option is to let anything cross the pathway and forget about the
 red snapper property.
Instead we can be content with a trivial @emph{fish soundness} property;
 namely, that every thing in the tank is either native to the tank or came
 from the pathway.

@inline-pict[fishtank/biohazard/erasure]

A third option is to enforce a weaker @emph{red soundness} property.
If an adult thing arrives at the boundary, check its color and allow only
 red things.
If an egg arrives, check its color and check the color of the baby when it hatches.
These checks cannot ensure red snapper soundness in the face of arbitrary inputs.

@inline-pict[fishtank/biohazard/locally-defensive]

This concludes the illustration.
The three options outlined above correspond to three notions of type soundness
 for typed/untyped programs.
The strategy to enforce red snapper soundness is the natural embedding.
The strategy for fish soundness is the erasure embedding.
The strategy for red soundness is the locally-defensive embedding.


@section{Common Semantic Notions}

@Figure-ref{fig:multi-syntax} presents the syntax.
The grammar for @${\exprdyn} defines an untyped host language; the
 grammar @${\exprsta} defines an explicitly-typed twin language.
Both expression languages, @${\exprdyn} and @${\exprsta}, describe a lambda
 calculus extended with integers, pairs, related primitive operations,
 and @emph{boundary terms}.
The @${\exprdyn} boundary term @${(\esta{\tau}{\exprsta})} embeds a
 typed expression in an untyped context.
Conversely, the @${\exprsta} boundary term @${(\edyn{\tau}{\exprdyn})} embeds
 a dynamically-typed expression; the type annotation @${\tau} describes the
 context's assumptions about the value of the embedded expression.

The syntax intentionally does not include recursive functions, arbitrary-length
 data structures, mutable values, or infinite values such as streams.
Incorporating these values and their types is straightforward given a strategy
 that handles basic values, immutable data structures, and anonymous functions.
See @secref{sec:implementation} for details.
@; simple as possible ... well I guess pairs could be immutable boxes

@Figure-ref{fig:multi-preservation} defines a type system for this
 surface language.
An expression @${e} is well-formed, written @${\cdot \wellM e}, if it
 has no free variables and all its embedded terms are well-typed.
An expression is well-typed, written @${\cdot \wellM \exprsta : \tau},
 if it has no free variables, does not apply a function or primitive operation
 to an argument outside its domain, and all its embedded terms are well-typed.

The challenge is to define a sound semantics for well-typed expressions.
Specifically, we are looking for a reduction relation @${\rastar} that provides:
@itemlist[
@item{
  @emph{soundness for a single language}: for expressions without boundary
   terms, the typing judgment in @figure-ref{fig:multi-preservation} is sound
   with respect to the reduction semantics;
}
@item{
  @emph{expressive boundary terms}: the static and dynamic twin languages can
   share values at any type;
  @; e.g. no rule (dyn t->t v) ==> error to prohibit sharing all function
}
@item{
  @emph{soundness for the pair of languages}: for all expressions,
   evaluation preserves some property, though it may be weaker than a standard
   notion of type soundness.
}
]
With these goals in mind, the following three subsections give strategies for
 embedding untyped expressions (@${\exprdyn}) within typed expressions (@${\exprsta})
 and vice-versa.
Each embedding is made of five basic ingredients:
 a notion of reduction @${\rrD} for dynamically-typed expressions;
 a notion of reduction @${\rrS} for statically-typed expressions;
 a function @${\vfromdyn} that imports a dynamically-typed value into a typed context;
 a function @${\vfromsta} that imports a statically-typed value into an untyped context;
 and a judgment form that is both implied by the typing judgment in
 @figure-ref{fig:multi-preservation} and sound with respect to a semantics derived from the
 four previous components.

The starting point for these embeddings is the @mytech{evaluation syntax}
 and @${\delta} function in @figure-ref{fig:multi-reduction}.
The syntax provides a uniform language for reduction relations:
 the expression grammar @${e} is the domain of evaluation,
 evaluation ends in either a value @${v} or error @${\eerr},
 and the order of evaluation is guided by contexts @${\ES}.
There are two kinds of error.
Since this is a multi-language system, a @mytech{boundary error} @${\boundaryerror}
 can occur when one language receives an incompatible value from another.
A @mytech{tag error} @${\tagerror} occurs when value of the wrong shape reaches
 an elimination form.
@; GAAAH
High level: boundary errors and tag errors both occur because of bad values;
 boundary error is from an impedence mismatch between languages,
 tag error is from a mismatch between components in one language.
Evaluation contexts have two levels.
A pure context @${\ebase} does not contain boundary terms;
 an evaluation context @${\esd} may contain boundary terms.
This distinction is important if the embedding has two notions of reduction
 for typed and untyped code.

The @${\delta} function assigns meaning to the primitives.
The primitives @${\vfst} and @${\vsnd} extract the first and second components
 of a pair value, respectively.
The primitive @${\vsum} adds integers and the primitive @${\vquotient} performs
 integer division.
Division by zero raises a boundary error because one language (math) received
 an incompatible value from another language (@${\exprdyn} or @${\exprsta}) 

@include-figure["fig:multi-syntax.tex" @elem{Twin languages syntax}]
@include-figure["fig:multi-preservation.tex" @elem{Twin languages static typing judgments}]
@include-figure["fig:multi-reduction.tex" @elem{Common semantic notions}]

@;In order to provide some kind of type soundness, an embedding must restrict
@; the dynamically-typed values that can flow into typed contexts.


@; -----------------------------------------------------------------------------
@section[#:tag "sec:natural-embedding"]{Natural Embedding}
@include-figure*["fig:natural-reduction.tex" "Natural Embedding"]
@include-figure*["fig:natural-preservation.tex" "Property judgments for the natural embedding"]

@; Thesis for this section?
@; - impossible to provide conventional soundness, but can faithfully
@;   approximate with runtime checks ?
@; ... simple idea just od `\vdash e : \tau` at runtime

@subsection[#:tag "sec:natural:overview"]{Overview}

A standard type soundness theorem guarantees that if a well-typed expression
 reduces to a value, the value is of the same type.
This guarantee comes about because the static type checker establishes a type
 for every sub-expression, and these proofs compose.
The analogous guarantee for the surface syntax (@figure-ref{fig:multi-syntax})
 and typing system (@figure-ref{fig:multi-reduction}) is the following:

@$$|{
  \mbox{\emph{(ideal)}}
    {\cdot \wellM \exprsta : \tau}
    \wedge
    {\exprsta \rastar v}
    \Rightarrow
    {\cdot \wellM v : \tau}
}|

It is impossible to realize this guarantee in the same way as in a statically-typed
 language, because some terms are intentionally untyped.
In the expression @${(\edyn{\tau}{e})} there is no guarantee that the expression
 @${e} has type @${\tau}, or any type at all.
Instead, however, it is possible to approximate the same guarantee with
 runtime checks.
When a value @${v} flows from dynamically-typed code into a statically-typed
 context expecting a value of type @${\tau}, a runtime check can try to establish
 that the value is well-typed.
The question is then how to implement such checks.

For base types such as @${\tint} and @${\tnat}, we suppose that the language
 comes with primitives that implement @${v \in \integers} and @${v \in \naturals}
 (see @secref{sec:implementation:tag-check} for a discussion).
For inductive types such as @${\tpair{\tau_0}{\tau_1}}, an inductive checking
 strategy can confirm that a value is a pair and that its components match
 the types @${\tau_0} and @${\tau_1}, respectively.@note{Notation: @${\tau_0} is the type at index zero in the pair type, @${\tau_1} is the type at index one.}
For coinductive types such as @${\tarr{\tau_d}{\tau_c}}, the @emph{natural}
 approach is to check that the value is a function and monitor its future
 behavior for counterexamples to the conjecture that it treats its inputs as
 values of type @${\tau_d} and yields values of type @${\tau_c}.@note{Notation: @${\tau_d} is the domain type, @${\tau_c} is the codomain type.}
Monitoring delays a type error until the runtime system finds a witness
 that the given value does not match the coinductive type.

@Figure-ref{fig:natural-reduction} implements the above checking strategy
 and uses it to define a reduction relation.
@; ??? really just want to say "Fig 1 implements the above"


@subsection[#:tag "sec:natural:implementation"]{Implementation}

@; concrete examples ... ???

The natural embedding defined in @figure-ref{fig:natural-reduction} adds
 one new value form, two functions for checking values at boundary terms,
 and two reduction rules to handle the new value form.
The new value form, @${(\vmonfun{(\tarr{\tau_d}{\tau_c})}{v})}, is a monitor
 that associates a value @${v} with a type.
Such monitors arise at runtime as the result of calls to the @${\vfromdyn}
 and @${\vfromsta} conversion functions.

@;In principle, the one monitor value @${(\vmonfun{(\tarr{\tau_d}{\tau_c})}{v})}
@; could be split into two value forms: one for protecting the domain of a statically-typed
@; function and one for checking the range of a dynamically-typed function.
@;The split would clarify @${\rrNS} and @${\rrND} but it would also create a
@; larger gap between the model and implementation (@secref{sec:implementation}).

The purpose of @${\efromdyn{\tau}{v}} is to import a dynamically-typed value
 into a statically-typed context, such that the result matches the assumptions
 of the context.
If @${\tau} is a base type, then @${\efromdyn{\tau}{v}} returns @${v} if the
 value matches the type and raises a boundary error otherwise.
If @${\tau} is a product type, then @${\efromdyn{\tau}{v}} asserts that @${v}
 is a pair value and returns a pair expression to import the components of the
 pair at the appropriate type.
Finally if @${\tau} is a function type, then @${\efromdyn{\tau}{v}} asserts
 that @${v} is a function (or a monitored function) and wraps @${v} in a monitor.

The purpose of @${\efromsta{\tau}{v}} is to import a statically-typed value
 into a dynamically-typed context such that context cannot break any assumption
 made by the value.
Integers and natural numbers do not interact with their context, thus
 @${\efromsta{\tint}{v}} returns the given value.
Pair values may indirectly interact with the context via their components,
 so @${\efromsta{\tpair{\tau_0}{\tau_1}}{v}} returns a pair expression to import
 the components.
Function values interact with their context by receiving arguments, and so
 @${\efromdyn{\tarr{\tau_d}{\tau_c}}{v}} wraps the function @${v} in a monitor
 to protect it from dynamically-typed arguments.

The notion of reduction @${\rrNS} adds a rule for applying a monitor as a function
 in a typed context.
The rule is to export the argument value to an untyped context and import the result
 back into typed code.
The ``export'' and ``import'' are implemented with boundary terms.
Conversely, the notion of reduction @${\rrND} adds a rule for applying a monitor
 in an untyped context.
In this case the conversion strategy is dual:
 convert the argument to typed, convert the result back to untyped.

These notions of reduction assume that all monitors in statically-typed contexts
 contain dynamically-typed values, and that all monitors in dynamically-typed
 contexts contain statically-typed values.
@Figure-ref{fig:natural-property} captures this requirement by extending the
 basic typing judgments for the evaluation syntax (@figure-ref{fig:multi-preservation})
 with appropriate rules for monitors.

The final components in @figure-ref{fig:natural-reduction} define a reduction
 relation @${\ccNE} for evaluation contexts and take the reflexive, transitive
 closure of this relation.
These define the operational semantics of an expression @${e}; a single step
 finds the innermost boundary term in @${e} and advances it.
If the innermost boundary has the form @${(\esta{\tau}{e'})} then @${\ccNE}
 either uses @${\rrNS} to step @${e'} or @${\vfromsta} to cross the boundary.
If the innermost boundary has the form @${(\edyn{\tau}{e'})} then @${\ccNE}
 either uses @${\rrNS} or @${\vfromdyn} to advance.

@subsection[#:tag "sec:natural:soundness"]{Soundness}

The soundness theorems for the natural embedding state two results about the
 possible outcomes of evaluating a well-typed surface language term.
First, the evaluation of a (terminating) statically-typed expression ends
 in either a well-typed value, a boundary error, or a tag error in dynamically-typed code.
Second, dynamically-typed code cannot exhibit undefined behavior.
More formally:

@twocolumn[
  @tr-theorem[#:key "N-static-soundness" @elem{static @${\mathbf{N}}-soundness}]{
    If @${\wellM e : \tau} then @${\wellNE e : \tau} and one
    @linebreak[]
    of the following holds:
    @itemlist[
      @item{ @${e \rrNSstar v \mbox{ and } \wellNE v : \tau} }
      @item{ @${e \rrNSstar \ctxE{\edyn{\tau'}{\ebase[e']}} \mbox{ and } e' \rrND \tagerror} }
      @item{ @${e \rrNSstar \boundaryerror} }
      @item{ @${e} diverges}
    ] }

  @tr-theorem[#:key "N-dynamic-soundness" @elem{dynamic @${\mathbf{N}}-soundness}]{
    If @${\wellM e} then @${\wellNE e} and one
    @linebreak[]
    of the following holds:
    @itemlist[
      @item{ @${e \rrNDstar v \mbox{ and } \wellNE v} }
      @item{ @${e \rrNDstar \tagerror} }
      @item{ @${e \rrNDstar \boundaryerror} }
      @item{ @${e} diverges}
    ] }
]

The theorems follow from standard progress and preservation lemmas
 for each reduction relation and the corresponding
 property judgment.
See the appendix for proofs.

The central lemmas that connect this pair of theorems are a specification for
 the @${\vfromdyn} and @${\vfromsta} functions:

@twocolumn[
  @tr-lemma[#:key "N-D-soundness" @elem{@${\vfromdyn} soundness}]{
    If @${\Gamma \wellNE v} and @${\efromdyn{\tau}{v} = e} then @${\Gamma \wellNE e : \tau}
  }

  @tr-lemma[#:key "N-S-soundness" @elem{@${\vfromsta} soundness}]{
    If @${\Gamma \wellNE v : \tau} and @${\efromsta{\tau}{v} = e} then @${\Gamma \wellNE e}
  }
]

@; Any choice of S/D that satisfies these theorems is probably OK for soundness

In other words, the implementations of @${\vfromdyn} and @${\vfromsta} establish
 an invariant about monitors occurring in dynamic and static contexts.
Every monitor in dynamically-typed code encapsulates a typed value,
 and every monitor in statically-typed code encapsulates an untyped value.

The soundness guarantee for the natural embedding is very strong.
@; with blame, TypeError at runtime is at least debuggable
One goal of soundness is to eliminate a class of errors.
The natural embedding eliminates tag errors in typed code.
It cannot eliminate boundary errors, but it brings them under control in a
 useful way.


@; -----------------------------------------------------------------------------
@section[#:tag "sec:erasure-embedding"]{Erasure Embedding}
@include-figure["fig:erasure-reduction.tex" "Erasure Embedding"]
@include-figure["fig:erasure-preservation.tex" "Property judgments for the erasure embedding"]

@subsection[#:tag "sec:erasure:overview"]{Overview}

A second approach to migratory typing is to define soundness
 for the pair of languages as the soundness of the dynamically-typed
 host language.
@; so unclear
Instead of designing two notions of reduction and converting values at
 boundary terms, the erasure embedding comes with one notion of reduction.

@; omg this repeats the intro
From the programmers' perspective, erased types can catch static errors
 and enable tools like type-directed autocomplete.
Erased types have no relation to the semantics of a program.
For example, if an expression has the static type @${\tnat} then might
 reduce to a natural number, a negative integer, a pair, or a function.


@subsection[#:tag "sec:erasure:implementation"]{Implementation}

To implement the erasure embedding, it suffices to ignore type annotations
 and boundary terms in the surface language.
The notion of reduction @${\rrEE} in @figure-ref{fig:erasure-reduction}
 implements this idea by extending the dynamically-typed notion of reduction
 with two rule to let any value cross a boundary term and one rule to reduce
 the application of a statically-typed function to the application of a dynamically-typed
 function.
The reduction relation @${\rrEEstar} is the standard context closure of
 this notion of reduction.

The judgment in @figure-ref{fig:erasure-preservation} describes well-formed
 evaluation syntax terms.
Just like the notion of reduction, it extends a dynamically typed judgment
 with rules that ignore type annotations.


@subsection[#:tag "sec:erasure:soundness"]{Soundness}

The erasure embedding treats typed code as untyped code.
Consequently, erasure soundness for the pair of language is their lowest common
 denominator --- well-typed programs have well-defined behavior.

@twocolumn[
  @tr-theorem[#:key "E-static-soundness" @elem{static @${\mathbf{E}}-soundness}]{
    If @${\wellM e : \tau} then @${\wellEE e} and one
    @linebreak[]
    of the following holds:
    @itemlist[
      @item{ @${e \rrEEstar v \mbox{ and } \wellEE v} }
      @item{ @${e \rrEEstar \tagerror} }
      @item{ @${e \rrEEstar \boundaryerror} }
      @item{ @${e} diverges}
    ] }

  @tr-theorem[#:key "E-dynamic-soundness" @elem{dynamic @${\mathbf{E}}-soundness}]{
    If @${\wellM e} then @${\wellEE e} and one
    @linebreak[]
    of the following holds:
    @itemlist[
      @item{ @${e \rrEEstar v \mbox{ and } \wellEE v} }
      @item{ @${e \rrEEstar \tagerror} }
      @item{ @${e \rrEEstar \boundaryerror} }
      @item{ @${e} diverges}
    ] }
]

The proof follows from progress and preservation lemmas for the
 @${\wellEE} judgment and the @${\rrEEstar} reduction relation.
It is a weak theorem with a straightforward proof.


@; -----------------------------------------------------------------------------
@section[#:tag "sec:locally-defensive-embedding"]{Locally-Defensive Embedding}
@include-figure*["fig:locally-defensive-reduction.tex" "Locally-Defensive Embedding"]
@include-figure*["fig:locally-defensive-preservation.tex" "Property judgments for the locally-defensive embedding"]

@subsection[#:tag "sec:locally-defensive:overview"]{Overview}

@; Maybe try: "3rd approach = enforce constructors, this can be done with local checks"

A third approach to migratory typing is to ensure that every typed value matches
 the outermost constructor of its static type.
If this shallow invariant holds, then one can prove that an evaluator
 similar to @${\rrS} never gets stuck.
Intuitively, this works out because the ``stuck'' judgment only looks at
 type constructors.
@; Where "getting stuck" is precisely:
@; - `(a b)` where `a` is not a function
@; - `(op ...)` where `op` undefined for arguments

For example, two values that match the outermost constructor of the type
 @${\tarr{\tnat}{\tnat}} are @${(\vlam{x}{x})} and @${(\vlam{\tann{y}{\tint}}{y})},
 because both values are functions.
These values, and indeed any other functions, are safe to place in the context
 @${(\eapp{\ehole}{1})} without making it stuck.
Similarly, the context @${\efst{x}} is stuck if and only if @${x} is not a
 pair value.

These are one-level examples.
What about @${\efst{\efst{x}}}?
To avoid getting stuck, @${x} needs to be a pair value whose first component is
 a pair value.
If this is a well-typed program and evaluation preserves the invariant that
 every value matches the top-level constructor of its type, then both @${x} and
 @${\efst{x}} are guaranteed to be pair values at runtime and the program is
 safe.

The question becomes, how to implement the invariant.
The straightforward way is to start from the natural embedding and change
 the interpretation of boundary terms.
In particular: (1) check only value constructors, (2) wrap functions and pairs,
 with monitors that check the constructor of their components / arguments / results.
This approach is fine, see appendix.

A different strategy, due to @citet[vss-popl-2017], is to ditch the monitors
 and rewrite typed code with assertions that check value constructors.
Assertions are sufficient because the invariant depends only on local
 typing assumptions.
(Monitors can accumulate checks from boundaries, rack up the history of a value.
 This history doesn't matter for the soundness of the currently-executing context.)
So we just need to be sure the assertions go in the right places.
The right places are wherever a monitor would insert a check.
Oh dear @bold{this} is very hard to motivate without the co-natural embedding.

In summary, the plan is to use a programs typing derivation to decide what
 checks to insert.
The rewritten program can reduce using a semantics similar to the common
 reduction relations, except that both typed and untyped functions can appear
 in both typed and untyped contexts.
Need a technical device for this.

@; Dynamically typed languages often come with efficient constructor-checking
@;  procedures, so the work required to implement this approach is probably all
@;  about making sure checks go in the right place.



@subsection[#:tag "sec:locally-defensive:implementation"]{Implementation}

@Figure-ref{fig:locally-defensive-reduction} presents the key components of a
 @emph{locally-defensive} embedding.
As a disclaimer, this embedding includes two technical devices to streamline
 the proof of soundness: first is the use of the pseudo-boundary terms
 @${(\edynfake{e})} and @${(\estafake{e})}, and second is the treatment
 of typed functions in the reduction relation.
These devices ensure that typed functions may be safely applied in typed or
 untyped code; details follow.

The syntax of the embedding extends the evaluation syntax from @figure-ref{fig:multi-reduction}
 with new expressions, new contexts, and a grammar @${\kappa} for type constructors.
The expression @${(\edynfake{e})} encapsulates the body of an untyped function
 applied in a typed context; there is no type annotation for this boundary
 term because (as we shall see) the evaluator does not know what type to expect.
The expression @${(\estafake{e})} conversely encapsulates the body of a typed
 function applied in an untyped context; again there is no type annotation.
The expression @${(\echk{\kappa}{e})} associates a typed expression @${e} with an
 expected type constructor.
If we have the typed expression @${\wellM (f 0) : \tnat} and @${f} evaluates
 to an untyped function @${(\vlam{x}{\esum{x}{1}})} then the immediate result
 of the application must be @${\echk{\tnat}{\edyn{(\esum{0}{1})}}}.
@; TODO do example first, to motivate the dyn and sta
The extended definitions of contexts @${\ebase} and @${\esd} accomodate the
 new expression forms.

Constructors @${\kappa} are first-order properties of values:
 a value may be a number (@${\kint} or @${\knat}), a pair (@${\kpair}),
 a function (@${\kfun}), or something else (@${\kany}).
For instance, the first component of any @${\kpair} value is a @${\kany} value.
The meta-function @${\tagof{\cdot}} maps a type to a constructor by ``truncating''
 the contents of the type.@note{Notation from @citet[vss-popl-2017].}

The judgment @${\Gamma e : \tau \carrow e'} states that @${e'} is the
 checked @emph{completion}@~cite[h-scp-1994] of the typed expression.
This completion is identical to the surface expression @${e} except that it
 adds @${\echk{\tagof{\tau}}{\cdot}} forms around every function application
 expecting a result of type @${\tau}, and around every call to @${\vfst} and
 @${\vsnd} expecting a result of the same type.
@Figure-ref{fig:locally-defensive-reduction} demonstrates the rules for
 application and @${\vfst}; the rule for @${\vsnd} is similar, and the other
 rules recursively take the completion of their sub-expressions.

@; TODO this should parallel the discussion in natural embedding
The dynamic boundary function @${\vfromdyn} computes the constructor of the given type
 and invokes a generic boundary-crossing function @${\vfromany} to check that
 the given value matches the constructor.
The function @${\vfromsta} does nothing (justified in the next section).
Lastly @${\efromany{\kappa}{v}} checks that the value @${v} matches the given
 type constructor.
If not, it raises a boundary error.

The notions of reduction @${\rrKS} and @${\rrKD} define the semantics of
 @${\vchk} expressions and function application.
A @${\vchk} expression in typed code steps to the result of the @${\vfromany}
 boundary-crossing function.
A @${\vchk} expression in untyped code is stuck.
Typed and untyped functions can appear anywhere, so @${\rrKS} includes a
 rule for dynamically-typed application and @${\rrKD} includes rules for
 statically-typed application.
The application rules for a statically-typed function raise a boundary error
 if the argument does not match constructor of the function's domain type.
 
The reduction relations @${\rrKSstar} and @${\rrKDstar} are analogous to those
 of the natural embedding, but include transitions for un-annotated boundary
 terms.


@subsection[#:tag "sec:locally-defensive:soundness"]{Soundness}

@Figure-ref{fig:locally-defensive-preservation} presents two judgments for
 expressions internal to the locally-defensive evaluator.
The main theorem for this embedding is that these properties are sound with
 respect to the @${\rrKSstar} and @${\rrKDstar} reduction relations.

@twocolumn[
  @tr-theorem[#:key "K-static-soundness" @elem{static @${\mathbf{K}}-soundness}]{
    If @${\wellM e : \tau} then 
    @${\wellM e : \tau \carrow e''}
    and @${\wellKE e'' : \tagof{\tau}}
    @linebreak[]
    and one of the following holds:
    @itemlist[
      @item{ @${e'' \rrKSstar v} and @${\wellKE v : \tagof{\tau}} }
      @item{ @${e'' \rrKSstar \ctxE{\edyn{\tau'}{\ebase[e']}} \mbox{ and } e' \rrKD \tagerror} }
      @item{ @${e'' \rrKSstar \boundaryerror} }
      @item{ @${e''} diverges }
    ]
  }

  @tr-theorem[#:key "K-dynamic-soundness" @elem{dynamic @${\mathbf{K}}-soundness}]{
    If @${\wellM e} then 
    @${\wellM e \carrow e''}
    and @${\wellKE e''}
    @linebreak[]
    and one of the following holds:
    @itemlist[
      @item{ @${e'' \rrKDstar v} and @${\wellKE v : \tagof{\tau}} }
      @item{ @${e'' \rrKDstar \tagerror} }
      @item{ @${e'' \rrKDstar \boundaryerror} }
      @item{ @${e''} diverges }
    ]
  }
]

In other words, a ``well-constructed'' expression @${\wellKE e'' : \kappa} can
 reduce to either: a well-constructed value, a tag error (in untyped code), or
 a boundary error.
The link between well-constructed expressions and the surface syntax is the
 completion judgment; a key lemma for the previous theorems is that the
 completion judgment meets the following specification:

@twocolumn[
  @tr-lemma[#:key "K-S-completion" @elem{static @${\carrow} soundness}]{
    If @${\Gamma \wellM e : \tau} then
    @linebreak[]
    @${\Gamma \vdash e : \tau \carrow e'} and @${\Gamma \wellKE e' : \tagof{\tau}}
  }

  @tr-lemma[#:key "K-D-completion" @elem{dynamic @${\carrow} soundness}]{
    If @${\Gamma \wellM e} then
    @linebreak[]
    @${\Gamma \wellM e \carrow e'} and @${\Gamma \wellKE e'}
  }
]

Any judgment that satisfies this spec could be substituted for the @${\carrow}
 judgment.
@; what are you going to improve without changing \wellKE ?

The other main lemma is that boundary-crossing via @${\vfromany} is sound
 with respect to the property judgment.

@tr-lemma[#:key "K-check" @elem{@${\vfromany} soundness}]{
  If @${\mchk{K}{v} = v}
   @linebreak[]
   then @${\wellKE v : K}
}

These lemmas hold because the definitions are good.
