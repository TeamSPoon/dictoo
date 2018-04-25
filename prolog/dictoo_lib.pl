:- module(dictoo_lib, [
  oo/1,
  oo_bind/2,
  is_oo/1,
  is_oo/2,
  % '$was_dictoo'/2,
  is_oo_invokable/2,
  oo_call/4,
  oo_call_dot_hook/4,
  oo_jpl_call/3,
  oo_deref/3,
  oo_put_attr/3,
  oo_put_attrs/2,               
  oo_get_attr/3,
  oo_get_attrs/2,
  oo_inner_class_begin/1,
  oo_inner_class_end/1,
  oo_class_field/1,
  oo_class_begin/1,
  oo_class_end/1,  
  oo_set/3,
  oo_put/4,
  oo_get/3  
  ]).

/** <module> dictoo_lib - Dict-like OO Syntax Pack

    Author:        Douglas R. Miles
    E-mail:        logicmoo@gmail.com
    WWW:           http://www.logicmoo.org
    Copyright (C): 2017
                       
    This program is free software; you can redistribute it and/or
    modify it.

*/



:- set_module(class(library)).
:- reexport(library(gvar_lib)).
:- use_module(library(dicts)).
:- use_module(library(attvar_serializer)).

:- multifile(dot_cfg:using_dot_type/2).
:- dynamic(dot_cfg:using_dot_type/2).

:- nodebug(dictoo(core)).
:- nodebug(dictoo(decl)).
:- nodebug(dictoo(syntax)).
:- nodebug(dictoo(goal_expand)).

% :- use_module(library(jpl),[jpl_set/3,jpl_get/3,jpl_call/4]).
% :- use_module(atts).

:- meta_predicate(fail_on_missing(*)).
% fail_on_missing(G):-current_predicate(G),!,call(G).
fail_on_missing(G):- notrace(catch(G,error(existence_error(_,_),_),fail)).


oo_get_attr(MVar,Attr,Value):- % notrace
            ((strip_module(MVar,M,Var),oo_call(M,Var,Attr,Value))).

oo_put_attr(MVar,Attr,Value):- notrace((strip_module(MVar,M,Var),oo_put(M,Attr,Var,Value))).

oo_get_attrs(V,Att3s):- var(V),!,get_attrs(V,Att3s),!.
oo_get_attrs('$VAR'(Name),_):- atom(Name),!,fail.
oo_get_attrs('$VAR'(Att3s),Att3):-!,Att3s=Att3.
oo_get_attrs('avar'(Att3s),Att3):-!,Att3s=Att3.
oo_get_attrs('avar'(_,Att3s),Att3):-!,Att3s=Att3.
% oo_get_attrs(V,Value):- trace_or_throw(oo_get_attrs(V,Value)).


put_atts_list([KV|Attrs],Var):-!, get_kv(KV,K,V),oo_set(Var,K,V),put_atts_list(Attrs,Var).
put_atts_list([],_):-!.

%:- if(exists_source(library(atts))).
%:- user:use_module(library(atts)).
oo_put_attrs(V,Attrs):- must_be(nonvar,Attrs),is_list(Attrs),!,put_atts_list(Attrs,V).
%:- endif.
oo_put_attrs(V,Att3s):- var(V),!,put_attrs(V,Att3s),!.
oo_put_attrs(VAR,Att3s):- VAR='$VAR'(Name), atom(Name),!,setarg(1,VAR, att(vn, Name, Att3s)).
oo_put_attrs(VAR,Att3s):- VAR='$VAR'(_Att3),!,setarg(1,VAR, Att3s).
oo_put_attrs(VAR,Att3s):- VAR='avar'(_Att3),!,setarg(1,VAR, Att3s).
oo_put_attrs(VAR,Att3s):- VAR='avar'(_,_),!,setarg(2,VAR, Att3s).
oo_put_attrs(V,Att3s):- trace_or_throw(oo_put_attrs(V,Att3s)).



% '$was_dictoo'(_,_).

