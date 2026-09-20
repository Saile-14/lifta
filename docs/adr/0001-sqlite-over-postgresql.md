*English / [日本語](#日本語)*

# 0001. SQLite instead of PostgreSQL

**Status:** Accepted

## Context

Lifta needs a database for users, lifts and bodyweight entries. The
expected load is small and well understood: a few hundred lifters, maybe
twenty at once, writing a handful of rows each per week. Reads dominate,
and the heaviest query is a leaderboard over at most a few thousand rows.

The reflex choice for a Rails app is PostgreSQL. It would mean a database
server to provision, back up, monitor and pay for, alongside the app
container.

## Decision

Use SQLite, on a persistent volume attached to the single application
container (see `config/deploy.yml`).

Rails 8 treats SQLite as a production-capable default and ships the
configuration that makes it one: WAL mode, a sane busy timeout, and the
Solid Queue / Solid Cache adapters that would otherwise need Redis.

## Consequences

**What this buys.** One container and one volume is the whole production
footprint. There is no connection pooling to tune, no network hop on
every query, no separate backup story — the database is a file, so a
backup is a file copy. For a project whose job is partly to be read by
other engineers, the deployment is small enough to understand in full.

**What it costs.** Writes serialise, so this stops working under
write-heavy concurrent load — the ceiling is roughly the scale described
above, not ten times it. Horizontal scaling isn't available: a second app
container would need a shared database, which means changing this
decision. Some PostgreSQL features are simply absent, notably real
`jsonb` querying and full-text search.

**When to revisit.** If concurrent writes start timing out, or the app
needs more than one container, move to PostgreSQL. The migration is
mechanical because nothing depends on SQLite-specific behaviour: no raw
SQL beyond a `LIKE` search, and the check constraints added in
`20260920140000` are standard.

---

<a id="日本語"></a>

# 0001. PostgreSQL ではなく SQLite を使う

**状態:** 採用

## 背景

Lifta にはユーザー・挙上記録・体重記録を保存するデータベースが必要です。
想定する負荷は小さく、見通しも立っています。リフターは数百人、同時利用は
20人程度、1人あたり週に数行の書き込みです。読み取りが大半を占め、最も重い
クエリでも数千行規模のリーダーボード集計にとどまります。

Rails アプリでの反射的な選択は PostgreSQL です。しかしその場合、アプリ用
コンテナとは別に、構築・バックアップ・監視・課金の対象となるデータベース
サーバーを用意することになります。

## 決定

アプリのコンテナ1つに永続ボリュームを付け、そこで SQLite を動かします
（`config/deploy.yml` を参照）。

Rails 8 は SQLite を本番でも使える既定の選択肢として扱い、そのための設定
一式を同梱しています。WAL モード、適切なビジータイムアウト、そして本来
Redis が必要になる Solid Queue / Solid Cache のアダプタです。

## 影響

**得られるもの。** 本番環境はコンテナ1つとボリューム1つだけで完結します。
コネクションプールの調整も、クエリごとのネットワーク往復も、独立した
バックアップ手順も不要です。データベースはファイルなので、バックアップは
ファイルのコピーで済みます。他のエンジニアに読まれることも目的の一つで
あるこのプロジェクトにとって、構成全体を見渡せる小ささには価値があります。

**代償。** 書き込みは直列化されるため、書き込みが多い同時アクセスには
耐えられません。上限は上に書いた規模であって、その10倍ではありません。
水平スケールもできません。アプリのコンテナを2つにするには共有データベース
が必要で、それはこの決定を変えることを意味します。PostgreSQL の機能のうち、
本格的な `jsonb` 検索や全文検索は使えません。

**見直す時期。** 同時書き込みでタイムアウトが出始めたとき、またはコンテナ
を複数必要とするときは、PostgreSQL へ移行します。移行は機械的に行えます。
SQLite 固有の挙動に依存していないためです。生の SQL は `LIKE` 検索だけで、
`20260920140000` で追加したチェック制約も標準的なものです。
