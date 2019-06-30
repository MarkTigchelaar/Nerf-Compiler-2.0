module code_generation;

import symbol_table;
import structures;
import std.stdio;
import stack;
import std.conv;
import std.algorithm;


void generate_mnemonic_code(Program* program, SymbolTable table) {
    program.current = new mnemonic_node;
    write_out_main(program, table);
    write_out_other_fns(program, table);
    sift_variable_declarations(program);
}

void write_out_main(Program* program, SymbolTable table) {
    program.current.labels ~= "declare_function_main";
    program.current.labels ~= "declare_locals";
	foreach(Function* f; program.functions) {
		if(f.name == "main") {
			write_out_function(f, program, table);
			break;
		}
	}
    program.current = new mnemonic_node;
    program.current.opcode = opcodes.HALT;
    append(program);
}

void write_out_other_fns(Program* program, SymbolTable table) {
	foreach(Function* func; program.functions) {
		if(func.name != "main") {
            program.current = new mnemonic_node;
            program.current.labels ~= "declare_function_" ~ func.name;
            program.current.variable = "return_value";
            append(program);
            program.current = new mnemonic_node;
            program.current.variable = "return_address";
            append(program);
            write_out_function_arguments(func, program, table);
            program.current = new mnemonic_node;
            program.current.labels ~=  "declare_locals";
            write_out_function(func, program, table);
            end_non_main_functions(program);
		}
	}
}

void write_out_function(Function* func, Program* program, SymbolTable table) {
	foreach(Statement* stmt; func.stmts) {
		write_out_statement(program, stmt, table);
	}
    program.current.labels ~= "func_end";
    append(program);
}

void write_out_statement(
      Program* program, Statement* statement, SymbolTable table) {
    final switch(statement.stmt_type) {
        case StatementTypes.assign_statement:
            writeout_assignment_statement(program, statement, table);
            break;
        case StatementTypes.re_assign_statement:
            writeout_re_assignment_statement(program, statement, table);
            break;
        case StatementTypes.break_statement:
            write_out_break_statement(program, statement, table);
            break;
        case StatementTypes.return_statement:
            write_out_return_statement(program, statement, table);
            break;
        case StatementTypes.if_statement:
            write_out_if_statement(program, statement, table);
            break;
        case StatementTypes.else_statement:
            write_out_else_statement(program, statement, table);
            break;
        case StatementTypes.else_if_statement:
            write_out_else_if_statement(program, statement, table);
            break;
        case StatementTypes.while_statement:
            write_out_while_statement(program, statement, table);
            break;
        case StatementTypes.continue_statement:
            write_out_continue_statement(program, statement, table);
            break;
        case StatementTypes.print_statement:
            writeout_print_statement(program, statement, table);
            break;
    }
}

void writeout_assignment_statement(Program* program, Statement* statement, SymbolTable table) {
    program.current ~= "declare_" ~ statement.var_type ~ "_" ~ statement.name;
    append(program);
    statement.syntax_tree.var_type = statement.var_type;
    writeout_rvalue_expressions(program, statement.syntax_tree, table);
    program.mnemonic_code ~= "MOVE";
    program.mnemonic_code ~= statement.var_type ~ "_" ~statement.name;
    
}

void writeout_re_assignment_statement(Program* program, Statement* statement, SymbolTable table) {
    writeout_rvalue_expressions(program, statement.syntax_tree, table);
    program.mnemonic_code ~= "MOVE";
    program.mnemonic_code ~= statement.syntax_tree.var_type ~ "_" ~ statement.name;
}

