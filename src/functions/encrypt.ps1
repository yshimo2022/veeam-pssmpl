[byte[]] $EncryptedKey = (3,4,2,3,56,34,254,222,1,1,2,23,42,54,33,233,1,34,2,7,6,5,35,43)

<#
.SYNOPSIS
    パスワードファイルをエンコードしてファイルに保存
.NOTES
    https://github.com/senkousya/usingEncryptedStandardStringOnPowershell
#>
function passwordEncode {
    Param(
        [CmdletBinding()]
        [Parameter(Mandatory)]
        [String]$password,
        [Parameter(Mandatory)]
        [String]$filepath
    )
    $SecureString = ConvertTo-SecureString -String $password -AsPlainText -Force
    $encrypted = ConvertFrom-SecureString -SecureString $SecureString -key $EncryptedKey
    $encrypted | Set-Content $filepath
}

<#
.SYNOPSIS
    パスワードファイルをデコードして出力する
.NOTES
    https://github.com/senkousya/usingEncryptedStandardStringOnPowershell
#>
function passwordDecode {
    Param(
        [CmdletBinding()]
        [Parameter(Mandatory)]
        [String]$filepath
    )
    $importSecureString = Get-Content $filepath | ConvertTo-SecureString -key $EncryptedKey
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($importSecureString)
    $StringPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    return $StringPassword
}