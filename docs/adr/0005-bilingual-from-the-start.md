*English / [日本語](#日本語)*

# 0005. Bilingual from the start, enforced by a test

**Status:** Accepted

## Context

Lifta is written partly to be shown to Japanese employers, so it has to
work properly in Japanese — not as a later translation pass over an
English app.

Retrofitting a second language is where this usually goes wrong. English
strings settle into views, layouts get built around English word lengths,
and the translation arrives as a half-finished second-class version: some
pages translated, some flash messages still in English, dates in the
wrong format. A half-translated Japanese page would undercut the exact
thing the project is meant to demonstrate.

## Decision

Every user-facing string lives in `config/locales/en.yml` and
`config/locales/ja.yml` from the moment it is written. Neither file is
allowed to drift from the other, and a test enforces it.

Three things back this up:

- `spec/i18n_spec.rb` fails if the two files' keys or their
  `%{placeholders}` differ at all.
- `spec/requests/localization_spec.rb` renders every page in Japanese and
  fails on any "translation missing".
- Missing translations raise in development and test, so a missing key is
  an error while writing the feature, not a silent fallback in production.

## Consequences

**What this buys.** Japanese is never behind. Adding a string means
adding two keys, which is a small tax paid continuously instead of a
large one paid late. Layout problems surface immediately —
ウエイトリフティング is far wider than "Weightlifting", which is why the
rank label column has a per-language width.

**What it costs.** Every user-facing change is twice the text, and the
Japanese has to be written, not machine-translated, or the exercise is
pointless. Some phrasing can't be translated one-to-one and needs a real
decision: the per-discipline board is 総合, so the cross-discipline
combined rank had to become 総合力 rather than reuse it.

**Scope.** This covers the UI. The READMEs are bilingual as well, since
they are the first thing a reader sees. Code comments and these records
are English-first, with these records carrying a Japanese version in the
same file.

---

<a id="日本語"></a>

# 0005. 最初から2言語対応とし、テストで担保する

**状態:** 採用

## 背景

Lifta は日本の採用担当者に見せることも目的の一つなので、日本語でもきちんと
動く必要があります。英語のアプリを作ったあとで翻訳を当てる、という進め方
では不十分です。

あとから2言語目を足す方法は、たいてい失敗します。英語の文字列がビューに
染み付き、レイアウトが英語の語長を前提に組まれ、翻訳は中途半端な二級品
として現れます。翻訳されたページとされていないページが混在し、フラッシュ
メッセージだけ英語のまま残り、日付の書式が合わない、といった具合です。
中途半端な日本語ページは、このプロジェクトが示そうとしているものを、その
まま損ないます。

## 決定

ユーザーに表示される文字列は、書いたその時点から `config/locales/en.yml`
と `config/locales/ja.yml` の両方に置きます。どちらか一方がずれることを
許さず、それをテストで担保します。

これを支えるものが3つあります。

- `spec/i18n_spec.rb` は、2つのファイルのキーまたは `%{placeholder}` に
  少しでも差があれば失敗します。
- `spec/requests/localization_spec.rb` は全ページを日本語で描画し、
  「translation missing」が出れば失敗します。
- 開発環境とテスト環境では翻訳の欠落が例外になります。キーの漏れは機能を
  書いている最中のエラーになり、本番で黙ってフォールバックすることが
  ありません。

## 影響

**得られるもの。** 日本語が遅れることがありません。文字列を追加するとは
キーを2つ追加することであり、小さな負担を継続的に払う代わりに、大きな負担
をあとでまとめて払わずに済みます。レイアウトの問題もその場で表面化します。
「ウエイトリフティング」は "Weightlifting" よりはるかに幅を取るため、ランク
ラベルの列幅を言語ごとに変えているのはそのためです。

**代償。** ユーザーに見える変更はすべて文章量が2倍になり、日本語は機械翻訳
ではなく書かなければ意味がありません。一対一で訳せず、判断が必要な表現も
あります。競技内の総合ランキングがすでに「総合」なので、競技をまたぐ
ランクは同じ語を使えず「総合力」としました。

**範囲。** 対象は UI です。README も2言語で用意しています。読む人が最初に
目にするものだからです。コード内のコメントとこれらの記録は英語を基本と
し、記録については同じファイル内に日本語版を併記しています。
