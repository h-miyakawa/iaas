# 不正アクセス検知機能を持つ仮想FWを備えた IaaS

## 概要
Virtualbox と OpenFlow を用いて FW（ファイアウォール）機能を備えた MiniIaaS
を作成しました。ユーザ（クラウド利用者）は Web インターフェースにより
仮想マシン（VM）を作成・編集・削除・起動・停止することができ、さらにユーザ単位で希望する
ファイアウォールのルールを設定できます。

また、クラウド側のネットワーク及びこのファイアウォール機能は
OpenFlow（Trema）によって実現されており、
不正なアクセス（ICMP Flood）を自動検知し遮断する機能も備えています。
これにより、遮断された不正アクセス元についての情報（Blacklist）は全てのユーザの通信ルールに反映され、
IaaS上に作成された全てのVMをセキュリティ脅威から守ります。



### 紹介用ポスター
（ポスター画像はる）


## デモ（使い方）

### デモの内容
ユーザが VM を作成し、起動するまでの設定・操作方法を記します。

### Controller の設定
1. 〜〜から VM イメージをダウンロード。Virtualbox で起動。
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
（PMの設定をかく）


### 使用例

1. ユーザの PC から Web ブラウザで Controller にアクセス
```
 http://(ControllerのIPアドレス)/CodeIgnitor/form_murata
```
2. あああ

