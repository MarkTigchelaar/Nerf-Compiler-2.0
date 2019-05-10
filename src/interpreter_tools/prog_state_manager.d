module program_state_manager;

import stack: Stack;

class ProgramStateManager {
    private struct func_state {
        string[string] variable_table;
        string[][int] variables_declared_at_scope_level;
        int current_scope_level = 1;
        string[string] current_values;
    }
    private string[string] function_return_types;
    private string[][string] function_fn_arg_types_table;
    private Stack!(func_state*) states;
    private func_state* current_func;

    this() {
        this.current_func = new func_state;
        this.states = new Stack!(func_state*);
    }

    public int current_scope_level() {
        return current_func.current_scope_level;
    }

    public void inc_scope_level() {
        current_func.current_scope_level++;
    }

    public void dec_scope_level() {
        current_func.current_scope_level--;
        if(current_func.current_scope_level < 1) {
            throw new Exception("Scope is less than one.");
        }
        remove_variables_at_deeper_scope_levels();
    }

    private void remove_variables_at_deeper_scope_levels() {
        foreach(int key; current_func.variables_declared_at_scope_level.keys) {
            if(key <= current_func.current_scope_level) {
                continue;
            }
            foreach(string var_key; current_func.variables_declared_at_scope_level[key]) {
                current_func.current_values.remove(var_key);
                current_func.variable_table.remove(var_key);
            }
            current_func.variables_declared_at_scope_level.remove(key);
        }
    }

    public bool is_function_name(string fn_name) {
        if(fn_name in function_fn_arg_types_table) {
            return true;
        }
        return false;
    }

    // arg types in order from left to right (for semantic analysis).
    public void add_fn_args(string fn_name, string[] arg_types) {
        import fn_header_syntax_errors: duplicate_fn_name;
        if(is_function_name(fn_name)) {
            duplicate_fn_name();
        } else {
            function_fn_arg_types_table[fn_name] = arg_types;
        }
    }

    public string[] get_function_args(string func_name) {
        import semantic_errors: invalid_func_call;
        if(is_function_name(func_name)) {
            return function_fn_arg_types_table[func_name];
        } else {
            invalid_func_call();
        }
        return null;
    }

    public void add_fn_return_type(string fn_name, string return_type) {
        import fn_header_syntax_errors: duplicate_fn_name;
        if(fn_name in function_return_types) {
            duplicate_fn_name();
        } else {
            function_return_types[fn_name] = return_type;
        }
    }

    public string get_return_type(string fn_name) {
        return function_return_types[fn_name];
    }

    public void add_local_variable_type(string variable, string type) {
        import fn_header_syntax_errors: duplicate_fn_args;
        if(!is_declared_variable(variable)) {
            current_func.variable_table[variable] = type;
            current_func.
            variables_declared_at_scope_level[
                current_func.current_scope_level
            ] ~= variable;
        } else {
            duplicate_fn_args();
        }
    }

    public string get_local_variable_type(string variable) {
        if(variable !in current_func.variable_table) {
            return null;
        }
        return current_func.variable_table[variable];
    }

    public void clear_local_variables() {
        current_func.variable_table.clear();
        current_func.variables_declared_at_scope_level.clear();
        current_func.variable_table.clear();
    }

    public bool is_declared_variable(string token) {
        if(token in current_func.variable_table) {
            return true;
        }
        return false;
    }

    public void add_variable_for_eval(string key, string value) {
        current_func.variables_declared_at_scope_level[
            current_func.current_scope_level
        ] ~= key;
        current_func.current_values[key] = value;
    }

    public string get_variable_for_eval(string key) {
        return current_func.current_values[key];
    }

    public void save_caller_function_state() {
        states.push(current_func);
        current_func = new func_state;
    }

    public void reinstate_caller_function() {
        current_func = states.pop();
        if(current_func is null) {
            throw new Exception("Func call stack returned null fun state.");
        }
    }
}