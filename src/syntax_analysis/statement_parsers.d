module statement_parsers;

import structures: Statement, Expression, StatementTypes;
import symbol_table;
import variable_assign_errors;
import expression_parsers;
import general_syntax_errors;
import scoped_token_collector;
import std.stdio: writeln;

Statement*[] parse_statements(string[] func_body, ref SymbolTable table) {
    Statement*[] fn_statements;
    for(int mutating_index = 0; mutating_index < func_body.length; mutating_index++) {
        fn_statements ~= parse_statement_type(table, func_body, &mutating_index);
    } return fn_statements;
}

private:
Statement* parse_statement_type(ref SymbolTable table, string[] func_body, int* index) {
    if(table.is_primitive_type(func_body[*index])) {
        return parse_assign_statement(table, func_body, index);
    }
    if(table.is_if(func_body[*index])) {
        return parse_if_statement(table, func_body, index);
    }
    if(table.is_else(func_body[*index])) {
        return parse_else_statement(table, func_body, index);
    }
    if(table.is_while(func_body[*index])) {
        return parse_while_statement(table, func_body, index);
    }
    if(table.is_break(func_body[*index])) {
        return parse_break_statement(table, func_body, index);
    }
    if(table.is_continue(func_body[*index])) {
        return parse_continue_statement(table, func_body, index);
    }
    if(table.is_return(func_body[*index])) {
        return parse_return_statement(table, func_body, index);
    }
    if(table.is_valid_variable(func_body[*index])) {
        return parse_re_assign_statement(table, func_body, index, null);
    }
    if(table.is_assignment(func_body[*index])) {
        missing_identifier();
    }
    if(!table.is_valid_variable(func_body[*index])) {
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
    string assign = get_token(func_body, index);
    if(!table.is_assignment(assign)) {
        string possible_assign = get_token(func_body, index);
        check_assignment(table, possible_assign);
    }
    string[] rvalues = get_r_value_tokens(table,func_body, index);
    Statement* statement = new Statement(StatementTypes.assign_statement,
                                         false, type, identifier);
    if(rvalues !is null) {
        statement.syntax_tree = parse_expressions(table, rvalues.dup);
    }
    return statement;
}

Statement* parse_if_statement(ref SymbolTable table, string[] func_body, int* index) {
    return null;
}

Statement* parse_else_statement(ref SymbolTable table, string[] func_body, int* index) {
    return null;
}

Statement* parse_while_statement(ref SymbolTable table, string[] func_body, int* index) {
    return null;
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
    if(!table.is_terminator(func_body[*index])) {
        statement_not_terminated();
    }
    return new Statement(type, false, null, null);
}

Statement* parse_return_statement(ref SymbolTable table, string[] func_body, int* index) {
    (*index)++;
    string[] return_results = get_r_value_tokens(table,func_body, index);
    auto ret_statement = new Statement(StatementTypes.return_statement, false);
    if(return_results !is null) {
        ret_statement.syntax_tree = parse_expressions(table, return_results.dup);
    }
    return ret_statement;
}

string get_token(string[] func_body, int* index)  {
    if(*index >= func_body.length) {
        invalid_statement();
    }
    string token = func_body[*index];
    (*index)++;
    return token;
}

string[] get_r_value_tokens(ref SymbolTable table, string[] func_body, int* index) {
    string[] rvalues;
    bool hit_terminator = false;
    for(; *index < func_body.length; (*index)++) {
        if(table.is_terminator(func_body[*index])) {
            hit_terminator = true;
            break;
        } else {
            rvalues ~= func_body[*index];
        }
    }
    if(!hit_terminator) {
        statement_not_terminated();
    }
    return rvalues;
}

void check_identifier(SymbolTable table, string identifier) {
    if(!table.is_valid_variable(identifier)) {
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

void check_assignment(SymbolTable table, string possible_assign) {
    if(table.is_assignment(possible_assign)) {
        invalid_misspelt_type();
    } else {
        missing_assignment_operator();
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
    assert(s.has_args == false);
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["return", ";"]; 
    int index = 0;
    Statement* s = parse_statement_type(table, expression, &index);
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.return_statement);
    assert(s.has_args == false);    
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["break", ";"]; 
    int index = 0;
    Statement* s = parse_statement_type(table, expression, &index);
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.break_statement);
    assert(s.has_args == false);    
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["continue", ";"]; 
    int index = 0;
    Statement* s = parse_statement_type(table, expression, &index);
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.continue_statement);
    assert(s.has_args == false);    
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
    assert(s[0].has_args == false);
    assert(s[1].stmt_type == StatementTypes.return_statement);
    assert(s[1].has_args == false);
}