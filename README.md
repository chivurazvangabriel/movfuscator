# movfuscator

## Usage:
1) Git clone the repository and change directory to movfuscator. 
```bash
git clone https://github.com/chivurazvangabriel/movfuscator.git
cd movfuscator
``` 
2) Run app.py.
3) Drag and drop your Assembly file.
4) Hope the returned file is working as intended.

## Implementation / Details to consider
This implementation of the movfuscator tries to use a different approach compared to the original one. We liked the idea of macros and we took it to another level.
Our movfuscator heavily relies on the idea that there may be a bijection between any two instructions: classic and the movfuscated one. In other words, we believe that any basic instruction can be rewritten using only mov.

This, of course, comes with its own limitations.

## Implemented
* Virtual Registers
* Stack, push, pop and function calling (with arguments and local variables)
* Variables and labels (they replace the in-memory counterparts during coding)
* Arithmetic, logic and boolean calculations
* System call for printing strings

## Known issues / Not implemented yet
* Arrays (Easily implementable, but we were nearing the deadline and had to cut corners)
* All jumps/function calls require a return address to be manually written as a label to come back to (check m_jmp implementation; this is handled automatically by the parser)
* 'lea' as addresses are also virtualized
* Reading from memory using pointer arithmetic (aside from the stack; NOTE: When addressing relative to %ebp (or mbp in this case), use m_movmbp)
* Some instructions were not movfuscated: int, jmp (for looping main)

Our goal was to make the movfuscator in our OWN way, rather than translating the already existent movfuscator.
