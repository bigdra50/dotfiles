# dotfiles Architecture

## 全体構成

```mermaid
graph TB
    subgraph dotfiles["dotfiles repo"]
        root[".* (dotfiles)"]
        config[".config/"]
        claude[".claude/"]
        scripts["scripts/setup/"]
        mise["mise.toml"]
    end

    subgraph home["$HOME"]
        home_dots["~/.*"]
        home_config["~/.config/*"]
        home_claude["~/.claude/"]
    end

    root -->|symlink| home_dots
    config -->|symlink| home_config
    claude -->|symlink| home_claude
    mise -->|"mise run setup"| scripts
```

## Zsh 起動シーケンス

sheldon + zsh-defer による遅延ロードで起動を高速化している。

```mermaid
sequenceDiagram
    participant Shell as Zsh
    participant Env as .zshenv
    participant Core as env.zsh / func-core.zsh
    participant Prof as .zprofile
    participant RC as .zshrc
    participant UI as interface.zsh
    participant Ext as extensions.zsh

    Note over Shell: ~/.zshenv -> ZDOTDIR設定
    Shell->>Env: source $ZDOTDIR/.zshenv (全 zsh)
    Note over Env: XDG, FPATH, fzf
    Env->>Core: source env.zsh + func-core.zsh
    Note over Core: 正準PATH順序 (mise shims 静的prepend)<br/>GOPATH, CC_WORKLOG_DIR<br/>gh() アカウント自動選択

    alt login shell
        Note over Shell: /etc/zprofile (path_helper) が<br/>PATH を再構成し prepend を降格させる
        Shell->>Prof: source $ZDOTDIR/.zprofile
        Prof->>Core: env.zsh を再 source (正準順序を再主張)
    end

    alt interactive shell
        Shell->>RC: source $ZDOTDIR/.zshrc
        RC->>UI: source interface.zsh
        Note over UI: compinit (24h cache)<br/>atuin init<br/>starship init<br/>vi keybindings
        RC->>Ext: source extensions.zsh
        Note over Ext: sheldon source (下記参照)<br/>func/history/completion/alias<br/>plugins/*.zsh
        RC->>RC: source .zshrc_local
        Note over RC: マシン固有設定
    end

    Note over Shell: 非対話シェルは .zshenv (+login なら .zprofile) のみ。<br/>PATH/env/常時関数を env.zsh 側に置くのはこのため
```

## sheldon プラグインの遅延ロード

```mermaid
graph LR
    subgraph immediate["即時ロード"]
        fzf_tab["fzf-tab"]
    end

    subgraph deferred["zsh-defer (遅延)"]
        auto["zsh-autosuggestions"]
        syntax["fast-syntax-highlighting"]
        color["zsh-256color"]
        abbr["zsh-abbr"]
    end

    sheldon["sheldon source"] --> immediate
    sheldon --> deferred

    style immediate fill:#4a9,color:#fff
    style deferred fill:#69c,color:#fff
```

## Neovim 起動フロー

```mermaid
graph TD
    init["init.lua"] --> vimrc["~/.vimrc (互換)"]
    init --> base["base.lua<br/>Leader=Space, 基本設定"]
    init --> lazy["config/lazy.lua"]

    lazy --> ui["plugins/ui.lua"]
    lazy --> lsp["plugins/lsp.lua"]
    lazy --> editor["plugins/editor.lua"]
    lazy --> ai["plugins/ai.lua"]
    lazy --> go["plugins/go.lua"]
    lazy --> haskell["plugins/haskell.lua"]

    subgraph disabled_builtin["無効化された組み込みプラグイン"]
        netrw["netrwPlugin"]
        gzip["gzip"]
        matchit["matchit"]
        tar["tarPlugin"]
        zip["zipPlugin"]
        tutor["tutor"]
    end

    lazy -.->|disabled| disabled_builtin

    style disabled_builtin fill:#933,color:#fff
```

## Neovim プラグイン遅延ロード戦略

lazy.nvim のイベント/コマンド/キー/ファイルタイプによる遅延ロード。

