module executor;

import symbol_table;
import structures;
import std.stdio;
import std.array;
import std.regex;
import std.conv: to;

/*
    Uses all the needed methods from the symbol table, and executes the
    instructions found in the abstract syntax tree.
*/
class ExecutionUnit {
    private SymbolTable table;
    private Program* program;
    private string[string] current_values;
    private string callee_function_name;

    this(SymbolTable table, Program* program) {
        this.table = table;
        this.program = program;
    }

    private void increase_scope_level() {
        table.scope_level_one_level_deeper();
    }

    private void decrease_scope_level() {
        table.scope_level_one_level_shallower();
    }

    private void end_function() {
        table.clear_local_variables();
        current_values.clear();
    }

    public void execute() {
        execute_function(table.get_entry_point(), []);
    }

    private void execute_function(string fn_name, string[] values) {
        Function* func = get_function(fn_name);
        prepare_function(func.arg_names, values);
        foreach(Statement* statement; func.stmts) {
            execute_statment(statement);
        }
    }

    private Function* get_function(string fn_name) {
        Function* selected;
        foreach(Function* func; program.functions) {
            if(func.name == fn_name) {
                selected = func;
                break;
            }
        }
        return selected;
    }

    private void prepare_function(string[] var_names, string[] values) {
        assert(var_names.length == values.length);
        for(ulong i = 0; i < values.length; i++) {
            current_values[var_names[i]] = values[i];
        }
    }
}