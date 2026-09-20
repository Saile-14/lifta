*English / [日本語](#日本語)*

# 0002. Rails' built-in authentication instead of Devise

**Status:** Accepted

## Context

Lifta needs email-and-password sign-in, sessions that survive a browser
restart, and an admin flag. It does not need OAuth, confirmation emails,
account locking, or any of the other things a full authentication gem
provides.

Devise is the reflex answer in Rails, and it is a large dependency: a
DSL of modules, its own routes and controllers, its own views to
override, and a lot of behaviour that only becomes visible when you need
to change it.

## Decision

Use the authentication generator Rails 8 ships (`User`, `Session`,
`Current`, and the `Authentication` concern), with `has_secure_password`
underneath.

## Consequences

**What this buys.** The whole authentication path is a few files in
`app/models` and `app/controllers/concerns`, readable end to end in a few
minutes. Sessions are database rows, so signing out everywhere is a
`destroy_all` and there's no token-invalidation puzzle. Adding rate
limiting to sign-in was one line, because the controller is ours. For a
project meant to be read, owning this code is the point rather than a
cost.

**What it costs.** Anything Devise would have given us has to be written:
password reset is ours (and is switched off until production has outgoing
mail, see `config.x.password_resets_enabled`), and so is any future email
confirmation or OAuth. Each is a small amount of security-sensitive code,
which is exactly the code it's least comfortable to write yourself.

**When to revisit.** If the app needs OAuth providers, or multi-factor
authentication, reach for a library rather than growing this. The
migration cost is real but bounded — `User` already stores a
`password_digest` in the format Devise expects.

---

<a id="日本語"></a>

# 0002. Devise ではなく Rails 標準の認証を使う

**状態:** 採用

## 背景

Lifta に必要なのは、メールアドレスとパスワードによるログイン、ブラウザを
閉じても維持されるセッション、そして管理者フラグだけです。OAuth も、確認
メールも、アカウントロックも、認証 gem が提供するその他の機能も必要あり
ません。

Rails では Devise が反射的な答えになりますが、これは大きな依存関係です。
モジュールの DSL、独自のルーティングとコントローラ、上書きするための
ビュー群、そして変更が必要になって初めて見えてくる多くの挙動を抱えています。

## 決定

Rails 8 に同梱されている認証ジェネレータ（`User`、`Session`、`Current`、
および `Authentication` concern）を使い、その下で `has_secure_password`
を利用します。

## 影響

**得られるもの。** 認証の処理全体が `app/models` と
`app/controllers/concerns` の数ファイルに収まり、数分で端から端まで読め
ます。セッションはデータベースの行なので、全端末からのログアウトは
`destroy_all` で済み、トークンの無効化に頭を悩ませる必要がありません。
ログインへのレート制限も、コントローラが自前なので1行で追加できました。
読まれることを目的としたプロジェクトでは、このコードを自分で持っていること
自体が目的であり、負担ではありません。

**代償。** Devise が用意してくれるものは、すべて自分で書くことになります。
パスワードリセットは自前で（本番環境でメール送信が使えるようになるまでは
無効にしてあります。`config.x.password_resets_enabled` を参照）、将来の
確認メールや OAuth も同様です。いずれもコード量自体は少ないものの、
セキュリティに直結する部分であり、自分で書くのが最も気の進まない類の
コードでもあります。

**見直す時期。** OAuth 連携や多要素認証が必要になったら、この実装を育てる
のではなくライブラリを導入します。移行の手間は現実にありますが限定的です。
`User` はすでに Devise と同じ形式で `password_digest` を保存しています。
