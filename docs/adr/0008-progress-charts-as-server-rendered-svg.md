*English / [日本語](#日本語)*

# 0008. Progress charts are server-rendered SVG, and chart the estimated 1RM

**Status:** Accepted

## Context

Lifters want to see their lifts and bodyweight change over time. Two
obvious choices were on the table, and both were rejected.

The obvious way to draw a chart is a JavaScript charting library. That
brings a dependency for two kinds of line chart, draws nothing until the
script runs, and leaves accessibility to the library: most render to a
`<canvas>`, which assistive technology can't read at all.

The obvious thing to chart is the stored score, since every lift already
has one (see 0006). But a DOTS or Sinclair score moves with bodyweight. A
lifter cutting from 90 kg to 80 kg would see their squat "improve" without
lifting any more, and a lifter bulking would see it fall.

## Decision

Charts are inline SVG built on the server. `LineChart` works out the
geometry (scales, gridlines at round values, the path), and
`ChartsHelper#line_chart` draws it with the palette's CSS tokens. There
is no JavaScript.

Barbell lifts chart the **estimated one-rep max** (Epley, as the scoring
already uses), the best set of each day, in the lifter's unit.
Calisthenics has no weight to estimate from, so it charts its score,
bodyweight-equivalent reps. Bodyweight charts the last weigh-in of each
day. Only approved lifts count, so a chart never disagrees with the rank
beside it.

The charts are private, on `/progress`. The public profile promises to
show best lifts and never bodyweight, so neither the history nor the
bodyweight chart appears there.

## Consequences

**What this buys.** The charts render with JavaScript off, cost no
dependency, and meet WCAG 2.0 1.1.1: each
SVG is `role="img"` with a `<title>` and a `<desc>` that states the range
in words, and the table it was drawn from is one click away in a
`<details>`. Dates and numbers are localized by the same helpers as the
rest of the app.

**What it costs.** No hover crosshair or zooming: each point has a native
tooltip, and the table carries the detail. Scaling and tick logic that a
library would provide is ours to maintain, which is why `LineChart` is
kept free of HTML and has its own unit specs.

---

<a id="日本語"></a>

# 0008. 推移グラフはサーバー側で SVG として描き、推定1RMを表示する

**状態:** 採用

## 背景

リフターは、記録と体重が時間とともにどう変わったかを見たいものです。
自明に見える選択肢が2つありましたが、どちらも退けました。

グラフを描く自明な方法は JavaScript のグラフライブラリです。しかし2種類の
折れ線グラフのために依存関係が増え、スクリプトが動くまで何も表示されず、
アクセシビリティもライブラリ任せになります。多くは `<canvas>` に描画する
ため、支援技術からはまったく読み取れません。

表示する値として自明なのは、保存済みのスコアです（0006 参照）。しかし DOTS
やシンクレアのスコアは体重とともに動きます。90 kg から 80 kg に減量した
リフターは、挙げた重量が同じでもスクワットが「伸びた」ように見え、増量中
なら下がったように見えてしまいます。

## 決定

グラフはサーバー側で組み立てるインライン SVG とします。`LineChart` が
座標（スケール、きりのよい値の目盛り線、折れ線）を計算し、
`ChartsHelper#line_chart` がパレットの CSS トークンを使って描画します。
JavaScript は使いません。

バーベル種目は、各日のベストセットを**推定1RM**（スコア計算と同じ Epley
式）に換算し、利用者の単位で表示します。自重種目には推定の元になる重量が
ないため、スコアである自重換算の回数を表示します。体重は各日の最後の計量値
を表示します。承認済みの記録だけを対象とするため、グラフが隣のランクと
食い違うことはありません。

グラフは本人だけが見られる `/progress` に置きます。公開プロフィールは
ベスト記録のみを表示し、体重は表示しないと約束しているため、履歴も体重の
グラフもそこには載せません。

## 影響

**得られるもの。** JavaScript が無効でも表示され、依存関係も増えず、WCAG
2.0 の 1.1.1 を満たせます。各 SVG は `role="img"` を持ち、`<title>` と、
値の範囲を文章で説明する `<desc>` を備え、描画元の表は `<details>` を開けば
すぐに見られます。日付と数値は、アプリのほかの部分と同じヘルパーで
ローカライズされます。

**代償。** ホバー時の十字線やズームはありません。各点にはブラウザ標準の
ツールチップがあり、詳細は表が担います。ライブラリなら用意されている
スケールや目盛りの計算を自前で保守する必要があるため、`LineChart` は HTML
から切り離し、専用のユニットテストを持たせています。
