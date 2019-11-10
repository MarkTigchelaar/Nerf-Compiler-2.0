module ByteCodeVM;

import opcodes: opcodes;
import assembler: ByteCodeProgram;
import std.stdio;
/*
    ByteCode Virtual Machine.
    Written by Mark Tigchelaar.

    See bottom of file for description of VM.
*/

class ByteCodeVM {

    private struct heap_node {
        long id;
        ubyte[] bytecode;
        long[] integers;
        double[] floats;
    }

    private ubyte[] instructions;
    private ubyte[] stack;
    private double[] fp_stack;
    private double[] fp_constants;

    private ulong inst_ptr;
    private ulong stk_ptr;
    private ulong fp_stk_ptr;
    private ulong frame_ptr;

    private heap_node*[] lazy_heap;
    private ulong unique_heapitem_id;

    private void delegate()[] operations;

    private long counter;
    private long function_depth;


    this() {
        function_depth = 0;
        stack       = new ubyte[fiftyk];
        fp_stack    = new double[fiftyk];
        fp_constants = new double[fiftyk / 5];
        operations = new void delegate()[inst_count];
        unique_heapitem_id = 0;
        lazy_heap    = new heap_node*[1];
        lazy_heap[0] = new heap_node(-1, null, null);
        set_operations(this);
        set_pointers();
    }

    // Expensive, and optional.
    public void reset() {
        for(ulong i = 0; i < stack.length; i++) {
            stack[i] = 0;
        }
        for(ulong l = 0; l < instructions.length; l++) {
            instructions[l] = 0;
        }
        for(ulong j = 0; j < fp_stack.length; j++) {
            fp_stack[j] = double.init;
        }
        for(ulong k = 0; k < fp_constants.length; k++) {
            fp_constants[k] = double.init;
        }
        set_pointers();
    }

    public void pointers() {
        import std.stdio: writeln;
        writeln("stack pointer: ", stk_ptr, "    instruction pointer: ", inst_ptr);
    }

    public void show_bytecode() {
        import std.stdio: write, writeln;
        writeln("stack length: ", stack.length);
        writeln("Stack:");
        for(long i = 0; i < 200; i++) {
            ubyte bt = stack[i];
            if(i == stk_ptr) {
                write('(');
            }
            if(i == inst_ptr) {
                write('[');
            }
            if(i == counter) {
                write('{');
            }
            write(bt);
            if(i == stk_ptr) {
                write(')');
            }
            if(i == inst_ptr) {
                write(']');
            }
            if(i == counter) {
                write('}');
            }
            if((i + 1) % 8 == 0 && i > 0) {
                write("| ");
            } else {
                write(", ");
            }

            if(i % 31 == 0 && i > 0) {
                writeln();
            }
        }
        writeln('\n');
        writeln("Done showbytecode");
    }



    public void load_bytecode(ubyte[] assembled_program) {
        set_pointers();
        long i = 0;
        foreach(ubyte bt; assembled_program) {
            push(bt);
            i++;
        }
        counter = i - 1;
    }

    public void load_float_constants(double[] floats) {
        fp_constants = floats;
    }

    public void run() {
        while(is_running()) {
            execute_operations();
        }
    }

    private bool is_running() {
        return (inst_ptr < stack.length);
    }

    private void execute_operations() {
        operations[cast(long) fetch_opcode()]();
    }

    private ubyte fetch_opcode() {
        return stack[inst_ptr];
    }

    private void set_pointers() {
        stk_ptr = ulong.max;
        fp_stk_ptr = ulong.max;
        inst_ptr = 0;
        frame_ptr = 0;
        for(ulong i = 0; i < lazy_heap.length; i++) {
            lazy_heap[i].id = -1;
            lazy_heap[i].bytecode = null;
            lazy_heap[i].integers = null;
        }
    }

    private void inc_stk_ptr() {
        stk_ptr++;
        if(stk_ptr >= stack.length - 1) {
            ubyte[] upgrade_stack = new ubyte[stack.length + fiftyk];
            foreach(long i, ubyte bt; stack) {
                upgrade_stack[i] = bt;
            }
            stack = upgrade_stack;
        }
    }

