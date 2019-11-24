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

