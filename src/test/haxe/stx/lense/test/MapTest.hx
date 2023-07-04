package stx.lense.test;

final ctr : stx.lense.term.Pml<Atom>  = __.lense().Pml(__.assert().Comparable().pml().Atom);
final _   : LExprCtr                  = __.lense().LExpr;

class MapTest extends TestCase{
  public function test(){
    final c     = __.pml().parser()("{:a 1 :c 2}".reader()).fudge().head().fudge();
    final a     = __.pml().parser()("{:c 5}".reader()).fudge().head().fudge();
    final p     = _.Add(Coord.make("c"),PValue(N(KLInt(3))));
    // final l  = _.Constant(PValue(N(KLInt(99))),null).seq(LsPlunge(Coord.make("z")));
    // final g  = ctr.get(l,PEmpty);
    // trace(g);
    final x = ctr.get(p,c).value();
    final y = ctr.put(p,a,c).value();
    
    //trace(y.toString());
    //final b = __.pml().parser()("{:a 5}".reader()).fudge().head().fudge();
    //final y = ctr.put(p,b,a).fudge();

    trace(x.toString());
    trace(y.toString());
    
  }   
  // public function testI(){
  //   final a = __.pml().parser()("{:a 1 :b 2 :c 3}".reader()).fudge().head().fudge();
  //   final q = _.Map(_.Plunge(Coord.make("x")));
  //   final r = ct
  // }
}