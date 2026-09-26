# ふたり日和 — 2人専用の思い出アプリ

GitHub Pages + Supabase で動く、スマホ向けの共有Webアプリです。

## 主な機能
- 2人それぞれログインして同じデータを共有
- 行きたい場所・したいことリスト
- 「できた！」管理、写真、思い出メモ
- 2人それぞれのひとこと感想
- 思い出タイムライン
- お気に入り思い出
- 記念日・次の記念日までのカウントダウン
- 行きたい場所 / 行った場所マップ
- 月・年ごとの振り返り
- 季節・未登録内容から「まだしたことなさそうなこと」をおすすめ
- おすすめからワンタップで「やりたいこと」に追加
- おすすめエリア設定

## 1. Supabase
1. Supabaseでプロジェクトを作成
2. SQL Editorで `supabase-setup.sql` を全部実行
   - 既存の旧共有版から更新する場合も再実行してください
3. Project URL と Publishable key を取得
4. `config.js` を編集

```js
window.APP_CONFIG = {
  SUPABASE_URL: "https://xxxxxxxx.supabase.co",
  SUPABASE_PUBLISHABLE_KEY: "sb_publishable_xxxxxxxx"
};
```

`service_role` は絶対にブラウザへ入れないでください。

## 2. GitHub Pages
公開先: `https://aoyan1982.github.io/couple/`

Supabase Authentication → URL Configuration で上記URLを Site URL / Redirect URLs に追加してください。

## 3. 2人で使う
1人目: 新規登録 → ページ作成 → 右上♡から招待コードをコピー
2人目: 新規登録 → 招待コードで参加

## マップについて
場所を保存した時に OpenStreetMap の Nominatim で場所名を検索し、緯度経度をDBへ保存します。
曖昧な場所名だと別の地点になる場合があるため、「渋谷スクランブルスクエア」のように具体的に入力してください。

## おすすめについて
おすすめはアプリ内の候補リストから、現在の月と、すでに登録・達成した内容を見て候補を変えます。
外部AI APIを使わないのでAPI料金はかかりません。
