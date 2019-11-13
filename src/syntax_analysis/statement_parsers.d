module statement_parsers;

import structures: Statement, Expression, StatementTypes, PrimitiveTypes, Variable;
import functions: Function;
import NewSymbolTable;
import Lexer;
import variable_assign_errors;
import general_syntax_errors;
import branching_logic_errors;
import std.stdio;
import core.sys.posix.stdlib: exit;
import PrattParser;

class StatementParser {
    private Lexer lexer;
    private Function func;
    private PrattParser exp_parser;

    this(Lexer lexer) {
        this.lexer = lexer;
        exp_parser = new PrattParser(lexer);
    }

    public void set_function(Function func) {
        this.func = func;
        this.exp_parser.set_function(func);
    }

    public void parse() {
        foreach(Statement* stmt; parse_statements()) {
            func.add_statement(stmt);
        }
    } 

    // Is called recursively, because of sub statements.
    private Statement*[] parse_statements() {
        Statement*[] stmts;
        while(lexer.has_tokens()) {
            stmts ~= parse_statement_type();
        }
        return stmts;
    }

    private:
    
    Statement* parse_statement_type() {
        string current = lexer.next_token();
        if(is_primitive_type(current)) {
            return parse_assign_statement(current);
        }
        if(is_if(current)) {
            return parse_if_statement(current);
        }
        if(is_else(current)) {
            return parse_else_statement(current);
        }
        if(is_while(current)) {
            return parse_while_statement(current);
        }
        if(is_break(current)) {
            return parse_break_statement(current);
        }
        if(is_continue(current)) {
            return parse_continue_statement(current);
        }
        if(is_return(current)) {
            return parse_return_statement(current);
        }
        if(is_print(current)) {
            return parse_print_statement(current);
        }
        if(is_assignment(current)) {
            missing_identifier();
        }
        return parse_re_assign_statement(current);
    }

    Statement* parse_assign_statement(string type) {
        if(!lexer.has_tokens()) {
            invalid_statement();
        }
        string current = lexer.next_token();
        bool is_new = true;
        check_identifier(current, is_new);
        check_for_assignment_operator();
        string[] rvalues     = lexer.collect_until_match(";");
        Statement* statement = new Statement(StatementTypes.assign_statement);
        statement.var_type   = set_type_code(type);
        statement.name       = current;
        Variable* var        = new Variable;
        var.name             = current;
        var.type             = statement.var_type;
        var.declaration      = true;
        var.belongs_to       = statement;

        if(rvalues !is null) {
            statement.syntax_tree = exp_parser.parse_expressions(rvalues.dup);
        }
        func.add_local(var);
        return statement;
    }

    Statement* parse_re_assign_statement(string current) {
        bool is_new = false;
        check_identifier(current, is_new);
        check_for_assignment_operator();
        string[] rvalues     = lexer.collect_until_match(";");
        Statement* statement = new Statement(StatementTypes.re_assign_statement);
        statement.var_type   = func.get_variable_type(current);
        statement.name       = current;
        Variable* var        = new Variable;
        var.name             = current;
        var.type             = statement.var_type;
        var.declaration      = false;
        var.belongs_to       = statement;
        if(rvalues !is null) {
            statement.syntax_tree = exp_parser.parse_expressions(rvalues.dup);
        }
        func.add_local(var);
        return statement;
    }

    Statement* parse_else_statement(string current_token) {
        Statement* else_stmt;
        if(!lexer.has_tokens()) {
            invalid_statement();
        }
        string next_token = lexer.next_token();
        if(is_if(next_token)) {
            auto type = StatementTypes.else_if_statement;
            else_stmt = parse_branch_logic(current_token ~ "_" ~ next_token, type);
        } else if(is_open_curly_brace(next_token)) {
            else_stmt = new Statement(StatementTypes.else_statement);
            else_stmt.name = current_token;
            lexer.set_init_token_type_for_collection(next_token);
            lexer.take_tokens_of_deeper_scope();
            else_stmt.stmts = parse_statements();
            lexer.restore_previous_scope_level();
        } else {
            invalid_branching_logic_scope_token();
        }
        return else_stmt;
    }

    Statement* parse_if_statement(string current_token) {
        return parse_branch_logic(current_token, StatementTypes.if_statement);
    }

    Statement* parse_while_statement(string current_token) {
        return parse_branch_logic(current_token, StatementTypes.while_statement);
    }

