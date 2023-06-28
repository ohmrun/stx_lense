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
  LsCopy(m:K,n:K);
  LsMerge(m:K,n:K);

  LsCCond(ccond:V,_true:LExpr<K,V>,_false:LExpr<K,V>);
  LsACond(ccond:V,acond:V,l:LExpr<K,V>,r:LExpr<K,V>);

  //LsBisect(head:LExpr<K,V>,tail:LExpr<K,V>);
}

@:using(stx.lense.LExpr.LExprLift)
abstract LExpr<K,V>(LExprSum<K,V>) from LExprSum<K,V> to LExprSum<K,V>{
  public function new(self) this = self;
  @:noUsing static public function lift<K,V>(self:LExprSum<K,V>):LExpr<K,V> return new LExpr(self);

  public function prj():LExprSum<K,V> return this;
  private var self(get,never):LExpr<K,V>;
  private function get_self():LExpr<K,V> return lift(this);

  public function toString(){
    return LExprLift.toString_with(this,x -> Std.string(x));
  }
}

class LExprLift{
  static public function seq<K,V>(self:LExpr<K,V>,that:LExpr<K,V>):LExpr<K,V>{
    return __.lense().LExpr.Sequence(self,that);
  }  
  static public function toString_with<K,V>(self:LExpr<K,V>,fn:V->String){
    final f = toString_with.bind(_,fn);
    return switch(self){
      case LsId                         : "id";
      case LsConstant(value,_default)   : 'const(${fn(value)}, ${fn(_default)})';
      case LsSequence(l,r)              : 'seq(${f(l)}, ${f(r)})';
      
      case LsHoist(name)                : 'hoist($name)';
      case LsPlunge(name)               : 'plunge($name)';
      
      case LsXFork(pc,pa,lhs,rhs)       : 'xfork($pc, $pa, ${f(lhs)}, ${f(rhs)})';
      case LsMap(x)                     : 'map($x)';
      case LsCopy(m,n)                  : 'copy($m, $n)';
      case LsMerge(m,n)                 : 'merge($m, $n)';
      case LsCCond(ccond,l,r)           : 'ccond($ccond, ${f(l)} ${f(r)})';
      case LsACond(ccond,acond,l,r)     : 'acond($ccond, $acond ${f(l)} $f(r)})';
    }
  }
}