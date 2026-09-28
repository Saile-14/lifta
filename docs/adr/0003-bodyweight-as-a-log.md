*English / [日本語](#日本語)*

# 0003. Bodyweight is a log, not a profile field

**Status:** Accepted

## Context

Every score in Lifta depends on bodyweight. DOTS and Sinclair both divide
by a coefficient derived from it, and calisthenics uses it to convert
added weight into reps. A 150 kg squat is a different achievement at
70 kg than at 110 kg.

The simple modelling is a `bodyweight` column on `users`. It is also
wrong in a way that only shows up later: lifters' bodyweight changes, and
people backdate lifts. With a single column, cutting from 90 kg to 80 kg
silently rescores every lift you ever logged, and a lift entered a month
late is scored at today's weight rather than the weight you actually
lifted it at.

## Decision

Bodyweight is its own table, `bodyweight_entries`, a log of weigh-ins
over time. Each lift snapshots `bodyweight_kg` as of the lift's own date,
the way a meet records the weigh-in for that meet.

`User#bodyweight_on(date)` resolves the weight for a date: the most
recent weigh-in on or before it, falling back to the earliest one after
if the log doesn't reach back that far.

## Consequences

**What this buys.** Scores are stable. A lift logged in March stays worth
what it was worth in March, whatever the lifter weighs in September. A
backdated lift is scored correctly, because the snapshot is taken for its
own date and not for today. Lifters get a bodyweight history for free,
which is worth having on its own.

**What it costs.** More moving parts: a second table, an extra lookup on
every lift save, and a `before_validation` ordering dependency — the
bodyweight snapshot has to be resolved before the score is computed.
There is also a bootstrapping case to handle, a lifter logging their
first lift with no weigh-in yet, which is why the lift form accepts a
bodyweight directly and writes it to the log.

**A consequence worth stating.** Because the snapshot is stored per lift,
a change to the log has to be carried to the lifts it affects. When a
weigh-in is logged, corrected, moved or deleted, each lift whose date now
resolves to a different weight is re-snapshotted and rescored
(`User#resnapshot_bodyweight`). The common case is backfilling an older
weigh-in, which fixes lifts that had fallen back to a later one. Lifts the
change doesn't move keep their score, so logging today's weight still
leaves March alone. A bodyweight typed into a lift that differs from the
log is that lift's own and is kept. Emptying the log leaves every lift at
its last known weight.

*Amended:* this used to say corrections did not rescore past lifts. That
left lifts logged before the first weigh-in scored at the wrong weight
for good once an older one was backfilled.

---

<a id="日本語"></a>

# 0003. 体重はプロフィール項目ではなくログとして持つ

**状態:** 採用

## 背景

Lifta のスコアはすべて体重に依存します。DOTS もシンクレアも体重から導いた
係数で割りますし、自重種目では加重を回数に換算するために体重を使います。
150 kg のスクワットは、体重 70 kg と 110 kg とでは意味が違います。

素直なモデリングは `users` テーブルに `bodyweight` カラムを1つ置くこと
です。しかしこれは、あとになって初めて表面化する形で誤っています。体重は
変化しますし、過去の日付で記録を登録することもあるからです。カラムが1つ
だと、90 kg から 80 kg に減量した瞬間、過去に登録したすべての記録のスコア
が黙って書き換わります。1か月後に登録した記録も、実際に挙げた当時ではなく
今日の体重で採点されてしまいます。

## 決定

体重は `bodyweight_entries` という独立したテーブルに、時系列の計量ログと
して保存します。各記録は**その記録自身の日付時点の** `bodyweight_kg` を
スナップショットとして保持します。大会ごとに計量結果を残すのと同じ考え方
です。

`User#bodyweight_on(date)` がその日付の体重を解決します。その日以前で最も
新しい計量値を使い、ログがそこまで遡っていなければ、それ以降で最も古い値に
フォールバックします。

## 影響

**得られるもの。** スコアが安定します。3月に登録した記録は、9月にその人が
何キロであろうと、3月時点の価値のまま残ります。過去日付の記録も正しく採点
されます。スナップショットが今日ではなくその記録の日付で取られるためです。
副産物としてリフターは体重の履歴を得られますが、これ自体にも価値があります。

**代償。** 構成要素が増えます。テーブルが1つ増え、記録の保存ごとに参照が
1回増え、`before_validation` の順序依存も生まれます。スコアを計算する前に
体重のスナップショットを解決しておく必要があるためです。また、計量記録が
まだない状態で最初の記録を登録するケースへの対応も必要で、そのために記録
フォームは体重を直接受け取り、ログにも書き込むようにしています。

**明記しておくべき帰結。** スナップショットを記録ごとに保存しているため、
ログの変更は影響を受ける記録に反映する必要があります。計量値を登録・修正・
日時変更・削除すると、その日付で解決される体重が変わった記録だけを取り直し、
スコアを再計算します（`User#resnapshot_bodyweight`）。よくあるのは、より
古い計量値を後から登録したことで、それ以降の計量値にフォールバックしていた
記録が正しい体重に直るケースです。変更の影響を受けない記録のスコアは変わら
ないため、今日の体重を記録しても3月の記録はそのままです。記録に直接入力した
体重がログと異なる場合は、その記録固有の値として残します。ログを空にした
場合は、すべての記録が最後に分かっていた体重のまま残ります。

*改訂:* 以前は「修正しても過去の記録は再計算しない」としていました。しかし
それでは、古い計量値を後から登録したときに、最初の計量より前の記録が誤った
体重で採点されたままになっていました。
