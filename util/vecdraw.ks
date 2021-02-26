//Draws the XYZ axes of a given direction (rotation)
//
parameter dir is r(0, 0, 0), 
          baseColor is red, 
          scale is 5, 
          label is "raw".

local draws to list().

    draws:add(list()).

    local colorOffset to 0.3.

    draws[draws:length - 1]:add(
        vecDrawArgs(
            v(0, 0, 0), 
            dir * v(1, 0, 0),
            rgb( baseColor:red + colorOffset, baseColor:Green - colorOffset, baseColor:blue - colorOffset),
            label + " X", 
            scale, 
            true,
            0.05
        )
    ).

    draws[draws:length - 1]:add(
        vecDrawArgs(
            v(0, 0, 0), dir * v(0, 1, 0),
            rgb( baseColor:red - colorOffset, baseColor:Green + colorOffset, baseColor:blue - colorOffset),
            label + " Y", 
            scale, 
            true,
            0.05
        )
    ).

    draws[draws:length - 1]:add(
        vecDrawArgs(
            v(0, 0, 0), 
            dir * v(0, 0, 1),
            rgb( baseColor:red - colorOffset, baseColor:Green + colorOffset, baseColor:blue + colorOffset),
            label + " Z", 
            scale, 
            true,
            0.05
        )
    ).
