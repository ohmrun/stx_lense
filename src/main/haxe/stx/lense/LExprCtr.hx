package stx.lense;

class LExprCtr extends Clazz{
  static public function Id(){
    return LsId;
  }
  public function Constant<K,V>(value,?_default):LExpr<K,V>{
    return LsConstant(value,_default);
  }
  public function Sequence<K,V>(l:LExpr<K,V>,r:LExpr<K,V>):LExpr<K,V>{
    return LsSequence(l,r);
  }
  public function Hoist<K,V>(name:K):LExpr<K,V>{
    return LsHoist(name);
  }
  public function Plunge<K,V>(name:K):LExpr<K,V>{
    return LsPlunge(name);
  }
  public function XFork<K,V>(pc:Cluster<K>,pa:Cluster<K>,lhs:LExpr<K,V>,rhs:LExpr<K,V>):LExpr<K,V>{
    return LsXFork(pc,pa,lhs,rhs);
  }
  public function Map<K,V>(lense:LExpr<K,V>):LExpr<K,V>{
    return LsMap(lense);
  }
  public function Fork<K,V>(p:Cluster<K>,lhs:LExpr<K,V>,rhs:LExpr<K,V>):LExpr<K,V>{
    return LsXFork(p,p,lhs,rhs);
  }
  public function Filter<K,V>(p:Cluster<K>,?d:Null<V>):LExpr<K,V>{
    return Fork(p,LsId,LsConstant(null,d));
  }
  /**
   * Remove Keys in `ns`
   * @param ns 
   * @param d
   */
  public function Prune<K,V>(ns:Cluster<K>,?d:Null<V>):LExpr<K,V>{
    return Fork(ns,LsConstant(null,d),LsId);
  }
  public function Add<K,V>(n:K,v:Null<V>):LExpr<K,V>{
    return LsXFork([],[n],LsConstant(v,null),LsPlunge(n));
  }
  public function Focus<K,V>(n:K,?d:Null<V>):LExpr<K,V>{
    return Sequence(Filter([n],d),LsHoist(n));
  }
  public function Rename<K,V>(m:K,n:K){
    return LsXFork([m],[n],LsHoist(m).seq(LsPlunge(n)),LsId);
  }
}