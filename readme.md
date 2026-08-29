# FF12 Volume Launcher

Launches **Final Fantasy XII: The Zodiac Age** (or any other game with the correct ini values) and automatically sets its volume for you. No more digging into the Windows volume mixer every time you play.

## What it does

1. Starts the game through Steam.
2. Waits for the game to open.
3. Sets the game's volume to whatever you choose (default: 10%).
4. Closes itself. It doesn't run in the background.

## How to use it

1. Download `FF12_Volume.exe` and `FF12_Volume.ini` and put them **in the same folder**, anywhere.
2. (Optional) Open `FF12_Volume.ini` in Notepad to change the volume:
   ```ini
   Volume=10
   ```
   Change `10` to any number from `0` (silent) to `100` (full volume), then save.

   The `.ini` also has `SteamAppID` and `ProcessName` — leave these as-is for FFXII. If you want to use this tool for a *different* Steam game, change `SteamAppID` to that game's Steam app ID, and `ProcessName` to the exact name of its running process (check Task Manager → Details tab while the game is open).
3. Double-click `FF12_Volume.exe` to launch the game. Use this instead of clicking "Play" in Steam.
4. (Optional) Add the exe to Steam as a non-Steam game.

## "Is this safe? Why does Defender/SmartScreen warn me?"

Windows warns about any small app from an unknown developer. It's not a sign of a virus, just that the file isn't "trusted" by Microsoft. Some things that should help you feel confident:

- The `.exe` is just a compiled version of the included `.ps1` file — you can open `FF12_Volume.ps1` in Notepad and read it.
- It only touches the volume of the FFXII game itself. It can't see or change anything else on your PC.
- It doesn't connect to the internet, install anything, or keep running after it sets the volume.

If you'd rather not run the `.exe` at all, you can run the script directly instead:

1. In the folder with the files, click the address bar, type `powershell`, and press Enter (this opens PowerShell already in that folder).
2. Type this and press Enter:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\ff12_volume.ps1
   ```
   (Right-click → "Run with PowerShell" often doesn't work due to Windows' default script restrictions — the command above works around that just for this one run.)


## License

MIT