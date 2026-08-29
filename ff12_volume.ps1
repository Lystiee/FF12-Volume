# ============================================================
# FF12 Volume Launcher
# ============================================================

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

# Get the folder of the script
$ScriptDirectory = $PSScriptRoot

$ConfigFile = [System.IO.Path]::Combine(
    $ScriptDirectory,
    "FF12_Volume.ini"
)

# Make sure INI exists
if (-not [System.IO.File]::Exists($ConfigFile))
{
    exit 1
}

# Non-hardcoded defaults
$SteamAppID = $null
$ProcessName = $null
$Volume = $null

# Read INI
foreach ($line in [System.IO.File]::ReadAllLines($ConfigFile))
{
    $line = $line.Trim()

    # Ignore empty lines and comments
    if ([string]::IsNullOrWhiteSpace($line))
    {
        continue
    }

    if ($line.StartsWith(";") -or $line.StartsWith("#"))
    {
        continue
    }

    # Ignore section names such as [Settings]
    if ($line.StartsWith("["))
    {
        continue
    }

    # Split key=value
    $parts = $line.Split("=", 2)

    if ($parts.Count -ne 2)
    {
        continue
    }

    $key = $parts[0].Trim()
    $value = $parts[1].Trim()

    switch ($key)
    {
        "SteamAppID"
        {
            $SteamAppID = $value
        }

        "ProcessName"
        {
            $ProcessName = $value
        }

        "Volume"
        {
            $Volume = $value
        }
    }
}

# Check that all required settings were found
if ([string]::IsNullOrWhiteSpace($SteamAppID))
{
    exit 1
}

if ([string]::IsNullOrWhiteSpace($ProcessName))
{
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Volume))
{
    exit 1
}

# Convert percentage to 0.0 - 1.0
try
{
    $Volume = [double]::Parse(
        $Volume,
        [System.Globalization.CultureInfo]::InvariantCulture
    ) / 100
}
catch
{
    exit 1
}

# Clamp volume
if ($Volume -lt 0)
{
    $Volume = 0
}

if ($Volume -gt 1)
{
    $Volume = 1
}


# ------------------------------------------------------------
# Launch Game
# ------------------------------------------------------------

Start-Process "steam://rungameid/$SteamAppID"


