. "$($PSScriptRoot)/../functions/encrypt.ps1"

$filepath = (Join-Path $PSScriptRoot cred.dat)
$username = Read-Host "ユーザ名を入力してください"
$password = Read-Host -MaskInput "パスワードを入力してください"
$cred = @{
    'username' = $username
    'password' = $password
}
passwordEncode -password ($cred | ConvertTo-Json) -filepath $filepath