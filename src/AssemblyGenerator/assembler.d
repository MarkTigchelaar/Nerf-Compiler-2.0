module assembler;

import std.math: pow;
import std.stdio;
import std.string;
import std.algorithm;
import std.conv: to;
import structures;
import core.sys.posix.stdlib: exit;

struct ByteCodeProgram {
    ubyte[] compiled_program;
    double[] fp_constants;
}

class Assembler {

    private string[] assembly;
    private ByteCodeProgram* product;
    private long[string] label_locations;
    private static char[] digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    private ubyte[] integer;

    
    this() {
        product = new ByteCodeProgram();
        integer = new ubyte[8];
    }

    public void load_from_file(string filename) {
        if(!endsWith(filename, ".asm")) {
            writeln("ERROR: Input file does not have .asm extension.");
            exit(1);
        }
        try {
            File asm_file = File(filename, "r");
            while(!asm_file.eof()) {
                assembly ~= strip(asm_file.readln());
            }
            asm_file.close();
        } catch(Exception exc) {
            writeln(exc.msg);
            exit(1);
        }
    }

    public void load_from_compiler(string[] asm_program) {
        assembly = asm_program;
    }

    // memory location is in bytes, adjust 64 bit integers to show this
    private void process_offsets() {
        string[] temp;
        string test_value;
        for(long i = 0; i < assembly.length; i++) {
            temp ~= assembly[i];
            if(startsWith(assembly[i], ">")) { //writeln("here  ", assembly[i]);
                string[] label_and_op = split(assembly[i], ':');
                test_value = label_and_op[1][0..$];
            } else {
                test_value = assembly[i];
            }
            if(is_const_int_or_ptr_operation(test_value)) {//writeln("and here  ", test_value);
                //if(startsWith(assembly[i], ":")) {
                //    assembly[i] = assembly[i][1 .. $];
                //}
                i++;
                temp ~= assembly[i];
                for(int j = 1; j <= 7; j++) {
                    temp ~= " ";
                }
            }
        }
        assembly = temp;
    }

    private void process_labels() {
        for(long index = 0; index < assembly.length; index++) {
            if(startsWith(assembly[index], ">")) {
                string[] label_and_op = split(assembly[index], ':');
                label_locations[label_and_op[0][1..$]] = index;
                assembly[index] = label_and_op[1];
            }
        }
    }

    private void process_variable_declarations() {
        string[] temp;
        for(long i = 0; i < assembly.length; i++) {
            if(startsWith(assembly[i], "<")) {
                string declare = assembly[i][1 .. $];
                string[] name_and_offset = split(declare, ":");
                label_locations[name_and_offset[0]] = str_to_int(name_and_offset[1]);
            } else {
                temp ~= assembly[i];
            }
        }
        assembly = temp;
    }

    public ByteCodeProgram* assemble() {
        process_variable_declarations();
        process_offsets();
        process_labels();

        foreach(string str; assembly) { //writeln(str);
            ubyte op = get_operator(str);
            if(op != ubyte.max) {
                product.compiled_program ~= op;
            } else if(is_label(str)){
                assemble_label(str);
            } else if(is_integer(str)) {
                assemble_int_const(str);
            } else if(is_float(str)) {
                assemble_float_const(str);
            } else if(is_char(str)) {
                assemble_char(str);
            } else if(str == " ") {
                continue;
            } else {
                writeln("ERROR: unknown operation or type.");
                exit(1);
            }
        }//writeln('\n');
        return product;
    }

    private bool is_integer(string str) {
        char[] chars = cast(char[]) str;
        foreach(char ch; chars) {
            bool found = false;
            foreach(char digit; digits) {
                if(ch == digit) {
                    found = true;
                    break;
                }
            }
            if(!found) {
                return false;
            }
        }
        return true;
    }

    private void assemble_int_const(string str) {
        long result = str_to_int(str);
        to_array_int(result);
        append_integer_to_bytecode();
    }

