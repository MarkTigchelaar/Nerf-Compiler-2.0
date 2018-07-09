module lexing_tools;

import core.sys.posix.stdlib: exit;
import lexing_errors;
import std.algorithm: endsWith;
import std.stdio: File;
import std.string: chomp;
import symbol_table;

void check_files(string[] arguments) {
    if(arguments.length < 2) {
        exit(-1);
    } else if(arguments.length > 2) {
        multiple_files();
    }
    if(! endsWith(arguments[1], ".nerf")) {
        bad_file_extension();
    }
}

string[] lex(string file_name, SymbolTable table) {
    File file;
    string[] tokens;
    try {
        file  = File(file_name, "r");
    } catch(Exception exc) {
        file_not_found();
    } finally {
        tokens = tokenize_source(file, table);
        file.close();
    }
    return tokens;
}

string[] tokenize_source(File source, SymbolTable table) {
    char[] no_newlines;
    while(!source.eof()) {
        foreach(char ch; chomp(source.readln())) {
            if(ch != '\n' && ch != '\r') {
                no_newlines ~= ch;
            }
        }
    }
    if(no_newlines.length == 0) {
        empty_file();
    }
    return null;
}