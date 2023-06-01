package stx.lense;

/**
 * TODO: maybe reinstate `concat`
 */
interface LenseApi<K,V>{
  public function access(k:K,v:V):Option<V>;
}