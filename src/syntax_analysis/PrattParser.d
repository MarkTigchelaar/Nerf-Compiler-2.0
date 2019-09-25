module PrattParser;

import NewSymbolTable;
import structures: Expression, ExpTypes, Variable, PrimitiveTypes;
import functions: Function;
import expression_errors;
import scoped_token_collector;
import Lexer;
import std.stdio;


class PrattParser {

    private Lexer lexer;
    private Function func;

    this() {
        lexer = null;
    }
    this(Lexer lexer) {
        this.lexer = lexer;
    }


public:
    Expression*[] parse_func_call_arg_expressions(string[] rvalues) {
        Expression*[] func_args;
        string[] expressions;
        for(int i = 0; i < rvalues.length; i++) {
            if(is_open_paren(rvalues[i])) {
                expressions ~= "(" ~ collect_scoped_tokens(rvalues, &i) ~ ")";
            } else if(is_comma(rvalues[i])) {
                if(i == rvalues.length -1) {
                    missing_arg_from_call();
                } else if(expressions.length == 0) {
                    missing_arg_from_call();
                }
                Expression* result = parse_expressions(expressions.dup);
                if(result !is null) {
                    func_args ~= result;
                }
                expressions = null;
            } else {
                expressions ~= rvalues[i];
            }
        }
        Expression* result = parse_expressions(expressions.dup);
        if(result !is null) {
            func_args ~= result;
        }
        return func_args;
    }

    Expression* parse_expressions(string[] rvalues) {
        if(rvalues is null || rvalues.length == 0) {
            return null;
        }
        check_last_index(rvalues);
        int index = 0; // terrible, but I'm leaving it for now.
        return build_ast(rvalues, 0, &index);
    }

    void set_function(Function func) {
        this.func = func;
    }

private: 
    Expression* build_ast(string[] exptokens, int rank, int* index) {
        Expression* left = prefix_func_switchboard(exptokens, index);
        while(rank < precedenceOfNextToken(exptokens, index)) {
            left = infix_func_switchboard(left, exptokens, index);
        }   return left;
    }

    int precedenceOfNextToken(string[] exptokens, int* index) {
        if(is_valid_variable(current_token(exptokens, index))) {
            missing_operator();
        } else if(is_number(current_token(exptokens, index))) {
            missing_operator();
        }
        if((*index) + 1 >= exptokens.length) {
            return 0;
        }
        return token_precedence(current_token(exptokens, index));
    }

    Expression* prefix_func_switchboard(string[] exptokens, int* index) {
        Expression* prefix;
        if(is_open_paren(current_token(exptokens, index))) {
            prefix = paren_parser(exptokens, index);
        } else if(is_prefix(current_token(exptokens, index))) {
            return prefix_ops_parser(exptokens, index);
        } else if(is_valid_variable(current_token(exptokens, index))) {
            prefix = variable_or_const_parser(exptokens, index);
        } else if(is_boolean(current_token(exptokens, index))) {
            prefix = variable_or_const_parser(exptokens, index);
        } else if(is_number(current_token(exptokens, index))) {
            prefix = variable_or_const_parser(exptokens, index);
        } else if(is_operator(current_token(exptokens, index))) {
            missing_variable_or_constant();
        } else {
            invalid_expression_token();
        }
        return prefix;
    }


    Expression* paren_parser(string[] exptokens, int* index) {
        string[] sub_expression = collect_scoped_tokens(exptokens, index);
        if(sub_expression.length < 1) {
            empty_parens();
        }
        int new_index;
        return build_ast(sub_expression, 0, &new_index);
    }

    Expression* prefix_ops_parser(string[] exptokens, int* index) {
        Expression* current = new Expression(current_token(exptokens, index));
        int rank = prefix_precedence(get_token(exptokens, index));
        Expression* right = build_ast(exptokens, rank, index);
        if(is_minus(current.var_name) &&
        is_minus(right.var_name) &&
        right.left is null) {
            multiple_minus_signs();
        }
        current.right = right;
        return current;
    }

    Expression* infix_func_switchboard(Expression* left, string[] exptokens, int* index) {
        Expression* infix;
        int var_type;
        if(is_math_op(current_token(exptokens, index))) {
            var_type = PrimitiveTypes.Integer;
            infix = operator_parser(left, exptokens, index, var_type);
        } else if(is_bool_compare(current_token(exptokens, index))) {
            var_type = PrimitiveTypes.Bool;
            infix = operator_parser(left, exptokens, index, var_type);
        } else if(is_bool_operator(current_token(exptokens, index))) {
            var_type = PrimitiveTypes.Bool;
            infix = operator_parser(left, exptokens, index, var_type);
        } else if(is_open_paren(current_token(exptokens, index))) {
            infix = func_call_parser(left, exptokens, index);
        } else {
            invalid_expression_token();
        }
        return infix;
    }

