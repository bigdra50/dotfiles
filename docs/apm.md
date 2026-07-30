# apm — エージェント資産の配布

skills と agents を apm (Microsoft Agent Package Manager) で管理し、claude / codex / copilot / cursor へまとめて展開する。

rules は apm のクロスツール配布が部分対応のため対象外。
`scripts/sync-rules.sh` が担当する。

## 正本と配置先

```
  .apm/apm.yml            正本。編集するのはここだけ
      |
      | symlink
      v
  ~/.apm/apm.yml          apm が読む場所
      |
      | apm install -g
      +--> ~/.claude/skills/    Claude Code が直接読む
      +--> ~/.agents/skills/    agentskills.io 標準の共通置き場
```

`targets` に codex / copilot / cursor を並べているが、apm は各ツール固有の skills ディレクトリ (`~/.codex/skills` など) には書かない。
共通置き場へ出すだけなので、そこを読むかどうかは各ツール次第。
cursor は agents を無視することが分かっている。

symlink にしてあるのは、apm 側の変更が dotfiles へ戻るようにするため。
copy にすると `~/.apm` にだけ依存が増える片道の drift が起き、`git diff` に出ないので気づけない。

## 日常操作

依存の追加と削除は正本を編集して反映する。

```bash
vim .apm/apm.yml
mise run setup:claude
```

`apm install -g` を直接叩いてもよい。
`setup:claude` はそれに加えて agents のミラーと symlink の検証を行う。

## コマンド

| コマンド | 用途 |
|---|---|
| `apm install -g` | apm.yml のとおりに配置する。manifest も ref も書き換えない |
| `apm install -g --frozen` | lockfile に固定して配置する。drift で fail。他マシンでの再現向け |
| `apm update -g --dry-run` | 更新 plan を読むだけ。書き込みもプロンプトも無い |
| `apm update -g` | plan を見て y/N で答える。既定は N |
| `apm update -g <pkg>...` | 指定した依存だけ更新する |
| `apm outdated -g` | 更新可能な依存を一覧する |
| `apm prune` | apm.yml に無いパッケージを削除する。`~/.apm` で実行する |
| `apm audit` | 配置物に不可視文字が混入していないか検査する |

### `apm update -g --yes` は使わない

`apm update` は `#sha` pin を「最新の annotated tag が指す commit」へ書き換える。
上流がタグを打つたびにレビューする Dependabot 方式の設計で、既定 No のプロンプトが書き換え内容を見せる。
`--yes` はその関門を潰す唯一の方法になっている。

タグが default branch より遅れている上流では、更新が巻き戻しになる。
実際に mattpocock/skills で 42 コミット分の巻き戻しが起きた。

## pin の方針

| 対象 | pin | 理由 |
|---|---|---|
| 自分のリポジトリ | 無し | main 追従。自分で壊さない限り安全 |
| 他人のリポジトリ | `#<sha>` | 上流の変更を制御できない |

pin した依存は `apm update` に任せられない。
上流の default branch を直接見て、pin を手で書き換える。

## トラブルシュート

### push したのに古い内容が配置される

lockfile が古い commit を指している。
`apm install` は ref を更新しないので、install を繰り返しても変わらない。

```bash
apm update -g --dry-run   # plan を確認する
apm update -g             # y/N に答える
```

### ~/.apm/apm.yml が symlink でなくなった

`apm update` は manifest を atomic write するため、symlink を実ファイルに置換する。
`apm install` 系は symlink を辿って書くのでこれは起きない。

`mise run setup:claude` が検出して再リンクする。
内容が正本と違えば `~/.apm/apm.yml.detached.<timestamp>` へ退避する。

**退避ファイルは捨てる前に diff する。** pin が書き換わっている可能性がある。

### スキルが勝手に消えた

apm.yml から外れた依存の配置ファイルは、次の install で削除される。
管理外で残したいものは `~/.claude/skills/` へ直接置く。
apm は "local files not managed by APM" として触らない。

### private repo が 404 になる

apm は gh の active アカウントの token を使う。
`gh()` ラッパーの CWD ベース切り替えは subprocess に効かないので、実行時に別アカウントが active だと private repo が見えない。

```bash
GITHUB_APM_PAT_<OWNER>=<token> apm install -g
```

### `apm outdated -g` が同じ依存を常に outdated と言う

pin した commit がタグより新しいときに起きる。
タグと比較しているだけなので誤報告。無視してよい。

## 参考

- [apm docs](https://microsoft.github.io/apm/) — 依存管理、pin、lockfile の仕様
- [bigdra50/skills](https://github.com/bigdra50/skills) — 自作 skills の配布元
