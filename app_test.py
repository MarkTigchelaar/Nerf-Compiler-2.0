import os, sys

def run_tests():
    test_loop(run_lexing_tests)
    print('lexer tests complete')
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
        with open('printout.txt', 'r') as err_file:
            error_text = err_file.readline()
        error_text = error_text.rstrip('\n')

        if error_text != file[error]:
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

    err = 'ERROR: function missing parenthesesfor arguments.'
    file = 'noFnArgParen.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function missing return type.'
    file = 'noReturnType.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    err = 'ERROR: function body is missing.'
    file = 'noFnBody.nerf'
    tests.append((preamble + file + fail + err, dir_name+file, err,))

    return tests

run_tests()