#lang gf-pldi-2018
@require{techreport.rkt}

@appendix-title++{Locally-Defensive Embedding}

@; -----------------------------------------------------------------------------
@section{@${\langK} Definitions}
@exact{\input{fig:locally-defensive-embedding.tex}}

@; -----------------------------------------------------------------------------
@|clearpage|
@section{@${\langK} Properties}

@tr-theorem[#:key "K-soundness" @elem{@${\langK} type-tag soundness}]{
  If @${\wellM e : \tau}
   and @${\tagof{\tau} = K}, then
   @${\wellM e : \tau \carrow e'}
   and
   @${\wellKE e' : K}
   and either:
@itemlist[
  @item{ @${e^+ \rrKEstar v} and @${\wellKE v : K} }
  @item{ @${e^+ \rrKEstar E[e'] \ccKD \tagerror} }
  @item{ @${e^+ \rrKEstar \boundaryerror} }
  @item{ @${e^+} diverges }
]}@tr-proof{
  Both @${\wellM e : \tau \carrow e^+} and @${\wellKE e^+ : K} follow from
   @tr-ref[#:key "completion soundness"]{soundness of @${\carrow}}.
  The outcomes for @${\rrKEstar} follow from @tr-ref[#:key "K-S-progress"]{progress}
   and @tr-ref[#:key "K-S-preservation"]{preservation} lemmas
   for the @${\wellKE} relation.
}

@; -----------------------------------------------------------------------------
@tr-lemma[#:key "K-S-progress" @elem{@${\langK} static progress}]{
  If @${\wellKE e : K} then either:
  @itemlist[
    @item{ @${e} is a value }
    @item{ @${e \ccKS e'} }
    @item{ @${e \ccKS \boundaryerror} }
    @item{ @${e \eeq \ctxE{\edyn{\tau}{e'}} \mbox{ and } e' \ccKD \tagerror} }
]}@tr-proof{
  By case analysis on the structure of @${e};
   by the @tr-ref[#:key "K-S-uec"]{unique evaluation contexts} lemma,
   there are seven cases to consider.

  @tr-case[@${e \eeq v}]{
    @tr-qed{}
  }

  @tr-case[@${e \eeq \ctxE{\edyn{\tau}{e'}}}
           #:itemize? #false ]{
    @tr-if[@${e' \in v}
           #:itemize? #false ]{
      @tr-if[@${\mchk{\tagof{\tau}}{e'} = e'}]{
        @tr-step[
          @${e \ccKS \ctxE{e'}}
          @${(\edyn{\tau}{e'}) \rrKS e'}]
        @tr-qed[]
      }
      @tr-else[@${\mchk{\tagof{\tau}}{e'} = \boundaryerror}]{
        @tr-step[
          @${e \ccKS \boundaryerror}
          @${(\edyn{\tau}{e'}) \rrKS \boundaryerror}]
        @tr-qed[]
      }
    }
    @tr-else[@${e' \not\in v}]{
      @tr-step[
        @${e' \ccKD A}
        @tr-ref[#:key "K-S-progress"]{static progress}
      ]
      @tr-qed{
        by @${e \ccKS \ctxE{\edyn{\tau}{A}}} if @${A \in e}
        @linebreak[]
        and by @${e \ccKS A} otherwise}
    }
  }

  @tr-case[@${e \eeq \ctxE{\edyn{\kany}{e'}}} #:itemize? #f]{
    @tr-if[@${e' \in v}]{
      @tr-step[
        @${e \ccKS \ctxE{v}}
        @${(\edyn{\kany}{v}) \rrKS v}]
      @tr-qed[]}
    @tr-else[@${e' \not\in v}]{
      @tr-step[
        @${e' \ccKD A}
        @tr-ref[#:key "K-D-progress"]{dynamic progress}]
      @tr-qed{
        by @${e \ccKS \ctxE{\edyn{\kany}{A}}} if @${A \in e}
        @linebreak[]
        and by @${e \ccKS A} otherwise}
    }
  }

  @tr-case[@${e \eeq \ctxE{\echk{K}{v}}} #:itemize? #f]{
    @tr-if[@${\mchk{K}{v} = v}]{
      @tr-step[
        @${e \ccKS \ctxE{v}}
        @${(\echk{K}{v}) \rrKS v}]
      @tr-qed[]
    }
    @tr-else[@${\mchk{K}{v} = \boundaryerror}]{
      @tr-step[
        @${e \ccKS \boundaryerror}
        @${(\echk{K}{v}) \rrKS \boundaryerror}]
      @tr-qed[]
    }
  }

  @tr-case[@${e \eeq \ctxE{v_0~v_1}}]{
    @tr-step[
      @${\wellKE v_0~v_1 : K'}
      @tr-ref[#:key "K-S-hole-typing"]{static hole typing}]
    @tr-step{
      @${\wellKE v_0 : \kfun}
      @tr-ref[#:key "K-S-inversion"]{inversion} (1)}
    @tr-step{
      @${v_0 \eeq \vlam{x}{e'} @tr-or[] v_0 \eeq \vlam{\tann{x}{\tau_d}}{e'}}
      @tr-ref[#:key "K-canonical"]{canonical forms} (2)}
    @list[
      @tr-if[@${v_0 \eeq \vlam{x}{e'}}]{
        @tr-step[
          @${e \ccKS \ctxE{\edyn{\kany}{(\vsubst{e'}{x}{v_1})}}}
          @${(\vlam{x}{e'}~v_1) \rrKS (\edyn{\kany}{(\vsubst{e'}{x}{v_1})})}]
        @tr-qed[]
      }
      @tr-if[@${v_0 \eeq \vlam{\tann{x}{\tau_d}}{e'}
                @tr-and[2]
                \mchk{\tagof{\tau_d}}{v_1} = v_1}]{
        @tr-step[
          @${e \ccKS \ctxE{\vsubst{e'}{x}{v_1}}}
          @${(\vlam{\tann{x}{\tau_d}}{e'})~v_1 \rrKS \vsubst{e'}{x}{v_1}}]
        @tr-qed[]
      }
      @tr-else[@${v_0 \eeq \vlam{\tann{x}{\tau_d}}{e'}
                  @tr-and[4]
                  \mchk{\tagof{\tau_d}}{v_1} = \boundaryerror}]{
        @tr-step[
          @${e \ccKS \boundaryerror}
          @${(\vlam{\tann{x}{\tau_d}}{e'})~v_1 \rrKS \boundaryerror}]
        @tr-qed[]
      }
    ]
  }

  @tr-case[@${e \eeq \ctxE{\eunop{v}}}]{
    @${\vunop \eeq \vfst @tr-or[] \vunop \eeq \vsnd}
    @tr-step[
      @${\wellKE \eunop{v} : K'}
      @tr-ref[#:key "K-S-hole-typing"]{hole typing}]
    @tr-step{
      @${\wellKE v : \kpair}
      @tr-ref[#:key "K-S-inversion"]{inversion} (2)}
    @tr-step{
      @${v \eeq \vpair{v_0}{v_1}}
      @tr-ref[#:key "K-canonical"]{canonical forms} (3)}
    @tr-step{
      @${\delta(\vunop, v) = v_i \mbox{ where } i \in \{0,1\}}
      (1,3)}
    @tr-step{
      @${e \ccKS \ctxE{v_i}}
      @${(\eunop{v}) \rrKS v_i}}
    @tr-qed[]
  }

  @tr-case[@${e \eeq \ctxE{\ebinop{v_0}{v_1}}}]{
    @tr-step{
      @${\wellKE \ebinop{v_0}{v_1} : K'}
      @tr-ref[#:key "K-S-hole-typing"]{hole typing}}
    @tr-step{
      @${\wellKE v_0 : K_0
         @tr-and[] \wellKE v_1 : K_1
         @tr-and[] \Delta(\vbinop, K_0, K_1) = K_2}
      @tr-ref[#:key "K-S-inversion"]{inversion} (1)}
    @tr-step{
      @${\delta(\vbinop, v_0, v_1) = v
         @tr-or[] \delta(\vbinop, v_0, v_1) = \boundaryerror}
      @tr-ref[#:key "K-Delta-soundness"]{@${\Delta} tag soundness}}
    @tr-qed{
      by @${e \ccKS \ctxE{v}} if @${\delta(\vbinop, v_0, v_1)}
      @linebreak[]
      and by @${e \ccKS \boundaryerror} otherwise}
  }
}

@; -----------------------------------------------------------------------------
@tr-lemma[#:key "K-D-progress" @elem{@${\langK} dynamic progress}]{
  If @${\wellKE e} then either @${e} is a value or @${e \ccKD A}.
}@tr-proof{
  By case analysis on the structure of @${e};
   by the @tr-ref[#:key "K-D-uec"]{unique evaluation contexts} lemma,
   there are six cases to consider.

  @tr-case[@${e \eeq v}]{
    @tr-qed[]
  }

  @tr-case[@${e \eeq \ctxE{\esta{\tau}{e'}}} #:itemize? #f]{
    @tr-if[@${e' \in v} #:itemize? #f]{
      @tr-if[@${\mchk{\tagof{\tau}}{e'} = e'}]{
        @tr-step[
          @${e \ccKD \ctxE{e'}}
          @${(\esta{\tau}{e'}) \rrKD e'}]
        @tr-qed[]
      }
      @tr-else[@${\mchk{\tagof{\tau}}{e'} = \boundaryerror}]{
        @tr-step[
          @${e \ccKD \boundaryerror}
          @${(\esta{\tau}{e'}) \rrKD \boundaryerror}]
        @tr-qed[]
      }
    }
    @tr-else[@${e' \not\in v}]{
      @tr-step[
        @${e' \ccKS A}
        @tr-ref[#:key "K-S-progress"]{static progress}]
      @tr-qed{by @${e \ccKD \ctxE{\esta{\tau}{A}}} if @${A \in e}
        @linebreak[] and by @${e' \ccKD A} otherwise}
    }
  }

  @tr-case[@${e \eeq \ctxE{\esta{\kany}{e'}}} #:itemize? #f]{
    @tr-if[@${e' \in v}]{
      @tr-step[
        @${e \ccKD \ctxE{e'}}
        @${(\esta{\kany}{e'}) \rrKD e'}
      ]
      @tr-qed[]
    }
    @tr-else[@${e' \not\in v}]{
      @tr-step[
        @${e' \ccKS A}
        @tr-ref[#:key "K-S-progress"]{static progress}]
      @tr-qed{by @${e \ccKD \ctxE{\esta{\kany}{A}}} if @${A \in e}
        @linebreak[] and by @${e \ccKD A} otherwise}
    }
  }

  @tr-case[@${e \eeq \ctxE{v_0~v_1}}]{
    @tr-if[@${v_0 \eeq \vlam{x}{e_0}}]{
      @tr-step[
        @${e \ccKD \ctxE{\vsubst{e_0}{x}{v_1}}}
        @${(\vlam{x}{e_0})~v_1 \rrKD \vsubst{e_0}{x}{v_1}}]
      @tr-qed[]
    }
    @tr-if[@${v_0 \eeq \vlam{\tann{x}{\tau_d}}{e_0}
              @tr-and[2]
              \mchk{\tagof{\tau_d}}{v_1} = v_1}]{
      @tr-step[
        @${e \ccKD \ctxE{\esta{\kany}{(\vsubst{e_0}{x}{v_1})}}}
        @${(\vlam{\tann{x}{\tau_d}}{e_0})~v_1 \rrKD (\esta{\kany}{\vsubst{e_0}{x}{v_1}})}]
      @tr-qed[]
    }
    @tr-if[@${v_0 \eeq \vlam{\tann{x}{\tau_d}}{e_0}
              @tr-and[2]
              \mchk{\tagof{\tau_d}}{v_1} = \boundaryerror}]{
      @tr-step[
        @${e \ccKD \boundaryerror}
        @${(\vlam{\tann{x}{\tau_d}}{e_0})~v_1 \rrKD \boundaryerror}]
      @tr-qed[]
    }
    @tr-else[@${v_0 \eeq i
                @tr-or[4]
                v_0 \eeq \vpair{v}{v'}}]{
      @tr-step[
        @${e \ccKD \tagerror}
        @${v_0~v_1 \rrKD \tagerror}]
      @tr-qed[]
    }
  }

  @tr-case[@${e = \ctxE{\eunop{v}}} #:itemize? #f]{
    @tr-if[@${\delta(\vunop, v) = v'}]{
      @tr-step[
        @${e \ccKD \ctxE{v'}}
        @${(\eunop{v}) \rrKD v'}]
      @tr-qed[]
    }
    @tr-else[@${\delta(\vunop, v) \mbox{ is undefined}}]{
      @tr-step[
        @${e \ccKD \tagerror}
        @${(\eunop{v}) \rrKD \tagerror}]
      @tr-qed[]
    }
  }

  @tr-case[@${e = \ctxE{\ebinop{v_0}{v_1}}} #:itemize? #f]{
    @tr-if[@${\delta(\vbinop, v_0, v_1) = v'}]{
      @tr-step[
        @${e \ccKD \ctxE{v'}}
        @${(\ebinop{v_0}{v_1}) \rrKD v'}]
      @tr-qed[]
    }
    @tr-if[@${\delta(\vbinop, v_0, v_1) = \boundaryerror}]{
      @tr-step[
        @${e \ccKD \boundaryerror}
        @${(\ebinop{v_0}{v_1}) \rrKD \boundaryerror}]
      @tr-qed[]
    }
    @tr-else[@${\delta(\vbinop, v_0, v_1) \mbox{ is undefined}}]{
      @tr-step[
        @${e \ccKD \tagerror}
        @${(\ebinop{v_0}{v_1}) \rrKD \tagerror}]
      @tr-qed[]
    }
  }
}

@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} static preservation} #:key "lemma:LK-S-preservation"]{
@;  If @${\wellKE e : K} and @${e \ccKS e'} then @${\wellKE e' : K}
@;}
@;
@;@proof{
@;  By @tech{lemma:LK-S-uec} there are six cases to consider.
@;
@;  @proofcase[@${e = \ctxE{\edyn{\tau}{e'}}}]{
@;    @proofif[@${\ctxE{\edyn{\tau}{e'}} \ccKS \ctxE{\edyn{\tau}{e''}}}]{
@;      @proofitems[
@;        @item{
@;          @${\wellKE \edyn{\tau}{e'} : K'}
@;          @proofby{lemma:LK-S-hole-typing}
@;        }
@;        @item{
@;          @${\tagof{\tau} \subt K' \mbox{ or } \tagof{\tau} = K'}
@;          @proofby{lemma:LK-S-inversion}
@;        }
@;        @item{
@;          @${\wellKE e'}
@;          @proofby{lemma:LK-S-inversion}
@;        }
@;        @item{
@;          @${\wellKE e''}
@;          @proofby{lemma:LK-D-preservation}
@;        }
@;        @item{
@;          @${\wellKE \edyn{\tau}{e''} : \tagof{\tau}}
@;          @proofbecause 4
@;        }
@;        @item{
@;          @proofqed by 2,5,@tech{lemma:LK-S-hole-subst}
@;        }
@;      ]
@;    }
@;    @proofelse[@${\ctxE{\edyn{\tau}{v}} \ccKS \ctxE{v}}]{
@;      @proofitems[
@;        @item{
@;          @${\wellKE \edyn{\tau}{v} : K'}
@;          @proofby{lemma:LK-S-hole-typing}
@;        }
@;        @item{
@;          @${\tagof{\tau} \subt K'}
@;          @proofby{lemma:LK-S-inversion}
@;        }
@;        @item{
@;          @${\wellKE v : \tagof{\tau}}
@;          @proofbecause @${\mchk{\tagof{\tau}}{v} = v}
@;        }
@;        @item{
@;          @proofqed by 2,3,@tech{lemma:LK-S-hole-subst}
@;        }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${e = \ctxE{\edyn{\kany}{e'}}}]{
@;    @proofif[@${\ctxE{\edyn{\kany}{e'}} \ccKS \ctxE{\edyn{\kany}{e''}}}]{
@;      @proofitems[
@;        @item{
@;          @${\wellKE \edyn{\kany}{e'} : \kany}
@;          @proofby{lemma:LK-S-hole-typing}
@;        }
@;        @item{
@;          @${\wellKE e'}
@;          @proofby{lemma:LK-inversion}
@;        }
@;        @item{
@;          @${\wellKE e''}
@;          @proofby{lemma:LK-D-preservation}
@;        }
@;        @item{
@;          @${\wellKE \edyn{\kany}{e''} : \kany}
@;          @proofbecause 3
@;        }
@;        @item{
@;          @proofqed by 4,@tech{lemma:LK-S-hole-subst}
@;        }
@;      ]
@;    }
@;    @proofelse[@${\ctxE{\edyn{\kany}{v}} \ccKS \ctxE{v}}]{
@;      @proofitems[
@;        @item{
@;          @${\wellKE \edyn{\kany}{v} : \kany}
@;          @proofby{lemma:LK-S-hole-typing}
@;        }
@;        @item{
@;          @${\wellKE v}
@;          @proofby{lemma:LK-S-inversion}
@;        }
@;        @item{
@;          @${\wellKE v : \kany}
@;          @proofby{lemma:LK-val-tagging}
@;        }
@;        @item{
@;          @proofqed by 3,@tech{lemma:LK-S-hole-subst}
@;        }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${e = \ctxE{\echk{K'}{v}}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{\echk{K'}{v}} \ccKS \ctxE{v}}
@;      }
@;      @item{
@;        @${\wellKE \echk{K'}{v} : K''}
@;        @proofby{lemma:LK-S-hole-typing}
@;      }
@;      @item{
@;        @${K' \subt K''}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\wellKE v : K'}
@;        @proofbecause @${\mchk{K'}{v} = v}
@;      }
@;      @item{
@;        @proofqed by 3,4,@tech{lemma:LK-S-hole-subst}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \ctxE{v_0~v_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\wellKE v_0~v_1 : \kany}
@;        @proofby{lemma:LK-S-hole-typing}
@;      }
@;      @item{
@;        @${\wellKE v_0 : \kfun \mbox{ and } \wellKE v_1 : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${v_0 = \vlam{x}{e} \mbox{ or } v_0 = \vlam{\tann{x}{\tau}}{e}}
@;        @proofby{lemma:LK-canonical}
@;      }
@;    ]
@;
@;    @proofif[@${v_0 = \vlam{x}{e}}]{
@;      @proofitems[
@;        @item{
@;          @${\ctxE{v_0~v_1} \ccKS \ctxE{\edyn{\kany}{\vsubst{e}{x}{v_1}}}}
@;        }
@;        @item{
@;          @${x \wellKE e}
@;          @proofby{lemma:LK-S-inversion}
@;        }
@;        @item{
@;          @${\wellKE v_1}
@;          @proofby{lemma:val-wellformed} 2
@;        }
@;        @item{
@;          @${\wellKE \vsubst{e}{x}{v_1}}
@;          @proofby{lemma:LK-DD-subst} 4,5
@;        }
@;        @item{
@;          @${\wellKE \edyn{\kany}{\vsubst{e}{x}{v_1}} : \kany}
@;          @proofbecause 7
@;        }
@;        @item{
@;          @proofqed by @tech{lemma:LK-S-hole-subst}
@;        }
@;      ]
@;    }
@;
@;    @proofelse[@${v_0 = \vlam{\tann{x}{\tau}}{e}}]{
@;      @proofitems[
@;        @item{
@;          @${\ctxE{v_0~v_1} \ccKS \ctxE{\vsubst{e}{x}{v_1}}
@;             \\\mbox{and } \mchk{\tagof{\tau}}{v_1} = v_1}
@;        }
@;        @item{
@;          @${\wellKE v_1 : \tagof{\tau}}
@;          @proofbecause 4
@;        }
@;        @item{
@;          @${\tann{x}{\tau} \wellKE e : \kany}
@;          @proofby{lemma:LK-S-inversion}
@;        }
@;        @item{
@;          @${\wellKE \vsubst{e}{x}{v_1} : \kany}
@;          @proofby{lemma:LK-SS-subst} 5,6
@;        }
@;        @item{
@;          @proofqed by @lemmaref{lemma:LK-S-hole-subst}
@;        }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${e = \ctxE{\eunop{v}}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{\eunop{v}} \ccKS \ctxE{v'}}
@;        @proofwhere @${\delta(\vunop, v) = v'}
@;      }
@;      @item{
@;        @${\wellKE \eunop{v} : \kany}
@;        @proofby{lemma:LK-S-hole-typing}
@;      }
@;      @item{
@;        @${\wellKE v : \kpair}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${v = \vpair{v_0}{v_1}}
@;        @proofby{lemma:LK-canonical}
@;      }
@;      @item{
@;        @${\wellKE v_0 : \kany \mbox{ and } \wellKE v_1 : \kany}
@;        @proofby{lemma:LK-S-inversion} 3,4
@;      }
@;    ]
@;    @proofif[@${\vunop = \vfst}]{
@;      @proofitems[
@;        @item{
@;          @${\delta(\vfst, v) = v_0}
@;        }
@;        @item{
@;          @proofqed by @lemmaref{lemma:LK-S-hole-subst} (5)
@;        }
@;      ]
@;    }
@;    @proofelse[@${\vunop = \vsnd}]{
@;      @proofitems[
@;        @item{
@;          @${\delta(\vsnd, v) = v_1}
@;        }
@;        @item{
@;          @proofqed by @lemmaref{lemma:LK-S-hole-subst} (5)
@;        }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${e = \ctxE{\ebinop{v_0}{v_1}}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{\ebinop{v_0}{v_1}} \ccKS v}
@;        @proofwhere @${\delta(\vbinop, v_0, v_1) = v}
@;      }
@;      @item{
@;        @${\wellKE \ebinop{v_0}{v_1} : K'}
@;        @proofby{lemma:LK-S-hole-typing}
@;      }
@;      @item{
@;        @${\wellKE v_0 : K_0 \mbox{ and } \wellKE v_1 : K_1 \mbox{ and }
@;           \Delta(\vbinop, K_0, K_1) = K'' \mbox{ and } K'' \subt K'}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\wellKE v : K''}
@;        @proofby{lemma:LK-Delta-soundness} (3)
@;      }
@;      @item{
@;        @${\wellKE v : K'}
@;        @proofbecause 3
@;      }
@;      @item{
@;        @proofqed by @lemmaref{lemma:LK-S-hole-subst}
@;      }
@;    ]
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} dynamic preservation} #:key "lemma:LK-D-preservation"]{
@;  If @${\wellKE e} and @${e \ccKD e'} then @${\wellKE e'}
@;}
@;
@;@proof{
@;  By @lemmaref{lemma:LK-D-uec} there are five cases.
@;
@;  @proofcase[@${e = \ctxE{\esta{\tau}{e'}}}]{
@;    @proofif[@${\ctxE{\esta{\tau}{e'}} \ccKD \ctxE{\esta{\tau}{e''}}}]{
@;      @proofitems[
@;        @item{
@;          @${\wellKE \esta{\tau}{e'}}
@;          @proofby{lemma:LK-D-hole-typing}
@;        }
@;        @item{
@;          @${\wellKE e' : \tagof{\tau}}
@;          @proofby{lemma:LK-D-inversion}
@;        }
@;        @item{
@;          @${\wellKE e'' : \tagof{\tau}}
@;          @proofby{lemma:LK-S-preservation}
@;        }
@;        @item{
@;          @${\wellKE \esta{\tau}{e''}}
@;          @proofbecause 3
@;        }
@;        @item{
@;          @proofqed by @lemmaref{lemma:LK-D-hole-subst}
@;        }
@;      ]
@;    }
@;
@;    @proofelse[@${\ctxE{\esta{\tau}{v}} \ccKD \ctxE{v}}]{
@;      @proofitems[
@;        @item{
@;          @${\wellKE \esta{\tau}{v}}
@;          @proofby{lemma:LK-D-hole-typing}
@;        }
@;        @item{
@;          @${\wellKE v : \tagof{\tau}}
@;          @proofby{lemma:LK-D-inversion}
@;        }
@;        @item{
@;          @${\wellKE v}
@;          @proofby{lemma:LK-val-wellformed}
@;        }
@;        @item{
@;          @proofqed by @lemmaref{lemma:LK-D-hole-subst}
@;        }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${e = \ctxE{\esta{\kany}{e'}}}]{
@;    @proofif[@${\ctxE{\esta{\kany}{e'}} \ccKD \ctxE{\esta{\kany}{e''}}}]{
@;      @proofitems[
@;        @item{
@;          @${\wellKE \esta{\kany}{e'}}
@;          @proofby{lemma:LK-D-hole-typing}
@;        }
@;        @item{
@;          @${\wellKE e' : \kany}
@;          @proofby{lemma:LK-D-inversion}
@;        }
@;        @item{
@;          @${\wellKE e'' : \kany}
@;          @proofby{lemma:LK-S-preservation}
@;        }
@;        @item{
@;          @${\wellKE \esta{\kany}{e''}}
@;          @proofbecause 3
@;        }
@;        @item{
@;          @proofqed by @lemmaref{lemma:LK-D-hole-subst}
@;        }
@;      ]
@;    }
@;
@;    @proofelse[@${\ctxE{\esta{\kany}{v}} \ccKD v}]{
@;      @proofitems[
@;        @item{
@;          @${\wellKE \esta{\kany}{v}}
@;          @proofby{lemma:LK-D-hole-typing}
@;        }
@;        @item{
@;          @${\wellKE v : \kany}
@;          @proofby{lemma:LK-D-inversion}
@;        }
@;        @item{
@;          @${\wellKE v}
@;          @proofby{lemma:LK-val-wellformed}
@;        }
@;        @item{
@;          @proofqed by @lemmaref{lemma:LK-D-hole-subst}
@;        }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${e = \ctxE{v_0~v_1}}]{
@;    @proofif[@${v_0 = \vlam{x}{e}}]{
@;      @proofitems[
@;        @item{
@;          @${\ctxE{v_0~v_1} \ccKD \ctxE{\vsubst{e}{x}{v_1}}}
@;        }
@;        @item{
@;          @${\wellKE v_0~v_1}
@;          @proofby{lemma:LK-D-hole-typing}
@;        }
@;        @item{
@;          @${\wellKE v_0 \mbox{ and } \wellKE v_1}
@;          @proofby{lemma:LK-D-inversion} (2)
@;        }
@;        @item{
@;          @${x \wellKE e}
@;          @proofby{lemma:LK-D-inversion} (3)
@;        }
@;        @item{
@;          @${\wellKE \vsubst{e}{x}{v_1}}
@;          @proofby{lemma:LK-DD-subst} (3,4)
@;        }
@;        @item{
@;          @proofqed by @lemmaref{lemma:LK-D-hole-subst}
@;        }
@;      ]
@;    }
@;
@;    @proofelse[@${v_0 = \vlam{\tann{x}{\tau}}{e}}]{
@;      @proofitems[
@;        @item{
@;          @${\ctxE{v_0~v_1} \ccKD \ctxE{\esta{\kany}{(\vsubst{e}{x}{v_1})}}
@;             \\\mbox{and } \mchk{\tagof{\tau}}{v_1} = v_1}
@;        }
@;        @item{
@;          @${\wellKE v_1 : \tagof{\tau}}
@;          @proofbecause 1
@;        }
@;        @item{
@;          @${\wellKE v_0~v_1}
@;          @proofby{lemma:LK-D-hole-typing}
@;        }
@;        @item{
@;          @${\wellKE v_0}
@;          @proofby{lemma:LK-D-inversion} (3)
@;        }
@;        @item{
@;          @${\tann{x}{\tau} \wellKE e : \kany}
@;          @proofby{lemma:LK-D-inversion} (4)
@;        }
@;        @item{
@;          @${\wellKE \vsubst{e}{x}{v_1} : \kany}
@;          @proofby{lemma:LK-SS-subst} (2, 5)
@;        }
@;        @item{
@;          @${\wellKE \esta{\kany}{(\vsubst{e}{x}{v_1})}}
@;          @proofbecause 6
@;        }
@;        @item{
@;          @proofqed by @lemmaref{lemma:LK-D-hole-subst}
@;        }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${e = \ctxE{\eunop{v}}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{\eunop{v}} \ccKD \ctxE{v'}}
@;        @proofwhere @${\delta(\vunop, v) = v'}
@;      }
@;      @item{
@;        @${\wellKE \eunop{v}}
@;        @proofby{lemma:LK-D-hole-typing}
@;      }
@;      @item{
@;        @${\wellKE v}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE v'}
@;        @proofby{lemma:LK-delta-preservation}
@;      }
@;      @item{
@;        @proofqed by @lemmaref{lemma:LK-D-hole-subst}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \ctxE{\ebinop{v_0}{v_1}}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{\ebinop{v_0}{v_1}} \ccKD \ctxE{v'}}
@;        @proofwhere @${\delta(\vbinop, v_0, v_1) = v'}
@;      }
@;      @item{
@;        @${\wellKE \ebinop{v_0}{v_1}}
@;        @proofby{lemma:LK-D-hole-typing}
@;      }
@;      @item{
@;        @${\wellKE v_0 \mbox{ and } \wellKE v_1}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE v'}
@;        @proofby{lemma:LK-delta-preservation} (3)
@;      }
@;      @item{
@;        @proofqed by @lemmaref{lemma:LK-D-hole-subst}
@;      }
@;    ]
@;  }
@;}
@;
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\carrow} static soundness} #:key "lemma:LK-S-completion-soundness"]{
@;  If @${\Gamma \wellM e : \tau} then @${\Gamma \vdash e : \tau \carrow e'}
@;   and @${\Gamma \wellKE e' : \tagof{\tau}}.
@;}
@;
@;@proof{
@;  By induction on the structure of @${\Gamma \wellM e : \tau}.
@;  Proceed by cases on the last rule used.
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;                \tann{x}{\tau} \in \Gamma
@;              }{
@;                \Gamma \wellM x : \tau
@;              }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \vdash x \carrow x}
@;      }
@;      @item{
@;        @${\Gamma \wellKE x : \tagof{\tau}}
@;        @proofby[@${\tann{x}{\tau} \in \Gamma}]
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;                \tann{x}{\tau_d},\Gamma \wellM e : \tau_c
@;              }{
@;                \Gamma \wellM \vlam{\tann{x}{\tau_d}}{e} : \tau_d \tarrow \tau_c
@;              }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \vdash e : \tau_c \carrow e' \mbox{ and }
@;           \tann{x}{\tau_d},\Gamma \vdash e' : \tagof{\tau_c}}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\tann{x}{\tau_d},\Gamma \vdash e' : \kany}
@;        @proofby[@${\tagof{\tau_c} \subt \kany}]
@;      }
@;      @item{
@;        @${\vlam{\tann{x}{\tau_d}}{e} : \tarr{\tau_d}{\tau_c} \carrow \vlam{\tann{x}{\tau_d}}{e'}}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vlam{\tann{x}{\tau_d}}{e'} : \kfun}
@;        @proofby{2}
@;      }
@;      @item{
@;        @proofqed by 3,4
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;                i \in \naturals
@;              }{
@;                \Gamma \wellM i : \tnat
@;              }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \vdash i : \tnat \carrow i}
@;      }
@;      @item{
@;        @proofqed by @${\Gamma \wellKE i : \knat}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;              }{
@;                \Gamma \wellM i : \tint
@;              }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \vdash i : \tint \carrow i}
@;      }
@;      @item{
@;        @proofqed by @${\Gamma \wellKE i : \kint}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;                \Gamma \wellM e_0 : \tau_0
@;                \\
@;                \Gamma \wellM e_1 : \tau_1
@;              }{
@;                \Gamma \wellM \vpair{e_0}{e_1} : \tpair{\tau_0}{\tau_1}
@;              }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM e_0 : \tau_0 \carrow e_0' \mbox{ and }
@;           \Gamma \wellM e_0' : \tagof{\tau_0}}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellM e_1 : \tau_1 \carrow e_1' \mbox{ and }
@;           \Gamma \wellM e_1' : \tagof{\tau_1}}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellKE e_0 : \kany}
@;        @proofbecause @${\tagof{\tau_0} \subt \kany}
@;      }
@;      @item{
@;        @${\Gamma \wellKE e_1 : \kany}
@;        @proofbecause @${\tagof{\tau_1} \subt \kany}
@;      }
@;      @item{
@;        @${\Gamma \wellM \vpair{e_0}{e_1} : \tau \carrow \vpair{e_0'}{e_1'}}
@;        @proofbecause 1,2
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vpair{e_0'}{e_1'} : \kpair}
@;        @proofbecause 3,4
@;      }
@;      @item{
@;        @proofqed by 5,6
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;                \Gamma \wellM e_0 : \tau_d \tarrow \tau_c
@;                \\
@;                \Gamma \wellM e_1 : \tau_d
@;              }{
@;                \Gamma \wellM e_0~e_1 : \tau_c
@;              }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM e_0 : \tarr{\tau_d}{\tau_c} \carrow e_0' \\ \mbox{ and }
@;           \Gamma \wellKE e_0' : \tagof{\tarr{\tau_d}{\tau_c}}}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellM e_1 : \tau_d \carrow e_1' \\ \mbox{ and }
@;           \Gamma \wellKE e_1' : \tagof{\tau_c}}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellKE e_0' : \kfun}
@;        @proofbecause @${\tagof{\tarr{\tau_d}{\tau_c}} = \kfun}
@;      }
@;      @item{
@;        @${\Gamma \wellKE e_1' : \kany}
@;        @proofbecause @${\tagof{\tau_d} \subt \kany}
@;      }
@;      @item{
@;        @${\Gamma \wellM e_0~e_1 : \tau_c \carrow \echk{\tagof{\tau_c}}{(e_0'~e_1')}}
@;        @proofbecause 1,2
@;      }
@;      @item{
@;        @${\Gamma \wellKE \echk{\tagof{\tau_c}}{(e_0'~e_1')} : \tagof{\tau_c}}
@;        @proofbecause 3,4
@;      }
@;      @item{
@;        @proofqed by 5,6
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;                \Gamma \wellM e_0 : \tau_0
@;                \\
@;                \Delta(\vunop, \tau_0) = \tau
@;              }{
@;                \Gamma \wellM \vunop~e_0 : \tau
@;              }}]{
@;    @proofif[@${\vunop = \vfst}]{
@;      @proofitems[
@;        @item{
@;          @${\tau_0 = \tpair{\tau}{\tau'}}
@;          @proofby["lemma:LM-inversion" @${\Delta(\vfst, \tau_0) = \tau}]
@;        }
@;        @item{
@;          @${\Gamma \wellM e_0 : \tpair{\tau}{\tau'} \carrow e_0' \mbox{ and }
@;             \Gamma \wellKE e_0' : \tagof{\tpair{\tau}{\tau'}}}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\Gamma \wellKE e_0' : \kpair}
@;          @proofbecause @${\tagof{\tpair{\tau}{\tau'}} = \kpair}
@;        }
@;        @item{
@;          @${\Gamma \wellM \efst{e_0} : \tau \carrow \echk{\tagof{\tau}}{(\efst{e_0'})}}
@;          @proofbecause 2
@;        }
@;        @item{
@;          @${\Gamma \wellKE \echk{\tagof{\tau}}{(\efst{e_0'})} : \tagof{\tau}}
@;          @proofbecause 3
@;        }
@;        @item{
@;          @proofqed by 4,5
@;        }
@;      ]
@;    }
@;    @proofelse[@${\vunop = \vsnd}]{
@;      @proofitems[
@;        @item{
@;          @${\tau_0 = \tpair{\tau'}{\tau}}
@;          @proofby["lemma:LM-inversion" @${\Delta(\vsnd, \tau_0) = \tau}]
@;        }
@;        @item{
@;          @${\Gamma \wellM e_0 : \tpair{\tau'}{\tau} \carrow e_0' \mbox{ and }
@;             \Gamma \wellKE e_0' : \tagof{\tpair{\tau'}{\tau}}}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\Gamma \wellKE e_0' : \kpair}
@;          @proofbecause @${\tagof{\tpair{\tau'}{\tau}} = \kpair}
@;        }
@;        @item{
@;          @${\Gamma \wellM \esnd{e_0} : \tau \carrow \echk{\tagof{\tau}}{(\esnd{e_0'})}}
@;          @proofbecause 2
@;        }
@;        @item{
@;          @${\Gamma \wellKE \echk{\tagof{\tau}}{(\esnd{e_0'})} : \tagof{\tau}}
@;          @proofbecause 3
@;        }
@;        @item{
@;          @proofqed by 4,5
@;        }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;                \Gamma \wellM e_0 : \tau_0
@;                \\
@;                \Gamma \wellM e_1 : \tau_1
@;                \\
@;                \Delta(\vbinop, \tau_0, \tau_1) = \tau
@;              }{
@;                \Gamma \wellM \vbinop~e_0~e_1 : \tau
@;              }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM e_0 : \tau_0 \carrow e_0' \\ \mbox{ and }
@;           \Gamma \wellKE e_0' : \tagof{\tau_0}}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellM e_1 : \tau_1 \carrow e_1' \\ \mbox{ and }
@;           \Gamma \wellKE e_1' : \tagof{\tau_1}}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Delta(\vbinop, \tagof{\tau_0}, \tagof{\tau_1}) = \tagof{\tau}}
@;        @proofby["lemma:Delta-preservation"]
@;      }
@;      @item{
@;        @${\Gamma \wellM \ebinop{e_0}{e_1} : \tau \carrow \ebinop{e_0'}{e_1'}}
@;        @proofbecause 1,2
@;      }
@;      @item{
@;        @${\Gamma \wellKE \ebinop{e_0'}{e_1'} : \tagof{\tau}}
@;        @proofbecause 1,2,3
@;      }
@;      @item{
@;        @proofqed by 5,6
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;               \inferrule*{
@;                 \Gamma \wellM e : \tau'
@;                 \\
@;                 \tau' \subt \tau
@;               }{
@;                 \Gamma \wellM e : \tau
@;               }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM e : \tau' \carrow e' \\\mbox{ and }
@;           \Gamma \wellKE e' : \tagof{\tau'}}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\tagof{\tau'} \eeq \tagof{\tau} \mbox{ or } \tagof{\tau'} \subt \tagof{\tau}}
@;        @proofby{lemma:subt-preservation}
@;      }
@;      @item{
@;        @${\Gamma \wellKE e' : \tagof{\tau}}
@;        @proofbecause 2
@;      }
@;      @item{
@;        @proofqed by 1,3
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;               \inferrule*{
@;                 \Gamma \wellM e
@;               }{
@;                 \Gamma \wellM \edyn{\tau}{e} : \tau
@;               }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM e \carrow e' \mbox{ and } \Gamma \wellKE e'}
@;        @proofby{lemma:LK-D-completion-soundness}
@;      }
@;      @item{
@;        @${\Gamma \wellM \edyn{\tau}{e} : \tau \carrow \edyn{\tau}{e'}}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @${\Gamma \wellKE \edyn{\tau}{e'} : \tagof{\tau}}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @proofqed by 2,3
@;      }
@;    ]
@;  }
@;
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\carrow} dynamic soundness} #:key "lemma:LK-D-completion-soundness"]{
@;  If @${\Gamma \wellM e} then @${\Gamma \wellM e \carrow e'} and @${\Gamma \wellKE e'}
@;}
@;
@;@proof{
@;  By induction on the structure of @${\Gamma \wellM e}.
@;  Proceed by cases on the last rule used.
@;
@;  @proofcase[@fbox${
@;                \inferrule*{
@;                  x \in \Gamma
@;                }{
@;                  \Gamma \wellM x
@;                }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM x \carrow x}
@;      }
@;      @item{
@;        @${\Gamma \wellKE x}
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;                \inferrule*{
@;                  x,\Gamma \wellM e
@;                }{
@;                  \Gamma \wellM \vlam{x}{e}
@;                }}]{
@;    @proofitems[
@;      @item{
@;        @${x,\Gamma \wellM e \carrow e' \\\mbox{and }
@;           x,\Gamma \wellKE e'}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellM \vlam{x}{e} \carrow \vlam{x}{e'}}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vlam{x}{e'}}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @proofqed by 2,3
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;              }{
@;                \Gamma \wellM i
@;              } }]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM i \carrow i}
@;      }
@;      @item{
@;        @${\Gamma \wellKE i}
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;                \Gamma \wellM e_0
@;                \\
@;                \Gamma \wellM e_1
@;              }{
@;                \Gamma \wellM \vpair{e_0}{e_1}
@;              }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM e_0 \carrow e_0' \mbox{ and } \Gamma \wellKE e_0'}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellM e_1 \carrow e_1' \mbox{ and } \Gamma \wellKE e_1'}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellM \vpair{e_0}{e_1} \carrow \vpair{e_0'}{e_1'}}
@;        @proofbecause 1,2
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vpair{e_0'}{e_1'}}
@;        @proofbecause 1,2
@;      }
@;      @item{
@;        @proofqed by 3,4
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;                \Gamma \wellM e_0
@;                \\
@;                \Gamma \wellM e_1
@;              }{
@;                \Gamma \wellM e_0~e_1
@;              }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM e_0 \carrow e_0' \mbox{ and } \Gamma \wellKE e_0'}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellM e_1 \carrow e_1' \mbox{ and } \Gamma \wellKE e_1'}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellM \vapp{e_0}{e_1} \carrow \vapp{e_0'}{e_1'}}
@;        @proofbecause 1,2
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vapp{e_0'}{e_1'}}
@;        @proofbecause 1,2
@;      }
@;      @item{
@;        @proofqed by 3,4
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;                \Gamma \wellM e
@;              }{
@;                \Gamma \wellM \vunop~e
@;              }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM e \carrow e' \mbox{ and } \Gamma \wellKE e'}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellM \eunop{e} \carrow \eunop{e'}}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @${\Gamma \wellKE \eunop{e'}}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @proofqed by 2,3
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;  \inferrule*{
@;    \Gamma \wellM e_0
@;    \\
@;    \Gamma \wellM e_1
@;  }{
@;    \Gamma \wellM \vbinop~e_0~e_1
@;  }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM e_0 \carrow e_0' \mbox{ and } \Gamma \wellKE e_0'}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellM e_1 \carrow e_1' \mbox{ and } \Gamma \wellKE e_1'}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\Gamma \wellM \ebinop{e_0}{e_1} \carrow \ebinop{e_0'}{e_1'}}
@;        @proofbecause 1,2
@;      }
@;      @item{
@;        @${\Gamma \wellKE \ebinop{e_0'}{e_1'}}
@;        @proofbecause 1,2
@;      }
@;      @item{
@;        @proofqed by 3,4
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@fbox${
@;              \inferrule*{
@;                \Gamma \wellM e : \tau
@;              }{
@;                \Gamma \wellM \esta{\tau}{e}
@;              }}]{
@;    @proofitems[
@;      @item{
@;        @${\Gamma \wellM e : \tau \carrow e' \mbox{ and } \Gamma \wellKE e' : \tagof{\tau}}
@;        @proofby{lemma:LK-S-completion-soundness}
@;      }
@;      @item{
@;        @${\Gamma \wellM \esta{\tau}{e} \carrow \esta{\tau}{e'}}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @${\Gamma \wellKE \esta{\tau}{e}}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @proofqed by 2,3
@;      }
@;    ]
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\delta} preservation} #:key "lemma:delta-preservation"]{
@;}
@;  @itemlist[
@;    @item{
@;      If @${\wellKE v} and @${\delta(\vunop, v) = v'} then @${\wellKE v'}
@;    }
@;    @item{
@;      If @${\wellKE v_0} and @${\wellKE v_1} and @${\delta(\vbinop, v_0, v_1) = v'}
@;       then @${\wellKE v'}
@;    }
@;  ]
@;
@;@proof{
@;
@;  @proofcase[@${\delta(\vfst, \vpair{v_0}{v_1}) = v_0}]{
@;    @proofitems[
@;      @item{
@;        @${\wellKE v_0}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @proofqed by 1
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\delta(\vsnd, \vpair{v_0}{v_1}) = v_1}]{
@;    @proofitems[
@;      @item{
@;        @${\wellKE v_1}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @proofqed by 1
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\delta(\vsum, v_0, v_1) = v_0 + v_1}]{
@;    @proofitems[
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\delta(\vquotient, v_0, v_1) = \floorof{v_0 / v_1}}]{
@;    @proofitems[
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\Delta} preservation} #:key "lemma:Delta-preservation"]{
@;  If @${\Delta(\vbinop, \tau_0, \tau_1) = \tau} then
@;     @${\Delta(\vbinop, \tagof{\tau_0}, \tagof{\tau_1}) = \tagof{\tau}}.
@;}
@;
@;@proof{
@;  By case analysis on the definition of @${\Delta}
@;
@;  @proofcase[@${\Delta(\vbinop, \tnat, \tnat) = \tnat}]{
@;    @proofqed by @${\tagof{\tnat} = \tnat}
@;  }
@;
@;  @proofcase[@${\Delta(\vbinop, \tint, \tint) = \tint}]{
@;    @proofqed by @${\tagof{\tnat} = \tnat}
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\subt} preservation} #:key "lemma:subt-preservation"]{
@;  If @${\tau \subt \tau'} then
@;   @${\tagof{\tau} \eeq \tagof{\tau'}}
@;   or @${\tagof{\tau} \subt \tagof{\tau'}}
@;}
@;
@;@proof{
@;  By case analysis on the last rule used to show @${\tau \subt \tau'}.
@;
@;  @proofcase[@${\tnat \subt \tint}]{
@;    @proofqed @${\tagof{\tnat} \subt \tagof{\tint}}
@;  }
@;
@;  @proofcase[@${\tarr{\tau_d}{\tau_c} \subt \tarr{\tau_d'}{\tau_c'}}]{
@;    @proofitems[
@;      @item{
@;        @${\tagof{\tarr{\tau_d}{\tau_c}} = \kfun \mbox{ and }
@;           \tagof{\tarr{\tau_d'}{\tau_c'}} = \kfun}
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\tpair{\tau_0}{\tau_1} \subt \tpair{\tau_0'}{\tau_1'}}]{
@;    @proofitems[
@;      @item{
@;        @${\tagof{\tpair{\tau_0}{\tau_1}} = \kpair \mbox{ and }
@;           \tagof{\tpair{\tau_0'}{\tau_1'}} = \kpair}
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} unique static evaluation contexts} #:key "lemma:LK-S-uec"]{
@;  If @${\wellKE e : K} then either:
@;}
@;  @itemlist[
@;    @item{ @${e} is a value }
@;    @item{ @${e = \ctxE{v_0~v_1}} }
@;    @item{ @${e = \ctxE{\eunop{v}}} }
@;    @item{ @${e = \ctxE{\ebinop{v_0}{v_1}}} }
@;    @item{ @${e = \ctxE{\edyn{\tau}{e'}}} }
@;    @item{ @${e = \ctxE{\edyn{\kany}{e'}}} }
@;    @item{ @${e = \ctxE{\echk{K}{v}}} }
@;  ]
@;@proof{
@;  By induction on the structure of @${e}.
@;
@;  @proofcase[@${e = x}]{
@;    @proofcontradiction[@${\wellKE e : K}]
@;  }
@;
@;  @proofcase[@${e = i \mbox{ or }
@;                e = \vlam{x}{e'} \mbox{ or }
@;                e = \vlam{\tann{x}{\tau_d}}{e'}}]{
@;    @proofthen @${e} is a value
@;  }
@;
@;  @proofcase[@${e = \esta{\tau}{e'} \mbox{ or } e = \esta{\kany}{e'}}]{
@;    @proofcontradiction[@${\wellKE e : K}]
@;  }
@;
@;  @proofcase[@${e = \vpair{e_0}{e_1}}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ES_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${E = \vpair{\ES_0}{e_1}}
@;        }
@;      ]
@;      @proofthen @${e = \ctxE{e_0'}}
@;    }
@;    @proofif[@${e_0 \in v \mbox{ and } e_1 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_1 = \ES_1[e_1']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${E = \vpair{e_0}{\ES_1}}
@;        }
@;      ]
@;      @proofthen @${e = \ctxE{e_1'}}
@;    }
@;    @proofelse[@${e_0 \in v \mbox{ and } e_1 \in v}]{
@;      @proofthen @${e} is a value
@;    }
@;  }
@;
@;  @proofcase[@${e = e_0~e_1}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ED_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \ED_0~e_1}
@;        }
@;      ]
@;      @proofthen @${e = \ctxE{e_0'}}
@;    }
@;    @proofif[@${e_0 \in v \mbox{ and } e_1 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_1 = \ED_1[e_1']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = e_0~\ED_1}
@;        }
@;      ]
@;      @proofthen @${e = \ctxE{e_1'}}
@;    }
@;    @proofelse[@${e_0 \in v \mbox{ and } e_1 \in v}]{
@;      @proofitems[@item{ @${\ED = \ehole} }]
@;      @proofthen @${e = \ctxE{e_0~e_1}}
@;    }
@;  }
@;
@;  @proofcase[@${e = \eunop{e_0}}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ED_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \eunop{\ED_0}}
@;        }
@;      ]
@;      @proofthen @${e = \ctxE{e_0'}}
@;    }
@;    @proofelse[@${e_0 \in v}]{
@;      @proofitems[@item{ @${E = \ehole} }]
@;      @proofthen @${e = \ctxE{\eunop{e_0}}}
@;    }
@;  }
@;
@;  @proofcase[@${e = \ebinop{e_0}{e_1}}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ED_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \ebinop{\ED_0}{e_1}}
@;        }
@;      ]
@;      @proofthen @${e = \ctxE{e_0'}}
@;    }
@;    @proofif[@${e_0 \in v \mbox{ and } e_1 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_1 = \ED_1[e_1']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \ebinop{e_0}{\ED_1}}
@;        }
@;      ]
@;      @proofthen @${e = \ctxE{e_1'}}
@;    }
@;    @proofelse[@${e_0 \in v \mbox{ and } e_1 \in v}]{
@;      @proofitems[ @item{ @${\ED = \ehole} } ]
@;      @proofthen @${e = \ctxE{\ebinop{e_0}{e_1}}}
@;    }
@;  }
@;
@;  @proofcase[@${e = \edyn{\tau}{e_0}}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ED_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \edyn{\tau}{\ED_0}}
@;        }
@;      ]
@;      @proofthen @${e = \ctxE{e_0'}}
@;    }
@;    @proofelse[@${e_0 \in v}]{
@;      @proofitems[@item{ @${\ED = \ehole} }]
@;      @proofthen @${e = \ctxE{\edyn{\tau}{e_0}}}
@;    }
@;  }
@;
@;  @proofcase[@${e = \edyn{\kany}{e_0}}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ED_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \edyn{\kany}{\ED_0}}
@;        }
@;      ]
@;      @proofthen @${e = \ctxE{e_0'}}
@;    }
@;    @proofelse[@${e_0 \in v}]{
@;      @proofitems[@item{ @${\ED = \ehole} }]
@;      @proofthen @${e = \ctxE{\edyn{\kany}{e_0}}}
@;    }
@;  }
@;
@;  @proofcase[@${e = \echk{K}{e_0}}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ED_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \echk{K}{\ED_0}}
@;        }
@;      ]
@;      @proofthen @${e = \ctxE{e_0'}}
@;    }
@;    @proofelse[@${e_0 \in v}]{
@;      @proofitems[@item{ @${\ED = \ehole} }]
@;      @proofthen @${e = \ctxE{\echk{K}{e_0}}}
@;    }
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} unique dynamic evaluation contexts} #:key "lemma:LK-D-uec"]{
@;  If @${\wellKE e} then either:
@;}
@;  @itemlist[
@;    @item{ @${e} is a value }
@;    @item{ @${e = \ctxE{v_0~v_1}} }
@;    @item{ @${e = \ctxE{\eunop{v}}} }
@;    @item{ @${e = \ctxE{\ebinop{v_0}{v_1}}} }
@;    @item{ @${e = \ctxE{\esta{\tau}{e'}}} }
@;    @item{ @${e = \ctxE{\esta{\kany}{e'}}} }
@;  ]
@;@proof{
@;  By induction on the structure of @${e}.
@;
@;  @proofcase[@${e = x}]{
@;    @proofcontradiction[@${\wellKE e}]
@;  }
@;
@;  @proofcase[@${e = i \mbox{ or }
@;                e = \vlam{x}{e'} \mbox{ or }
@;                e = \vlam{\tann{x}{\tau_d}}{e'}}]{
@;    @proofqed @${e} is a value
@;  }
@;
@;  @proofcase[@${e = \edyn{\tau}{e'} \mbox{ or }
@;                e = \edyn{\kany}{e'} \mbox{ or }
@;                e = \echk{K}{e'}}]{
@;    @proofcontradiction[@${\wellKE e}]
@;  }
@;
@;  @proofcase[@${e = \vpair{e_0}{e_1}}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ES_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${E = \vpair{\ES_0}{e_1}}
@;        }
@;        @item{
@;          @proofqed @${e = \ctxE{e_0'}}
@;        }
@;      ]
@;    }
@;    @proofif[@${e_0 \in v \mbox{ and } e_1 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_1 = \ES_1[e_1']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${E = \vpair{e_0}{\ES_1}}
@;        }
@;        @item{
@;          @proofqed @${e = \ctxE{e_1'}}
@;        }
@;      ]
@;    }
@;    @proofelse[@${e_0 \in v \mbox{ and } e_1 \in v}]{
@;      @proofitems[@item{@proofqed @${e} is a value}]
@;    }
@;  }
@;
@;  @proofcase[@${e = e_0~e_1}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ED_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \ED_0~e_1}
@;        }
@;        @item{
@;          @proofqed @${e = \ctxE{e_0'}}
@;        }
@;      ]
@;    }
@;    @proofif[@${e_0 \in v \mbox{ and } e_1 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_1 = \ED_1[e_1']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = e_0~\ED_1}
@;        }
@;        @item{
@;          @proofqed @${e = \ctxE{e_1'}}
@;        }
@;      ]
@;    }
@;    @proofelse[@${e_0 \in v \mbox{ and } e_1 \in v}]{
@;      @proofitems[
@;        @item{ @${\ED = \ehole} }
@;        @item{ @proofqed @${e = \ctxE{e_0~e_1}} }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${e = \eunop{e_0}}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ED_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \eunop{\ED_0}}
@;        }
@;        @item{
@;          @proofqed @${e = \ctxE{e_0'}}
@;        }
@;      ]
@;    }
@;    @proofelse[@${e_0 \in v}]{
@;      @proofitems[
@;        @item{ @${E = \ehole} }
@;        @item{ @proofqed @${e = \ctxE{\eunop{e_0}}} }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${e = \ebinop{e_0}{e_1}}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ED_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \ebinop{\ED_0}{e_1}}
@;        }
@;        @item{
@;          @proofqed @${e = \ctxE{e_0'}}
@;        }
@;      ]
@;    }
@;    @proofif[@${e_0 \in v \mbox{ and } e_1 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_1 = \ED_1[e_1']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \ebinop{e_0}{\ED_1}}
@;        }
@;        @item{
@;          @proofqed @${e = \ctxE{e_1'}}
@;        }
@;      ]
@;    }
@;    @proofelse[@${e_0 \in v \mbox{ and } e_1 \in v}]{
@;      @proofitems[
@;        @item{ @${\ED = \ehole} }
@;        @item{ @proofqed @${e = \ctxE{\ebinop{e_0}{e_1}}} }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${e = \esta{\tau}{e_0}}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ED_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \esta{\tau}{\ED_0}}
@;        }
@;        @item{
@;          @proofqed @${e = \ctxE{e_0'}}
@;        }
@;      ]
@;    }
@;    @proofelse[@${e_0 \in v}]{
@;      @proofitems[
@;        @item{ @${\ED = \ehole} }
@;        @item{ @proofqed @${e = \ctxE{\esta{\tau}{e_0}}} }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${e = \esta{\kany}{e_0}}]{
@;    @proofif[@${e_0 \not\in v}]{
@;      @proofitems[
@;        @item{
@;          @${e_0 = \ED_0[e_0']}
@;          @proofbyIH[]
@;        }
@;        @item{
@;          @${\ED = \esta{\kany}{\ED_0}}
@;        }
@;        @item{
@;          @proofqed @${e = \ctxE{e_0'}}
@;        }
@;      ]
@;    }
@;    @proofelse[@${e_0 \in v}]{
@;      @proofitems[
@;        @item{ @${\ED = \ehole} }
@;        @item{
@;          @proofqed @${e = \ctxE{\esta{\kany}{e_0}}}
@;        }
@;      ]
@;    }
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} static hole typing} #:key "lemma:LK-S-hole-typing"]{
@;  If @${\wellKE \ctxE{e} : K} then the typing derivation contains a sub-term
@;   @${\wellKE e : K'} for some @${K'}.
@;}
@;@proof{
@;  By induction on the structure of @${\ED}.
@;
@;  @proofcase[@${\ED = \ehole}]{
@;    @proofqed @${\ctxE{e} = e}
@;  }
@;
@;  @proofcase[@${\ED = \ED_0~e_1}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ED_0[e]~e_1}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e] : \kfun}
@;        @proofby["lemma:LK-S-inversion" @${\wellKE \ED_0[e]~e_1 : K}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = v_0~\ED_1}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = v_0~\ED_1[e]}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e] : \kany}
@;        @proofby["lemma:LK-S-inversion" @${\wellKE v_0~\ED_1[e] : K}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \vpair{\ED_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \vpair{\ED_0[e]}{e_1}}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e] : \kany}
@;        @proofby["lemma:LK-S-inversion" @${\wellKE \vpair{\ED_0[e]}{e_1} : K}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \vpair{v_0}{\ED_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \vpair{v_0}{\ED_1[e]}}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e] : \kany}
@;        @proofby["lemma:LK-S-inversion" @${\wellKE \vpair{v_0}{\ED_1[e]} : K}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \eunop{\ED_0}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \eunop{\ED_0[e]}}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e] : \kpair}
@;        @proofby["lemma:LK-S-inversion" @${\wellKE \eunop{\ED_0[e]} : K}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \ebinop{\ED_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ebinop{\ED_0[e]}{e_1}}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e] : K_0}
@;        @proofby["lemma:LK-S-inversion" @${\wellKE \ebinop{\ED_0[e]}{e_1} : K}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \ebinop{v_0}{\ED_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ebinop{v_0}{\ED_1[e]}}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e] : K_1}
@;        @proofby["lemma:LK-S-inversion" @${\wellKE \ebinop{v_0}{\ED_1[e]} : K}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \echk{K}{\ED_0}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \echk{K}{\ED_0[e]}}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e] : \kany}
@;        @proofby["lemma:LK-S-inversion" @${\wellKE \echk{K}{\ED_0[e]} : K}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} dynamic hole typing} #:key "lemma:LK-D-hole-typing"]{
@;  If @${\wellKE \ctxE{e}} then the derivation contains a sub-term
@;   @${\wellKE e}
@;}
@;@proof{
@;  By induction on the structure of @${\ED}.
@;
@;  @proofcase[@${\ED = \ehole}]{
@;    @proofqed @${\ctxE{e} = e}
@;  }
@;
@;  @proofcase[@${\ED = \ED_0~e_1}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ED_0[e]~e_1}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e]}
@;        @proofby["lemma:LK-D-inversion" @${\wellKE \ED_0[e]~e_1}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = v_0~\ED_1}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = v_0~\ED_1[e]}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e]}
@;        @proofby["lemma:LK-D-inversion" @${\wellKE v_0~\ED_1[e]}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \vpair{\ED_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \vpair{\ED_0[e]}{e_1}}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e]}
@;        @proofby["lemma:LK-D-inversion" @${\wellKE \vpair{\ED_0[e]}{e_1}}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \vpair{v_0}{\ED_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \vpair{v_0}{\ED_1[e]}}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e]}
@;        @proofby["lemma:LK-D-inversion" @${\wellKE \vpair{v_0}{\ED_1[e]}}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \eunop{\ED_0}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \eunop{\ED_0[e]}}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e]}
@;        @proofby["lemma:LK-D-inversion" @${\wellKE \eunop{\ED_0[e]}}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \ebinop{\ED_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ebinop{\ED_0[e]}{e_1}}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e]}
@;        @proofby["lemma:LK-D-inversion" @${\wellKE \ebinop{\ED_0[e]}{e_1}}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \ebinop{v_0}{\ED_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ebinop{v_0}{\ED_1[e]}}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e]}
@;        @proofby["lemma:LK-D-inversion" @${\wellKE \ebinop{v_0}{\ED_1[e]}}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \echk{K}{\ED_0}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \echk{K}{\ED_0[e]}}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e]}
@;        @proofby["lemma:LK-D-inversion" @${\wellKE \echk{K}{\ED_0[e]}}]
@;      }
@;      @item{
@;        @proofqed @proofbyIH{2}
@;      }
@;    ]
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} static hole substitution} #:key "lemma:LK-S-hole-subst"]{
@;  If @${\wellKE \ctxE{e} : K} and @${\wellKE e : K'} and @${\wellKE e' : K'} then @${\wellKE \ctxE{e'} : K}
@;}
@;@proof{
@;  By induction on the structure of @${\ED}.
@;
@;  @proofcase[@${\ED = \ehole}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = e \mbox{ and } \ctxE{e'} = e'}
@;      }
@;      @item{
@;        @${\wellKE e : K}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @${K' = K \mbox{ or } K' \subt K}
@;        @proofbecause 2
@;      }
@;      @item{
@;        @${\wellKE e' : K}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @proofqed by 1,4
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \vpair{\ED_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \vpair{\ED_0[e]}{e_1}
@;          \\\mbox{and } \ctxE{e'} = \vpair{\ED_0[e']}{e_1}}
@;      }
@;      @item{
@;        @${\wellKE \vpair{\ED_0[e]}{e_1} : K}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e] : K_0
@;           \mbox{ and } \wellKE e_1 : K_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e'] : K_0}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \vpair{\ED_0[e']}{e_1} : K}
@;        @proofbecause 2,3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \vpair{v_0}{\ED_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \vpair{v_0}{\ED_1[e]}
@;           \\\mbox{and } \ctxE{e'} = \vpair{v_0}{\ED_1[e']}}
@;      }
@;      @item{
@;        @${\wellKE \vpair{v_0}{\ED_1[e]} : K}
@;      }
@;      @item{
@;        @${\wellKE v_0 : K_0 \mbox{ and } \wellKE \ED_1[e] : K_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e'] : K_1}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \vpair{v_0}{\ED_1[e']} : K}
@;        @proofbecause 2,3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \ED_0~e_1}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ED_0[e]~e_1
@;          \\\mbox{and } \ctxE{e'} = \ED_0[e']~e_1}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e]~e_1 : K}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e] : K_0
@;           \mbox{ and } \wellKE e_1 : K_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e'] : K_0}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e']~e_1 : K}
@;        @proofbecause 2,3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = v_0~\ED_1}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = v_0~\ED_1[e] \\\mbox{and } \ctxE{e'} = v_0~\ED_1[e']}
@;      }
@;      @item{
@;        @${\wellKE v_0~\ED_1[e] : K}
@;      }
@;      @item{
@;        @${\wellKE v_0 : K_0 \mbox{ and } \wellKE \ED_1[e] : K_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e'] : K_1}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE v_0~\ED_1[e'] : K}
@;        @proofbecause 2,3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \eunop{\ED_0}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \eunop{\ED_0[e]}
@;          \\\mbox{and } \ctxE{e'} = \eunop{\ED_0[e']}}
@;      }
@;      @item{
@;        @${\wellKE \eunop{\ED_0[e]} : K}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e] : K_0}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e'] : K_0}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \eunop{\ED_0[e']} : K}
@;        @proofbecause 2,3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \ebinop{\ED_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ebinop{\ED_0[e]}{e_1}
@;          \\\mbox{and } \ctxE{e'} = \ebinop{\ED_0[e']}{e_1}}
@;      }
@;      @item{
@;        @${\wellKE \ebinop{\ED_0[e]}{e_1} : K}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e] : K_0
@;           \mbox{ and } \wellKE e_1 : K_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e'] : K_0}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \ebinop{\ED_0[e']}{e_1} : K}
@;        @proofbecause 2,3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \ebinop{v_0}{\ED_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ebinop{v_0}{\ED_1[e]}
@;           \\\mbox{and } \ctxE{e'} = \ebinop{v_0}{\ED_1[e']}}
@;      }
@;      @item{
@;        @${\wellKE \ebinop{v_0}{\ED_1[e]} : K}
@;      }
@;      @item{
@;        @${\wellKE v_0 : K_0 \mbox{ and } \wellKE \ED_1[e] : K_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e'] : K_1}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \ebinop{v_0}{\ED_1[e']} : K}
@;        @proofbecause 2,3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \echk{K_c}{\ED_0}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \echk{K_c}{\ED_0[e]}
@;          \\\mbox{and } \ctxE{e'} = \echk{K_c}{\ED_0[e']}}
@;      }
@;      @item{
@;        @${\wellKE \echk{K_c}{\ED_0[e]} : K}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e] : K_0}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e'] : K_0}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \echk{K_c}{\ED_0[e']} : K}
@;        @proofbecause 2,3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} dynamic hole substitution} #:key "lemma:LK-D-hole-subst"]{
@;  If @${\wellKE \ctxE{e}} and @${\wellKE e'} then @${\wellKE \ctxE{e'}}
@;}
@;@proof{
@;  By induction on the structure of @${\ED}.
@;
@;  @proofcase[@${\ED = \ehole}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\ctxE{e'} = e'}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \vpair{\ED_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \vpair{\ED_0[e]}{e_1}
@;          \\\mbox{and } \ctxE{e'} = \vpair{\ED_0[e']}{e_1}}
@;      }
@;      @item{
@;        @${\wellKE \vpair{\ED_0[e]}{e_1}}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e]
@;           \mbox{ and } \wellKE e_1}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e']}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \vpair{\ED_0[e']}{e_1}}
@;        @proofbecause 3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \vpair{v_0}{\ED_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \vpair{v_0}{\ED_1[e]}
@;           \\\mbox{and } \ctxE{e'} = \vpair{v_0}{\ED_1[e']}}
@;      }
@;      @item{
@;        @${\wellKE \vpair{v_0}{\ED_1[e]}}
@;      }
@;      @item{
@;        @${\wellKE v_0 \mbox{ and } \wellKE \ED_1[e]}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e']}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \vpair{v_0}{\ED_1[e']}}
@;        @proofbecause 3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \ED_0~e_1}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ED_0[e]~e_1
@;          \\\mbox{and } \ctxE{e'} = \ED_0[e']~e_1}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e]~e_1}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e]
@;           \mbox{ and } \wellKE e_1}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e']}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e']~e_1}
@;        @proofbecause 3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = v_0~\ED_1}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = v_0~\ED_1[e] \\\mbox{and } \ctxE{e'} = v_0~\ED_1[e']}
@;      }
@;      @item{
@;        @${\wellKE v_0~\ED_1[e]}
@;      }
@;      @item{
@;        @${\wellKE v_0 \mbox{ and } \wellKE \ED_1[e]}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e']}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE v_0~\ED_1[e']}
@;        @proofbecause 3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \eunop{\ED_0}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \eunop{\ED_0[e]}
@;          \\\mbox{and } \ctxE{e'} = \eunop{\ED_0[e']}}
@;      }
@;      @item{
@;        @${\wellKE \eunop{\ED_0[e]}}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e]}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e']}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \eunop{\ED_0[e']}}
@;        @proofbecause 3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \ebinop{\ED_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ebinop{\ED_0[e]}{e_1}
@;          \\\mbox{and } \ctxE{e'} = \ebinop{\ED_0[e']}{e_1}}
@;      }
@;      @item{
@;        @${\wellKE \ebinop{\ED_0[e]}{e_1}}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e]
@;           \mbox{ and } \wellKE e_1}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_0[e']}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \ebinop{\ED_0[e']}{e_1}}
@;        @proofbecause 3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \ebinop{v_0}{\ED_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\ctxE{e} = \ebinop{v_0}{\ED_1[e]}
@;           \\\mbox{and } \ctxE{e'} = \ebinop{v_0}{\ED_1[e']}}
@;      }
@;      @item{
@;        @${\wellKE \ebinop{v_0}{\ED_1[e]}}
@;      }
@;      @item{
@;        @${\wellKE v_0 \mbox{ and } \wellKE \ED_1[e]}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE \ED_1[e']}
@;        @proofbyIH[] (3)
@;      }
@;      @item{
@;        @${\wellKE \ebinop{v_0}{\ED_1[e']}}
@;        @proofbecause 3,4
@;      }
@;      @item{
@;        @proofqed by 1,5
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\ED = \echk{K_c}{\ED_0}}]{
@;    @proofitems[
@;      @item{
@;        @proofcontradiction[@${\wellKE \ctxE{e}}]
@;      }
@;    ]
@;  }
@;
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} static inversion} #:key "lemma:LK-S-inversion"]{
@;}
@;  @itemlist[
@;    @item{
@;      If @${\wellKE \vpair{e_0}{e_1} : K} then
@;       @${\wellKE e_0 : \kany} and
@;       @${\wellKE e_1 : \kany}
@;    }
@;    @item{
@;      If @${\wellKE \vlam{x}{e} : K} then
@;       @${x \wellKE e}
@;    }
@;    @item{
@;      If @${\wellKE \vlam{\tann{x}{\tau}}{e} : K} then
@;       @${\tann{x}{\tau} \wellKE e : \kany}
@;    }
@;    @item{
@;      If @${\wellKE e_0~e_1 : K} then
@;       @${K = \kany} and
@;       @${\wellKE e_0 : \kfun} and
@;       @${\wellKE e_1 : \kany}
@;    }
@;    @item{
@;      If @${\wellKE \eunop{e_0} : K} then
@;       @${K = \kany} and
@;       @${\wellKE e_0 : \kpair}
@;    }
@;    @item{
@;      If @${\wellKE \ebinop{e_0}{e_1} : K} then
@;       @${\wellKE e_0 : K_0} and
@;       @${\wellKE e_1 : K_1} and
@;       @${\Delta(\vbinop, K_0, K_1) = K'} and
@;       @${K' \subt K}
@;    }
@;    @item{
@;      If @${\wellKE \echk{K'}{e_0} : K} then
@;       @${\wellKE e_0 : \kany} and
@;       @${K' \subt K}
@;    }
@;    @item{
@;      If @${\wellKE \edyn{\tau}{e} : K} then
@;       @${\wellKE e} and
@;       @${\tagof{\tau} \subt K}
@;    }
@;  ]
@;@proof{
@;  By induction on the structure of @${\wellKE e : K}.
@;  The desired conclusion either follows immediately from the last rule used,
@;   or the last rule is the subsumption rule and we have @${\wellKE e : K'}
@;   and @${K' \subt K}.
@;  In the latter case, apply the induction hypothesis to @${\wellKE e : K'}.
@;  The induction is well-founded by @tech{lemma:LK-finite-lattice}.
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} dynamic inversion} #:key "lemma:LK-D-inversion"]{
@;}
@;  @itemlist[
@;    @item{
@;      If @${\wellKE \vpair{e_0}{e_1}} then
@;       @${\wellKE e_0} and
@;       @${\wellKE e_1}
@;    }
@;    @item{
@;      If @${\wellKE \vlam{x}{e}} then
@;       @${x \wellKE e}
@;    }
@;    @item{
@;      If @${\wellKE \vlam{\tann{x}{\tau}}{e}} then
@;       @${\tann{x}{\tau} \wellKE e : \kany}
@;    }
@;    @item{
@;      If @${\wellKE e_0~e_1} then
@;       @${\wellKE e_0} and
@;       @${\wellKE e_1}
@;    }
@;    @item{
@;      If @${\wellKE \eunop{e_0}} then
@;       @${\wellKE e_0}
@;    }
@;    @item{
@;      If @${\wellKE \ebinop{e_0}{e_1}} then
@;       @${\wellKE e_0} and
@;       @${\wellKE e_1}
@;    }
@;    @item{
@;      If @${\wellKE \esta{\tau}{e}} then
@;       @${\wellKE e : \tagof{\tau}}
@;    }
@;    @item{
@;      If @${\wellKE \esta{\kany}{e}} then
@;       @${\wellKE e : \kany}
@;    }
@;  ]
@;@proof{
@;  Immediate from the definition of @${\wellKE e}.
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} canonical forms} #:key "lemma:LK-canonical"]{
@;}
@;  @itemlist[
@;    @item{
@;      If @${\wellKE v : \kpair}
@;      then @${v \eeq \vpair{v_0}{v_1}}
@;    }
@;    @item{
@;      If @${\wellKE v : \kfun}
@;      then @${v \eeq \vlam{x}{e'} \mbox{ or } v \eeq \vlam{\tann{x}{\tau_d}}{e'}}
@;    }
@;    @item{
@;      If @${\wellKE v : \kint}
@;      then @${v \eeq i}
@;    }
@;    @item{
@;      If @${\wellKE v : \knat}
@;      then @${v \eeq i} and @${v \in \naturals}
@;    }
@;  ]
@;@proof{
@;  Immediate from the definition of @${\wellKE \cdot : K}
@;
@;  @; more like ... if you look at all the rules for wellKE
@;  @;  then you see there's only one that applies for each value form,
@;  @;  and the premises of that rule establish what we want to know
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\Delta} tag soundness} #:key "lemma:K-Delta-soundness"]{
@;  If @${\wellKE v_0 : K_0 \mbox{ and }
@;        \wellKE v_1 : K_1 \mbox{ and }
@;        \Delta(\vbinop, K_0, K_1) = K}
@;  then either:}
@;  @proofitems[
@;    @item{ @${\delta(\vbinop, v_0, v_1) = v \mbox{ and } \wellKE v : K}, or }
@;    @item{ @${\delta(\vbinop, v_0, v_1) = \boundaryerror } }
@;  ]
@;
@;@proof{
@;  By case analysis on @${\Delta}.
@;
@;  @proofcase[@${\Delta(\vsum, \knat, \knat) = \knat}]{
@;    @proofitems[
@;      @item{
@;        @${v_0 = i_0 \mbox{ and } v_1 = i_1 \mbox{ and } i_0,i_1 \in \naturals}
@;        @proofby["lemma:LK-canonical"]
@;      }
@;      @item{
@;        @${\delta(\vsum, i_0, i_1) = i_0 + i_1 = i}
@;      }
@;      @item{
@;        @${i \in \naturals}
@;      }
@;      @item{
@;        @proofqed by @${\wellKE i : \knat}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\Delta(\vsum, \kint, \kint) = \kint}]{
@;    @proofitems[
@;      @item{
@;        @${v_0 = i_0 \mbox{ and } v_1 = i_1}
@;        @proofby["lemma:LK-canonical"]
@;      }
@;      @item{
@;        @${\delta(\vsum, i_0, i_1) = i_0 + i_1 = i}
@;      }
@;      @item{
@;        @proofqed by @${\wellKE i : \kint}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${\Delta(\vquotient, \knat, \knat) = \knat}]{
@;    @proofitems[
@;      @item{
@;        @${v_0 = i_0 \mbox{ and } v_1 = i_1 \mbox{ and } i_0,i_1 \in \naturals}
@;        @proofby["lemma:LK-canonical"]
@;      }
@;    ]
@;    @proofif[@${i_1 = 0}]{
@;      @proofitems[
@;        @item{ @proofqed by @${\delta(\vquotient, i_0, i_1) = \boundaryerror} }
@;      ]
@;    }
@;    @proofelse[@${i_1 \neq 0}]{
@;      @proofitems[
@;        @item{ @${\delta(\vquotient, i_0, i_1) = \floorof{i_0 / i_1}} = i }
@;        @item{ @${i \in \naturals} }
@;        @item{ @proofqed by @${\wellKE i : \knat} }
@;      ]
@;    }
@;  }
@;
@;  @proofcase[@${\Delta(\vquotient, \kint, \kint) = \kint}]{
@;    @proofitems[
@;      @item{
@;        @${v_0 = i_0 \mbox{ and } v_1 = i_1}
@;        @proofby["lemma:LK-canonical"]
@;      }
@;    ]
@;    @proofif[@${i_1 = 0}]{
@;      @proofitems[
@;        @item{ @proofqed by @${\delta(\vquotient, i_0, i_1) = \boundaryerror} }
@;      ]
@;    }
@;    @proofelse[@${i_1 \neq 0}]{
@;      @proofitems[
@;        @item{ @${\delta(\vquotient, i_0, i_1) = \floorof{i_0 / i_1}} = i }
@;        @item{ @proofqed by @${\wellKE i : \kint} }
@;      ]
@;    }
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@; TODO rename this
@;@lemma[@elem{@${\langK} value tag inference} #:key "lemma:LK-val-tagging"]{
@;  If @${\wellKE v} then @${\wellKE v : \kany}
@;}
@;@proof{
@;  By induction on the structure of @${v}.
@;
@;  @proofcase[@${v = i}]{
@;    @proofitems[
@;      @item{
@;        @${\wellKE v : \kint}
@;      }
@;      @item{
@;        @proofqed by @${\kint \subt \kany}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${v = \vpair{v_0}{v_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\wellKE v_0 \mbox{ and } \wellKE v_1}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE v_0 : \kany \mbox{ and } \wellKE v_1 : \kany}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @${\wellKE \vpair{v_0}{v_1} : \kpair}
@;        @proofbecause 2
@;      }
@;      @item{
@;        @proofqed by @${\kpair \subt \kany}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${v = \vlam{x}{e}}]{
@;    @proofitems[
@;      @item{
@;        @${x \wellKE e}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE \vlam{x}{e} : \kfun}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @proofqed by @${\kfun \subt \kany}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${v = \vlam{\tann{x}{\tau}}{e}}]{
@;    @proofitems[
@;      @item{
@;        @${\tann{x}{\tau} \wellKE e : \kany}
@;        @proofby{lemma:LK-D-inversion}
@;      }
@;      @item{
@;        @${\wellKE \vlam{\tann{x}{\tau}}{e} : \kfun}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @proofqed by @${\kfun \subt \kany}
@;      }
@;    ]
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@; TODO rename this
@;@lemma[@elem{@${\langK} value tag implies} #:key "lemma:LK-val-wellformed"]{
@;  If @${\wellKE v : \kany} then @${\wellKE v}
@;}
@;
@;@proof{
@;  By induction on the structure of @${v}.
@;
@;  @proofcase[@${v = i}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\wellKE v}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${v = \vpair{v_0}{v_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\wellKE v_0 : \kany \mbox{ and } \wellKE v_1 : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\wellKE v_0 \mbox{ and } \wellKE v_1}
@;        @proofbyIH[]
@;      }
@;      @item{
@;        @proofqed by 2
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${v = \vlam{x}{e}}]{
@;    @proofitems[
@;      @item{
@;        @${x \wellKE e}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @proofqed by 1
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${v = \vlam{\tann{x}{\tau}}{e}}]{
@;    @proofitems[
@;      @item{
@;        @${\tann{x}{\tau} \wellKE e : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @proofqed by 1
@;      }
@;    ]
@;  }
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} static-static substitution} #:key "lemma:LK-SS-subst"]{
@;      If @${\tann{x}{\tau},\Gamma \wellKE e : K}
@;      and @${\wellKE v : \tagof{\tau}}
@;      then @${\Gamma \wellKE \vsubst{e}{x}{v} : K}
@;}
@;@proof{
@;  By induction on the structure of @${e}.
@;
@;  @proofcase[@${e = x}]{
@;    @proofitems[
@;      @item{
@;        @${\tagof{\tau} = K \mbox{ or } \tagof{\tau} \subt K}
@;        @proofbecause @${\tann{x}{\tau},\Gamma \wellKE x : K}
@;      }
@;      @item{
@;        @${\vsubst{e}{x}{v} = v}
@;      }
@;      @item{
@;        @${\wellKE v : K}
@;        @proofbecause 1
@;      }
@;      @item{
@;        @${\Gamma \wellKE v : K}
@;        @proofby{lemma:weakening} 3
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = x'}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${(\vsubst{x'}{x}{v}) = x'}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = i}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\vsubst{i}{x}{v} = i}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{x}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\vsubst{(\vlam{x}{e'})}{x}{v} = \vlam{x}{e'}}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{x'}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vlam{x'}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @${x',\tann{x}{\tau},\Gamma \wellKE e'}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${x',\Gamma \wellKE \vsubst{e'}{x}{v}}
@;        @proofby{lemma:LK-DS-subst}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vlam{x'}{\vsubst{e'}{x}{v}} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{\tann{x'}{\tau'}}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vlam{\tann{x'}{\tau'}}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @${\tann{x'}{\tau'},\tann{x}{\tau},\Gamma \wellKE e' : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\tann{x'}{\tau'},\Gamma \wellKE \vsubst{e'}{x}{v} : \kany}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vlam{\tann{x'}{\tau'}}{(\vsubst{e'}{x}{v})} : K}
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vpair{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vpair{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e_0 : \kany
@;           \\\mbox{and } \tann{x}{\tau},\Gamma \wellKE e_1 : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v} : \kany
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v} : \kany}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vpair{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vapp{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vapp{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e_0 : K_0
@;           \\\mbox{and } \tann{x}{\tau},\Gamma \wellKE e_1 : K_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v} : K_0
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v} : K_1}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vapp{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \eunop{e_0}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \eunop{\vsubst{e_0}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e_0 : K_0}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v} : K_0}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \eunop{\vsubst{e_0}{x}{v}} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \ebinop{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \ebinop{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e_0 : K_0
@;           \\\mbox{and } \tann{x}{\tau},\Gamma \wellKE e_1 : K_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v} : K_0
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v} : K_1}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \ebinop{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \edyn{\tau'}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \edyn{\tau'}{\vsubst{e'}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e'}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e'}{x}{v}}
@;        @proofby{lemma:LK-DS-subst} (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \edyn{\tau'}{(\vsubst{e'}{x}{v})} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \edyn{\kany}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \edyn{\kany}{\vsubst{e'}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e'}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e'}{x}{v}}
@;        @proofby{lemma:LK-DS-subst} (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \edyn{\kany}{(\vsubst{e'}{x}{v})} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \echk{K'}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \echk{K'}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e' : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e'}{x}{v} : \kany}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \echk{K'}{(\vsubst{e'}{x}{v})} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \esta{\tau'}{e'} \mbox{ or } e = \esta{\kany}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @proofcontradiction{@${\Gamma \wellKE e : K}}
@;      }
@;    ]
@;  }
@;
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} static-dynamic substitution} #:key "lemma:LK-SD-subst"]{
@;      If @${x,\Gamma \wellKE e : K}
@;      and @${\wellKE v}
@;      then @${\Gamma \wellKE \vsubst{e}{x}{v} : K}
@;}
@;@proof{
@;  By induction on the structure of @${e}.
@;
@;  @proofcase[@${e = x}]{
@;    @proofitems[
@;      @item{
@;        @${K = \kany}
@;        @proofbecause @${x,\Gamma \wellKE x : K}
@;      }
@;      @item{
@;        @${\vsubst{e}{x}{v} = v}
@;      }
@;      @item{
@;        @${\wellKE v : K}
@;        @proofbecause @lemmaref{lemma:LK-val-tagging}
@;      }
@;      @item{
@;        @${\Gamma \wellKE v : K}
@;        @proofby{lemma:weakening} 3
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = x'}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\vsubst{x'}{x}{v} = x'}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = i}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\vsubst{i}{x}{v} = i}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{x}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\vsubst{(\vlam{x}{e'})}{x}{v} = \vlam{x}{e'}}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{x'}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vlam{x'}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @${x',x,\Gamma \wellKE e'}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${x',\Gamma \wellKE \vsubst{e'}{x}{v}}
@;        @proofby{lemma:LK-DD-subst}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vlam{x'}{\vsubst{e'}{x}{v}} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{\tann{x'}{\tau'}}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vlam{\tann{x'}{\tau'}}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @${\tann{x'}{\tau'},x,\Gamma \wellKE e' : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\tann{x'}{\tau'},\Gamma \wellKE \vsubst{e'}{x}{v} : \kany}
@;        @proofby{lemma:LK-SD-subst}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vlam{\tann{x'}{\tau'}}{(\vsubst{e'}{x}{v})} : K}
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vpair{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vpair{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e_0 : \kany
@;           \\\mbox{and } x,\Gamma \wellKE e_1 : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v} : \kany
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v} : \kany}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vpair{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vapp{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vapp{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e_0 : K_0
@;           \\\mbox{and } x,\Gamma \wellKE e_1 : K_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v} : K_0
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v} : K_1}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vapp{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \eunop{e_0}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \eunop{\vsubst{e_0}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e_0 : K_0}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v} : K_0}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \eunop{\vsubst{e_0}{x}{v}} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \ebinop{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \ebinop{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e_0 : K_0
@;           \\\mbox{and } x,\Gamma \wellKE e_1 : K_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v} : K_0
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v} : K_1}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \ebinop{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \edyn{\tau'}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \edyn{\tau'}{\vsubst{e'}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e'}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e'}{x}{v}}
@;        @proofby{lemma:LK-DD-subst} (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \edyn{\tau'}{(\vsubst{e'}{x}{v})} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \edyn{\kany}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \edyn{\kany}{\vsubst{e'}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e'}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e'}{x}{v}}
@;        @proofby{lemma:LK-DD-subst} (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \edyn{\kany}{(\vsubst{e'}{x}{v})} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \echk{K'}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \echk{K'}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e' : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e'}{x}{v} : \kany}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \echk{K'}{(\vsubst{e'}{x}{v})} : K}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \esta{\tau'}{e'} \mbox{ or } e = \esta{\kany}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @proofcontradiction{@${\Gamma \wellKE e : K}}
@;      }
@;    ]
@;  }
@;
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} dynamic-static substitution} #:key "lemma:LK-DS-subst"]{
@;      If @${\tann{x}{\tau},\Gamma \wellKE e}
@;      and @${\wellKE v : \tagof{\tau}}
@;      then @${\Gamma \wellKE \vsubst{e}{x}{v}}
@;}
@;@proof{
@;  By induction on the structure of @${e}.
@;
@;  @proofcase[@${e = x}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = v}
@;      }
@;      @item{
@;        @${\wellKE v : \kany}
@;        @proofbecause @${\tagof{\tau} \subt \kany}
@;      }
@;      @item{
@;        @${\wellKE v}
@;        @proofbecause @lemmaref{lemma:LK-val-wellformed} (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE v}
@;        @proofby{lemma:weakening} (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = x'}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\vsubst{x'}{x}{v} = x'}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = i}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\vsubst{i}{x}{v} = i}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{x}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\vsubst{(\vlam{x}{e'})}{x}{v} = \vlam{x}{e'}}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{x'}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vlam{x'}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @${x',\tann{x}{\tau},\Gamma \wellKE e'}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${x',\Gamma \wellKE \vsubst{e'}{x}{v}}
@;        @proofby{lemma:LK-DS-subst}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vlam{x'}{\vsubst{e'}{x}{v}}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{\tann{x'}{\tau'}}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vlam{\tann{x'}{\tau'}}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @${\tann{x'}{\tau'},\tann{x}{\tau},\Gamma \wellKE e' : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\tann{x'}{\tau'},\Gamma \wellKE \vsubst{e'}{x}{v} : \kany}
@;        @proofby{lemma:LK-SS-subst}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vlam{\tann{x'}{\tau'}}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vpair{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vpair{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e_0
@;           \\\mbox{and } \tann{x}{\tau},\Gamma \wellKE e_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v}
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v}}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vpair{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vapp{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vapp{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e_0
@;           \\\mbox{and } \tann{x}{\tau},\Gamma \wellKE e_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v}
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v}}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vapp{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \eunop{e_0}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \eunop{\vsubst{e_0}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e_0}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v}}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \eunop{\vsubst{e_0}{x}{v}}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \ebinop{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \ebinop{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e_0
@;           \\\mbox{and } \tann{x}{\tau},\Gamma \wellKE e_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v}
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v}}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \ebinop{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \edyn{\tau'}{e'}
@;                \mbox{ or } e = \edyn{\kany}{e'}
@;                \mbox{ or } e = \echk{K'}{e'}
@;               }]{
@;    @proofitems[
@;      @item{
@;        @proofcontradiction{@${\tann{x}{\tau},\Gamma \wellKE e}}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \esta{\tau'}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \esta{\tau'}{\vsubst{e'}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e' : \tagof{\tau'}}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e'}{x}{v} : \tagof{\tau'}}
@;        @proofby{lemma:LK-SS-subst} (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \esta{\tau'}{(\vsubst{e'}{x}{v})}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \esta{\kany}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \esta{\kany}{\vsubst{e'}{x}{v}}}
@;      }
@;      @item{
@;        @${\tann{x}{\tau},\Gamma \wellKE e' : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e'}{x}{v} : \kany}
@;        @proofby{lemma:LK-SS-subst} (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \esta{\kany}{(\vsubst{e'}{x}{v})}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${\langK} dynamic-dynamic substitution} #:key "lemma:LK-DD-subst"]{
@;      If @${x,\Gamma \wellKE e}
@;      and @${\wellKE v}
@;      then @${\Gamma \wellKE \vsubst{e}{x}{v}}
@;}
@;@proof{
@;  By induction on the structure of @${e}.
@;
@;  @proofcase[@${e = x}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = v}
@;      }
@;      @item{
@;        @${\Gamma \wellKE v}
@;        @proofby{lemma:weakening} 3
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = x'}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\vsubst{x'}{x}{v} = x'}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = i}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${\vsubst{i}{x}{v} = i}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{x}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @proofqed by @${(\vsubst{\vlam{x}{e'}}{x}{v}) = \vlam{x}{e'}}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{x'}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vlam{x'}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @${x',x,\Gamma \wellKE e'}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${x',\Gamma \wellKE \vsubst{e'}{x}{v}}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vlam{x'}{\vsubst{e'}{x}{v}}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vlam{\tann{x'}{\tau'}}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vlam{\tann{x'}{\tau'}}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @${\tann{x'}{\tau'},x,\Gamma \wellKE e' : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\tann{x'}{\tau'},\Gamma \wellKE \vsubst{e'}{x}{v} : \kany}
@;        @proofby{lemma:LK-SD-subst}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vlam{\tann{x'}{\tau'}}{(\vsubst{e'}{x}{v})}}
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vpair{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vpair{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e_0
@;           \\\mbox{and } x,\Gamma \wellKE e_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v}
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v}}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vpair{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \vapp{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \vapp{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e_0
@;           \\\mbox{and } x,\Gamma \wellKE e_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v}
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v}}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vapp{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \eunop{e_0}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \eunop{\vsubst{e_0}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e_0}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v}}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \eunop{\vsubst{e_0}{x}{v}}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \ebinop{e_0}{e_1}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \ebinop{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e_0
@;           \\\mbox{and } x,\Gamma \wellKE e_1}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e_0}{x}{v}
@;           \\\mbox{and } \Gamma \wellKE \vsubst{e_1}{x}{v}}
@;        @proofbyIH[] (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \ebinop{\vsubst{e_0}{x}{v}}{\vsubst{e_1}{x}{v}}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \edyn{\tau'}{e'}
@;                \mbox{ or } e = \edyn{\kany}{e'}
@;                \mbox{ or } e = \echk{K'}{e'}
@;               }]{
@;    @proofitems[
@;      @item{
@;        @proofcontradiction{@${\Gamma \wellKE e}}
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \esta{\tau'}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \esta{\tau'}{\vsubst{e'}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e' : \tagof{\tau'}}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e'}{x}{v} : \tagof{\tau'}}
@;        @proofby{lemma:LK-SD-subst} (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \esta{\tau'}{(\vsubst{e'}{x}{v})}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;  @proofcase[@${e = \esta{\kany}{e'}}]{
@;    @proofitems[
@;      @item{
@;        @${\vsubst{e}{x}{v} = \esta{\kany}{\vsubst{e'}{x}{v}}}
@;      }
@;      @item{
@;        @${x,\Gamma \wellKE e' : \kany}
@;        @proofby{lemma:LK-S-inversion}
@;      }
@;      @item{
@;        @${\Gamma \wellKE \vsubst{e'}{x}{v} : \kany}
@;        @proofby{lemma:LK-SD-subst} (2)
@;      }
@;      @item{
@;        @${\Gamma \wellKE \esta{\kany}{(\vsubst{e'}{x}{v})}}
@;        @proofbecause (3)
@;      }
@;      @item{
@;        @proofqed
@;      }
@;    ]
@;  }
@;
@;}
@;
@;@; -----------------------------------------------------------------------------
@;@lemma[@elem{@${K \subt K} finite} #:key "lemma:LK-finite-lattice"]{
@;  All chains @${K_0 \subt \cdots \subt K_n} are finite.
@;}
@;@proof{
@;  By definition.
@;  The longest chain has three tags: @${\knat \subt \kint \subt \kany}.
@;}