%% is_oo(+Self) is det.
%% is_oo(+Module,+Self) is det.
%
%  Tests to see if Self
%   Has  Member Functions
%    
is_oo(S):- ((strip_module(S,M,O),is_oo(M,O))).
%is_oo(_,_):- !. % assume we''ll take care of dicts as well
is_oo(M,O):-  
 (var(O)->attvar(O);
  (is_dvar(O)->true;
 (((((((O='$was_dictoo'(MM,_),ignore(M=MM));
     is_dict(O);
     O=jclass(_);
     O=jpl(_);
     O= class(_);
     O='&'(_) ;
     O='&'(_,_) ;
     functor(O,'.',2);
     is_logtalk_object(O);

  fail_on_missing(jpl_is_ref(O));
  fail_on_missing(cli_is_object(O));
  fail_on_missing(cli_is_struct(O)))))))))),!.

:- if((false,exists_source(library(multivar)))).
:- use_module(library(multivar)).
oo(O):- call(ignore,xvarx(O)),put_attr(O,oo,binding(O,_Value)).
:- else.
oo(O):- do_but_warn(put_attr(O,oo,binding(O,_Value))).
:- endif.

do_but_warn(G):- call(G),dmsg(do_but_warn(G)).

oo_bind(O,Value):- oo(O),put_attr(O,oo,binding(O,Value)).
oo:attr_unify_hook(B,Value):- B = binding(_Var,Prev)->Prev.equals(Value);true.

oo_get_extender(_,_):-fail.

oo_put_extender(_,_):-fail.

new_oo(_M,Self,NewSelf):- oo(Self),NewSelf=Self.

logtalk_ready :- current_predicate(logtalk:current_logtalk_flag/2).

is_logtalk_object(O):- logtalk_ready, call(logtalk:current_object(O)).

nb_setattr(Att,Key,Value):-nb_setattr(Att,Att,Key,Value).
nb_setattr(att(Key,_OldValue,_),Atts,Key,Value):-!,nb_setarg(2,Atts,Value).
nb_setattr(att(_,_,[]),Att,Key,Value):-!,nb_setarg(3,Att,att(Key,Value,[])).
nb_setattr(att(_,_,Att),_,Key,Value):-nb_setattr(Att,Att,Key,Value).

oo_set(UDT,Key, Value):- attvar(UDT),!,get_attrs(UDT,Atts),nb_setattr(Atts,Atts,Key,Value).
oo_set(UDT,Key,Value):- var(UDT),!,do_but_warn(put_attrs(UDT,Key,Value)),!.
oo_set(UDT,Key, Value):- is_dict(UDT),!,nb_set_dict(Key, UDT, Value).
% todo index these by sending in the UDT on two args
oo_set(UDT,Key,Value):- UDT='$VAR'(Name), atom(Name),!,nb_setarg(1,UDT, att(vn, Name, att(Key,Value, []))).
oo_set(UDT,Key,Value):- UDT='$VAR'(Att3),!,nb_setarg(1,UDT,att(Key,Value,Att3)).
oo_set(UDT,Key,Value):- UDT='avar'(Att3),!,nb_setarg(1,UDT,att(Key,Value,Att3)).
oo_set(UDT,Key,Value):- UDT='avar'(_,Att3),!,nb_setarg(2,UDT, att(Key,Value,Att3)).
oo_set(UDT,Key,Value):- UDT=att(_,_,_),!,nb_setattr(UDT,Key,Value).
oo_set(UDT,Key,Value):-is_rbtree(UDT),!,rb_insert(UDT,Key,Value,NewUDT),arg(1,NewUDT,Arg1),nb_setarg(1,UDT,Arg1),arg(2,NewUDT,Arg2),nb_setarg(2,UDT,Arg2).
oo_set(UDT,Key,Value):-is_assoc(UDT),!,put_assoc(Key,UDT,Value,NewUDT),nb_copy(NewUDT,UDT).
oo_set(UDT,Key,Value):-is_list(UDT),!,((member(KV,UDT),get_kv(KV,K,_),Key==K,nb_set_kv(KV,K,Value))->true;(nb_copy([Key-Value|UDT],UDT))).
oo_set(UDT,Key,Value):- fail_on_missing(jpl_is_ref(UDT)),jpl_set(UDT,Key,Value).
%oo_set(UDT,Key,Value):- trace_or_throw(oo_set(UDT,Key,Value)).

