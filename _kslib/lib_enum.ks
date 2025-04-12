// This file is distributed under the terms of the MIT license, (c) the KSLib
// team

  global Enum is lex(
    "version", "0.1.1",
    "all", all@,
    "any", any@,
    "count", count@,
    "each", each@,
    "each_slice", each_slice@,
    "each_with_index", each_with_index@,
    "find", find@,
    "find_index", find_index@,
    "group_by", group_by@,
    "map", map@,
    "map_with_index", map_with_index@,
    "max", _max@,
    "min", _min@,
    "partition", partition@,
    "reduce", reduce@,
    "reject", reject@,
    "reverse", reverse@,
    "select", select@,
    "sort", sort@
  ).

  local y is true. local n is false.

  function cast {
    parameter a,
              b,
              _r is 0.
    
    if a:typename = b return a.
    
    if b = "List" { 
      set _r to list(). 
      for i in a _r:Add(i). 

      return _r.
    }

    if b = "Queue" { 
      set _r to queue(). 
      for i in a _r:push(i). 

      return _r.
    }

    if b="Stack"{
      local l is stack().

      set _r to stack(). 
      for i in a _r:push(i).
      for i in _r l:push(i). 
      
      return l.
    }
  }.

  function to_l { 
    parameter c. 

    return cast(c,"List").
  }.

  function all { 
    parameter l,
              c. 
    
    for i in l {
      if not c(i) {

        return n. 
      }
    }

    return y.
  }.

  function any { 
    parameter l,
              c. 
    
    for i in l {
      if c(i) { 
        
        return y. 
      }
    }

    return n.
  }.

  function count {
    parameter l,
              c,
              _r is 0. 
    
    for i in l if c(i) set _r to r+1. 

    return _r.
  }.

  function each { 
    parameter l,
              o. 
    
    for i in l o(i).
  }.

  function each_slice {
    parameter l,
              m,
              o,
              c is to_l(l),
              i is 0.
    
    until i > c:Length - 1 {
      o(cast(c:sublist(i, min(m, c:Length-1)), l:typename)). 
      set i to i+m. 
    } 
  }.

  function each_with_index {
    parameter l,
              o,
              i is 0. 
    
    for j in to_l(l) { 
      o(j,i + 1). 
      set i to i + 1. 
    } 
  }.

  function find {
    parameter l,
              c. 
    
    for i in l if c(i) return i. 

    return n.
  }.

  function find_index {
    parameter l,
              c,
              i is 0. 
    
    for j in to_l(l) {
      
      if c(j) return i. 
      set i to i + 1. 
    }

    return -1. 
  }.

  function group_by { 
    parameter l,
              t,
              _r is lex(). 
    
    for i in l {
      local u is t(i). 
      
      if _r:haskey(u) {
        _r[u]:Add(i). 
      }
      
      else {
        set _r[u] to list(i). 
      }
    }

    for k in _r:keys set _r[k] to cast(_r[k], l:typename). 
    return _r. 
  }.

  function map {
    parameter l,
              t,
              _r is list(). 
    
    for i in to_l(l) {
      _r:Add(t(i)).
    }

    return cast(_r, l:typename).
  }.

  function map_with_index { 
    parameter l,
              t,
              _r is list(), 
              i is 0, 
              c is to_l(l).

    until i=c:Length { 
      _r:Add(t(c[i], i + 1)). 
      set i to i + 1. 
    }

    return cast(_r, l:typename). 
  }.

  function _max {
    parameter l,
              c is to_l(l). 
    
    if c:Length = 0 return n.
    
    local r0 is c[0]. 
    
    for i in c {

      if i > r0 set r0 to i. 
    }
    return r0.
  }.

  function _min {
    parameter l, 
              c is to_l(l). 
    
    if c:Length = 0 return n.

    local r0 is c[0].

    for i in c {
      
      if i < r0 {
        set r0 to i. 
      }
    }

    return r0. 
  }.

  function partition { 
    parameter l, 
              o, 
              c is to_l(l), 
              _r is list(list(), list()).

    for i in c { 

      if o(i) {
        _r[0]:Add(i). 
      }
      
      else {
        _r[1]:Add(i). 
      }
    }

    set _r[0] to cast(_r[0], l:typename). 
    set _r[1] to cast(_r[1], l:typename).

    return _r.
  }.

  function reduce { 
    parameter l, 
              m, 
              t. 
    
    for i in to_l(l) {
      set m to t(m, i). 
      
      return m. 
    }
  }.

  function reject { 
    parameter l, 
              c, 
              _r is list().

    for i in to_l(l) {

      if not c(i) {
        _r:Add(i). 
      }
    }
    
    return cast(_r, l:typename). 
  }.

  function reverse { 
    parameter l, 
              _r is stack().

    for i in l _r:push(i).
    
    return cast(_r, l:typename). 
  }.

  function select {
    parameter l, 
              c, 
              _r is list().

    for i in to_l(l) {
      
      if c(i) _r:Add(i). 
    }
    
    return cast(_r,l:typename).
  }

  function sort {
    parameter l, 
              c, 
              _r is to_l(l):copy.

    function qs {
      parameter A, 
                lo, 
                hi.

      if lo < hi {
        local p is pt(A, lo, hi). 
        qs(A, lo, p). 
        qs(A, p + 1, hi).
      }
    }

    function pt {
      parameter A, 
                lo, 
                hi, 
                pivot is A[lo], 
                i is lo - 1, 
                j is hi + 1.
      
      until 0 {

        until 0 {
          set j to j - 1. 
          if c(A[j], pivot) <= 0 break.
        }

        until 0 {
          set i to i + 1. 
          if c(A[i], pivot) >= 0 break.}

        if i < j { 
          local s is A[i]. 
          set A[i] to A[j]. 
          set A[j] to s.
        } 
        
        else return j.
      }
    }
    
    qs(_r, 0, _r:Length - 1).
    
    return cast(_r, l:typename).
  }