# 実装の委譲（cursor-agent）

cursor-agent（grok）へ実装を出すときは、wrapper の subagent（`cursor-agent` エージェント）を挟まない。
CLI を Bash の `run_in_background` で直接走らせ、完了の通知を自分で受けて検証する。
wrapper の subagent は、裏で走らせた CLI の完了通知を取りこぼして止まることがある。

```bash
agent -p "$(cat prompt.txt)" --model cursor-grok-4.6-xhigh --force --trust --output-format json > run.json 2> run.err
```

- 規約（共通）と課題ごとの指示書をファイルに書き、プロンプトではそのファイルを読ませる。指示書は `.agent/briefs/` のような git の対象外へ置く
- 指示書には、触ってよい範囲、先に書くテスト、報告の前に通すコマンドを書く。git の commit、push、reset は禁じる
- 戻ってきたら、報告を信用せずに同じコマンドを自分で流し、差分を読んでからコミットする
- 同時に複数を走らせるときは、触るディレクトリが重ならないように分ける。SwiftPM の `.build` を共有する作業は同時に走らせない
- モデルはユーザーの指定に固定し、レート制限でも別のモデルへ切り替えない
- 署名、キーチェーン、usbmuxd に触る実行は、サンドボックスの外で走らせる
