import os, sys

def run_tests():
    print('running lexing tests...\n')
    test_loop(run_lexing_tests)
    print('lexer tests complete.')
    print('running syntax analysis tests...\n')
    test_loop(run_syntax_tests)
    print('All Syntax tests complete')
    #test_loop(run_semantics_tests)
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
        os.system(exe + file[actual])
        with open('printout.txt', 'r') as err_file:
            error_text = err_file.readline()
        error_text = error_text.rstrip('\n')

        if error_text != file[error]:
            if error_text == '':
                #print('Error Generated: ' + error_text)
            #else:
                print('Did not generate error.')
            print("Test failed.")
            os.system('rm printout.txt')
            sys.exit()
        else:
            print("Test passed")
        print('\n')


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

    err = 'ERROR: function missing name.'
    file = 'noFnName.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function missing parentheses for arguments.'
    file = 'noFnArgParen.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: missing or invalid return type.'
    file = 'noReturnType.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function body is missing.'
    file = 'noFnBody.nerf'
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

run_tests()