    private long str_to_int(string str) {
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

    private bool is_char(string str) {
        if(startsWith(str, "'") && endsWith(str, "'") && str.length == 3) {
            return true;
        }
        return false;
    }

    private bool is_float(string str) {
        char[] chars = cast(char[]) str;
        long decimal_location = -1;
        for(long i = 0; i < chars.length; i++) {
            if(chars[i] == '.') {
                decimal_location = i;
                break;
            }
        }
        if(decimal_location == -1) {
            return false;
        } else if(decimal_location == chars.length - 1) {
            return false;
        }
        return is_integer(cast(string) chars[0 .. decimal_location]) && 
               is_integer(cast(string) chars[decimal_location + 1 .. $]);
    }

    private void assemble_float_const(string str) {
        product.fp_constants ~= to!double(str);
        to_array_int(product.fp_constants.length - 1);
        append_integer_to_bytecode();
    }

    // chars in the asm program are in the form of 'a', 'b' etc ...
    private void assemble_char(string str) {
        char[] chars = cast(char[]) str;
        product.compiled_program ~= cast(ubyte) chars[1];
    }

    private void to_array_int(long result) {
        ulong uvalue = cast(ulong) result;
        ulong temp;
        ulong bit_mask = cast(ulong) ubyte.max << 56;
        ubyte push_value;
        long index = 0;
        for(int i = 64; i > 0; i -= 8) {
            temp = uvalue & bit_mask;
            temp >>>= (i - 8);
            bit_mask >>>= 8;
            push_value = cast(ubyte) temp;
            integer[index] = push_value;
            index++;
        }
    }

    private bool is_const_int_or_ptr_operation(string operation) {
        bool it_is = false;
        if(startsWith(operation,"fp")) {
            return true;
        }

        switch(operation) {
            case "iPUSHc":
                it_is = true;
                break;
            case "iPUSHv":
                it_is = true;
                break;
            case "chPUSHv":
                it_is = true;
                break;
            case "ROLLBACK":
                it_is = true;
                break;
            case "iMOVE":
                it_is = true;
                break;
            case "chMOVE":
                it_is = true;
                break;
            case "fpMOVE":
                it_is = true;
                break;
            case "JUMP":
                it_is = true;
                break;
            case "chJUMPNEQ":
                it_is = true;
                break;
            case "chJUMPEQ":
                it_is = true;
                break;
            case "iJUMPNEQ":
                it_is = true;
                break;
            case "iJUMPEQ":
                it_is = true;
                break;
            default:
                it_is = false;
                break;
        }
        return it_is;
    }

    private bool is_label(string str) {
        if(str in label_locations) {
            return true;
        }
        return false;
    }

    private void assemble_label(string str) {
        to_array_int(label_locations[str]);
        append_integer_to_bytecode();
    }

    private void append_integer_to_bytecode() {
        foreach(ubyte bt; integer) {
            product.compiled_program ~= bt;
        }
    }
}

ubyte get_operator(string operator_literal) {
    ubyte code;
    switch(operator_literal) {
        case "iADD":
            code = opcodes.iADD;
            break;
        case "iSUB":
            code = opcodes.iSUB;
            break;
        case "iMULT":
            code = opcodes.iMULT;
            break;
        case "iDIV":
            code = opcodes.iDIV;
            break;
        case "iEXP":
            code = opcodes.iEXP;
            break;
        case "iMOD":
            code = opcodes.iMOD;
            break;
        case "iGT":
            code = opcodes.iGT;
            break;
        case "iLT":
            code = opcodes.iLT;
            break;
        case "iLTEQ":
            code = opcodes.iLTEQ;
            break;
        case "iGTEQ":
            code = opcodes.iGTEQ;
            break;
        case "iEQ":
            code = opcodes.iEQ;
            break;
        case "iNEQ":
            code = opcodes.iNEQ;
            break;
        case "chEQ":
            code = opcodes.chEQ;
            break;
        case "chNEQ":
            code = opcodes.chNEQ;
            break;
        case "chLT":
            code = opcodes.chLT;
            break;
        case "chGT":
            code = opcodes.chGT;
            break;
        case "chLTEQ":
            code = opcodes.chLTEQ;
            break;
        case "chGTEQ":
            code = opcodes.chGTEQ;
            break;
        case "fpEQ":
            code = opcodes.fpEQ;
            break;
        case "fpNEQ":
            code = opcodes.fpNEQ;
            break;
        case "fpLT":
            code = opcodes.fpLT;
            break;
        case "fpGT":
            code = opcodes.fpGT;
            break;
        case "fpLTEQ":
            code = opcodes.fpLTEQ;
            break;
        case "fpGTEQ":
            code = opcodes.fpGTEQ;
            break;
        case "iPUSHc":
            code = opcodes.iPUSHc;
            break;
        case "iPUSHv":
            code = opcodes.iPUSHv;
            break;
        case "chPUSHc":
            code = opcodes.chPUSHc;
            break;
        case "chPUSHv":
            code = opcodes.chPUSHv;
            break;
        case "fpPUSHc":
            code = opcodes.fpPUSHc;
            break;
        case "fpPUShv":
            code = opcodes.fpPUShv;
            break;
        case "iMOVE":
            code = opcodes.iMOVE;
            break;
        case "chMOVE":
            code = opcodes.chMOVE;
            break;
        case "fpMOVE":
            code = opcodes.fpMOVE;
            break;
        case "NEWARRAY":
            code = opcodes.NEWARRAY;
            break;
        case "DELARRAY":
            code = opcodes.DELARRAY;
            break;
        case "chARRINSERT":
            code = opcodes.chARRINSERT;
            break;
        case "chARRGET":
            code = opcodes.chARRGET;
            break;
        case "chARRAPPEND":
            code = opcodes.chARRAPPEND;
            break;
        case "chARRDUPLICATE":
            code = opcodes.chARRDUPLICATE;
            break;
        case "iARRINSERT":
            code = opcodes.iARRINSERT;
            break;
        case "iARRGET":
            code = opcodes.iARRGET;
            break;
        case "iARRAPPEND":
            code = opcodes.iARRAPPEND;
            break;
        case "iARRDUPLICATE":
            code = opcodes.iARRDUPLICATE;
            break;
        case "fpARRINSERT":
            code = opcodes.fpARRINSERT;
            break;
        case "fpARRGET":
            code = opcodes.fpARRGET;
            break;
        case "fpARRAPPEND":
            code = opcodes.fpARRAPPEND;
            break;
        case "fpARRDUPLICATE":
            code = opcodes.fpARRDUPLICATE;
            break;
        case "JUMP":
            code = opcodes.JUMP;
            break;
        case "chJUMPNEQ":
            code = opcodes.chJUMPNEQ;
            break;
        case "chJUMPEQ":
            code = opcodes.chJUMPEQ;
            break;
        case "iJUMPNEQ":
            code = opcodes.iJUMPNEQ;
            break;
        case "iJUMPEQ":
            code = opcodes.iJUMPEQ;
            break;
        case "fpJUMPNEQ":
            code = opcodes.fpJUMPNEQ;
            break;
        case "fpJUMPEQ":
            code = opcodes.fpJUMPEQ;
            break;
        case "chPUT":
            code = opcodes.chPUT;
            break;
        case "chPUTLN":
            code = opcodes.chPUTLN;
            break;
        case "iPUT":
            code = opcodes.iPUT;
            break;
        case "iPUTLN":
            code = opcodes.iPUTLN;
            break;
        case "fpPUT":
            code = opcodes.fpPUT;
            break;
        case "fpPUTLN":
            code = opcodes.fpPUTLN;
            break;
        case "INPUT":
            code = opcodes.INPUT;
            break;
        case "HALT":
            code = opcodes.HALT;
            break;
        default:
            code = ubyte.max;
            break;
    }
    return code;
}








/*
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
*/