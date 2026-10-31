$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class WorkshopExitProbe {
  [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
  public static extern bool ShutdownBlockReasonQuery(IntPtr hwnd, StringBuilder reason, ref uint length);
  [DllImport("user32.dll", SetLastError = true)]
  public static extern IntPtr SendMessageTimeout(IntPtr hwnd, uint message, UIntPtr wparam,
      IntPtr lparam, uint flags, uint timeout, out UIntPtr result);
}
'@

$executable = Resolve-Path 'build/windows/x64/runner/Release/workshop_desktop.exe'
$probeApp = Start-Process -FilePath $executable -PassThru
try {
  $deadline = [DateTime]::UtcNow.AddSeconds(45)
  $ready = $false
  while ([DateTime]::UtcNow -lt $deadline) {
    $probeApp.Refresh()
    if ($probeApp.HasExited) { throw 'Release app exited before its close guard became ready.' }
    $window = $probeApp.MainWindowHandle
    if ($window -ne [IntPtr]::Zero) {
      $text = [System.Text.StringBuilder]::new(256)
      [uint32]$length = 256
      if ([WorkshopExitProbe]::ShutdownBlockReasonQuery($window, $text, [ref]$length) -and $text.Length -gt 0) {
        $ready = $true
        break
      }
    }
    Start-Sleep -Milliseconds 200
  }
  if (-not $ready) { throw 'Native backup reminder did not register its shutdown reason.' }

  [UIntPtr]$reply = [UIntPtr]::Zero
  $sent = [WorkshopExitProbe]::SendMessageTimeout($window, 0x0010, [UIntPtr]::Zero, [IntPtr]::Zero, 2, 5000, [ref]$reply)
  if ($sent -eq [IntPtr]::Zero) { throw 'Main window did not answer WM_CLOSE.' }
  Start-Sleep -Milliseconds 700
  $probeApp.Refresh()
  if ($probeApp.HasExited) { throw 'WM_CLOSE bypassed the backup reminder.' }

  $sent = [WorkshopExitProbe]::SendMessageTimeout($window, 0x0011, [UIntPtr]::Zero, [IntPtr]::Zero, 2, 5000, [ref]$reply)
  if ($sent -eq [IntPtr]::Zero -or $reply.ToUInt64() -ne 0) {
    throw 'Ordinary Windows shutdown was not deferred for the backup reminder.'
  }
  # A critical termination is not cancelable; do not claim that it is protected.
  $sent = [WorkshopExitProbe]::SendMessageTimeout($window, 0x0011, [UIntPtr]::Zero, [IntPtr]::new(0x40000000), 2, 5000, [ref]$reply)
  if ($sent -eq [IntPtr]::Zero -or $reply.ToUInt64() -ne 1) {
    throw 'Critical termination handling returned an unexpected result.'
  }
  $null = [WorkshopExitProbe]::SendMessageTimeout($window, 0x0016, [UIntPtr]::Zero, [IntPtr]::Zero, 2, 5000, [ref]$reply)
  $probeApp.Refresh()
  if ($probeApp.HasExited) { throw 'Cancelled session ending unexpectedly closed the app.' }
  Write-Host 'Release smoke test passed: close prompt, shutdown deferral and forced-exit boundary.'
} finally {
  # Only the synthetic app process launched by this CI smoke test is terminated.
  $probeApp.Refresh()
  if (-not $probeApp.HasExited) {
    Stop-Process -Id $probeApp.Id -Force
    $null = $probeApp.WaitForExit(5000)
  }
}
