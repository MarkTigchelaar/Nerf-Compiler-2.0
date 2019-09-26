module tree_linking;

import structures: Variable, Statement, Expression, StatementTypes;
import std.stdio;

void link_ast_branches(Statement*[] statements) {
    if(statements is null) { return; }
    link_statements_on_this_level(statements);
    link_last_sub_statement_for_each_statement(statements);
    //link_loop_shortcuts_to_while_loop(statements);
    foreach(Statement* statement; statements) {
        link_ast_branches(statement.stmts);
    }
}

void link_statements_on_this_level(Statement*[] statements) {
    long last = statements.length - 1;
    if(statements[last].alt_branch_name is null) {
        if(statements[last].end_branch_name is null) {
            statements[last].alt_branch_name = statements[last].stmt_name; // this is causing the issue, next recursive call overwrites end branch
            statements[last].end_branch_name = statements[last].stmt_name;
        }
    } else if(is_assignment(statements[last])) {
        statements[last].alt_branch_name = statements[last].stmt_name;
        statements[last].end_branch_name = statements[last].stmt_name;
    }
    for(long i = 0; i < last; i++) {
        statements[i].alt_branch_name = statements[i + 1].stmt_name;
        if(statements[i].stmt_type == StatementTypes.while_statement) {
            statements[i].end_branch_name = statements[i].stmt_name;
        } else if(statements[i].stmt_type == StatementTypes.else_statement) {
            statements[i].end_branch_name = statements[i + 1].stmt_name;
        } else {
            link_end_of_scope_jump_destination(i, statements);
        }
    }
}

void link_end_of_scope_jump_destination(long index, Statement*[] statements) {
    if(!is_branching_logic(statements[index])
       ) { 
           return; 
    }
    long last = statements.length;
    long current = index;
    index++;
    while(index < last) {
        if(is_alt_branching_logic(statements[index])) {
            index++;
        } else {
            break;
        }
    }
    if(index == last) {
        index = last - 1;
    }
    if(index == last - 1 && index > current + 1) {
        statements[current].end_branch_name = statements[index].end_branch_name;
    } else if(index > current + 1) {
        statements[current].end_branch_name = statements[index].stmt_name;
    } else if(index == current + 1) {
        statements[current].end_branch_name = null;
    }
}

bool is_branching_logic(Statement* statement) {
    int type = statement.stmt_type;
    return (type == StatementTypes.if_statement || type == StatementTypes.else_if_statement);
}

bool is_alt_branching_logic(Statement* statement) {
    int type = statement.stmt_type;
    return (type == StatementTypes.else_statement || type == StatementTypes.else_if_statement);
}

bool should_stop(Statement* statement) {
    bool stop;
    if(is_branching_logic(statement)) {
        stop = false;
    } else if(statement.stmt_type == StatementTypes.else_statement) {
        stop = false;
    } else {
        stop = true;
    }
    return stop;
}

void link_last_sub_statement_for_each_statement(Statement*[] statements) {
    if(statements is null || statements.length < 1) { return; }
    for(long i = 0; i < statements.length; i++) {
        Statement* statement = statements[i];
        if(statement.stmts is null) { continue; }
        Statement* last = statement.stmts[statement.stmts.length - 1];

        if(statement.stmt_type == StatementTypes.while_statement) {
            last.end_branch_name = statement.stmt_name;
            last.alt_branch_name = statement.stmt_name;
        } else if(statement.end_branch_name !is null && statement.end_branch_name != "") {
            last.alt_branch_name = statement.end_branch_name;
            last.end_branch_name = statement.end_branch_name;
        } else {
            Statement* next_stmt = get_parents_next_statement(statement);
           last.alt_branch_name = next_stmt.end_branch_name;
            last.end_branch_name = next_stmt.end_branch_name;
        }
    }
}

Statement* get_parents_next_statement(Statement* statement) {
    if(statement.stmt_name == "top") {
        throw new Exception("INTERNAL ERROR: Hit top statement inside parent retrieval function.");
    }
    while(last_statement_in_scope(statement)) {
        statement = statement.parent;
    }
    return statement;
}

bool last_statement_in_scope(Statement* statement) {
    if(statement.stmt_name == "top") {
        return false;
    }
    Statement* prt = statement.parent;
    if(prt.stmts[prt.stmts.length-1] == statement) {
        return true;
    }
    return false;
}

void generate_parent_for_first_level(Statement*[] statements) {
    Statement* _parent = new Statement();
    _parent.stmt_name = "top";
    foreach(Statement* statement; statements) {
        statement.parent = _parent;
    }
    _parent.stmts = statements;
}

bool is_assignment(Statement* statement) {
    if(statement.stmt_type == StatementTypes.assign_statement) {
        return true;
    }
    if(statement.stmt_type == StatementTypes.re_assign_statement) {
        return true;
    }
    return false;
}