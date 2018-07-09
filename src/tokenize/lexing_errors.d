import core.sys.posix.stdlib: exit;
import std.stdio: writeln, write;

void bad_file_extension() {
    writeln("ERROR: file has incorrect file extension.");
    exit(-1);
}

void empty_file() {
    writeln("ERROR: source file is empty.");
    exit(-1);
}

void file_not_found() {
    writeln("ERROR: file not found.");
    exit(-1);
}