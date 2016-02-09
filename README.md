# 不正アクセス検知機能を持つ仮想FWを備えたIaaS

## 概要
Virtualbox と OpenFlow を用いて FW（ファイアウォール）機能を備えた MiniIaaS
を作成しました。ユーザ（クラウド利用者）は Web インターフェースにより
仮想マシン（VM）を作成・編集・削除・起動・停止することができ、さらにユーザ単位で希望する
FW のルールを設定できます。

また、（クラウド側のネットワークと）この FW 機能は
OpenFlow（Trema）によって実現されており、
不正なアクセス（ICMP Flood）を自動検知し遮断する機能も備えています。
これにより、遮断されるべき不正アクセス元の情報（Blacklist）は全てのユーザの通信ルールに反映され、
IaaS上に作成された全てのVMをセキュリティ脅威から守ります。



## 紹介用ポスター
[ポスターはこちら](./img/enshu_poster_final.pdf)

## 成果物の説明
* 基本的に全て Controller のソースコード
    * Controller および VM の操作に関するモジュールは主に /lib/ に配置
* /CodeIgniter.zip
    * Web コンテンツ。解凍して Web サーバの DocumentRoot に配置して使用
* host/host.rb
    * ホストが Controller から命令を受信してコマンドを実行するためのプログラム

## Webインターフェースの使い方
1. Webページへアクセス
	* ユーザのPCからWebブラウザで以下のURLを入力すると、IaaSログインページヘ移動できる。

		http://(ControllerのIPアドレス)/CodeIgniter/form_murata
	
2. ユーザの登録とログイン
	* IaaSを利用するためのIDとパスワードを設定するために、ログインページ下部の"新規登録"をクリックする
	* UserCreateページへ移動し、UserIDとパスワードを登録する。このとき、すでに登録されているIDで新規登録を行った場合、登録不可として他のIDによる登録を促す。
	* ユーザ登録が成功し、登録したIDでログインすると、アクション選択ページへ移動する。
	* アクション選択ページには、当該ユーザーが現在設定しているVMとファイアーウォールの一覧を表示しており、IaaSの利用状況を確認することが出来る。
	* 当ページで、IaaSを利用する際のアクションを選択出来るようになっており、このページを起点として、IaaSを利用する事となる。以下に、アクション一覧を記載する。

			user_delete ：IaaSを利用するユーザの登録を削除する。
			vm_create：VMを生成する
			vm_modify：VMを編集する	
			vm_delete：VMを削除する
			vm_state_change：VMの状態を変更(停止中から起動、起動中から停止)する
			fw_control_add：ファイアーウォールの設定を追加する
			fw_control_modify：ファイアーウォールの設定を編集する
			fw_control_delete：ファイアーウォールの設定を削除する

3. VMの作成
	* アクション選択ページでvm_createを選択すると、VM\_Createページへ移動する。
	* フォームに記された4項目を入力し、submitボタンをクリックすると、VMを作成することができる。
4. VMの起動・停止
	* VMを作成した段階ではVMは停止中であり、当VMを利用する事できない。そのため、当VMを起動する必要がある。その際には、アクション選択ページでvm\_state\_changeアクションを選択する。
	* VM\_STATE\_CHANGEページでは、作成したVMの一覧から、各VMの状態(停止中・起動中・セットアップ中)を確認することが出来る。そして、停止中のVMには起動ボタン、起動中のVMには停止ボタンが付随されている。停止しているVMを起動するために、起動ボタンをクリックすると、VMを起動することが出来る。VMの停止についても同様である。
5. VMの編集
	* アクション選択ページでvm\_modifyを選択すると、VM\_MODIFYページへ移動する。
	* フォームに記された4項目を入力する。VMを編集するためには、VMは停止中である必要があるため、VMの状態が停止中のものから既存のVMを選択する。
