.PHONY: cli core fmt clean
.DEFAULT_GOAL := cli

download-wasi-sdk:
	sh install-wasi-sdk.sh

install:
	cargo install --path crates/cli

cli: core
		cd crates/cli && QUICKJS_WASM_SYS_WASI_SDK_PATH="$(CURDIR)/wasi-sdk/" cargo build --release && cd -

core:
		cd crates/core \
			  && cd src/prelude \
				&& npm install \
				&& npm run build \
				&& cd ../.. \
				&& QUICKJS_WASM_SYS_WASI_SDK_PATH="$(CURDIR)/wasi-sdk/" cargo build --release --target=wasm32-wasi \
				&& cd -

fmt: fmt-core fmt-cli

fmt-core:
		cd crates/core/ \
				&& cargo fmt -- --check \
				&& cargo clippy --target=wasm32-wasi -- -D warnings \
				&& cd -

fmt-cli:
		cd crates/cli/ \
				&& cargo fmt -- --check \
				&& cargo clippy -- -D warnings \
				&& cd -

clean: clean-wasi-sdk clean-cargo

clean-cargo:
		cargo clean

clean-wasi-sdk:
		rm -r wasi-sdk 2> /dev/null || true

test: compile-examples
		@extism call examples/simple_js.wasm greet --wasi --input="Benjamin"
		@extism call examples/bundled.wasm greet --wasi --input="Benjamin"

compile-examples:
		./target/release/extism-js examples/simple_js/script.js -i examples/simple_js/script.d.ts -o examples/simple_js.wasm
		cd examples/bundled && npm install && npm run build && cd ../..
