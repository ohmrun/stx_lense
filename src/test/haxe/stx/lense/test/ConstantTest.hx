package stx.lense.test;

final ctr : stx.lense.term.Pml<Atom>  = __.lense().Pml(__.assert().Comparable().pml().Atom);
final _   : LExprCtr                  = __.lense().LExpr;

class ConstantTest extends TestCase{
  public function test(){
    final a = __.pml().parser()("{ :a 1 }".reader()).toUpshot().value().fudge();
    final b = __.pml().parser()("{ :b 2 }".reader()).toUpshot().value().fudge();
    final c = __.pml().parser()("{ :c 3 }".reader()).toUpshot().value().fudge();
    final d = _.Constant(a);
    final e = ctr.put(d,b,c);
    final f = ctr.get(d,b);
    same(e.value(),c);
    // trace(f.value());
    // trace(b);
    same(f.value(),a);
  }
}