# ------------------------------------------------------------
# Windows Audio API
# ------------------------------------------------------------

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class AppVolume
{
    private const int CLSCTX_ALL = 23;
    private const int eRender = 0;
    private const int eMultimedia = 1;

    [ComImport]
    [Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
    private class MMDeviceEnumerator
    {
    }

    [ComImport]
    [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IMMDeviceEnumerator
    {
        int EnumAudioEndpoints(
            int dataFlow,
            int stateMask,
            out IntPtr devices);

        int GetDefaultAudioEndpoint(
            int dataFlow,
            int role,
            out IMMDevice endpoint);
    }

    [ComImport]
    [Guid("D666063F-1587-4E43-81F1-B948E807363F")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IMMDevice
    {
        int Activate(
            ref Guid iid,
            int clsCtx,
            IntPtr activationParams,
            [MarshalAs(UnmanagedType.IUnknown)]
            out object interfacePointer);
    }

    [ComImport]
    [Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IAudioSessionManager2
    {
        int NotImpl1();
        int NotImpl2();

        int GetSessionEnumerator(
            out IAudioSessionEnumerator sessionEnumerator);
    }

    [ComImport]
    [Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IAudioSessionEnumerator
    {
        int GetCount(out int count);

        int GetSession(
            int index,
            out IAudioSessionControl session);
    }

    [ComImport]
    [Guid("F4B1A599-7266-4319-A8CA-E70ACB11E8CD")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IAudioSessionControl
    {
        int GetState(out int state);

        int GetDisplayName(
            [MarshalAs(UnmanagedType.LPWStr)]
            out string name);

        int SetDisplayName(
            [MarshalAs(UnmanagedType.LPWStr)]
            string name,
            ref Guid eventContext);

        int GetIconPath(
            [MarshalAs(UnmanagedType.LPWStr)]
            out string path);

        int SetIconPath(
            [MarshalAs(UnmanagedType.LPWStr)]
            string path,
            ref Guid eventContext);

        int GetGroupingParam(out Guid groupingParam);

        int SetGroupingParam(
            ref Guid groupingParam,
            ref Guid eventContext);

        int RegisterAudioSessionNotification(
            IntPtr client);

        int UnregisterAudioSessionNotification(
            IntPtr client);
    }

    [ComImport]
    [Guid("BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IAudioSessionControl2
    {
        int GetState(out int state);

        int GetDisplayName(
            [MarshalAs(UnmanagedType.LPWStr)]
            out string name);

        int SetDisplayName(
            [MarshalAs(UnmanagedType.LPWStr)]
            string name,
            ref Guid eventContext);

        int GetIconPath(
            [MarshalAs(UnmanagedType.LPWStr)]
            out string path);

        int SetIconPath(
            [MarshalAs(UnmanagedType.LPWStr)]
            string path,
            ref Guid eventContext);

        int GetGroupingParam(out Guid groupingParam);

        int SetGroupingParam(
            ref Guid groupingParam,
            ref Guid eventContext);

        int RegisterAudioSessionNotification(
            IntPtr client);

        int UnregisterAudioSessionNotification(
            IntPtr client);

        int GetSessionIdentifier(
            [MarshalAs(UnmanagedType.LPWStr)]
            out string id);

        int GetSessionInstanceIdentifier(
            [MarshalAs(UnmanagedType.LPWStr)]
            out string id);

        int GetProcessId(out uint processId);

        int IsSystemSoundsSession();

        int SetDuckingPreference(bool optOut);
    }

    [ComImport]
    [Guid("87CE5498-68D6-44E5-9215-6DA47EF883D8")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface ISimpleAudioVolume
    {
        int SetMasterVolume(
            float level,
            ref Guid eventContext);

        int GetMasterVolume(
            out float level);

        int SetMute(
            bool mute,
            ref Guid eventContext);

        int GetMute(
            out bool mute);
    }

    public static bool SetVolume(uint processId, float level)
    {
        IMMDeviceEnumerator enumerator =
            (IMMDeviceEnumerator)new MMDeviceEnumerator();

        IMMDevice device;

        int hr = enumerator.GetDefaultAudioEndpoint(
            eRender,
            eMultimedia,
            out device);

        if (hr < 0)
            Marshal.ThrowExceptionForHR(hr);

        Guid managerGuid =
            typeof(IAudioSessionManager2).GUID;

        object managerObject;

        hr = device.Activate(
            ref managerGuid,
            CLSCTX_ALL,
            IntPtr.Zero,
            out managerObject);

        if (hr < 0)
            Marshal.ThrowExceptionForHR(hr);

        IAudioSessionManager2 manager =
            (IAudioSessionManager2)managerObject;

        IAudioSessionEnumerator sessions;

        hr = manager.GetSessionEnumerator(
            out sessions);

        if (hr < 0)
            Marshal.ThrowExceptionForHR(hr);

        int count;

        hr = sessions.GetCount(out count);

        if (hr < 0)
            Marshal.ThrowExceptionForHR(hr);

        for (int i = 0; i < count; i++)
        {
            IAudioSessionControl control;

            hr = sessions.GetSession(
                i,
                out control);

            if (hr < 0)
                continue;

            IAudioSessionControl2 control2 =
                (IAudioSessionControl2)control;

            uint pid;

            hr = control2.GetProcessId(out pid);

            if (hr < 0)
                continue;

            if (pid != processId)
                continue;

            Guid volumeGuid =
                typeof(ISimpleAudioVolume).GUID;

            IntPtr unknown =
                Marshal.GetIUnknownForObject(control);

            IntPtr volumePtr;

            hr = Marshal.QueryInterface(
                unknown,
                ref volumeGuid,
                out volumePtr);

            Marshal.Release(unknown);

            if (hr < 0)
                continue;

            try
            {
                ISimpleAudioVolume volume =
                    (ISimpleAudioVolume)
                    Marshal.GetObjectForIUnknown(volumePtr);

                Guid eventContext = Guid.Empty;

                hr = volume.SetMasterVolume(
                    level,
                    ref eventContext);

                if (hr < 0)
                    Marshal.ThrowExceptionForHR(hr);

                return true;
            }
            finally
            {
                Marshal.Release(volumePtr);
            }
        }

        return false;
    }
}
"@


# ------------------------------------------------------------
# Wait for the game's process
# ------------------------------------------------------------

$timeout = 120
$elapsed = 0
$process = $null

while ($elapsed -lt $timeout)
{
    $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue |
               Select-Object -First 1

    if ($process)
    {
        break
    }

    Start-Sleep -Milliseconds 500
    $elapsed += 0.5
}

if (-not $process)
{
    exit 1
}


# ------------------------------------------------------------
# Wait for audio session
# ------------------------------------------------------------

$timeout = 60
$elapsed = 0

while ($elapsed -lt $timeout)
{
    $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue |
               Select-Object -First 1

    if (-not $process)
    {
        exit 1
    }

    $success = [AppVolume]::SetVolume(
        [uint32]$process.Id,
        [float]$Volume
    )

    if ($success)
    {
        exit 0
    }

    Start-Sleep -Milliseconds 500
    $elapsed += 0.5
}

exit 1
```