    // avoids convoluted use of ipush and ipop;
    // gets index from instructions, which is offset by current
    // frame pointer value. This supports function calls.
    private ulong collect_int_at(ulong start_idx) {
        ulong temp = 0;
        ulong worker;
        ulong shift_amount = 56;
        for(ulong i = start_idx; i < start_idx + 8; i++) {
            worker = cast(ulong) stack[i];
            worker <<= shift_amount;
            temp += worker;
            shift_amount -= 8;
        }
        return temp;
    }

    private void division_by_zero() {
        error_msg("ERROR: Division by 0!");
    }

    private void array_seg_fault() {
        error_msg("ERROR: Null array reference!");
    }

    private void array_out_of_bounds() {
        error_msg("ERROR: Array index out of bounds!");
    }

    private void stack_overflow() {
        error_msg("ERROR: Maximum stack frames reached!");
    }

    private void error_msg(string message) {
        import core.sys.posix.stdlib: exit;
        import std.stdio: writeln;
        writeln(message);
        exit(1);
    }

    private void push(ubyte value) {
        if(stk_ptr == ulong.max) {
            stk_ptr = 0;
            stack[stk_ptr] = value;
        } else {
            inc_stk_ptr();
            stack[stk_ptr] = value;
        }
    }

    private ubyte pop() {
        if(stk_ptr > stack.length - 1) {
            error_msg("stack pointer off array!");
        }
        ubyte value = stack[stk_ptr];
        stack[stk_ptr] = 0;
        stk_ptr--;
        return value;
    }

    private void mem_alloc() {
        stack[inst_ptr] = cast(ubyte) 0;
        inst_ptr++;
    }

    private void inc_func_depth() {
        function_depth++;
        if(function_depth > max_recursion) {
            stack_overflow();
        }
    }

    private void dec_func_depth() {
        function_depth--;
    }

    private void chpushc() {
        inst_ptr++;
        push(stack[inst_ptr]);
        inst_ptr++;
    }

    private void chpushv() {
        ipushc();
        ulong diff = inst_ptr - cast(ulong) ipop() - 8;
        push(stack[diff]);
    }

    private void ipushc() {
        inst_ptr++;
        for(long i = 0; i < 8; i++) {
            push(stack[inst_ptr]);
            inst_ptr++;
        }
    }

    private void ipushv() {
        // offset from frame pointer is fixed for any function.
        // put frame pointer offset onto stack
        ipushc();
        // get the number at the location, and push it onto the stack.
        ulong diff = inst_ptr - cast(ulong) ipop() - 8;
        ipush(collect_int_at(diff));
    }

    private long ipop() {
        ulong temp = 0;
        ulong worker;
        temp = cast(ulong) pop();
        for(ulong i = 1; i < 8; i++) {
            worker = cast(ulong) pop();
            worker <<= (8 * i);
            temp += worker;
        }
        return cast(long) temp;
    }

    private void ipush(long value) {
        ulong uvalue = cast(ulong) value;
        ulong temp;
        ulong bit_mask = cast(ulong) ubyte.max << 56;
        ubyte push_value;
        for(int i = 64; i > 0; i -= 8) {
            temp = uvalue & bit_mask;
            temp >>>= (i - 8);
            bit_mask >>>= 8;
            push_value = cast(ubyte) temp;
            push(push_value);
        }
    }

    private void ch_move() {
        ubyte value = pop();
        ipushc();
        ulong diff = cast(ulong) ipop();
        ulong temp = stk_ptr;
        stk_ptr = inst_ptr - diff - 9;
        push(value);
        stk_ptr = temp;
    }

    private void imove() {
        ulong value = cast(ulong) ipop();
        ipushc();
        ulong diff = cast(ulong) ipop();
        ulong temp = stk_ptr;
        stk_ptr = inst_ptr - diff - 9;
        ipush(value);
        stk_ptr = temp;
    }

    private void iadd() {
        inst_ptr++;
        ipush(ipop() + ipop());
    }

    private void isub() {
        inst_ptr++;
        long subtrahend = ipop();
        long minuend = ipop();
        ipush(minuend - subtrahend);
    }

    private void imult() {
        inst_ptr++;
        ipush(ipop() * ipop());
    }

    private void idiv() {
        inst_ptr++;
        long divisor = ipop();
        if(divisor == 0) {
            division_by_zero();
        }
        ipush(ipop() / divisor);
    }

    private void iexp() {
        import std.math: pow;
        inst_ptr++;
        long exponent = ipop();
        if(exponent < 0) {
            ipush(0);
        } else {
            ipush(pow(ipop(), exponent));
        }
    }

