module assembler;

import std.math: pow;
import std.stdio;
import std.algorithm;
import structures;


public:
ubyte[] assemble(Program* program) {
    mnemonic_node*[] assembly;
    foreach(Function func; program.functions) {
        func_to_assembly(func, &assembly);
    }
    return compile_to_bytecode(&assembly);
}
private:

void func_to_assembly(Function func, mnemonic_node*[]* assembly) {
    assemble_function_arguments(func, assembly);
    foreach(Statement* statement; func.get_statements()) {
        assemble_statement(statement, assembly);
    }
}

void assemble_function_arguments(Function func, mnemonic_node*[]* assembly) {
    foreach(Variable* var; func.get_arguments()) {
        mnemonic_node* node = new mnemonic_node();
        node.target_name = var.name;
        node.type = var.type;
        node.labels ~= "declare";
        *assembly ~= node;
    }
    foreach(Variable* var; func.get_local_variables()) {
        mnemonic_node* node = new mnemonic_node();
        node.target_name = var.name;
        node.type = var.type;
        node.labels ~= "declare";
        *assembly ~= node;
    }
}

void assemble_statement(Statement* statement, mnemonic_node*[]* assembly) {
    switch(statement.stmt_type) {
        case StatementTypes.assign_statement:
            assemble_expression(statement.syntax_tree, assembly);
            assign_to_var(statement.name, statement.var_type, assembly);
            break;
        default:
            return;
        // TODO more statements
    }
}


void assemble_expression(Expression* ast, mnemonic_node*[]* assembly) {
    if(ast is null) {
        return;
    }
    assemble_expression(ast.left, assembly);
    assemble_expression(ast.right, assembly);

    mnemonic_node* node = new mnemonic_node();
    node.type = ast.var_type;
    if(ast.exp_type == ExpTypes.Variable) {
        node.opcode = opcodes.iPUSHc;
        node.iconstant = to_long(ast.var_name);
    } else if(ast.exp_type == ExpTypes.Operator) {
        node.opcode = get_operator(ast.var_name);
    }

    *assembly ~= node;
}

void assign_to_var(string name, int varType, mnemonic_node*[]* assembly) {
    mnemonic_node* node = new mnemonic_node();
    node.target_name = name;
    node.type = varType;
    node.opcode = opcodes.iMOVE;
    node.labels ~= name;
    *assembly ~= node;
}

long to_long(string str) {
    char[] digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    char[] chars = cast(char[]) str;
    long digit = 0;
    long result = 0;
    long len = chars.length - 1;
    for(long i = chars.length - 1; i >= 0; i--) {
        for(long j = 0; j < digits.length; j++) {
            if(chars[i] == digits[j]) {
                digit = j;
                break;
            }
        }
        digit = digit * pow(10, len - i);
        result += digit;
    }
    return result;
}

ubyte get_operator(string operator_literal) {
    ubyte code;
    final switch(operator_literal) {
        case "+":
            code = opcodes.iADD;
            break;
        case "-":
            code = opcodes.iSUB;
            break;
        case "*":
            code = opcodes.iMULT;
            break;
        case "/":
            code = opcodes.iDIV;
            break;
        case "^":
            code = opcodes.iEXP;
            break;
        case "%":
            code = opcodes.iMOD;
            break;
        case ">":
            code = opcodes.iGT;
            break;
        case "<":
            code = opcodes.iLT;
            break;
        case "<=":
            code = opcodes.iLTEQ;
            break;
        case ">=":
            code = opcodes.iGTEQ;
            break;
        case "==":
            code = opcodes.iEQ;
            break;
        case "!=":
            code = opcodes.iNEQ;
            break;
        case "&":
            code = opcodes.AND;
            break;
        case "|":
            code = opcodes.OR;
            break;
        case "!":
            code = opcodes.NOT;
            break;
    }
    return code;
}

ubyte[] compile_to_bytecode(mnemonic_node*[]* assembly) {
    ubyte[] bytecode;
    return bytecode;
}

void display_asm(mnemonic_node*[]* assembly) {
    foreach(mnemonic_node* node; *assembly) {
        writeln(show_asm(node.opcode), ": ", node.target_name, node.iconstant, node.cconstant);
        write("labels: ");
        foreach(string str; node.labels) {
            write(str, " ");
        }
        writeln();
    }
}


string show_asm(ubyte opcode) {
    string name;
    switch(opcode) {
        case opcodes.SAVEFRAME:
            name = "SAVEFRAME";
            break;
        case opcodes.LOADFRAME:
            name = "LOADFRAME";
            break;
        case opcodes.SAVEINSTRUCTION:
            name = "SAVEINSTRUCTION";
            break;
        case opcodes.LOADINSTRUCTION:
            name = "LOADINSTRUCTION";
            break;
        case opcodes.ROLLBACK:
            name = "ROLLBACK";
            break;
        case opcodes.iADD:
            name = "iADD";
            break;
        case opcodes.iSUB:
            name = "iSUB";
            break;
        case opcodes.iMULT:
            name = "iMULT";
            break;
        case opcodes.iDIV:
            name = "iDIV";
            break;
        case opcodes.iEXP:
            name = "iEXP";
            break;
        case opcodes.iMOD:
            name = "iMOD";
            break;
        case opcodes.AND:
            name = "AND";
            break;
        case opcodes.OR:
            name = "OR";
            break;
        case opcodes.NOT:
            name = "NOT";
            break;
        case opcodes.iEQ:
            name = "iEQ";
            break;
        case opcodes.iNEQ:
            name = "iNEQ";
            break;
        case opcodes.iLT:
            name = "iLT";
            break;
        case opcodes.iGT:
            name = "iGT";
            break;
        case opcodes.iLTEQ:
            name = "iLTEQ";
            break;
        case opcodes.iGTEQ:
            name = "iGTEQ";
            break;
        case opcodes.chEQ:
            name = "chEQ";
            break;
        case opcodes.chNEQ:
            name = "chNEQ";
            break;
        case opcodes.chLT:
            name = "chLT";
            break;
        case opcodes.chGT:
            name = "chGT";
            break;
        case opcodes.chLTEQ:
            name = "chLTEQ";
            break;
        case opcodes.chGTEQ:
            name = "chGTEQ";
            break;
        case opcodes.iPUSHc:
            name = "iPUSHc";
            break;
        case opcodes.iPUSHv:
            name = "iPUSHv";
            break;
        case opcodes.chPUSHc:
            name = "chPUSHc";
            break;
        case opcodes.chPUSHv:
            name = "chPUSHv";
            break;
        case opcodes.iMOVE:
            name = "iMOVE";
            break;
        case opcodes.chMOVE:
            name = "chMOVE";
            break;
        case opcodes.JUMP:
            name = "JUMP";
            break;
        case opcodes.chJUMPNEQ:
            name = "chJUMPNEQ";
            break;
        case opcodes.chJUMPEQ:
            name = "chJUMPEQ";
            break;
        case opcodes.iJUMPNEQ:
            name = "iJUMPNEQ";
            break;
        case opcodes.iJUMPEQ:
            name = "iJUMPEQ";
            break;
        case opcodes.iPUT:
            name = "iPUT";
            break;
        case opcodes.iPUTLN:
            name = "iPUTLN";
            break;
        case opcodes.INPUT:
            name = "INPUT";
            break;
        case opcodes.HALT:
            name = "HALT";
            break;
        default:
            name = "UNKNOWN";
    }
    return name;
}