#lang gf-pldi-2018
@title[#:tag "sec:related-work"]{Related Work}

@parag{Multi-Language Semantics}

Matthews-Findler originated.
Dimoulas for complete monitoring.

Erased embedding, see TypeScript and pluggable types.
@; does the academic history go deeper?

Natural embedding formatlized by Matthews / Findler,
 based on lots of prior work about type-safe FFIs.
@; thank you based Robby, perfect reference material

Co-Natural is our own, but the idea comes from Findler / Felleisen.

Forgetful by Greenberg.
Never would have taken it seriously otherwise.

Tagged by Vitousek.
This work started by trying to replicate their compiler,
 wound up with many difficult questions.
We confirm their performance results with an apples-to-apples for TR,
 and outline the research landscape for improving tag-soundness.


@parag{Migratory Typing}

Tobin-Hochstadt, Typed Racket.


@parag{Type-Tag Soundness}

@citet[vss-popl-2017] present a compiler from type-annotated source code
 to a dynamically typed host language.
They prove that the generated code is tag sound.
First implementation of the forgetful, first-order embedding.

@;... in a way, our Section 3 is adding the missing "why" from their paper,
@;I mean they give high-level motivation, but that's all besides "proofs worked out".
@;Very frustrating.
@;There are many design choices, important to know why this particular set
@; makes sense for what context.
@;Because it's not always going to be true for all contexts.
@;
@; 2017-11-05 : trouble reverse-engineering the model, whence the story

@; retic calls it "transient" as opposed to the "guarded" natural embedding.
@; we aren't saying "transient" because believe it confuses two things,
@; - forgetting types
@; - only tag-checks
@;
@; BUT I STILL DONT HAVE A NAME

@; Question: does reticulated follow the model?
@;  Yes basically. Something's wrong checking [] twice but the same problem
@;   doesn't happen with integers so I guess its fine.

@;Like types@~cite[bfnorsvw-oopsla-2009] are annotations with no semantics.
@;@citet[rnv-ecoop-2015] apply the idea to TypeScript; TypeScript has only like types,
@; and their work gives programmers the choice of using (concrete) types that
@; are enforced at run-time.

@section{Gradual Typing}
Extremely similar.
A migratory typing system is a gradual typing system designed for an existing
 dynamically-typed language.
The dynamic type and type compatibility relations are optional.

Not sure about that gradual guarantee.
For us, no matter how your system evolves you can count on type soundness.
@; thats part of why we say 'migratory'

Gradual typing broadly construed = any kind of research about mixing
 static/dynamic typing, where statically-typed is denoted by explicit type
 annotations.
In this sense, migratory typing is a special case.

Recently Siek etal propose gradual guarantee, suggest that a gradual typing
 system
In this sense, a gradual typing system is one kind of migratory typing system.


@; progressive types
@; redex
@; redex-check
@; levity polymorphism, ideas for compiling functions that MIGHT need checks