    private void imod() {
        inst_ptr++;
        long modulo = ipop();
        ipush(ipop() % modulo);
    }

    private void ilessThanEQ() {
        inst_ptr++;
        long right = ipop();
        long left = ipop();
        if(left <= right) {
            ipush(1);
        } else {
            ipush(0);
        }
    }

    private void ilessThan() {
        inst_ptr++;
        long right = ipop();
        long left = ipop();
        if(left < right) {
            ipush(1);
        } else {
            ipush(0);
        }
    }

    private void iGreaterThanEQ() {
        inst_ptr++;
        long right = ipop();
        long left = ipop();
        if(left >= right) {
            ipush(1);
        } else {
            ipush(0);
        }
    }

    private void iGreaterThan() {
        inst_ptr++;
        long right = ipop();
        long left = ipop();
        if(left > right) {
            ipush(1);
        } else {
            ipush(0);
        }
    }

    private void iNotEqual() {
        inst_ptr++;
        long right = ipop();
        long left = ipop();
        if(left != right) {
            ipush(1);
        } else {
            ipush(0);
        }
    }

    private void iEqual() {
        inst_ptr++;
        long right = ipop();
        long left = ipop();
        if(left == right) {
            ipush(1);
        } else {
            ipush(0);
        }
    }

    private void expand_heap() {
        heap_node*[] new_heap = new heap_node*[lazy_heap.length + fiftyk];
        for(ulong i = 0; i < lazy_heap.length; i++) {
            new_heap[i] = lazy_heap[i];
            lazy_heap[i] = null;
        }
        lazy_heap = new_heap;
    }

    private ulong assign_heap_id() {
        ulong id = unique_heapitem_id;
        unique_heapitem_id++;
        if(unique_heapitem_id == lazy_heap.length) {
            expand_heap();
        }
        return id;
    }

    private void new_array() {
        heap_node* node = null;
        for(long i = 0; i <= unique_heapitem_id; i++) {
            if(lazy_heap[i] == null) {
                break;
            } else if(lazy_heap[i].id == -1) {
                node = lazy_heap[i];
                break;
            }
        }
        if(node is null) {
            node = new heap_node;
            lazy_heap ~= node;
        }
        node.id = assign_heap_id();
        ipush(node.id);
    }

    private void delete_array() {
        long array_id = ipop();
        heap_node* node = lazy_heap[find(array_id)];
        node.id = -1;
        node.bytecode = null;
        node.integers = null;
    }

    private long find(long array_id) {
        inst_ptr++;
        for(long i = 0; i <= unique_heapitem_id; i++) {
            if(lazy_heap[i].id == i) {
                return i;
            }
        }
        array_seg_fault();
        return -1;
    }

    private void array_length(bool is_char) {
        inst_ptr++;
        long array_id = ipop();
        heap_node* node = lazy_heap[find(array_id)];
        if(is_char) {
            ipush(cast(long) node.bytecode.length);
        } else {
            ipush(cast(long) node.integers.length);
        }
    }

    private void array_insert(bool is_char) {
        inst_ptr++;
        long array_id = ipop();
        long index = ipop();
        heap_node* node = lazy_heap[find(array_id)];
        if(is_char) {
            if(index >= node.bytecode.length) {
                array_out_of_bounds();
            }
            node.bytecode[index] = pop();
        } else {
            if(index >= node.integers.length) {
                array_out_of_bounds();
            }
            node.integers[index] = ipop();
        }
    }

    private void array_get(bool is_char) {
        inst_ptr++;
        long array_id = ipop();
        long index = ipop();
        heap_node* node = lazy_heap[find(array_id)];
        if(is_char) {
            if(index >= node.bytecode.length) {
                array_out_of_bounds();
            }
            push(node.bytecode[index]);
        } else {
            if(index >= node.integers.length) {
                array_out_of_bounds();
            }
            ipush(node.integers[index]);
        }
    }

    private void array_append(bool is_char) {
        inst_ptr++;
        long array_id = ipop();
        heap_node* node = lazy_heap[find(array_id)];
        if(is_char) {
            node.bytecode ~= pop();
        } else {
            node.integers ~= ipop();
        }
    }

