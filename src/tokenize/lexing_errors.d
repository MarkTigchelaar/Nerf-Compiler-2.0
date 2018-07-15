module lexing_errors;
import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void bad_file_extension() {
    writeln("ERROR: file has incorrect file extension.");
    exit(1);
}

void empty_file() {
    writeln("ERROR: source file is empty.");
    exit(1);
}

void file_not_found() {
    writeln("ERROR: file not found.");
    exit(1);
}

void multiple_files() {
    writeln("ERROR: language only supports single files.");
    exit(1);
}

void mismatched_tokens() {
    writeln("ERROR: parenthesis or curly brackets are not correctly matched");
    exit(-1);
}