    Statement* parse_branch_logic(string current_token, int type) {
        bool is_for_branching = true;
        Statement* branch = new Statement(type);
        branch.name = current_token;
        if(!lexer.has_tokens()) {
            invalid_statement();
        }
        current_token = lexer.next_token();
        set_lexer_tokens_to_statment_args(current_token, is_for_branching);
        if(!lexer.has_tokens()) {
            empty_conditional();
        }

        string[] rvals;
        while(lexer.has_tokens()) {
            rvals ~= lexer.next_token();
        }

        branch.syntax_tree = exp_parser.parse_expressions(rvals);


        lexer.restore_previous_scope_level();
        if(!lexer.has_tokens()) {
            invalid_statement();
        }
        string curly_brace = lexer.next_token();
        set_lexer_tokens_to_statment_body(curly_brace);
        if(!lexer.has_tokens()) {
            empty_statement_body();
        }
        branch.stmts = parse_statements();
        lexer.restore_previous_scope_level();
        return branch;
    }

    void set_lexer_tokens_to_statment_args(string current_token, bool is_for_branching) {
        if(is_open_paren(current_token)) {
            lexer.set_init_token_type_for_collection(current_token);
            lexer.take_tokens_of_deeper_scope();
        } else if(is_for_branching) {
            invalid_args_token();
        }
    }

    void set_lexer_tokens_to_statment_body(string current_token) {
        if(is_open_curly_brace(current_token)) {
            lexer.set_init_token_type_for_collection(current_token);
            lexer.take_tokens_of_deeper_scope();
        } else {
            invalid_branching_logic_scope_token();
        }
    }

    Statement* parse_break_statement(string current_token) {
        return break_continue_statement(current_token,StatementTypes.break_statement);
    }

    Statement* parse_continue_statement(string current_token) {
        return break_continue_statement(current_token, StatementTypes.continue_statement);
    }

    Statement* break_continue_statement(string current_token, int type) {
        if(!lexer.has_tokens()) {
            invalid_statement();
        }
        if(!is_terminator(lexer.next_token())) {
            statement_not_terminated();
        }
        return new Statement(type, cast(int) null, current_token, func.get_name());
    }

    Statement* parse_return_statement(string current_token) {
        string[] return_results = lexer.collect_until_match(";");
        auto ret_statement = new Statement(StatementTypes.return_statement);

        ret_statement.var_type = cast(int) null;
        ret_statement.name = current_token;
        ret_statement.func_name = func.get_name();
        if(return_results !is null) {
            ret_statement.syntax_tree = exp_parser.parse_expressions(return_results.dup);
        }
        return ret_statement;
    }

    Statement* parse_print_statement(string current_token) {
        if(!lexer.has_tokens()) {
            invalid_statement();
        }
        string open_paren = lexer.next_token();
        Statement* print_statement = new Statement(StatementTypes.print_statement);
        print_statement.name = current_token;
        print_statement.func_name = func.get_name();
        lexer.set_init_token_type_for_collection(open_paren);
        string[] printable_stuff = lexer.collect_scoped_tokens();
        if(printable_stuff.length < 1) {
            empty_print();
        }
        print_statement.built_in_args = exp_parser.parse_func_call_arg_expressions(printable_stuff);
        if(!lexer.has_tokens()) {
            invalid_statement();
        }
        string next = lexer.next_token();
        if(!is_terminator(next)) {
            statement_not_terminated();
        }
        return print_statement;
    }

    void check_identifier(string identifier, bool is_new) {
        if(identifier is null) {
            invalid_statement();
        } else if(!is_valid_variable(identifier)) {
            if(is_assignment(identifier)) {
                missing_identifier();
            } else if(is_number(identifier)) {
                assignment_to_constant();
            } else if(is_terminator(identifier)) {
                invalid_statement();
            } else if(is_seperator(identifier)) {
                invalid_statement();
            } else {
                invalid_l_value();
            }
        } else if(func.is_declared_variable(identifier)) {
            if(is_new) {
                repeated_variable_name();
            }
        }
    }

    void check_for_assignment_operator() {
        if(!lexer.has_tokens()) {
            invalid_statement();
        }
        string assign = lexer.next_token();
        
        if(assign is null) {
            invalid_statement();
        }
        if(!is_assignment(assign)) {
            if(is_valid_variable(assign)) {
                invalid_misspelt_type();
            } else if(is_garbage(assign)) {
                invalid_misspelt_type();
            }
            missing_assignment_operator();
        }
    }
}



unittest {
    string[] statement = ["bool", "test", ":=", "a", "+", "b", "==", "c", ";"]; 
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement* s = st.parse_statement_type();
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.assign_statement);
    assert(s.var_type == PrimitiveTypes.Bool);
}

