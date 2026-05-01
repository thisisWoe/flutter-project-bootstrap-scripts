# flutter_launcher

Desktop Flutter app that guides the creation of a new Flutter project through a multi-step bootstrap flow.

The app collects the main project inputs:

- target folder
- project name
- app display name
- organization ID
- target platforms
- environments
- router shape

Then it runs the bootstrap pipeline and generates the destination project scaffold using `fvm flutter create`, dependency setup, architecture folders, templates, and validation steps.

## Prerequisites

- `fvm` installed and available in `PATH`
- Flutter desktop toolchains configured for the target platform
- a valid destination folder for the generated project

## Run

Development entrypoint:

```bash
fvm flutter run -d macos -t lib/entrypoints/dev/main.dart
```

Production-like entrypoint:

```bash
fvm flutter run -d macos -t lib/entrypoints/prod/main.dart
```

Replace `macos` with `linux` or `windows` when running on those platforms.

## Build

Prod build commands:

```bash
fvm flutter build macos -t lib/entrypoints/prod/main.dart
fvm flutter build linux -t lib/entrypoints/prod/main.dart
fvm flutter build windows -t lib/entrypoints/prod/main.dart
```

Dev build commands:

```bash
fvm flutter build macos -t lib/entrypoints/dev/main.dart
fvm flutter build linux -t lib/entrypoints/dev/main.dart
fvm flutter build windows -t lib/entrypoints/dev/main.dart
```

Desktop builds must be executed on the corresponding operating system:

- `macos` on macOS
- `linux` on Linux
- `windows` on Windows
