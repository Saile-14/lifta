*English / [日本語](#日本語)*

# Architecture decision records

Short records of the decisions that shaped Lifta: what was chosen, what
else was considered, and what it costs. They exist so the reasoning
survives after the reasoning is forgotten — a reader shouldn't have to
reverse-engineer *why* SQLite, or why bodyweight is a log.

Each record keeps its English and Japanese text in one file, so the two
can't drift apart the way parallel directories do.

| # | Decision | Status |
|---|---|---|
| [0001](0001-sqlite-over-postgresql.md) | SQLite instead of PostgreSQL | Accepted |
| [0002](0002-built-in-authentication.md) | Rails' built-in authentication instead of Devise | Accepted |
| [0003](0003-bodyweight-as-a-log.md) | Bodyweight is a log, not a profile field | Accepted |
| [0004](0004-accessibility-target.md) | Target WCAG 2.0 AA, the standard JIS X 8341-3 adopts | Accepted |
| [0005](0005-bilingual-from-the-start.md) | Bilingual from the first commit, enforced by a test | Accepted |
| [0006](0006-formula-based-scoring.md) | Scores are computed and stored; tiers are not | Accepted |
| [0007](0007-combined-rank-rewards-breadth.md) | The combined rank rewards breadth, not peak strength | Accepted |

A record is written when a decision is hard to reverse, or when the
obvious choice was rejected. Small reversible choices stay in code
comments, where they're closer to what they explain.

New records are added, never edited: if a decision is replaced, the old
record is marked superseded and points at the new one.

---

<a id="日本語"></a>

# アーキテクチャ決定記録（ADR）

Lifta の設計を形づくった決定の記録です。何を選び、ほかに何を検討し、その
代償が何かを短くまとめています。目的は、判断の理由が忘れられたあとも理由
そのものを残すことです。「なぜ SQLite なのか」「なぜ体重をログとして持つ
のか」を、読む人がコードから推測せずに済むようにします。

各記録は英語と日本語を同じファイルに収めています。ディレクトリを分けると
内容がずれていくためです。

| # | 決定 | 状態 |
|---|---|---|
| [0001](0001-sqlite-over-postgresql.md) | PostgreSQL ではなく SQLite を使う | 採用 |
| [0002](0002-built-in-authentication.md) | Devise ではなく Rails 標準の認証を使う | 採用 |
| [0003](0003-bodyweight-as-a-log.md) | 体重はプロフィール項目ではなくログとして持つ | 採用 |
| [0004](0004-accessibility-target.md) | JIS X 8341-3 が採用する WCAG 2.0 AA を目標とする | 採用 |
| [0005](0005-bilingual-from-the-start.md) | 最初から2言語対応とし、テストで担保する | 採用 |
| [0006](0006-formula-based-scoring.md) | スコアは計算して保存し、ティアは保存しない | 採用 |
| [0007](0007-combined-rank-rewards-breadth.md) | 総合力ランクは突出した強さではなく幅広さを評価する | 採用 |

記録を書くのは、決定を覆すのが難しい場合か、自明に見える選択肢をあえて
退けた場合です。小さく元に戻せる判断は、説明する対象に近いコード内の
コメントに残します。

記録は追加するもので、書き換えません。決定が置き換わったときは、古い記録
を「廃止」と記し、新しい記録へのリンクを添えます。
