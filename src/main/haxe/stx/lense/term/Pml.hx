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
	public final V:Comparable<PExpr<V>>;

	public function new(inner) {
		this.V = new stx.assert.pml.comparable.PExpr(inner);
	}

	public function select(self:PExpr<V>, p:Cluster<Coord>) {
		trace('select ${__.show(p)} in ${__.show(self)}');

		return Upshot.bind_fold(p,
			(next:Coord, memo:Cluster<PExpr<V>>) -> {
				return access(next, self)
					.resolve(f -> f.of(E_Lense('no $next on $self')))
					.map(memo.snoc);
			}, 
			[].imm()
		).map((rest) -> switch (self) {
			case PGroup(list) 	: Some(PGroup(LinkedList.fromCluster(rest)));
			case PArray(array)	: Some(PArray(rest));
			case PSet(set) 			: Some(PSet(rest));
			default 						: None;
		});
	}

	public function access(k:Coord, v:PExpr<V>) {
		return v.access(k);
	}

	public function labels(v:PExpr<V>) {
		return v.labels();
	}

	public function put(self:LExpr<Coord, PExpr<V>>, a:PExpr<V>, c:PExpr<V>):Upshot<PExpr<V>, LenseFailure> {
		final result = switch (self) {
			case LsId 				: __.accept(a);
			case LsConstant(value, _default): switch (c) {
					case PEmpty		: __.accept(_default);
					default 			: __.accept(c);
				}
			case LsHoist(k): switch (k) {
					case CoField(key, null) : 
						__.accept(PAssoc([tuple2(PLabel(key), a)]));
					case CoField(key, idx)  : 
						__.accept(
								PAssoc(
									Iter.range(0, idx)
										.lfold(
											(next:Int, memo:Cluster<Tup2<PExpr<V>, PExpr<V>>>) -> {
													return memo.cons(tuple2(PExpr.lift(PEmpty), PExpr.lift(PEmpty)));
											}, 
											[].imm().cons(tuple2(PLabel(key), a))
										)
								)
						);
					case CoIndex(idx): __.accept(
						PArray(Iter.range(0,idx).map(x->PEmpty).toCluster().snoc(a))
					);
				}
			case LsPlunge(k) : 
				this.access(k, a)
						.fold(
							(x) -> __.accept(a),
							() 	-> __.accept(PEmpty) 
						);
			case LsXFork(pc, pa, lhs, rhs):
				trace(c);
				final in_c = c.ifilter(
					(i,e) -> {
						final loc = PmlLift.coord_makeI(c,i,e);
						return pc.any(x -> loc.equals(x));
					}
				);
				trace(in_c);
				final not_in_c = c.ifilter(
					(i,e) -> {
						final loc = PmlLift.coord_makeI(c,i,e);
						return !pc.any(x -> loc.equals(x));
					}
				);
				trace(not_in_c);
				trace(a);
				final in_a = a.ifilter(
					(i,e) -> {
						final loc = PmlLift.coord_makeI(a,i,e);
						return pc.any(x -> loc.equals(x));
					}
				);
				trace(in_a);
				final not_in_a = a.ifilter(
					(i,e) -> {
						final loc = PmlLift.coord_makeI(a,i,e);
						return !pc.any(x -> loc.equals(x));
					}
				);
				trace(not_in_a);
				return in_a.zip(not_in_a).flat_map(
					__.decouple(
						(in_a:PExpr<V>,not_in_a:PExpr<V>) -> in_c.zip(not_in_c).fold(
							__.decouple(
								(in_c:PExpr<V>,not_in_c:PExpr<V>) -> {
									trace('$in_a $in_c');
									final l 	= put(lhs,in_a,in_c);
									trace('$not_in_a $not_in_c');
									final r 	= put(rhs,not_in_a,not_in_c);
									trace('$l $r');
									return l.zip(r).flat_map(
										__.decouple((x:PExpr<V>,y:PExpr<V>) -> this.concat(y,x)) // TODO not sure this should be a lub
									);
								}
							),
							e -> __.reject(e)
						)
					)
				);
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
						case PGroup(list) 	: __.accept(PGroup(xs.map(x -> x.snd()).toLinkedList()));
						case PArray(array) 	: __.accept(PArray(xs.map(x -> x.snd())));
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
			case LsSequence(l, r): 
				get(l, c).flat_map(
					(cI) -> {
						return put(r, a, cI)
							.flat_map(aI -> put(l, aI, c));
					}
				);
			case LsCopy(m, n):
				trace(a);
				trace(n);
				a.imod(
					(i, e) -> switch(e){
						case PGroup(Cons(PLabel(x),Cons(y,Nil))) if (a.is_assoc()) : 
							Coord.make(x,i).equals(n).if_else(
								() -> __.accept(None),
								() -> __.accept(Some(e))
							);
						case x : 
							Coord.make(null,i).equals(n).if_else(
								() -> __.accept(None),
								() -> __.accept(Some(e))
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
					trace('$cm, $cn');
					final are_equal = V.eq().comply(cm, cn).is_ok();
					trace(are_equal);
					return 
						are_equal.if_else(
              () -> this.access(m, a)
							  .resolve(f -> f.of(E_Lense('no value $m on $a')))
							  .flat_map(
									am -> {
										trace('$a $am $cn');
										return this.upsert(
											a,
											am,
											n
										);
									}
                ),
              () -> {
								trace('$a $cn $n');
								this.upsert(a, cn,n);
							}
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
		trace('$self $result');
		return result;
	}

	public function get(self:LExpr<Coord, PExpr<V>>, c:PExpr<V>):Upshot<PExpr<V>, LenseFailure> {
		final ___self = __.show(self);
		final __c     = __.show(c);
		trace('$___self : $__c');
		final result = switch(self){
			case LsId                       : __.accept(c);
		  case LsConstant(value,_default) : __.accept(value);
		  case LsHoist(k)                 :
		    this.access(k,c).resolve(f -> f.of(E_Lense('no value at $k on $c')));
		  case LsPlunge(k)                :
		    switch(k){
		      case CoField(key,null) : __.accept(PAssoc([tuple2(PLabel(key),c)]));
		      case CoField(key,idx)  :
		        trace('idx $idx');
		        __.tracer()(__.accept(PAssoc(
		          Iter.range(0,__.tracer()(idx)).lfold(
		            (next,memo:Cluster<Tup2<PExpr<V>,PExpr<V>>>) -> {
		              //trace('ZSsas');
		              return memo.cons(tuple2(PExpr.lift(PEmpty),PExpr.lift(PEmpty)));
		            },
		            [].imm().cons(tuple2(PLabel(key),c))
		          )
		        )));
		        case CoIndex(idx)      :
		        __.accept(PArray([c]));
		    };
		  case LsXFork(pc,pa,lhs,rhs) : 
				final in_c = c.ifilter(
					(i,e) -> {
						final loc 		= PmlLift.coord_makeI(c,i,e);
						final result 	= pc.any(x -> loc.equals(x));
						trace(result);
						return result;
					}
				);
				trace(in_c);
				final not_in_c = c.ifilter(
					(i,e) -> {
						final loc = PmlLift.coord_makeI(c,i,e);
						trace('$pc $loc');
						final result = !pc.any(x -> {
							trace('${loc.equals(x)} ${loc.equals(x)}');
							return loc.equals(x);
						});
						trace(result);
						return result;
					}
				);
				trace(not_in_c);
				final a_in_c = in_c.flat_map(
					in_c -> {
						return (in_c.size() == 0).if_else(
							() -> this.get(lhs,in_c).map(Some),
							() -> in_c.mod(
								(e:PExpr<V>) -> c.is_assoc().if_else(
									() -> {
										trace(e);
										final t2 = e.as_tuple2().fudge();
										return this.get(lhs,t2.snd()).map(eI -> PExpr._.assoc_make(t2.fst(),eI)).map(Some);
									},
									() -> {
										this.get(lhs,e).map(Some);
									}
								)
							)
						);
					}
				);
				trace(a_in_c);
				final a_not_in_c = not_in_c.flat_map(
					not_in_c -> {
						return (not_in_c.size() == 0).if_else(
							() -> this.get(rhs,not_in_c).map(Some),
							() -> not_in_c.mod(
								(e:PExpr<V>) -> c.is_assoc().if_else(
									() -> {
										final t2 = e.as_tuple2().fudge();
										return this.get(rhs,t2.snd()).map(eI -> PExpr._.assoc_make(t2.fst(),eI)).map(Some);
									},
									() -> {
										this.get(rhs,e).map(Some);
									}
								)
							)
						);
					}
				);
				trace(a_not_in_c);
				//trace(a_in_c.zip(a_not_in_c));
				a_in_c.zip(a_not_in_c).flat_map(
					__.decouple(
						(x:Option<PExpr<V>>,y:Option<PExpr<V>>) -> {
							//trace('$x $y');
							return this.concat(y.defv(PEmpty),x.defv(PEmpty));
						}
					)	
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
				trace('$l $r');
		    get(l,c).flat_map(
		      cI -> {
						trace('$r $cI');
						return get(r,cI).map(
							(x) -> {
								trace(x);
								return x;
							}
						);
					}
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
		    // c.refine(
		    //   (x,y) -> __.accept(x.equals(n))
				// ).errate(E_Lense_Pml);
				final not_in_c = c.ifilter(
					(i,e) -> {
						final loc 	= PmlLift.coord_makeI(c,i,e);
						final result =  !n.equals(loc);
						trace('$n $loc $result');
						return result;
					}
				);
				trace(not_in_c);
				not_in_c;
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
		};
		trace('$self $result');
		return result;
	}

	/**
	 * Lub.
	 * @param self 
	 * @param that 
	 * 
	 */
	public function adjoin(lhs:PExpr<V>, rhs:PExpr<V>):Upshot<PExpr<V>, LenseFailure> {
		function joiner(next:Couple<PExpr<V>, PExpr<V>>, memo:Cluster<PExpr<V>>) {
			return next.decouple(adjoin).map(memo.snoc);
		}
		trace('$lhs $rhs');
		trace(this.V.lt().comply(rhs,lhs).is_less_than());
		return switch ([lhs, rhs]) {
			case [PAssoc(xs), PGroup(Cons(x, Cons(y, Nil)))]: __.accept(PAssoc(xs.snoc(tuple2(x, y))));

			case [x, null]: __.accept(x);
			case [null, x]: __.accept(x);

			case [x, PEmpty]: __.accept(x);
			case [PEmpty, x]: __.accept(x);

			case [PGroup(Nil), x]: __.accept(x);
			case [x, PGroup(Nil)]: __.accept(x);

			case [PGroup(listI), PGroup(listII)]:
				final max = Math.max(listI.size(),listII.size()).floor();
				listI 	= listI.rpad(max,PEmpty);
				listII 	= listII.rpad(max,PEmpty);

				Upshot.bind_fold(listI.zip(listII), joiner, [].imm()).map(xs -> xs.toLinkedList()).map(PGroup);
			case [PGroup(arrayI), PArray(arrayII)]:
				final max = Math.max(arrayI.size(),arrayII.size()).floor();
				arrayI 		= arrayI.rpad(max,PEmpty);
				arrayII 	= arrayII.pad(max,PEmpty);

				Upshot.bind_fold(arrayI.zip(arrayII), joiner, [].imm()).map(xs -> xs.toLinkedList()).map(PGroup);
			case [PGroup(arrayI), PSet(arrayII)]:
				final max = Math.max(arrayI.size(),arrayII.size()).floor();
				arrayI 		= arrayI.rpad(max,PEmpty);
				arrayII 	= arrayII.pad(max,PEmpty);

				Upshot.bind_fold(arrayI.zip(arrayII), joiner, [].imm()).map(xs -> xs.toLinkedList()).map(PGroup);
			case [PSet(setI), PSet(setII)]:
				final set 	= RedBlackSet.make(this.V).concat(setI).concat(setII);
				__.accept(PSet(set.toCluster()));
			case [PSet(setI), PArray(arrayII)]:
				final set 	= RedBlackSet.make(this.V).concat(setI).concat(arrayII);
				__.accept(PSet(set.toCluster()));
			case [PSet(setI), PGroup(arrayII)]:
				final set 	= RedBlackSet.make(this.V).concat(setI).concat(arrayII);
				__.accept(PSet(set.toCluster()));
			case [PArray(arrayI), PGroup(arrayII)]:
				final max = Math.max(arrayI.size(),arrayII.size()).floor();
				arrayI 		= arrayI.pad(max,PEmpty);
				final arrayIII 	= arrayII.toCluster().pad(max,PEmpty);

				Upshot.bind_fold(arrayI.zip(arrayIII), joiner, [].imm()).map(PArray);
			case [PArray(arrayI), PSet(arrayII)]:
				final max = Math.max(arrayI.size(),arrayII.size()).floor();
				arrayI 		= arrayI.pad(max,PEmpty);
				arrayII 	= arrayII.pad(max,PEmpty);

				Upshot.bind_fold(arrayI.zip(arrayII), joiner, [].imm()).map(PArray);
			case [PArray(arrayI), PArray(arrayII)]:
				final max = Math.max(arrayI.size(),arrayII.size()).floor();
				arrayI 		= arrayI.pad(max,PEmpty);
				arrayII 	= arrayII.pad(max,PEmpty);

				Upshot.bind_fold(arrayI.zip(arrayII), joiner, [].imm()).map(PArray);
			case [PAssoc(mapI), PAssoc(mapII)]:
				var keys 	: RedBlackSet<PExpr<V>> = RedBlackSet.make(this.V);
				
				for(k in mapI){
					$type(keys.put);
					keys = keys.put(k.fst());
				}
				for(k in mapII){
					keys = keys.put(k.fst());
				}
				trace(keys);
				return Upshot.bind_fold(
					keys,
					(next:PExpr<V>,memo:Cluster<Tup2<PExpr<V>,PExpr<V>>>) -> {
						final lhs = mapI.search(x -> V.eq().comply(next,x.fst()).is_ok()).map(x -> x.snd());
						final rhs = mapII.search(x -> V.eq().comply(next,x.fst()).is_ok()).map(x -> x.snd());
						final res = this.adjoin(lhs.defv(PEmpty),rhs.defv(PEmpty));
						return res.map(tuple2.bind(next)).map(memo.snoc);
					},
					[].imm()
				).map(PAssoc);
				// final max 	= Math.max(mapI.size(),mapII.size()).floor();
				// mapI 	= mapI.pad(max,tuple2(PEmpty,PEmpty));
				// mapII = mapII.pad(max,tuple2(PEmpty,PEmpty));
				
				// Upshot.bind_fold(mapI.zip(mapII), function(next:CplOfTup2OfP<V>, memo:Cluster<Tup2<PExpr<V>, PExpr<V>>>) {
				// 	return next.decouple((l, r) -> switch ([l, r]) {
				// 		case [tuple2(lI, rI), tuple2(lII, rII)]:
				// 			adjoin(lI, lII).zip(adjoin(rI, rII));
				// 	}).map(__.decouple(tuple2)).map(x -> memo.snoc((x)));
				// }, [].imm()).map(PAssoc);
			case [PValue(l),PValue(r)] if (V.is_greater_or_equal(PValue(r),PValue(l))) : __.accept(PValue(r));
			case [PLabel(l),PLabel(r)] if (V.is_greater_or_equal(PLabel(r),PLabel(l))) : __.accept(PLabel(r));
			case [PApply(l),PApply(r)] if (V.is_greater_or_equal(PApply(r),PApply(l))) : __.accept(PApply(r));
			default:
				__.reject(__.fault().of(stx.fail.PmlFailure.PmlFailureSum.E_Pml_CannotMix(lhs, rhs))).errate(E_Lense_Pml);
		}
	}
}

private class PmlLift {
	static public function concat<K, V>(self:Pml<V>, lhs:PExpr<V>, rhs:PExpr<V>) {
		final length = lhs.labels().length;
		// __.reject(f -> f.of(E_Parse('lhs is not a chain')));
		final signature = lhs.signature();
		final chain = switch (signature) {
			case PSigPrimate(_) 		: 
				None;
			case PSigCollect(_, _) 	| PSigBattery(_, _) : 
				Some(Left(Iter.range(0, length).map(_ -> PEmpty).toCluster()));
			case PSigCollate(_, _) 	| PSigOutline(_) : 
				//Some(Right(Iter.range(0, length).map(_ -> tuple2(PEmpty, PEmpty)).toCluster()));
				Some(Right([].imm()));
		}
		trace('$chain $rhs');
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
		trace(lhs.toString());
		trace(rhsI.toString());
		final result = self.adjoin(lhs, rhsI.defv(PEmpty));
		trace(result.fudge().toString());
		return result;
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
            __.accept(
							PAssoc(
								[tuple2(x,y)]
								//Iter.range(0,lhs.size()).toCluster().map(_ -> tuple2(PEmpty,PEmpty)).snoc(tuple2(x,y))
							)
						);
          default                           : 
          __.reject(f -> f.of(E_Lense('malformed item for entry into group $rhs')));
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
								__.accept(Some(PGroup(Cons(PLabel(key),Cons(replace_with,Nil)))));
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
		trace(is_update);
    return is_update.if_else(
      () -> {
				trace('$lhs $rhs');
				return update(lhs,rhs,at);
			},
      () -> {
				if(lhs.is_assoc()){
					rhs = PGroup(Cons(PLabel(at.field.fudge()),Cons(rhs,Nil)));
					trace(rhs);
				}
				return insert(self,lhs,rhs);
			}
    );
  }
	static public function append<T>(self:Pml<T>,lhs:PExpr<T>,rhs:Cluster<PExpr<T>>):Upshot<PExpr<T>,LenseFailure>{
		return switch(lhs){
			case PAssoc(map) : PExpr._.as_assoc_cluster(rhs).map(
				x -> PAssoc(map.concat(x))
			).errate(E_Lense_Pml);
			case PArray(arr) 	: __.accept(PArray(arr.concat(rhs)));
			case PSet(arr) 		: 
				final set = RedBlackSet.make(self.V).concat(arr).concat(rhs);
				__.accept(PSet(set.toCluster()));
			case PGroup(grp) 	: 
				__.accept(PGroup(grp.concat(rhs)));
			default 					: 
				__.reject(f -> f.of(E_Lense('lhs is not a chain')));
		}
	}
	static public function coord_makeI<T>(root:PExpr<T>,i:Int,e:PExpr<T>){
		return if(root.is_assoc()){
			switch(e){
				case PGroup(Cons(PLabel(x),Cons(y,Nil))) : Coord.make(x,i);
				default 																 : Coord.make(null,i);
			}
		}else{
			Coord.make(null,i);
		}
	}
}

