global function add_node {
    parameter t,
              p is 0,
              n is 0,
              r is 0.

    //Maneuver node is time, radial, normal, prograde.
    if career():canmakenodes {
        local mnode to node(t, r, n, p).
        add mnode.
        return mnode.
    }

    else return false.
}