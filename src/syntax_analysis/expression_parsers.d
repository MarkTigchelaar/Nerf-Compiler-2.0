module expression_parsers;

import symbol_table;
import structures: Expression;
import expression_errors;
import get_token;

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

Expression* parse_expressions(SymbolTable table, string[] rvalues) {
    return null;
}