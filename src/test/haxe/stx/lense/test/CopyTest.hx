package stx.lense.test;

final ctr : stx.lense.term.Pml<Atom>  = __.lense().Pml(__.assert().Comparable().pml().Atom);
final _   : LExprCtr                  = __.lense().LExpr;

class CopyTest extends TestCase{
  public function test(){
    final c = __.pml().parser()("{:a (3,4,5) }".reader()).fudge().head().fudge();
    final a = __.pml().parser()("{:b 2}".reader()).fudge().head().fudge();
    final p = _.Copy(Coord.make("a"),Coord.make("c"));
    final x = ctr.get(p,c).value();
    final y = ctr.put(p,a,c).value();
    trace(x.toString());
    trace(y.toString());
  }   
}