#!/bin/bash

# NordVPNエンドポイントをランダムに選択してコンテナを再起動するスクリプト

# スクリプトのディレクトリを取得（シンボリックリンク経由でも動作）
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# プロジェクトディレクトリを検出（docker-compose.ymlがあるディレクトリを探す）
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    # スクリプトがシンボリックリンク経由で実行されている場合、元の場所を探す
    if [ -L "${BASH_SOURCE[0]}" ]; then
        REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
        PROJECT_DIR="$(cd "$(dirname "$REAL_SCRIPT")" && pwd)"
    fi
    
    # それでも見つからない場合、環境変数から取得を試みる
    if [ ! -f "$PROJECT_DIR/docker-compose.yml" ] && [ -n "$TAILSCALE_NORDVPN_DIR" ]; then
        PROJECT_DIR="$TAILSCALE_NORDVPN_DIR"
    fi
fi

# プロジェクトディレクトリに移動
cd "$PROJECT_DIR" || {
    echo "エラー: プロジェクトディレクトリに移動できませんでした: $PROJECT_DIR"
    exit 1
}

# エンドポイントリスト（Tokyo / Osaka のみ）
ENDPOINTS=("Tokyo" "Osaka")

# ランダムに1つ選択
SELECTED_ENDPOINT=${ENDPOINTS[$RANDOM % ${#ENDPOINTS[@]}]}

echo "========================================="
echo "NordVPN エンドポイントをランダム選択中..."
echo "選択されたエンドポイント: $SELECTED_ENDPOINT"
echo "プロジェクトディレクトリ: $PROJECT_DIR"
echo "========================================="

# .envファイルのパス
ENV_FILE="$PROJECT_DIR/.env"

# .envファイルが存在しない場合は作成
if [ ! -f "$ENV_FILE" ]; then
    echo ".envファイルが見つかりません。新規作成します。"
    touch "$ENV_FILE"
fi

# .envファイルのバックアップを作成
cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# NORDVPN_ENDPOINTの行を更新または追加
if grep -q "^NORDVPN_ENDPOINT=" "$ENV_FILE"; then
    # 既存の行を更新
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS用
        sed -i '' "s|^NORDVPN_ENDPOINT=.*|NORDVPN_ENDPOINT=$SELECTED_ENDPOINT|" "$ENV_FILE"
    else
        # Linux用
        sed -i "s|^NORDVPN_ENDPOINT=.*|NORDVPN_ENDPOINT=$SELECTED_ENDPOINT|" "$ENV_FILE"
    fi
    echo ".envファイルのNORDVPN_ENDPOINTを更新しました。"
else
    # 行が存在しない場合は追加
    echo "NORDVPN_ENDPOINT=$SELECTED_ENDPOINT" >> "$ENV_FILE"
    echo ".envファイルにNORDVPN_ENDPOINTを追加しました。"
fi

# 更新された内容を確認
echo ""
echo "更新後のNORDVPN_ENDPOINT設定:"
grep "^NORDVPN_ENDPOINT=" "$ENV_FILE" || echo "設定が見つかりませんでした。"

# NordVPNコンテナを再起動
echo ""
echo "NordVPNコンテナを再起動しています..."
cd "$PROJECT_DIR" && docker compose up -d nordvpn

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ コンテナの再起動が完了しました。"
    echo ""
    echo "接続状態を確認するには:"
    echo "  docker compose exec nordvpn nordvpn status"
    echo ""
    echo "ログを確認するには:"
    echo "  docker compose logs nordvpn --tail 50"
else
    echo ""
    echo "✗ コンテナの再起動に失敗しました。"
    exit 1
fi

