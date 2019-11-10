module tree_linking;

import structures: Variable, Statement, Expression, StatementTypes;
import std.stdio;

/*
    The branching logic needs to know where to jump to under any condition.
    This module is for stringing together the branching logic in the AST.
    This is used by the compiler to convert the tree structure into assembly.
*/
Statement* generate_parent_for_first_level(Statement*[] statements) {
    Statement* _parent = new Statement();
    _parent.stmt_name = "top";
    foreach(Statement* statement; statements) {
        statement.parent = _parent;
    }
    _parent.stmts = statements;
    _parent.alt_branch_name = statements[statements.length - 1].stmt_name;
    _parent.end_branch_name = statements[statements.length - 1].stmt_name;

    return _parent;
}

void link_ast_branches(Statement* parent) {
    if(parent is null) { return; }
    link_statements_on_this_level(parent);
    foreach_reverse(Statement* statement; parent.stmts) {
        link_ast_branches(statement);
    }
}

void link_statements_on_this_level(Statement* parent) {
    if(parent.stmts is null) {
        return;
    }
    Statement* last = parent.stmts[parent.stmts.length - 1];
    last.func_name = parent.func_name;
    link_to_stmt_after_parent(last);
    
    for(long i = parent.stmts.length - 2; i >= 0; i--) {
        Statement* current = parent.stmts[i];
        current.func_name = parent.func_name;
        link_while_statement(current, parent.stmts[i+1]);
        link_else_statement(current, parent.stmts[i+1]);
        link_assign_statement(current, parent.stmts[i+1]);
        link_if_statement(current, parent.stmts[i+1]);
        link_else_if_statement(current, parent.stmts[i+1]);
        link_built_in_statement(current, parent.stmts[i+1]);
        link_return_statement(current);
        link_break_statement(current);
        link_continue_statement(current);
    }
}

void link_to_stmt_after_parent(Statement* current) {
    Statement* original = current;
    Statement* compare = null;
    if(current.parent.stmt_type == StatementTypes.while_statement) {
        current.alt_branch_name = current.parent.stmt_name;
        current.end_branch_name = current.parent.stmt_name;
    } else {
        current.alt_branch_name = current.parent.end_branch_name;
        current.end_branch_name = current.parent.end_branch_name;
    }
}

Statement* get_next_statement(Statement* compare, Statement*[] statements) {
    for(long i = 0; i < statements.length; i++) {
        if(statements[i] == compare) {
            if(i+1 < statements.length) {
                return statements[i+1];
            } else {
                return null;
            }
        }
    }
    assert(0);
}

void link_while_statement(Statement* current, Statement* next) {
    if(current.stmt_type != StatementTypes.while_statement) {
        return;
    }
    current.end_branch_name = next.stmt_name;
    current.alt_branch_name = next.stmt_name;
}

void link_else_statement(Statement* current, Statement* next) {
    if(current.stmt_type != StatementTypes.else_statement) {
        return;
    }
    current.end_branch_name = next.stmt_name;
    current.alt_branch_name = next.stmt_name;
}

void link_assign_statement(Statement* current, Statement* next) {
    if(current.stmt_type != StatementTypes.assign_statement) {
        if(current.stmt_type != StatementTypes.re_assign_statement) {
            return;
        }
    }
    current.end_branch_name = next.stmt_name;
    current.alt_branch_name = next.stmt_name;
}

void link_if_statement(Statement* current, Statement* next) {
    if(current.stmt_type != StatementTypes.if_statement) {
        return;
    }
    if(next.stmt_type == StatementTypes.else_if_statement) {
        current.end_branch_name = next.end_branch_name;
    } else if(next.stmt_type == StatementTypes.else_statement) {
        current.end_branch_name = next.end_branch_name;
    } else {
        current.end_branch_name = next.stmt_name;
    }
    current.alt_branch_name = next.stmt_name;
}

void link_else_if_statement(Statement* current, Statement* next) {
    if(current.stmt_type != StatementTypes.else_if_statement) {
        return;
    }
    if(next.stmt_type == StatementTypes.else_if_statement) {
        current.end_branch_name = next.end_branch_name;
    } else if(next.stmt_type == StatementTypes.else_statement) {
        current.end_branch_name = next.end_branch_name;
    } else {
        current.end_branch_name = next.stmt_name;
    }
    current.alt_branch_name = next.stmt_name;
}

void link_built_in_statement(Statement* current, Statement* next) {
    if(current.stmt_type < 10) {
        return;
    }
    current.end_branch_name = next.stmt_name;
    current.alt_branch_name = next.stmt_name;
}

void link_return_statement(Statement* current) {
    if(current.stmt_type != StatementTypes.return_statement) {
        return;
    }
    current.end_branch_name = "return_" ~ current.func_name;
    current.alt_branch_name = "return_" ~ current.func_name;
}

void link_break_statement(Statement* current) {
    if(current.stmt_type != StatementTypes.break_statement) {
        return;
    }
    Statement* parent = current.parent;
    while(parent.parent !is null) {
        if(parent.stmt_type == StatementTypes.while_statement) {
            current.end_branch_name = parent.end_branch_name;
            current.alt_branch_name = parent.end_branch_name;
            return;
        }
        parent = parent.parent;
    }
    assert(0);
}

void link_continue_statement(Statement* current) {
    if(current.stmt_type != StatementTypes.continue_statement) {
        return;
    }
    Statement* parent = current.parent;
    while(parent.parent !is null) {
        if(parent.stmt_type == StatementTypes.while_statement) {
            current.end_branch_name = parent.stmt_name;
            current.alt_branch_name = parent.stmt_name;
            return;
        }
        parent = parent.parent;
    }
    assert(0);
}