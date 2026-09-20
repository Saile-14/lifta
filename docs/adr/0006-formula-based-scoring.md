*English / [日本語](#日本語)*

# 0006. Scores are computed and stored; tiers are not

**Status:** Accepted

## Context

A lift has to become a rank. There are two separable steps: turning the
lift into a comparable number (DOTS points, Sinclair points,
bodyweight-equivalent reps), and turning that number into a tier
(bronze … grandmaster) by comparing it to a world-class standard.

The two have very different stability. The formulas are published and
change rarely — the Sinclair coefficients change once per Olympic cycle.
The standards are a judgement call: the ceilings in `CEILINGS` and the
rep ladders in `THRESHOLDS` are rough calibrations that should be tuned
as real data arrives.

A third option existed: seed a table of strength standards and look ranks
up. That is how many strength sites work.

## Decision

Compute the score with the formula and **store it** on the lift
(`lifts.score`). Derive the tier from that score at read time and **do
not store it**.

No reference table of strength standards is seeded. The calibration lives
in code, in `app/models/discipline`.

## Consequences

**What this buys.** Tuning a ceiling is a code change with no migration
and no backfill — every tier recomputes on the next page load, because
tiers were never persisted. That matters when the numbers are admittedly
rough and expected to move.

Storing the score keeps the leaderboard a plain aggregate query. Ranking
every lifter is `MAX(score) GROUP BY user_id, exercise`, not formula
evaluation in Ruby across thousands of rows.

**What it costs.** A stored score can go stale. If a *formula* changes,
rather than a ceiling, the stored values are wrong until recomputed,
which is why `bin/rails lifts:rescore` exists. That task is the one thing
a reader has to know about; without it, the correctness of this design
depends on remembering to run it.

`rescore` also saves with `validate: false`, which is a deliberate bypass
of the model layer and part of why the database now carries its own
constraints.

**Where the boundary sits.** Scores are facts about a lift and are
stored. Tiers are opinions about a score and are not. When adding
something new, ask which it is.

---

<a id="日本語"></a>

# 0006. スコアは計算して保存し、ティアは保存しない

**状態:** 採用

## 背景

挙上記録をランクに変換する必要があります。これは分離できる2つの段階から
なります。記録を比較可能な数値にする段階（DOTS ポイント、シンクレア
ポイント、自重換算の回数）と、その数値を世界トップレベルの基準と比べて
ティア（ブロンズ〜グランドマスター）にする段階です。

この2つは安定性がまったく違います。計算式は公表されていて、めったに変わり
ません。シンクレア係数はオリンピックのサイクルごとに一度改定される程度
です。一方、基準値は判断の産物です。`CEILINGS` の上限値や `THRESHOLDS` の
回数ラダーは概算のキャリブレーションであり、実データが集まるにつれて調整
すべきものです。

第3の選択肢もありました。筋力基準の一覧をテーブルとして投入し、ランクを
参照する方式です。多くの筋力系サイトはこの作りになっています。

## 決定

計算式でスコアを求め、記録に**保存します**（`lifts.score`）。ティアは
読み取り時にそのスコアから導出し、**保存しません**。

筋力基準の参照テーブルは用意しません。キャリブレーションはコード側、
`app/models/discipline` に置きます。

## 影響

**得られるもの。** 上限値の調整がコードの変更だけで済み、マイグレーション
もデータの書き戻しも不要です。ティアは保存されていないので、次のページ表示
時にすべて再計算されます。数値が概算であり、今後動かすことが前提である以上、
これは重要です。

スコアを保存しておくことで、リーダーボードは素朴な集計クエリのままで済み
ます。全リフターの順位付けは `MAX(score) GROUP BY user_id, exercise` であり、
数千行に対して Ruby で計算式を評価することにはなりません。

**代償。** 保存したスコアは古くなりえます。上限値ではなく**計算式**が変わっ
た場合、再計算するまで保存値は誤ったままです。`bin/rails lifts:rescore` が
存在するのはそのためです。このタスクは、読む人が知っておく必要のある唯一の
ものです。これを実行し忘れれば、この設計の正しさは崩れます。

`rescore` は `validate: false` で保存します。これはモデル層を意図的に迂回
する操作であり、データベース側にも制約を持たせるようにした理由の一つです。

**境界の位置。** スコアは記録についての事実なので保存します。ティアは
スコアについての解釈なので保存しません。新しく何かを足すときは、どちらな
のかを問うてください。
