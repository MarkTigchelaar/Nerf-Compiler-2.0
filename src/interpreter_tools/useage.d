module useage;
import std.stdio: writeln;

void useage() {
    writeln("Useage:");
    writeln("    nerf [filename] --tok --ast");
    writeln("    tok: displays tokens of inputted source file.");
    writeln("    ast: displays programs abstract syntax tree.");
    writeln("    ./nerf 'filename.nerf': compiles source program.");
    writeln("    nerf currently supports only one source file at a time.");
    writeln("\n\n    Files must have extension of '.nerf' for nerf programming language.");
    writeln("\n    Function declaration: fn function_name(type arg, type arg[, ...]) type {}");
    writeln("\n    built in types: int, float, bool, void.");
    writeln("\n    statements in nerf are terminated with a ;.");
    writeln("\n    nerf currently does not support arrays (todo).");
    writeln("\n    branching statements: if, else, (else if), while, return, break.");
    writeln("\n    assignment statement: type variable_name := value OR type variable_name;.");
    writeln("\n    nerf has one built in function, print: print(arg1, arg2[, ...]);");
    writeln("\n    print accepts any number of arguments, of any supported type.");
    writeln("\n    nerf is a statically typed language, and does not support casting, or conversion of types.");
    writeln("\n    nerf does not have built in data structures, or structs (todo?).");
}