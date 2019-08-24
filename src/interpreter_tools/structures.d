module structures;

        import std.stdio;

/*struct Program {
    Function[] functions;
    //mnemonic_node*[] mnemonic_code;
    //mnemonic_node* current;
    //ubyte[] bytecode;
}*/

struct Variable {
    string name;
    int type;
    int scope_depth;
    bool declaration;
    Statement* belongs_to;
}

struct Statement {
    immutable int stmt_type;
    int depth;
    int var_type;
    string name;
    string stmt_name;
    string alt_branch_name;
    string func_name;
    Expression* syntax_tree;
    Expression*[] built_in_args;
    Statement*[] stmts;
    Statement* parent;
}

enum StatementTypes {
    assign_statement = 1,
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

struct Expression {
    immutable string var_name;
    int var_type;
    int exp_type;
    Expression*[] args;
    Expression* left;
    Expression* right;
}

enum ExpTypes {
    Operator = 0,
    Variable,
    FnCall
}

enum PrimitiveTypes {
    Integer,
    IntArray,
    Bool,
    BoolArray,
    Character,
    CharArray,
    Float,
    FloatArray
}

struct mnemonic_node {
    int type;
    ubyte opcode;
    string target_name;
    long iconstant;
    ubyte cconstant;
    string[] labels;
}

enum AsmNodeTypes {
    IntConst,
    CharConst
}
