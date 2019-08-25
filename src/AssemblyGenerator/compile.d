module compile;

import functions: Function;
import structures: Variable, Statement, Expression, StatementTypes, PrimitiveTypes, ExpTypes;
import std.conv: to;
import std.stdio;
import std.string: chomp;
import std.algorithm: startsWith;

// Need one of these for each function
// used to label each branching logic statement.
class IdGenerator {
    long id;

    this() {
        id = 1;
    }

    string next_id() {
        string id_num = to!string(id);
        id++;
        return id_num;
    }
}

string[] compile(Function[] program) {
    string[] assembly;
    Function fn_main;
    for(long i = 0; i < program.length; i++) {
        name_every_statement_uniquely(program[i]);
        link_branching_with_alternate_branches(program[i]);
        if(program[i].get_name() == "main") {
            fn_main = program[i];
        }
    }
    write_out_locals(&assembly, fn_main);
    write_out_statements(&assembly, fn_main);
    foreach(Function func; program) {
        if(func.get_name() == "main") {
            continue;
        }
        assembly ~= "`" ~ func.get_name();
        write_out_args(&assembly, func);
        write_out_locals(&assembly, func);
        write_out_statements(&assembly, func);
    }
    for(long i = 0; i < assembly.length; i++) {
        assembly[i] = chomp(assembly[i]);
    }
    return assembly;
}

void write_out_args(string[] *assembly, Function func) {
    string item = "";
    foreach(Variable* variable; func.get_arguments()) {
        item ~= "<~" ~ func.get_name();
        item ~= "_" ~ variable.name ~ get_offset(variable);
        *assembly ~= item;
        item = "";
    }
}

void write_out_locals(string[] *assembly, Function func) {
    string item = "";
    foreach(Variable* variable; func.get_local_variables()) {
        item ~= "<" ~ func.get_name();
        item ~= "_" ~ variable.name ~ get_offset(variable);
        *assembly ~= item;
        item = "";
    }
}

string get_offset(Variable* variable) {
    string offset = "";
    switch(variable.type) {
        case PrimitiveTypes.Integer:
        case PrimitiveTypes.IntArray:
        case PrimitiveTypes.BoolArray:
        case PrimitiveTypes.CharArray:
        case PrimitiveTypes.Float:
        case PrimitiveTypes.FloatArray:
            offset =  ":8";
            break;
        default:
            offset = ":1";
            break;
    }
    return offset;
}

string get_var_type(Statement* statement) {
    if(statement.syntax_tree.var_type == PrimitiveTypes.Integer) {
        return "i";
    }
    return "ch";
}
void write_out_statements(string[] *assembly, Function func) {
    Statement*[] all_statements = func.get_statements();
    string[] variable_names = func.get_var_names();
    for(long i = 0; i < all_statements.length; i++) {
        Statement* statement = all_statements[i];
        statement.func_name = func.get_name();
        switch(statement.stmt_type) {
            case StatementTypes.assign_statement:
            case StatementTypes.re_assign_statement:
                write_out_assignment(statement, assembly, &variable_names);
                break;
            case StatementTypes.if_statement:
            case StatementTypes.else_if_statement:
                //write_out_branch_logic();
                break;
            case StatementTypes.while_statement:
                //write_out_loop_logic();
                break;
            case StatementTypes.continue_statement:
                //write_out_continue_statement();
                break;
            case StatementTypes.print_statement:
                //write_out_print_statement();
                break;
            case StatementTypes.return_statement:
                process_inner_returns(i, all_statements.length, assembly, statement, &variable_names, func.get_name());
                break;
            case StatementTypes.break_statement:
                //write_out_break_statement();
                break;
            default:
                throw new Exception("AST TO ASM ERROR: Could not find matching type while writing out asm for " ~ statement.name);
        }
    }
    write_out_return_statement(assembly, func);
}

void process_inner_returns (
    long i, 
    long statements_length, 
    string[] *assembly, 
    Statement* statement, 
    string[] *variable_names, 
    string func_name
    ) {
    if(i < statements_length - 1) {
        if(statement.syntax_tree.var_name == "-") {
            write_out_neg_expression(assembly, statement.syntax_tree, variable_names, func_name);
        } else {
            writeln(statement.syntax_tree.var_name ~ " is the var name");
            write_out_expression(assembly, statement.syntax_tree, variable_names, func_name);
        }
        *assembly ~= "JUMP";
        *assembly ~= "return_" ~ func_name;
    } else {
        if(statement.syntax_tree.var_name == "-") {
            write_out_neg_expression(assembly, statement.syntax_tree, variable_names, func_name);
        } else {
            write_out_expression(assembly, statement.syntax_tree, variable_names, func_name);
        }
    }
}

void write_out_assignment(Statement* statement, string[] *assembly, string[] *variable_names) {
    if(statement.syntax_tree.var_name == "-") {
        write_out_neg_expression(assembly, statement.syntax_tree, variable_names, statement.func_name);
    } else {
        write_out_expression(assembly, statement.syntax_tree, variable_names, statement.func_name);
    }
    *assembly ~= get_var_type(statement) ~ "MOVE";
    *assembly ~= statement.func_name ~ "_" ~ statement.name;
    //writeln("var type: ", statement.syntax_tree.var_type);
}

