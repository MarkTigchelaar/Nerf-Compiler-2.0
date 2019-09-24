module compile;

import functions: Function;
import structures: Variable, Statement, Expression, StatementTypes, PrimitiveTypes, ExpTypes;
import std.conv: to;
import std.stdio;
import std.string: chomp, split;
import std.algorithm: startsWith;
import std.stdio;
import tree_linking: link_ast_branches, generate_parent_for_first_level;

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
    for(long i = program.length - 1; i >= 0;  i--) { 
        name_every_statement_uniquely(program[i]);
        link_statements_with_alterative_execution_paths(program[i].get_statements());
        if(program[i].get_name() == "main") {
            fn_main = program[i];
        }
    }
    write_out_locals(&assembly, fn_main);
    Statement*[] main_statements = fn_main.get_statements();
    foreach(Statement* s; main_statements) {
        s.func_name = fn_main.get_name();
    }
    string[] variable_names = remove_dups(fn_main.get_var_names());
    write_out_statements(&assembly, main_statements, &variable_names, fn_main.get_return_type());
    write_out_return_statement(&assembly, fn_main.get_name(), fn_main.get_return_type());
    foreach(Function func; program) {
        if(func.get_name() == "main") {
            continue;
        }
        assembly ~= "`" ~ func.get_name();
        write_out_args(&assembly, func);
        write_out_locals(&assembly, func);
        Statement*[] stmts = func.get_statements();
        foreach(Statement* s; stmts) {
            s.func_name = func.get_name();
        }
        variable_names = remove_dups(func.get_var_names());
        write_out_statements(&assembly, stmts, &variable_names, func.get_return_type());
        write_out_return_statement(&assembly, func.get_name(), func.get_return_type());
    }
    for(long i = 0; i < assembly.length; i++) {
        assembly[i] = chomp(assembly[i]);
    }
    return assembly;
}


void link_statements_with_alterative_execution_paths(Statement*[] statements) {
    generate_parent_for_first_level(statements);
    link_ast_branches(statements);
}