    private void array_duplicate(bool is_char) {
        inst_ptr++;
        long new_array_id;
        heap_node* new_node;
        long old_array_id = ipop();
        heap_node* old_node = lazy_heap[find(old_array_id)];
        new_array();
        new_node = lazy_heap[ipop()];
        if(is_char) {
            new_node.bytecode = old_node.bytecode.dup;
        } else {
            new_node.integers = old_node.integers.dup;
        }
        ipush(new_node.id);
    }

    private void ch_array_insert() {
        bool is_char = true;
        array_insert(is_char);
    }

    private void ch_array_get() {
        bool is_char = true;
        array_get(is_char);
    }

    private void ch_array_append() {
        bool is_char = true;
        array_append(is_char);
    }

    private void ch_array_duplicate() {
        bool is_char = true;
        array_duplicate(is_char);
    }

    private void iarray_insert() {
        bool is_char = false;
        array_insert(is_char);
    }

    private void iarray_get() {
        bool is_char = false;
        array_get(is_char);
    }

    private void iarray_append() {
        bool is_char = false;
        array_append(is_char);
    }

    private void iarray_duplicate() {
        bool is_char = false;
        array_duplicate(is_char);
    }

    private void jump() {
        ipushc();
        long relative_address = ipop();
        long temp = cast(long) inst_ptr;
        temp += relative_address;
        inst_ptr = cast(ulong) temp;
    }

    private void chjump_if_equal() {
        ubyte rhs = pop();
        ubyte lhs = pop();
        if(lhs == rhs) {
            jump();
        } else {
            inst_ptr += 9;
        }
    }

    private void chjump_if_not_equal() {
        ubyte rhs = pop();
        ubyte lhs = pop();
        if(lhs != rhs) {
            jump();
        } else {
            inst_ptr += 9;
        }
    }

    private void ijump_if_equal() {
        long rhs = ipop();
        long lhs = ipop();
        if(lhs == rhs) {
            jump();
        } else {
            inst_ptr += 9;
        }
    }

    private void ijump_if_not_equal() {
        long rhs = ipop();
        long lhs = ipop();
        if(lhs != rhs) {
            jump();
        } else {
            inst_ptr += 9;
        }
    }

    private void ijump_if_lhs_less_than() {
        long rhs = ipop();
        long lhs = ipop();
        if(lhs < rhs) {
            jump();
        } else {
            inst_ptr += 9;
        }
    }

    private void ijump_if_lhs_greater_than() {
        long rhs = ipop();
        long lhs = ipop();
        if(lhs > rhs) {
            jump();
        } else {
            inst_ptr += 9;
        }
    }

    private double fppop() {
        double value = fp_stack[fp_stk_ptr];
        fp_stk_ptr--;
        return value;
    }

    private void fppush(double value) {
        inc_fp_stk_ptr();
        fp_stack[fp_stk_ptr] = value;
    }

/*
    private void fp_pushc() {

    }

    private void fp_pushv() {

    }

    private long fp_move() {

    }
*/
    private void inc_fp_stk_ptr() {
        fp_stk_ptr++;
        if(fp_stk_ptr >= fp_stack.length - 1) {
            double[] upgrade_stack = new double[fp_stack.length + fiftyk];
            foreach(long i, double fp; fp_stack) {
                upgrade_stack[i] = fp;
            }
            fp_stack = upgrade_stack;
        }
    }

    private void fpjump_if_equal() {
        double rhs = fppop();
        double lhs = fppop();
        if(lhs == rhs) {
            jump();
        } else {
            inst_ptr += 9;
        }
    }

    private void fpjump_if_not_equal() {
        double rhs = fppop();
        double lhs = fppop();
        if(lhs != rhs) {
            jump();
        } else {
            inst_ptr += 9;
        }
    }

    private void fpjump_if_lhs_less_than() {
        double rhs = fppop();
        double lhs = fppop();
        if(lhs < rhs) {
            jump();
        } else {
            inst_ptr += 9;
        }
    }

    private void fpjump_if_lhs_greater_than() {
        double rhs = fppop();
        double lhs = fppop();
        if(lhs > rhs) {
            jump();
        } else {
            inst_ptr += 9;
        }
    }

    private void chput() {
        import std.stdio: write;
        write(cast(char) pop());
        inst_ptr++;
    }

    private void chputln() {
        import std.stdio: writeln;
        chput();
        writeln();
    }

    private void iput() {
        import std.stdio: write;
        write(ipop());
        inst_ptr++;
    }

    private void iputln() {
        import std.stdio: writeln;
        iput();
        writeln();
    }

