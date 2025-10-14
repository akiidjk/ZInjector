# ZInjector

Simple Process injector for Windows and Linux written in Zig.

## DISCLAIMER

This is my first project in Zig, and the purpose is to learn Zig and process injection.
I don't know yet what to implement, but the first steps are to learn Zig and implement simple DLL injection. Then, I will move on to something similar for Linux, such as LD_PRELOAD hijacking or ptrace-based injection.

## Some cool resource for learning Zig and Process Injection

- [Zig Guide](https://zig.guide/)
- [Zig Standard Library](https://ziglang.org/documentation/master/std/)
- [LearnXInYMinutes](https://learnxinyminutes.com/zig/)
- [Process Injection Techniques](https://www.ired.team/offensive-security/code-injection-process-injection)
- [MITRE](https://attack.mitre.org/techniques/T1055/)
- [DLL Injector C++](https://github.com/leetCipher/Malware.development/tree/main/dll-injector)
- [Cool cheasheet (zig_in_depth)](https://codeberg.org/dude_the_builder/zig_in_depth)
- https://github.com/marlersoft/zigwin32/tree/main
- https://raw.githubusercontent.com/marlersoft/zigwin32/refs/heads/main/win32/everything.zig

For linux on arch install: mingw-w64-headers,mingw-w64-gcc
For work the clangd lsp from zed i am using the compile_flags.txt file

## Todo:

- [x] PoC
- [x] Resolution of relative path to absolute path
- [ ] Search process by name
- [ ] First base with IMGUI
...

## Command:

Compile: `zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSmall --summary all`
Test: `zig build test -Dtarget=x86_64-windows -Doptimize=ReleaseSmall --summary all`
