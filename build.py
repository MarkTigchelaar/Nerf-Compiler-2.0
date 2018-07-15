import os

def build():
    tok_path = './src/tokenize/'
    syntax_path = './src/syntax_analysis/'
    command = 'dmd ./src/nerf.d ./src/stack.d '
    command += './src/symbol_table.d '
    command += tok_path + 'lexing_tools.d '
    command += tok_path + 'lexing_errors.d '
    command += syntax_path + 'syntax_errors.d '
    
    command += ' -w -m64 -inline -unittest'
    os.system(command)

build()