#lang gf-icfp-2018
@require[(only-in "techreport.rkt" tr-theorem tr-proposition tr-lemma tr-definition tr-proof tr-and UID++)]
@(void (UID++) (UID++))
@title[#:tag "sec:design"]{Logic and Metatheory}

@; -----------------------------------------------------------------------------

The three approaches to migratory typing can be understood as three
 multi-language embeddings in the style of @citet[mf-toplas-2007].
Each approach uses a different strategy to enforce static types at the
 boundaries between typed and untyped code.
Eagerly enforcing types corresponds to a @emph[holong] embedding.
Ignoring types corresponds to an @emph[eolong] embedding.
Enforcing type constructors corresponds to a @emph[folong] embedding.

This section begins with the introduction of the surface syntax and typing
 system (@section-ref{sec:common-syntax}).
It then defines three models,
 states their soundness theorems (@sections-ref{sec:natural-embedding}, @secref{sec:erasure-embedding}, and @secref{sec:locally-defensive-embedding}),
 and concludes with a discussion on scaling the models to a practical implementation (@section-ref{sec:practical-semantics}).
Each model builds upon a common semantic framework (@section-ref{sec:common-semantics})
 to keep the technical presentation focused on their differences.
Unabridged definitions are in the supplement@~cite[gf-tr-2018].


@; -----------------------------------------------------------------------------
@section[#:tag "sec:common-syntax"]{Common Syntactic Notions}

A migratory typing system extends a dynamically-typed @mytech{host language}
 with an optional syntax for type annotations.
The type checker for the extended language must be able to validate mixed-typed
 programs, and the semantics must define a type-directed protocol for transporting
 values across the boundaries between typed and untyped contexts.

In a full language, all kinds of values may cross a type boundary at run-time.
Possibilities include values of base type (numbers, strings, booleans),
 values of algebraic type (pairs, finite lists, immutable sets),
 and values of higher type (functions, mutable references, infinite lists).
As representative examples, the surface language in @figure-ref{fig:multi-syntax}
 includes integers, pairs, and functions, and three corresponding types.
The fourth type, @${\tnat}, is a subset of the type of integers, and is included
 because set-based reasoning is common in dynamically-typed programs@~cite[awl-popl-1994 tf-icfp-2010 tfffgksst-snapl-2017].

An expression in the surface language may be dynamically typed (@${\exprdyn})
 or statically typed (@${\exprsta}).
The main difference between the two grammars is that a statically-typed
 function must provide a type annotation for its formal parameter.
The second, minor difference is that each grammar includes a
 @emph{boundary term} for embedding an expression of the other grammar.
The expression @${(\edyn{\tau}{\exprdyn})} embeds a dynamically-typed subexpression in a
 statically-typed context, and the expression @${(\esta{\tau}{\exprsta})} embeds a
 statically-typed subexpression in a dynamically-typed context.

The last components in @figure-ref{fig:multi-syntax} specify the names of
 primitive operations (@${\vunop} and @${\vbinop}).
The primitives represent low-level procedures that operate on bitstrings rather than
 abstract syntax.

@include-figure["fig:multi-syntax.tex" @elem{Twin languages syntax}]
@include-figure["fig:multi-preservation.tex" @elem{Twin languages static typing judgments}]

@Figure-ref{fig:multi-preservation} presents a relatively straightforward typing
 system for the complete syntax, augmented with error terms.
To accomodate the two kinds of expressions, there are two typing judgments.
The first judgment, @${\Gamma \wellM \exprdyn}, essentially states that the
 expression @${e} is closed; this weak property characterizes the ahead-of-time
 checking available in some dynamically-typed languages.
The second judgment, @${\Gamma \wellM \exprsta : \tau}, is a mostly-conventional static
 type checker; given an expression and a type, the judgment holds if the two match up.
The unconventional part of both judgments are the rules for boundary terms,
 which invoke the opposite judgment on their subexpressions.
For example, @${\Gamma \wellM \esta{\tau}{e}} holds only if the enclosed expression
 is well-typed.

Two auxiliary components of the type system are the function @${\Delta},
 which assigns a type to the primitives, and a subtyping
 judgment based on the subset relation between natural numbers and integers.
Subtyping adds a logical distinction to the type system that is not automatically
 enforced by the host language or the primitives; as mentioned, programmers invent many more.


@; -----------------------------------------------------------------------------
@section[#:tag "sec:common-semantics"]{Common Semantic Notions}

Each model consists of two reduction relations: one for statically-typed
 expressions (@${\rrSstar}) and one for dynamically-typed ones (@${\rrDstar}).
Both reduction relations must satisfy three criteria:
@; the following criteria:
@itemlist[
@item{
  @emph{soundness for a single language} : for expressions without boundary
   terms, both typing judgments in @figure-ref{fig:multi-preservation} are sound
   with respect to the matching reduction relation;
}
@item{
  @emph{expressive boundary terms} : static and dynamic contexts can
   share values at any type;
   @;more formally, for any type @${\tau} there must
   @;be at least four values such that @${(\edyn{\tau}{v_d}) \rrSstar v} and
   @;@${(\esta{\tau}{v_s}) \rrDstar v'};
}
@item{
  @emph{soundness for the pair of languages} : for all expressions,
   evaluation preserves some property that is implied by the surface notion of typing,
   but it is neither the same nor necessarily a straightforward generalization
   of single-language soundness.
}
]
@Figure-ref{fig:multi-reduction} introduces the common semantic notions.
The syntactic components of this figure are expressions @${e},
 values @${v}, irreducible results @${\vresult},
 and two kinds of evaluation context.
A boundary-free context @${\ebase} does not contain @${\vdyn} or @${\vsta} boundary terms but a multi-language
 context @${\esd} may.

The semantic components in @figure-ref{fig:multi-reduction} are the
 @${\delta} function and the @${\rrS} and @${\rrD} notions of reduction@~cite[b-lambda-1981].
 The @${\delta} function
 is a computable, partial mathematical specification for the primitives.
The partial nature of @${\delta} represents certain
 errors that the use of a primitive operation may trigger.
Specifically, primitive operations give rise to two kinds of errors:
@itemlist[

@item{The semantic models reduce a program to a @italic{tag error} when a
 primitive operation is applied to inappropriate values.  Mathematically
 speaking, the @${\delta} function is undefined for the values. The name
 alludes to the idea that (virtual or abstract) machines represent one form of
 value differently from others, e.g., pointers to functions have different
 type-tag bits than integers.  Thus, the machine is able to report the addition of a
 function to an integer as a tag mismatch.}

@item{By contrast, a @italic{boundary error} is the result of applying a
 partial primitive operation, such as division, to well-typed but exceptional
 values.
 Division-by-zero is a representative example.
 Mathematically put, the @${\delta} function is defined for these values,
 and the result represents a boundary error. The name suggests that the
 run-time library, which implements these primitive operations directly as
 hardware instructions, represents an untyped part of the program and that
 both the statically typed and dynamically typed parts send values across a
 boundary into this component. The name ``boundary error''
 anticipates the generalization of the concept to programs that mix typed
 and untyped code. In a mixed-typed program, a boundary error may arise, e.g.,
 when an untyped subexpression evaluates to a negative integer and its typed
 context expects a natural number.}
]
@exact{\noindent}The functions @${\Delta} and @${\delta} must satisfy a
 typability condition@~cite[wf-ic-1994]:

@tr-proposition[#:key "delta-typability" @elem{@${\delta} typability}]{
  @itemlist[
    @item{
      If @${\wellM v : \tau_v} and @${\Delta(\vunop, \tau_v) = \tau} then @${\wellM \delta(\vunop, v) : \tau}.
    }
    @item{
      If @${\wellM v_0 : \tau_0} and @${\wellM v_1 : \tau_1} and @${\Delta(\vbinop, \tau_0, \tau_1) = \tau} then @${\wellM \delta(\vbinop, v_0, v_1) : \tau}.
    }
  ]
}

The notion of reduction @${\rrS} defines a semantics for statically-typed expressions.
It relates the left-hand side to the right-hand side on an unconditional basis,
 which expresses the reliance on the type system to prevent stuck terms up
 front.
The notion of reduction @${\rrD} defines a semantics for dynamically-typed expressions.
A dynamic expression may attempt to apply an integer or
 send inappropriate arguments to a primitive operation.
Hence, @${\rrD} explicitly checks for
 malformed expressions and signals a tag error.
These checks make the untyped language safe.

The three models in the following sections build upon @figure-ref{fig:multi-reduction}.
They define a pair of @emph{boundary functions} (@${\vfromdyn} and @${\vfromsta})
 for transporting a value across a boundary term,
 extend the @${\rrS} and @${\rrD} notions of reduction,
 and syntactically close the notions of reduction to reduction relations @${\rrSstar} and
 @${\rrDstar} for multi-language evaluation contexts.
Lastly, the models define a two-part syntactic property that is
 sound with respect to the reduction relations.

@include-figure["fig:multi-reduction.tex" @elem{Common semantic notions}]


@; -----------------------------------------------------------------------------
@section[#:tag "sec:natural-embedding"]{@|HOlong| Embedding}

The @|holong| embedding is based on the idea that types enforce levels
 of abstraction@~cite[r-ip-1983].
In a conventional typed language, the type checker ensures that the whole
 program respects these abstractions.
A migratory typing system can provide a similar guarantee if the semantics
 dynamically enforces a type specification on every untyped value that enters
 a typed context.
Higher-order types require @|holong| dynamic enforcement.

@include-figure*["fig:natural-reduction.tex" @elem{@|HOlong| Embedding}]

The @|holong| embedding uses a type-directed strategy to @mytech{transport}
 a value across a type boundary.
If an untyped value meets a boundary that expects
 a value of a base type, such as @${\tint},
 then the strategy is to check the shape of the value.
If the boundary expects a value of an algebraic type, such as a pair,
 then the strategy is to check the value and recursively transport its components.
Lastly, if the boundary expects a value of a higher type, such as
 @${(\tarr{\tnat}{\tnat})}, then the strategy is to check the constructor and
 monitor the future interactions between the value and the context.
For the specific case of an untyped function @${f} and the type @${(\tarr{\tnat}{\tnat})},
 the @|holong| embedding wraps @${f} in a proxy.
The wrapper checks that every result computed by @${f} is of type @${\tnat}
 and otherwise halts the program with a witness that @${f} does not match the type.
@; There is no need to check the argument because the application takes place in
@;  a typed region.

@subsection[#:tag "sec:natural:model"]{Model}

@Figure-ref{fig:natural-reduction} presents a model of the @|holong| embedding.
The centerpiece of the model is the pair of @mytech{boundary functions}:
 @${\vfromdynN} and @${\vfromstaN}.
The @${\vfromdynN} function imports a dynamically-typed value into a statically-typed
 context by checking the shape of the value and proceeding as outlined above.
In particular, the strategy for transporting an untyped value @${v} into a
 context expecting a function with domain @${\tau_d} and codomain @${\tau_c}
 is to check that @${v} is a function and create a monitor @${(\vmonfun{(\tarr{\tau_d}{\tau_c})}{v})}.
Conversely, the @${\vfromstaN} function exports a typed value to an untyped context.
It transports an integer as-is, transports a pair recursively,
 and wraps a function in a monitor to protect the typed function against untyped arguments.

The extended notions of reduction in @figure-ref{fig:natural-reduction} define the complete semantics of monitor application.
In a statically-typed context, applying a monitor entails applying a
 dynamically-typed function to a typed argument.
Thus the semantics unfolds the monitor into two boundary terms:
 a @${\vdyn} boundary in which to apply the dynamically-typed function
 and an inner @${\vsta} boundary to transport the argument.
In a dynamically-typed context, a monitor encapsulates a typed function and
 application unfolds into two dual boundary terms.

The boundary functions and the notions of reductions together
 define the semantics of mixed-typed expressions.
There are two main reduction relations: @${\rrNSstar} for typed expressions
 and @${\rrNDstar} for untyped expressions.
The only difference between the two is how they act on an expression that
 does not contain boundary terms.
The typed reduction relation steps via @${\rrS} by default, and the
 untyped relation steps via @${\rrD} by default.
For other cases, the relations are identical.

@;In principle, the one monitor value @${(\vmonfun{(\tarr{\tau_d}{\tau_c})}{v})}
@; could be split into two value forms: one for protecting the domain of a statically-typed
@; function and one for checking the range of a dynamically-typed function.
@;The split would clarify @${\rrNS} and @${\rrND} but it would also create a
@; larger gap between the model and MODEL (@section-ref{sec:implementation}).


@subsection[#:tag "sec:natural:soundness"]{Soundness}
@include-figure*["fig:natural-preservation.tex" @elem{Property judgments for the @|holong| embedding}]

@Figure-ref{fig:natural-preservation} presents two properties for the @|holong|
 embedding: one for dynamically-typed expressions and one
 for statically-typed expressions.
Each property extends the corresponding judgment from @figure-ref{fig:multi-preservation}
 with a rule for monitors.
The property for dynamic expressions (in the left column) states that a
 typed value may be wrapped in a monitor of the same type.
The static property states that any untyped value may be wrapped in a monitor,
 and that the monitor is assumed to follow its type annotation.

The soundness theorems for the @|holong| embedding state three results about
 surface-language expressions:
 (1) reduction is fully defined, (2) reduction in a statically-typed context
 cannot raise a tag error, and (3) reduction preserves the properties from
 @figure-ref{fig:natural-preservation}.

@exact{\vspace{-2ex}}
@twocolumn[
  @tr-theorem[#:key "N-static-soundness" @elem{static @${\langN}-soundness}]{
    If @${\wellM e : \tau} then @${\wellNE e : \tau} and one
    @linebreak[]
    of the following holds:
    @itemlist[
      @item{ @${e \rrNSstar v \mbox{ and } \wellNE v : \tau} }
      @item{ @${e \rrNSstar \ctxE{\edyn{\tau'}{\ebase[e']}}} and @${e' \rrND \tagerror} }
      @item{ @${e \rrNSstar \boundaryerror} }
      @item{ @${e} diverges}
    ] }

  @tr-theorem[#:key "N-dynamic-soundness" @elem{dynamic @${\langN}-soundness}]{
    If @${\wellM e} then @${\wellNE e} and one
    @linebreak[]
    of the following holds:
    @itemlist[
      @item{ @${e \rrNDstar v \mbox{ and } \wellNE v} }
      @item{ @${e \rrNDstar \ctxE{e'}} and @${e' \rrND \tagerror} }
      @item{ @${e \rrNDstar \boundaryerror} }
      @item{ @${e} diverges}
    ] }@;
]
@exact{\vspace{-8ex}}
@tr-proof[#:sketch? #true]{
  First, @${\wellM e : \tau} implies @${\wellNE e : \tau}
   (similarly for the dynamic property)
   because the latter
   judgment generalizes the former.
  The rest follows from progress and
   preservation lemmas@~cite[gf-tr-2018].
}

One notable lemma for the proof states that the codomain of
 the @${\vfromdynN} boundary function is typed.

@tr-lemma[#:key "N-D-soundness" @elem{@${\vfromdynN} soundness}]{
  If @${\Gamma \wellNE v} and @${\efromdynN{\tau}{v} = e} then @${\Gamma \wellNE e : \tau}
}@;
@;
A similar lemma does not hold of the surface-language typing judgment.
To illustrate, let @${v} be the identity function @${(\vlam{x}{x})}.
In this case @${\wellM v} holds but @${\efromdynN{(\tarr{\tint}{\tint})}{v}}
 returns a monitor, which is not part of the surface language but rather an
 extension to support mixed-typed programs.
A language with mutable data would require a similar extension
 to monitor reads and writes@~cite[stff-oopsla-2012].

@; -----------------------------------------------------------------------------
@section[#:tag "sec:erasure-embedding"]{@|EOlong| Embedding}
@include-figure["fig:erasure-reduction.tex" @elem{@|EOlong| Embedding}]
@include-figure["fig:erasure-preservation.tex" @elem{Common property judgment for the @|eolong| embedding}]

@; types should not affect semantics.
@; "syntactic discipline" is a quote from J. Reynolds

The @|eolong| approach is based on a view of types as an optional syntactic artifact.
Type annotations are just a structured form of comment; their presence (or absence)
 should not affect the behavior of a program.
The main purpose of types is to help developers read a codebase.
A secondary purpose is to enable static type checking and IDE tools.
Whether the types are sound is incidental.
 @; , since type soundness never holds for the entirety of a practical language.

The justification for the @|eolong| point of view is that the host
 language can safely execute both typed and untyped code.
Thus any value may cross any type boundary without further checking.


@subsection[#:tag "sec:erasure:model"]{Model}

@Figure-ref{fig:erasure-reduction} presents a semantics for @|eolong|.
The two boundary functions, @${\vfromdynE} and @${\vfromstaE}, let values freely cross type boundaries.
The two notions of reduction must therefore accomodate values from the opposite grammar.
The static notion of reduction @${\rrES} allows
 the application of dynamically-typed functions and checks for invalid uses
 of the primitives.
The dynamic notion of reduction @${\rrED} allows the application of
 statically-typed functions.
The reduction relations @${\rrESstar} and @${\rrEDstar} are based on the
 compatible closure of the matching notion of reduction.


@subsection[#:tag "sec:erasure:soundness"]{Soundness}

@Figure-ref{fig:erasure-preservation} extends the judgment for a well-formed
 dynamically-typed expression to accomodate type-annotated expressions.
This judgment ignores the type annotations; for any expression @${e}, the
 judgment @${\wellEE e} holds if @${e} is closed.
Soundness for the @|eolong| embedding states that reduction is well-defined
 for statically-typed and dynamically-typed expressions.

@exact{\vspace{-2ex}}
@twocolumn[
  @tr-theorem[#:key "E-static-soundness" @elem{static @${\langE}-soundness}]{
    If @${\wellM e : \tau} then @${\wellEE e} and one
    @linebreak[]
    of the following holds:
    @itemlist[
      @item{ @${e \rrESstar v \mbox{ and } \wellEE v} }
      @item{ @${e \rrESstar \tagerror} }
      @item{ @${e \rrESstar \boundaryerror} }
      @item{ @${e} diverges}
    ] }

  @tr-theorem[#:key "E-dynamic-soundness" @elem{dynamic @${\langE}-soundness}]{
    If @${\wellM e} then @${\wellEE e} and one
    @linebreak[]
    of the following holds:
    @itemlist[
      @item{ @${e \rrEDstar v \mbox{ and } \wellEE v} }
      @item{ @${e \rrEDstar \tagerror} }
      @item{ @${e \rrEDstar \boundaryerror} }
      @item{ @${e} diverges}
    ] }
]
@exact{\vspace{-9ex}}
@tr-proof[#:sketch? #true]{
  A well-typed term is closed, therefore @${\wellM e : \tau} implies that @${\wellEE e} holds.
  The rest follows from progress and preservation lemmas@~cite[gf-tr-2018].
}

The @|eolong| embedding is clearly unsound with respect to types for mixed-typed
 expressions.
A simple example is the expression @${(\edyn{\tint}{\vpair{2}{2}})}, which has the static
 type @${\tint} but reduces to a pair.
The embedding is sound, however, for well-typed expressions that do not
 contain boundary terms.
In other words, a disciplined programmer who avoids external libraries may be
 justified in assuming that evaluation preserves static types and never
 results in a tag error.

@tr-theorem[#:key "E-pure-static" @elem{boundary-free @${\langE}-soundness}]{
  If @${\wellM e : \tau} and @${e} does not contain a subexpression @${(\edyn{\tau'}{e'})}, then
   one of the following holds:
  @itemlist[
    @item{ @${e \rrESstar v \mbox{ and } \wellM v : \tau} }
    @item{ @${e \rrESstar \boundaryerror} }
    @item{ @${e} diverges}
  ]
}
@exact{\vspace{0ex}}
@tr-proof[#:sketch? #true]{
  By progress and preservation lemmas@~cite[gf-tr-2018].
}


@; -----------------------------------------------------------------------------
@section[#:tag "sec:locally-defensive-embedding"]{@|FOlong| Embedding}
@include-figure*["fig:locally-defensive-reduction.tex" @elem{@|FOlong| Embedding}]

@; types should prevent logical stuck-ness

The @|folong| approach is the result of two assumptions: one philosophical,
 one pragmatic.
The philosophical assumption is that the purpose of types is to prevent evaluation
 from ``going wrong''@~cite[m-jcss-1978] in the sense of applying a typed elimination form to a value
 outside its domain.
In particular, the elimination forms in our surface
 language are function application and primitive application.
A  function application @${(\eapp{v_0}{v_1})} expects @${v_0} to be a function;
 primitive application expects arguments for which @${\delta}
 is defined.
The goal of the @|folong| embedding is to ensure that such basic assumptions
 are always satisfied in typed contexts.
@; ... what about Nat? ... generalized form of tag error

The pragmatic assumption is that run-time monitoring is impractical.
For one, implementing monitors requires a significant engineering effort@~cite[stff-oopsla-2012].
Such monitors must preserve all the observations that dynamically-typed code
 can make of the original value, including object-identity tests.
@; TODO treatJS ? also cite chaperones, TS*, Retic
Second, monitoring adds a significant run-time cost.

Based on these assumptions, the @|folong| semantics employs a
 type-directed rewriting pass over typed code to defend against untyped inputs.
The defense takes the form of type-constructor checks; for example,
 if a typed context expects a value of type @${(\tarr{\tnat}{\tnat})} then a
 run-time check asserts that the context receives a function.
If this function is applied @emph{in the same context}, then a second run-time
 check confirms that the result is a natural number.
If the same function is applied @emph{in a different typed context} that expects a
 result of type @${(\tpair{\tint}{\tint})}, then a different run-time check confirms that
 the result is a pair.

Constructor checks run without creating monitors,
 work in near-constant time,@note{The constructor check for a union type or
 structural object type may require time linear in the size of the type.}
 and ensure that every value in a typed context has the correct top-level shape.
If the notions of reduction rely only on the top-level shape of a value to avoid stuck states,
 then the latter guarantee implies that well-typed programs do not ``go wrong'',
 just as desired.
@; or rather, "do not apply a typed elimination form to a value outside its domain" ?


@subsection[#:tag "sec:locally-defensive:model"]{Model}

@Figure-ref{fig:locally-defensive-reduction} presents a model of the
 @|folong| approach.
The model represents a type-constructor check as a @${\vchk} expression;
 informally, the semantics of @${(\echk{K}{e})} is to reduce @${e} to a value
 and affirm that it matches the @${K} constructor.
Type constructors @${K} include one constructor @${\tagof{\tau}} for each
 type @${\tau}, and the technical @${\kany} constructor, which
 does not correspond to a static type.

The purpose of @${\kany} is to reflect the weak invariants of the @|folong|
 semantics.
In contrast to full types, type constructors say nothing about the
 contents of a structured value.
The first and second components of a generic @${\kpair} value can have any shape,
 and similarly the result of applying a function of constructor @${\kfun} can be any
 value.@note{Since the contractum of function application is an expression,
  the model includes the ``no-op'' boundary term @${(\edynfake{e})}
  to support the application of an untyped function in a typed context.
  The @${(\estafake{e})} boundary serves a dual purpose. These two forms facilitate
  the proofs of the progress and preservation lemmas.
  They need not appear in an implementation.}
Put another way, the @${\kany} constructor is necessary because information about
 type constructors is not compositional.

In the model, the above-mentioned rewriting pass corresponds
 to the judgment @${\Gamma \vdash e : \tau \carrow e'}, which states that @${e'}
 is the @emph{completion}@~cite[h-scp-1994] of the surface language expression.
The rewritten expression @${e'} includes @${\vchk} forms around:
 function applications, @${\vfst} projections, and @${\vsnd} projections.
For any other expression, the result is constructed by structural recursion.

The semantics ensures that every expression of type
 @${\tau} reduces to a value that matches the @${\tagof{\tau}} constructor.
The boundary function @${\vfromdynK} checks that an untyped value
 entering typed code matches the constructor of the expected type;
 its implementation defers to the
 @${\vfromany} boundary-crossing function.
The boundary function @${\vfromstaK} lets any typed
 value---including a fuction---cross into an untyped context.

The notions of reduction consequently treat the type annotation @${\tau_d} on
 the formal parameter of a typed function @${(\vlam{\tann{x}{\tau_d}}{e})}
 as an assertion that its actual parameter matches the @${\tagof{\tau_d}} constructor.
Thus the @${\rrKD} notion of reduction protects typed functions from untyped arguments.
Similarly, the static @${\rrKS} notion of reduction protects typed functions
 against @emph{typed} arguments; the following example demonstrates the need
 for this protection by applying a typed function that expects an integer to
 a typed pair value:

@dbend[
  @warning{
    \wellM (\eapp{(\esta{(\tarr{\tpair{\tint}{\tint}}{\tint})}{(\edyn{(\tarr{\tint}{\tint})}{(\vlam{\tann{x}{\tint}}{\esum{x}{x}})})})}{\vpair{0}{0}}) : \tint
  }
]

@exact{\noindent}@bold{Note:} one alternative way to protect the body of a typed
 function is to extend the core language with syntax for domain checks@~cite[vss-popl-2017].
A second alternative is to encode domain checks into the completion of a typed
 function, in the spirit of
    @${(\vlam{\tann{x}{\tau_d}}{e}) \carrow
       (\vlam{\tann{x}{\tau_d}}{(\eapp{(\eapp{(\vlam{y}{\vlam{z}{z}})}{(\echk{\tagof{\tau_d}}{x})})}{e})})}.
For the model, we picked the approach that we found to be the clearest.@exact{\hfill\textbf{End note.}}

The remaining rules of @${\rrKS} give semantics to the application of an
 untyped function and to the @${\vchk} type-constructor checks.
Finally, the @${\rrKSstar} and @${\rrKDstar} reduction relations define
 a multi-language semantics for the model.


@subsection[#:tag "sec:locally-defensive:soundness"]{Soundness}

@Figure-ref{fig:locally-defensive-preservation} presents two judgments that express
 the invariants of the @|folong| semantics.
The first judgment, @${\Gamma \wellKE e}, applies to untyped expressions.
The second judgment is a constructor-typing system that formalizes the intuitions stated above;
 in particular,
 the value of a typed variable is guaranteed to match its type constructor,
 the @${\vfst} projection can produce any kind of value,
 and the result of a @${\vchk} expression matches the
 given constructor.

Soundness for the @|folong| embedding states that the evaluation of the
 @emph{completion} of any surface-level expression preserves the constructor
 of its static type.
The theorems furthermore state that only the @${\rrKD} notion of reduction
 can yield a tag error, therefore such errors can only occur in dynamically-typed contexts.

@twocolumn[
  @tr-theorem[#:key "K-static-soundness" @elem{static @${\langK}-soundness}]{
    If @${\wellM e : \tau} then
    @${\wellM e : \tau \carrow e''}
    and @${\wellKE e'' : \tagof{\tau}}
    @linebreak[]
    and one of the following holds:
    @itemlist[
      @item{ @${e'' \rrKSstar v} and @${\wellKE v : \tagof{\tau}} }
      @item{ @${e''\!\rrKSstar\!\ctxE{\edyn{\tau'}{\ebase[e']}}} and @${e'\!\rrKD\!\!\tagerror} }
      @item{ @${e'' \rrKSstar \ctxE{\edynfake{\ebase[e']}}} and @${e' \rrKD \tagerror} }
      @item{ @${e'' \rrKSstar \boundaryerror} }
      @item{ @${e''} diverges }
    ]
  }

  @tr-theorem[#:key "K-dynamic-soundness" @elem{dynamic @${\langK}-soundness}]{
    If @${\wellM e} then
    @${\wellM e \carrow e''}
    and @${\wellKE e''}
    @linebreak[]
    and one of the following holds:
    @itemlist[
      @item{ @${e'' \rrKDstar v} and @${\wellKE v} }
      @item{ @${e'' \rrKDstar \ctxE{e'}} and @${e' \rrKD \tagerror} }
      @item{ @${e'' \rrKDstar \boundaryerror} }
      @item{ @${e''} diverges }
    ]
  }
]
@exact{\vspace{-8ex}}
@tr-proof[#:sketch? #true]{
  By progress and preservation lemmas@~cite[gf-tr-2018].
}

@; --- completion lemmas
@;@twocolumn[
@;  @tr-lemma[#:key "K-S-completion" @elem{static @${\carrow} soundness}]{
@;    If @${\Gamma \wellM e : \tau} then
@;    @linebreak[]
@;    @${\Gamma \vdash e : \tau \carrow e'} and @${\Gamma \wellKE e' : \tagof{\tau}}
@;  }
@;
@;  @tr-lemma[#:key "K-D-completion" @elem{dynamic @${\carrow} soundness}]{
@;    If @${\Gamma \wellM e} then
@;    @linebreak[]
@;    @${\Gamma \wellM e \carrow e'} and @${\Gamma \wellKE e'}
@;  }
@;]

@; --- check lemma
@;@tr-lemma[#:key "K-check" @elem{@${\vfromany} soundness}]{
@;  If @${\mchk{K}{v} = v}
@;   @linebreak[]
@;   then @${\wellKE v : K}
@;}


@section[#:tag "sec:practical-semantics"]{From Models to Implementations}

@include-figure*["fig:locally-defensive-preservation.tex" @elem{Property judgments for the @|folong| embedding}]

@; AKA threats to the validity of the models

@; TODO
@; - type-constructor checks suffice to prevent stuck-ness

While the models use two reductions, one for the typed and one for the untyped
 fragments of code, any practical migratory typing system compiles typed expressions to the
 host language.
In terms of the models, this means @${\rrD} is the only notion of reduction,
 and statically-typed expressions are rewritten so that @${\rrDstar} applies.

@;To resolve this challenge, it suffices to build a reduction relation based on @${\rrD}
@; and conservatively guard @${\vsta} boundaries with the @${\vfromdyn} boundary
@; function.

A secondary semantic issue concerns the rules for the application of a typed
 function in the @|folong| embedding.
As written, the @${\rrKD} notion of reduction implies a non-standard protocol
 for function application @${(\eapp{v_0}{v_1})}, namely:
 (1) check that @${v_0} is a function;
 (2) check whether @${v_0} was defined in typed code;
 (3) if so, then check @${v_1} against the static type of @${v_0}.
If the host language does not support this protocol, a conservative
 work-around is to extend the completion judgment to add a constructor-check
 to the body of every typed function.
Using pseudo-syntax @${e_0;\,e_1} to represent sequencing, a suitable completion rule is:
@exact|{
  \begin{mathpar}
  \inferrule*{
    \tann{x}{\tau}, \Gamma \wellM e \carrow e'
  }{
    \Gamma \wellM \vlam{\tann{x}{\tau_d}}{e} \carrow \vlam{\tann{x}{\tau_d}}{\vchk{\tagof{\tau_d}}{x};\,e'}
  }
  \end{mathpar}
}|@;

Lastly, the models do not mention union types, universal types,
 and recursive types---all of which are common tools for reasoning about
 dynamically-typed code.
To extend the @|holong| embedding with support for these types, the language
 must add new kinds of monitors to enforce type soundness for their
 elimination forms.
The literature on Typed Racket presents one strategy for handling such types@~cite[stff-oopsla-2012 tfdfftf-ecoop-2015].
To extend the @|folong| embedding, the language must add unions @${K \cup K}
 to its grammar of type constructor and must extend the @${\tagof{\cdot}} function.
For a union type, let @${\tagof{\tau_0 \cup \tau_1}} be @${\tagof{\tau_0} \cup \tagof{\tau_1}},
 i.e., the union of the constructors of its members.
For a universal type @${\tall{\alpha}{\tau}} let the constructor be @${\tagof{\tau}},
 and for a type variable let @${\tagof{\alpha}} be @${\kany} because there are
 no elimination forms for a universally-quantified type variable.@note{This
  treatment of universal types does not enforce parametricity.}
For a recursive type @${\trec{\alpha}{\tau}}, let the constructor be
 @${\tagof{\vsubst{\tau}{\alpha}{\trec{\alpha}{\tau}}}}; this definition is
 well-founded if all occurrences of the variable occur within some type
 @${\tau'} such that @${\tagof{\tau'}} has a non-recursive definition.

