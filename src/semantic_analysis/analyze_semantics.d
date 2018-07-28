module analyze_semantics;

import structures;
import symbol_table;
import semantic_errors;
import std.stdio: writeln;

struct visitor {
    Statement*[] statements;

}

void semantic_analysis(Program* program, ref SymbolTable table) {
    int count_main = 0;
    foreach(Function* func; program.functions) {
        if(table.is_program_entry_point(func.name)) {
            count_main++;
        }
        analyze(func, table);
    }
    if(count_main != 1) {
        missing_main();
    }
}

void analyze(Function* func, ref SymbolTable table) {
    bool in_loop = false;
    table.clear_local_variables();
    add_func_args_to_local_variable_table(func, table);
    check_for_order_of_statements(func.stmts);
    type_check_variables(func.name, func.stmts, table, in_loop);
}

void add_func_args_to_local_variable_table(Function* func, ref SymbolTable table) {
    string[] func_args = func.arg_names.dup;
    string[] arg_types = table.get_function_args(func.name);
    if(func_args.length != arg_types.length) {
        throw new Exception("Number of function variables is not the 
                            same as number of types for same function.");
    }
    for(int i = 0; i < func_args.length; i++) {
        table.add_local_variable(func_args[i], arg_types[i]);
    }
}

void check_for_order_of_statements(Statement*[] statements) {
    for(int i = 0; i < statements.length; i++) {
        switch(statements[i].stmt_type) {
            case StatementTypes.else_statement:
            case StatementTypes.else_if_statement:
                halt_if_orphaned_else(statements, i);
                break;
            case StatementTypes.break_statement:
            case StatementTypes.continue_statement:
                if(i < statements.length-1) {
                    loop_logic_creating_dead_code();
                }
                break;
            case StatementTypes.return_statement:
                validate_return_statement_location(statements, i);
                break; 
            default:
                check_for_order_of_statements(statements[i].stmts);  
                break;
        }
    }
}

void halt_if_orphaned_else(Statement*[] statements, int index) {
    if(index == 0) {
        orphaned_else_statement();
    }
    if(statements[index-1].stmt_type != StatementTypes.if_statement) {
        orphaned_else_statement();
    }
    if(statements[index-1].stmt_type != StatementTypes.else_if_statement) {
        orphaned_else_statement();
    }
}

void validate_return_statement_location(Statement*[] statements, int index) {
    if(index < statements.length-1) {
        return_creating_dead_code();
    } else if(statements[index].stmts.length > 0) {
        check_for_order_of_statements(statements[index].stmts);
    }
}

void type_check_variables
        (string fn_name, Statement*[] statements, ref SymbolTable table, bool in_loop) {
    foreach(Statement* statement; statements) {
        switch(statement.stmt_type) {
            case StatementTypes.assign_statement:
                check_assign_statement(statement, table);
                break;
            case StatementTypes.re_assign_statement:
                check_re_assign_statement(statement, table);
                break;
            case StatementTypes.break_statement:
            case StatementTypes.continue_statement:
                check_loop_escape_statement(in_loop);
                break;
            case StatementTypes.return_statement:
                check_return_statement(fn_name, statement, table);
                break;
            case StatementTypes.while_statement:
                check_loop_statement(fn_name, statement, table, in_loop);
                break;
            case StatementTypes.if_statement:
                check_if_statement(fn_name, statement, table, in_loop);
                break;
            case StatementTypes.else_if_statement:
                check_else_if_statement(fn_name, statement, table, in_loop);
                break;
            case StatementTypes.else_statement:
                check_else_statement(fn_name, statement, table, in_loop);
                break;
            case StatementTypes.print_statement:
                check_built_in_func_statement(statement, table);
                break;
            default:
                throw new Exception("Unknown option in match_existing_scoped_variables");
        }
    }
}

void check_assign_statement(Statement* statement, ref SymbolTable table) {
    check_for_bad_variable_useage(true, statement.name, table);
    check_assignment_ast(statement, table);
    table.add_local_variable(statement.name, statement.var_type);
}

void check_re_assign_statement(Statement* statement, ref SymbolTable table) {
    check_for_bad_variable_useage(false, statement.name, table);
    check_assignment_ast(statement, table);
}

void check_assignment_ast(Statement* statement, ref SymbolTable table) {
    string ast_value_type = resolve_ast_value_type(statement.syntax_tree, table);
    if(statement.var_type != ast_value_type) {
        variable_type_mismatch();
    } 
}

void check_for_bad_variable_useage(bool is_new, string variable, ref SymbolTable table) {
    if(table.is_declared_variable(variable)) {
        if(is_new) {
            re_instantiation_of_variable();
        }
    }
    if(table.is_function_name(variable)) {
        variable_has_fn_name();
    }
    if(table.is_number(variable)) {
        assignment_to_constant();
    }
    if(table.is_keyword(variable)) {
        assignment_to_keyword();
    }
}

void check_loop_escape_statement(bool in_loop) {
    if(!in_loop) {
        loop_escape_not_in_loop();
    }
}

void check_return_statement(string fn_name, Statement* statement, ref SymbolTable table) {
    string ret_type = table.get_return_type(fn_name);
    if(statement.syntax_tree is null) {
        if(table.is_void(ret_type)) {
            return;
        } else {
            return_statement_has_no_value();
        }
    } else if(table.is_void(ret_type)) {
        returning_values_in_void_function();
    }
    string this_ret_type = resolve_ast_value_type(statement.syntax_tree, table);
    compare_types(ret_type, this_ret_type, table);
}

void check_loop_statement(string fn_name, Statement* statement, ref SymbolTable table, bool in_loop) {
    if(!table.resolves_to_bool_value(resolve_ast_value_type(statement.syntax_tree, table))) {
        loop_args_do_not_resolve_to_bool_value();
    }
    table.scope_level_one_level_deeper();
    type_check_variables(fn_name, statement.stmts, table, in_loop);
    table.scope_level_one_level_shallower();
}

void check_if_statement(string fn_name, Statement* statement, ref SymbolTable table, bool in_loop) {
    if(!table.resolves_to_bool_value(resolve_ast_value_type(statement.syntax_tree, table))) {
        if_stmt_args_do_not_resolve_to_bool_value();
    }
    table.scope_level_one_level_deeper();
    type_check_variables(fn_name, statement.stmts, table, in_loop);
    table.scope_level_one_level_shallower();
}

void check_else_if_statement(string fn_name, Statement* statement, ref SymbolTable table, bool in_loop) {
    check_if_statement(fn_name, statement.stmts[0], table, in_loop);
}

void check_else_statement(string fn_name, Statement* statement, ref SymbolTable table, bool in_loop) {
    table.scope_level_one_level_deeper();
    type_check_variables(fn_name, statement.stmts, table, in_loop);
    table.scope_level_one_level_shallower();
}

void check_built_in_func_statement(Statement* statement, ref SymbolTable table) {
    if(statement.syntax_tree.args.length > 0) {
        resolve_function_call_values(statement.syntax_tree, table);
    }
}

string resolve_ast_value_type(Expression* root, ref SymbolTable table) {
    string current_type = null;
    if(root is null) {
        return null;
    } else if(table.is_function_name(root.var_name)) {
        current_type = resolve_function_call_values(root, table);
    } else if(root.args !is null) {
        invalid_func_call();
    } else {
        current_type = root.var_name;
    }
    string left_type = resolve_ast_value_type(root.left, table);
    string right_type = resolve_ast_value_type(root.right, table);

    compare_types(left_type, right_type, table);
    compare_types(current_type, left_type, table);
    compare_types(current_type, right_type, table);
    return current_type;
}

string resolve_function_call_values(Expression* func_call, ref SymbolTable table) {
    // return type is stored in table
    return null;
}

void compare_types(string left_type, string right_type, ref SymbolTable table) {
    return;
}