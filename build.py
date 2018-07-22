import os

def build():
    tok_path = './src/tokenize/'
    syntax_path = './src/syntax_analysis/'
    semantics_path = './src/semantic_analysis/'
    utilities_path = './src/compiler_tools/'

    command = 'dmd ./src/nerf.d '
    command += utilities_path + 'stack.d '
    command += utilities_path + 'symbol_table.d '
    command += utilities_path + 'structures.d '
    command += utilities_path + 'scoped_token_collector.d '
    command += tok_path + 'lexing_tools.d '
    command += tok_path + 'lexing_errors.d '
    command += syntax_path + 'fn_header_syntax_errors.d '
    command += syntax_path + 'function_parsers.d '
    command += syntax_path + 'variable_assign_errors.d '
    command += syntax_path + 'statement_parsers.d '
    command += syntax_path + 'expression_parsers.d '
    command += syntax_path + 'general_syntax_errors.d '
    command += semantics_path + 'semantic_errors.d'
    command += ' -w -m64 -inline -unittest'
    os.system(command)

build()