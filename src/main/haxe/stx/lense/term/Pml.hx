package stx.lense.term;

using stx.Pico;
using stx.Nano;
using stx.Ds;
using stx.Show;
using eu.ohmrun.Pml;
using stx.lense.term.Pml;

private typedef Tup2OfPExpr<T> = Tup2<PExpr<T>, PExpr<T>>;
private typedef CplOfTup2OfP<T> = Couple<Tup2OfPExpr<T>, Tup2OfPExpr<T>>;

@:using(stx.lense.term.Pml.PmlLift)
class Pml<V> implements LenseApi<Coord, PExpr<V>> {
	public final V:stx.assert.pml.comparable.PExpr<V>;

	public function new(inner) {
		this.V = new stx.assert.pml.comparable.PExpr(inner);
	}

	public function select(self:PExpr<V>, p:Cluster<Coord>) {
		trace('select ${__.show(p)} in ${__.show(self)}');

		return Upshot.bind_fold(p, (next:Coord, memo:Cluster<PExpr<V>>) -> {
			return access(next, self).resolve(f -> f.of(E_Lense('no $next on $self'))).map(memo.snoc);
		}, [].imm()).map((rest) -> switch (self) {
			case PGroup(list): Some(PGroup(LinkedList.fromCluster(rest)));
			case PArray(array): Some(PArray(rest));
			case PSet(set): Some(PSet(rest));
			default: None;
		});
	}

	public function access(k:Coord, v:PExpr<V>) {
		return v.access(k);
	}

	public function labels(v:PExpr<V>) {
		return v.labels();
	}

