# movfuscator

Echipă:
- Chivu Răzvan Gabriel - Grupa 152
- Soare Mihai - Grupa 152
- Ungureanu Bogdan - Grupa 152
- Belu Antonie-Gabriel - Grupa 152


Descriere:
Mai jos am detaliat implementarea, dar, pe scurt, movfuscăm fișierul sursă folosind foarte multe macro-uri care sunt la bază aproape doar mov-uri. Sistemul de calcul este pe 8 biți.

Sursă:
Problemele cerute sunt puse în tests/input, iar rezultatele movfuscate sunt puse în tests/output.

Referințe:
* Turing Complete Computerphile, https://www.youtube.com/watch?v=RPQD7-AOjMI
* Christopher Domas, The movfuscator, https://www.youtube.com/watch?v=hsNDLVUzYEs
* Christopher Domas, https://www.youtube.com/watch?v=wiFI5cqE49g
* https://github.com/xoreaxeaxeax/movfuscator


## Usage:
1) Git clone the repository and change directory to movfuscator. 
```bash
git clone https://github.com/chivurazvangabriel/movfuscator.git
cd movfuscator
``` 
2) Run app.py.
3) Drag and drop or use the file dialog to select your Assembly file.
<img width="400" height="350" alt="movfuscator website" src="https://github.com/user-attachments/assets/12770ca9-76ca-4146-807f-bbf309265508" />

4) Hope the returned file is working as intended 🙏🙏.

## Implementation / Details to consider
This implementation of the movfuscator tries to use a different approach compared to the original one. We liked the idea of macros and we took it to another level.
Our movfuscator heavily relies on the idea that there may be a bijection between any two instructions: the classic and movfuscated one. In other words, we believe that any basic instruction can be rewritten using only mov.

This, of course, comes with its own limitations.

## Implemented
* Virtual Registers
* Stack, push, pop and function calling (with arguments and local variables)
* Variables and labels (they replace the in-memory counterparts during coding)
* Arithmetic, logic and boolean calculations
* Conditional and unconditional jumps
* System call for printing strings
* Added many new instructions as macros, with mosft of them following the format "m_{instruction name}"

## Known issues / Not implemented yet
* Arrays (Easily implementable, but we were nearing the deadline and had to cut corners)
* All function calls require a return address to be manually written as a label to come back to (check m_call implementation; this is handled automatically by the parser)
* 'lea' as addresses are also virtualized
* Reading from memory using pointer arithmetic (aside from the stack; NOTE: When addressing relative to %ebp (or mbp in this case), use m_movmbp)
* Some instructions were not movfuscated: int, jmp (for looping main)

### Our goal was to make the movfuscator in our OWN way, rather than translating the already existent movfuscator.