b_copy(NewMap,Map):-functor(NewMap,F,A),functor(Map,F,A),b_copy(A,NewMap,Map).
b_copy(A,NewMap,Map):- arg(A,NewMap,E),setarg(A,NewMap,E), (A==1-> true ; Am1 is A-1, (b_copy(Am1,NewMap,Map))).

nb_copy(NewMap,Map):-functor(NewMap,F,A),functor(Map,F,A),nb_copy(A,NewMap,Map).
nb_copy(A,NewMap,Map):- arg(A,NewMap,E),nb_setarg(A,NewMap,E), (A==1-> true ; Am1 is A-1, (b_copy(Am1,NewMap,Map))).


%get_kv(KV,K,V):-compound(KV),(KV=..[_,K,V]->true;KV=..[K,V]).
%% get_kv( ?KV, ?X, ?Y) is semidet.
%
% Get Kv.
%
get_kv(X=Y,X,Y):- !.
get_kv(X-Y,X,Y):- !.
get_kv(KV,X,Y):- functor(KV,_,1),KV=..[X,Y],!.
get_kv(KV,X,Y):- arg(1,KV,X),arg(2,KV,Y),!.

b_put_kv(KV,_,V):- functor(KV,_,A),setarg(A,KV,V).
nb_put_kv(KV,_,V):- functor(KV,_,A),nb_setarg(A,KV,V).


% oo_get_attr(V,A,Value):- trace_or_throw(oo_get_attr(V,A,Value)).


oo_put(M,Key, UDT, Value, NewUDT):- is_dict(UDT),!,M:put_dict(Key, UDT, Value, NewUDT).
oo_put(M,Key, UDT, Value, NewUDT):- oo_copy_term(UDT,NewUDT),oo_put(M,Key,NewUDT, Value).

oo_copy_term(UDT,NewUDT):- copy_term(UDT,NewUDT).

oo_put(M,Key, UDT,Value):- attvar(UDT),!,M:put_attr(UDT,Key, Value).                           
oo_put(_M,Key,UDT,Value):- var(UDT),!,put_attr(UDT,Key,Value),!.
oo_put(_M,Key,UDT,Value):- UDT=att(_,_,_),!,nb_setattr(UDT,Key,Value).
oo_put(M,Key, UDT, Value):- is_dict(UDT),!,M:put_dict(Key, UDT, Value).
% todo index these by sending in the UDT on two args
oo_put(_M,Key,UDT,Value):- UDT='$VAR'(Name), atom(Name),!,setarg(1,UDT, att(vn, Name, att(Key,Value, []))).
oo_put(_M,Key,UDT,Value):- UDT='$VAR'(Att3),!,setarg(1,UDT, att(Key,Value,Att3)).
oo_put(_M,Key,UDT,Value):- UDT='avar'(Att3),!,setarg(1,UDT, att(Key,Value,Att3)).
oo_put(_M,Key,UDT,Value):- UDT='avar'(_,Att3),!,setarg(2,UDT, att(Key,Value,Att3)).
oo_put(_M,Key,UDT,Value):-is_rbtree(UDT),!,rb_insert(UDT,Key,Value,NewUDT),arg(1,NewUDT,Arg1),setarg(1,UDT,Arg1),arg(2,NewUDT,Arg2),setarg(2,UDT,Arg2).
oo_put(_M,Key,UDT,Value):-is_assoc(UDT),!,put_assoc(Key,UDT,Value,NewUDT),b_copy(NewUDT,UDT).
oo_put(_M,Key,UDT,Value):-is_list(UDT),!,((member(KV,UDT),get_kv(KV,K,_),Key==K,set_kv(KV,K,Value))->true;(b_copy([Key-Value|UDT],UDT))).
oo_put(M,Key, UDT, Value):- M:oo_set(UDT,Key, Value),!.
oo_put(M,Key, UDT,Value):- trace_or_throw(oo_put(M,Key, UDT,Value)).


oo_get(Key, UDT, Value):- strip_module(UDT,M,Self), oo_call(M,Self,Key, Value).

put_dict(Key,Map,Value):- ((get_dict(Key,Map,_),b_set_dict(Key,Map,Value))->true;(oo_put_extender(Map,Ext),oo_put_attr(Ext,Key,Value))).


