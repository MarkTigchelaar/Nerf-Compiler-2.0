import os

def build():
    tok_path = './src/tokenize/'
    command = 'dmd ./src/nerf.d '
    command += './src/symbol_table.d '
    command += tok_path + 'lexing_tools.d '
    command += tok_path + 'lexing_errors.d '
    
    command += ' -w -m64 -inline'
    os.system(command)










build()