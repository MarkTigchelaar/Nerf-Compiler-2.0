module get_token;
import general_syntax_errors: invalid_statement;

string get_token(string[] func_body, int* index)  {
    if(*index >= func_body.length) {
        invalid_statement();
    }
    string token = func_body[*index];
    (*index)++;
    return token;
}