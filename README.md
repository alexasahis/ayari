# Ayari - Dropbox を用いた静的サイト構築ツール

## Description

[pancake.io](https://pancake.io) っぽいものを自分でホスティングするなにか。
ぶっちゃけ自分しか使わないので適当に書きます。

## Install

	$ git clone https://github.com/wafrelka/ayari.git
	$ cd ayari
	$ bundle install --without test --path vendor/bundle
	$ echo 'dropbox_token: "xxx"' > config.yaml
sqlite3.gem を入れるので関連ファイルをインストールする必要があるかもしれない。
Dropbox のトークンはがんばって自分で取得してください。

## Operation

	$ bundle exec rake sync
動かしているあいだ Dropbox のアプリフォルダとローカルデータを同期してくれる……といいな。

	$ bundle exec thin start -p 8080
thin でなくても動く……はず？

## Routing

`/hoge.fuga`へのリクエストに対して

1. `/hoge.fuga`
2. `/hoge.fuga.md`
3. `/hoge.fuga.haml`
4. `/hoge.fuga.html`
5. `/hoge.fuga/index.md`
6. `/hoge.fuga/top.md`

という順番でファイルを見て行き一番最初に見つかったものをレンダリングする。

ほとんどのファイルはそのまま送信される。
haml(\*.haml) と markdown(\*.md) だけはすこし処理をして返している。
haml は 普通にレンダリングをしているだけ。markdown は後述する。

## Markdown Notation

Redcarpet を使ってレンダリングしている。
ファイルの先頭に

	---
	template: "/template.haml"
	markdown:
	  hard_wrap: true
	  safe_links_only: true
	---
などと YAML 形式でオプションを書いて`---`で囲う必要がある。

### Template Option

markdown ファイルは haml ファイルに埋め込む形でしか利用できず、ファイルの先頭で

	---
	template: "/template.haml"
	---

として template オプションを用いて埋め込む先の haml を指定する必要がある。

### Markdown Option

	---
	template: "/template.haml"
	markdown:
	  hard_wrap: true
	  safe_links_only: true
	---

などと markdown オプションを用いて Redcarpet のオプションを指定できる。

### Flavor Option

	---
	template: "/template.haml"
	flavor: "ayari"
	---

とすると Redcarpet に対して拡張が施され、

	## 緋宮 {#hinomiya .ayari}
	- test
	### あやり {.ayari}
	- test
	## ウィッチズガーデン {#witch}
	- test

このような markdown ファイルに対して

	<section id="hinomiya" class="ayari">
		<h2>緋宮</h2>
		<section class="ayari">
			<h3>あやり</h3>
		</section>
	</section>
	<section id="witch">
		<h2>ウィッチズガーデン</h2>
	</section>

のようなレンダリングが行われる。

### Other Options

template, markdown, flavor 以外のオプションは
すべて haml のレンダリング時にローカル変数として渡される。
なおキーはすべて Symbol に変換される。

## Miscellaneous
- Author: わふれるか。
- Licence: 修正BSDライセンスとかだろうか
