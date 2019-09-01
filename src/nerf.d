import Lexer;
import SemanticAnalyzer;
import std.getopt;
import functions: Function;
import assembler: Assembler, ByteCodeProgram;
import ByteCodeVM: ByteCodeVM;
import useage: useage;
import function_parsers: Parser;
import compile: compile;
import std.stdio: writeln;
import core.memory;

void main(string[] arguments) {
    if(arguments.length < 2) {
        useage();
        return;
    }
    bool _asm = false;
    getopt(arguments, "asm", &_asm);
    auto lexer = new Lexer();
    lexer.process_source(arguments);

    Parser parser = new Parser(lexer);
    Function[] program = parser.parse();

    SemanticAnalyzer analyzer = new SemanticAnalyzer();
    analyzer.semantic_analysis(program);

    string[] assembly = compile(program);
    if(_asm) {
        display_asm(assembly);
        return;
    }
    Assembler asm_machine = new Assembler();
    asm_machine.load_from_compiler(assembly);

    ByteCodeProgram* runnable = asm_machine.assemble();
    ByteCodeVM VirtualMachine = new ByteCodeVM();
    VirtualMachine.load_bytecode(runnable.compiled_program);
    VirtualMachine.load_float_constants(runnable.fp_constants);
    GC.collect();
    GC.disable();
    VirtualMachine.run();
    GC.enable();

}


void display_asm(string[] assembly) {
    foreach(string _asm; assembly) {
        writeln(_asm);
    }
}