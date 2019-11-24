# Nerf Bytecode Interpreter

## Installation

Python 3 is needed for running build tool, and testing files.


## Overview

This project was about discovering how a compiler works from front to back.

The intention was to create a language that looks like a actual language that is used in production environments.

Although the scope of the language is restricted, it is still open to modification.

## Lessons learned

Being the largest project for me so far, I have learned project organization to a larger degree than I have ever dealt with before.

I also see the importance of encapsulation of state, as I deliberately took a more procedural approach, which led to issues with having to re - aqquire information on the tokens, and abstract syntax tree elements I was working on at each stage.

Had everything been encapsulated, I believe that this project would be hundreds of SLOC shorter in size.

I did make an attempt to refactor, but I chose to instead design a similar language as a project in the future.

## Source code example

```
fn main() int {

    int a := 0;
    while(a < 10) {
        print(a);
        a := a + 1;
    }
    a := second(a);
    return 0;
}

fn second(int a_variable) int {
    if(a_variable == 100) {
        return 2;
    } else if(2 != 2) {
        return 56 * a_variable;
    } else {
        return 5 * a_variable;
    }
}
```

All functions must return a variable, including main.
the int is the only type the front end supports currently.
The bytecode machine does support characters also.
plans for arrays, as well as booleans and floating point numbers have been scrapped for the next language.

The next language will take the virtual machine, and all of the algorithms used.


## Known Bugs

There is a scoping issue where the Symantic Analysis sees a instantiation outside of it's scope, which incorrectly triggers an error.

The expression parser has a bug / defect that causes the expression to evaluate in a different order that a identical expression in Python.
Since python was being used as a reference, this is a issue.

The expression parser also throws a compiler error for certain expression that have several - signs, and ().
It is possible to trick the parser to thinking that the expression is malformed with these tokens.