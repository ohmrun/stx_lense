package stx.lense.test;

final ctr : stx.lense.term.Pml<Atom>  = __.lense().Pml(__.assert().Comparable().pml().Atom);

class OpsTest extends TestCase{
  // public function test_adjoin(){
  //   final l = PArray([PValue(N(NInt(1))),PValue(N(NInt(2))),PValue(N(NInt(3)))]);
  //   final r = PArray([PValue(N(NInt(4))),PValue(N(NInt(5))),PValue(N(NInt(6)))]);
  //   final b = ctr.adjoin(l,r);
  //   trace(b.fudge().toString());
  //   final c = ctr.concat(l,r);
  //   trace(c.fudge().toString());
  // }
  // public function test_concat_map(){
  //   final l = PAssoc(
  //     [
  //       tuple2(PLabel("a"),PValue(N(NInt(1)))),
  //       tuple2(PLabel("b"),PValue(N(NInt(2)))),
  //       tuple2(PLabel("c"),PValue(N(NInt(3))))
  //     ]);
  //   final r = PAssoc(
  //     [
  //       tuple2(PLabel("d"),PValue(N(NInt(4)))),
  //       tuple2(PLabel("e"),PValue(N(NInt(5)))),
  //       tuple2(PLabel("f"),PValue(N(NInt(6))))
  //     ]
  //   );
    
  //   final c = ctr.concat(l,r);
  //   trace(c.fudge().toString());
  // }
  public function test_adjoin_map(){
    final l = PAssoc(
      [
        tuple2(PLabel("a"),PValue(N(NInt(1)))),
        tuple2(PLabel("b"),PValue(N(NInt(2)))),
        tuple2(PLabel("c"),PValue(N(NInt(3))))
      ]);
    final r = PAssoc(
      [
        tuple2(PLabel("a"),PValue(N(NInt(4)))),
        tuple2(PLabel("b"),PValue(N(NInt(5)))),
        tuple2(PLabel("c"),PValue(N(NInt(6))))
      ]
    );
    
    final c = ctr.adjoin(l,r);
    trace(c.fudge().toString());
  }
}