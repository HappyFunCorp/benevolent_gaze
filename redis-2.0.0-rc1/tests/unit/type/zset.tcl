start_server default.conf {} {
    test {ZSET basic ZADD and score update} {
        r zadd ztmp 10 x
        r zadd ztmp 20 y
        r zadd ztmp 30 z
        set aux1 [r zrange ztmp 0 -1]
        r zadd ztmp 1 y
        set aux2 [r zrange ztmp 0 -1]
        list $aux1 $aux2
    } {{x y z} {y x z}}

    test {ZCARD basics} {
        r zcard ztmp
    } {3}

    test {ZCARD non existing key} {
        r zcard ztmp-blabla
    } {0}

    test {ZRANK basics} {
        r zadd zranktmp 10 x
        r zadd zranktmp 20 y
        r zadd zranktmp 30 z
        list [r zrank zranktmp x] [r zrank zranktmp y] [r zrank zranktmp z]
    } {0 1 2}

    test {ZREVRANK basics} {
        list [r zrevrank zranktmp x] [r zrevrank zranktmp y] [r zrevrank zranktmp z]
    } {2 1 0}

    test {ZRANK - after deletion} {
        r zrem zranktmp y
        list [r zrank zranktmp x] [r zrank zranktmp z]
    } {0 1}

    test {ZSCORE} {
        set aux {}
        set err {}
        for {set i 0} {$i < 1000} {incr i} {
            set score [expr rand()]
            lappend aux $score
            r zadd zscoretest $score $i
        }
        for {set i 0} {$i < 1000} {incr i} {
            if {[r zscore zscoretest $i] != [lindex $aux $i]} {
                set err "Expected score was [lindex $aux $i] but got [r zscore zscoretest $i] for element $i"
                break
            }
        }
        set _ $err
    } {}

    test {ZSCORE after a DEBUG RELOAD} {
        set aux {}
        set err {}
        r del zscoretest
        for {set i 0} {$i < 1000} {incr i} {
            set score [expr rand()]
            lappend aux $score
            r zadd zscoretest $score $i
        }
        r debug reload
        for {set i 0} {$i < 1000} {incr i} {
            if {[r zscore zscoretest $i] != [lindex $aux $i]} {
                set err "Expected score was [lindex $aux $i] but got [r zscore zscoretest $i] for element $i"
                break
            }
        }
        set _ $err
    } {}

    test {ZRANGE and ZREVRANGE basics} {
        list [r zrange ztmp 0 -1] [r zrevrange ztmp 0 -1] \
            [r zrange ztmp 1 -1] [r zrevrange ztmp 1 -1]
    } {{y x z} {z x y} {x z} {x y}}

    test {ZRANGE WITHSCORES} {
        r zrange ztmp 0 -1 withscores
    } {y 1 x 10 z 30}

    test {ZSETs stress tester - sorting is working well?} {
        set delta 0
        for {set test 0} {$test < 2} {incr test} {
            unset -nocomplain auxarray
            array set auxarray {}
            set auxlist {}
            r del myzset
            for {set i 0} {$i < 1000} {incr i} {
                if {$test == 0} {
                    set score [expr rand()]
                } else {
                    set score [expr int(rand()*10)]
                }
                set auxarray($i) $score
                r zadd myzset $score $i
                # Random update
                if {[expr rand()] < .2} {
                    set j [expr int(rand()*1000)]
                    if {$test == 0} {
                        set score [expr rand()]
                    } else {
                        set score [expr int(rand()*10)]
                    }
                    set auxarray($j) $score
                    r zadd myzset $score $j
                }
            }
            foreach {item score} [array get auxarray] {
                lappend auxlist [list $score $item]
            }
            set sorted [lsort -command zlistAlikeSort $auxlist]
            set auxlist {}
            foreach x $sorted {
                lappend auxlist [lindex $x 1]
            }
            set fromredis [r zrange myzset 0 -1]
            set delta 0
            for {set i 0} {$i < [llength $fromredis]} {incr i} {
                if {[lindex $fromredis $i] != [lindex $auxlist $i]} {
                    incr delta
                }
            }
        }
        format $delta
    } {0}

    test {ZINCRBY - can create a new sorted set} {
        r del zset
        r zincrby zset 1 foo
        list [r zrange zset 0 -1] [r zscore zset foo]
    } {foo 1}

    test {ZINCRBY - increment and decrement} {
        r zincrby zset 2 foo
        r zincrby zset 1 bar
        set v1 [r zrange zset 0 -1]
        r zincrby zset 10 bar
        r zincrby zset -5 foo
        r zincrby zset -5 bar
        set v2 [r zrange zset 0 -1]
        list $v1 $v2 [r zscore zset foo] [r zscore zset bar]
    } {{bar foo} {foo bar} -2 6}

    test {ZRANGEBYSCORE and ZCOUNT basics} {
        r del zset
        r zadd zset 1 a
        r zadd zset 2 b
        r zadd zset 3 c
        r zadd zset 4 d
        r zadd zset 5 e
        list [r zrangebyscore zset 2 4] [r zrangebyscore zset (2 (4] \
             [r zcount zset 2 4] [r zcount zset (2 (4]
    } {{b c d} c 3 1}

    test {ZRANGEBYSCORE withscores} {
        r del zset
        r zadd zset 1 a
        r zadd zset 2 b
        r zadd zset 3 c
        r zadd zset 4 d
        r zadd zset 5 e
        r zrangebyscore zset 2 4 withscores
    } {b 2 c 3 d 4}

    test {ZRANGEBYSCORE fuzzy test, 100 ranges in 1000 elements sorted set} {
        set err {}
        r del zset
        for {set i 0} {$i < 1000} {incr i} {
            r zadd zset [expr rand()] $i
        }
        for {set i 0} {$i < 100} {incr i} {
            set min [expr rand()]
            set max [expr rand()]
            if {$min > $max} {
                set aux $min
                set min $max
                set max $aux
            }
            set low [r zrangebyscore zset -inf $min]
            set ok [r zrangebyscore zset $min $max]
            set high [r zrangebyscore zset $max +inf]
            set lowx [r zrangebyscore zset -inf ($min]
            set okx [r zrangebyscore zset ($min ($max]
            set highx [r zrangebyscore zset ($max +inf]

            if {[r zcount zset -inf $min] != [llength $low]} {
                append err "Error, len does not match zcount\n"
            }
            if {[r zcount zset $min $max] != [llength $ok]} {
                append err "Error, len does not match zcount\n"
            }
            if {[r zcount zset $max +inf] != [llength $high]} {
                append err "Error, len does not match zcount\n"
            }
            if {[r zcount zset -inf ($min] != [llength $lowx]} {
                append err "Error, len does not match zcount\n"
            }
            if {[r zcount zset ($min ($max] != [llength $okx]} {
                append err "Error, len does not match zcount\n"
            }
            if {[r zcount zset ($max +inf] != [llength $highx]} {
                append err "Error, len does not match zcount\n"
            }

            foreach x $low {
                set score [r zscore zset $x]
                if {$score > $min} {
                    append err "Error, score for $x is $score > $min\n"
                }
            }
            foreach x $lowx {
                set score [r zscore zset $x]
                if {$score >= $min} {
                    append err "Error, score for $x is $score >= $min\n"
                }
            }
            foreach x $ok {
                set score [r zscore zset $x]
                if {$score < $min || $score > $max} {
                    append err "Error, score for $x is $score outside $min-$max range\n"
                }
            }
            foreach x $okx {
                set score [r zscore zset $x]
                if {$score <= $min || $score >= $max} {
                    append err "Error, score for $x is $score outside $min-$max open range\n"
                }
            }
            foreach x $high {
                set score [r zscore zset $x]
                if {$score < $max} {
                    append err "Error, score for $x is $score < $max\n"
                }
            }
            foreach x $highx {
                set score [r zscore zset $x]
                if {$score <= $max} {
                    append err "Error, score for $x is $score <= $max\n"
                }
            }
        }
        set _ $err
    } {}

    test {ZRANGEBYSCORE with LIMIT} {
        r del zset
        r zadd zset 1 a
        r zadd zset 2 b
        r zadd zset 3 c
        r zadd zset 4 d
        r zadd zset 5 e
        list \
            [r zrangebyscore zset 0 10 LIMIT 0 2] \
            [r zrangebyscore zset 0 10 LIMIT 2 3] \
            [r zrangebyscore zset 0 10 LIMIT 2 10] \
            [r zrangebyscore zset 0 10 LIMIT 20 10]
    } {{a b} {c d e} {c d e} {}}

    test {ZRANGEBYSCORE with LIMIT and withscores} {
        r del zset
        r zadd zset 10 a
        r zadd zset 20 b
        r zadd zset 30 c
        r zadd zset 40 d
        r zadd zset 50 e
        r zrangebyscore zset 20 50 LIMIT 2 3 withscores
    } {d 40 e 50}

    test {ZREMRANGEBYSCORE basics} {
        r del zset
        r zadd zset 1 a
        r zadd zset 2 b
        r zadd zset 3 c
        r zadd zset 4 d
        r zadd zset 5 e
        list [r zremrangebyscore zset 2 4] [r zrange zset 0 -1]
    } {3 {a e}}

    test {ZREMRANGEBYSCORE from -inf to +inf} {
        r del zset
        r zadd zset 1 a
        r zadd zset 2 b
        r zadd zset 3 c
        r zadd zset 4 d
        r zadd zset 5 e
        list [r zremrangebyscore zset -inf +inf] [r zrange zset 0 -1]
    } {5 {}}

    test {ZREMRANGEBYRANK basics} {
        r del zset
        r zadd zset 1 a
        r zadd zset 2 b
        r zadd zset 3 c
        r zadd zset 4 d
        r zadd zset 5 e
        list [r zremrangebyrank zset 1 3] [r zrange zset 0 -1]
    } {3 {a e}}

    test {ZUNIONSTORE against non-existing key doesn't set destination} {
      r del zseta
      list [r zunionstore dst_key 1 zseta] [r exists dst_key]
    } {0 0}

    test {ZUNIONSTORE basics} {
        r del zseta zsetb zsetc
        r zadd zseta 1 a
        r zadd zseta 2 b
        r zadd zseta 3 c
        r zadd zsetb 1 b
        r zadd zsetb 2 c
        r zadd zsetb 3 d
        list [r zunionstore zsetc 2 zseta zsetb] [r zrange zsetc 0 -1 withscores]
    } {4 {a 1 b 3 d 3 c 5}}

    test {ZUNIONSTORE with weights} {
        list [r zunionstore zsetc 2 zseta zsetb weights 2 3] [r zrange zsetc 0 -1 withscores]
    } {4 {a 2 b 7 d 9 c 12}}

    test {ZUNIONSTORE with AGGREGATE MIN} {
        list [r zunionstore zsetc 2 zseta zsetb aggregate min] [r zrange zsetc 0 -1 withscores]
    } {4 {a 1 b 1 c 2 d 3}}

    test {ZUNIONSTORE with AGGREGATE MAX} {
        list [r zunionstore zsetc 2 zseta zsetb aggregate max] [r zrange zsetc 0 -1 withscores]
    } {4 {a 1 b 2 c 3 d 3}}

    test {ZINTERSTORE basics} {
        list [r zinterstore zsetc 2 zseta zsetb] [r zrange zsetc 0 -1 withscores]
    } {2 {b 3 c 5}}

    test {ZINTERSTORE with weights} {
        list [r zinterstore zsetc 2 zseta zsetb weights 2 3] [r zrange zsetc 0 -1 withscores]
    } {2 {b 7 c 12}}

    test {ZINTERSTORE with AGGREGATE MIN} {
        list [r zinterstore zsetc 2 zseta zsetb aggregate min] [r zrange zsetc 0 -1 withscores]
    } {2 {b 1 c 2}}

    test {ZINTERSTORE with AGGREGATE MAX} {
        list [r zinterstore zsetc 2 zseta zsetb aggregate max] [r zrange zsetc 0 -1 withscores]
    } {2 {b 2 c 3}}
    
    test {ZSETs skiplist implementation backlink consistency test} {
        set diff 0
        set elements 10000
        for {set j 0} {$j < $elements} {incr j} {
            r zadd myzset [expr rand()] "Element-$j"
            r zrem myzset "Element-[expr int(rand()*$elements)]"
        }
        set l1 [r zrange myzset 0 -1]
        set l2 [r zrevrange myzset 0 -1]
        for {set j 0} {$j < [llength $l1]} {incr j} {
            if {[lindex $l1 $j] ne [lindex $l2 end-$j]} {
                incr diff
            }
        }
        format $diff
    } {0}

    test {ZSETs ZRANK augmented skip list stress testing} {
        set err {}
        r del myzset
        for {set k 0} {$k < 10000} {incr k} {
            set i [expr {$k%1000}]
            if {[expr rand()] < .2} {
                r zrem myzset $i
            } else {
                set score [expr rand()]
                r zadd myzset $score $i
            }
            set card [r zcard myzset]
            if {$card > 0} {
                set index [randomInt $card]
                set ele [lindex [r zrange myzset $index $index] 0]
                set rank [r zrank myzset $ele]
                if {$rank != $index} {
                    set err "$ele RANK is wrong! ($rank != $index)"
                    break
                }
            }
        }
        set _ $err
    } {}
}
