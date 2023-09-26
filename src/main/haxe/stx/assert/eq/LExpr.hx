package stx.assert.eq;

import stx.lense.LExpr as TLExpr;

class LExpr<K,V> extends EqCls<TLExpr>{
  final K : Eq<K>;
  final V : Eq<V>;
  public function comply(lhs:TLExpr<K>,rhs:TLExpr<V>){
    return switch([lhs,rhs]){

    }
  }
}