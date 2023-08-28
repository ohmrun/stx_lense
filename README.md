# Stx Lense

Functional lenses require macros or type constructors so if you drop down to a more homogenous object tree description you can implement them there.


This library is based on the paper [A Language for Bi-Directional Tree Transformations](https://www.cis.upenn.edu/~bcpierce/papers/lenses-toplas-final.pdf) and currently implements the following lenses over [pml](https://github.com/ohmrun/pml):


```haxe
  LsId;//Id
  LsConstant(value:Null<V>,_default:Null<V>);//Constant
  LsSequence(l:LExpr<K,V>,r:LExpr<K,V>);//Sequence

  LsHoist(name:K);//Hoist
  LsPlunge(name:K);//Plunge
  
  LsXFork(pc:Cluster<K>,pa:Cluster<K>,lhs:LExpr<K,V>,rhs:LExpr<K,V>);//XFork
  LsMap(lense:LExpr<K,V>);//Map
  LsCopy(m:K,n:K);//Copy
  LsMerge(m:K,n:K);//Merge

  LsCCond(ccond:V,_true:LExpr<K,V>,_false:LExpr<K,V>);//Concrete Condition
  LsACond(ccond:V,acond:V,l:LExpr<K,V>,r:LExpr<K,V>);//Abstract Condition

```