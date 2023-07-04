package stx.lense.test;

final ctr : stx.lense.term.Pml<Atom>  = __.lense().Pml(__.assert().Comparable().pml().Atom);

class OpsTest extends TestCase{
  // public function test_adjoin(){
  //   final l = PArray([PValue(N(KLInt(1))),PValue(N(KLInt(2))),PValue(N(KLInt(3)))]);
  //   final r = PArray([PValue(N(KLInt(4))),PValue(N(KLInt(5))),PValue(N(KLInt(6)))]);
  //   final b = ctr.adjoin(l,r);
  //   trace(b.fudge().toString());
  //   final c = ctr.concat(l,r);
  //   trace(c.fudge().toString());
  // }
  // public function test_concat_map(){
  //   final l = PAssoc(
  //     [
  //       tuple2(PLabel("a"),PValue(N(KLInt(1)))),
  //       tuple2(PLabel("b"),PValue(N(KLInt(2)))),
  //       tuple2(PLabel("c"),PValue(N(KLInt(3))))
  //     ]);
  //   final r = PAssoc(
  //     [
  //       tuple2(PLabel("d"),PValue(N(KLInt(4)))),
  //       tuple2(PLabel("e"),PValue(N(KLInt(5)))),
  //       tuple2(PLabel("f"),PValue(N(KLInt(6))))
  //     ]
  //   );
    
  //   final c = ctr.concat(l,r);
  //   trace(c.fudge().toString());
  // }
  public function test_adjoin_map(){
    final l = PAssoc(
      [
        tuple2(PLabel("a"),PValue(N(KLInt(1)))),
        tuple2(PLabel("b"),PValue(N(KLInt(2)))),
        tuple2(PLabel("c"),PValue(N(KLInt(3))))
      ]);
    final r = PAssoc(
      [
        tuple2(PLabel("a"),PValue(N(KLInt(4)))),
        tuple2(PLabel("b"),PValue(N(KLInt(5)))),
        tuple2(PLabel("c"),PValue(N(KLInt(6))))
      ]
    );
    
    final c = ctr.adjoin(l,r);
    trace(c.fudge().toString());
  }
}