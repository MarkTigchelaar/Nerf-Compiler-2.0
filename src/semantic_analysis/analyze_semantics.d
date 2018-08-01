module analyze_semantics;

import structures;
import symbol_table;
import semantic_errors;
alias Tble = SymbolTable;

void semantic_analysis(Program* program, ref Tble table) {
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

void analyze(Function* func, ref Tble table) {
    bool in_loop = false;
    table.clear_local_variables();
    add_func_args_to_local_variable_table(func, table);
    check_for_order_of_statements(func.stmts);
    check_for_return_in_else(func, table);
    type_check_variables(func.name, func.stmts, table, in_loop);
}

void add_func_args_to_local_variable_table(Function* func, ref Tble table) {
    string[] func_args = func.arg_names.dup;

    string[] arg_types = table.get_function_args(func.name);
    if(table.is_program_entry_point(func.name)) {
        if(arg_types.length > 0) {
            main_has_args();
        }
    }
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
    if(statements[index-1].stmt_type == StatementTypes.if_statement) {
        return;
    }
    if(statements[index-1].stmt_type == StatementTypes.else_if_statement) {
        return;
    }
    orphaned_else_statement();
}

void validate_return_statement_location(Statement*[] statements, int index) {
    if(index < statements.length-1) {
        return_creating_dead_code();
    } else if(statements[index].stmts.length > 0) {
        check_for_order_of_statements(statements[index].stmts);
    }
}

void check_for_return_in_else(Function* func, ref Tble table) {
    string return_type = table.get_return_type(func.name);
    if(table.is_void(return_type)) {
        return;
    }
    if(func.stmts[func.stmts.length-1].stmt_type == StatementTypes.else_statement) {
        Statement*[] sub_stmts = func.stmts[func.stmts.length-1].stmts;
        if(sub_stmts[sub_stmts.length -1].stmt_type != StatementTypes.return_statement) {
            non_void_func_missing_returns();
        }
    } else if(func.stmts[func.stmts.length-1].stmt_type == StatementTypes.return_statement) {
        return;
    } else {
        non_void_func_missing_returns();
    }

}

void type_check_variables
        (string fn_name, Statement*[] statements, ref Tble table, bool in_loop) {
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
                check_loop_statement(fn_name, statement, table, true);
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

void check_assign_statement(Statement* statement, ref Tble table) {
    check_for_bad_variable_useage(true, statement.name, table);
    check_assignment_ast(statement, table);
    table.add_local_variable(statement.name, statement.var_type);
}

void check_re_assign_statement(Statement* statement, ref Tble table) {
    check_for_bad_variable_useage(false, statement.name, table);
    check_assignment_ast(statement, table);
}

void check_assignment_ast(Statement* statement, ref Tble table) {
    string ast_value_type = resolve_ast_value_type(statement.syntax_tree, table);
    if(statement.var_type != ast_value_type) {
        if(table.get_local_variable_type(statement.name) != ast_value_type) {
            variable_type_mismatch();
        }
    } 
}

void check_for_bad_variable_useage(bool is_new, string variable, ref Tble table) {
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

void check_return_statement(string fn_name, Statement* statement, ref Tble table) {
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
    resolve_normal_tree(ret_type, this_ret_type, table, false);
}

void check_loop_statement(string fn_name, Statement* statement, ref Tble table, bool in_loop) {
    if(!table.resolves_to_bool_value(resolve_ast_value_type(statement.syntax_tree, table))) {
        loop_args_do_not_resolve_to_bool_value();
    }
    table.scope_level_one_level_deeper();
    type_check_variables(fn_name, statement.stmts, table, in_loop);
    table.scope_level_one_level_shallower();
}

void check_if_statement(string fn_name, Statement* statement, ref Tble table, bool in_loop) {
    if(!table.resolves_to_bool_value(resolve_ast_value_type(statement.syntax_tree, table))) {
        if_stmt_args_do_not_resolve_to_bool_value();
    }
    table.scope_level_one_level_deeper();
    type_check_variables(fn_name, statement.stmts, table, in_loop);
    table.scope_level_one_level_shallower();
}

void check_else_if_statement(string fn_name, Statement* statement, ref Tble table, bool in_loop) {
    check_if_statement(fn_name, statement.stmts[0], table, in_loop);
}

void check_else_statement(string fn_name, Statement* statement, ref Tble table, bool in_loop) {
    table.scope_level_one_level_deeper();
    type_check_variables(fn_name, statement.stmts, table, in_loop);
    table.scope_level_one_level_shallower();
}

void check_built_in_func_statement(Statement* statement, ref Tble table) {
    if(statement.syntax_tree.args.length > 0) {
        foreach(Expression* arg_tree; statement.syntax_tree.args) {
            resolve_ast_value_type(arg_tree, table);
        }
    }
}

string resolve_ast_value_type(Expression* root, ref Tble table) {
    string current_type = null;
    if(root is null) {
        return null;
    } else if(table.is_function_name(root.var_name)) {
        if(!is_leaf(root)) {
            throw new Exception("Function call not a leaf node.");
        }
        return resolve_function_call_values(root, table);
    } else if(root.args !is null) {
        call_to_non_existant_function();
    } else if(!table.is_declared_variable(root.var_name)) {
        if(!table.is_number(root.var_name) &&
           !table.is_operator(root.var_name) &&
           !table.is_boolean(root.var_name)) {
            undeclared_variables_in_expression();
        }
    }
    string left_type = resolve_ast_value_type(root.left, table);
    string right_type = resolve_ast_value_type(root.right, table);

    if(is_prefix_tree(root, table)) {
        return resolve_normal_tree(root.var_name, right_type, table,false);
    } else if(is_subtree(root, table)) {
        string new_current_type = resolve_normal_tree(left_type, right_type, table, false);
        return resolve_normal_tree(root.var_name, new_current_type, table, true);
    } else if(is_leaf(root)) {
        return resolve_variable_or_constant(root.var_name, table);
    } else {
        throw new Exception("Right is null, but not left.");
    }
}

bool is_subtree(Expression* current, ref Tble table) {
    if(current.left !is null && current.right !is null) {
        if(!table.is_operator(current.var_name)) {
            throw new Exception("Non root node is not operator.");
        }
        return true;
    }
    return false;
}

bool is_leaf(Expression* current) {
    return current.left is null && current.right is null;
}

bool is_prefix_tree(Expression* current, ref Tble table) {
    if(current.left is null && current.right !is null) {
        if(!table.is_prefix(current.var_name)) {
            throw new Exception("prefix node isn't a prefix.");
        }
        return true;
    }
    return false;
}

string resolve_normal_tree(string left_type, string right_type, ref Tble table, bool cmp_root) {
    if(table.resolves_to_bool_value(left_type) && table.resolves_to_bool_value(right_type)) {
        return table.get_bool();
    }
    if(table.resolves_to_int(left_type) && table.resolves_to_int(right_type)) {
        return table.get_int();
    }
    if(table.resolves_to_float(left_type) && table.resolves_to_float(right_type)) {
        return table.get_float();
    }
    if(cmp_root) {
        if(table.resolves_to_bool_value(left_type) && table.resolves_to_int(right_type)) {
            return table.get_bool();
        }
        if(table.resolves_to_bool_value(left_type) && table.resolves_to_float(right_type)) {
            return table.get_bool();
        }
    }
    expressions_have_mismatching_types();
    return null;
}

string resolve_variable_or_constant(string leaf, ref Tble table) {
    if(table.resolves_to_bool_value(leaf)) {
        return table.get_bool();
    }
    if(table.resolves_to_int(leaf)) {
        return table.get_int();
    }
    if(table.resolves_to_float(leaf)) {
        return table.get_float();
    }
    throw new Exception("leaf node is of unknown type.");
}

string resolve_function_call_values(Expression* func_call, ref Tble table) {
    string fn_name = func_call.var_name;
    if(table.is_program_entry_point(fn_name)) {
        calling_main();
    }
    ulong num_args = func_call.args.length;
    string[] func_arg_types = table.get_function_args(fn_name);
    if(num_args != func_arg_types.length) {
        incorrect_number_of_args_to_function();
    }
    for(ulong i = 0; i < num_args; i++) {
        string type = resolve_ast_value_type(func_call.args[i], table);
        if(type != func_arg_types[i]) {
            mismatching_function_argument();
        }
    }
    string ret_type = table.get_return_type(fn_name);
    return ret_type;
}