    Expression* operator_parser(Expression* left, string[] exptokens, int* index, int vartype) {
        int rank_reduce = 0;
        if(is_right_associative(current_token(exptokens,index))) {
            rank_reduce = 1;
        }
        int rank = token_precedence(current_token(exptokens,index));
        Expression* current = new Expression(get_token(exptokens,index));
        current.var_type = vartype;
        Expression* right = build_ast(exptokens, rank - rank_reduce, index);
        if(current.var_name == right.var_name) {
            if(current.var_name != "^") {
                multiple_minus_signs();
            }
        }
        current.right = right;
        current.left = left;
        return current;
    }

    Expression* func_call_parser(Expression* left, string[] exptokens, int* index) {
        string[] call_args = collect_scoped_tokens(exptokens, index);
        left.args = parse_func_call_arg_expressions(call_args);
        return left;
    }

    Expression* variable_or_const_parser(string[] exptokens, int* index) {
        string current = get_token(exptokens, index);
        Expression* exp = new Expression(current);
        exp.var_type = func.get_variable_type(current);
        exp.exp_type = ExpTypes.Variable;
        return exp;
    }

    void check_last_index(string[] rvalues) {
        if(is_valid_variable(rvalues[rvalues.length - 1])) {
            return;
        }
        if(is_number(rvalues[rvalues.length - 1])) {
            return;
        }
        if(is_return(rvalues[rvalues.length - 1])) {
            return;
        }
        if(is_break(rvalues[rvalues.length - 1])) {
            return;
        }
        if(is_continue(rvalues[rvalues.length - 1])) {
            return;
        }
        if(is_boolean(rvalues[rvalues.length - 1])) {
            return;
        }
        if(is_close_paren(rvalues[rvalues.length - 1])) {
            return;
        }
        invalid_expression();
    }

    string get_token(string[] func_body, int* index)  {
        string token = current_token(func_body, index);
        (*index)++;
        return token;
    }

    string current_token(string[] func_body, int* index)  {
        if(*index >= func_body.length) {
            return null;
        }
        string token = func_body[*index];
        return token;
    }

    string[] collect_scoped_tokens(string[] func_body, int* index) {
        ScopedTokenCollector collector = new ScopedTokenCollector();
        collector.add_token(get_token(func_body, index));
        do {
            collector.add_token(get_token(func_body, index));
        } while(collector.not_done_collecting());
        return collector.get_scoped_tokens();
    }
}













unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["True"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right is null);
    assert(result.var_name == "True");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["False"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right is null);
    assert(result.var_name == "False");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["3.8"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right is null);
    assert(result.var_name == "3.8");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["38"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right is null);
    assert(result.var_name == "38");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["(", "38", ")"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right is null);
    assert(result.var_name == "38");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["-", "38"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right !is null);
    assert(result.var_name == "-");
    assert(result.right.var_name == "38");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["(", "-", "38", ")"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right !is null);
    assert(result.var_name == "-");
    assert(result.right.var_name == "38");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["-", "(", "38", ")"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.left is null);
    assert(result.right !is null);
    assert(result.var_name == "-");
    assert(result.right.var_name == "38");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["a", "+", "b"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.var_name == "+");
    assert(result.left !is null);
    assert(result.right !is null);
    assert(result.right.var_name == "b");
    assert(result.left.var_name == "a");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["a", "+", "b", "==", "c"];
    Expression* result = pratt.parse_expressions(expression);
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
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["a", "^", "b"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.var_name == "^");
    assert(result.left !is null);
    assert(result.right !is null);
    assert(result.right.var_name == "b");
    assert(result.left.var_name == "a");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["a", "+", "b", "^", "c"];
    Expression* result = pratt.parse_expressions(expression);
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
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["(", "a", "+", "b", ")", "^", "c"];
    Expression* result = pratt.parse_expressions(expression);
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
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["-", "a", "+", "b", "*", "c", "-", "d"];
    Expression* result = pratt.parse_expressions(expression);
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
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["-", "a", "+", "b", "^", "c", "-", "d"];
    Expression* result = pratt.parse_expressions(expression);
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
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["a", "+", "b", "-", "c"];
    Expression* result = pratt.parse_expressions(expression);
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
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["a", "+", "b", "==", "c"];
    Expression* result = pratt.parse_expressions(expression);
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

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["a", "+", "b", ",", "b", "/", "c"];
    Expression*[] resultlist = pratt.parse_func_call_arg_expressions(expression);
    assert(resultlist !is null);
    assert(resultlist.length == 2);
    Expression* result0 = resultlist[0];
    Expression* result1 = resultlist[1];
    assert(result0 !is null);
    assert(result1 !is null);
    assert(result0.var_name == "+");
    assert(result1.var_name == "/");
    assert(result0.left !is null);
    assert(result0.right !is null);
    assert(result1.left !is null);
    assert(result1.right !is null);
    assert(result0.left.var_name == "a");
    assert(result0.right.var_name == "b");
    assert(result1.left.var_name == "b");
    assert(result1.right.var_name == "c");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["a", "+", "-", "b"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.var_name == "+");
    assert(result.left !is null);
    assert(result.left.var_name == "a");
    assert(result.right !is null);
    assert(result.right.var_name == "-"); 
    assert(result.right.right !is null);
    assert(result.right.right.var_name == "b");
    assert(result.right.left is null);
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["(", "(","a", "+", "(","b", ")", ")", "==", "c", ")"];
    Expression* result = pratt.parse_expressions(expression);
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

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["(", "(","-", "a", ")", "+", "(", "(",
                           "b", "^", "c", ")", "-", "d", ")", ")"];
    Expression* result = pratt.parse_expressions(expression);
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
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["-", "(", "(", "(","-", "1", ")", "+", "(",
                           "13", "^", "6", ")", ")", "-", "8", ")"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.var_name == "-");
    assert(result.left is null);
    assert(result.right !is null);
    assert(result.right.var_name == "-");
    assert(result.right.right !is null);
    assert(result.right.right.var_name == "8");
    assert(result.right.left.var_name !is null);
    assert(result.right.left.var_name == "+");
    Expression* right_subtree = result.right.left.right;
    Expression* left_subtree = result.right.left.left;
    assert(left_subtree !is null);
    assert(right_subtree !is null);
    assert(left_subtree.var_name == "-");
    assert(right_subtree.var_name == "^");
    assert(left_subtree.left is null);
    assert(left_subtree.right !is null);
    assert(left_subtree.right.var_name == "1");
    assert(right_subtree.left !is null);
    assert(right_subtree.left.var_name == "13");
    assert(right_subtree.right !is null);
    assert(right_subtree.right.var_name == "6");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = ["func", "(", "True", ")"];
    Expression* result = pratt.parse_expressions(expression);
    assert(result !is null);
    assert(result.args !is null);
    assert(result.args.length == 1);
    assert(result.args[0].var_name == "True");
}