void writeout_rvalue_expressions(Program* program, Expression* syntax_tree, SymbolTable table) {
    if(syntax_tree is null) {
        return;
    }
    
    writeout_rvalue_expressions(program, syntax_tree.left, table);
    writeout_rvalue_expressions(program, syntax_tree.right, table);
    program.current = new mnemonic_node;
    if(table.is_number(syntax_tree.var_name)) {
        program.current.opcode = program.opcodes["PUSHc"];
        append(program);
        program.current = new mnemonic_node;
        program.current.variabe = syntax_tree.var_name;
    } else if(table.is_operator(syntax_tree.var_name)) {
        char op_type;
        final switch(syntax_tree.var_type) {
            case "int":
                op_type = 'i';
                break;
            case "float":
                op_type = 'f';
                break;
            case "bool":
                op_type = 'b';
                break;
        }
        program.mnemonic_code ~= table.get_asm_operator(syntax_tree.var_name) ~ op_type;
    } else if(table.is_boolean(syntax_tree.var_name)) {
        program.mnemonic_code ~= "PUSHc";
        program.mnemonic_code ~= syntax_tree.var_name;
    } else if(syntax_tree.args !is null) {
        program.mnemonic_code ~= "PUSHc";
        program.mnemonic_code ~= "0";
        program.mnemonic_code ~= "SETRETURN";
        program.mnemonic_code ~= to!string(2*syntax_tree.args.length + 5);// # of inst after func returns
        foreach(Expression* exp; syntax_tree.args) {
            writeout_rvalue_expressions(program, exp, table);
        }
        program.mnemonic_code ~= "LOAD";
        program.mnemonic_code ~= "function_" ~ syntax_tree.var_name;
        program.mnemonic_code ~= "LINKFUNC";
        program.mnemonic_code ~= "function_" ~ syntax_tree.var_name;
        // Assembler finds length of func instructions for 
    } else if(table.is_valid_variable(syntax_tree.var_name)) {
        program.mnemonic_code ~= "PUSHv";
        program.mnemonic_code ~= syntax_tree.var_type ~ "_" ~ syntax_tree.var_name;
    }
}

void write_out_if_statement(Program* program, Statement* statement, SymbolTable table) {
    writeout_rvalue_expressions(program, statement.syntax_tree, table);
    write_out_jump_comparison(program, "if_" ~ to!string(statement.depth) ~ "_end");
    foreach(Statement* s; statement.stmts) {
        write_out_statement(program, s, table);
    }
    program.mnemonic_code ~= "if_" ~ to!string(statement.depth) ~ "_end";
}

void write_out_else_if_statement(Program* program, Statement* statement, SymbolTable table) {
    if(program.mnemonic_code[program.mnemonic_code.length - 1] == "if_" ~ to!string(statement.depth) ~ "_end") {
        program.mnemonic_code[program.mnemonic_code.length - 1] = "JUMP";
        program.mnemonic_code ~= "if_" ~ to!string(statement.depth) ~ "_chain_end";
        program.mnemonic_code ~= "if_" ~ to!string(statement.depth) ~ "_end";
    } else if(program.mnemonic_code[program.mnemonic_code.length - 1] == "if_" ~ to!string(statement.depth) ~ "_chain_end") {
        program.mnemonic_code[program.mnemonic_code.length - 1] = "";
    }

    writeout_rvalue_expressions(program, statement.syntax_tree, table);
    write_out_jump_comparison(program, "if_" ~ to!string(statement.depth) ~ "_end");

    foreach(Statement* s; statement.stmts) {
        write_out_statement(program, s, table);
    }
    program.mnemonic_code ~= "JUMP";
    program.mnemonic_code ~= "if_" ~ to!string(statement.depth) ~ "_chain_end";
    program.mnemonic_code ~= "if_" ~ to!string(statement.depth) ~ "_end";
    program.mnemonic_code ~= "if_" ~ to!string(statement.depth) ~ "_chain_end";
}

void write_out_else_statement(Program* program, Statement* statement, SymbolTable table) {
    if(program.mnemonic_code[program.mnemonic_code.length - 1] == "if_" ~ to!string(statement.depth) ~ "_end") {
        program.mnemonic_code[program.mnemonic_code.length - 1] = "JUMP";
        program.mnemonic_code ~= "if_" ~ to!string(statement.depth) ~ "_chain_end";
        program.mnemonic_code ~= "if_" ~ to!string(statement.depth) ~ "_end";
    } else if(program.mnemonic_code[program.mnemonic_code.length - 1] == 
      "if_" ~ to!string(statement.depth) ~ "_chain_end") {
        program.mnemonic_code = program.mnemonic_code[0 .. $ - 1];
    }
    foreach(Statement* s; statement.stmts) {
        write_out_statement(program, s, table);
    }
    program.mnemonic_code ~= "if_" ~ to!string(statement.depth) ~ "_chain_end";
}


