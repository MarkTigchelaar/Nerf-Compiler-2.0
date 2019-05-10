import os

def build():
    tok_path = './src/tokenize/'
    syntax_path = './src/syntax_analysis/'
    semantics_path = './src/semantic_analysis/'
    utilities_path = './src/interpreter_tools/'
    gen_path = './src/AssemblyGenerator/'

    command = 'dmd ./src/nerf.d '
    command += tok_path + 'Lexer.d '
    command += tok_path + 'LexingErrors.d '
    command += utilities_path + 'NewSymbolTable.d '
    command += utilities_path + 'stack.d '
    command += utilities_path + 'structures.d '
    command += utilities_path + 'scoped_token_collector.d '
    command += syntax_path + 'fn_header_syntax_errors.d '
    command += syntax_path + 'function_parsers.d '
    command += syntax_path + 'variable_assign_errors.d '
    command += syntax_path + 'statement_parsers.d '
    command += syntax_path + 'general_syntax_errors.d '
    command += syntax_path + 'branching_logic_errors.d '
    command += syntax_path + 'PrattParser.d '
    command += syntax_path + 'expression_errors.d '

    command += semantics_path + 'semantic_errors.d '
    command += semantics_path + 'SemanticAnalyzer.d '
    command += gen_path + 'assembler.d '
    """
    command += gen_path + 'code_generation.d '
    command += gen_path + 'assembler.d '
    command += utilities_path + 'display_ast.d'
    """
    command += ' -w -m64 -inline -unittest'
    os.system(command)

build()
