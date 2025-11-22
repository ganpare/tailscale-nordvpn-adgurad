# NordVPN エンドポイント一覧

## インストール方法

### 方法1: 公式インストールスクリプト（推奨）
```bash
sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
sudo usermod -aG nordvpn $USER
# ログアウト/ログインまたは再起動が必要
```

### 方法2: aptリポジトリからインストール
```bash
wget -qO /etc/apt/trusted.gpg.d/nordvpn_public.asc https://repo.nordvpn.com/gpg/nordvpn_public.asc
echo "deb https://repo.nordvpn.com/deb/nordvpn/debian stable main" | sudo tee /etc/apt/sources.list.d/nordvpn.list
sudo apt update
sudo apt install nordvpn
sudo usermod -aG nordvpn $USER
# ログアウト/ログインまたは再起動が必要
```

## エンドポイント一覧の取得

インストール後、以下のコマンドでエンドポイント一覧を取得できます：

```bash
# 利用可能な国一覧
nordvpn countries

# 利用可能な都市一覧
nordvpn cities

# 特定の国の都市一覧
nordvpn cities Japan
nordvpn cities United_States
```

## 一般的なエンドポイント例

### 国名（大文字小文字は区別されませんが、アンダースコアで区切ります）
- `Japan`
- `United_States`
- `United_Kingdom`
- `Germany`
- `Netherlands`
- `Sweden`
- `Switzerland`
- `Canada`
- `Australia`
- `Singapore`
- `France`
- `Spain`
- `Italy`
- `South_Korea`
- `Brazil`
- `Mexico`
- `India`
- `Hong_Kong`
- `Taiwan`
- `New_Zealand`
- `Norway`
- `Denmark`
- `Finland`
- `Poland`
- `Czech_Republic`
- `Austria`
- `Belgium`
- `Ireland`
- `Portugal`
- `Greece`
- `Turkey`
- `Israel`
- `South_Africa`
- `Argentina`
- `Chile`
- `Colombia`
- `Estonia`
- `Latvia`
- `Lithuania`
- `Luxembourg`
- `Romania`
- `Slovakia`
- `Slovenia`
- `Ukraine`

### 都市名（アンダースコアで区切ります）
- **日本**: `Tokyo`, `Osaka`
- **アメリカ**: `New_York`, `Los_Angeles`, `Chicago`, `Miami`, `Seattle`, `San_Francisco`, `Dallas`, `Atlanta`, `Boston`, `Denver`, `Phoenix`, `Las_Vegas`, `Washington`, `Detroit`
- **イギリス**: `London`, `Manchester`, `Glasgow`, `Edinburgh`
- **ドイツ**: `Berlin`, `Frankfurt`, `Munich`, `Hamburg`
- **オランダ**: `Amsterdam`, `Rotterdam`
- **スウェーデン**: `Stockholm`, `Gothenburg`
- **スイス**: `Zurich`, `Geneva`
- **カナダ**: `Toronto`, `Vancouver`, `Montreal`
- **オーストラリア**: `Sydney`, `Melbourne`, `Perth`, `Brisbane`
- **フランス**: `Paris`, `Marseille`, `Lyon`
- **スペイン**: `Madrid`, `Barcelona`
- **イタリア**: `Rome`, `Milan`
- **シンガポール**: `Singapore`
- **香港**: `Hong_Kong`
- **台湾**: `Taipei`
- **韓国**: `Seoul`
- **インド**: `Mumbai`, `New_Delhi`, `Bangalore`
- **ブラジル**: `Sao_Paulo`, `Rio_de_Janeiro`
- **メキシコ**: `Mexico_City`
- **ノルウェー**: `Oslo`
- **デンマーク**: `Copenhagen`
- **フィンランド**: `Helsinki`
- **ポーランド**: `Warsaw`
- **チェコ**: `Prague`
- **オーストリア**: `Vienna`
- **ベルギー**: `Brussels`
- **アイルランド**: `Dublin`
- **ポルトガル**: `Lisbon`
- **ギリシャ**: `Athens`
- **トルコ**: `Istanbul`
- **イスラエル**: `Tel_Aviv`
- **南アフリカ**: `Johannesburg`, `Cape_Town`
- **アルゼンチン**: `Buenos_Aires`
- **チリ**: `Santiago`
- **コロンビア**: `Bogota`

## .envファイルでの設定例

```bash
# 日本に接続
NORDVPN_ENDPOINT=Japan

# 東京に接続
NORDVPN_ENDPOINT=Tokyo

# ニューヨークに接続
NORDVPN_ENDPOINT=New_York

# デフォルト（サンフランシスコ）
NORDVPN_ENDPOINT=San_Francisco
```

## 接続先の変更方法

### 1. .envファイルを編集

```bash
# .envファイルを編集
nano .env
# または
vi .env
```

`NORDVPN_ENDPOINT` の値を変更します：

```bash
NORDVPN_ENDPOINT=Tokyo  # 東京に変更
```

### 2. NordVPNコンテナを再作成

**.envファイルの変更後、以下のコマンドで反映**：

```bash
docker compose up -d nordvpn
```

このコマンドは：
- 変更された環境変数を読み込む
- NordVPNコンテナのみを再作成・再起動
- 他のコンテナ（Tailscale、AdGuard）には影響しない
- **ビルドは不要**（イメージの再ビルドなし）

### 3. 接続状態の確認

```bash
# NordVPNの接続状態を確認
docker compose exec nordvpn nordvpn status
```

**出力例**：
```
Status: Connected
Server: Japan #664
Hostname: jp664.nordvpn.com
IP: 192.166.247.164
Country: Japan
City: Osaka
Current technology: OPENVPN
Current protocol: TCP
```

### 4. ログの確認（オプション）

接続に問題がある場合は、ログを確認：

```bash
# NordVPNコンテナのログを表示
docker compose logs nordvpn --tail 50

# リアルタイムでログを監視
docker compose logs nordvpn -f
```

## 注意事項

- エンドポイント名は**アンダースコア（_）で区切る**必要があります（スペースは使えません）
- 大文字小文字は通常区別されませんが、公式の表記に合わせることを推奨します
- 利用可能なエンドポイントは、NordVPNアカウントのプランや地域によって異なる場合があります
- 最新のエンドポイント一覧は、`nordvpn countries` と `nordvpn cities` コマンドで確認できます

