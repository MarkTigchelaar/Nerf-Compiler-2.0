module get_token;
import general_syntax_errors: invalid_statement;
import scoped_token_collector;
import symbol_table;

string get_token(string[] func_body, int* index)  {
    string token = current_token(func_body, index);
    (*index)++;
    return token;
}

string current_token(string[] func_body, int* index)  {
    if(*index >= func_body.length) {
        invalid_statement();
    }
    string token = func_body[*index];
    return token;
}

string[] collect_scoped_tokens(ref SymbolTable table, string[] func_body, int* index) {
    ScopedTokenCollector collector = new ScopedTokenCollector(table);
    collector.add_token(get_token(func_body, index));
    do {
        collector.add_token(get_token(func_body, index));
    } while(collector.not_done_collecting());
    return collector.get_scoped_tokens();
}