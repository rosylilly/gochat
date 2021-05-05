# バージョン
VERSION:=$(shell cat VERSION)
# リビジョン
REVISION:=$(shell git rev-parse --short HEAD 2> /dev/null || cat REVISION)

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

# gRPC ファイル
PB_FILES:=$(shell find . -type f -name '*.proto' -print)
# proto から生成される .go ファイル
GOPB_FILES:=$(PB_FILES:%.proto=%.pb.go)

# version ldflag
GO_LDFLAGS_VERSION:=-X '${ROOT_PACKAGE}.VERSION=${VERSION}' -X '${ROOT_PACKAGE}.REVISION=${REVISION}'
# symbol table and dwarf
GO_LDFLAGS_SYMBOL:=
ifdef RELEASE
	GO_LDFLAGS_SYMBOL:=-w -s
endif
# static ldflag
GO_LDFLAGS_STATIC:=
ifdef RELEASE
	GO_LDFLAGS_STATIC:=-extldflags '-static'
endif
# build ldflags
GO_LDFLAGS:=$(GO_LDFLAGS_VERSION) $(GO_LDFLAGS_SYMBOL) $(GO_LDFLAGS_STATIC)
# build tags
GO_BUILD_TAGS:=debug
ifdef RELEASE
	GO_BUILD_TAGS:=release
endif
# race detector
GO_BUILD_RACE:=-race
ifdef RELEASE
	GO_BUILD_RACE:=
endif
# static build flag
GO_BUILD_STATIC:=
ifdef RELEASE
	GO_BUILD_STATIC:=-a -installsuffix netgo
	GO_BUILD_TAGS:=$(GO_BUILD_TAGS),netgo
endif
# go build
GO_BUILD:=-tags=$(GO_BUILD_TAGS) $(GO_BUILD_RACE) $(GO_BUILD_STATIC) -ldflags "$(GO_LDFLAGS)"

# ビルドタスク
.PHONY: build
build: $(BINARIES)

# お掃除
.PHONY: clean
clean:
	@$(RM) $(GOPB_FILES) $(BINARIES) $(BINDIR)/protoc-gen-go

# 実ビルドタスク
$(BINARIES): $(GO_FILES) $(GOPB_FILES) VERSION .git/HEAD
	@go build -o $@ $(GO_BUILD) $(@:$(BINDIR)/%=$(ROOT_PACKAGE)/cmd/%)

# protoc のビルド
$(GOPB_FILES): $(PB_FILES) $(BINDIR)/protoc-gen-go
	@protoc \
		--plugin=protoc-gen-go=$(BINDIR)/protoc-gen-go \
		-I ./proto \
		--go_out=./proto \
		--go_opt=paths=source_relative \
		$(@:%.pb.go=%.proto)

$(BINDIR)/protoc-gen-go: go.sum
	@go build -o $@ google.golang.org/protobuf/cmd/protoc-gen-go