	public function put(self:LExpr<Coord, PExpr<V>>, a:PExpr<V>, c:PExpr<V>):Upshot<PExpr<V>, LenseFailure> {
		return switch (self) {
			case LsId: __.accept(a);
			case LsConstant(value, _default): switch (c) {
					case PEmpty: __.accept(_default);
					default: __.accept(c);
				}
			case LsHoist(k): switch (k) {
					case CoField(key, null): __.accept(PAssoc([tuple2(PLabel(key), a)]));
					case CoField(key, idx): __.accept(PAssoc(Iter.range(0, idx - 2).lfold((next:Int, memo:Cluster<Tup2<PExpr<V>, PExpr<V>>>) -> {
							return memo.cons(tuple2(PExpr.lift(PEmpty), PExpr.lift(PEmpty)));
						}, [].imm().cons(tuple2(PLabel(key), a)))));
					case CoIndex(idx): __.accept(PArray([a]));
				}
			case LsPlunge(k): this.access(k, a).resolve(f -> f.of(E_Lense('no value at $k on $a')));
			case LsXFork(pc, pa, lhs, rhs):
				final aI = select(a, pa).flat_map(x -> x.resolve(f -> f.of(E_Lense("no value"))));
				final cI = select(c, pc).flat_map(x -> x.resolve(f -> f.of(E_Lense("no value"))));
				return aI.zip(cI).flat_map(__.decouple((aII, cII) -> {
					return put(lhs, aII, cII).zip(put(rhs, aII, cII)).flat_map(__.decouple(function(l:PExpr<V>, r:PExpr<V>):Upshot<PExpr<V>, LenseFailure> {
						return switch ([l, r]) {
							case [PGroup(listI), PGroup(listII)]: __.accept(PGroup(listI.concat(listII)));
							case [PArray(arrayI), PArray(arrayII)]: __.accept(PArray(arrayI.concat(arrayII)));
							case [PAssoc(mapI), PAssoc(mapII)]: __.accept(PAssoc(mapI.concat(mapII)));
							case [PSet(setI), PSet(setII)]: __.accept(PSet(setI.concat(setII)));
							default: __.reject(__.fault().of(new stx.fail.LenseFailure(E_Lense('can\'t merge $l and $r'))));
						}
					}));
				}));
			case LsMap(p):
				final a_labels = labels(a);
				Upshot.bind_fold(a_labels, (next:Coord, memo:Cluster<Tup2<Coord, PExpr<V>>>) -> {
					return a.access(next)
						.zip(c.access(next))
						.resolve(f -> f.of(E_Lense("no value")))
						.flat_map(__.decouple((a, c) -> put(p, a, c).map(tuple2.bind(next))))
						.map(memo.snoc);
				}, [].imm()).flat_map((xs) -> {
					return switch (a) {
						case PGroup(list): __.accept(PGroup(xs.map(x -> x.snd()).toLinkedList()));
						case PArray(array): __.accept(PArray(xs.map(x -> x.snd())));
						case PAssoc(map):
							Upshot.bind_fold(xs, (next:Tup2<Coord, PExpr<V>>, memo:Cluster<Tup2<PExpr<V>, PExpr<V>>>) -> {
								return next.fst()
									.field.fold(fld -> c.access(next.fst())
									.fold(ok -> __.accept(tuple2(PLabel(fld), next.snd())), () -> __.reject(f -> f.of(E_Lense('no value at ${next.fst()}'))))
									.map(memo.snoc),
									() -> __.reject(f -> f.of(E_Lense('no value at ${next.fst()}'))));
							}, [].imm()).map(PAssoc);
						case PSet(arr): __.accept(PArray(xs.map(x -> x.snd())));
						default: __.reject(f -> f.of(E_Lense('abstract view $a is a leaf')));
					}
				});
			case LsSequence(l, r): get(l, c).flat_map(cI -> put(r, a, cI).flat_map(aI -> put(l, aI, c)));
			case LsCopy(m, n):
				a.imod(
					(i, e) -> switch(e){
						case PGroup(Cons(PLabel(x),Cons(y,Nil))) if (a.is_assoc()) : 
							Coord.make(x,i).equals_loose(n).if_else(
								() -> __.accept(Some(e)),
								() -> __.accept(None)
							);
						case x : 
							Coord.make(null,i).equals_loose(n).if_else(
								() -> __.accept(Some(e)),
								() -> __.accept(None)
							);
					}
				).map(
					opt -> opt.fold(
						x 	-> x,
						() 	-> PEmpty
					)
				).errate(
					E_Lense_Pml
				);
			case LsMerge(m, n):
				final c_m = this.access(m, c).resolve(f -> f.of(E_Lense('no value $m on $c')));
				final c_n = this.access(n, c).resolve(f -> f.of(E_Lense('no value $n on $c')));
				c_m.zip(c_n).flat_map(__.decouple((cm:PExpr<V>, cn:PExpr<V>) -> {
					return V.eq()
						.comply(cm, cn)
						.is_ok()
						.if_else(
              () -> this.access(m, a)
							  .resolve(f -> f.of(E_Lense('no value $m on $a')))
							  .flat_map(am -> 
                  this.upsert(
                    a,
                    PGroup(Cons(PLabel(n.field.fudge()),Cons(am,Nil))),
										m
									)
                ),
              () -> this.insert(a, cn)
            );
        }));
			  case LsCCond(cond,l,r) :
			      V.eq().comply(c,cond).is_ok().if_else(
			        () -> put(l,a,c),
			        () -> put(r,a,c)
			      );
			  case LsACond(cond,acond,l,r) :
			    a.any_layer(p -> V.eq().comply(acond,p).is_ok()).zip(
			      c.any_layer(p -> V.eq().comply(cond,p).is_ok())
			    ).errate(E_Lense_Pml).flat_map(
			      __.decouple(
			        function (x:Bool,y:Bool):Upshot<PExpr<V>,LenseFailure> {(return switch([x,y]){
			          case [true,true]    : put(l,a,c);
			          case [true,false]   : put(l,a,PEmpty);
			          case [false,false]  : put(r,a,c);
			          case [false,true]   : put(r,a,PEmpty);
			        });}
			      )
			    );
		}
	}