void write_out_function_arguments(Function* func, Program* program, SymbolTable table) {
    for(ulong i = 0; i < func.arg_names.length; i++) {
        program.current = new mnemonic_node;
        program.current.variable ~= "declare_" ~ func.arg_types[i] ~ "_" ~ func.arg_names[i];
        append(program);
    }
}

void write_out_jump_comparison(Program* program, string label) {
    program.mnemonic_code ~= "PUSHc";
    program.mnemonic_code ~= "1";
    program.mnemonic_code ~= "JUMPNEQ";
    program.mnemonic_code ~= label;
}

void write_out_while_statement(Program* program, Statement* statement, SymbolTable table) {
    program.mnemonic_code ~= "while_" ~ to!string(statement.depth) ~ "_start";
    writeout_rvalue_expressions(program, statement.syntax_tree, table);
    write_out_jump_comparison(program, "while_" ~ to!string(statement.depth) ~ "_end");
    foreach(Statement* s; statement.stmts) {
        write_out_statement(program, s, table);
    }
    program.mnemonic_code ~= "JUMP";
    program.mnemonic_code ~= "while_" ~ to!string(statement.depth) ~ "_start";
    program.mnemonic_code ~= "while_" ~ to!string(statement.depth) ~ "_end";
}

void write_out_break_statement(Program* program, Statement* statement, SymbolTable table) {
    program.mnemonic_code ~= "JUMP";
    program.mnemonic_code ~= "while_#_end";
}

void write_out_continue_statement(Program* program, Statement* statement, SymbolTable table) {
    program.mnemonic_code ~= "JUMP";
    program.mnemonic_code ~= "while_#_start";
}

void write_out_return_statement(Program* program, Statement* statement, SymbolTable table) {
    writeout_rvalue_expressions(program, statement.syntax_tree, table);
    program.mnemonic_code ~= "JUMP";
    program.mnemonic_code ~= "func_end";
}


void end_non_main_functions(Program* program) {
    program.mnemonic_code ~= "MOVE";
    program.mnemonic_code ~= "return_value";
    program.mnemonic_code ~= "ROLLBACK";
    program.mnemonic_code ~= "return_address";
    program.mnemonic_code ~= "LINKRETURN";
    program.mnemonic_code ~= "return_address";
}

void writeout_print_statement(Program* program, Statement* statement, SymbolTable table) {
    foreach_reverse(Expression* arg_tree; statement.syntax_tree.args) {
        writeout_rvalue_expressions(program, arg_tree, table);
    }
    for(long i = 0; i < statement.syntax_tree.args.length; i++) {
        program.mnemonic_code ~= "PUT";
    }
}

void sift_variable_declarations(Program* program) {
    for(long i = 0; i < program.mnemonic_code.length; i++) {
        if(program.mnemonic_code[i].startsWith("declare_function_")) {
            sift_in_func(program, i+1);
        }
    }
}

void sift_in_func(Program* program, long start) {
    for(long i = start; i < program.mnemonic_code.length; i++) {
        if(program.mnemonic_code[i].startsWith("declare_function_")) {
            return;
        }
        if(program.mnemonic_code[i].startsWith("declare_")) {
            bubble_up_variable(program, i);
        }
    }
}

void bubble_up_variable(Program* program, long start) {
    string var_declare = program.mnemonic_code[start];
    start--;
    for(long i = start; i > 0; i--) {
        if(program.mnemonic_code[i].startsWith("declare_function_")) {
            break;
        } else if(program.mnemonic_code[i].startsWith("declare_")) {
            program.mnemonic_code[i + 1] = var_declare;
            break;
        } else if(program.mnemonic_code[i].startsWith("return_")) {
            program.mnemonic_code[i + 1] = var_declare;
            break;
        } else {
            program.mnemonic_code[i + 1] = program.mnemonic_code[i];
        }
    }
}

void append(Program* program) {
    program.mnemonic_code ~= program.current;
    program.current = null;
}