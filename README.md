# Plakaki

Plakaki is an experimental, i3-style tiling window manager for macOS. It aims
to make window layout feel predictable and keyboard-driven while still working
with the grain of the macOS desktop.

Its core philosophy is to treat macOS Spaces as lightweight virtual displays:
each Space can hold its own tiling context, letting you organize work by task,
project, or mode without needing extra physical monitors.

## Dev Bootstrap

This project uses Mise-managed tooling and Tuist for project generation.

```sh
mise install
tuist install
cp Config/Signing.xcconfig.example Config/Signing.xcconfig
mise run generate
```

`Config/Signing.xcconfig` is machine-specific and supplies the app target's
code signing settings. Adjust `DEVELOPMENT_TEAM`, `CODE_SIGN_IDENTITY`, or
provisioning values there if your local Apple developer setup differs from the
example.

After generating the project, build or test through Tuist:

```sh
tuist build run Plakaki --generate
tuist test Plakaki
```

Optional local setup:

```sh
mise run hooks:install
```

> [!NOTE]
> Some commits in this repository may be generated with assistance from an LLM.
> Agent-generated commit messages are prefixed with `✨` and should use a
> separate committer identity so they are easy to identify in project history.
