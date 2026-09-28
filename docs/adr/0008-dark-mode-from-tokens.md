*English / [日本語](#日本語)*

# 0008. Dark mode swaps the palette tokens, and the server renders the choice

**Status:** Accepted

## Context

Lifta is often opened in a gym or late in the evening, on a phone whose
system theme is already dark. A bright cream page is then the one glaring
thing on the screen.

Every colour in the stylesheet was already a custom property on `:root`,
except for a handful of literals (the profile card surface, white text on
the red button, the success flash, the highlighted own row). The rank
meters are the product's centre, and their colours carry meaning, so a
dark theme has to keep every tier distinguishable and every fill visible
against its track.

## Decision

- **Swap tokens, not rules.** The remaining literals became tokens, and
  dark mode is a second set of values for the same tokens. No component
  rule knows which theme is active.
- **Follow the system until the lifter chooses.** With no choice made,
  `prefers-color-scheme` decides. The nav's theme button records a choice
  in a `theme` cookie.
- **The server renders the choice.** The layout writes the cookie's value
  to `<html data-theme>`, so a lifter who picked dark never sees a light
  page flash before the script runs. Only `light` and `dark` are accepted.
- **Hold dark to the same bar as light (ADR 0004).** Every text colour is
  at least 4.5:1 on the dark background (body text 14.9:1, muted text
  6.5:1, the accent 6.0:1), and every tier and combined-rank fill is at
  least 3:1 against the meter track (the lowest, dormant grey, 4.1:1).
- **The primary button keeps its deep red.** The accent brightens in the
  dark for text and focus rings, but white on that brighter red would fall
  below 4.5:1, so the button has tokens of its own (5.3:1 in both themes).

## Consequences

The dark palette appears twice in the stylesheet, once inside the media
query and once under `[data-theme="dark"]`, because plain CSS can't share
one block between them. The two must be edited together.

The button needs JavaScript to switch, so it is rendered `hidden` and
revealed by its controller; without JavaScript the page still follows the
system setting.

A new colour has to be added as a token with a value for both themes.
A literal colour in a rule will look wrong in one of them.

---

<a id="日本語"></a>

# 0008. ダークモードはパレットのトークンを差し替え、選択はサーバーが描画する

**状態:** 採用

## 背景

Lifta はジムや夜遅くに、システムのテーマがすでにダークになっているスマート
フォンで開かれることがよくあります。そのとき、明るいクリーム色のページだけが
画面の中でまぶしく浮いてしまいます。

スタイルシートの色はほぼすべて `:root` のカスタムプロパティでしたが、いくつか
直接書かれた色が残っていました（プロフィールカードの面、赤いボタン上の白文字、
成功メッセージ、自分の行の強調）。ランクメーターはこのアプリの中心であり、
色が意味を持つため、ダークテーマでもすべてのティアを見分けられ、すべての
メーターがトラックに対して見える必要があります。

## 決定

- **ルールではなくトークンを差し替える。** 残っていた直書きの色をトークンに
  し、ダークモードは同じトークンに対するもう一組の値とします。どのテーマが
  有効かを個々のルールは知りません。
- **ユーザーが選ぶまではシステム設定に従う。** 選択がなければ
  `prefers-color-scheme` で決まります。ナビのテーマボタンは選択を `theme`
  クッキーに記録します。
- **選択はサーバーが描画する。** レイアウトがクッキーの値を
  `<html data-theme>` に書き出すため、ダークを選んだユーザーがスクリプトの
  実行前に明るいページを一瞬見ることはありません。受け付ける値は `light` と
  `dark` のみです。
- **ダークにもライトと同じ基準を課す（ADR 0004）。** ダークの背景に対して、
  すべての文字色は 4.5:1 以上（本文 14.9:1、補足テキスト 6.5:1、アクセント
  6.0:1）、ティアと総合力ランクのメーターはすべてトラックに対して 3:1 以上
  （最も低い dormant のグレーで 4.1:1）です。
- **主ボタンは深い赤のままにする。** ダークでは文字やフォーカスリング用に
  アクセントを明るくしますが、その明るい赤の上の白文字は 4.5:1 を下回るため、
  ボタンには専用のトークンを持たせています（両テーマとも 5.3:1）。

## 影響

プレーンな CSS ではメディアクエリと `[data-theme="dark"]` で1つのブロックを
共有できないため、ダークのパレットはスタイルシートに2回現れます。2つは必ず
一緒に編集する必要があります。

ボタンの切り替えには JavaScript が必要なため、ボタンは `hidden` で描画され、
コントローラーが表示します。JavaScript がなくても、ページはシステム設定に
従います。

新しい色はトークンとして追加し、両テーマの値を持たせる必要があります。
ルールに直接書いた色は、どちらかのテーマで不自然に見えます。
