package stx.lense;

interface LenseApi<K,V>{
  final V : ComparableApi<V>;
  
  public function access(k:K,v:V):Option<V>;
  public function adjoin(lhs:V,rhs:V):Upshot<V,LenseFailure>;
  public function labels(v:V):Cluster<K>;
  public function select(v:V,labels:Cluster<K>):Upshot<Option<V>,LenseFailure>;

  /**
   * Checks `c` for the existence of `v`. If `c` is a map it null checks the value of the `k,v` of v and tests the
   * value if it exists.
   * Designed to allow set and map operations along the same generic types.
   * @param c 
   * @param v 
   * @return Bool
   */
  public function member(c:V,v:V):Bool;
}