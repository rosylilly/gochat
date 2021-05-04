# バージョン
VERSION:=$(shell cat VERSION)
# リビジョン
REVISION:=$(shell git rev-parse --short HEAD)

# 出力先のディレクトリ
BINDIR:=bin

# ルートパッケージ名の取得
ROOT_PACKAGE:=$(shell go list .)
# コマンドとして書き出されるパッケージ名の取得
COMMAND_PACKAGES:=$(shell go list ./cmd/...)

# 出力先バイナリファイル名(bin/server など)
BINARIES:=$(COMMAND_PACKAGES:$(ROOT_PACKAGE)/cmd/%=$(BINDIR)/%)

# ビルド時にチェックする .go ファイル
GO_FILES:=$(shell find . -type f -name '*.go' -print)

# ldflag
GO_LDFLAGS_VERSION:=-X '${ROOT_PACKAGE}.VERSION=${VERSION}' -X '${ROOT_PACKAGE}.REVISION=${REVISION}'
GO_LDFLAGS:=$(GO_LDFLAGS_VERSION)

# go build
GO_BUILD:=-ldflags "$(GO_LDFLAGS)"

# ビルドタスク
.PHONY: build
build: $(BINARIES)

# 実ビルドタスク
$(BINARIES): $(GO_FILES) VERSION .git/HEAD
	@go build -o $@ $(GO_BUILD) $(@:$(BINDIR)/%=$(ROOT_PACKAGE)/cmd/%)
