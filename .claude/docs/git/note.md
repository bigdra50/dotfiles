# Git Notes ガイド

## git notes の用途と特徴

### 基本概念

**git notes** は既存のコミットに対して、**コミットハッシュを変更せずに**追加情報を後から付加する機能です。

### 主な特徴

- **非破壊的**: コミット履歴を変更しない
- **後付け可能**: コミット後に情報追加
- **分離管理**: コミット本体と独立して管理
- **複数名前空間**: 用途別にノート分類可能

## 用途別ガイド

### 1. レビュー・品質管理

```bash
# コードレビュー結果を記録
git notes add -m "Code Review: Approved by @senior-dev
- Security review passed
- Performance impact: minimal
- Memory usage optimized"

# 品質チェック結果
git notes add -m "Quality Gate:
- Code coverage: 85%
- SonarQube: Grade A
- Security scan: No issues"
```

### 2. CI/CD・デプロイ履歴

```bash
# ビルド結果
git notes add -m "Build #1234:
- All tests passed (247/247)
- Build time: 3m 42s
- Artifacts uploaded to S3"

# デプロイ情報
git notes add -m "Production Deployment:
- Deployed: 2024-01-15 14:30 JST
- Environment: production-tokyo
- Status: Success
- Rollback plan: deploy-rollback-v1.2.3.sh"
```

### 3. パフォーマンス・運用情報

```bash
# パフォーマンス測定
git notes add -m "Performance Impact:
- Response time: 150ms → 80ms (47% improvement)
- Memory usage: -15MB
- CPU utilization: -12%
- Load test: 1000 concurrent users OK"

# 運用インシデント記録
git notes add -m "Production Incident:
- Issue: Memory leak detected
- Impact: 20% performance degradation
- Resolution: Hotfix deployed (commit abc123)
- Monitoring: Alert threshold adjusted"
```

### 4. 外部システム連携

```bash
# チケット・PR関連
git notes add -m "Related Links:
- JIRA: PROJ-1234
- GitHub PR: #567
- Confluence: feature-spec-doc-123
- Slack thread: #dev-channel/p1642123456"

# A/Bテスト結果
git notes add -m "A/B Test Results:
- Variant: login-button-color-blue
- Conversion: +15% vs control
- Statistical significance: 99.5%
- Recommendation: Apply to all users"
```

## What / How / Results フレームワーク

### コミットメッセージとの情報分担

| 側面 | コミットメッセージ | git notes |
|------|------------------|-----------|
| **時期** | コミット時点で確定 | コミット後に判明 |
| **What** | 何を変更したか | 何が起こったか（結果） |
| **Why** | なぜ変更したか | なぜこの評価になったか |
| **How** | どう実装したか | どう運用されているか |

### コミットメッセージ（作成時確定）

**用途**: コミット時点で分かる情報
```bash
git commit -m ":sparkles: ユーザー認証にJWT機能を追加

- トークンベース認証を実装
- セキュリティ強化とスケーラビリティ向上
- 既存セッション認証との互換性保持"
```

**記録内容**:
- **What**: 何を変更したか
- **Why**: なぜ変更したか  
- **How**: どのように実装したか

### git notes（後から判明）

**用途**: コミット後に分かる情報
```bash
git notes add -m "Implementation Results:
- Security audit: Passed
- Performance: 25% faster login
- User feedback: 95% satisfaction
- Production issues: None in 30 days"
```

**記録内容**:
- **What happened**: 実際に何が起こったか
- **How it performs**: どのように動作しているか
- **Results**: 結果・成果・評価
- **Impact**: 実際の影響・効果

## git notesに記録すべき情報の詳細ガイド

### 1. 開発プロセス結果

#### レビュー・品質評価
```bash
# ✅ 記録すべき内容
git notes add -m "Code Review Results:
Reviewer: @senior-dev, @security-team
Security: ✅ No vulnerabilities found
Performance: ✅ Memory usage within limits
Code Quality: ✅ SonarQube Grade A
Approval: ✅ Approved with minor suggestions"

# ❌ 記録すべきでない内容
git notes add -m "レビューで褒められた"  # 主観的
git notes add -m "なんか問題ないらしい"  # 曖昧
```

#### CI/CD・テスト結果
```bash
# ✅ 具体的な結果
git notes add -m "CI/CD Results:
Build #1234: ✅ Success (3m 42s)
Unit Tests: ✅ 247/247 passed (coverage: 89%)
Integration Tests: ✅ 34/34 passed
Security Scan: ✅ No issues detected
Deployment: ✅ Staging successful"

# ❌ 曖昧な記録
git notes add -m "テスト全部通った"  # 詳細不明
```

