/* C file for test the dll */
#include <stdio.h>
#include <windows.h>

DWORD WINAPI threadFunction(LPVOID lpParam) {
  printf("Hello from the injected DLL!\n");
  return 0;
}

int main(int argc, char **argv) {
  // Load and check DLL
  PCSTR path_dll = argv[1];
  HINSTANCE hDll = LoadLibrary(argv[1]);
  if (hDll == NULL) {
    printf("Failed to load the DLL.");
    return 1;
  }

  // Create the thread
  HANDLE hthread = CreateThread(NULL, 0, threadFunction, NULL, 0, NULL);
  if (hthread == NULL) {
    printf("Failed to create thread.");
    return 1;
  }

  WaitForSingleObject(hthread, INFINITE);
  CloseHandle(hthread);
  FreeLibrary(hDll);

  return 0;
}