    private void input() {
        import std.stdio: readln;
        import std.string: strip;
        ubyte[] input = cast(ubyte[]) strip(readln());
        long array_id = ipop();
        heap_node* node = lazy_heap[find(array_id)];
        foreach(ubyte bt; input) {
            node.bytecode ~= bt;
        }
        inst_ptr++;
    }

    private void call_func() {
        inc_func_depth();
        ulong save_instruction = inst_ptr;
        ipushc();
        ulong func_template_address = cast(ulong) ipop();
        ulong func_size = collect_int_at(func_template_address);
        ulong start = func_template_address + 8;
        ulong end = start + func_size;
        ulong func_start = stk_ptr + 1;
        for(; start < end; start++) {
            push(stack[start]);
        }
        ipush(save_instruction + 9);
        ipush(func_size);
        inst_ptr = func_start;
    }


    private void ireturn() {
        dec_func_depth();
        long i_ret_val = ipop();
        ulong func_size = cast(ulong) ipop();
        ulong temp_stk_ptr = inst_ptr- func_size;
        inst_ptr = cast(ulong) ipop();
        stk_ptr = temp_stk_ptr;
        ipush(i_ret_val);
    }

    private void chreturn() {
        ubyte ch_ret_val = pop();
        ulong func_size = cast(ulong) ipop();
        ulong temp_stk_ptr = inst_ptr- func_size;
        inst_ptr = cast(ulong) ipop();
        stk_ptr = temp_stk_ptr;
        push(ch_ret_val);
    }

    private void halt() {
        inst_ptr = stack.length + 1;
    }
}

private:

immutable long fiftyk = 50000;
immutable long inst_count = 100;
immutable long max_recursion = 3000;

private:

void set_operations(ByteCodeVM VM) {
    VM.operations[opcodes.MEMALLOC]        = &VM.mem_alloc;
    VM.operations[opcodes.CALL]            = &VM.call_func;
    VM.operations[opcodes.iRETURN]         = &VM.ireturn;
    VM.operations[opcodes.chRETURN]        = &VM.chreturn;

    VM.operations[opcodes.iADD]            = &VM.iadd;
    VM.operations[opcodes.iSUB]            = &VM.isub;
    VM.operations[opcodes.iMULT]           = &VM.imult;
    VM.operations[opcodes.iDIV]            = &VM.idiv;
    VM.operations[opcodes.iEXP]            = &VM.iexp;
    VM.operations[opcodes.iMOD]            = &VM.imod;

    VM.operations[opcodes.iLTEQ]           = &VM.ilessThanEQ;
    VM.operations[opcodes.iGTEQ]           = &VM.iGreaterThanEQ;
    VM.operations[opcodes.iLT]             = &VM.ilessThan;
    VM.operations[opcodes.iGT]             = &VM.iGreaterThan;
    VM.operations[opcodes.iEQ]             = &VM.iEqual;
    VM.operations[opcodes.iNEQ]            = &VM.iNotEqual;

    VM.operations[opcodes.iPUSHc]          = &VM.ipushc;
    VM.operations[opcodes.iPUSHv]          = &VM.ipushv;

    VM.operations[opcodes.chPUSHc]         = &VM.chpushc;
    VM.operations[opcodes.chPUSHv]         = &VM.chpushv;

    VM.operations[opcodes.chMOVE]          = &VM.ch_move;
    VM.operations[opcodes.iMOVE]           = &VM.imove;

    VM.operations[opcodes.NEWARRAY]        = &VM.new_array;
    VM.operations[opcodes.DELARRAY]        = &VM.delete_array;

    VM.operations[opcodes.chARRINSERT]     = &VM.ch_array_insert;
    VM.operations[opcodes.chARRGET]        = &VM.ch_array_get;
    VM.operations[opcodes.chARRAPPEND]     = &VM.ch_array_append;
    VM.operations[opcodes.chARRDUPLICATE]  = &VM.ch_array_duplicate;

    VM.operations[opcodes.iARRINSERT]      = &VM.iarray_insert;
    VM.operations[opcodes.iARRGET]         = &VM.iarray_get;
    VM.operations[opcodes.iARRAPPEND]      = &VM.iarray_append;
    VM.operations[opcodes.iARRDUPLICATE]   = &VM.iarray_duplicate;

    VM.operations[opcodes.JUMP]            = &VM.jump;
    VM.operations[opcodes.chJUMPNEQ]       = &VM.chjump_if_not_equal;
    VM.operations[opcodes.chJUMPEQ]        = &VM.chjump_if_equal;

    VM.operations[opcodes.iJUMPNEQ]        = &VM.ijump_if_not_equal;
    VM.operations[opcodes.iJUMPEQ]         = &VM.ijump_if_equal;
    VM.operations[opcodes.iJUMPLT]         = &VM.ijump_if_lhs_less_than;
    VM.operations[opcodes.iJUMPGT]         = &VM.ijump_if_lhs_greater_than;

    VM.operations[opcodes.fpJUMPNEQ]        = &VM.fpjump_if_not_equal;
    VM.operations[opcodes.fpJUMPEQ]         = &VM.fpjump_if_equal;
    VM.operations[opcodes.fpJUMPLT]         = &VM.fpjump_if_lhs_less_than;
    VM.operations[opcodes.fpJUMPGT]         = &VM.fpjump_if_lhs_greater_than;

    VM.operations[opcodes.chPUT]           = &VM.chput;
    VM.operations[opcodes.chPUTLN]         = &VM.chputln;
    VM.operations[opcodes.iPUT]            = &VM.iput;
    VM.operations[opcodes.iPUTLN]          = &VM.iputln;
    VM.operations[opcodes.INPUT]           = &VM.input;
    VM.operations[opcodes.HALT]            = &VM.halt;
}

