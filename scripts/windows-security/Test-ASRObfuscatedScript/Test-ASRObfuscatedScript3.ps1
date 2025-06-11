<#
.SYNOPSIS
    This is a script that will test "Block execution of potentially obfuscated scripts" Attack Surface Reduction rule in Microsoft Defender for Endpoint.

.DESCRIPTION
    Script obfuscation is a common technique that both malware authors and legitimate applications use to hide intellectual property 
    or decrease script loading times. Malware authors also use obfuscation to make malicious code harder to read, which hampers close 
    scrutiny by humans and security software.
    This script was meant to be obfuscated in certain parts for Windows Defender to take action against it (and therefore to 
    test the abilities of Microsoft's Attack Surface Reduction rules, specifically: "Block execution of potentially obfuscated scripts").
    Please keep in mind that Microsoft Defender for Endpoint can remove the script.

.EXAMPLE
    The script can be run via .\Test-ASRObfuscatedScript3.ps1

.NOTES
    Author:         egrzeszczak
    Created:        2025-06-02
    Version:        v1.0.0
    Dependencies:   none
    Compatibility:  >=5.0

.LINK
    https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-reference#block-execution-of-potentially-obfuscated-scripts
    https://github.com/danielbohannon/Invoke-Obfuscation
#>

# Output the first sentence using Write-Output
Write-Output "Hello, this is the FISRT sentence"

# Output the second sentence using Write-Host
Write-Host "This would be the SECOND sentence"

# Output the third sentence by writing directly to the pipeline (Encoding->1, Compress->1)
&((GV '*Mdr*').nAME[3,11,2]-JOIn'')(nEw-obJecT SysteM.io.cOMprEsSIoN.DEfLATEsTream( [sYsteM.Io.mEMorYstrEAM][cOnverT]::FrombaSE64STRING('PY/NqsIwEIVf5SyEtjBKp0napjsRF7roXVxwU7qSy1XBH9T3x5lJEJpyJjPnyxmsSiy242HY/Fx/H3/HyRMHasK8vNx3Y1FUKKfX+7m7/c/DsL+fxxJFAZqOp/VzmmeUkUExErj2FDti9iBEluNUOIKvRThP6BpIX+bBbA6WsjeBbPQy5mysTUjrITVNu0ZF0JGglbzeWU9BEl0eoExAQnx9vUA0AzqJ1otoe7tXm6URQK2/NntSnbZThCVki+CD0du8UU5kmwrYRflQVajwAQ==' ),[sYstem.IO.coMpResSION.coMpREsSIOnMoDE]::DecoMPrEsS) | %{ nEw-obJecT sYSTEM.io.stREamrEadeR($_ , [teXT.ENCOdiNg]::AScIi) }).reaDToeND()

# Output the fourth sentence using [Console]::WriteLine
[Console]::WriteLine("Meanwhile, we need to also output the FOURTH sentence")

# Output the fifth sentence using Out-File and then Get-Content to display it
$sentence5 = "Finally, we are left with the last, FIFTH sentence"; $sentence5 | Out-File -FilePath "$env:TEMP\sentence5.txt" -Encoding utf8; Get-Content "$env:TEMP\sentence5.txt"; Remove-Item "$env:TEMP\sentence5.txt";