unittest {
    string[] statement = ["return", ";"]; 
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement* s = st.parse_statement_type();
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.return_statement);
}

unittest {
    string[] statement = ["break", ";"]; 
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement* s = st.parse_statement_type();
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.break_statement);
}

unittest {
    string[] statement = ["continue", ";"]; 
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement* s = st.parse_statement_type();
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.continue_statement);
}

unittest {
    string[] statement = ["bool", "test", ":=", "a", "+", "b",
                           "==", "c", ";", "return", ";"];
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement* s = st.parse_statement_type();
    assert(s !is null);
    assert(s.stmt_type == StatementTypes.assign_statement);
    assert(s.var_type == PrimitiveTypes.Bool);

    Statement* s2 = st.parse_statement_type();
    assert(s2 !is null);
    assert(s2.stmt_type == StatementTypes.return_statement);
}

unittest {
    string[] statement = ["test", ":=", "a", "+", "b",
                           "==", "c", ";"];
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement*[] s = st.parse_statements();
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.re_assign_statement);
    assert(s[0].var_type == -1);
}

unittest {
    string[] statement = ["if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", "7", ";", "}"];
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement*[] s = st.parse_statements();
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.if_statement);
    assert(s[0].var_type == cast(int) null);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0].stmt_type == StatementTypes.return_statement);
}

unittest {
    string[] statement = ["while","(", "True",")", "{","if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", ";", "}","}"];
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement*[] s = st.parse_statements();
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.while_statement);
    assert(s[0].var_type == cast(int) null);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0].stmt_type == StatementTypes.if_statement);
    assert(s[0].stmts[0].stmts !is null);
    assert(s[0].stmts[0].stmts.length == 1);
    assert(s[0].stmts[0].stmts[0].stmt_type == StatementTypes.return_statement);
}

unittest {
    string[] statement = ["else", "if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", ";", "}"];
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement*[] s = st.parse_statements();
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.else_if_statement);
    assert(s[0].var_type == cast(int) null);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0] !is null);
    assert(s[0].stmts[0].stmt_type == StatementTypes.return_statement);
}

unittest {
    string[] statement = ["int", "a", ":=", "2", ";"];
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement*[] s = st.parse_statements();
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.assign_statement); 
}

unittest {
    string[] statement = ["a", ":=", "2", ";"];
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement*[] s = st.parse_statements();
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.re_assign_statement); 
}

unittest {
    string[] statement = ["else", "{", "return", ";", "}"];
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement*[] s = st.parse_statements();
    assert(s !is null);
    assert(s.length == 1);
    assert(s[0].stmt_type == StatementTypes.else_statement);
    assert(s[0].var_type == cast(int) null);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0].stmt_type == StatementTypes.return_statement);
}

unittest {
    string[] statement = ["if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", ";", "}",
                           "else", "{", "return", ";", "}"];
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement*[] s = st.parse_statements();
    assert(s !is null);
    assert(s.length == 2);
    assert(s[0].stmt_type == StatementTypes.if_statement);
    assert(s[0].var_type == cast(int) null);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0].stmt_type == StatementTypes.return_statement);
    assert(s[1].stmts !is null);
    assert(s[1].stmt_type == StatementTypes.else_statement);
    assert(s[1].var_type == cast(int) null);
    assert(s[1].stmts[0].stmt_type == StatementTypes.return_statement);
}

unittest {
    string[] statement = ["if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", ";", "}",
                           "else", "if", "(","a", "+", "b",
                           "==", "c", ")", "{", "return", ";", "}",
                           "else", "{", "return", ";", "}"];
    Lexer lex = new Lexer(statement);
    StatementParser st = new StatementParser(lex);
    st.set_function(new Function("tester"));
    Statement*[] s = st.parse_statements();
    assert(s !is null);
    assert(s.length == 3);
    assert(s[0].stmt_type == StatementTypes.if_statement);
    assert(s[0].stmts !is null);
    assert(s[0].stmts.length == 1);
    assert(s[0].stmts[0].stmt_type == StatementTypes.return_statement);

    assert(s[1].stmt_type == StatementTypes.else_if_statement);
    assert(s[1].var_type == cast(int) null);
    assert(s[1].stmts !is null);
    assert(s[1].stmts.length == 1);
    assert(s[1].stmt_type == StatementTypes.else_if_statement);
    assert(s[1].stmts !is null);
    assert(s[1].stmts.length == 1);
    assert(s[1].stmts[0].stmt_type == StatementTypes.return_statement);
}
