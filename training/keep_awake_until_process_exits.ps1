param(
    [Parameter(Mandatory = $true)]
    [int]$ProcessIdToWatch
)

Add-Type @"
using System.Runtime.InteropServices;

public static class ReadBuddyExecutionState
{
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern uint SetThreadExecutionState(uint flags);
}
"@

$continuous = [uint32]0x80000000
$systemRequired = [uint32]0x00000001

[ReadBuddyExecutionState]::SetThreadExecutionState(
    $continuous -bor $systemRequired
) | Out-Null

try {
    while (Get-Process -Id $ProcessIdToWatch -ErrorAction SilentlyContinue) {
        Start-Sleep -Seconds 30
    }
}
finally {
    [ReadBuddyExecutionState]::SetThreadExecutionState($continuous) | Out-Null
}
