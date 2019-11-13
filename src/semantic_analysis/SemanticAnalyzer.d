module SemanticAnalyzer;

import structures;
import functions: Function;
import semantic_errors;
import NewSymbolTable;
import std.stdio;

class SemanticAnalyzer {

    private Function func;
    private Function[] program;

    public void semantic_analysis(Function[] program) {
        FuncRegistry reg = new FuncRegistry();

        this.program = program;
        int count_main = 0;
        string[] func_names;
        foreach(Function func; program) {
            if(is_program_entry_point(func.get_name())) {
                count_main++;
                check_for_args_in_main(func);
            }
            this.func = func;
            analyze();
            func_names ~= func.get_name();
        }
        if(count_main != 1) {
            missing_or_extra_mains();
        }
        check_for_duplicate_funcs(func_names);
        foreach(Function func; program) {
            reg.set_return_type(func.get_name(), func.get_return_type());
            reg.set_args(func.get_name(), func.get_arguments());
        }
        reg.lock();
        foreach(Function func; program) {
            func.set_registry(reg.clone());
        }
        
    }
    private:
    void analyze() {
        check_for_incorrect_variable_useage();
        bool in_loop = false;
        check_for_order_of_statements(func.get_statements(),0);
        check_for_return_in_else();
        type_check_variables(func.get_statements(), in_loop);
        
    }

