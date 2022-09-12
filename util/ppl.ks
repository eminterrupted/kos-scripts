@lazyGlobal off.

parameter inObj.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").

local tip to "".

if inObj:TypeName = "ListValue`1" or inObj:TypeName = "List"
{
    if inObj[0]:typename = "string"
    {
        if inObj[0]:startsWith("<tip>") 
        {
            set tip to inObj[0]:replace("<tip>","").
        }
    }
    DispList(inObj, tip).
} 
else if inObj:TypeName = "Lexicon" 
{
    if inObj:hasKey("<tip>") set tip to inObj["<tip>"].
    DispLex(inObj, tip).
}