```mermaid
graph TB
    subgraph startup["起動時 (lazy=false)"]
        gruvbox["gruvbox-material<br/>priority=1000"]
        snacks["snacks.nvim<br/>priority=1000"]
        session["auto-session"]
    end

    subgraph very_lazy["VeryLazy イベント"]
        lualine["lualine.nvim"]
        wintabs["vim-wintabs"]
        surround["nvim-surround"]
    end

    subgraph buf_read["BufReadPost / BufNewFile"]
        treesitter["nvim-treesitter"]
        mason_lsp["mason-lspconfig"]
        gitsigns["gitsigns.nvim"]
    end

    subgraph insert["InsertEnter"]
        cmp["nvim-cmp + sources"]
        luasnip["LuaSnip"]
        autopairs["nvim-autopairs"]
        autotag["nvim-ts-autotag"]
    end

    subgraph cmd_key["コマンド / キー"]
        telescope["telescope.nvim<br/>cmd: Telescope<br/>keys: leader+f*"]
        oil["oil.nvim<br/>cmd: Oil<br/>keys: -"]
        trouble["trouble.nvim<br/>cmd: Trouble"]
        dap["nvim-dap<br/>keys: F5,F10..."]
        fugitive["vim-fugitive<br/>cmd: Git,Gdiff..."]
    end

    subgraph ft["ファイルタイプ"]
        roslyn["roslyn.nvim<br/>ft: cs, razor"]
        xcode["xcodebuild.nvim<br/>ft: swift"]
        colorizer["nvim-colorizer<br/>ft: css,html,js..."]
        pug["vim-pug<br/>ft: pug"]
        mdpreview["markdown-preview<br/>ft: markdown"]
    end

    subgraph lsp_attach["LspAttach イベント"]
        lspsaga["lspsaga.nvim"]
        fidget["fidget.nvim"]
    end

    style startup fill:#d84,color:#fff
    style very_lazy fill:#4a9,color:#fff
    style buf_read fill:#69c,color:#fff
    style insert fill:#96c,color:#fff
    style cmd_key fill:#c93,color:#fff
    style ft fill:#9c6,color:#fff
    style lsp_attach fill:#c69,color:#fff
```

## LSP 構成

```mermaid
graph LR
    mason["Mason"] -->|auto install| tools

    subgraph tools["LSPサーバー"]
        gopls
        pyright
        bash_ls["bash-ls"]
        sourcekit
    end

    subgraph custom["カスタムLSP"]
        roslyn["roslyn.nvim<br/>(C#/Razor)"]
        upm["upm-lsp<br/>(Unity manifest)"]
    end

    subgraph format["Formatter (conform.nvim)"]
        go_fmt["Go: goimports + gofmt"]
        py_fmt["Python: ruff"]
        cs_fmt["C#: csharpier"]
        swift_fmt["Swift: swiftformat"]
        lua_fmt["Lua: stylua"]
        web_fmt["Web: prettier"]
    end

    subgraph lint["Linter (nvim-lint)"]
        jsonlint
        swiftlint
    end

    tools --> buf["Buffer"]
    custom --> buf
    buf -->|BufWritePre| format
    buf -->|BufWritePost| lint
```

## ツール管理レイヤー

```mermaid
graph TD
    mise["mise (orchestrator)"] -->|"activate --shims"| shims["~/.local/share/mise/shims/"]
    mise -->|"run setup:*"| setup["scripts/setup/*.sh"]

    subgraph managed["mise管理ツール"]
        direction LR
        runtime["ランタイム<br/>node, go, python..."]
        cli["CLI<br/>fd, rg, bat, starship..."]
    end

    mise --> managed

    subgraph brew_only["brew管理 (許可リスト)"]
        python_dep["python (依存)"]
        ruby_dep["ruby (依存)"]
    end

```

## リファレンスハブ

詳細は [reference.md](reference.md)。1つの列駆動レンダラ（`scripts/reference/common/`）を4ドメインで共有する。

```mermaid
flowchart LR
    subgraph sources["設定ソース"]
        kb[".wezterm.lua / .config/zsh<br/>.skhdrc / .config/nvim"]
        sc[".config/zsh<br/>(alias/abbr/func)"]
        tk["mise tasks --json"]
        cl[".claude/"]
    end

    kb --> ekb["extract.sh<br/>(keybindings)"]
    sc --> esc["extract_shortcuts.py"]
    tk --> etk["extract_tasks.py"]
    cl --> ecl["extract_claude.py"]

    ekb & esc & etk & ecl --> render["common 列駆動レンダラ<br/>(page.py / PageConfig)"]
    render --> pages["GitHub Pages<br/>hub + /<domain>/"]
    render --> fzf["mise run keys<br/>(fzf検索)"]
```