void write_out_neg_expression(string[] *assembly, Expression* root, string[] *variable_names, string func_name) {
    import NewSymbolTable: is_variable_integer;
    if(root.right !is null && 
       root.right.var_type == PrimitiveTypes.Integer && 
       is_variable_integer(root.right.var_name)
    ) {
        root.right.var_name = "-" ~ root.right.var_name;
        write_out_expression(assembly, root.right, variable_names, func_name);
    } else {
        //writeln("here: " ~ )
        *assembly ~= "iPUSHc";
        *assembly ~= "0";
        write_out_expression(assembly, root.left, variable_names, func_name);
        write_out_expression(assembly, root.right, variable_names, func_name);
        *assembly ~= "iSUB";
    }
}

void write_out_expression(string[] *assembly, Expression* root, string[] *variable_names, string func_name) {
    if(root is null) {
        return;
    }
    write_out_expression(assembly, root.left, variable_names, func_name);
    write_out_expression(assembly, root.right, variable_names, func_name);
    if((root.args !is null && root.args.length > 0) || 
        root.exp_type == ExpTypes.FnCall) {
        foreach(Expression* arg; root.args) {
            write_out_expression(assembly, arg, variable_names, func_name);
        }
        *assembly ~= "CALL";
        *assembly ~= root.var_name;
    }
    append_current_expression(assembly, root, variable_names, func_name);
}

void append_current_expression(string[] *assembly, Expression* root, string[] *variable_names, string func_name) {
    import NewSymbolTable;
    if(is_variable_integer(root.var_name)) {
        *assembly ~= "iPUSHc";
        *assembly ~= root.var_name;
    } else if (startsWith(root.var_name, "-")) {
        if(is_variable_integer(root.var_name[1 .. $])) {
            *assembly ~= "iPUSHc";
            *assembly ~= root.var_name;
        }
    }
    string var = get_operator_string(root.var_name);
    if(var != "no_var") {
        *assembly ~= var;
    } else if(is_variable(root.var_name, variable_names)) {
        *assembly ~= "iPUSHv";
        *assembly ~= func_name ~ "_" ~ root.var_name;
    }
}

bool is_variable(string root_name, string[] *variable_names) {
    foreach(string item; *variable_names) {
        if(root_name == item) {
            return true;
        }
    }
    return false;
}
void write_out_return_statement(string[] *assembly, Function func) {
    if(func.get_name() == "main") {
        *assembly ~= ">return_main:HALT";
        return;
    } 
    string prefix = "";
    switch(func.get_return_type()) {
        case PrimitiveTypes.Integer:
        case PrimitiveTypes.IntArray:
        case PrimitiveTypes.BoolArray:
        case PrimitiveTypes.CharArray:
        case PrimitiveTypes.Float:
        case PrimitiveTypes.FloatArray:
            prefix =  "i";
            break;
        default:
            prefix = "ch";
            break;
    }
    *assembly ~= "return_" ~ func.get_name() ~ ":" ~ prefix ~ "RETURN";
}

string int_as_string(long value) {
    char[] digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    char[] str_num = ['0','0','0','0','0','0','0','0','0','0','0','0'];
    for(long i = 1; i <= value; i++) {
        increment_array(str_num, digits);
    }
    string return_val;
    bool append = false;
    foreach(char ch; str_num) {
        if(ch != '0') {
            append = true;
        }
        if(append) {
            return_val ~= ch;
        }
    }
    return return_val;
}

// This can go wrong if the function
// length is a insanely huge number.
void increment_array(char[] str_num, char[] digits) {
    long start = str_num.length - 1;
    while(start >= 0) {
        long index = get_index(str_num[start], digits);
        if(index < 9) {
            str_num[start] = digits[index + 1];
            break;
        } else { // digit is 9.
            str_num[start] = '0';
            start--;
        }
    }
}

long get_index(char digit, char[] digits) {
    for(long i = 0; i < digits.length; i++) {
        if(digits[i] == digit) {
            return i;
        }
    }
    return 0;
}

void name_every_statement_uniquely(Function func) {
    IdGenerator gen = new IdGenerator();
    foreach(Statement* statement; func.get_statements()) {
        statement.func_name = func.get_name();
        name_statement(statement, gen);
    }
}

void name_statement(Statement* statement, IdGenerator gen) {
    //if(statement.stmt_type != StatementTypes.print_statement) {
    statement.stmt_name = statement.func_name ~ "_" ~ type_name(statement) ~ "_" ~ gen.next_id();
    //stderr.writeln("I name you: " ~ statement.stmt_name ~ " for " ~ statement.name);
    //}
    if(statement.stmts !is null && statement.stmts.length > 0) {
        for(long index = 0; index < statement.stmts.length; index++) {
            statement.stmts[index].func_name = statement.func_name;
            name_statement(statement.stmts[index], gen);
        }
    }
}

string type_name(Statement* statement) {
    string type;
    switch(statement.stmt_type) {
        case StatementTypes.assign_statement:
            type = "assign";
            break;
        case StatementTypes.re_assign_statement:
            type = "re_assign";
            break;
        case StatementTypes.break_statement:
            type = "break";
            break;
        case StatementTypes.return_statement:
            type = "return";
            break;
        case StatementTypes.if_statement:
            type = "if";
            break;
        case StatementTypes.else_if_statement:
            type = "elseif";
            break;
        case StatementTypes.else_statement:
            type = "else";
            break;
        case StatementTypes.while_statement:
            type = "while";
            break;
        case StatementTypes.continue_statement:
            type = "continue";
            break;
        default:
            throw new Exception("AST TO ASM ERROR: Didn't find matching statement type.");
    }
    return type;
}

void link_branching_with_alternate_branches(Function func) {
    return;
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
        asm_operator = "no_var";
    }
    return asm_operator;
}