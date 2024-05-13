// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion

// ***~~~ Delegate Objects ~~~*** //
    // *- Local Anonymous Delegates
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion
// #endregion


// ***~~~ Functions ~~~*** //
// #region

//  *- Gravity Calc
// #region

    // CalcLocalGravity :: _body<Body>, _ves<Vessel>, _alt<Scalar>  -> locGravity<Scalar>
    // Calculates the local gravity between a body and vessel at a given altitude
    global function CalcLocalGravity
    {
        parameter _body is Ship:Body,
                  _ves  is Ship,
                  _alt  is Ship:Altitude,
                  _bodyMass is _body:Mass,
                  _vesMass is _ves:Mass.

        // F = (G * M_1 * M_2) / r^2
        return (Constant:G * _bodyMass * _vesMass) / ((_alt + _body:Radius)^2).
    }
    
// #endregion
// #endregion