module structures;

import std.stdio;

struct Variable {
    string name;
    int type;
    bool declaration;
    Statement* belongs_to;
}

struct Statement {
    immutable int stmt_type;
    int var_type;
    string name;
    string stmt_name;
    string alt_branch_name;
    string end_branch_name;
    string func_name;
    Expression syntax_tree;
    Expression[] built_in_args;
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

class FuncRegistry {
    private int[string] return_types;
    private Variable*[][string] function_args;
    private bool locked;

    this() {
        locked = false;
    }

    public void lock() {
        locked = true;
    }

    public bool is_a_function(string name) {
        if(name !in return_types) {
            return false;
        }
        return true;
    }

    public void set_return_type(string fnName, int rType) {
        if(locked) {
            return;
        }
        return_types[fnName] = rType;
    }

    public void set_args(string fnName, Variable*[] vars) {
        if(locked) {
            return;
        }
        function_args[fnName] = vars;
    }

    public int get_return_type(string fnName) {
        if(fnName !in return_types) {
            return -1;
        }
        return return_types[fnName];
    }

    public Variable*[] get_func_args(string fnName) {
        if(fnName !in function_args) {
            throw new Exception("Asking for args of non - exisitant function.");
        }
        return function_args[fnName];
    }

    public FuncRegistry clone() {
        FuncRegistry new_reg = new FuncRegistry();
        foreach(string key; return_types.byKey) {
            new_reg.set_return_type(key, return_types[key]);
        }
        foreach(string key; function_args.byKey) {
            Variable*[] variables;
            foreach(Variable* variable; function_args[key]) {
                variables ~= new Variable(
                    variable.name,
                    variable.type,
                    variable.declaration,
                    variable.belongs_to
                );
            }
            new_reg.set_args(key, variables);
        }
        if(locked) {
            new_reg.lock();
        }
        return new_reg;
    }
}

class Expression {
    private string var_name;
    private string asm_operation;
    private string asm_var_name;
    private string function_name;
    private int var_type;
    int exp_type;

    Expression[] args;
    Expression left;
    Expression right;
    FuncRegistry reg;

    this(string name, string func_name) {
        asm_operation = get_operator_string(name);
        asm_var_name = func_name ~ "_" ~ name;
        var_name = name;
        function_name = func_name;
        //var_type = type;
    }

    public void set_type(int type) {
        var_type = type;
    }

    public int get_type() {
        return var_type;
    }

    public string get_var_name() {
        return var_name;
    }

    public void set_var_name(string name) {
        var_name = name;
    }

    public void set_func_registry(FuncRegistry reg) {
        this.reg = reg;
        if(left !is null) {
            left.set_func_registry(reg);
        }
        if(right !is null) {
            right.set_func_registry(reg);
        }
        foreach(Expression exp; args) {
            exp.set_func_registry(reg);
        }
        if(reg.is_a_function(var_name)) {
            exp_type = ExpTypes.FnCall;
        }
    }
}

enum ExpTypes {
    Operator = 0,
    Variable,
    Const,
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


string get_operator_string(string operator) {
    string asm_operator;
    switch(operator) {
        case "+":
            asm_operator = "iADD";
            break;
        case "-":
            asm_operator = "iSUB";
            break;
        case "*":
            asm_operator = "iMULT";
            break;
        case "/":
            asm_operator = "iDIV";
            break;
        case "%":
            asm_operator = "iMOD";
            break;
        case "^":
            asm_operator = "iEXP";
            break;
        case "<=":
            asm_operator = "iLTEQ";
            break;
        case ">=":
            asm_operator = "iGTEQ";
            break;
        case "<":
            asm_operator = "iLT";
            break;
        case ">":
            asm_operator = "iGT";
            break;
        case "==":
            asm_operator = "iEQ";
            break;
        case "!=":
            asm_operator = "iNEQ";
            break;
        default:
        asm_operator = "no_OP";
    }
    return asm_operator;
}