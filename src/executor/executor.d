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
    private SymbolTable table;
    private string[string] operation_table;
    private Program* program;
    private string callee_function_name;

    this(SymbolTable table, Program* program) {
        this.variable_mgmt = table.get_state_mgmt();
        this.program = program;
        this.callee_function_name = table.get_entry_point();
        this.table = table;
        this.operation_table = table.get_operation_table();
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
                break;
            case StatementTypes.re_assign_statement:
                break;
            case StatementTypes.break_statement:
                break;
            case StatementTypes.return_statement:
                break;
            case StatementTypes.if_statement:
                break;
            case StatementTypes.else_if_statement:
                break;
            case StatementTypes.else_statement:
                break;
            case StatementTypes.while_statement:
                break;
            case StatementTypes.continue_statement:
                break;
            case StatementTypes.print_statement:
                exec_print(statement);
                break;
            default:
                throw new Exception("unknown statment evaluation.");
        }
    }

    private void exec_print(Statement* statement) {
        foreach(Expression* exp; statement.syntax_tree.args) {
            write(eval_expression(exp), " ");
        }
        writeln();
    }

    private string eval_expression(Expression* exp) {
        
    }

    private real add(string left, string right) {
        return to!real(left) + !real(right);
    }

    private real sub(string left, string right) {
        return to!real(left) - !real(right);
    }

    private real mult(string left, string right) {
        return to!real(left) * !real(right);
    }

    private real div(string left, string right) {
        return to!real(left) / !real(right);
    }

    private real mod(string left, string right) {
        return floor(to!real(left) / !real(right));
    }

    private real exp(string left, string right) {
        return to!real(left) ^^ to!real(right);
    }

    private bool less_than(string left, string right) {
        return to!real(left) < to!real(right);
    }

    private bool equal(string left, string right) {
        return to!real(left) < to!real(right);
    }

    private bool not(string arg) {
        return ! table.get_bool(arg);
    }
}