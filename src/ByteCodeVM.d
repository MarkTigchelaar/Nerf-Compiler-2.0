module ByteCodeVM;

import structures: opcodes;

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
    }

    private ubyte[] memory;

    private ulong inst_ptr;
    private ulong stk_ptr;
    private ulong frame_ptr;

    private heap_node*[] lazy_heap;
    private ulong unique_heapitem_id;

    private void delegate()[] instructions;

    this() {
        memory       = new ubyte[fiftyk];
        instructions = new void delegate()[inst_count];
        unique_heapitem_id = 0;
        lazy_heap    = new heap_node*[1];
        lazy_heap[0] = new heap_node(-1, null, null);
        set_instructions(this);
        set_pointers();
    }

    // Expensive, and optional.
    public void reset_memory() {
        for(ulong i = 0; i < memory.length; i++) {
            memory[i] = 0;
        }
        set_pointers();
    }

    public void load_bytecode(ubyte[] assembled_program) {
        set_pointers();
        foreach(ubyte bytecode; assembled_program) {
            push(bytecode);
        }
    }

    public void run() {
        while(is_running()) {
            execute_instructions();
        }
    }

    private bool is_running() {
        return (inst_ptr < memory.length);
    }

    private void execute_instructions() {
        instructions[cast(long) fetch_opcode()]();
    }

    private ubyte fetch_opcode() {
        return memory[inst_ptr];
    }

    private void set_pointers() {
        stk_ptr = ulong.max;
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
        if(stk_ptr >= memory.length - 1) {
            ubyte[] upgrade_memory = new ubyte[memory.length + fiftyk];
            foreach(int i, ubyte bt; memory) {
                upgrade_memory[i] = bt;
            }
            memory = upgrade_memory;
        }
    }

    // avoids convoluted use of ipush and ipop;
    private ulong collect_int_at(ulong start_idx) {
        ulong temp = 0;
        ulong worker;
        ulong shift_amount = 56;
        for(ulong i = start_idx; i < start_idx + 8; i++) {
            worker = cast(ulong) memory[i];
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

    private void error_msg(string message) {
        import core.sys.posix.stdlib: exit;
        import std.stdio: writeln;
        writeln(message);
        exit(1);
    }

    private void push(ubyte value) {
        if(stk_ptr == ulong.max) {
            stk_ptr = 0;
            memory[stk_ptr] = value;
        } else {
            inc_stk_ptr();
            memory[stk_ptr] = value;
        }
    }

    private ubyte pop() {
        ubyte value = memory[stk_ptr];
        stk_ptr--;
        return value;
    }

    private void chpushc() {
        inst_ptr++;
        push(memory[inst_ptr]);
        inst_ptr++;
    }

    private void chpushv() {
        ipushc();
        ulong temp_inst_ptr = inst_ptr;
        inst_ptr = frame_ptr + ((cast(ulong) ipop()) - 1);
        chpushc();
        inst_ptr = temp_inst_ptr;
    }

    private void ipushc() {
        inst_ptr++;
        for(long i = 0; i < 8; i++) {
            push(memory[inst_ptr]);
            inst_ptr++;
        }
    }

    private void ipushv() {
        ipushc();
        ulong temp_inst_ptr = inst_ptr;
        inst_ptr = frame_ptr + ((cast(ulong) ipop()) - 1);
        ipushc();
        inst_ptr = temp_inst_ptr;
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

    private void save_frame_ptr() {
        ipush(frame_ptr);
    }

    private void restore_frame_ptr() {
        frame_ptr = cast(ulong) ipop();
    }

    private void save_instr_ptr() {
        ipush(inst_ptr);
    }

    private void restore_instr_ptr() {
        inst_ptr = cast(ulong) ipop();
    }

    private void ch_move() {
        ubyte value = pop();
        ulong temp = stk_ptr;
        stk_ptr = inst_ptr + 9;
        ulong var_index = frame_ptr + cast(ulong) ipop();
        memory[var_index] = value;
        inst_ptr += 9;
        stk_ptr = temp;
    }

    private void imove() {
        long value = ipop();
        inst_ptr++;
        ulong index = collect_int_at(inst_ptr);
        inst_ptr += 8;
        ulong temp = stk_ptr;
        stk_ptr = index - 1;
        ipush(value);
        stk_ptr = temp;
    }

    private void rollback() {
        inst_ptr++;
        stk_ptr = collect_int_at(inst_ptr);
        inst_ptr += 8; 
    }

    private void iadd() {
        ipush(ipop() + ipop());
    }

    private void isub() {
        long subtrahend = ipop();
        long minuend = ipop();
        ipush(minuend - subtrahend);
    }

    private void imult() {
        ipush(ipop() * ipop());
    }

    private void idiv() {
        long divisor = ipop();
        if(divisor == 0) {
            division_by_zero();
        }
        ipush(ipop() / divisor);
    }

    private void iexp() {
        long exponent = ipop();
        ipush(ipop() ^ exponent);
    }

    private void imod() {
        long modulo = ipop();
        ipush(ipop() % modulo);
    }

    private void and() {
        ubyte rhs = pop();
        ubyte lhs = pop();
        ubyte eq = cast(ubyte) lhs == rhs;
        push(cast(ubyte) eq > 0);
    }

    private void or() {
        ubyte rhs = pop();
        ubyte lhs = pop();
        push(cast(ubyte) (rhs > 0) || (lhs > 0));
    }

    private void not() {
        push(pop() == cast(ubyte) 0);
    }

    private void iequal() {
        push(cast(ubyte) ipop() == ipop());
    }

    private void inot_equal() {
        push(cast(ubyte) ipop() != ipop());
    }

    private void iless_than() {
        long rhs = ipop();
        push(cast(ubyte) ipop() < rhs);
    }

    private void igreater_than() {
        long rhs = ipop();
        push(cast(ubyte) ipop() > rhs);
    }

    private void iless_than_or_equal() {
        long rhs = ipop();
        push(cast(ubyte) ipop() <= rhs);
    }

    private void igreater_than_or_equal() {
        long rhs = ipop();
        push(cast(ubyte) ipop() >= rhs);
    }

    private void ch_equal() {
        push(cast(ubyte) pop() == pop());
    }

    private void ch_not_equal() {
        push(cast(ubyte) pop() != pop());
    }

    private void ch_less_than() {
        ubyte rhs = pop();
        push(cast(ubyte) pop() < rhs);
    }

    private void ch_greater_than() {
        ubyte rhs = pop();
        push(cast(ubyte) pop() > rhs);
    }

    private void ch_less_than_or_equal() {
        ubyte rhs = pop();
        push(cast(ubyte) pop() <= rhs);
    }

    private void ch_greater_than_or_equal() {
        ubyte rhs = pop();
        push(cast(ubyte) ipop() >= rhs);
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
        long index = ipop();
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
        inst_ptr = collect_int_at(++inst_ptr);
    }

    private void chjump_if_equal() {
        ubyte rhs = pop();
        ubyte lhs = pop();
        if(lhs == rhs) {
            jump();
        } else {
            inst_ptr+=9;
        }
    }

    private void chjump_if_not_equal() {
        ubyte rhs = pop();
        ubyte lhs = pop();
        if(lhs != rhs) {
            jump();
        } else {
            inst_ptr+=9;
        }
    }

    private void ijump_if_equal() {
        long rhs = ipop();
        long lhs = ipop();
        if(lhs == rhs) {
            jump();
        } else {
            inst_ptr +=9;
        }
    }

    private void ijump_if_not_equal() {
        long rhs = ipop();
        long lhs = ipop();
        if(lhs != rhs) {
            jump();
        } else {
            inst_ptr +=9;
        }
    }

    private void chput() {
        import std.stdio: write;
        write(pop());
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

    private void halt() {
        inst_ptr = memory.length + 1;
    }
}

private:

immutable long fiftyk = 50000;
immutable long inst_count = 53;

private:

void set_instructions(ByteCodeVM VM) {
    VM.instructions[opcodes.SAVEFRAME]       = &VM.save_frame_ptr;
    VM.instructions[opcodes.LOADFRAME]       = &VM.restore_frame_ptr;

    VM.instructions[opcodes.SAVEINSTRUCTION] = &VM.save_instr_ptr;
    VM.instructions[opcodes.LOADINSTRUCTION] = &VM.restore_instr_ptr;
    VM.instructions[opcodes.ROLLBACK]        = &VM.rollback;
    
    VM.instructions[opcodes.iADD]            = &VM.iadd;
    VM.instructions[opcodes.iSUB]            = &VM.isub;
    VM.instructions[opcodes.iMULT]           = &VM.imult;
    VM.instructions[opcodes.iDIV]            = &VM.idiv;
    VM.instructions[opcodes.iEXP]            = &VM.iexp;
    VM.instructions[opcodes.iMOD]            = &VM.imod;

    VM.instructions[opcodes.AND]             = &VM.and;
    VM.instructions[opcodes.OR]              = &VM.or;
    VM.instructions[opcodes.NOT]             = &VM.not;

    VM.instructions[opcodes.iEQ]             = &VM.iequal;
    VM.instructions[opcodes.iNEQ]            = &VM.inot_equal;
    VM.instructions[opcodes.iLT]             = &VM.iless_than;
    VM.instructions[opcodes.iGT]             = &VM.igreater_than;
    VM.instructions[opcodes.iLTEQ]           = &VM.iless_than_or_equal;
    VM.instructions[opcodes.iGTEQ]           = &VM.igreater_than_or_equal;

    VM.instructions[opcodes.chEQ]            = &VM.ch_equal;
    VM.instructions[opcodes.chNEQ]           = &VM.ch_not_equal;
    VM.instructions[opcodes.chLT]            = &VM.ch_less_than;
    VM.instructions[opcodes.chGT]            = &VM.ch_greater_than;
    VM.instructions[opcodes.chLTEQ]          = &VM.ch_less_than_or_equal;
    VM.instructions[opcodes.chGTEQ]          = &VM.ch_greater_than_or_equal;

    VM.instructions[opcodes.iPUSHc]          = &VM.ipushc;
    VM.instructions[opcodes.iPUSHv]          = &VM.ipushv;

    VM.instructions[opcodes.chPUSHc]         = &VM.chpushc;
    VM.instructions[opcodes.chPUSHv]         = &VM.chpushv;

    VM.instructions[opcodes.chMOVE]          = &VM.imove;
    VM.instructions[opcodes.iMOVE]           = &VM.ch_move;

    VM.instructions[opcodes.NEWARRAY]        = &VM.new_array;
    VM.instructions[opcodes.DELARRAY]        = &VM.delete_array;

    VM.instructions[opcodes.chARRINSERT]     = &VM.ch_array_insert;
    VM.instructions[opcodes.chARRGET]        = &VM.ch_array_get;
    VM.instructions[opcodes.chARRAPPEND]     = &VM.ch_array_append;
    VM.instructions[opcodes.chARRDUPLICATE]  = &VM.ch_array_duplicate;

    VM.instructions[opcodes.iARRINSERT]      = &VM.iarray_insert;
    VM.instructions[opcodes.iARRGET]         = &VM.iarray_get;
    VM.instructions[opcodes.iARRAPPEND]      = &VM.iarray_append;
    VM.instructions[opcodes.iARRDUPLICATE]   = &VM.iarray_duplicate;

    VM.instructions[opcodes.JUMP]            = &VM.jump;
    VM.instructions[opcodes.chJUMPNEQ]       = &VM.chjump_if_not_equal;
    VM.instructions[opcodes.chJUMPEQ]        = &VM.chjump_if_equal;
    VM.instructions[opcodes.iJUMPNEQ]        = &VM.ijump_if_not_equal;
    VM.instructions[opcodes.iJUMPEQ]         = &VM.ijump_if_equal;

    VM.instructions[opcodes.chPUT]           = &VM.chput;
    VM.instructions[opcodes.chPUTLN]         = &VM.chputln;
    VM.instructions[opcodes.iPUT]            = &VM.iput;
    VM.instructions[opcodes.iPUTLN]          = &VM.iputln;
    VM.instructions[opcodes.INPUT]           = &VM.input;
    VM.instructions[opcodes.HALT]            = &VM.halt;
}

public:

void main() {
    ByteCodeVM vm = new ByteCodeVM();
    //vm.load_bytecode(get_bytes(vm));
}

unittest {
    ByteCodeVM vm = new ByteCodeVM();
    vm.ipush(long.max);
    assert(vm.stk_ptr == 7);
}

// ipushc places correct # bytes on stack,
// instruction pointer at next byte after number.
unittest {
    ByteCodeVM vm = new ByteCodeVM();
    vm.ipush(3);
    vm.ipushc();
    // int offset, plus next instruction.
    assert(vm.inst_ptr == 9);
    // pushed two ints, 16 bytes in.
    assert(vm.stk_ptr == 15);
}

// pushing and popping integers gives correct values.
unittest {
    ByteCodeVM vm = new ByteCodeVM();
    for(long i = -100; i <= 100; i++) {
        vm.ipush(i);
        long j = vm.ipop();
        assert(i == j);
    }
}

// pushing integers based off of variable reference.
unittest {
    ByteCodeVM vm = new ByteCodeVM();
    // actual variable to be pushed.
    vm.ipush(3);
    // set ptr to where var reference is (begins).
    vm.inst_ptr = 8;
    // index of variable to be pushed.
    // relative to frame pointer.
    vm.ipush(0);
    // push from variable location
    vm.ipushv();
    assert(vm.ipop() == 3);
}

// chpushc works correctly.
unittest {
    ByteCodeVM vm = new ByteCodeVM();
    // throw away, representing the actual cpushc opcode in memory.
    // this is needed bc the instruction pointer is incremented to
    // the next index representing the value to be pushed.
    vm.push(0);
    // the const value to push on the stack.
    vm.push(10);
    vm.chpushc();
    assert(vm.inst_ptr == 2);
    assert(vm.memory[1] == vm.memory[2]);
}

// cpushv works correctly
unittest {
    ByteCodeVM vm = new ByteCodeVM();
    // throw away, representing the actual cpushv opcode in memory.
    // this is needed bc the instruction pointer is incremented to
    // the next index representing the value to be pushed.
    vm.push(0);
    // the address of the variable, offset by the frame pointer (0 in this case)
    vm.ipush(20);
    vm.memory[20] = cast(ubyte) 13;
    vm.chpushv();
    // chpushv manipulates, and restores instruction pointer correctly.
    // The instruction pointer moves further than a char operation, as it needs
    // a address which is always a 64 bit int (8 bytes).
    assert(vm.inst_ptr == 9);
    // item at location is correct
    assert(vm.memory[vm.stk_ptr] == cast(ubyte) 13);
}

// ch_move works correctly
unittest {
    ByteCodeVM vm = new ByteCodeVM();
    // throw away, representing the actual chmove opcode in memory.
    vm.push(0);

    for(ulong i = 9; i < 100; i++) {
        // The value to place into the "variable"
        vm.push(3);
        ulong temp = vm.stk_ptr;
        // The variable location
        vm.ipush(i);
        // in reality, this mem address would be coded in by the assembler.
        // it wouldn't be actually pushing the address on the stack.
        // so reset the stack pointer.
        vm.stk_ptr = temp;
        temp = vm.inst_ptr;
        vm.ch_move();
        // artificially running same command repeatedly,
        // instruction pointer must be reset.
        vm.inst_ptr = temp;
        assert(vm.memory[i] == cast(ubyte) 3);
    }
}

// imove works correctly
unittest {
    ByteCodeVM vm = new ByteCodeVM();
    // throw away, representing the actual imove opcode in memory.
    // this is needed bc the instruction pointer is incremented to
    // the next index representing the value to be pushed in the actual operation.
    vm.push(0);
    // push location
    vm.ipush(16);
    // The value to place into the "variable"
    vm.ipush(30);
    // move 30 into variable location
    vm.imove();
    assert(vm.stk_ptr == 8);
    assert(vm.inst_ptr == 9);
    assert(vm.collect_int_at(16) == 30);
 
}

// rollback works correctly
unittest {
    ByteCodeVM vm = new ByteCodeVM();
    // simulate being at end of function.
    vm.ipush(0);
    vm.ipush(0);
    vm.ipush(0);
    // throw away, representing the actual rollback opcode in memory.
    // this is needed bc the instruction pointer is incremented to
    // the next index representing the value to be pushed in the actual operation.
    vm.push(0);
    vm.inst_ptr = 24;
    vm.ipush(0);
    vm.rollback();
    assert(vm.inst_ptr == 33);
    assert(vm.stk_ptr == 0);
}

// new_array works correctly
unittest {
    ByteCodeVM vm = new ByteCodeVM();
    // throw away, representing the actual imove opcode in memory.
    // this is needed bc the instruction pointer is incremented to
    // the next index representing the value to be pushed in the actual operation.
    vm.push(0);
    vm.new_array();
    assert(vm.ipop() == 0);
}

/*
    ---------------- Description ----------------

    This VM is a stack based machine.
    It uses unsigned bytes for instructions, and unsigned 64 bit integers for pointers.
    All integers used in any program are 64 bit signed integers.

    All instructions are responsible for the correct 
    manipulation of the instruction pointer, if used.

    All instructions are responsible for the correct
    manipulation of the stack pointer, if used.

    The SAVEFRAME, and LOADFRAME instructions are responsible for the correct
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

    It is the caller functions job to place the arguments
    and local variables onto the stack.
    It is also the caller functions job to save the location of the next (local) instruction,
    and the current frame pointer.
    The caller function then JUMP(s) to the location of the callee function (It's first instruction).

    The assembler resolves the relative locations during assembly.
    This allows for correct access to the variables on the stack, and for the correct
    instruction to run when the callee function returns.
    This is despite the fact that the assembled function templates do not include slots for variables.

    In other words, until the caller function loads the variables onto the stack, and adjusts
    the frame pointer, variables in the callee function are actually dangling pointers.

    The frame pointer is used for efficiency.
    I decided pushing the function template onto the stack each function call would be too slow.
    I made functions as static instructions (see load_bytecode).
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

    This VM has special instructions for array operations.
    Array index errors are not permitted, instead array access uses a modulo operation.
    This would be problematic in the real world, but here it is to avoid adding too many checks
    at the machine level.

    This VM currently does not support floating point numbers.
*/