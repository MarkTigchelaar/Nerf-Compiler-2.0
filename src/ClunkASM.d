import ByteCodeVM;
import assembler: Assembler, ByteCodeProgram;
import structures;
import std.stdio;

void main(string[] args) {
    writeln("Starting program.");
    if(args.length != 2) {
        writeln("ERROR: 1 filename argument required.");
    } else {
        ByteCodeVM vm = new ByteCodeVM();
        Assembler asblr = new Assembler();
        asblr.load_from_file(args[1]);
        ByteCodeProgram* runnable = asblr.assemble();
        vm.load_bytecode(runnable.compiled_program);
        vm.load_float_constants(runnable.fp_constants);
        vm.run();
        writeln("Program finished.");
        //vm.show_bytecode();
    }
}