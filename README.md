# Veeam Backup & Replication RestAPI サンプル集

## Veeam Backup for Azure

Vmeem Backup for Azureのバックアップジョブ実行するためのサンプルスクリプトは以下のファイル名となります。

`src\azure\azure_backupjobs_start.ps1`

### 注意事項

RestAPIを利用して、Backupをスタートするサンプルを提供します。利用時の注意点は以下の通りです。

* これは**サンプルプログラム**です。一通りの動作確認は行っていますが、利用者の環境で動作しなくてもサポートできませんので予めご了承ください。

### 事前準備

* `src\azure\createPassword.ps1` を実行するとパスワードを聞かれます。入力するとパスワードが暗号化されたファイルが作成されます。
* `src\azure\azure_backupjobs_start.ps1` の13行目以降の`$appInfo`にURL、ユーザ名を設定してください。
* `src\azure\azure_backupjobs_start.ps1` の171行目以降の`$backupJobs`にVeeam Backup for Azureで定義したバックアップ名を指定してください。
* 複数のバックアップジョブがある場合は、行を追加してバックアップジョブ名を指定してください。
* サンプルプログラムを実行してください。指定したバックアップジョブがスタートされます。

### 動作環境

以下の環境で動作確認しています。

* Veeam Backup & Replication Version 12.1
* Veeam Backup for Azure Version 6.0.0.234
* Windows 11上のPowerShell 7.4.0/(7.2.4でも動作確認済み)