### 2. 運用・本番環境での実績

#### パフォーマンス実測値
```bash
# ✅ 定量的データ
git notes add -m "Performance Metrics (30-day avg):
Response Time: 150ms → 95ms (-37%)
Throughput: +25% (1200 → 1500 req/min)
CPU Usage: -15% (avg 60% → 51%)
Memory: Stable (no leaks detected)
Error Rate: 0.02% (target: <0.1%)"

# ❌ 感覚的評価
git notes add -m "速くなった気がする"  # 主観的
```

#### インシデント・運用情報
```bash
# ✅ 構造化された記録
git notes add -m "Production Incident:
Date: 2024-01-15 14:30 JST
Issue: High memory usage detected
Root Cause: JWT cache not configured properly
Impact: 15% performance degradation (5 minutes)
Resolution: Config adjustment deployed
Prevention: Monitoring alert threshold lowered
Related: INC-2024-001"
```

### 3. 外部システム・ビジネス指標

#### ユーザー・ビジネス影響
```bash
# ✅ 客観的指標
git notes add -m "Business Impact (Week 1):
User Satisfaction: 8.9/10 (survey: 150 responses)
Conversion Rate: +12% (login → purchase)
Support Tickets: -30% (auth-related issues)
MAU Retention: +5.2%
A/B Test: Statistical significance achieved (p<0.01)"

# ❌ 推測・印象
git notes add -m "ユーザーが喜んでる"  # 根拠不明
```

#### 外部システム連携
```bash
# ✅ 連携記録
git notes add -m "External Integration:
JIRA: PROJ-1234 ✅ Resolved
Slack: Deployment notification sent
Monitoring: DataDog alert rules updated
Documentation: Confluence page updated
Release Notes: v1.2.0 published"
```

### 4. 長期的評価・改善提案

#### 技術的評価
```bash
git notes add -m "6-Month Retrospective:
Technical Debt: Reduced (complexity score: 7.2 → 5.8)
Maintainability: Improved (dev velocity +20%)
Security: No vulnerabilities reported
Scalability: Handles 3x traffic without issues
Recommendation: Consider OAuth 2.0 migration for v2"
```

### 記録タイミングと責任

#### 段階的記録フロー
```bash
# 1. レビュー完了時（レビュワー）
git notes add -m "Code Review: Approved by @lead-dev
Security check passed, performance impact minimal"

# 2. デプロイ完了時（DevOps）
git notes add -m "Deployment: Production successful
No rollback required, monitoring all green"

# 3. 1週間後（開発者）
git notes add -m "Week 1 Results: Performance improved 25%
No user complaints, error rate within SLA"

# 4. 1ヶ月後（プロダクトオーナー）
git notes add -m "Month 1 Impact: Conversion up 15%
User satisfaction high, business goals met"
```

### 名前空間による分類

```bash
# 開発プロセス
git notes --ref=review add -m "レビュー結果"
git notes --ref=test add -m "テスト結果"
git notes --ref=deploy add -m "デプロイ情報"

# 運用・ビジネス
git notes --ref=performance add -m "パフォーマンス実測"
git notes --ref=incident add -m "インシデント記録"
git notes --ref=business add -m "ビジネス指標"

# 表示時の名前空間指定
git log --notes=review    # レビュー結果のみ
git log --notes=incident  # インシデント記録のみ
```

### 記録品質のガイドライン

#### ✅ 良い記録の特徴
- **定量的**: 数値・メトリクスベース
- **客観的**: 事実に基づく記録
- **構造化**: 一貫したフォーマット
- **追跡可能**: 関連情報へのリンク
- **アクション指向**: 次のステップが明確

#### ❌ 避けるべき記録
- **主観的**: 個人の感想・印象
- **曖昧**: 具体性に欠ける表現
- **感情的**: 批判的・否定的な内容
- **機密**: 秘匿性の高い情報
- **重複**: 既存情報の再記載

## GitHub PR・Issue との使い分け

| 項目 | GitHub PR | git notes | GitHub Issue |
|------|-----------|-----------|--------------|
| **スコープ** | 機能レベル | コミットレベル | タスク・バグレベル |
| **期間** | 開発期間中 | 長期間 | 課題解決まで |
| **対象者** | 開発チーム | 運用・開発者 | ステークホルダー |
| **情報種類** | 設計・レビュー | 結果・履歴 | 要求・課題 |

