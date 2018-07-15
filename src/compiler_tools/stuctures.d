module structures;

struct Program {
    immutable string name;
    Function*[] functions;
}

struct Function {
    immutable string name;
    Statement*[] stmts;
}

struct Statement {
    immutable int type;
    immutable bool has_args;
    Expression*[] args;
    Expression* syntax_tree;
    Statement*[] stmts;
}

struct Expression {
    immutable string var_name;
    Expression* left;
    Expression* right;
}

enum StatementTypes {
    assign_statement,
    break_statement,
    return_statement,
    if_statement,
    else_statement,
    else_if_statement,
    while_statement,
    re_assign_statement,
    continue_statement
}