oo_jpl_call(A,B,C):- (integer(B);B==length; B= (_-_)),!,jpl_get(A,B,C).
oo_jpl_call(A,B,C):- (compound(B)->compound_name_arguments(B,H,L);(H=B,L=[])),fail_on_missing(jpl_call(A,H,L,C)),!.
oo_jpl_call(A,B,C):- catch(fail_on_missing(jpl_get(A,B,C)),E,(debug(dictoo(_),'~N~w,~n',[E:jpl_get(A,B,C)]),fail)).

to_atomic_name(DMemb,Memb):- compound(DMemb),!,compound_name_arity(DMemb,Memb,0).
to_atomic_name(Memb,Memb):- var(Memb),!.
to_atomic_name(SMemb,Memb):- string_to_atom(SMemb,Memb).

member_func_unify(X,Y):- to_atomic_name(X,X1),to_atomic_name(Y,Y1),X1=Y1.

%% is_oo_invokable(+Self,-DeRef) is det.
%
%  DeRef''s an OO Whatnot and ckecks if invokable
%    

is_oo_invokable(Was,Was):- is_oo(Was),!.
% is_oo_invokable(Was,Was):- M:nb_current('$oo_stack',[Was|_])
is_oo_invokable(Was,Ref):- strip_module(Was,M,Self),oo_deref(M,Self,Ref),!,((Self\==Ref,M:Self\==Ref,Self\==M:Ref);is_oo(M,Ref)).

:- module_transparent(oo_call/4).
:- module_transparent(oo_call_dot_hook/4).

:- thread_initialization(nb_setval('$oo_stack',[])).
oo_call_dot_hook(M,Self, Func, Value):- is_dict(Self), M:dot_dict(Self, Func, Value),!.
oo_call_dot_hook(M,A,B,C):-  (M:nb_current('$oo_stack',Was)->true;Was=[]),b_setval('$oo_stack',['.'(A,B,C)|Was]),oo_call(M,A,B,C).

oo_call(M,DVAR, Memb,Value):- dvar_name(M,DVAR,_,NameSpace),
   dot_cfg:dictoo_decl(= ,_SM,_CM,From,DVAR,DMemb,Value,Call),member_func_unify(DMemb,Memb),!,
   sanity(ground(NameSpace)),
   show_call(dictoo(core), From:Call).



%oo_call(M,DVAR,Memb,Value):- Memb==value, dvar_name(M,DVAR,_,GVar), atom(GVar), var(Value),M:nb_current_value(GVar,Value),!.
%oo_call(M,DVAR,Memb,Value):- Memb==value, dvar_name(M,DVAR,_,GVar), atom(GVar),!,must( M:nb_link_value(GVar,Value)),!, on_bind(Value,gvar_put(M, GVar, Value)),!.

oo_call(_M,Self,Memb,Value):- notrace((atom(Memb),attvar(Self))),get_attr(Self, Memb, Value),!.
                                                 
oo_call(M,Self,Memb,Value):- var(Self),atom(Memb),!,trace,on_bind(Self,oo_call(M,Self,Memb,Value)).
oo_call(M,Self,Memb,Value):- var(Self),!,trace,on_bind(Self,oo_call(M,Self,Memb,Value)).

oo_call(_M,'$VAR'(Name),N,V):- atom(Name),!,N=vn,V=Name.
oo_call(_M,'$VAR'(Att3),A,Value):- !, put_attrs(NewVar,Att3),get_attr(NewVar,A,Value).
oo_call(_M,'avar'(Att3),A,Value):- !, put_attrs(NewVar,Att3),get_attr(NewVar,A,Value).
oo_call(_M,'avar'(_,Att3),A,Value):- !, put_attrs(NewVar,Att3),get_attr(NewVar,A,Value).
oo_call(M,Map,Key,Value):-is_dict(Map),!,(get_dict(Key,Map,Value)->true;(oo_get_extender(Map,Ext),oo_call(M,Ext,Key,Value))).
oo_call(M,Map,Key,Value):-is_rbtree(Map),!,(rb_in(Key,Value,Map)->true;(oo_get_extender(Map,Ext),oo_call(M,Ext,Key,Value))).
oo_call(M,Map,Key,Value):-is_assoc(Map),!,(get_assoc(Key,Value,Map)->true;(oo_get_extender(Map,Ext),oo_call(M,Ext,Key,Value))).
oo_call(M,Map,Key,Value):-is_list(Map),!,((member(KV,Map),get_kv(KV,K,V),Key==K,V=Value)->true;(oo_get_extender(Map,Ext),oo_call(M,Ext,Key,Value))).
oo_call(_M,Self,Memb,Value):- strip_module(Memb,M,Prop),Memb\==Prop,catch(oo_call(M,Self,Prop,Value),_E,fail).