unittest {
    PrattParser pratt = new PrattParser();
    pratt.set_function(new Function("test"));
    string[] expression = 
    [
    "func","(",
      "a", "+", "-", "b", ",",
      "-", "(", "(", "(","-", "1", ")", "+", "(", "13", "^", "6", ")", ")","-", "8", ")",
    ")"
    ];
    Expression* func = pratt.parse_expressions(expression);
    assert(func !is null);
    assert(func.args !is null);
    assert(func.args.length == 2);
    Expression* args0 = func.args[0];
    Expression* args1 = func.args[1];
    assert(args0 !is null);
    assert(args0.var_name == "+");
    assert(args0.left !is null);
    assert(args0.left.var_name == "a");
    assert(args0.right !is null);
    assert(args0.right.var_name == "-"); 
    assert(args0.right.right !is null);
    assert(args0.right.right.var_name == "b");
    assert(args0.right.left is null);
    assert(args1 !is null);
    assert(args1.var_name == "-");
    assert(args1.left is null);
    assert(args1.right !is null);
    assert(args1.right.var_name == "-");
    assert(args1.right.right !is null);
    assert(args1.right.right.var_name == "8");
    assert(args1.right.left.var_name !is null);
    assert(args1.right.left.var_name == "+");
    Expression* right_subtree = args1.right.left.right;
    Expression* left_subtree = args1.right.left.left;
    assert(left_subtree !is null);
    assert(right_subtree !is null);
    assert(left_subtree.var_name == "-");
    assert(right_subtree.var_name == "^");
    assert(left_subtree.left is null);
    assert(left_subtree.right !is null);
    assert(left_subtree.right.var_name == "1");
    assert(right_subtree.left !is null);
    assert(right_subtree.left.var_name == "13");
    assert(right_subtree.right !is null);
    assert(right_subtree.right.var_name == "6");
}

unittest {
    // (a+b)<5
    PrattParser pratt = new PrattParser();
    Function test = new Function("test");
    pratt.set_function(test);
    Variable* a = new Variable();
    a.name = "a";
    a.type = PrimitiveTypes.Integer;
    test.add_local(a);
    Variable* b = new Variable();
    b.name = "b";
    b.type = PrimitiveTypes.Integer;
    test.add_local(b);
    string[] exp = ["(", "a", "+", "b", ")", "<", "5"];
    Expression* result = pratt.parse_expressions(exp);
    assert(result !is null);
    assert(result.var_name == "<");
    assert(result.exp_type == ExpTypes.Operator);
    assert(result.var_type == PrimitiveTypes.Bool);
    assert(result.right !is null);
    assert(result.left !is null);
}

unittest {
    // - y - 4
    PrattParser pratt = new PrattParser();
    Function test = new Function("test");
    pratt.set_function(test);
    Variable* y = new Variable();
    y.name = "y";
    y.type = PrimitiveTypes.Integer;
    test.add_local(y);
    string[] exp = ["-", "y", "-", "4"];
    Expression* result = pratt.parse_expressions(exp);
    assert(result !is null);
    assert(result.var_name == "-");
    assert(result.left.var_name == "-");
    assert(result.left.right.var_name == "y");
    assert(result.right.var_name == "4");
}