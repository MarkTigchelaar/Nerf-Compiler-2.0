module expression_parsers;

import symbol_table;
import structures: Expression;
import expression_errors;
import get_token: get_token, collect_scoped_tokens, current_token;
import scoped_token_collector;
import std.stdio;

void main() {
    writeln("Done");
    SymbolTable table = new SymbolTable;
    Expression* a = parse_expressions(table, ["a"]);
}

Expression*[] parse_func_call_arg_expressions(SymbolTable table, string[] rvalues) {
    Expression*[] func_args;
    string[] expressions;
    foreach(int i, string str; rvalues) {
        if(table.is_comma(str)) {
            if(i == rvalues.length -1) {
                missing_arg_from_call();
            } else if(expressions.length == 0) {
                missing_arg_from_call();
            }
            func_args ~= parse_expressions(table, expressions);
            expressions = null;
        } else {
            expressions ~= str;
        }
    }
    return func_args;
}

Expression* parse_expressions(ref SymbolTable table, string[] rvalues) {
    if(rvalues is null || rvalues.length == 0) {
        return null;
    }
    check_last_index(table, rvalues);
    int index = 0;
    return build_ast(table, rvalues, 0, &index);
}

Expression* build_ast(ref SymbolTable table, string[] exptokens, int rank, int* index) {
    Expression* left = prefix_func_switchboard(table, exptokens, index);
    while(rank < precedenceOfNextToken(table,exptokens, index)) {
        left = infix_func_switchboard(table, left, exptokens, index);
    }   return left;
}

int precedenceOfNextToken(ref SymbolTable table, string[] exptokens, int* index) {
    if((*index) + 1 >= exptokens.length) {
        return 0;
    }
    return table.token_precedence(current_token(exptokens, index));
}

Expression* prefix_func_switchboard(ref SymbolTable table, string[] exptokens, int* index) {
    Expression* prefix;
    if(table.is_open_paren(current_token(exptokens, index))) {
        prefix = paren_parser(table, exptokens, index);
    } else if(table.is_prefix(current_token(exptokens, index))) {
        return prefix_ops_parser(table, exptokens, index);
    } else if(table.is_valid_variable(current_token(exptokens, index))) {
        prefix = variable_or_const_parser(table, exptokens, index);
    } else if(table.is_boolean(current_token(exptokens, index))) {
        prefix = variable_or_const_parser(table, exptokens, index);
    } else if(table.is_number(current_token(exptokens, index))) {
        prefix = variable_or_const_parser(table, exptokens, index);
    } else { 
        invalid_expression_token();
    }
    return prefix;
}


Expression* paren_parser(ref SymbolTable table, string[] exptokens, int* index) {
    string[] sub_expression = collect_scoped_tokens(table, exptokens, index);
    if(sub_expression.length < 1) {
        empty_parens();
    }
    int new_index;
    return build_ast(table, sub_expression, 0, &new_index);
}

Expression* prefix_ops_parser(ref SymbolTable table, string[] exptokens, int* index) {
    Expression* current = new Expression(current_token(exptokens, index));
    int rank = table.prefix_precedence(get_token(exptokens, index));
    Expression* right = build_ast(table, exptokens, rank, index);
    if(table.is_minus(current.var_name) && table.is_minus(right.var_name)) {
        multiple_minus_signs();
    }
    current.right = right;
    return current;
}

Expression* infix_func_switchboard(ref SymbolTable table, Expression* left,
                                    string[] exptokens, int* index) {
    Expression* infix;
    if(table.is_math_op(current_token(exptokens, index))) {
        infix = operator_parser(table, left, exptokens, index);
    } else if(table.is_bool_compare(current_token(exptokens, index))) {
        infix = operator_parser(table, left, exptokens, index);
    } else if(table.is_bool_operator(current_token(exptokens, index))) {
        infix = operator_parser(table, left, exptokens, index);
    } else if(table.is_open_paren(current_token(exptokens, index))) {
        infix = func_call_parser(table, left, exptokens, index);
    } else {
        invalid_expression_token();
    }
    return infix;
}

Expression* operator_parser(ref SymbolTable table, Expression* left, string[] exptokens, int* index) {
    int rank_reduce = 0;
    if(table.is_right_associative(current_token(exptokens,index))) {
        rank_reduce = 1;
    }
    int rank = table.token_precedence(current_token(exptokens,index));
    Expression* current = new Expression(get_token(exptokens,index));
    Expression* right = build_ast(table, exptokens, rank - rank_reduce, index);
    current.right = right;
    current.left = left;
    return current;
}

Expression* func_call_parser(ref SymbolTable table, Expression* left, string[] exptokens, int* index) {
    string[] call_args = collect_scoped_tokens(table, exptokens, index);
    left.args = parse_func_call_arg_expressions(table,call_args);
    return left;
}

Expression* variable_or_const_parser(ref SymbolTable table, string[] exptokens, int* index) {
    return new Expression(get_token(exptokens, index));
}


void check_last_index(ref SymbolTable table, string[] rvalues) {
    if(table.is_valid_variable(rvalues[rvalues.length - 1])) {
        return;
    }
    if(table.is_number(rvalues[rvalues.length - 1])) {
        return;
    }
    if(table.is_return(rvalues[rvalues.length - 1])) {
        return;
    }
    if(table.is_break(rvalues[rvalues.length - 1])) {
        return;
    }
    if(table.is_continue(rvalues[rvalues.length - 1])) {
        return;
    }
    if(table.is_boolean(rvalues[rvalues.length - 1])) {
        return;
    }
    if(table.is_close_paren(rvalues[rvalues.length - 1])) {
        return;
    }
    invalid_expression();
}





unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["True"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right is null);
    assert(result.var_name == "True");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["False"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right is null);
    assert(result.var_name == "False");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["3.8"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right is null);
    assert(result.var_name == "3.8");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["38"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right is null);
    assert(result.var_name == "38");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["(", "38", ")"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right is null);
    assert(result.var_name == "38");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["-", "38"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right !is null);
    assert(result.var_name == "-");
    assert(result.right.var_name == "38");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["(", "-", "38", ")"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right !is null);
    assert(result.var_name == "-");
    assert(result.right.var_name == "38");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["-", "(", "38", ")"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right !is null);
    assert(result.var_name == "-");
    assert(result.right.var_name == "38");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["a", "+", "b"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.var_name == "+");
    assert(result.left !is null);
    assert(result.right !is null);
    assert(result.right.var_name == "b");
    assert(result.left.var_name == "a");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["a", "+", "b", "==", "c"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.var_name == "==");
    assert(result.left !is null);
    assert(result.right !is null);
    assert(result.right.var_name == "c");
    assert(result.left.var_name == "+");
    Expression* leftexp = result.left;
    assert(leftexp.left !is null);
    assert(leftexp.right !is null);
    assert(leftexp.right.var_name == "b");
    assert(leftexp.left.var_name == "a");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["a", "^", "b"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.var_name == "^");
    assert(result.left !is null);
    assert(result.right !is null);
    assert(result.right.var_name == "b");
    assert(result.left.var_name == "a");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["a", "+", "b", "^", "c"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.var_name == "+");
    assert(result.left !is null);
    assert(result.right !is null);
    assert(result.right.var_name == "^");
    assert(result.left.var_name == "a");
    Expression* rightexp = result.right;
    assert(rightexp.left !is null);
    assert(rightexp.right !is null);
    assert(rightexp.right.var_name == "c");
    assert(rightexp.left.var_name == "b");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["(", "a", "+", "b", ")", "^", "c"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.var_name == "^");
    assert(result.left !is null);
    assert(result.right !is null);
    assert(result.right.var_name == "c");
    assert(result.left.var_name == "+");
    Expression* leftexp = result.left;
    assert(leftexp.left !is null);
    assert(leftexp.right !is null);
    assert(leftexp.right.var_name == "b");
    assert(leftexp.left.var_name == "a");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["-", "a", "+", "b", "*", "c", "-", "d"];
    Expression* result = parse_expressions(table, expression);
    /* Resulting syntax tree:
            <+>
        ->              <->
            a      <*>       d
                b        c
    */
    assert(result !is null);
    assert(result.var_name == "+");
    assert(result.left !is null);
    assert(result.right !is null);
    assert(result.right.var_name == "-");
    assert(result.left.var_name == "-");
    Expression* leftexp = result.left;
    assert(leftexp.left is null);
    assert(leftexp.right !is null);
    assert(leftexp.right.var_name == "a");
    Expression* rightexp = result.right;
    assert(rightexp.left !is null);
    assert(rightexp.right !is null);
    assert(rightexp.right.var_name == "d");
    assert(rightexp.left.var_name == "*");
    Expression* right_leftexp = rightexp.left;
    assert(right_leftexp !is null);
    assert(right_leftexp.left !is null);
    assert(right_leftexp.right !is null);
    assert(right_leftexp.right.var_name == "c");
    assert(right_leftexp.left.var_name == "b");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["-", "a", "+", "b", "^", "c", "-", "d"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.var_name == "+");
    assert(result.left !is null);
    assert(result.right !is null);
    assert(result.right.var_name == "-");
    assert(result.left.var_name == "-");
    Expression* leftexp = result.left;
    assert(leftexp.left is null);
    assert(leftexp.right !is null);
    assert(leftexp.right.var_name == "a");
    Expression* rightexp = result.right;
    assert(rightexp.left !is null);
    assert(rightexp.right !is null);
    assert(rightexp.right.var_name == "d");
    assert(rightexp.left.var_name == "^");
    Expression* right_leftexp = rightexp.left;
    assert(right_leftexp !is null);
    assert(right_leftexp.left !is null);
    assert(right_leftexp.right !is null);
    assert(right_leftexp.right.var_name == "c");
    assert(right_leftexp.left.var_name == "b");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["a", "+", "b", "-", "c"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.var_name == "+");
    assert(result.left !is null);
    assert(result.right !is null);
    assert(result.left.var_name == "a");
    assert(result.right.var_name == "-");
    Expression* rightexp = result.right;
    assert(rightexp.left !is null);
    assert(rightexp.right !is null);
    assert(rightexp.left.var_name == "b");
    assert(rightexp.right.var_name == "c");
}

unittest {
    SymbolTable table = new SymbolTable;
    string[] expression = ["a", "+", "b", "==", "c"];
    Expression* result = parse_expressions(table, expression);
    assert(result !is null);
    assert(result.var_name == "==");
    assert(result.left !is null);
    assert(result.right !is null);
    assert(result.left.var_name == "+");
    assert(result.right.var_name == "c");
    Expression* leftexp = result.left;
    assert(leftexp.left !is null);
    assert(leftexp.right !is null);
    assert(leftexp.left.var_name == "a");
    assert(leftexp.right.var_name == "b");
}