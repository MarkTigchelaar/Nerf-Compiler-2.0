module executor;

import symbol_table;
import structures;
import program_state_manager;
import std.stdio;
import std.array;
import std.regex;
import std.conv: to;

/*
    Uses all the needed methods from the symbol table, and executes the
    instructions found in the abstract syntax tree.
*/
class ExecutionUnit {
    private ProgramStateManager variable_mgmt;
    private Program* program;
    private string callee_function_name;

    this(SymbolTable table, Program* program) {
        this.variable_mgmt = table.get_state_mgmt();
        this.program = program;
        this.callee_function_name = table.get_entry_point();
    }

    private void end_function() {
        variable_mgmt.clear_local_variables();
    }

    public void execute_program() {
        execute_function(callee_function_name, []);
        end_function();
    }

    private void execute_function(string fn_name, string[] values) {
        Function* func = get_function(fn_name);
        prepare_function(func.arg_names, values);
        foreach(Statement* statement; func.stmts) {
            statement_type_switchboard(statement);
        }
        end_function();
    }

    private Function* get_function(string fn_name) {
        Function* selected;
        foreach(Function* func; program.functions) {
            if(func.name == fn_name) {
                selected = func;
                break;
            }
        }
        assert(selected !is null);
        return selected;
    }

    private void prepare_function(immutable string[] var_names, string[] values) {
        assert(var_names.length == values.length);
        for(ulong i = 0; i < values.length; i++) {
            variable_mgmt.add_variables_for_eval(var_names[i].dup, values[i]);
        }
    }

    private void statement_type_switchboard(Statement* statement) {
        switch(statement.stmt_type) {
            case StatementTypes.assign_statement:

            case StatementTypes.re_assign_statement:

            case StatementTypes.break_statement:

            case StatementTypes.return_statement:

            case StatementTypes.if_statement:

            case StatementTypes.else_if_statement:

            case StatementTypes.else_statement:

            case StatementTypes.while_statement:

            case StatementTypes.continue_statement:

            case StatementTypes.print_statement:
                break;
            default:
                throw new Exception("unknown statment evaluation.");
        }
    }
}