	public function get(self:LExpr<Coord, PExpr<V>>, c:PExpr<V>):Upshot<PExpr<V>, LenseFailure> {
		final ___self = __.show(self);
		final __c     = __.show(c);
		trace('$___self : $__c');
		return __.tracer()(switch(self){
			case LsId                       : __.accept(c);
		  case LsConstant(value,_default) : __.accept(value);
		  case LsHoist(k)                 :
		    this.access(k,c).resolve(f -> f.of(E_Lense('no value at $k on $c')));
		  case LsPlunge(k)                :
		    switch(k){
		      case CoField(key,null) : __.accept(PAssoc([tuple2(PLabel(key),c)]));
		      case CoField(key,idx)  :
		        trace('idx');
		        __.accept(PAssoc(
		          Iter.range(0,__.tracer()(idx-2)).lfold(
		            (next,memo:Cluster<Tup2<PExpr<V>,PExpr<V>>>) -> {
		              //trace('ZSsas');
		              return memo.cons(tuple2(PExpr.lift(PEmpty),PExpr.lift(PEmpty)));
		            },
		            [].imm().cons(tuple2(PLabel(key),c))
		          )
		        ));

		        case CoIndex(idx)      :
		        __.accept(PArray([c]));
		    };
		  case LsXFork(pc,pa,lhs,rhs) :
		    final cI = select(c,pc).flat_map(x -> x.resolve(f -> f.of(E_Lense('no indeces $pc found in $c'))));
		    return cI.flat_map(
		      cII -> {
		        trace('C = ${__.show(lhs)} ${__.show(cII)} !C ==  ${__.show(rhs)} ${__.show(cII)}');
		        return get(lhs,cII).flat_map(
		          function(x:PExpr<V>){
		            final not_in_c        = c.refine(
		              (key,val) -> __.accept(!pc.any(
										z -> {
											trace('$z $x ${z.equals_loose(key)}');
											return z.equals_loose(key);
										}
		              ))
								).errate(E_Lense_Pml);
		            trace('${__.show(c)} :: ${__.show(not_in_c)}');
		            return (not_in_c).flat_map(x -> get(rhs,x)).map(__.couple.bind(x));
		          }
		        ).flat_map(
		          __.decouple(
		            function (l:PExpr<V>,r:PExpr<V>):Upshot<PExpr<V>,LenseFailure>{
		              trace('$l ||| $r');
		              return this.concat(l,r);
		            }
		        ));
		      }
		    );
		  case LsMap(p) :
		    trace('map');
		    Upshot.bind_fold(
		      labels(c),
		      (next:Coord,memo:Cluster<Tup2<Coord,PExpr<V>>>) -> {
		        return access(next,c).resolve(f -> f.of(E_Lense('no $next at $c'))).flat_map(
		          ok -> {
		            trace(ok);
		            trace('$next $p');
		            return get(p,ok).map(tuple2.bind(next)).map(memo.snoc);
		          }
		        );
		      },
		      [].imm()
		    ).flat_map(
		      (xs) -> {
		        trace(xs);
		        final res : Upshot<PExpr<V>,LenseFailure> =  switch(c){
		          case PGroup(list)   : __.accept(PGroup(xs.map(x -> x.snd()).toLinkedList()));
		          case PArray(array)  : __.accept(PArray(xs.map(x -> x.snd())));
		          case PAssoc(map)    :
		            Upshot.bind_fold(
		              xs,
		              (next:Tup2<Coord,PExpr<V>>,memo:Cluster<Tup2<PExpr<V>,PExpr<V>>>) -> {
		                return next.fst().field.fold(
		                  fld -> c.access(next.fst()).fold(
		                    ok -> __.accept(tuple2(PLabel(fld),next.snd())),
		                    () -> __.reject(f->f.of(E_Lense('no value at ${next.fst()}')))
		                  ).map(memo.snoc),
		                  () -> __.reject(f->f.of(E_Lense('no value at ${next.fst()}')))
		                );
		              },
		              [].imm()
		            ).map(PAssoc);
		          case PSet(arr)      : __.accept(PArray(xs.map(x -> x.snd())));
		          default             : __.reject(f -> f.of(E_Lense('concrete view $c is a leaf')));
		        }
		        for(x in res){
		          trace(x.toString());
		        }
		        return res;
		      }
		    );
		  case LsSequence(l,r) :
		    get(l,c).flat_map(
		      cI -> get(r,cI)
		    );
		  case LsCopy(m,n)     :
		    final m_value = c.access(m).resolve(f -> f.of(E_Lense('no $m in $c')));
		    //$type(c);
		    final c_next  = m_value.flat_map(
		      (m_value:PExpr<V>) -> {
		        return this.upsert(
							c,							
							m_value,
							n
						);
		      }
		    );
		    c_next;
		  case LsMerge(m,n)     :
		    c.refine(
		      (x,y) -> __.accept(x.equals_loose(n))
				).errate(E_Lense_Pml);
		  case LsCCond(cond,l,r) :
		    V.eq().comply(c,cond).is_ok().if_else(
		      () -> {
		        trace("true");
		        return get(l,c);
		      },
		      () -> {
		        trace("false");
		        return get(r,c);
		      }
		    );
		  case LsACond(cond,acond,l,r) :
		    V.eq().comply(c,cond).is_ok().if_else(
		      () -> get(l,c),
		      () -> get(r,c)
		    );
		});
	}

