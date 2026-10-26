# Third-party material

Source: https://github.com/ionuttbara/windows-defender-remover
Pinned revision: `6126092a5376753153295a20806ebd2f5f3e1c0e`.

The Remove_Defender and Remove_SecurityComp directories are copied from that
revision, with its LICENSE (CC BY-NC 4.0). Attribution: ionuttbara and contributors.
These files retain their separate license; the repository's top-level license
does not replace it. Review the noncommercial condition before redistribution.

PowerRun.exe is the binary distributed in the same upstream revision. It is a
third-party Sordum freeware utility, not authored by this project. Its publisher:
https://www.sordum.org/9416/. It is unsigned. The manifest pins the included bytes;
a matching hash establishes integrity, not safety or publisher authentication.

This project supplies its own experimental orchestration, Appx removal,
file cleanup and verification. It does not execute upstream Script_Run.cmd,
files_removal.bat or Script_Run.ps1. No restart is forced and no verification
scheduled task is installed. Registry changes are the upstream changes, including
security/mitigation settings beyond Defender. UAC is explicitly disabled via
EnableLUA=0 and takes effect after restart.
