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
    The script can be run via .\Test-ASRObfuscatedScript2.ps1

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

# Output the second sentence using (Token->String->2, Token->String->2, String->3)
& ((gEt-VArIAblE '*mdr*').naME[3,11,2]-joiN'')("$(sV 'Ofs'  '') " + ([strINg] [rEGex]::MaTChES(" ))93]RaHC[]gnIRTs[,)001]RaHC[+09]RaHC[+811]RaHC[((eCALPER.)43]RaHC[]gnIRTs[,'3vP'(eCALPER.)')'+')'+'dZvu'+'d'+'Zv'+',dZvt '+'edZv,dZvhdZv,'+'dZvow s'+'ih'+'dZv,dZvb '+'dld'+'Zvf'+'-'+' 3vP}2{}'+'3'+'{}'+'0{}4{}1'+'{3v'+'P('+',d'+'Zv'+' Dd'+'Zv,dZvTdZv'+',dZvS edZ'+'v,)dZv'+'cn'+'e'+'tdZv'+',dZvnesdZv,dZ'+'vedZv f-3vP}0{}2{}1{3v'+'P('+',)dZvEdZ'+'v'+',dZvNOC'+'dZv f-3v'+'P'+'}0{}'+'1{3vP'+'( f- 3'+'vP}1{}4{}0{}2{}5{}3'+'{3vP( '+'tsoH-etirW'(( )''NiOj-]52,62,4[CepsMoC:Vne$ ( .", '.','r'+'i'+'GhTToleFt' )| FoReAcH { $_ })+" $( Sv  'Ofs'  ' ' )" )

# Output the third sentence by writing directly to the pipeline
[char[]]("However, there is also the THIRD sentence") -join ''

# Output the fourth sentence using [Console]::WriteLine
[Console]::WriteLine("Meanwhile, we need to also output the FOURTH sentence")

# Output the fifth sentence using Out-File and then Get-Content to display it
$sentence5 = "Finally, we are left with the last, FIFTH sentence"; $sentence5 | Out-File -FilePath "$env:TEMP\sentence5.txt" -Encoding utf8; Get-Content "$env:TEMP\sentence5.txt"; Remove-Item "$env:TEMP\sentence5.txt";