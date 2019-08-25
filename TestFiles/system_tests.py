import json
from sys import exit
import os
import time

def test_system(system_list):
    post_fix = '_params.json'
    for system in system_list:
        filename = system + post_fix
        tests = retrieve(filename)
        run(tests)


def retrieve(filename):
    dir_name = './TestFiles/TestParameterFiles/'
    red_start = '\033[91m'
    red_end = '\033[0m'
    try:
        with open(dir_name + filename, 'r') as f:
            array = json.load(f)
            f.close()
            return array
    except:
        print(red_start + 'TEST SYSTEM ERROR: Cannot find test file, or file failed to load.' + red_end)
        exit(1)


def run(tests):
    directory = tests['dir']
    exe = tests['exe']
    print_header_footer(tests['preamble'])
    time.sleep(0.5)
    for test in tests['tests']:
        run_test_batch(directory, exe, test)
    print_header_footer(tests['postamble'])
    print('\n\n\n')
    


def run_test_batch(directory, exe, test):
        expect = test['expected_output_per_line']
        testfile = directory + test['test_file_name']
        os.system(exe + ' ' + testfile + ' > resultfile.txt')
        test_preamble(test['test_file_name'])

        with open('resultfile.txt', 'r') as result:
                contents = result.readlines()
                result.close()
                if len(contents) != len(expect):
                        show_mismatch(contents, expect)
                elif len(contents) > 0:
                        test_all_outputs(contents, expect)
                else:
                        expect_nothing()

def show_mismatch(contents, expected_output):
        red_start = '\033[91m'
        red_end = '\033[0m'
        print('\n\t' + red_start + 'ERROR: test did not generate the expected number of outputs:' + red_end)
        print('\n\t' + red_start + ' ... Expected:' + red_end)
                
        for item in expected_output:
                print(red_start + item + red_end)
        print('\n\t' + red_start + ' ... Got:' + red_end)
        for item in contents:
                print(red_start + item.replace('\n', '') + red_end)
        exit(1)


def test_all_outputs(contents, expected_output):
        red_start = '\033[91m'
        red_end = '\033[0m'
        green_start = '\033[92m'
        green_end = '\033[0m'

        for index, (content, expected) in enumerate(zip(contents, expected_output)):
                content = content.replace('\n', '')
                if content != expected:
                        print("\n\t" + red_start + " TEST " + str(index + 1) + ". Output: " + content + ' ... expected: ' + red_end, end=' ')
                        print(red_start + expected + ' Failed' + red_end + '\n')
                        exit(1)
                else:
                        print("\n\t" + green_start + " TEST " + str(index + 1) + ". Output: " + content + ' ... expected: ' + green_end, end=' ')
                        print(green_start + expected + ' Success!' + green_end + '\n')


def expect_nothing():
        green_start = '\033[92m'
        green_end = '\033[0m'
        print("\n\t" + green_start + " TEST 1. Empty input for test and empty output expected, Success!" + green_end + "\n")


def test_preamble(preamble):
        blue_start = '\033[34m'
        blue_end = '\033[0m'
        print(blue_start + 'Running test file \"' + preamble + '\" ... result(s):  ' + blue_end, end='')


def print_header_footer(message):
    gold_start = '\033[93m'
    gold_end = '\033[0m'
    print(gold_start + '****************************************' + gold_end)
    print('    ' + gold_start + message + gold_end + '\n\n')
    print(gold_start + '****************************************' + gold_end)