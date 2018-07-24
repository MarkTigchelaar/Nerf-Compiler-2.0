module structures;

struct Program {
    immutable string name;
    Function*[] functions;
}

struct Function {
    immutable string name;
    immutable string[] arg_names;
    Statement*[] stmts;
}

struct Statement {
    immutable int stmt_type;
    immutable bool has_args;
    immutable string var_type;
    string name;
    Expression* syntax_tree;
    Statement*[] stmts;
}

struct Expression {
    immutable string var_name;
    Expression*[] args;
    Expression* left;
    Expression* right;
}

enum StatementTypes {
    assign_statement,
    re_assign_statement,
    break_statement,
    return_statement,
    if_statement,
    else_statement,
    else_if_statement,
    while_statement,
    continue_statement,
    print_statement
}