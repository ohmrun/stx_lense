package stx.lense.test;

final ctr : stx.lense.term.Pml<Atom>  = __.lense().Pml(__.assert().Comparable().pml().Atom);
final _   : LExprCtr                  = __.lense().LExpr;

class HoistTest extends TestCase{
  public function test(){
    final a = __.pml().parser()("{ :a { :b 1 } }".reader()).toUpshot().value().fudge();
    final b = __.pml().parser()("{ :c 3 }".reader()).toUpshot().value().fudge();
    final p = _.Hoist(Coord.make(null,0));
    final q = ctr.get(p,a);
    final r = ctr.put(p,b,a);

    same(r.value(),PArray([b]));
  }
}