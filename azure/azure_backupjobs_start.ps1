<#
.SYNOPSIS
    Veeam Backup for Azure のジョブをRestAPI経由で実行するためのPowerShellサンプル

.NOTES
    PSVersion 7.4.0 でテストしています。
#>

. "$($PSScriptRoot)/../functions/Get-Logger.ps1"
. "$($PSScriptRoot)/../functions/encrypt.ps1"
Add-Type -AssemblyName System.Web

$appInfo = [PSCustomObject]@{
    server = [PSCustomObject]@{
        baseUrl = "https://azvmap01.japaneast.cloudapp.azure.com" # URLを設定してください。
        version = "v6"
        username = "veeamadmin" # ユーザ名を設定してください。
        password = (passwordDecode -filepath (Join-Path $PSScriptRoot password.dat))
    }
    logger = Get-Logger -Logfile "$($PSScriptRoot)/$([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path))-$(Get-Date -Format "yyyyMM").log"
}

<#
.SYNOPSIS
    RestAPIにログインする

.NOTES
    $appInfo.server.access_token に Authorization Key を設定する
#>
function login {
    $headers = @{
        'accept' = 'application/json'
        'Content-Type' = 'application/x-www-form-urlencoded'
    }
    
    $body = @{
        'username' = "$($appInfo.server.username)"
        'password' = "$($appInfo.server.password)"
        'grant_type' = 'Password'
    }
    
    # REST APIエンドポイントへのリクエスト
    $endpoint = "$($appInfo.server.baseUrl)/api/oauth2/token"
    
    $response = Invoke-RestMethod -SkipCertificateCheck -Uri $endpoint -Headers $headers -Body $body -Method Post
    $appInfo.server | Add-Member -MemberType NoteProperty -Name "access_token" -Value "Bearer $($response.access_token)"
    $appInfo.logger.Info.Invoke("Login Success")
}

<#
.SYNOPSIS
    RestAPIからログアウトする
#>
function logout {
    $headers = @{
        'accept' = '*/*'
        'Authorization' = $appInfo.server.access_token
    }
    
    # REST APIエンドポイントへのリクエスト
    $endpoint = "$($appInfo.server.baseUrl)/api/oauth2/token"
    
    $response = Invoke-RestMethod -SkipCertificateCheck -Uri $endpoint -Headers $headers -Method Delete
    [void]$response
    $appInfo.logger.Info.Invoke("Logout Success")
}

<#
.SYNOPSIS
    指定した PolicyName のバックアップジョブを返す

.PARAMETER policyName
    policyName (ジョブ名)を指定する、前方一致
#>
function virtualMachines {
    Param(
        [CmdletBinding()]
        [Parameter()]
        [String]$policyName
    )

    $endpoint = [System.UriBuilder]"$($appInfo.server.baseUrl)/api/$($appInfo.server.version)/policies/virtualMachines"

    $headers = @{
        'accept' = 'application/json'
        'Authorization' = "$($appInfo.server.access_token)"
    }

    $parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    $parameters['PolicyName'] = "$($policyName)"
    
    $endpoint.Query = $parameters.ToString()

    $response = Invoke-RestMethod -SkipCertificateCheck -Uri $endpoint.Uri -Headers $headers -Method Get
    $appInfo.logger.Info.Invoke("virtualMachines policyName=`"$($policyName)`" Success")

    return $response
}

<#
.SYNOPSIS
    指定した policyId のジョブを実行する

.PARAMETER policyName
    policyId (ジョブのid)を指定する(必須)

.NOTES
    関数を呼ぶ前にバックアップジョブのステータスを事前確認すること
#>
function startBackup {
    Param(
        [CmdletBinding()]
        [Parameter(Mandatory)]
        [String]$policyId
    )

    $endpoint = "$($appInfo.server.baseUrl)/api/$($appInfo.server.version)/policies/virtualMachines/$($policyId)/start"

    $headers = @{
        'accept' = 'application/json'
        'Authorization' = $appInfo.server.access_token
    }
  
    $response = Invoke-RestMethod -SkipCertificateCheck -Uri $endpoint -Headers $headers -Method Post
    $appInfo.logger.Info.Invoke("startBackup policyId=`"$($policyId)`" Success")

    return $response
}

<#
.SYNOPSIS
    バックアップジョブの実行

.NOTES
    メインの処理を記載している
#>
function executeBackupJobs {
    Param(
        [CmdletBinding()]
        [Parameter(Mandatory)]
        [Array]$backupJobs
    )
    
    # バックアップジョブ名を検索して、バックアップをスタート
    foreach ($backupJob in $backupJobs) {
        $response = virtualMachines -PolicyName $backupJob
        foreach ($result in $response.results) {
            $policyId = $result.id
            if ($result.backupStatus -ne "Running") {
                $result = startBackup -policyId $policyId
                $appInfo.logger.Info.Invoke("Backup Jobs `"$($backupJob)`" start.")
            } else {
                $appInfo.logger.Info.Invoke("Backup Jobs `"$($backupJob)`" already started.")
            }
        }
    }
}

<#
.SYNOPSIS
    バックアップ呼び出しとエラー処理を実行

.NOTES
    エラー処理を一か所に統合
#>
function main {
    $appInfo.logger.Info.Invoke("----- Start Program -----")

    # 実行したいバックアップジョブ名を記載する。完全一致で記載
    $backupJobs = @(
        "Backup Job Windows Servers"
    )

    try {
        # ログイン実行
        login
        executeBackupJobs -backupJobs $backupJobs
        # ログアウト実行
        logout
        $result = 0
    } catch {
        $appInfo.logger.Error.Invoke("$($_.Exception.Message)")
        $result = -1
    } finally {
        $appInfo.logger.Info.Invoke("----- Finish Program -----")
    }
    exit $result
}

<#
.SYNOPSIS
  メイン処理を呼び出す
#>
main