	/**
	 * Basically a lub.
	 * @param self 
	 * @param that 
	 * 
	 */
	public function adjoin(self:PExpr<V>, that:PExpr<V>):Upshot<PExpr<V>, LenseFailure> {
		function joiner(next:Couple<PExpr<V>, PExpr<V>>, memo:Cluster<PExpr<V>>) {
			return next.decouple(adjoin).map(memo.snoc);
		}
		return switch ([self, that]) {
			case [PAssoc(xs), PGroup(Cons(x, Cons(y, Nil)))]: __.accept(PAssoc(xs.snoc(tuple2(x, y))));

			case [x, null]: __.accept(x);
			case [null, x]: __.accept(x);

			case [x, PEmpty]: __.accept(x);
			case [PEmpty, x]: __.accept(x);

			case [PGroup(Nil), x]: __.accept(x);
			case [x, PGroup(Nil)]: __.accept(x);

			case [PGroup(listI), PGroup(listII)]:
				Upshot.bind_fold(listI.zip(listII), joiner, [].imm()).map(xs -> xs.toLinkedList()).map(PGroup);
			case [PGroup(arrayI), PArray(arrayII)]:
				Upshot.bind_fold(arrayI.zip(arrayII), joiner, [].imm()).map(xs -> xs.toLinkedList()).map(PGroup);
			case [PGroup(arrayI), PSet(arrayII)]:
				Upshot.bind_fold(arrayI.zip(arrayII), joiner, [].imm()).map(xs -> xs.toLinkedList()).map(PGroup);
			case [PSet(setI), PSet(setII)]:
				Upshot.bind_fold(setI.zip(setII), joiner, [].imm()).map(PSet);
			case [PSet(setI), PArray(arrayII)]:
				Upshot.bind_fold(setI.zip(arrayII), joiner, [].imm()).map(PSet);
			case [PSet(setI), PGroup(arrayII)]:
				Upshot.bind_fold(setI.zip(arrayII.toCluster()), joiner, [].imm()).map(PSet);
			case [PArray(arrayI), PGroup(arrayII)]:
				Upshot.bind_fold(arrayI.zip(arrayII.toCluster()), joiner, [].imm()).map(PArray);
			case [PArray(arrayI), PSet(arrayII)]:
				Upshot.bind_fold(arrayI.zip(arrayII), joiner, [].imm()).map(PArray);
			case [PArray(arrayI), PArray(arrayII)]:
				Upshot.bind_fold(arrayI.zip(arrayII.prj()), joiner, [].imm()).map(PArray);
			case [PAssoc(mapI), PAssoc(mapII)]:
				Upshot.bind_fold(mapI.zip(mapII), function(next:CplOfTup2OfP<V>, memo:Cluster<Tup2<PExpr<V>, PExpr<V>>>) {
					return next.decouple((l, r) -> switch ([l, r]) {
						case [tuple2(lI, rI), tuple2(lII, rII)]:
							adjoin(lI, lII).zip(adjoin(rI, rII));
					}).map(__.decouple(tuple2)).map(x -> memo.snoc((x)));
				}, [].imm()).map(PAssoc);
			default:
				__.reject(__.fault().of(stx.fail.PmlFailure.PmlFailureSum.E_Pml_CannotMix(self, that))).errate(E_Lense_Pml);
		}
	}
}