    void check_for_order_of_statements(Statement*[] statements, int depth) {
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
                    check_for_order_of_statements(statements[i].stmts, depth + 1);  
                    break;
            }
        }
        if(statements !is null && statements.length > 0 && depth == 0) {
            check_last_statement(statements[statements.length - 1]);
        }
    }

    void check_last_statement(Statement* last) {
        if(last.stmt_type != StatementTypes.return_statement) {
            if(last.stmts is null || last.stmts.length < 1) {
                non_void_func_missing_returns();
            } else {
                check_last_statement(last.stmts[last.stmts.length - 1]);
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
            check_for_order_of_statements(statements[index].stmts, 1);
        }
    }

    void check_for_return_in_else() {
        int return_type = func.get_return_type();
        Statement*[] stmts = func.get_statements();
        if(stmts[stmts.length-1].stmt_type == StatementTypes.else_statement) {
            Statement*[] sub_stmts = stmts[stmts.length-1].stmts;
            if(sub_stmts[sub_stmts.length -1].stmt_type != StatementTypes.return_statement) {
                non_void_func_missing_returns();
            }
        } else if(stmts[stmts.length-1].stmt_type == StatementTypes.return_statement) {
            return;
        } else {
            if(is_program_entry_point(func.get_name())) {
                return;
            }
            non_void_func_missing_returns();
        }

    }

    void type_check_variables(Statement*[] stmts, bool in_loop) {
        foreach(Statement* statement; stmts) {
            switch(statement.stmt_type) {
                case StatementTypes.assign_statement:
                case StatementTypes.re_assign_statement:
                    check_assignment_ast(statement);
                    break;
                case StatementTypes.break_statement:
                case StatementTypes.continue_statement:
                    check_loop_escape_statement(statement, in_loop);
                    break;
                case StatementTypes.return_statement:
                    check_return_statement(statement);
                    break;
                case StatementTypes.while_statement:
                    check_loop_statement(statement, true);
                    break;
                case StatementTypes.if_statement:
                case StatementTypes.else_if_statement:
                    check_else_if_statement(statement, in_loop);
                    break;
                case StatementTypes.else_statement:
                    check_else_statement(statement, in_loop);
                    break;
                case StatementTypes.print_statement:
                    check_built_in_func_statement(statement);
                    break;
                default:
                    throw new Exception("INTERNAL ERROR: Unknown option in match_existing_scoped_variables");
            }
        }
    }

    void check_assignment_ast(Statement* statement) {
        int ast_value_type = resolve_ast_value_type(statement.syntax_tree, statement);
        if(statement.var_type != ast_value_type) {
            expressions_have_mismatching_types();
        }
        statement.syntax_tree.set_type(ast_value_type);
    }

    void check_loop_escape_statement(Statement* statement, bool in_loop) {
        statement.func_name = func.get_name();
        if(!in_loop) {
            loop_escape_not_in_loop();
        }
    }

    void check_return_statement(Statement* statement) {
        int ret_type = func.get_return_type();
        if(statement.syntax_tree is null) {
            return_statement_has_no_value();
        }
        int this_ret_type = resolve_ast_value_type(statement.syntax_tree, statement);
        check_expression_subtree_types(ret_type, this_ret_type);
    }

    void check_loop_statement(Statement* statement, bool in_loop) {
        int resolved_value = resolve_ast_value_type(statement.syntax_tree, statement);
        if(!resolves_to_bool_value(resolved_value)) {
            loop_args_do_not_resolve_to_bool_value();
        }
        type_check_variables(statement.stmts, in_loop);
        assert(statement.stmts !is null);
    }

    void check_if_statement(Statement* statement, bool in_loop) {
        int resolved_value = resolve_ast_value_type(statement.syntax_tree, statement);
        if(!resolves_to_bool_value(resolved_value)) {
            if_stmt_args_do_not_resolve_to_bool_value();
        }
        type_check_variables(statement.stmts, in_loop);
    }

    void check_else_if_statement(Statement* statement, bool in_loop) {
        check_if_statement(statement, in_loop);
    }

    void check_else_statement(Statement* statement, bool in_loop) {
        type_check_variables(statement.stmts, in_loop);
    }

    void check_built_in_func_statement(Statement* statement) {
        if(statement.built_in_args is null) {
            return;
        } else if(statement.built_in_args.length > 0) {
            foreach(Expression arg_tree; statement.built_in_args) {
                resolve_ast_value_type(arg_tree, statement);
            }
        }
    }

    int resolve_ast_value_type(Expression root, Statement* statement) {
        string current_type = null;
        if(root is null) {
            return -1;
        } else if(is_function_name(root.get_var_name())) {
            if(!is_leaf(root)) {
                throw new Exception("INTERNAL ERROR: Function call not a leaf node.");
            }
            root.exp_type = ExpTypes.FnCall;
            return resolve_function_call_values(root, statement);
        }
        
        if(root.args !is null) {
            call_to_non_existant_function();
        } else if(!func.is_declared_variable(root.get_var_name())) {
            if(!is_number(root.get_var_name())   &&
               !is_operator(root.get_var_name()) &&
               !is_boolean(root.get_var_name())) {
                undeclared_variables_in_expression();
            }
        } else if(is_variable_float(root.get_var_name())) {
            unsupported_type();
        } else if(!is_valid_variable(root.get_var_name())) {
            invalid_variable_in_expression();
        } else if(func.variable_in_expression_out_of_scope(root, statement)) {
            variable_in_expression_out_of_scope();
        }

        int left_type = resolve_ast_value_type(root.left, statement);
        int right_type = resolve_ast_value_type(root.right, statement);

        if(is_prefix_tree(root)) {
            check_expression_subtree_types(root.get_type(), right_type);
        } else if(is_subtree(root)) {
            check_expression_subtree_types(left_type, right_type);
            return root.get_type();
        } else if(is_leaf(root)) {
            return root.get_type();
        } else {
            throw new Exception("INTERNAL ERROR: Right is null, but not left.");
        }
        return root.get_type();
    }

    bool is_subtree(Expression current) {
        if(current.left !is null && current.right !is null) {
            if(!is_operator(current.get_var_name())) {
                throw new Exception("Non root node is not operator.");
            }
            return true;
        }
        return false;
    }

    bool is_leaf(Expression current) {
        return current.left is null && current.right is null;
    }

    bool is_prefix_tree(Expression current) {
        if(current.left is null && current.right !is null) {
            if(!is_prefix(current.get_var_name())) {
                throw new Exception("prefix node isn't a prefix.");
            }
            return true;
        }
        return false;
    }

    void check_expression_subtree_types(int left_type, int right_type) {
        if(left_type == right_type) {
            return;
        }
        expressions_have_mismatching_types();
    }

    int resolve_function_call_values(Expression func_call, Statement* statement) {
        string fn_name = func_call.get_var_name();
        if(is_program_entry_point(fn_name)) {
            calling_main();
        }

        Function other = get_function(fn_name);
        if(func_call.args.length != other.number_of_args()) {
            incorrect_number_of_args_to_function();
        }

        for(int i = 0; i < func_call.args.length; i++) {
            int type = resolve_ast_value_type(func_call.args[i], statement);
            if(type != other.get_arg_type(i)) {
                mismatching_function_argument();
            }
        }

        return other.get_return_type();
    }

    Function get_function(string name) {
        foreach(Function f; program) {
            if(f.get_name() == name) {
                return f;
            }
        }
        call_to_non_existant_function();
        assert(0);
    }

    bool is_function_name(string name) {
        foreach(Function f; program) {
            if(f.get_name() == name) {
                return true;
            }
        }
        return false;
    }

    bool resolves_to_bool_value(int resolved_ast_value) {
        return resolved_ast_value == PrimitiveTypes.Bool;
    }

    void check_for_duplicate_funcs(string[] func_names) {
        for(long i = 0; i < func_names.length; i++) {
            for(long j = i+1; j < func_names.length; j++) {
                if(i == j) {
                    continue;
                }
                if(func_names[i] == func_names[j]) {
                    duplicate_function_names();
                }
            }
        }
    }

    void check_for_args_in_main(Function func) {
        if(func.number_of_args() > 0) {
            main_has_args();
        }
    }

    void check_for_incorrect_variable_useage() {
        foreach(string variable; func.get_var_names()) {
            if(is_function_name(variable)) {
                variable_has_fn_name();
            }
            if(is_number(variable)) {
                assignment_to_constant();
            }
            if(is_keyword(variable)) {
                assignment_to_keyword();
            }
            if(!func.is_declared_variable(variable)) {
                undeclared_variables_in_reassignment();
            }
        }
        if(func.check_for_bad_instantiations()) {
            re_instantiation_of_variable();
        }
        if(func.check_for_bad_reassignments()) {
            undeclared_variables_in_reassignment();
        }
    }
}