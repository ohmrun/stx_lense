package stx.fail;

enum LenseFailureSum{
  E_Lense(reason:String);
  E_Lense_Pml(e:PmlFailure);
}
@:using(stx.fail.LenseFailure.LenseFailureLift)
@:forward abstract LenseFailure(LenseFailureSum) from LenseFailureSum to LenseFailureSum{
  static public var _(default,never) = LenseFailureLift;
  public inline function new(self:LenseFailureSum) this = self;
  @:noUsing static inline public function lift(self:LenseFailureSum):LenseFailure return new LenseFailure(self);

  public function prj():LenseFailureSum return this;
  private var self(get,never):LenseFailure;
  private function get_self():LenseFailure return lift(this);
}
class LenseFailureLift{
  static public inline function lift(self:LenseFailureSum):LenseFailure{
    return LenseFailure.lift(self);
  }
}