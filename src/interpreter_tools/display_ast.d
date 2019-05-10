module display_ast;
import std.stdio;
import structures;
import symbol_table;

void display_ast(Program *program, SymbolTable table) {
    writeln("\n\nAbstract Syntax Tree Output for program: " ~ program.name ~ "\n\n");
    foreach(Function* func; program.functions) {
        writeout_function(func, table);
    }
    writeln("End of program.");
}

void writeout_function(Function* func, SymbolTable table) {
    write("Function: '" ~ func.name ~ "'");
    if(func.arg_names.length == 0) {
        writeln(" does not take arguments.");
    } else {
        writeln(" takes following arguments: ");
        string[] arg_types = table.get_function_args(func.name);
        for(int i = 0; i < func.arg_names.length; i++) {
            write(func.arg_names[i], ", ");
            writeln("type: " ~ arg_types[i]);
        }
    }
    foreach(Statement* statement; func.stmts) {
        writeout_statements(statement, table);
    }
}

void writeout_statements(Statement* statement, SymbolTable table) {
    final switch(statement.stmt_type) {
        case StatementTypes.assign_statement:
            writeout_assignment_statement(statement);
            break;
        case StatementTypes.re_assign_statement:

            break;
        case StatementTypes.break_statement:

            break;
        case StatementTypes.return_statement:

            break;
        case StatementTypes.if_statement:

            break;
        case StatementTypes.else_statement:

            break;
        case StatementTypes.else_if_statement:

            break;
        case StatementTypes.while_statement:

            break;
        case StatementTypes.continue_statement:

            break;
        case StatementTypes.print_statement:
            writeout_print_statement(statement);
            break;
    }
}

void writeout_assignment_statement(Statement* statement) {
    write("var name: " ~ statement.name);
    write(", var type: " ~ statement.var_type);
    writeln(" value expression: ");
    writeout_expression(statement.syntax_tree, 0);
    writeln("end expression.");
}

void writeout_expression(Expression* expression, int depth) {
    int max_depth = max_depth(expression,depth);
    print_exp(expression, max_depth);
}


int max_depth(Expression* exp, int depth) {
    if(exp is null) {
        return --depth;
    }
    int ldepth = max_depth(exp.left, depth + 1);
    int rdepth = max_depth(exp.right, depth + 1);
    if(exp.args !is null) {
        foreach(Expression* arg; exp.args) {
            int arg_depth = max_depth(arg, depth + 1);
            if(arg_depth > ldepth) {
                ldepth = arg_depth;
            }
        }
    }
    if(ldepth > rdepth) {
        return ldepth;
    }
    return rdepth;
}

void print_exp(Expression* exp, int depth) {
    if(exp is null) {
        return;
    }
    print_exp(exp.left, depth - 1);
    for(int i = 0; i < depth; i++) {
        write(" ");
    }
    if(exp.args !is null) {
        writeln("Function call for fn ", exp.var_name);
        foreach(Expression* fn_exp; exp.args) {
            writeout_expression(fn_exp, depth);
        }
    } else {
        writeln(exp.var_name);
    }
    print_exp(exp.right, depth - 1);
}

void writeout_print_statement(Statement* statement) {
    
}