module analyze_semantics;

import structures;
import symbol_table;
import semantic_errors;


void semantic_analysis(Program* program, ref SymbolTable table) {
    int count_main = 0;
    foreach(Function* func; program.functions) {
        if(func.name == "main") {
            count_main++;
        }
        analyze(func, table);
    }
    if(count_main != 1) {
        duplicate_or_missing_main();
    }
}

void analyze(Function* func, ref SymbolTable table) {
    add_func_args_to_local_variable_table(func, table);
    check_for_order_of_statements(func.stmts);

}

void add_func_args_to_local_variable_table(Function* func, ref SymbolTable table) {
    string[] func_args = func.arg_names.dup;
    string[] arg_types = table.get_function_args(func.name);
    if(func_args.length != arg_types.length) {
        throw new Exception("Number of function variables is not the 
                            same as number of types for same function.");
    }
    for(int i = 0; i < func_args.length; i++) {
        table.add_local_variable(func_args[i], arg_types[i]);
    }
}

void check_for_order_of_statements(Statement*[] statements) {
    for(int i = 0; i < statements.length; i++) {
        final switch(statements[i].stmt_type) {
            case StatementTypes.else_statement:
            case StatementTypes.else_if_statement:
                halt_if_orphaned_else(statements, i);
                break;
            case StatementTypes.break_statement:
            case StatementTypes.continue_statement:
                if(i < statements.length-1) {
                    loop_logic_creating_dead_code();
                }
                break;
            case StatementTypes.return_statement:
                check_return_statement(statements, i);
                break;    
        }
    }
}

void halt_if_orphaned_else(Statement*[] statements, int index) {
    if(index == 0) {
        orphaned_else_statement();
    }
    if(statements[index-1].stmt_type == StatementTypes.else_statement) {
        orphaned_else_statement();
    }
}

void check_return_statement(Statement*[] statements, int index) {
    if(index < statements.length-1) {
        return_creating_dead_code();
    } else if(statements[index].stmts.length > 0) {
        check_for_order_of_statements(statements[index].stmts);
    }
}