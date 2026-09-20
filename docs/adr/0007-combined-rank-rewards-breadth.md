*English / [日本語](#日本語)*

# 0007. The combined rank rewards breadth, not peak strength

**Status:** Accepted

## Context

Lifta ranks three disciplines separately. A single rank spanning all
three needs a rule for combining them, and the rule decides what the
whole feature means.

Three candidates:

1. **Average all three, an untrained discipline counting as zero.**
2. **Average only the disciplines the lifter has trained.** A pure
   powerlifter is scored on powerlifting alone.
3. **Sum on a 0–300 scale.**

Option 2 makes the top rank reachable by specialising, which is what the
per-discipline boards already reward — the combined rank would say
nothing new. Option 3 stops matching the percentage meters used
everywhere else in the app.

## Decision

Average the lifter's progress through all three disciplines, counting a
discipline they have never trained as zero
(`Discipline#progress_percent`, averaged in `ComboCard`).

Give it its own ladder rather than reusing bronze … grandmaster: dormant,
awakened, evolved, apex, transcendent, ultimate lifeform. Its rungs sit
lower (15/30/50/70/90) because averaging makes high numbers much harder
to reach.

## Consequences

**What this buys.** A number that says something the other boards don't.
On the seeded data, the lifter who trains all three sits at Apex (51.6%)
above a lifter who is 71% of world class at powerlifting and has never
done the other two (Awakened, 23.7%). A pure specialist tops out near a
third, by construction. The top rung means diamond-level strength in all
three simultaneously, which is genuinely rare — the point of naming it
"ultimate lifeform" at all.

**What it costs.** It is discouraging if you only care about one sport,
and that is a real cost, not a rounding error: most lifters specialise.
The mitigation is that the per-discipline ranks are unchanged and still
lead the dashboard, and that lifters choose which badges to show, so a
powerlifter can display powerlifting and never surface the combined rank.

**Why a separate ladder.** Reusing tier names would have implied the two
scales are comparable, and they are not: 60% combined is a far greater
achievement than 60% in one discipline. Different names and a different
colour ramp make them visually distinct, and the rung names don't overlap,
so one set of CSS classes serves both.

**Partial credit.** A discipline that is started but incomplete counts
proportionally rather than as zero, so progress shows up immediately.
This differs from the per-discipline overall rank, which is withheld
until every exercise has a lift — there, showing a rank dragged down by
unlogged lifts would misrepresent the lifter.

---

<a id="日本語"></a>

# 0007. 総合力ランクは突出した強さではなく幅広さを評価する

**状態:** 採用

## 背景

Lifta は3つの競技を別々にランク付けしています。3競技をまたぐ単一のランク
には合成のルールが必要で、そのルールが機能全体の意味を決めます。

候補は3つありました。

1. **3競技すべての平均をとり、未経験の競技は0として数える。**
2. **取り組んだ競技だけで平均をとる。** パワーリフティング一本の人は
   パワーリフティングだけで評価される。
3. **300点満点の合計にする。**

案2では、専門化するだけで最上位に到達できてしまいます。それは競技別の
ランキングがすでに評価していることであり、総合力ランクが新しく語るものが
なくなります。案3はアプリ全体で使っている百分率のメーターと整合しなく
なります。

## 決定

3競技すべての達成度を平均し、まだ取り組んでいない競技は0として数えます
（`Discipline#progress_percent` を `ComboCard` で平均）。

ブロンズ〜グランドマスターを流用せず、独自の段階を与えます。休眠・覚醒・
進化・頂点・超越・究極生命体です。平均を取ると高い数値に届きにくくなる
ため、しきい値は低め（15/30/50/70/90）に置いています。

## 影響

**得られるもの。** 他のランキングが語らないことを語る数値です。シード
データでは、3競技すべてに取り組むリフターが頂点（51.6%）に位置し、
パワーリフティングで世界基準の71%に達しているが他の2競技は未経験の
リフター（覚醒、23.7%）を上回ります。一つだけを極めた人は、構造上おおよそ
3分の1で頭打ちになります。最上位は3競技すべてで同時にダイヤモンド級である
ことを意味し、これは実際に稀です。「究極生命体」という名前を与えたのは
そのためです。

**代償。** 一つの競技にしか関心がない人にとっては気の滅入る指標であり、
これは無視できない代償です。多くのリフターは専門化するからです。緩和策と
して、競技別のランクは従来どおりでダッシュボードの主役のままであること、
そして表示するバッジをリフター自身が選べることがあります。パワーリフター
はパワーリフティングだけを掲げ、総合力ランクを表に出さずに済みます。

**なぜ別の段階なのか。** ティア名を流用すると、2つの尺度が比較可能である
かのように示唆してしまいますが、実際には違います。総合力の60%は、1競技で
の60%よりはるかに大きな達成です。名前と色の系統を分けることで視覚的にも
区別され、段階名も重複しないため、CSS のクラスは1組で両方をまかなえます。

**部分的な評価。** 着手したが完了していない競技は、0ではなく比例して数え
ます。そのため進捗がすぐに反映されます。これは競技別の総合ランクとは異なる
扱いです。競技別では全種目の記録がそろうまでランクを出しません。そこでは、
まだ登録していない記録のせいで下がったランクを表示することが、そのリフター
を正しく表さないからです。