### 実践的な使い分け例

```bash
# Issue #123: ログイン速度改善要求
# ↓
# PR #456: JWT認証実装（複数コミット含む）
#   ├── commit abc123: JWT基盤実装
#   ├── commit def456: ログイン画面更新  
#   └── commit ghi789: テスト追加

# PR マージ後の git notes
git notes add abc123 -m "JWT Implementation Results:
- Security review: Approved
- Performance: Login time 200ms → 85ms
- Memory impact: +5MB (acceptable)"

git notes add def456 -m "UI Update Feedback:
- User testing: 9.2/10 satisfaction
- A/B test: 18% higher conversion
- Accessibility: WCAG 2.1 AA compliant"
```

## 基本コマンド

### ノート作成・編集

```bash
# 現在のコミットにノート追加
git notes add -m "メッセージ"

# 特定のコミットにノート追加
git notes add <commit-hash> -m "メッセージ"

# エディタでノート編集
git notes edit

# 既存ノート上書き
git notes add --force -m "新しいメッセージ"
```

### ノート表示

```bash
# 現在のコミットのノート表示
git notes show

# 特定のコミットのノート表示
git notes show <commit-hash>

# ログと一緒にノート表示
git log --show-notes

# ノート一覧表示
git notes list
```

### ノート管理

```bash
# ノート削除
git notes remove

# 特定コミットのノート削除
git notes remove <commit-hash>

# リモートからノート取得
git fetch origin refs/notes/*:refs/notes/*

# リモートにノートプッシュ
git push origin refs/notes/*
```

### 名前空間の使用

```bash
# 特定の名前空間でノート作成
git notes --ref=review add -m "レビュー結果"
git notes --ref=deploy add -m "デプロイ情報"

# 名前空間別表示
git log --notes=review
git log --notes=deploy
```

## 運用ベストプラクティス

### 1. ノート分類戦略

```bash
# 名前空間による分類
refs/notes/review    # コードレビュー結果
refs/notes/deploy    # デプロイ・運用情報  
refs/notes/perf      # パフォーマンス測定
refs/notes/incident  # インシデント記録
```

### 2. チーム運用ルール

**ノート作成ルール**:
- 重要な結果は必ずノート記録
- 24時間以内にレビュー結果を記録
- デプロイ後は運用状況を週次更新
- インシデント発生時は即座に記録

**ノート形式統一**:
```bash
# テンプレート化
git notes add -m "$(cat <<'EOF'
Review Result: [APPROVED/REJECTED]
Reviewer: @username
Date: $(date)
Comments:
- Point 1
- Point 2
Security: [OK/CONCERN/ISSUE]
Performance: [OK/DEGRADED/IMPROVED]
EOF
)"
```

### 3. 自動化との連携

```bash
# CI/CDパイプラインでの自動ノート追加
#!/bin/bash
if [ "$CI_BUILD_STATUS" = "success" ]; then
    git notes add -m "CI Build: SUCCESS
Build ID: $CI_BUILD_ID
Duration: $CI_BUILD_DURATION
Tests: $CI_TEST_COUNT passed"
fi
```

### 4. 長期保守での活用

```bash
# 1年後の振り返り時
git log --since="1 year ago" --show-notes=deploy
git notes show <old-commit> # 過去の判断理由確認
```

## 注意事項・制限

### 技術的制限
- **同期必要**: リモートとの手動同期が必要
- **衝突可能性**: 複数人での同一ノート編集時
- **ツール対応**: 一部のGitツールで表示されない場合

### 運用面の注意
- **プライバシー**: 機密情報の記録避ける
- **ライフサイクル**: ノートの削除・アーカイブ戦略
- **アクセス制御**: リポジトリアクセス権に依存

### おすすめしない使用例
```bash
# ❌ 避ける: 機密情報
git notes add -m "API Key: abc123..."

# ❌ 避ける: 過度に詳細な技術情報
git notes add -m "デバッグ情報: stack trace 500行..."

# ❌ 避ける: 主観的・感情的コメント  
git notes add -m "このコード最悪、書いた人センスない"
```

## 関連リンク

- [Git Notes Official Documentation](https://git-scm.com/docs/git-notes)
- [Pro Git Book - Git Notes](https://git-scm.com/book/en/v2/Git-Tools-Notes)
- [Git Notes Best Practices](https://github.com/git/git/blob/master/Documentation/user-manual.txt)