private class PmlLift {
	static public function concat<K, V>(self:Pml<V>, lhs:PExpr<V>, rhs:PExpr<V>) {
		final length = lhs.labels().length;
		// __.reject(f -> f.of(E_Parse('lhs is not a chain')));
		final signature = lhs.signature();
		final chain = switch (signature) {
			case PSigPrimate(_): None;
			case PSigCollect(_, _): Some(Left(Iter.range(0, length).map(_ -> PEmpty).toCluster()));
			case PSigCollate(_, _): Some(Right(Iter.range(0, length).map(_ -> tuple2(PEmpty, PEmpty)).toCluster()));
			case PSigOutline(_): Some(Right(Iter.range(0, length).map(_ -> tuple2(PEmpty, PEmpty)).toCluster()));
			case PSigBattery(_, _): Some(Left(Iter.range(0, length).map(_ -> PEmpty).toCluster()));
		}
		final rhsI = switch ([signature, rhs]) {
			case [PSigCollect(_, PCArray), PArray(arr)]:
				Some(PArray(chain.flat_map(x -> x.left()).fudge().concat(arr)));
			case [PSigCollect(_, PCSet), PSet(arr)]:
				Some(PSet(chain.flat_map(x -> x.left()).fudge().concat(arr)));
			case [PSigCollect(_, PCGroup), PGroup(arr)]:
				Some(PGroup(LinkedList.fromCluster(chain.flat_map(x -> x.left()).fudge()).concat(arr)));
			case [PSigCollate(_, _), PAssoc(cs)]:
				Some(PAssoc(chain.flat_map(x -> x.right()).fudge().concat(cs)));
			case [PSigOutline(_), PAssoc(cs)]:
				Some(PAssoc(chain.flat_map(x -> x.right()).fudge().concat(cs)));
			case [PSigBattery(_, PCArray), PArray(arr)]:
				Some(PArray(chain.flat_map(x -> x.left()).fudge().concat(arr)));
			case [PSigBattery(_, PCSet), PSet(arr)]:
				Some(PSet(chain.flat_map(x -> x.left()).fudge().concat(arr)));
			case [PSigBattery(_, PCGroup), PGroup(arr)]:
				Some(PGroup(LinkedList.fromCluster(chain.flat_map(x -> x.left()).fudge()).concat(arr)));
			default: None;
		}
		return self.adjoin(lhs, rhsI.defv(PEmpty));
	}
  static public function insert<K,V>(self:Pml<V>,lhs:PExpr<V>,rhs:PExpr<V>){
    return (switch(lhs.signature()){
      case PSigPrimate(_)                                   : 
        __.reject(f -> f.of(E_Lense('lhs not a chain I can insert to: $lhs')));
			case PSigCollect(_, PCArray) | PSigBattery(_,PCArray) : 
        __.accept(PArray([rhs]));
      case PSigCollect(_, PCSet)   | PSigBattery(_,PCSet)   : 
        __.accept(PSet([rhs]));
      case PSigCollect(_, PCGroup) | PSigBattery(_,PCGroup) : 
        __.accept(PGroup(Cons(rhs,Nil)));
      case PSigCollate(_,_) | PSigOutline(_)                :
        switch(rhs){
          case PGroup(Cons(x,Cons(y,Nil)))  : 
            __.accept(PAssoc([tuple2(x,y)]));
          default                           : 
          __.reject(f -> f.of(E_Lense('malformed item for entry into group$rhs')));
    }}).flat_map(
      x -> concat(self,lhs,x)
    );
  }
	static public function update<K,V>(self:PExpr<V>,replace_with:PExpr<V>,at:Coord){
		var done = false;
    return self.imod(
      function(int:Int,v:PExpr<V>):Upshot<Option<PExpr<V>>,PmlFailure>{
				return switch([at,v]){
					case [CoField(key,idx),PGroup(Cons(PLabel(x),Cons(y,Nil)))] if (self.is_assoc()) :
						if(idx == null || (int == idx && idx != null)){
							if(key == x){
								done = true;
								__.accept(Some(replace_with));
							}else{
								__.accept(Some(v));
							}
						}else{
							__.accept(Some(v));
						}
					case [CoIndex(i),v] if(i == int) :
						done == true;
						__.accept(Some(replace_with));
					default : 
						__.reject(f -> f.of(E_Pml('No update possible at $at')));
				}
      }
    ).flat_map(
			opt -> switch(done){
				case false : __.reject(f -> f.of('No coord $at found'));
				case true  : opt.fold(
					ok -> __.accept(ok),
					() -> __.reject(f -> f.of(E_Pml('update returned None')))
				);
			}
		).errate(E_Lense_Pml);
  }
  static public function upsert<K,V>(self:Pml<V>,lhs:PExpr<V>,rhs:PExpr<V>,at:Coord){
    final is_update = self.labels(lhs).any(
      label -> label.equals(at)
    );
    return is_update.if_else(
      () -> update(lhs,rhs,at),
      () -> insert(self,lhs,rhs)
    );
  }
}

