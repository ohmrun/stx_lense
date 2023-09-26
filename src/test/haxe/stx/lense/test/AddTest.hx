package stx.lense.test;

final ctr : stx.lense.term.Pml<Atom>  = __.lense().Pml(__.assert().Comparable().pml().Atom);
final _   : LExprCtr                  = __.lense().LExpr;

class AddTest extends TestCase{
  // public function test_add_to_array(){
  //   final a = PArray([PValue(N(NInt(1)))]);
  //   final b = PValue(N(NInt(2)));
  //   final x = _.Add(Coord.make(null,null),b);
  //   final p = ctr.get(x,a);
  //   final r = PArray([PValue(N(NInt(1))),PValue(N(NInt(2)))]);
  //   same(p.fudge(),r);
  // }
  // public function test_add_to_group(){
  //   final a = PGroup(Cons(PValue(N(NInt(1))),Nil));
  //   final b = PValue(N(NInt(2)));
  //   final x = _.Add(Coord.make(null,null),b);
  //   final p = ctr.get(x,a);
  //   final r = PGroup(
  //     Cons(
  //       PValue(N(NInt(1))),
  //       Cons(
  //         PValue(N(NInt(2))),
  //         Nil
  //       )
  //     )
  //   );
  //   same(r,p.fudge());
  // }
  // public function test_replace_to_assoc(){
  //   final a = PAssoc(
  //     [
  //       tuple2(
  //         PLabel('hello'),
  //         PValue(Str("world"))
  //       )
  //     ]
  //   );
  //   final b = PGroup(Cons(PLabel('hello'),Cons(PValue(Str('www')),Nil)));
  //   final x = _.Add(Coord.make(null,null),b);
  //   final p = ctr.get(x,a);
  //   trace(p.fudge());
  // }
  // public function test_add_to_assoc(){
  //   final a = PAssoc(
  //     [
  //       tuple2(
  //         PLabel('hello'),
  //         PValue(Str("world"))
  //       )
  //     ]
  //   );
  //   final b = PGroup(Cons(PLabel('something'),Cons(PValue(Str('else')),Nil)));
  //   final x = _.Add(Coord.make(null,null),b);
  //   final p = ctr.get(x,a);
  //   trace(p.fudge());
  // }
}