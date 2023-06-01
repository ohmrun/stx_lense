package stx;

using stx.Nano;

typedef LExpr<K,V>    = stx.lense.LExpr<K,V>;
typedef LExprSum<K,V> = stx.lense.LExpr.LExprSum<K,V>;

class Lense{
  static public function lense(self:Wildcard){
    return new stx.lense.Module();
  }
}