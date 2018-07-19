import os, sys
"""
    System Test
      This script runs source code files (in TestFiles folder) into the compiler.
      Each file has a specific part of the source code that is erronous.
      The compiler should raise an error that is specific to each of these type of errors.
      Only if it does raise the correct type of error does the system test pass.
      There are system tests for each phase of compilation, in order to deal with all types of
      issues that a developer might mistakenly create.

      The system tests also run correct files into the compiler to ensure that correct source
      code successfully compiles.
      These files are have various levels of complexity, to ensure the compiler can handle arbitrary
      nesting of loops, branching logic, large numbers of function calls, large amounts of variables etc.
"""

def run_tests():
    print('running lexing tests...\n')
    test_loop(run_lexing_tests)
    print('lexer tests complete.')
    print('running syntax analysis tests...\n\n\n\n\n')
    test_loop(run_syntax_tests)
    print('syntax tests complete')
    #test_loop(run_semantics_tests)
    print('running compiler on correct source files...\n\n\n\n\n')
    test_loop(happy_path)
    print('final tests on correct files complete')
    print('All tests passed')
    os.system('rm printout.txt')

def test_loop(get_files):
    preamble = 0
    actual = 1
    error = 2
    exe = './nerf '
    for file in get_files():
        print(file[preamble])
        os.system(exe + file[actual] + ' > printout.txt')

        with open('printout.txt', 'r') as err_file:
            error_text = err_file.readline()
        error_text = error_text.rstrip('\n')

        if error_text != file[error]:
            if error_text != '' and error_text != "Compilation Successful":
                print('Error Generated: ' + error_text)
            else:
                print('Did not generate error.')
            print("Test failed.")
            err_file.close()
            os.system('rm printout.txt')
            sys.exit()
        else:
            print("Test passed")
        print('\n')
    err_file.close()


def run_lexing_tests():
    dir_name = 'TestFiles/FileErrors/'
    preamble = 'Testing file '
    fail = ', \nExpecting '

    tests = list()

    err = 'ERROR: file has incorrect file extension.'
    file = 'bad_extension.txt'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: language only supports single files.'
    file = 'empty.nerf doesnt_exist.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: file not found.'
    file = 'doesnt_exist.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: source file is empty.'
    file = 'empty.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    return tests


def run_syntax_tests():
    tests = list()
    tests.extend(fn_declaration_tests())
    #tests.extend(fn_assignments_tests())
    #tests.extend(fn_branching_logic_tests())
    return tests


def fn_declaration_tests():
    dir_name = 'TestFiles/SyntaxErrors/fnDeclarationErrors/'
    preamble = 'Testing file '
    fail = ', \nExpecting '

    tests = list()

    err = 'ERROR: function declaration invalid.'
    file = 'noFnError.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function declaration invalid.'
    file = 'noFnError2functions.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function missing name.'
    file = 'noFnName.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: variable or function name has invalid characters.'
    file = 'nonNumericFuncname.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: variable or function name has invalid characters.'
    file = 'keywordFunctionName.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function missing name.'
    file = 'noFnName2functions.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function missing parentheses for arguments.'
    file = 'noFnArgParen.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function missing parentheses for arguments.'
    file = 'noFnArgParen2.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: missing or invalid return type.'
    file = 'noReturnType.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: missing or invalid return type.'
    file = 'noReturnType2.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function body is missing.'
    file = 'noFnBody.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function body is missing.'
    file = 'noFnBody2.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function body begins with invalid token.'
    file = 'badFnBodyScopeToken.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function body begins with invalid token.'
    file = 'missingFnBodyScopeToken.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))


    return tests

def fn_assignments_tests():
    dir_name = 'TestFiles/SyntaxErrors/AssignmentStatementErrors/'
    preamble = 'Testing file '
    fail = ', \nExpecting '

    tests = list()


    err = 'ERROR: variable not assigned a type.'
    file = 'noTypeOnInstantiation.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: new variables must be instantiated with values.'
    file = 'noValueAssignedOnNew.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: missing assignment operator.'
    file = 'missing_assignment_operator.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: assignment statement missing R value'
    file = 'missing_r_value.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    return tests

def fn_branching_logic_tests():
    dir_name = 'TestFiles/SyntaxErrors/BranchingLogicErrors/'
    preamble = 'Testing file '
    fail = ', \nExpecting '

    tests = list()

    err = 'ERROR: else (if) statement must appear after if statement'
    file = 'orphaned_else_statement.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: malformed branching logic'
    file = 'if_stub.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: malformed branching logic'
    file = 'if_no_paren_w_scope.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: malformed branching logic'
    file = 'if_no_paren_w_scope_no_condition.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: malformed branching logic'
    file = 'if_no_scope_body.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: malformed branching logic'
    file = 'if_no_body.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: malformed branching logic'
    file = 'conditional_no_branching_type.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: malformed branching logic'
    file = 'while_stub.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: malformed branching logic'
    file = 'while_no_paren_w_scope.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: malformed branching logic'
    file = 'while_no_paren_w_scope_no_condition.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: malformed branching logic'
    file = 'while_no_scope_body.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: malformed branching logic'
    file = 'while_no_body.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    return tests

def happy_path():
    dir_name = 'TestFiles/OkFiles/'
    preamble = 'Testing file '
    success = 'Compilation Successful'
    good = ', \nExpecting '

    tests = list()

    file = 'return_nothing.nerf'
    tests.append((preamble + file + good + success, dir_name+file, success,))

    file = 'single_assignment.nerf'
    tests.append((preamble + file + good + success, dir_name+file, success,))

    file = 'assign_with_two_variables.nerf'
    tests.append((preamble + file + good + success, dir_name+file, success,))

    file = 'conditional_re_assignment.nerf'
    tests.append((preamble + file + good + success, dir_name+file, success,))

    return tests



run_tests()