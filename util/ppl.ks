@lazyGlobal off.

parameter inObj. 

runOncePath("0:/lib/disp").

if inObj:TypeName = "ListValue`1" or inObj:TypeName = "List"
{
    print_list(inObj).
} 
else if inObj:TypeName = "Lexicon" 
{
    print_lex(inObj).
}