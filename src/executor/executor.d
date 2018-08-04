module executor;

import symbol_table;
import structures;
import std.stdio;
import std.array;
import std.regex;


/*
    Uses all the needed methods from the symbol table, and executes the
    instructions found in the abstract syntax tree.
*/
class ExecutionUnit {
    private int current_int;
    private real current_float;
    private bool current_bool;
    private SymbolTable table;
    private Program* program;
    private string fn_name;

    this(SymbolTable table, Program* program) {
        this.table = table;
        this.program = program;
        this.fn_name = table.get_entry_point();
    }

    private void increase_scope_level() {
        table.scope_level_one_level_deeper();
    }

    private void decrease_scope_level() {
        table.scope_level_one_level_shallower();
    }

    private void end_function() {
        table.clear_local_variables();
    }

    public void execute() {
        Function* selected;
        foreach(Function* func; program.functions) {
            if(func.name == fn_name) {
                selected = func;
                break;
            }
        }
    }
}