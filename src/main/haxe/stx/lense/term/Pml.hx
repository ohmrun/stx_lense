package stx.lense.term;

using stx.Pico;
using stx.Nano;
using stx.Ds;
using stx.Show;
using eu.ohmrun.Pml;

class Pml<V> implements LenseApi<Coord,PExpr<V>> extends Clazz {
  static function search_all<V>(x:PExpr<V>,p:Cluster<Coord>){
    return switch(x){
      case PLabel(name)     : None;
      case PApply(name)     : None;
      case PGroup(list)     : Some(PGroup(
        list.imap(
          (i,v) -> p.any(
            (coord) -> switch(coord){
              case CoField(key,idx) : false;
              case CoIndex(idx)     : idx == i;
            }
          ).if_else(
            () -> Some(v),
            () -> None
          )
        ).map_filter(
          (x)  -> x
        )
      ));
      case PArray(array)    : Some(PArray(
        array.imap(
          (i,v) -> p.any(
            (coord) -> switch(coord){
              case CoField(key,idx) : false;
              case CoIndex(idx)     : idx == i;
            }
          ).if_else(
            () -> Some(v),
            () -> None
          )
        ).map_filter(
          (x)  -> x
        )
      ));
      case PValue(value)  : None;
      case PEmpty         : None;
      case PAssoc(map)    : Some(PAssoc(
        map.imap(
          (i,v) -> p.any(
            (coord) -> switch(coord){
              case CoField(key,idx) : 
                v.fst().get_label().fold(
                  ok -> (key == ok).if_else(
                    () -> idx == null ? true : idx == i,
                    () -> false
                  ),
                  () -> false
                );
              case CoIndex(idx)     : idx == i;
            }
          ).if_else(
            () -> Some(v),
            () -> None
          )
        ).map_filter(
          (x)  -> x
        )
      ));
      case PSet(arr) : Some(PSet(
        arr.imap(
          (i,v) -> p.any(
            (coord) -> switch(coord){
              case CoField(key,idx) : false;
              case CoIndex(idx)     : idx == i;
            }
          ).if_else(
            () -> Some(v),
            () -> None
          )
        ).map_filter(
          (x)  -> x
        )
      ));
    }
  }
  public function access(k:Coord,v:PExpr<V>){
    return v.access(k);
  }
  //public function concat(l,r)
  public function put(self:LExpr<Coord,PExpr<V>>,a:PExpr<V>,c:PExpr<V>):Upshot<PExpr<V>,LenseFailure>{
    return switch(self){
      case LsId                       : __.accept(c);
      case LsConstant(value,_default) : switch(c){
        case PEmpty : __.accept(_default);
        default     : __.accept(c);
      }
      case LsHoist(k)                 : switch(k){
        case CoField(key,null) : __.accept(PAssoc([tuple2(PLabel(key),a)]));
        case CoField(key,idx)  : __.accept(PAssoc(
          Iter.range(0,idx-2).lfold(
            (next:Int,memo:Cluster<Tup2<PExpr<V>,PExpr<V>>>) -> {
              return memo.cons(tuple2(PExpr.lift(PEmpty),PExpr.lift(PEmpty)));
            },
            [].imm().cons(tuple2(PLabel(key),a))
          )
        ));
        case CoIndex(idx)      : __.accept(PArray(Iter.range(0,idx-2).toCluster().map(_ -> PEmpty).snoc(a)));
      }
      case LsPlunge(k)            : this.access(k,a).resolve(f -> f.of(E_Lense('no value at $k on $a')));
      case LsXFork(pc,pa,lhs,rhs) : 
        final aI = search_all(a,pa).resolve(f -> f.of(E_Lense("no value")));
        final cI = search_all(c,pc).resolve(f -> f.of(E_Lense("no value")));
        return aI.zip(cI).flat_map(
          __.decouple((aII,cII) -> {
            return put(lhs,aII,cII).zip(put(rhs,aII,cII)).flat_map(
              __.decouple((l:PExpr<V>,r:PExpr<V>) -> switch([l,r]){
                case [PGroup(listI),PGroup(listII)]   : __.accept(PGroup(listI.concat(listII)));
                case [PArray(arrayI),PArray(arrayII)] : __.accept(PArray(arrayI.concat(arrayII)));
                case [PAssoc(mapI),PAssoc(mapII)]     : __.accept(PAssoc(mapI.concat(mapII)));
                case [PSet(setI),PSet(setII)]         : __.accept(PSet(setI.concat(setII)));
                default                               : __.reject(__.fault().of(E_Lense('can\'t merge $l and $r')));
              }
            ));
          })
        );
      case LsMap(p)   :
        final a_index = a.index();
        Upshot.bind_fold(
          a_index,
          (next:Coord,memo:Cluster<Tup2<Coord,PExpr<V>>>) ->{
            return a.access(next).zip(c.access(next))
                    .resolve(f -> f.of(E_Lense("no value"))).flat_map(
                      __.decouple(
                        (a,c) -> put(p,a,c).map(tuple2.bind(next))
                      )
                    ).map(
                      memo.snoc
                    );
          },
          [].imm()
        ).flat_map(
          (xs) -> {
            return switch(a){
              case PGroup(list)   : __.accept(PGroup(xs.map(x -> x.snd()).toLinkedList()));
              case PArray(array)  : __.accept(PArray(xs.map(x -> x.snd())));
              case PAssoc(map)    : 
                Upshot.bind_fold(
                  xs,
                  (next:Tup2<Coord,PExpr<V>>,memo:Cluster<Tup2<PExpr<V>,PExpr<V>>>) -> {
                    return next.fst().field.fold(
                      fld -> c.access(next.fst()).fold(
                        ok -> __.accept(tuple2(PLabel(fld),ok)),
                        () -> __.reject(f->f.of(E_Lense('no value at ${next.fst()}')))
                      ).map(memo.snoc),
                      () -> __.reject(f->f.of(E_Lense('no value at ${next.fst()}')))
                    );
                  },
                  [].imm()
                ).map(PAssoc);
              case PSet(arr)      : __.accept(PArray(xs.map(x -> x.snd())));
              default             : __.reject(f -> f.of(E_Lense('abstract view $a is a leaf')));
            }
          }
        );
      case LsSequence(l,r) : get(l,c).flat_map(
        cI -> put(r,a,cI).flat_map(
          aI -> put(l,aI,c)
        )
      );
    }
  }
  public function get(self:LExpr<Coord,PExpr<V>>,c:PExpr<V>):Upshot<PExpr<V>,LenseFailure>{
    trace(__.show(self));
    trace(__.show(c));
    return switch(self){
      case LsId                       : __.accept(c);
      case LsConstant(value,_default) : __.accept(value); 
      case LsHoist(k)                 : this.access(k,c).resolve(f -> f.of(E_Lense('no value at $k on $c')));
      case LsPlunge(k)                : 
        switch(k){
          case CoField(key,null) : __.accept(PAssoc([tuple2(PLabel(key),c)]));
          case CoField(key,idx)  : 
            trace('idx');
            __.accept(PAssoc(
              Iter.range(0,__.tracer()(idx-2)).lfold(
                (next,memo:Cluster<Tup2<PExpr<V>,PExpr<V>>>) -> {
                  trace('ZSsas');
                  return memo.cons(tuple2(PExpr.lift(PEmpty),PExpr.lift(PEmpty)));
                },
                [].imm().cons(tuple2(PLabel(key),c))
              )
            ));
          
            case CoIndex(idx)      : 
            __.accept(PArray(Iter.range(0,idx-2).toCluster().map(_ -> PEmpty).snoc(c)));
        };
      case LsXFork(pc,pa,lhs,rhs) : 
        final cI = search_all(c,pc).resolve(f -> f.of(E_Lense("no value")));
        for(v in cI){
          trace(__.show(v));
        }
        return cI.flat_map(
          cII -> {
            trace('${__.show(lhs)} ${__.show(cII)} ${__.show(rhs)} ${__.show(cII)}');
            return get(lhs,cII).flat_map(
              function(x:PExpr<V>){
                final not_in_c        = c.refine(
                  (key,val) -> switch(key){
                    case Left(x)  : pc.all(z -> z != x);
                    default       : false;
                  }
                );
                return get(rhs,not_in_c).map(__.couple.bind(x));
              }  
            ).flat_map(
              __.decouple(
                (l:PExpr<V>,r:PExpr<V>) -> {
                  trace('$l ||| $r');
                  return switch([l,r]){
                    case [PGroup(listI),PGroup(listII)]   : __.accept(PGroup(listI.concat(listII)));
                    case [PArray(arrayI),PArray(arrayII)] : __.accept(PArray(arrayI.concat(arrayII)));
                    case [PAssoc(mapI),PAssoc(mapII)]     : __.accept(PAssoc(mapI.concat(mapII)));
                    case [PSet(setI),PSet(setII)]         : __.accept(PSet(setI.concat(setII)));
                    default                               : __.reject(__.fault().of(E_Lense('can\'t merge $l and $r')));
                  }
                }
            ));
          }
        );
      case LsMap(p) :
        Upshot.bind_fold(
          c.index(),
          (next:Coord,memo:Cluster<Tup2<Coord,PExpr<V>>>) -> {
            return access(next,c).resolve(f -> f.of(E_Lense('no $next at $c'))).flat_map(
              ok -> get(p,ok).map(tuple2.bind(next)).map(memo.snoc)
            );
          },
          [].imm()
        ).flat_map(
          (xs) -> switch(c){
            case PGroup(list)   : __.accept(PGroup(xs.map(x -> x.snd()).toLinkedList()));
            case PArray(array)  : __.accept(PArray(xs.map(x -> x.snd())));
            case PAssoc(map)    : 
              Upshot.bind_fold(
                xs,
                (next:Tup2<Coord,PExpr<V>>,memo:Cluster<Tup2<PExpr<V>,PExpr<V>>>) -> {
                  return next.fst().field.fold(
                    fld -> c.access(next.fst()).fold(
                      ok -> __.accept(tuple2(PLabel(fld),ok)),
                      () -> __.reject(f->f.of(E_Lense('no value at ${next.fst()}')))
                    ).map(memo.snoc),
                    () -> __.reject(f->f.of(E_Lense('no value at ${next.fst()}')))
                  );
                },
                [].imm()
              ).map(PAssoc);
            case PSet(arr)      :__.accept(PArray(xs.map(x -> x.snd())));
            default             : __.reject(f -> f.of(E_Lense('concrete view $c is a leaf')));
          }
        );
      case LsSequence(l,r) : 
        get(l,c).flat_map(
          cI -> get(r,cI)
        );
    }
  }  
}