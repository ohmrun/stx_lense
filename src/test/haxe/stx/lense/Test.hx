package stx.lense;

using stx.Nano;
using stx.Test;
using stx.Log;
using stx.Lense;

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
  public function test(){
    final ctr    = __.lense().Pml();
    final _      = __.lense().LExpr;

    final data = __.pml().parser()(__.resource("dataI").string().reader()).toUpshot().fudge();
    for(x in data){
      final a = 
        _.Hoist(Coord.make()).seq(
          _.Hoist(Coord.make())
        );

      final b = ctr.get(a,x);
      for(x in b){
        trace(x);
      }
    }
  }
}