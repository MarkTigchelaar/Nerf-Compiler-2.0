import Lexer;
import NewSymbolTable;
import function_parsers;
import SemanticAnalyzer;
import std.stdio: writeln;
import std.getopt;
import structures: Program;
import assembler: assemble;

void main(string[] arguments) {
    if(arguments.length < 2) {
        usage();
        return;
    }

    bool ast = false;
    getopt(arguments, "ast", &ast);
    auto lexer = new Lexer();
    lexer.process_source(arguments);
    Parser parser = new Parser(lexer);
    Program* program = parser.parse();
    SemanticAnalyzer analyzer = new SemanticAnalyzer();
    analyzer.semantic_analysis(program);
    ubyte[] bytecode = assemble(program);
/*
    ByteCodeVM VirtualMachine = new ByteCodeVM();
    VirtualMachine.load_bytecode(bytecode);
    VirtualMachine.run();
*/
    writeln("Program Successful.");

}


void usage() {
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


string trim_prog_name(string raw_name) {
    ulong trim_left;
    ulong trim_right;
    for(long i = raw_name.length - 1; i >= 0; i--) {
        if(raw_name[i] == '.') {
            trim_right = i;
        } else if(raw_name[i] == '/') {
            trim_left = i + 1;
            break;
        }
    }
    return raw_name[trim_left .. trim_right].dup;
}