/*
    ---------------- Description ----------------

    This VM is a stack based machine.
    It uses unsigned bytes for operations, and unsigned 64 bit integers for pointers.
    All integers used in any program are 64 bit signed integers.

    All operations are responsible for the correct 
    manipulation of the instruction pointer, if used.

    All operations are responsible for the correct
    manipulation of the stack pointer, if used.

    The SAVEFRAME, and LOADFRAME operations are responsible for the correct
    manipulation of the frame pointer.

    All variables are referenced as an offset from the current location of the frame pointer.

    The frame pointer is set to the first variable on the stack used in
    any given callee function (Which is always the return value).

    This means the relative address from the frame pointer is always positive.

    All function arguments are placed on the stack in the same order
    as seen in nerf source code.

    Local variables are placed on the stack immediately after the argument variables.
    Local variables are always placed as blanks,
    until a move instruction (assignment) places a value into them.

    It is the caller functions job to place the argumentsonto the stack.
    It is the called functions job to place the local variables onto the stack.
    It is also the caller functions job to save the location of the next (local) instruction,
    and the current frame pointer.
    The caller function then JUMP(s) to the location of the callee function (It's first instruction).

    The assembler resolves the relative locations during assembly.
    This allows for correct access to the variables on the stack, and for the correct
    instruction to run when the callee function returns.
    This is despite the fact that the assembled function templates do not include slots for variables.
    Variables are strictly found on the stack, and are placed there when the function is called.

    In other words, until the caller function loads the variables onto the stack, and adjusts
    the frame pointer, variables in the callee function are actually dangling pointers.

    The frame pointer is used for efficiency.
    I decided pushing the function template onto the stack each function call would be too slow.
    I made functions as static operations (see load_bytecode).
    Their state never changes.

    This VM supports calling functions inside of function calls,
    return statements, and assignment statements.
    This VM supports recursion.
    All of these things are laid out (correctly) by the Assembler before hand.
    Function calls are reduced to a handful of stack, and pointer operations.
    
    This VM supports arrays, I did not make a legit heap, so I'm cheating with a struct array.
    I use unique ID numbers to refer to a given array in the "heap" (see lazy_heap).
    Each new array is placed in the first available spot in the "heap".
    Their ID's do not neccesarily line up with their indicies in the "heap".
    These IDs are auto incremented ulong numbers, and are used for one array instance each.
    This is what makes each array uniquely referencable.

    This VM has special operations for array operations.
    Array index errors are not permitted, instead array access uses a modulo operation.
    This would be problematic in the real world, but here it is to avoid adding too many checks
    at the machine level.

    This VM supports floating point numbers.
    Floating point number use a seperate stack, as well as an array that represents all
    floating point constants found in nerf source code.

    Floating point operations also use unsigned integers.
    These unsigned integers are the literal indicies in the array of constants, or they are
    offsets from the floating point frame pointer, in the case of variables.

    This VM does not currently support pointers, but most likely will in the future.
    This will eventually lead to structs, and then classes.
*/