oo_call(M,'$was_dictoo'(CM,Self),Memb,Value):- var(Self),new_oo(M,Self,NewSelf),!,M:oo_call(CM,NewSelf,Memb,Value).
                                                                                                                                

oo_call(M,DVAR,add(Memb,V),'$was_dictoo'(M,DVAR)):-
  dvar_name(M,DVAR,_,GVar), 
  notrace((atom(GVar),M:nb_current_value(GVar,Self))),
  is_dict(Self),!,
  M:put_dict(Memb,Self,V,NewSelf),
  M:nb_set_value(GVar,NewSelf).

oo_call(M,DVAR,Memb,Value):- dvar_name(M,DVAR,_,GVar), atom(GVar), gvar_call(M, GVar, Memb, Value),!.
oo_call(M,DVAR,Memb,Value):- dvar_name(M,DVAR,_,GVar), is_gvar(M,GVar,_Name),gvar_call(M,GVar,Memb,Value),!.

oo_call(M,'&'(Self,_),Memb,Value):- gvar_call(M,Self,Memb,Value),!.
oo_call(M,'&'(_,Self),Memb,Value):- oo_call(M,Self,Memb,Value),!.
oo_call(M,Self,set(Memb,Value),'&'(Self)):- is_dict(Self),!,M:nb_set_dict(Memb,Self,Value).

 

oo_call(M,Self,Memb,Value):- notrace(is_dict(Self)),!, M:dot_dict(Self, Memb, Value).
oo_call(M,'&'(Self),Memb,Value):- !,oo_call(M,Self,Memb,Value).
oo_call(M,jpl(Self),Memb,Value):- !, M:oo_jpl_call(Self, Memb, Value).
oo_call(M,jclass(Self),Memb,Value):- !, M:oo_jpl_call(Self, Memb, Value).
oo_call(M,class(Self),Memb,Value):- M:fail_on_missing(cli_call(Self, Memb, Value)),!.
oo_call(M,DVAR,Memb,Value):- dvar_name(M,DVAR,_,GVar), atom(GVar),
 (M:nb_current_value(GVar,Self)),oo_call(M,Self,Memb,Value),
 M:nb_set_value(GVar,Self).

oo_call(M,Self,Memb,Value):- fail_on_missing(jpl_is_ref(Self)),!,M:oo_jpl_call(Self, Memb, Value).

oo_call(M,Self,Memb,Value):-  notrace(fail_on_missing(cli_is_object(Self))),!,fail_on_missing(M:cli_call(Self, Memb, Value)).
oo_call(M,Self,Memb,Value):-  notrace(fail_on_missing(cli_is_struct(Self))),!,fail_on_missing(M:cli_call(Self, Memb, Value)).
oo_call(M,Class,Inner,Value):- show_success(is_oo_class(inner(Class,Inner))),!,oo_call(M,inner(Class,Inner),Value,_).

oo_call(M,'&'(_,DeRef),Memb,Value):- oo_call(M,DeRef,Memb,Value).

%oo_call(M,Self,deref,Value):- var(Self),nonvar(Value),!,oo_call(M,Value,deref,Self).
%oo_call(M,Self,deref,Self):-!.

% oo_call(M,Self,Memb,Value):- nonvar(Value),trace_or_throw(oo_call(M,Self,Memb,Value)).
oo_call(M,Self,Memb,Value):- ((oo_deref(M,Self,NewSelf)-> NewSelf\==Self)),!,oo_call(M,NewSelf,Memb,Value).

% oo_call(M,Self,Memb,Value):- gvar_interp(M,Self,Self,Memb,Value).

