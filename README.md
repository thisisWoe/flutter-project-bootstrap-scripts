# Flutter Project Bootstrap Scripts

Opinionated bootstrap scripts for creating a production-ready Flutter project baseline with FVM, multi-environment entrypoints, routing, localization, IDE launch configurations, and a feature-oriented application structure.

The repository provides equivalent Unix/macOS and Windows entrypoints:

- `collect_required_inputs.sh`
- `collect_required_inputs.bat`

Both scripts collect the required project metadata interactively, generate a Flutter scaffold in a temporary workspace, copy it into the target directory, apply the standard project structure, install dependencies, and validate the result.

## What It Creates

The bootstrap flow creates a Flutter project with:

- Flutter stable selected through FVM.
- Target platforms selected at runtime.
- A deterministic package name and platform identifier derived from the project name.
- Environment-specific entrypoints under `lib/entrypoints/<environment>/main.dart`.
- A core application layer with configuration, dependency bindings, networking, routing, theming, shared preferences, and localization.
- Initial `onboarding`, `home`, and `profile` feature folders.
- `go_router` routing with either root routes or a shell route layout.
- GetX bindings/controllers for dependency registration and simple feature state.
- Material 3 light/dark theme baseline.
- English and Italian ARB localization files.
- VS Code launch configurations for every environment.
- JetBrains Flutter run configurations when a `.idea` directory is present.
- A baseline `analysis_options.yaml`.

## Requirements

Install these tools before running the scripts:

- Git.
- FVM available in `PATH`.
- A platform toolchain compatible with the Flutter platforms you select.
- Bash on Unix/macOS.
- Command Prompt plus PowerShell on Windows.

The scripts run:

```bash
fvm install stable
fvm use stable --force --skip-pub-get
fvm flutter create
fvm flutter pub add
fvm flutter pub get
fvm flutter analyze
```

## Usage

Run the script from this repository and pass the target project directory as the first argument.

### Unix/macOS

```bash
./collect_required_inputs.sh /path/to/target/project
```

If no target path is provided, the current working directory is used:

```bash
./collect_required_inputs.sh
```

### Windows

```bat
collect_required_inputs.bat C:\path\to\target\project
```

If no target path is provided, the current working directory is used:

```bat
collect_required_inputs.bat
```

## Interactive Inputs

The scripts prompt for the following values:

| Input               | Description                                                                                              |
| ------------------- | -------------------------------------------------------------------------------------------------------- |
| `project_name`      | Human-readable project name. It is normalized into a valid Flutter project name.                         |
| `app_display_name`  | Display name injected into the generated app configuration.                                              |
| `target_platforms`  | Interactive multi-select prompt. Allowed values: `android`, `ios`, `web`, `macos`, `windows`, `linux`. |
| `environment_names` | Interactive multi-select prompt. Available values: `dev`, `test`, `prod`. At least two are required.   |
| `router_shape`      | Routing layout. Allowed values: `root` or `shell`.                                                       |

Example input:

```text
project_name: My Client App
app_display_name: My Client
target_platforms: android, ios, web
environment_names: dev, test, prod
router_shape: shell
```

Derived values are printed before generation, including:

- `flutter_project_name`
- `platform_identifier_base`
- `android_namespace`
- `android_application_id`
- `ios_bundle_identifier`
- `temporary workspace path`

## Generated Project Structure

The generated Flutter project includes the following application structure:

```text
lib/
  app.dart
  core/
    bindings/
    config/
    network/
    routing/
    shared_preferences/
    styles/
    utils/
    view/
  entrypoints/
    <environment>/
      main.dart
  features/
    onboarding/
    home/
    profile/
  l10n/
    app_en.arb
    app_it.arb
```

The script also writes:

```text
.vscode/launch.json
l10n.yaml
analysis_options.yaml
```

JetBrains run configuration files are generated under `.idea/runConfigurations/` only when the target project already contains a `.idea` directory.

## Dependencies Added

Runtime dependencies:

- `dio`
- `shared_preferences`
- `get`
- `go_router`
- `intl`
- `flutter_displaymode`
- `stack_trace`
- `skeletonizer`
- `url_launcher`
- `device_info_plus`
- `package_info_plus`

Development dependencies:

- `flutter_native_splash`
- `flutter_launcher_icons`
- `flutter_lints`

The script also enables Flutter localization generation and adds `flutter_localizations` from the Flutter SDK.

## Safety Checks

Before generating the project, the scripts run preflight checks on the target directory:

- The target path must exist.
- Existing Flutter projects are rejected.
- Isolated Flutter-related files such as `lib/`, `android/`, `ios/`, `test/`, `web/`, `macos/`, `windows/`, `linux/`, or `analysis_options.yaml` without a coherent scaffold are rejected for manual review.
- `README.md`, `.gitignore`, and `LICENSE` are classified as missing, placeholder, or custom content.

The generated Flutter scaffold is first created in a temporary workspace and copied into the target directory only after `flutter create` succeeds.

## Validation

At the end of the bootstrap flow, the generated project is validated with:

```bash
fvm flutter pub get
fvm flutter analyze
```

The temporary workspace is removed after the run completes or fails.

## Repository Layout

```text
.
  collect_required_inputs.sh
  collect_required_inputs.bat
  templates/
```

`templates/` contains template files for the Flutter application scaffold, localization, analysis options, and IDE configuration. The current scripts generate the final project files directly while keeping these templates available as the canonical shape of the intended scaffold.

## Troubleshooting

### `fvm was not found in PATH`

Install FVM and ensure the `fvm` executable is available from the shell used to run the script.

### `existing Flutter project detected`

Run the bootstrap script against an empty or intentionally prepared target directory. The scripts are designed for initial project creation, not for modifying an existing Flutter project.

### `isolated Flutter-related files detected`

The target directory contains files that look like part of a Flutter project but do not form a complete scaffold. Review the directory manually before rerunning the script.

### `flutter analyze` fails

Open the generated project and run:

```bash
fvm flutter pub get
fvm flutter analyze
```

Fix the reported analyzer issues in the generated project before continuing development.

## Notes

- The organization identifier is currently fixed to `it.alessandrorondolini`.
- Platform identifiers are derived from the normalized project name.
- The bootstrap is intentionally opinionated and optimized for new Flutter projects that follow this repository's architecture conventions.
