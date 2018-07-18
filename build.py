import os

def build():
    tok_path = './src/tokenize/'
    syntax_path = './src/syntax_analysis/'
    utilities_path = './src/compiler_tools/'

    command = 'dmd ./src/nerf.d '
    command += utilities_path + 'stack.d '
    command += utilities_path + 'symbol_table.d '
    command += utilities_path + 'structures.d '
    command += utilities_path + 'scoped_token_collector.d '
    command += tok_path + 'lexing_tools.d '
    command += tok_path + 'lexing_errors.d '
    command += syntax_path + 'syntax_errors.d '
    command += syntax_path + 'function_parsers.d '
    
    command += ' -w -m64 -inline -unittest'
    os.system(command)

build()