// // Calculates the eccentricity of given ap, pe, and planet
// global function calc_ecc {
//     parameter _ap,
//               _pe,
//               _body is ship:body.

//     if _body:typeName <> "Body" set _body to Body(_body).
    
//     return (_ap + _body:radius) - (_pe + _body:radius) / (_ap + _pe + (_body:radius * 2)).
// }