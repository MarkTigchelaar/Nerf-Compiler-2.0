module assembler;

import std.math: pow;
import std.stdio;
import std.string;
import std.algorithm;
import std.conv: to;
import opcodes: opcodes, get_operator;
import core.sys.posix.stdlib: exit;

struct ByteCodeProgram {
    ubyte[] compiled_program;
    double[] fp_constants;
}

class Assembler {

    private string[] assembly;
    private ByteCodeProgram* product;
    private long[string] label_locations;
    private long[string] var_locations;
    private long[string] call_locations;
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

    public ByteCodeProgram* assemble() {
        insert_label_offsets();
        resolve_label_locations();
/*
        writeln("variable keys: ");
        foreach(string key; var_locations.byKey) {
            writeln(key, ' ', var_locations[key]);
        }

        writeln("label keys: ");
        foreach(string key; label_locations.byKey) {
            writeln(key, ' ', label_locations[key]);
        }

        writeln("func call keys: ");
        foreach(string key; call_locations.byKey) {
            writeln(key, ' ',call_locations[key]);
        }
*/
        foreach(long i, string str; assembly) { //writeln(str);
            ubyte op = get_operator(str);
            if(op != ubyte.max) {
                product.compiled_program ~= op;
            } else if(is_label(str)) {
                assemble_label(str, i);
            } else if(is_variable_dec(str)) {
                assemble_variable_dec(str);
            } else if(is_variable_ref(str)) {
                assemble_variable_ref(str, i);
            } else if(is_integer(str)) {
                assemble_int_const(str);
            } else if(is_float(str)) {
                assemble_float_const(str);
            } else if(is_char(str)) {
                assemble_char(str);
            } else if(is_func_call(str)) {
                assemble_func_call(str);
            } else if(str == " ") {
                continue;
            } else {
                writeln("ERROR: unknown operation or type: " ~ str);
                exit(1);
            }
        }//writeln("end \n");
        return product;
    }

    // memory location is in bytes, adjust 64 bit integers to show this
    private void insert_label_offsets() {
        string[] temp;
        string test_value;
        for(long i = 0; i < assembly.length; i++) {
            temp ~= assembly[i];
            string[] label_and_op = split(assembly[i], ':');
            if(label_and_op.length == 1) {
                if(is_const_int_or_ptr_operation(assembly[i])) {
                    i++;
                    temp ~= assembly[i];
                    for(int j = 1; j <= 7; j++) {
                        temp ~= " ";
                    }
                }
            }
            if(startsWith(assembly[i], ">")) {
                test_value = label_and_op[1][0..$];
                if(is_const_int_or_ptr_operation(test_value)) {
                    i++;
                    temp ~= assembly[i];
                    for(int j = 1; j <= 7; j++) {
                        temp ~= " ";
                    }
                }
            } else if(startsWith(assembly[i], "<")) {
                long number = str_to_int(label_and_op[1]);
                for(long j = 0; j < number - 1; j++) {
                    temp ~= " ";
                }
            } else if (startsWith(assembly[i], "`")) {
                for(int k = 0; k < 7; k++) {
                    temp ~= " ";
                }
            }
        }
        assembly = temp;
        //foreach(string str; assembly) {
        //    writeln(str);
        //}
        //writeln("assembly length: ", assembly.length);
    }

    private void resolve_label_locations() {
        string[] label_and_op;
        for(long index = 0; index < assembly.length; index++) {
            if(startsWith(assembly[index], "`")) {
                //label_and_op = split(assembly[index], ":");
                //call_locations[label_and_op[0][1..$]] = index;
                call_locations[assembly[index][1 .. $]] = index;
                assembly[index] = function_size_as_string(index);//label_and_op[1];
            } else if(startsWith(assembly[index], ">")) {
                label_and_op = split(assembly[index], ':');
                label_locations[label_and_op[0][1..$]] = index;
                assembly[index] = label_and_op[1];
            } else if(startsWith(assembly[index], "<")) {
                label_and_op = split(assembly[index], ':');
                string var_name = label_and_op[0][1..$];
                var_locations[var_name] = index;
            }
        }
    }

