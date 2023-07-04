package stx.lense;

using stx.Nano;
using stx.Test;
using stx.Log;
using stx.Lense;
using stx.Show;
using stx.Assert;
using eu.ohmrun.Pml;

import stx.lense.test.*;

class Test extends TestCase{
  static public function main(){
    __.test().run(
      [
        //new ConstantTest(),
        //new LenseTest(),
        //new HoistTest(),
        //new SeqTest(),
        //new CopyTest(),
        //new OpsTest(),
        //new MapTest(),
        new MergeTest()
      ],[]
    );
  }
}
class LenseTest extends TestCase{
  final ctr : stx.lense.term.Pml<Atom>  = __.lense().Pml(__.assert().Comparable().pml().Atom);
  final _   : LExprCtr                  = __.lense().LExpr;
  
  function p(name){
    return pI(__.resource(name).string());
  }
  function pI(data:String){
    return __.pml().parser()(data.reader()).toUpshot().fudge();
  }
  // public function test(){
  //   final data = __.pml().parser()(__.resource("dataI").string().reader()).toUpshot().fudge();
  //   for(x in data){
  //     final a = 
  //       _.Hoist(Coord.make()).seq(
  //         _.Hoist(Coord.make())
  //       ).seq(_.Plunge(CoField('f')))
  //        .seq(_.Rename(CoField('f'),CoField('g')));

  //     final b = ctr.get(a,x);
  //     for(x in b){
  //     //  trace(x);
  //     }
  //   }
  // }
  // function test_rename(){
  //   final data = p('rename');
  //   for(x in data){
  //     final req = _.Hoist(Coord.make()).seq(_.Rename(Coord.make("a"),Coord.make("b")));
  //     final res = ctr.get(req,x);
  //     for(x in res){
  //       trace(x);
  //     }
  //   }
  // }
  // function test_xfork(){
  //   final data = pI("{ :a 1 :c 1 }").flat_map(x -> switch(x){ case PGroup(Cons(x,_)) : Some(x); default : None; }).defv(PEmpty);
  //   final req  = _.Rename(Coord.make('a'),Coord.make('b'));
  //   final res   = ctr.get(req,data);
  //   for(x in res){
  //     trace((x:PExpr<Atom>).toString());
  //   }
  //   // final hoist = _.Hoist(Coord.make('a'));
  //   // final res   = ctr.get(hoist,data);
  //   // trace(res);
  // }
  // function test_map(){
  //   final data = pI("{ :a 1 :c 1 }").flat_map(x -> switch(x){ case PGroup(Cons(x,_)) : Some(x); default : None; }).defv(PEmpty);
  //   final req  = 
  //   _.Rename(Coord.make('a'),Coord.make('b')).seq(_.Map(_.Constant(PValue(N(KLInt(3)))))).seq(
  //     _.Prune([Coord.make('c')])
  //   ).seq(
  //     _.Focus(Coord.make("b"))
  //   ).seq(
  //     _.Plunge(Coord.make("b"))
  //   ).seq(
  //     _.Add(Coord.make('teet'),PValue(N(KLInt(4))))
  //   );
  //   $type(req);
  //   final res   = ctr.get(req,data);
  //   trace(res);
  //   for(x in res){
  //     trace(x.toString());
  //   }
  // }
  function test_put_hoist(){
    final data = pI("{ :a 1 }").flat_map(x -> x.head()).defv(PEmpty);
    final req  = _.Hoist(Coord.make("c"));
    final res  = ctr.put(req,pI("{ :b 2}").flat_map(x -> x.head()).defv(PEmpty),data);
    for(x in res){
      final tst = pI("{ :c { :b 2 } }").flat_map(x -> x.head()).fudge();
      final eq  = __.assert().Eq().pml().PExpr(__.assert().Eq().pml().Atom);
      //trace(tst);
      //trace(x);
      is_true(eq.comply(x,tst).is_ok());
    }
  }
  // function test_put_plunge(){
  //   final data = pI("{ :a 1 }").flat_map(x -> x.head()).defv(PEmpty);
  //   final req  = _.Plunge(Coord.make("c"));
  // }
  function test_reverse(){
    final data  = pI("(a b c d e f)").flat_map(x -> x.head()).defv(PEmpty);
    // final req   = data.members().map(
    //   x -> {
    //     trace(x);
    //     return __.couple(_.Constant(data).seq(_.Hoist(x.fst())),x);
    //   }
    // ).lfold(
    //   (next:Couple<LExpr<Coord,PExpr<Atom>>,Tup2<Coord,PExpr<Atom>>>,memo:{ step : Int, data : LExpr<Coord,PExpr<Atom>> }) -> {
    //     final coord = Coord.make(memo.step);
    //     final then  = next.fst().seq(LsPlunge(coord));
    //     return { 
    //       data : switch(memo.data){
    //               case LsId : then;
    //               case data  : _.Fork([coord],then,data);
    //             },
    //       step : memo.step + 1 
    //     };
    //   },
    //   { step : 0, data : LsId } 
    // );
    // final req = _.XFork([Coord.make()],[],_.Plunge(ctr.unique()),_.Id());
    // final res = ctr.get(req,data);
    // trace(__.show(res));
  }
  // function test_add(){
  //   final data  = PAssoc([tuple2(PLabel("first"),PValue(Str("hej")))]);
  //   final req   = _.Add(Coord.make('teet'),PValue(N(KLInt(4))));
  //   final res   = ctr.get(req,data);
  //   for(x in res){
  //     trace(x.toString());
  //   }
  // }
}