package stx.lense;

using stx.Nano;
using stx.Test;
using stx.Log;
using stx.Lense;
using stx.Show;

class Test extends TestCase{
  static public function main(){
    __.test().run(
      [
        new LenseTest()
      ],[]
    );
  }
}
class LenseTest extends TestCase{
  final ctr : stx.lense.term.Pml<Atom>  = __.lense().Pml();
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
  function test_map(){
    final data = pI("{ :a 1 :c 1 }").flat_map(x -> switch(x){ case PGroup(Cons(x,_)) : Some(x); default : None; }).defv(PEmpty);
    final req  = 
    _.Rename(Coord.make('a'),Coord.make('b')).seq(_.Map(_.Constant(PValue(N(KLInt(3)))))).seq(
      _.Prune([Coord.make('c')])
    ).seq(
      _.Focus(Coord.make("b"))
    );
    $type(req);
    final res   = ctr.get(req,data);
    for(x in res){
      trace(x.toString());
    }
  }
}