string[] remove_dups(string[] variables) {
    string[] unique_list;
    for(long i = 0; i < variables.length; i++) {
        bool found = false;
        for(long j = i+1; j < variables.length; j++) {
            if(variables[i] == variables[j]) {
                found = true;
                break;
            }
        }
        if(!found) {
            found = false;
            for(long k = 0; k < unique_list.length; k++) {
                if(variables[i] == unique_list[k]) {
                    found = true;
                    break;
                }
            }
            if(!found) {
                unique_list ~= variables[i];
            }
        }
    }
    return unique_list;
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

string get_var_type_for_expression(Expression* expression) {
    if(expression.left is null && expression.right is null) {
        if(expression.var_type == PrimitiveTypes.Integer) {
            return "i";
        }
    } else if(is_prefix(expression)) {
        if(expression.right.var_type == PrimitiveTypes.Integer) {
            return "i";
        }
    }
    if(expression.right.var_type == PrimitiveTypes.Integer &&
       expression.left.var_type == PrimitiveTypes.Integer    
    ) {
        return "i";
    }
    return "ch";
}

void write_out_statements(
        string[] *assembly, 
        Statement*[] all_statements, 
        string[]* var_names, 
        long func_return_type
    ) {
    string[] variable_names = *var_names;
    for(long i = 0; i < all_statements.length; i++) {
        long current_index = (*assembly).length;
        Statement* statement = all_statements[i];
        switch(statement.stmt_type) {
            case StatementTypes.assign_statement:
            case StatementTypes.re_assign_statement:
                write_out_assignment(statement, assembly, &variable_names);
                break;
            case StatementTypes.if_statement:
            case StatementTypes.else_if_statement:
                write_out_branch_logic(statement, assembly, &variable_names, func_return_type);
                break;
            case StatementTypes.else_statement:
                write_out_statements(assembly, statement.stmts, &variable_names, func_return_type);
                break;
            case StatementTypes.while_statement:
                write_out_loop_logic(statement, assembly, &variable_names, func_return_type);
                break;
            case StatementTypes.continue_statement:
                write_out_continue_statement(statement, assembly, &variable_names);
                break;
            case StatementTypes.print_statement:
                write_out_print_statement(statement, assembly, &variable_names);
                break;
            case StatementTypes.return_statement:
                process_return_expressions(
                    i, 
                    all_statements.length, 
                    assembly, 
                    statement, 
                    &variable_names, 
                    statement.func_name
                );
                break;
            case StatementTypes.break_statement:
                write_out_break_statement(statement, assembly, &variable_names);
                break;
            default:
                throw new Exception("AST TO ASM ERROR: Could not find matching type while writing out asm for " ~ statement.name);
        }
        if(statement.stmt_type == StatementTypes.else_statement) {
            (*assembly)[current_index] = ">" ~ statement.stmt_name ~ ":" ~ break_off_label((*assembly)[current_index]);
        } else {
            (*assembly)[current_index] = ">" ~ statement.stmt_name ~ ":" ~(*assembly)[current_index];
        }
    }
}


string break_off_label(string statement) {
    string[] parts = split(statement, ":");
    return parts[1];
}

void process_return_expressions (
    long i, 
    long statements_length, 
    string[] *assembly, 
    Statement* statement, 
    string[] *variable_names, 
    string func_name
) {
    if(statement.syntax_tree.var_name == "-" && 
        is_prefix(statement.syntax_tree)
    ) {
        write_out_prefix_expression(
            assembly, 
            statement.syntax_tree, 
            variable_names, 
            func_name
        );
    } else {
        write_out_expression(
            assembly, 
            statement.syntax_tree, 
            variable_names, 
            func_name
        );
    }
    if(i != statements_length - 1 || 
      (statement.parent !is null && statement.parent.stmt_name != "top")) {
        *assembly ~= "JUMP";
        *assembly ~= "return_" ~ func_name;
    }
}

bool is_prefix(Expression* root) {
    if(root is null) {
        return false;
    }
    return root.left is null && root.right !is null;
}

void write_out_assignment(
    Statement* statement, 
    string[] *assembly, 
    string[] *variable_names
) {
    if(is_prefix(statement.syntax_tree)) {
        write_out_prefix_expression(
            assembly, 
            statement.syntax_tree, 
            variable_names, 
            statement.func_name
        );
    } else {
        write_out_expression(
            assembly, 
            statement.syntax_tree, 
            variable_names, 
            statement.func_name
        );
    }
    *assembly ~= get_var_type(statement) ~ "MOVE";
    *assembly ~= statement.func_name ~ "_" ~ statement.name;
}

void write_out_print_statement(
    Statement* statement, 
    string[] *assembly, 
    string[] *variable_names
) {
    foreach(Expression* arg; statement.built_in_args) {
        if(is_prefix(arg)) {
            write_out_prefix_expression(
                assembly, 
                arg, 
                variable_names, 
                statement.func_name
            );
        } else {
            write_out_expression(
                assembly, 
                arg, 
                variable_names, 
                statement.func_name
            );
        }
        *assembly ~= get_var_type_for_expression(arg) ~ "PUTLN";
    }
}

void write_out_prefix_expression(
    string[] *assembly, 
    Expression* root, 
    string[] *variable_names, 
    string func_name
) {
    import NewSymbolTable: is_variable_integer;
    if(is_variable_integer(root.right.var_name)) {
        root.right.var_name = "-" ~ root.right.var_name;
        write_out_expression(
            assembly, 
            root.right, 
            variable_names, 
            func_name
        );
    } else {
        *assembly ~= "iPUSHc";
        *assembly ~= "0";
        write_out_expression(
            assembly, 
            root.right, 
            variable_names, 
            func_name
        );
        *assembly ~= "iSUB";
    }
}

void write_out_expression(
    string[] *assembly,
    Expression* root, 
    string[] *variable_names, 
    string func_name
) {
    if(root is null) {
        return;
    }
    process_expression_by_type(
        assembly, 
        root.left, 
        variable_names, 
        func_name
    );
    process_expression_by_type(
        assembly, 
        root.right, 
        variable_names, 
        func_name
    );
    if((root.args !is null && root.args.length > 0) || 
        root.exp_type == ExpTypes.FnCall) {
        foreach(Expression* arg; root.args) {
            process_expression_by_type(
                assembly, 
                arg, 
                variable_names, 
                func_name
            );
        }
        *assembly ~= "CALL";
        *assembly ~= root.var_name;
    }
    append_current_expression(
        assembly, 
        root, 
        variable_names, 
        func_name
    );
}

void process_expression_by_type(
    string[] *assembly, 
    Expression* root, 
    string[] *variable_names,
    string func_name
) {
    if(is_prefix(root)) {
        write_out_prefix_expression(
            assembly, 
            root, 
            variable_names, 
            func_name
        );
    } else {
        write_out_expression(
            assembly, 
            root, 
            variable_names, 
            func_name
        );
    }
}

void append_current_expression(
    string[] *assembly, 
    Expression* root, 
    string[] *variable_names, 
    string func_name
) {
    import NewSymbolTable;
    if(is_variable_integer(root.var_name)) {
        *assembly ~= "iPUSHc";
        *assembly ~= root.var_name;
    } else if(startsWith(root.var_name, "-") && 
              is_variable_integer(root.var_name[1 .. $])
      ) {        
        *assembly ~= "iPUSHc";
        *assembly ~= root.var_name;
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
void write_out_return_statement(string[] *assembly, string func_name, long func_return_type) {
    if(func_name == "main") {
        *assembly ~= ">return_main:HALT";
        return;
    } 
    string prefix = "";
    switch(func_return_type) {
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
    *assembly ~= ">return_" ~ func_name ~ ":" ~ prefix ~ "RETURN";
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

// This can go wrong if it is a insanely huge number.
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
        set_parent(statement, statement.stmts);
    }
}

// apparently this wasen't done during parsing. (bug fix)
void set_parent(Statement* parent, Statement*[] children) {
    if(children is null) {
        return;
    }
    foreach(Statement* child; children) {
        child.parent = parent;
        set_parent(child, child.stmts);
    }
}

void name_statement(Statement* statement, IdGenerator gen) {
    statement.stmt_name = statement.func_name ~ "_" ~ type_name(statement) ~ "_" ~ gen.next_id();
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
        case StatementTypes.print_statement:
            type = "print";
            break;
        default:
            throw new Exception("AST TO ASM ERROR: Didn't find matching statement type.");
    }
    return type;
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


void write_out_branch_logic (
    Statement* statement, 
    string[] *assembly, 
    string[] *variable_names,
    long func_return_type
) {
    if(is_prefix(statement.syntax_tree)) {
        write_out_prefix_expression(
            assembly, 
            statement.syntax_tree, 
            variable_names, 
            statement.func_name
        );
    } else {
        write_out_expression(
            assembly, 
            statement.syntax_tree, 
            variable_names, 
            statement.func_name
        );
    }
    *assembly ~= "iPUSHc";
    *assembly ~= "1";
    *assembly ~= "iJUMPNEQ";
    *assembly ~= statement.alt_branch_name;
    write_out_statements(assembly, statement.stmts, variable_names, func_return_type);
    if((*assembly)[assembly.length-2] != "JUMP" && statement.end_branch_name !is null) {
        *assembly ~= "JUMP";
        *assembly ~= statement.end_branch_name;
    }
}

void write_out_loop_logic(
        Statement* statement, 
        string[] *assembly, 
        string[] *variable_names, 
        long func_return_type
    ) {
    process_expression_by_type(
        assembly, 
        statement.syntax_tree, 
        variable_names,
        statement.func_name
    );
    *assembly ~= "iPUSHc";
    *assembly ~= "1";
    *assembly ~= "iJUMPNEQ";
    if(statement.alt_branch_name !is null && statement.alt_branch_name != "") {
        *assembly ~= statement.alt_branch_name;        
    } else {
        *assembly ~= statement.end_branch_name;
    }
    write_out_statements(assembly, statement.stmts, variable_names, func_return_type);
    *assembly ~= "JUMP";
    *assembly ~= statement.stmt_name;
}

void write_out_continue_statement(Statement* statement, string[] *assembly, string[] *variable_names) {
    Statement* parent = statement.parent;
    while(parent !is null) {
        if(parent.stmt_type == StatementTypes.while_statement) {
            *assembly ~= "JUMP";
            *assembly ~= parent.stmt_name;
            break;
        } else {
            parent = parent.parent;
        }
    }
    if(parent is null) {
       throw new Exception("AST to ASM ERROR: no parent while statement found.");
    }
}

void write_out_break_statement(Statement* statement, string[] *assembly, string[] *variable_names) {
    Statement* parent = statement.parent;
    while(parent !is null) {
        if(parent.stmt_type == StatementTypes.while_statement) {
            *assembly ~= "JUMP";
            *assembly ~= parent.alt_branch_name;
            break;
        } else {
            parent = parent.parent;
        }
    }
    if(parent is null) {
       throw new Exception("AST to ASM ERROR: no parent while statement found.");
    }
}