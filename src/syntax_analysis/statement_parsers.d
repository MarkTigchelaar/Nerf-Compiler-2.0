module statement_parsers;

import structures: Statement, Expression, StatementTypes;
import symbol_table;
import variable_assign_errors;
import expression_parsers;
import general_syntax_errors;
import branching_logic_errors;
import scoped_token_collector;
import get_token: get_token, collect_scoped_tokens, current_token;

Statement*[] parse_statements(string[] func_body, ref SymbolTable table) {
    Statement*[] fn_statements;
    for(int mutating_index = 0; mutating_index < func_body.length; mutating_index++) {
        fn_statements ~= parse_statement_type(table, func_body, &mutating_index);
        
    } return fn_statements;
}

private:
Statement* parse_statement_type(ref SymbolTable table, string[] func_body, int* index) {
    if(table.is_primitive_type(current_token(func_body, index))) {
        return parse_assign_statement(table, func_body, index);
    }
    if(table.is_if(current_token(func_body, index))) {
        return parse_if_statement(table, func_body, index);
    }
    if(table.is_else(current_token(func_body, index))) {
        return parse_else_statement(table, func_body, index);
    }
    if(table.is_while(current_token(func_body, index))) {
        return parse_while_statement(table, func_body, index);
    }
    if(table.is_break(current_token(func_body, index))) {
        return parse_break_statement(table, func_body, index);
    }
    if(table.is_continue(current_token(func_body, index))) {
        return parse_continue_statement(table, func_body, index);
    }
    if(table.is_return(current_token(func_body, index))) {
        return parse_return_statement(table, func_body, index);
    }
    if(table.is_valid_variable(current_token(func_body, index))) {
        return parse_re_assign_statement(table, func_body, index, null);
    }
    if(table.is_print(current_token(func_body, index))) {
        return parse_print_statement(table, func_body, index);
    }
    if(table.is_assignment(current_token(func_body, index))) {
        missing_identifier();
    }
    if(!table.is_valid_variable(current_token(func_body, index))) {
        if(table.is_seperator(current_token(func_body, index))) {
            invalid_statement();
        }
        invalid_l_value();
    }
    invalid_statement();
    return null;
}

Statement* parse_assign_statement(ref SymbolTable table, string[] func_body, int* index) {
    string type = get_token(func_body, index);
    return parse_re_assign_statement(table, func_body, index, type);
}

Statement* parse_re_assign_statement(ref SymbolTable table, string[] func_body,
                                     int* index, string type) {
    string identifier = get_token(func_body, index);
    check_identifier(table, identifier);
    check_assignment(table, func_body, index);
    string[] rvalues = get_r_value_tokens(table,func_body, index);
    Statement* statement = new Statement(get_statement_type(type),type, identifier);
    if(rvalues !is null) {
        statement.syntax_tree = parse_expressions(table, rvalues.dup);
    }
    return statement;
}

Statement* parse_else_statement(ref SymbolTable table, string[] func_body, int* index) {
    (*index)++;
    string if_or_curly_bracket = current_token(func_body, index);
    Statement* else_stmt;
    if(table.is_if(if_or_curly_bracket)) {
        else_stmt = new Statement(StatementTypes.else_if_statement);
        else_stmt.stmts ~= parse_branch_logic(table, func_body, index, StatementTypes.else_if_statement);
    } else if(table.is_open_curly_brace(if_or_curly_bracket)) {
        else_stmt = new Statement(StatementTypes.else_statement);
        string[] stmt_body = collect_scoped_tokens(table, func_body, index);
        check_lengths([","], stmt_body);
        else_stmt.stmts = parse_statements(stmt_body.dup, table);
        (*index)--;
    } else {
        invalid_branching_logic_scope_token();
    }
    
    return else_stmt;
}

Statement* parse_if_statement(ref SymbolTable table, string[] func_body, int* index) {
    return parse_branch_logic(table, func_body,index, StatementTypes.if_statement);
}

Statement* parse_while_statement(ref SymbolTable table, string[] func_body, int* index) {
    return parse_branch_logic(table, func_body,index, StatementTypes.while_statement);
}

