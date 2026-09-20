*English / [日本語](#日本語)*

# 0004. Target WCAG 2.0 AA, the standard JIS X 8341-3 adopts

**Status:** Accepted

## Context

Lifta is built partly for a Japanese audience, so it should meet the
accessibility expectations that apply there rather than a vague sense of
"accessible enough".

Two things are relevant and often conflated:

- **JIS X 8341-3:2016** is Japan's web accessibility standard. It is
  technically identical to WCAG 2.0, and Level AA is what public-sector
  procurement asks for. It is the concrete, testable target.
- **The revised 障害者差別解消法 (Act on the Elimination of
  Discrimination against Persons with Disabilities)**, in force since
  1 April 2024, made providing 合理的配慮 (reasonable accommodation) a
  legal obligation for private businesses, where it had been an effort
  duty. It does not prescribe a technical web standard. Its practical
  effect is that accessibility is now something a Japanese company must
  be able to answer for, which makes the JIS standard the natural yardstick.

## Decision

Target **WCAG 2.0 Level AA**, the success criteria JIS X 8341-3:2016
adopts. Verify what can be verified automatically, and be explicit about
what cannot.

Where WCAG 2.1 adds a criterion that is cheap and clearly worth it —
non-text contrast for the rank meters, in particular — follow it too,
while not claiming 2.1 conformance.

## Consequences

**What was found and fixed.** Three palette colours were below the 1.4.3
contrast threshold, including `--ink-muted` at 3.23:1 used for body text.
There was no skip link (2.4.1) and no `main` landmark. Inputs removed
their focus outline and signalled focus only by recolouring a 1px border
(2.4.7). Table headers carried no `scope` (1.3.1).

**What is guarded.** `spec/requests/accessibility_spec.rb` checks the
criteria that are visible in markup: language of page and parts, skip
link and landmark, page titles, header scope, form labelling, and error
announcement. These fail the build if they regress.

**What this does not claim.** Contrast was verified by computing ratios
against the background, not by testing every rendered combination.
Keyboard focus *order*, screen-reader output, and whether the Japanese
text is actually comprehensible when read aloud all need a person and
assistive technology. This record should not be read as a conformance
claim; it records the target and the work done toward it.

**Cost.** Some of the palette moved away from the original muted, low
contrast look. That was the right trade: the design language survives,
and the text is legible.

---

<a id="日本語"></a>

# 0004. JIS X 8341-3 が採用する WCAG 2.0 AA を目標とする

**状態:** 採用

## 背景

Lifta は日本のユーザーを念頭に置いて作っているため、「なんとなくアクセシブル」
ではなく、日本で実際に求められる水準を目標にすべきです。

関係する事柄が2つあり、しばしば混同されています。

- **JIS X 8341-3:2016** は日本のウェブアクセシビリティ規格です。WCAG 2.0
  と技術的に同一で、公共調達で求められるのはレベル AA です。具体的で検証
  可能な目標になります。
- **改正障害者差別解消法**（2024年4月1日施行）は、それまで努力義務だった
  合理的配慮の提供を、民間事業者にとっても法的義務としました。ただし、
  ウェブの技術規格を定めるものではありません。実務上の意味は、アクセシ
  ビリティについて日本企業が説明責任を負うようになったということであり、
  その結果として JIS 規格が自然な物差しになります。

## 決定

JIS X 8341-3:2016 が採用する **WCAG 2.0 レベル AA** の達成基準を目標と
します。自動で検証できるものは検証し、できないものは明示します。

WCAG 2.1 で追加された基準のうち、低コストで明らかに価値のあるもの——特に
ランクメーターの非テキストコントラスト——にも従いますが、2.1 への準拠を
主張はしません。

## 影響

**発見し修正した点。** パレットの3色が達成基準 1.4.3 のコントラスト比を
下回っていました。本文に使われる `--ink-muted` の 3.23:1 を含みます。
スキップリンク（2.4.1）と `main` ランドマークがありませんでした。入力欄は
フォーカスの輪郭線を消し、1px のボーダーの色変化だけでフォーカスを示して
いました（2.4.7）。テーブルの見出しセルに `scope` がありませんでした
（1.3.1）。

**担保している点。** `spec/requests/accessibility_spec.rb` が、マークアップ
から確認できる基準を検査します。ページと部分の言語指定、スキップリンクと
ランドマーク、ページタイトル、見出しセルの scope、フォームのラベル付け、
エラーの通知です。これらが退行するとビルドが失敗します。

**主張していない点。** コントラストは背景色に対する比率の計算で確認した
ものであり、描画されるすべての組み合わせを検証したわけではありません。
キーボードのフォーカス**順序**、スクリーンリーダーの読み上げ結果、そして
日本語が読み上げられたときに実際に理解できるかどうかは、いずれも人と支援
技術による確認が必要です。この記録を準拠の宣言として読むべきではありま
せん。目標と、そこに向けて行った作業の記録です。

**代償。** パレットの一部は、当初の彩度を抑えた低コントラストの見た目から
離れました。これは正しい取引でした。デザインの言語は保たれたまま、文字が
読めるようになっています。