oo_call(M,DVAR,Memb,Value):- dvar_name(M,DVAR,_,NameSpace), nonvar(NameSpace),
  dot_cfg:dictoo_decl(= ,_SM,_CM,From,DVAR,Unk,Value,Call),!,
  throw(M:dot_cfg:dictoo_decl(= ,From,NameSpace,Memb-->Unk,Value,Call)),fail.

oo_call(_,M:Self,Memb,Value):- !,oo_call(M,Self,Memb,Value).
oo_call(_,_Self,_Memb,_Value):- !,fail.
oo_call(_,Self,Memb,Value):- Value =.. ['.', Self,Memb],!.

oo_call(M,Self,Memb,Value):- throw(oo_call(M,Self,Memb,Value)).

oo_call(M,Self,Memb,Value):- var(Value),!,on_bind(Value, oo_put(M,Memb,Self, Value)).
oo_call(M,Self,Memb,Value):- var(Memb),!,on_bind(Memb, oo_put(M,Memb,Self, Value)).

oo_call(_,Self,Memb,Value):- var(Value),!,Value='&'(Self,Memb).
oo_call(M,Self,Memb,Value):- throw(oo_call(M,Self,Memb,Value)).

/*
oo_call(M,Self,Memb,Value):- nb_link_value(Self,construct(Self,Memb,Value)),!,oo_call(M,Self,Memb,Value).
oo_call(M,Self,Memb,Value):- to_member_path(Memb,[F|Path]),append(Path,[Value],PathWValue),
   Call =.. [F,Self|PathWValue],
   oo_call(M,Call).

to_member_path(C,[F|ARGS]):-compound(C),!,compound_name_args(C,F,ARGS).
to_member_path(C,[C]).

*/


oo_deref(M,Obj,RObj):- var(Obj),!,M:once(get_attr(Obj,oo,binding(_,RObj));Obj=RObj),!.
% oo_deref(M,'$'(GVar),'&'(GVar,Value)):- atom(GVar),M:nb_current_value(GVar,Value),!.
oo_deref(_,Value,Value):- \+ compound(Value),!.

oo_deref(M,DVAR,Value):- dvar_name(M,DVAR,_,GVar), atom(GVar),notrace((M:nb_current_value(GVar,ValueM))),!,oo_deref(M,ValueM,Value).
oo_deref(M,cl_eval(Call),Result):-is_list(Call),!,M:fail_on_missing(cl_eval(Call,Result)).
oo_deref(M,cl_eval(Call),Result):-!,nonvar(Call),oo_deref(M,Call,CallE),!,M:call(CallE,Result).
%oo_deref(M,Value,Value):- M:fail_on_missing(jpl_is_ref(Value)),!.
% %oo_deref(M,[A|B],Result):-!, maplist(oo_deref(M),[A|B],Result).
% %oo_deref(M,Call,Result):- call(Call,Result),!.
%oo_deref(_,Value,Value):- is_logtalk_object(Value).
%oo_deref(M,Head,HeadE):- Head=..B,maplist(oo_deref(M),B,A),HeadE=..A,!.
oo_deref(_,Value,Value).


oo_get(M,Key, Dict, Value, NewDict, NewDict) :- is_dict(Dict),!,
   M:get_dict(Key, Dict, Value, NewDict, NewDict).
oo_get(M,Key, Dict, Value, NewDict, NewDict) :-
        oo_get(M,Key, Dict, Value),
        oo_put(M,Key, Dict, NewDict, NewDict).



%!  eval_oo_function(M,+Func, +Tag, +UDT, -Value)
%
%   Test for predefined functions on Objects or evaluate a user-defined
%   function.

eval_oo_function(_M,Func, Tag, UDT, Value) :- is_dict(UDT),!,
   '$dicts':eval_dict_function(Func, Tag, UDT, Value).

eval_oo_function(M,get(Key), _, UDT, Value) :-
    !,
    oo_get(M,Key, UDT, Value).
eval_oo_function(M,put(Key, Value), _, UDT, NewUDT) :-
    !,
    (   atomic(Key)
    ->  oo_put(M,Key, UDT, Value, NewUDT)
    ;   put_oo_path(M,Key, UDT, Value, NewUDT)
    ).
eval_oo_function(M,put(New), _, UDT, NewUDT) :-
    !,
    oo_put(M,New, UDT, NewUDT).
