package stx.lense;

class Module extends Clazz{
  @:isVar public var LExpr(get,null):LExprCtr;
  private function get_LExpr():LExprCtr{
    return __.option(this.LExpr).def(() -> this.LExpr = new LExprCtr());
  }
  public function Pml(inner){
    return new stx.lense.term.Pml(inner);
  }
}