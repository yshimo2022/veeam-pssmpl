. "$($PSScriptRoot)/../functions/encrypt.ps1"

$filepath = (Join-Path $PSScriptRoot password.dat)
$password = Read-Host -MaskInput "パスワードを入力してください"
passwordEncode -password $password -filepath $filepath