    private bool is_integer(string str) {
        if(startsWith(str, "-")) {
            str = str[1..$];
        }
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
        bool is_neg = false;
        if(startsWith(str, "-")) {
            str = str[1..$];
            is_neg = true;
        }
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
        if(is_neg) {
            result *= -1;
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
            case "CALL":
                it_is = true;
                break;
            case "LOADSTACK":
                it_is = true;
                break;
            case "iPUSHc":
                it_is = true;
                break;
            case "iPUSHv":
                it_is = true;
                break;
            case "iLTEQ":
                it_is = true;
                break;
            case "iGTEQ":
                it_is = true;
                break;
            case "iLT":
                it_is = true;
                break;
            case "iGT":
                it_is = true;
                break;
            case "iEQ":
                it_is = true;
                break;
            case "iNEQ":
                it_is = true;
                break;
            case "chPUSHv":
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
            case "iJUMPLT":
                it_is = true;
                break;
            case "iJUMPGT":
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

    private void assemble_label(string str, long var_index) {
        to_array_int(label_locations[str] - var_index - 8);
        append_integer_to_bytecode();
    }

    private bool is_func_call(string str) {
        if(str in call_locations) {
            return true;
        }
        return false;
    }

    private void assemble_func_call(string str) {
        long bytes_to_skip = 0;
        for(long i = 0; i < call_locations[str]; i++) {
            if(startsWith(assembly[i], "<~")) {
                string[] label_and_size = split(assembly[i], ":");
                bytes_to_skip += str_to_int(label_and_size[1]);
            }
        }
        to_array_int(call_locations[str] - bytes_to_skip);
        append_integer_to_bytecode();
    }

    // This works because main is always starting at index 0,
    // and all other functions begin with `.
    private string function_size_as_string(long func_index) {
        long size = -1;
        func_index += 8;
        for(long index = func_index; index < assembly.length; index++) {
            if(startsWith(assembly[index], "`")) {
                size = index - func_index;
                break;
            }
        }
        if(size < 0) {
            size = assembly.length - func_index;
        }
        return int_as_string(size);
    }

    private bool is_variable_ref(string str) {
        if(str in var_locations) {
            return true;
        } else if("~" ~ str in var_locations) {
            return true;
        }
        return false;
    }

    private void assemble_variable_ref(string var, long var_index) {

        if(var in var_locations) {
            to_array_int(var_index - var_locations[var]);
        } else if("~" ~ var in var_locations) {
            to_array_int(var_index - var_locations["~" ~ var]);
        }
        append_integer_to_bytecode();
        //writeln("This is the offset:                           ", var_index - var_locations[var]);
    }

    private bool is_variable_dec(string str) {
        return startsWith(str, "<");
    }

    private void assemble_variable_dec(string str) {
        if(startsWith(str[1 .. $], "~")) {
            return;
        }
        string[] components = split(str, ':');
        const long byte_offset = str_to_int(components[1]);
        for(long i = 0; i < byte_offset; i++) {
            product.compiled_program ~= opcodes.MEMALLOC;
        }
    }

    private void append_integer_to_bytecode() {
        foreach(ubyte bt; integer) {
            product.compiled_program ~= bt;
        }
    }

    // In efficient, but function sizes should not be larger
    // than a few thousand bytes max.
    private string int_as_string(long value) {
        char[] str_num = ['0','0','0','0','0','0','0','0','0','0','0','0'];
        for(long i = 1; i <= value; i++) {
            increment_array(str_num);
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
    private void increment_array(char[] str_num) {
        long start = str_num.length - 1;
        while(start >= 0) {
            long index = get_index(str_num[start]);
            if(index < 9) {
                str_num[start] = digits[index + 1];
                break;
            } else { // digit is 9.
                str_num[start] = '0';
                start--;
            }
        }
    }

    private long get_index(char digit) {
        for(long i = 0; i < digits.length; i++) {
            if(digits[i] == digit) {
                return i;
            }
        }
        return 0;
    }
}
