package stx.lense;

final _   : LExprCtr                  = __.lense().LExpr;

class Reader{
  static function error(name,detail:Dynamic,?pos:Position):CTR<Fault,Refuse<LenseFailure>>{
    return (f) -> f.of(E_Lense('$name $detail'));
  }
  static function k_of(e:PExpr<Atom>){
    return switch(e){
      case PGroup(Cons(l,Cons(PValue(N(KLInt(n))),Nil))) : 
        switch(l){
          case PValue(Str(s)) | PLabel(s) : __.accept(Coord.make(s,n));
          default                         : __.reject(error('coord',e));
        }
      case PValue(Str(s)) : 
        __.accept(Coord.make(s));
      default : __.reject(error('coord',e));
    }
  }
  static function ks_of(e:PExpr<Atom>):Upshot<Cluster<Coord>,LenseFailure>{
    return switch(e){
      case PArray(arr)  :
        Upshot.bind_fold(
          arr,
          (next,memo:Cluster<Coord>) -> {
            return k_of(next).map(
              memo.snoc
            );
          },
          [].imm()
        );
      default : __.reject(error('coord',e));
    }
  }
  static public function apply(self:PExpr<Atom>,?rest:String->PExpr<Atom>->Upshot<LExpr<Coord,PExpr<Atom>>,LenseFailure>):Upshot<LExpr<Coord,PExpr<Atom>>,LenseFailure>{
    return switch(self){
      case PGroup(Cons(PApply(x),xs)) :
        switch(x){
          case 'id'     : __.accept(_.Id());
          case 'const'  : switch(xs){
            case Cons(v,Cons(d,Nil))  : 
              __.accept(_.Constant(v,d));
            default                   : 
              __.reject(f -> f.of(E_Lense('const $xs')));
          }
          case 'seq'    : switch(xs){
            case Cons(v,Cons(d,Nil)) : 
              apply(v,rest).flat_map(vI -> apply(d,rest).map((vII) -> _.Sequence(vI,vII)));
            default : 
              __.reject(error('apply',xs));
          }
          case 'hoist' : switch(xs){
            case Cons(x,Nil) : 
              k_of(x).map(_.Hoist);
            default : 
            __.reject(error('hoist',xs));
          }
          case 'plunge' : switch(xs){
            case Cons(x,Nil) : 
              k_of(x).map(_.Plunge);
            default : 
            __.reject(error('plunge',xs));
          }
          case 'xfork' : switch(xs){
            case (Cons(PArray(pc),Cons(PArray(pa),Cons(l,Cons(r,Nil))))) : 
              ks_of(PArray(pc)).zip(ks_of(PArray(pa))).flat_map(
                __.decouple(
                  (pc,pa) -> {
                    return apply(l,rest).zip(apply(r,rest)).map(
                      __.decouple(
                        (lhs,rhs) -> {
                          return _.XFork(pc,pa,lhs,rhs);
                        }
                      )
                    );
                  }
                )
              );
            default : __.reject(error('xfork',xs));
          }
          case 'map' : switch(xs){
            case Cons(x,Nil) : apply(x,rest).map(
              x -> _.Map(x)
            );
            default : __.reject(error('map',xs));
          }
          case 'copy' : switch(xs){
            case Cons(x,Cons(y,Nil)) : k_of(x).zip(k_of(y)).map(
              __.decouple(
                (x,y) -> _.Copy(x,y)
              )
            );
            default : __.reject(error('copy',xs));
          }
          case 'merge' : switch(xs){
            case Cons(x,Cons(y,Nil)) : k_of(x).zip(k_of(y)).map(
              __.decouple(
                (x,y) -> _.Merge(x,y)
              )
            );
            default : __.reject(error('merge',xs));
          }
          case 'ccond' : switch(xs){
            case Cons(c,Cons(_t,Cons(_f,Nil))) : 
              apply(_t,rest).zip(apply(_f,rest)).map(
                __.decouple(
                  (_t,_f) -> _.CCond(c,_t,_f)
                )
              );
            default : __.reject(error('ccond',xs));
          }
          case 'acond' : switch(xs){
            case Cons(cc,Cons(ac,Cons(_t,Cons(_f,Nil)))) : 
              apply(_t,rest).zip(apply(_f,rest)).map(
                __.decouple(
                  (_t,_f) -> _.ACond(cc,ac,_t,_f)
                )
              );
            default : __.reject(error('acond',xs));
          }
          case 'filter' : switch(xs){
            case Cons(ks,Cons(d,Nil)) : 
              ks_of(ks).map(x -> _.Filter(x,d));
            case Cons(ks,Nil)         : 
              ks_of(ks).map(x -> _.Filter(x));
            default : __.reject(error('filter',xs));
          }
          case 'focus' : switch(xs){
            case Cons(k,Cons(d,Nil)) : 
              k_of(k).map(x -> _.Focus(x,d));
            case Cons(k,Nil)         : 
              k_of(k).map(x -> _.Focus(x));
            default : __.reject(error('focus',xs));
          }
          case 'rename' : switch(xs){
            case Cons(x,Cons(y,Nil)) : k_of(x).zip(k_of(y)).map(
              __.decouple(
                (x,y) -> _.Rename(x,y)
              )
            );
            default : __.reject(error('rename',xs));
          }
          case x : __.option(rest).fold(
            ok -> rest(x,self),
            () -> __.reject(error(x,null))
          );
        }        
      case PGroup(xs) : 
          Upshot.bind_fold(
            xs,
            (next,memo) -> {
              return apply(next,rest).map(
                x -> _.Sequence(memo,x)
              );
            },
            _.Id()
          );
      default : __.reject(f -> f.of(E_Lense('reader')));
    }
  }
}