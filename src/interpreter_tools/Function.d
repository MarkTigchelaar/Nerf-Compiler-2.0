module functions;

import structures: Variable, Statement, Expression, PrimitiveTypes, FuncRegistry;

class Function {
    private string name;
    private Variable*[] arguments;
    private Variable*[] locals;
    private int return_type;
    private Statement*[] func_statements;
    private FuncRegistry reg;

    this(string name) {
        this.name = name;
        this.return_type = -1;
    }

    public void set_registry(FuncRegistry reg) {
        this.reg = reg;
        foreach(Statement* stmt; this.func_statements) {
            set_reg(stmt);
        }
    }

    private void set_reg(Statement* stmt) {
        if(stmt.syntax_tree !is null) {
            stmt.syntax_tree.set_func_registry(this.reg);
        }
        if(stmt.built_in_args !is null) {
            foreach(Expression exp; stmt.built_in_args) {
                exp.set_func_registry(this.reg);
            }
        }
    }

    public Variable*[] get_arguments() {
        Variable*[] temp;
        foreach(Variable* candidate; arguments) {
            bool duplicate = false;
            foreach(Variable* sendable_arg; temp) {
                if(candidate.name == sendable_arg.name) {
                    duplicate = true;
                    break;
                }
            }
            if(!duplicate) {
                temp ~= candidate;
            }
        }
        return temp;
    }

    public Variable*[] get_local_variables() {
        Variable*[] temp;
        foreach(Variable* candidate; locals) {
            bool duplicate = false;
            foreach(Variable* sendable_arg; temp) {
                if(candidate.name == sendable_arg.name) {
                    duplicate = true;
                    break;
                }
            }
            if(!duplicate) {
                temp ~= candidate;
            }
        }
        return temp;
    }

    public void add_argument(Variable* argument) {
        argument.declaration = true;
        arguments ~= argument;
    }

    public void add_local(Variable* local) {
        locals ~= local;
    }

    public void add_statement(Statement* stmt) {
        func_statements ~= stmt;
    }

    public Statement*[] get_statements() {
        return func_statements;
    }

    public void add_return(int type) {
        return_type = type;
    }

    public int get_return_type() {
        return return_type;
    }

    public int number_of_args() {
        return cast(int) arguments.length;
    }

    public int get_arg_type(int index) {
        if(index > number_of_args() - 1) {
            throw new Exception(
        "INTERNAL ERROR: referencing function arg that is out of range of argument list.");
        }
        return arguments[index].type;
    }

    public string[] get_var_names() {
        string[] names;
        foreach(Variable* arg; arguments) {
            names ~= arg.name;
        }
        foreach(Variable* local; locals) {
            names ~= local.name;
        }
        return names;
    }

    public bool has_duplicate_func_args() {
        for(long i = 0; i < arguments.length; i++) {
            for(long j = i+1; j < arguments.length; j++) {
                if(i == j) {
                   continue;
                }
                if(arguments[i].name == arguments[j].name) {
                   return true;
                }
            } 
        }
        return false;
    }

    public bool is_declared_variable(string identifier) {
        return is_a_local(identifier) || is_a_argument(identifier);
    }

    public bool is_a_local(string identifier) {
        foreach(Variable* local; locals) {
            if(local.name == identifier && local.declaration) {
                return true;
            }
        }
        return false;
    }

    public bool is_a_argument(string identifier) {
        foreach(Variable* arg; arguments) {
            if(arg.name == identifier && arg.declaration == true) {
                return true;
            }
        }
        return false;
    }

    public bool check_for_bad_instantiations() {
        foreach(Variable* arg; arguments) {
            foreach(Variable* local; locals) {
                if(arg.name == local.name) {
                    if(local.declaration) {
                        return true;
                    }
                }
            }
        }
        for(long i = 0; i < locals.length; i++) {
            for(long j = i + 1; j < locals.length; j++) {
                if(locals[i].declaration && locals[j].declaration) {
                    if(locals[i].name != locals[j].name) {
                        continue;
                    }
                    if(check_declarations(locals[i], locals[j])) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    public bool check_for_bad_reassignments() {
        Variable*[] declarations = get_declarations();
        bool found_in_tree = false;
        foreach(Variable* reassignment; get_reassignments()) {
            found_in_tree = false;
            foreach(Variable* declare; declarations) {
                if(check_declarations(declare, reassignment)) {
                    found_in_tree = true;
                    break;
                }
            }
            if(!found_in_tree) {
                return true;
            }
        }
        return false;
    }

    public bool variable_in_expression_out_of_scope(Expression var_in_exp, Statement* statement) {
        Variable*[] declarations = get_declarations();
        Variable* to_find = new Variable();
        to_find.name = var_in_exp.get_var_name();
        to_find.belongs_to = statement;
        foreach(Variable* local; declarations) {
            if(local.name == var_in_exp.get_var_name()) {
                if(check_declarations(local, to_find)) {
                    return false;
                }
            }
        }
        return true;
    }

    private bool check_declarations(Variable* first, Variable* second) {
        Statement*[] candidates = statements_on_level(first);
        if(candidates is null) {
            return false;
        }
        if(second is null) {
        }
        foreach(Statement* stmt; candidates) {
            if(found_in_statement_tree(second, stmt)) {
                return true;
            }
        }
        return false;
    }

    private bool found_in_statement_tree(Variable* second, Statement* stmt) {
        if(second.belongs_to == stmt) {
            return true;
        }
        if(stmt.stmts !is null) {
            foreach(Statement* s; stmt.stmts) {
                if(found_in_statement_tree(second, s)) {
                    return true;
                }
            }
        }
        return false;
    }

    private Statement*[] statements_on_level(Variable* first) {
        if(is_a_argument(first.name)) {
            return func_statements;
        }
        return get_host_statement_location(first.belongs_to, func_statements);
    }

    private Statement*[] get_host_statement_location(Statement* to_find, Statement*[] search_in) {
        if(is_a_argument(to_find.name)) {
            return func_statements;
        }
        foreach(long i, Statement* candidate; search_in) {
            if(candidate == to_find) {
                return search_in[i .. $];
            } else if(candidate.stmts is null) {
                continue;
            } else {
                Statement*[] matches = get_host_statement_location(to_find, candidate.stmts);
                if(matches !is null) {
                    return matches;
                }
            }
        }
        return null;
    }

    private Variable*[] get_declarations() {
        Variable*[] declarations;
        foreach(Variable* candidate; locals) {
            if(candidate.declaration) {
                declarations ~= candidate;
            }
            
        }
        foreach(Variable* arg; arguments) {
            declarations ~= arg;
        }
        return declarations;
    }

    private Variable*[] get_reassignments() {
        Variable*[] reassignments;
        foreach(Variable* candidate; locals) {
            if(!candidate.declaration) {
                reassignments ~= candidate;
            }
        }
        return reassignments; 
    }

    public string get_name() {
        return name;
    }

    public int get_variable_type(string variable) {
        import NewSymbolTable:
          is_variable_integer,
          is_boolean,
          is_variable_char;
        foreach(Variable* var; arguments) {
            if(var.name == variable) {
                return var.type;
            }
        }
        foreach(Variable* var; locals) {
            if(var.name == variable) {
                return var.type;
            }
        }
        if(is_variable_integer(variable)) {
            return PrimitiveTypes.Integer;
        } else if(is_variable_char(variable)) {
            return PrimitiveTypes.Character;
        } else if(is_boolean(variable)) {
            return PrimitiveTypes.Bool;
        }
        return -1;
    }
}