6. VMの削除
	* アクション選択ページでvm\_deleteを選択すると、VM\_DELETEページへ移動する。
	* VM\_DELETEの際には、既存のVMのうち、VM\_IDのみを入力することで削除できる。ただし、VMを編集する場合と同様に、削除するVMは停止中でなければならない。
7. ファイアーウォールの設定に関する操作
	* アクション選択ページでfw\_control_addを選択すると、ファイアーウォールのルール追加ページへ移動する。
	* フォームに記された5項目を入力する。
	* ファイアーウォールの設定編集・削除の際も、これまでと同様に、与えられたフォームに従い、入力を行うことによって、ファイアーウォールの設定を行うことができる。
8. ユーザの削除
	* IaaSを今後使用しなくなるといった場合のために、ユーザ情報を削除することが出来る。その際には、アクション選択ページでuser\_deleteを選択する。
	* USER\_DELETEページでは、確認のために当該ユーザーが登録したパスワードを入力する。そのパスワードが適切であった場合にユーザー情報が削除され、再度そのIDでログインすることはできない。
	* ユーザ削除を実行するためには、当ユーザが作成したVMがすべて削除されていなければならない。
		


## デモ（使い方）

### デモの内容
ユーザが VM を作成し、起動するまでの設定・操作方法を記します。

### Controller の設定
1. [ここ](http://www.anarg.jp/enshuu2/miniiaas_controller_20160203.ova)から VM イメージをダウンロード。Virtualbox で起動。
1. ID:ensyuu2 / Password:ensyuu2 でログイン。
1. Controller に IP アドレスを設定
  * Web サーバ/DHCP サーバ 用に NIC を一つ用意
  * そのインターフェース（eth0） に静的 IP アドレスを設定
1. 以下のコマンドを実行して DHCP サーバを起動
```
$ sudo service isc-dhcp-server start
```
1. ~/git/iaas/ に移動し、以下のコマンドを実行して Controller を起動
```
$ ruby ./test.rb
```

### PM (Physical Machine) の設定
1. Virtualbox, Rubyの実行環境 をインストール

2. ホームディレクトリ(C:\Users\#{ユーザ名})に host.rb, vm_memories.json, 仮想アプライアンス([centos.ova](http://www.anarg.jp/enshuu2/centos.ova))をコピー

3. host.rb ファイルの initialize メソッド内の設定を環境に合わせた文字列・値に変更
   * @home … ホームディレクトリのパス
   * @ctrl_ip … Controller のIPアドレス
   * @ova … 使用する仮想アプライアンスのファイル名
   * @adapter … ブリッジ接続に使用するネットワークアダプタ名
      * 「コントロール パネル\ネットワークとインターネット\ネットワーク接続」で表示されるアダプタ名をそのままコピペ
   * @rest_memory … 最大利用可能メモリ数(MB)(ホストマシンのスペックを超えないように)

4. PowerShell などで以下のコマンドを実行して filesystem をインストール
```
 > gem install sys-filesystem
```
5.PowerShell などで以下のコマンドを実行
```
 > ruby host.rb
```
 
 
### 使用例

1. ユーザの PC から Web ブラウザで Controller にアクセス
```
 http://(ControllerのIPアドレス)/CodeIgniter/form_murata
```
2. 「新規登録」をクリックし、ユーザ作成画面でユーザを作成してログイン

 <img src="./img/WS000001.BMP" width="480" height="300">
 <img src="./img/WS000002.BMP" width="480" height="300">

3. 「アクション」から「VM_CREATE」を選択

 <img src="./img/WS000006.BMP" width="480" height="300">

4. VM の情報を入力し、VM を作成（作成には時間がかかります）

  <img src="./img/WS000007.BMP" width="480" height="300">
  <img src="./img/WS000009.BMP" width="480" height="300">

5. VM の状態が「停止中」になった後、「起動する」ボタンを押下

 <img src="./img/WS000010.BMP" width="480" height="300">

6. VM が起動すると管理画面にて IP アドレスが表示されるので ssh でアクセス
    * ID: root / Password: password
