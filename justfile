name := 'cosmic-idle'
export APPID := 'com.system76.CosmicIdle'

rootdir := ''
prefix := '/usr'

base-dir := absolute_path(clean(rootdir / prefix))

export INSTALL_DIR := base-dir / 'share'

cargo-target-dir := env('CARGO_TARGET_DIR', 'target')
bin-src := cargo-target-dir / 'release' / name
bin-dst := base-dir / 'bin' / name

# Default recipe which runs `just build-release`
default: build-release

# Runs `cargo clean`
clean:
    cargo clean

# `cargo clean` and removes vendored dependencies
clean-dist: clean
    rm -rf .cargo vendor vendor.tar

# Compiles with debug profile
build-debug *args:
    cargo build --all {{args}}

# Compiles with release profile
build-release *args: (build-debug '--release' args)

# Compiles release profile with vendored dependencies
build-vendored *args:
    @just vendor-extract
    cp Cargo.toml Cargo.toml.bak
    sed -i '/^\[patch/,/^$/d' Cargo.toml
    cargo build --release {{ args }} --frozen --offline
    mv Cargo.toml.bak Cargo.toml

# Runs a clippy check
check *args:
    cargo clippy --all-features {{args}} -- -W clippy::pedantic

# Runs a clippy check with JSON message format
check-json: (check '--message-format=json')

mock:
    cargo build --release --example server
    cosmic-comp {{cargo-target-dir}}/release/examples/server

# Run with debug logs
run *args:
    env RUST_LOG=debug RUST_BACKTRACE=full cargo run --release {{args}}

install:
    install -Dm0755 {{bin-src}} {{bin-dst}}

# Uninstalls installed files
uninstall:
    rm {{bin-dst}}

# Vendor dependencies locally
vendor:
    mkdir -p .cargo
    cargo vendor --sync Cargo.toml 2>/dev/null | awk '/^\[/{p=1} p' > .cargo/config
    tar pcf vendor.tar vendor .cargo/config
    rm -rf vendor

# Extracts vendored dependencies
vendor-extract:
    rm -rf vendor
    tar pxf vendor.tar
