package stx.lense;

class LExprCtr extends Clazz{
  /**
   * Use whatever input there is.
   */
  public function Id<K,V>():LExpr<K,V>{
    return LsId;
  }
  /**
   * Use `value` instead of input.
   * @param lense 
   * @return LExpr<K,V>
   */
  public function Constant<K,V>(value,?_default):LExpr<K,V>{
    return LsConstant(value,_default);
  }
  /**
   * Apply `l` and then `r`
   * @param p 
   * @param lhs 
   * @param rhs 
   * @return LExpr<K,V>
   */
  public function Sequence<K,V>(l:LExpr<K,V>,r:LExpr<K,V>):LExpr<K,V>{
    return LsSequence(l,r);
  }
  /**
   * Make value at `name` the root.
   * @param n 
   * @param v 
   * @return LExpr<K,V>
   */
  public function Hoist<K,V>(name:K):LExpr<K,V>{
    return LsHoist(name);
  }
  /**
   * Drop root namespace into `name`.
   * @param n 
   * @param v 
   * @return LExpr<K,V>
   */
  public function Plunge<K,V>(name:K):LExpr<K,V>{
    return LsPlunge(name);
  }
  public function XFork<K,V>(pc:Cluster<K>,pa:Cluster<K>,lhs:LExpr<K,V>,rhs:LExpr<K,V>):LExpr<K,V>{
    return LsXFork(pc,pa,lhs,rhs);
  }
  /**
   * Apply `lense` to values
   * @param m 
   * @param n 
   */
  public function Map<K,V>(lense:LExpr<K,V>):LExpr<K,V>{
    return LsMap(lense);
  }
  /**
   * Apply `lhs` to `p` and `rhs` to `!p`
   * @param m 
   * @param n 
   */
  public function Fork<K,V>(p:Cluster<K>,lhs:LExpr<K,V>,rhs:LExpr<K,V>):LExpr<K,V>{
    return LsXFork(p,p,lhs,rhs);
  }
  /**
   * Keep keys `ns`
   * @param ns 
   * @param d
   */
  public function Filter<K,V>(p:Cluster<K>,?d:Null<V>):LExpr<K,V>{
    return Fork(p,LsId,LsConstant(null,d));
  }
  /**
   * Remove keys `ns`
   * @param ns 
   * @param d
   */
  public function Prune<K,V>(ns:Cluster<K>,?d:Null<V>):LExpr<K,V>{
    return Fork(ns,LsConstant(null,d),LsId);
  }
  public function Add<K,V>(n:K,v:V):LExpr<K,V>{
    return LsXFork(
      [],[n],
      Constant(v,null).seq(LsPlunge(n))
      ,Id()
    );
  }
  public function Focus<K,V>(n:K,?d:Null<V>):LExpr<K,V>{
    return Sequence(Filter([n],d),LsHoist(n));
  }
  public function Rename<K,V>(m:K,n:K):LExpr<K,V>{
    return LsXFork([m],[n],LsHoist(m).seq(LsPlunge(n)),LsId);
  }
  public function Copy<K,V>(m:K,n:K):LExpr<K,V>{
    return LsCopy(m,n);
  }
  public function Merge<K,V>(m:K,n:K):LExpr<K,V>{
    return LsMerge(m,n);
  }
  public function Spray<K,V>(zero_c:V,zero_k:K):LExpr<K,V>{
    return CCond(zero_c,Id(),Plunge(zero_k));
  }
  public function CCond<K,V>(ccond:V,l:LExpr<K,V>,r:LExpr<K,V>){
    return LsCCond(ccond,l,r);
  }
  // public function Bisect<K,V>(head:LExpr<K,V>,tail:LExpr<K,V>){
  //   return LsBisect(head,tail);
  // }
  //public function WMap<K,V>(f:K->LExpr,K,V>)
  //HeadTail(head:LExpr<K,V>,tail:LExpr<K,V>);
}