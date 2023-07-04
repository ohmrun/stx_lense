package stx.lense.test;

final ctr : stx.lense.term.Pml<Atom>  = __.lense().Pml(__.assert().Comparable().pml().Atom);
final _   : LExprCtr                  = __.lense().LExpr;

class SeqTest extends TestCase{
  public function test(){
    final a = __.pml().parser()("{:a 1}".reader()).fudge();
    final b = __.pml().parser()("{:b 2}".reader()).fudge();
    final p = _.Sequence(_.Hoist(Coord.make(null,0)),_.Hoist(Coord.make("a")));
    final x = ctr.get(p,a).value();
    final y = ctr.put(p,b,a).value();
    trace(x.toString());
    trace(y.toString());
  }   
}