eval_oo_function(M,Func, Tag, UDT, Value) :-
    M:call(Tag:Func, UDT, Value).


%!  put_oo_path(M,+KeyPath, +UDT, +Value, -NewUDT)
%
%   Add/replace  a  value  according  to  a  path  definition.  Path
%   segments are separated using '/'.

put_oo_path(M,Key, UDT, Value, NewUDT) :-
    atom(Key),
    !,
    oo_put(M,Key, UDT, Value, NewUDT).
put_oo_path(M,Path, UDT, Value, NewUDT) :-
    get_oo_path(M,Path, UDT, _Old, NewUDT, Value).

get_oo_path(_M,Path, _, _, _, _) :-
    var(Path),
    !,
    '$instantiation_error'(Path).
get_oo_path(M,Path/Key, UDT, Old, NewUDT, New) :-
    !,
    get_oo_path(M,Path, UDT, OldD, NewUDT, NewD),
    (   oo_get(M,Key, OldD, Old, NewD, New),
        is_oo(M,Old)
    ->  true
    ;   Old = _{},
        oo_put(M,Key, OldD, New, NewD)
    ).
get_oo_path(M,Key, UDT, Old, NewUDT, New) :-
    oo_get(M,Key, UDT, Old, NewUDT, New),
    is_oo(M,Old),
    !.
get_oo_path(M,Key, UDT, _{}, NewUDT, New) :-
    oo_put(M,Key, UDT, New, NewUDT).

:- dynamic(is_oo_class/1).
:- dynamic(is_oo_class_field/2).
:- multifile(dot_cfg:dictoo_decl/8).
:- dynamic(dot_cfg:dictoo_decl/8).
:- discontiguous(dot_cfg:dictoo_decl/8).

% is_oo_hooked(M,Self,_Func,_Value):- M:is_oo(M,Self),!.
is_oo_hooked(M,Self,_Func,_Value):- M:is_oo_invokable(Self,_),!.

% $current_file.value = X :- prolog_load_context(file,X).
% dot_cfg:dictoo_decl(= ,mpred_gvars,current_file,value,A,prolog_load_context(file, A)).
is_oo_hooked(M, IVar, Memb, Value):- compound(IVar), IVar = ($(Var)),
   dot_cfg:dictoo_decl(= ,_SM,_CM,M,Var, Memb, Value,_Body).

% is_oo_hooked(M, IVar, value, Ref):- atom(IVar),IVar=Var,dot_cfg:dictoo_decl(= ,SM,CM,M,IVar,value,_Value,_Body),!,must(Ref=IVar).


%is_oo_hooked(M,Var,_,Ref):- dot_cfg:dictoo_decl(= ,SM,CM,M,Var,value,_Value,_Body),Ref=Var.


oo_class_begin(Name):-asserta(is_oo_class(Name)).
oo_class_end(Name):- is_oo_class(Name),!,retract(is_oo_class(Name)),assertz(is_oo_class(Name)).

oo_inner_class(Name,Inner):-asserta(is_oo_class(inner(Name,Inner))).

oo_inner_class_begin(Inner):- is_oo_class(Name),!,oo_class_begin(inner(Name,Inner)).
oo_inner_class_end(Inner):- is_oo_class(inner(Name,Inner)),!,oo_class_end(inner(Name,Inner)).

oo_class_field(Inner):- is_oo_class(Name),!,asserta(is_oo_class_field(Name,Inner)).

:- multifile(gvs:dot_overload_hook/4).
:- dynamic(gvs:dot_overload_hook/4).
:- module_transparent(gvs:dot_overload_hook/4).
gvs:dot_overload_hook(M,NewName, Memb, Value):- dot_cfg:using_dot_type(_,M)
  -> show_call(dictoo(overload),oo_call_dot_hook(M,NewName, Memb, Value)).

:- multifile(gvs:is_dot_hook/4).
:- dynamic(gvs:is_dot_hook/4).
:- module_transparent(gvs:is_dot_hook/4).
gvs:is_dot_hook(M,Self,Func,Value):- dot_cfg:using_dot_type(_,M) 
  -> is_oo_hooked(M,Self,Func,Value),!.


:- 
   gvar_file_predicates_are_exported,
   gvar_file_predicates_are_transparent.


