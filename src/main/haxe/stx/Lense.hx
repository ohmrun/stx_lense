package stx;

using stx.Nano;

typedef LenseFailureSum   = stx.fail.LenseFailure.LenseFailureSum;
typedef LenseFailure      = stx.fail.LenseFailure;

typedef LenseReader       = stx.lense.Reader;
typedef LExpr<K,V>        = stx.lense.LExpr<K,V>;
typedef LExprSum<K,V>     = stx.lense.LExpr.LExprSum<K,V>;

class Lense{
  static public function lense(self:Wildcard){
    return new stx.lense.Module();
  }
}