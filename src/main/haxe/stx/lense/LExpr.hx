package stx.lense;

@:using(stx.lense.LExpr.LExprLift)
enum LExprSum<K,V>{
  LsId;
  LsConstant(value:Null<V>,_default:Null<V>);
  LsSequence(l:LExpr<K,V>,r:LExpr<K,V>);
  
  LsHoist(name:K);
  LsPlunge(name:K);
  
  LsXFork(pc:Cluster<K>,pa:Cluster<K>,lhs:LExpr<K,V>,rhs:LExpr<K,V>);
  LsMap(lense:LExpr<K,V>);
}

@:using(stx.lense.LExpr.LExprLift)
abstract LExpr<K,V>(LExprSum<K,V>) from LExprSum<K,V> to LExprSum<K,V>{
  public function new(self) this = self;
  @:noUsing static public function lift<K,V>(self:LExprSum<K,V>):LExpr<K,V> return new LExpr(self);

  public function prj():LExprSum<K,V> return this;
  private var self(get,never):LExpr<K,V>;
  private function get_self():LExpr<K,V> return lift(this);

}

class LExprLift{
  static public function seq<K,V>(self:LExpr<K,V>,that:LExpr<K,V>):LExpr<K,V>{
    return __.lense().LExpr.Sequence(self,that);
  }  
}