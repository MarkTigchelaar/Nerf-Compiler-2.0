import os
import sys
import time
from TestFiles.system_tests import *

useage = """
Useage:
    -all : 
        Builds each component from assembler, to full interpreter, 
        with full testing at each step.
        Then builds optimized interpreter.

    -asm :
        Builds the assembler.

    -test :
        Extra option, runs unit tests, and system tests.

    -useage :
        Displays this useage message.

    default :
        builds optimized interpreter.
"""

def build():
    test = ''

    if len(sys.argv) == 1:
        arg = None
    elif '-useage' in sys.argv:
        print(useage)
        return
    elif len(sys.argv) == 2:
        arg = sys.argv[1]
    elif len(sys.argv) == 3:
        if '-test' not in sys.argv:
            print('BUILD ERROR: unknown option(s).')
            return
        else:
            args = sys.argv[1:]
            test = '-unittest'
            args.remove('-test')
            arg = args[0]
    else:
        print('BUILD ERROR: unknown option(s).')
        return
        

    if arg == '-useage':
        print(useage)
        return
    elif arg == '-all':
        build_all_steps(test)
    elif arg == '-asm':
        build_assembler(test)
    else:
        build_release()
    
    if test != '':
        os.system('rm resultfile.txt')



def build_release():
    command = general_build()
    #command += ' -O -m64 -inline'
    os.system(command)

def build_unittest():
    command = general_build()
    command += ' -w -m64 -inline -unittest'
    os.system(command)


def general_build():
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
    command += utilities_path + 'opcodes.d '
    command += utilities_path + 'scoped_token_collector.d '
    command += utilities_path + 'Function.d '
    command += utilities_path + 'useage.d '
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
    command += gen_path + 'compile.d '
    command += gen_path + 'assembler.d '
    command += './src/ByteCodeVM.d '

    return command


def build_all_steps(test):
    build_assembler(test)
    build_unittest()
    if test != '':
        test_system([
            'lexer',
            'parser_fn_declare', 
            'parser_expression_errors',
            'parser_assignment_errors',
            'semantic_analyzer_errors',
            'assembly_output'
            ])
        os.system('rm nerf nerf.o')

def build_assembler(test):
    command = 'dmd ' 
    command += './src/ClunkASM.d '
    command += './src/AssemblyGenerator/assembler.d '
    command += './src/interpreter_tools/opcodes.d '
    command += './src/ByteCodeVM.d -O -m64 ' + test
    os.system(command)
    if test != '':
        test_system(['asm'])
        os.system('rm ClunkASM ClunkASM.o')


if __name__ == '__main__':
    build()