Statement* parse_branch_logic(ref SymbolTable table, string[] func_body, int* index, int type) {
    (*index)++;
    string[] args = get_statement_args(table, func_body, index);
    string[] stmt_body = get_statment_body(table, func_body, index);
    check_lengths(args, stmt_body);
    Statement* branch = new Statement(type);
    branch.syntax_tree = parse_expressions(table, args);
    branch.stmts = parse_statements(stmt_body.dup, table);
    (*index)--;
    return branch;
}

string[] get_statement_args(ref SymbolTable table, string[] func_body, int* index) {
    if(table.is_open_paren(current_token(func_body, index))) {
        return collect_scoped_tokens(table, func_body, index);
    } else {
        invalid_args_token();
    }
    return null;
}

string[] get_statment_body(ref SymbolTable table, string[] func_body, int* index) {
    string curly_bracket = get_token(func_body, index);
    if(table.is_open_curly_brace(curly_bracket)) {
        (*index)--;
        return collect_scoped_tokens(table, func_body, index);
    } else {
        invalid_branching_logic_scope_token();
    }
    return null;
}

void check_lengths(string[] args, string[] stmt_body) {
    if(args is null || args.length == 0) {
        empty_conditional();
    } else if(stmt_body is null || stmt_body.length == 0) {
        empty_statement_body();
    }
}

Statement* parse_break_statement(ref SymbolTable table, string[] func_body, int* index) {
    return break_continue_statement(table,func_body,index,StatementTypes.break_statement);
}

Statement* parse_continue_statement(ref SymbolTable table, string[] func_body, int* index) {
    return break_continue_statement(table,func_body,index,StatementTypes.continue_statement);
}

Statement* break_continue_statement(ref SymbolTable table, string[] func_body,
                                    int* index, int type) {
    (*index)++;
    if(!table.is_terminator(current_token(func_body, index))) {
        statement_not_terminated();
    }
    return new Statement(type, null, null);
}

Statement* parse_return_statement(ref SymbolTable table, string[] func_body, int* index) {
    (*index)++;
    string[] return_results = get_r_value_tokens(table,func_body, index);
    auto ret_statement = new Statement(StatementTypes.return_statement);
    if(return_results !is null) {
        ret_statement.syntax_tree = parse_expressions(table, return_results.dup);
    }
    return ret_statement;
}

Statement* parse_print_statement(ref SymbolTable table, string[] func_body, int* index) {
    string fn_name = current_token(func_body, index);
    (*index)++;
    string[] args = get_statement_args(table, func_body, index);
    Statement* print_statement = new Statement(StatementTypes.print_statement);
    Expression* arg_tree = new Expression(fn_name);
    arg_tree.args = parse_func_call_arg_expressions(table, args.dup);
    print_statement.syntax_tree = arg_tree;
    if(!table.is_terminator(current_token(func_body, index))) {
        statement_not_terminated();
    }
    return print_statement;
}

string[] get_r_value_tokens(ref SymbolTable table, string[] func_body, int* index) {
    string[] rvalues = null;
    bool hit_terminator = false;
    for(; *index < func_body.length; (*index)++) {
        if(table.is_terminator(current_token(func_body, index))) {
            hit_terminator = true;
            break;
        } else {
            rvalues ~= current_token(func_body, index);
        }
    }
    if(!hit_terminator) {
        statement_not_terminated();
    }
    return rvalues;
}

void check_identifier(ref SymbolTable table, string identifier) {
    if(identifier is null) {
        invalid_statement();
    } else if(!table.is_valid_variable(identifier)) {
        if(table.is_assignment(identifier)) {
            missing_identifier();
        } else if(table.is_number(identifier)) {
            assignment_to_constant();
        } else if(table.is_terminator(identifier)) {
            invalid_statement();
        } else {
            invalid_l_value();
        }
    }
}

void check_assignment(ref SymbolTable table, string[] func_body, int* index) {
    string assign = get_token(func_body, index);
    if(table.is_assignment(assign)) {
        return;
    }
    string possible_assign = get_token(func_body, index);
    if(possible_assign is null) {
        invalid_statement();
    } else if(table.is_assignment(possible_assign)) {
        invalid_misspelt_type();
    } else {
        missing_assignment_operator();
    }
}

int get_statement_type(string type) {
    if(type !is null) {
        return StatementTypes.assign_statement;
    } else {
        return StatementTypes.re_assign_statement;
    }
}





unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["a", "+", "b", "==", "c", ";"];
    int index = 0;
    string[] result = get_r_value_tokens(table, expression, &index);
    assert(result.length == 5);
    assert(index == 5);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] statement = ["bool", "test", ":=", "a", "+", "b", "==", "c", ";"]; 
    int index = 0;
    Statement* s = parse_statement_type(table, statement, &index);
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.assign_statement);
    assert(s.var_type == "bool");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["return", ";"]; 
    int index = 0;
    Statement* s = parse_statement_type(table, expression, &index);
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.return_statement);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["break", ";"]; 
    int index = 0;
    Statement* s = parse_statement_type(table, expression, &index);
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.break_statement);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["continue", ";"]; 
    int index = 0;
    Statement* s = parse_statement_type(table, expression, &index);
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.continue_statement);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] statement = ["bool", "test", ":=", "a", "+", "b",
                           "==", "c", ";", "return", ";"];
    Statement*[] s = parse_statements(statement, table);
    assert(s !is null);
    assert(s.length == 2);
    assert(s[0].stmt_type == StatementTypes.assign_statement);
    assert(s[0].var_type == "bool");
    assert(s[1].stmt_type == StatementTypes.return_statement);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] statement = ["test", ":=", "a", "+", "b",
                           "==", "c", ";"];
    Statement*[] s = parse_statements(statement, table);
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.re_assign_statement);
    assert(s[0].var_type is null);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] statement = ["if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", ";", "}"];
    Statement*[] s = parse_statements(statement, table);
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.if_statement);
    assert(s[0].var_type is null);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0].stmt_type == StatementTypes.return_statement);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] statement = ["while","(", "True",")", "{","if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", ";", "}","}"];
    Statement*[] s = parse_statements(statement, table);
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.while_statement);
    assert(s[0].var_type is null);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0].stmt_type == StatementTypes.if_statement);
    assert(s[0].stmts[0].stmts !is null);
    assert(s[0].stmts[0].stmts.length == 1);
    assert(s[0].stmts[0].stmts[0].stmt_type == StatementTypes.return_statement);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] statement = ["else", "if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", ";", "}"];
    Statement*[] s = parse_statements(statement, table);
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.else_if_statement);
    assert(s[0].var_type is null);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0].stmt_type == StatementTypes.else_if_statement);
    assert(s[0].stmts[0].stmts[0] !is null);
    assert(s[0].stmts[0].stmts[0].stmt_type == StatementTypes.return_statement);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] statement = ["int", "a", ":=", "2", ";"];
    Statement*[] s = parse_statements(statement, table);
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.assign_statement); 
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] statement = ["a", ":=", "2", ";"];
    Statement*[] s = parse_statements(statement, table);
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.re_assign_statement); 
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] statement = ["else", "{", "return", ";", "}"];
    Statement*[] s = parse_statements(statement, table);
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.else_statement);
    assert(s[0].var_type is null);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0].stmt_type == StatementTypes.return_statement);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] statement = ["if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", ";", "}",
                           "else", "{", "return", ";", "}"];
    Statement*[] s = parse_statements(statement, table);
    assert(s !is null);
    assert(s.length == 2);
    assert(s[0].stmt_type == StatementTypes.if_statement);
    assert(s[0].var_type is null);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0].stmt_type == StatementTypes.return_statement);
    assert(s[1].stmts !is null);
    assert(s[1].stmts[0].stmt_type == StatementTypes.return_statement);
    assert(s[1].stmt_type == StatementTypes.else_statement);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] statement = ["if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", ";", "}",
                           "else", "if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", ";", "}",
                           "else", "{", "return", ";", "}"];
    Statement*[] s = parse_statements(statement, table);
    assert(s !is null);
    assert(s.length == 3);
    assert(s[0].stmt_type == StatementTypes.if_statement);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0].stmt_type == StatementTypes.return_statement);

    assert(s[1].stmt_type == StatementTypes.else_if_statement);
    assert(s[1].var_type is null);
    assert(s[1].stmts !is null);
    assert(s[1].stmts.length == 1);
    assert(s[1].stmts[0].stmt_type == StatementTypes.else_if_statement);
    assert(s[1].stmts[0].stmts !is null);
    assert(s[1].stmts[0].stmts.length == 1);
    assert(s[1].stmts[0].stmts[0].stmt_type == StatementTypes.return_statement);
}