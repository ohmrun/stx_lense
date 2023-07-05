package stx.lense;

/**
 * TODO: maybe reinstate `concat`
 */
interface LenseApi<K,V>{
  final V : ComparableApi<V>;
  
  public function access(k:K,v:V):Option<V>;
  public function adjoin(lhs:V,rhs:V):Upshot<V,LenseFailure>;
  public function labels(v:V):Cluster<K>;
  public function select(v:V,labels:Cluster<K>):Upshot<Option<V>,LenseFailure>;

  public function member(c:V,v:V):Bool;
  //public function unique():K;
}