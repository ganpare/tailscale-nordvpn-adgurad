# tailscale-nordvpn-adguard

[English](README.md) | [日本語](README.ja.md)

NordVPNのexit nodeとAdGuard Home統合を使用したDockerコンテナ化されたTailscale exit nodeを作成します。

このプロジェクトは3つのDockerコンテナを作成します：Tailscale、NordVPN、AdGuard Home。Tailscaleインスタンスはexit nodeとしてアドバタイズし、NordVPNコンテナを出口ルートとして使用し、DNSクエリをAdGuard Homeに転送して広告ブロックとプライバシー保護を実現します。

## このフォークでの拡張機能

このフォークでは、元のプロジェクトに以下の改善を加えています：

- ✅ **AdGuardのポート設定を追加**: Web管理画面(3000)とDNS(53)ポートのマッピングを追加
- ✅ **環境変数の修正**: Tailscaleコンテナに`IP_ADGUARD`環境変数を追加し、DNS転送機能を有効化
- ✅ **詳細なドキュメント**: 
  - 日本語版README（このファイル）
  - NordVPNエンドポイント一覧と変更手順（`NORDVPN_ENDPOINTS.md`）
  - ネットワーク構成の詳細な解説
- ✅ **セットアップガイドの改善**: 初回セットアップから動作確認までの手順を明確化

## 必要要件

* Dockerホストとdocker build tools
* NordVPNアカウント

## 機能

* 代替ログインサーバー（Headscaleなど）のサポート
* 任意のNordVPN地域への接続
* このスタックで`AdGuard Home`を実行し、Tailscaleexit nodeからDNSを転送

## セットアップ手順

### 1. 環境設定

`.env.example`を`.env`にコピーして、必要な設定をカスタマイズします：

```bash
cp .env.example .env
```

`.env`ファイルの設定項目：

