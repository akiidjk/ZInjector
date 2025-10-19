#include <stdio.h>
#include <windows.h>

int main() {
  STARTUPINFO si = {sizeof(STARTUPINFO)};
  PROCESS_INFORMATION pi;
  CONTEXT ctx;

  // PUNTO CHIAVE #1: Azzera TUTTA la struttura
  ZeroMemory(&ctx, sizeof(CONTEXT));

  // PUNTO CHIAVE #2: Imposta ContextFlags DOPO aver azzerato
  ctx.ContextFlags = CONTEXT_FULL;

  // Crea processo sospeso
  if (!CreateProcess(L"C:\\Windows\\System32\\calc.exe", NULL, NULL, NULL,
                     FALSE, CREATE_SUSPENDED, NULL, NULL, &si, &pi)) {
    printf("[-] Failed to create process\n");
    return 1;
  }

  printf("[+] Process created in suspended state\n");

  // PUNTO CHIAVE #3: Sospendi il thread (anche se già sospeso)
  SuspendThread(pi.hThread);

  // PUNTO CHIAVE #4: Ottieni il contesto
  if (!GetThreadContext(pi.hThread, &ctx)) {
    DWORD err = GetLastError();
    printf("[-] GetThreadContext Failed With Error: %d\n", err);
    TerminateProcess(pi.hProcess, 1);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 1;
  }

  printf("[+] GetThreadContext SUCCESS!\n");
  printf("[i] RIP: 0x%llX\n", ctx.Rip);
  printf("[i] RSP: 0x%llX\n", ctx.Rsp);

  // Modifica il contesto se necessario
  // ctx.Rip = nuova_address;

  // Setta il nuovo contesto
  // if (!SetThreadContext(pi.hThread, &ctx)) {
  //     printf("[-] SetThreadContext failed\n");
  // }

  // Riprendi il thread
  ResumeThread(pi.hThread);

  // Cleanup
  CloseHandle(pi.hThread);
  CloseHandle(pi.hProcess);

  return 0;
}