* `NORDVPN_TOKEN`: NordVPNのログイントークン（[取得方法](https://my.nordaccount.com/dashboard/nordvpn/access-tokens)）
* `TAILSCALE_UP_LOGIN_SERVER`: カスタムTailscaleログインサーバー（公式を使う場合は空欄のまま）
* `NORDVPN_ENDPOINT`: NordVPNの接続先（例: `Japan`, `Tokyo`, `United_States`）
* `NORDVPN_TECHNOLOGY`: `OPENVPN` または `NORDLYNX`
* `NORDVPN_OPENVPN_PROTOCOL`: `TCP` または `UDP`
* `IP_ADGUARD`: AdGuardコンテナのIPv4アドレス（例: `10.1.1.4`）exit nodeはここにDNSクエリを転送します

### 2. ホストOSのAdGuardを停止（該当する場合）

ホストOSに既にAdGuard Homeがインストールされている場合は、停止して無効化します：

```bash
sudo systemctl stop AdGuardHome
sudo systemctl disable AdGuardHome
```

### 3. コンテナの起動

```bash
docker compose up -d
```

### 4. Tailscaleの認証

Tailscaleコンテナのログを確認して、認証URLを取得します：

```bash
docker compose logs tailscale | grep "https://login.tailscale.com"
```

表示されたURLにブラウザでアクセスし、Tailscaleアカウントで認証します。

### 5. exit nodeの承認

[Tailscale Admin Console](https://login.tailscale.com/admin/machines)にアクセスし：

1. 新しいデバイス（`INSTANCE_NAME`で設定した名前）を探す
2. デバイスをクリックして詳細を表示
3. **"Edit route settings"** または **"..."メニュー** から設定
4. **"Use as exit node"** を承認

### 6. AdGuard Homeのセットアップ

ブラウザで `http://<docker-host-ip>:3000` にアクセスし、初期セットアップを完了します：

1. **管理Webインターフェース**: ポート `3000`
2. **DNSサーバー**: ポート `53`
3. 管理者ユーザー名とパスワードを設定
4. **DNS設定**で上流DNSサーバーを設定：
   ```
   https://dns10.quad9.net/dns-query
   8.8.8.8
   1.1.1.1
   ```

設定ファイルは `./adguard/conf` と `./adguard/workdir` に保存されます。

### 7. DNS設定（重要）

Tailscale Admin Consoleの**DNS設定**：

**オプション1: 自動DNS転送（推奨）**
- Global nameserversは**空のまま**
- "Override DNS servers"は**OFF**
- exit node使用時、iptablesが自動的にDNSをAdGuardにリダイレクトします

**オプション2: 明示的なDNS設定**
- 各デバイスでTailscaleアプリの"Use DNS settings"を有効化

## exit nodeの使用方法

### デバイス側の設定

**iPhone/iPad**:
1. Tailscaleアプリを開く
2. **"Exit Node"** セクションでexit nodeを選択

**Mac/Windows**:
1. Tailscaleアプリを開く
2. "Exit node"メニューから選択

**Linux/CLI**:
```bash
tailscale up --exit-node=<exit nodeのIP>
```

### 動作確認

exit nodeに接続後、以下のサイトで確認：

- https://ipinfo.io/
- https://whatismyipaddress.com/

**期待される結果**:
- IPアドレス: NordVPNの接続先のIP
- 場所: `NORDVPN_ENDPOINT`で指定した国/都市

## 接続先の変更方法

### 1. .envファイルを編集

```bash
nano .env
```

`NORDVPN_ENDPOINT`を変更：

```bash
NORDVPN_ENDPOINT=Tokyo  # 東京に変更
```

利用可能なエンドポイント一覧は `NORDVPN_ENDPOINTS.md` を参照してください。

### 2. NordVPNコンテナを再作成

```bash
docker compose up -d nordvpn
```

**注意**: ビルドは不要です。このコマンドでNordVPNコンテナのみが再起動されます。

### 3. 接続状態の確認

```bash
docker compose exec nordvpn nordvpn status
```

## ネットワーク構成

### コンテナ内部ネットワーク (Docker)

```
10.1.1.1    - Dockerブリッジゲートウェイ
10.1.1.2    - Tailscaleコンテナ
10.1.1.3    - NordVPNコンテナ
10.1.1.4    - AdGuardコンテナ
```

### トラフィックフロー

```
[あなたのデバイス]
    ↓ Tailscale VPN (暗号化)
[Tailscaleコンテナ (10.1.1.2)]
    ↓ デフォルトゲートウェイ
[NordVPNコンテナ (10.1.1.3)]
    ↓ VPN接続
[NordVPN出口サーバー]
    ↓
[インターネット]

DNSクエリの流れ:
[デバイス] → [Tailscale] → [AdGuard (10.1.1.4)] → [Quad9/Google/Cloudflare]
```

### レイヤー構造

1. **物理ネットワーク**: ホストのローカルLAN (例: 192.168.0.x)
2. **Dockerネットワーク**: コンテナ間通信用 (10.1.1.0/24)
3. **Tailscaleネットワーク**: 仮想プライベートネットワーク (100.x.x.x)

各コンテナはホストのローカルLANには直接参加せず、完全に隔離された環境で動作します。

## トラブルシューティング

### ローカルネットワークへのアクセスができない

**症状**: Exit Nodeを使用すると、ローカルネットワーク（例: 192.168.0.x）のデバイスにアクセスできなくなる

**原因**: Exit Nodeを使用すると、すべてのトラフィック（ローカルネットワーク宛を含む）がVPN経由になるため

**解決方法**:

**Windows/Mac/Linux（GUI）**:
1. Tailscaleアプリを開く
2. Exit Nodeの設定で **"Allow LAN access"** または **"ローカルネットワークアクセスを許可"** を有効化

**Linux/CLI**:
```bash
tailscale set --exit-node-allow-lan-access=true
```

**または、Tailscale Admin Consoleで設定**:
1. [Tailscale Admin Console](https://login.tailscale.com/admin/machines) にアクセス
2. Exit Nodeを使用しているデバイスを選択
3. 設定で "Allow LAN access when using an exit node" を有効化

この設定により、ローカルネットワーク宛のトラフィックはVPNをバイパスし、直接ルーティングされます。

### ログの確認

```bash
# すべてのコンテナのログ
docker compose logs

# 特定のコンテナのログ
docker compose logs tailscale
docker compose logs nordvpn
docker compose logs adguard

# リアルタイムでログを監視
docker compose logs -f
```

### コンテナの状態確認

```bash
docker compose ps
```

### NordVPN接続状態

```bash
docker compose exec nordvpn nordvpn status
```

### Tailscaleの状態

```bash
docker compose exec tailscale tailscale status
```

### DNS転送ルールの確認

```bash
docker compose exec tailscale iptables -t nat -L PREROUTING -n -v
```

期待される出力:
```
DNAT  udp  --  tailscale0  *  0.0.0.0/0  0.0.0.0/0  udp dpt:53 to:10.1.1.4
DNAT  tcp  --  tailscale0  *  0.0.0.0/0  0.0.0.0/0  tcp dpt:53 to:10.1.1.4
```

### コンテナへのシェルアクセス

```bash
# Tailscaleコンテナ
docker compose exec -it tailscale /bin/sh

# NordVPNコンテナ
docker compose exec -it nordvpn /bin/bash

# AdGuardコンテナ
docker compose exec -it adguard /bin/sh
```

## よくある質問

**Q: ホストLinuxにもTailscaleがインストールされているが問題ないか？**

A: 問題ありません。コンテナ内のTailscaleは完全に独立したデバイスとして動作し、異なるTailscale IPアドレスが割り当てられます。

**Q: 複数のexit nodeを異なる国で起動できるか？**

A: 可能です。`INSTANCE_NAME`と`IP_SUBNET`を変えて、複数のスタックを起動できます。

**Q: AdGuardなしで使用できるか？**

A: 可能です。`.env`から`IP_ADGUARD`を削除するか空にすれば、DNS転送は無効になります。

**Q: NordLynxとOpenVPNの違いは？**

A: NordLynx（WireGuard）は高速ですが、一部の環境で動作しない場合があります。OpenVPNはより互換性が高いです。

## 関連ファイル

- `NORDVPN_ENDPOINTS.md`: NordVPN接続先の一覧と変更方法
- `.env.example`: 環境変数のサンプル
- `docker-compose.yml`: コンテナ構成ファイル

## ライセンス

元のプロジェクトのライセンスに従います。

## 参考リンク

- [元のプロジェクト](https://github.com/ryanlim/tailscale-nordvpn)
- [Tailscale公式ドキュメント](https://tailscale.com/kb/)
- [NordVPN Linux公式ドキュメント](https://support.nordvpn.com/hc/en-us/articles/20196094470929-Installing-NordVPN-on-Linux-distributions)
- [AdGuard Home公式](https://adguard.com/en/adguard-home/overview.html)
