> ⚠️ This text may contain translation errors. You can read the Spanish version here: [technical-es.md](technical-es.md)

# Technical Documentation — algex

## Table of contents

1. [Structure](#1-structure)
2. [Main flow](#2-main-flow)
3. [Calculator engine](#3-calculator-engine)
4. [State management](#4-state-management)
5. [Persistence](#5-persistence)
6. [UI architecture](#6-ui-architecture)
7. [Charts system](#7-charts-system)
8. [Responsive design](#8-responsive-design)
9. [Testing](#9-testing)
10. [Technical debt](#10-technical-debt)

---

## 1. Structure
```
lib/
├── core/                        # Pure Dart — no Flutter dependency
│   ├── model/
│   │   ├── calculation_result.dart   # Output of a calculation run
│   │   ├── iteration_data.dart       # Data for a single iteration
│   │   └── settings.dart             # App settings + ToleranceType enum
│   └── service/
│       └── exp_calculator.dart       # Taylor series engine
│
└── ui/                          # Flutter layer
    ├── pages/
    │   ├── home_page.dart            # Main screen
    │   └── settings_page.dart        # Settings screen
    ├── state/
    │   └── settings_notifier.dart    # InheritedNotifier + ChangeNotifier
    └── widgets/
        ├── adjust/                   # Settings UI components
        │   ├── adjust_convergence.dart
        │   ├── adjust_visualization.dart
        │   ├── adjust_section_header.dart
        │   ├── adjust_textfield.dart
        │   └── chip_option.dart
        ├── charts/                   # Chart components
        │   ├── chart_card.dart       # Base card + shared helpers
        │   ├── convergence_chart.dart
        │   ├── error_chart.dart
        │   ├── significant_figures_chart.dart
        │   └── term_decay_chart.dart
        ├── base_card.dart
        ├── input_sliver.dart
        ├── iterations_view.dart
        ├── mode_toggle.dart
        ├── result_summary_card.dart
        └── algex_sliver_appbar.dart
```

---

## 2. Main flow

### e^x calculation
```
User enters x → InputSliver validates the field
        ↓
_HomePageState._calculateTaylor()
        ↓
SettingsScope.of(context) → reads current Settings
        ↓
ExpCalculator.calculate(x, settings)
        ├── Computes Taylor series iteration by iteration
        ├── Records IterationData for each n
        └── Returns CalculationResult when error < tolerance
        ↓
setState() → result + _usedTolerance updated
        ↓
        ├── ResultSummaryCard  → displays final summary
        ├── ModeToggle         → allows switching view
        └── depending on ViewMode:
            ├── ViewMode.iterations → IterationsView (SliverList)
            └── ViewMode.charts    → 4 ChartCards
```

### Settings change
```
User modifies a setting in SettingsPage
        ↓
SettingsScope.of(context).settings = newSettings
        ↓
SettingsNotifier.set settings()
        ├── _settings = newSettings
        ├── notifyListeners() → UI rebuilds immediately
        └── _save(s) async → writes to SharedPreferences in background
        ↓
Subscribed widgets rebuild with new values
(AdjustConvergence, AdjustVisualization, ResultSummaryCard, IterationsView)
```

### Initial load
```
App starts → _AppState creates SettingsNotifier()
        ↓
SettingsNotifier._load() async
        ├── SharedPreferences.getInstance()
        ├── Reads 5 individual keys
        ├── _settings.copyWith(...) — null preserves defaults
        └── notifyListeners() → UI rebuilds with persisted values
```

---

## 3. Calculator engine

**File:** `lib/core/service/exp_calculator.dart`

`ExpCalculator.calculate(x, settings)` is a static method that computes the Taylor series of $e^x$:

$$e^x = \sum_{n=0}^{\infty} \frac{x^n}{n!} = 1 + x + \frac{x^2}{2!} + \frac{x^3}{3!} + \cdots$$

### Term computation

Each term is computed incrementally to avoid factorial overflow:
```dart
// n=0: term = 1 (identity)
// n>0: term_n = term_{n-1} * x / n
term = term * x / n;
```

This avoids computing `x^n` and `n!` independently, which would overflow for large `n`.

### Error types

For each iteration `n`, four error values are computed:

| Error | Formula | Available in |
|---|---|---|
| Approximate | `\|sum_n - sum_{n-1}\| / \|sum_n\|` | Both modes |
| Absolute | `\|e^x - sum_n\|` | Absolute mode only |
| Relative | `absoluteError / \|e^x\|` | Absolute mode only |
| Percent | `relativeError × 100` | Absolute mode only |

In **approximate mode**, `realValue`, `absoluteError`, `relativeError`, and `percentError` are all `double.nan`. This is intentional — the calculator does not compute `exp(x)` at all, making it a true iterative approximation.

### Significant figures

Computed from the relative error using the standard formula:
```dart
significantFigures = floor(-log10(relativeError))
```

Only available in absolute mode (requires `relativeError`). Always `0` in approximate mode.

### Stopping criterion

The loop stops at iteration `n > 0` when:
- **Absolute mode:** `absoluteError < settings.tolerance`
- **Approximate mode:** `approxError < settings.tolerance`

`n=0` is never a stopping iteration by design — the first meaningful error comparison requires a previous iteration.

If no iteration satisfies the criterion, the loop completes at `maxIterations` and returns the final state.

### Output

`CalculationResult` contains:
- `finalValue` — the last computed partial sum
- `realValue` — `exp(x)` or `double.nan`
- `iterations` — total number of iterations run
- `history` — `List<IterationData>` with the full trace

`history.length == iterations` is always true.

---

## 4. State management

**File:** `lib/ui/state/settings_notifier.dart`

The app uses `InheritedNotifier<SettingsNotifier>` — a Flutter core pattern that combines an `InheritedWidget` (for propagation) with a `ChangeNotifier` (for reactivity). No third-party packages.
```
App (StatefulWidget)
└── SettingsScope (InheritedNotifier<SettingsNotifier>)
    └── MaterialApp
        ├── HomePage
        └── SettingsPage
```

### SettingsScope

`SettingsScope` wraps `InheritedNotifier` and exposes a single static accessor:
```dart
static SettingsNotifier of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
```

Any widget calling `SettingsScope.of(context)` subscribes to changes and rebuilds automatically when `notifyListeners()` is called.

### SettingsNotifier

- Holds a single immutable `Settings` value object
- The `settings` setter triggers `notifyListeners()` immediately, then fires `_save()` asynchronously
- `_load()` is called in the constructor and calls `notifyListeners()` after reading from disk
```dart
set settings(Settings s) {
  _settings = s;
  notifyListeners(); // UI updates immediately
  _save(s);          // Disk write happens in background
}
```

### Settings

`Settings` is an immutable value class with `copyWith`. All fields have defaults:

| Field | Type | Default |
|---|---|---|
| `maxIterations` | `int` | `100` |
| `tolerance` | `double` | `1e-6` |
| `toleranceType` | `ToleranceType` | `.absolute` |
| `showRealValue` | `bool` | `true` |
| `decimalPrecision` | `int` | `12` |

---

## 5. Persistence

**File:** `lib/ui/state/settings_notifier.dart`

Settings are persisted to `SharedPreferences` using individual keys per field.

### Loading

On startup, `_load()` reads all keys and calls `_settings.copyWith(...)`. If a key does not exist (first install, cleared data), `copyWith` receives `null` for that field, which preserves the default value from `Settings()`. No fallback logic required.
```dart
final index = _prefs!.getInt('toleranceType');
_settings = _settings.copyWith(
  toleranceType: index != null ? ToleranceType.values[index] : null,
  // null → copyWith keeps the default
);
```

`ToleranceType` is stored as its `.index` integer to avoid string fragility.

### Saving

Writes are parallelized with `Future.wait` — all five fields are written simultaneously instead of sequentially:
```dart
await Future.wait([
  _prefs!.setInt('maxIterations', s.maxIterations),
  _prefs!.setDouble('tolerance', s.tolerance),
  _prefs!.setInt('toleranceType', s.toleranceType.index),
  _prefs!.setBool('showRealValue', s.showRealValue),
  _prefs!.setInt('decimalPrecision', s.decimalPrecision),
]);
```

The `SharedPreferences` instance is cached in `_prefs` to avoid repeated `getInstance()` calls.

---

## 6. UI architecture

### Page structure

Both pages use `CustomScrollView` with slivers:
```
CustomScrollView
├── AlgexSliverAppBar    (pinned)
├── InputSliver          (home only)
├── ResultSummaryCard    (home, conditional)
├── ModeToggle           (home, conditional)
└── IterationsView / Charts  (home, conditional)
```

`AlgexSliverAppBar` accepts a `showBackButton` parameter rather than calling `Navigator.canPop()` at build time — this avoids stale values from the navigator state not triggering a rebuild.

### Widget hierarchy decisions

**`AdjustConvergence`** is a `StatefulWidget` because it manages two `TextEditingController`s that must sync with the notifier when settings change externally (e.g., reset button). The sync is done via `_notifier.addListener(_syncControllers)`, set up in `initState` through `addPostFrameCallback` (context is not available before the first frame).

**`AdjustVisualization`** follows the same pattern for its single precision controller.

### `_usedTolerance` snapshot

`HomePage` captures the tolerance at calculation time in `_usedTolerance`. This prevents the displayed error colors from shifting if the user changes the tolerance setting after a calculation, since color thresholds use `tolerance` as the reference point.

### Window configuration (desktop)

On desktop, `window_manager` sets a minimum window size on startup:
```dart
WindowOptions windowOptions = const WindowOptions(
  minimumSize: Size(300, 600),
);
```

This ensures the responsive layout always has enough space to render correctly. The 300px minimum allows the mode toggle to reach its icon-only state at the lower boundary.

---

## 7. Charts system

**File:** `lib/ui/widgets/charts/chart_card.dart`

All four charts share a single `ChartCard` base widget and a set of free functions.

### ChartCard

Renders a `BaseCard` with title, legend, and a `LayoutBuilder` that passes the available width to the chart builder:
```dart
ChartCard(
  title: 'Chart title',
  legend: [...],
  chartBuilder: (width) {
    final xInterval = chartXInterval(width, pointCount);
    return LineChart(...);
  },
)
```

### Shared helpers

| Function | Purpose |
|---|---|
| `chartAutoInterval(series)` | Computes Y-axis interval from data range / 5 |
| `chartXInterval(width, count)` | Limits X labels to ~40px each to prevent overlap |
| `chartValidSpots(spots)` | Filters out NaN/Infinite Y values |
| `chartTitles(...)` | Builds `FlTitlesData` with bottom and left labels |
| `chartBorder` | Standard border getter |
| `chartGrid(...)` | Standard grid with both axes |

### Four charts

| Chart | Data | Notes |
|---|---|---|
| `ConvergenceChart` | `partialSum` vs iteration | Adds real value reference line if available |
| `ErrorChart` | `log₁₀(\|approxError\|)` and `log₁₀(\|relativeError\|)` | Log scale for visibility across orders of magnitude |
| `TermDecayChart` | `log₁₀(\|term\|)` | Shows exponential decay of each term |
| `SignificantFiguresChart` | `significantFigures` and `−log₁₀(relativeError)` | Shows convergence relationship; absolute mode only |

`ChartUnavailable` is shown when a chart cannot be rendered in the current mode.

---

## 8. Responsive design

The app uses `LayoutBuilder` at three levels:

### Input area (`input_sliver.dart`)
- `< 400px` → stacked column (text field above button)
- `≥ 400px` → row with flex 3:2 ratio

### Result cards and metrics (`result_summary_card.dart`, `iterations_view.dart`)
- `< 600px` → single column, divider between info and error tiles
- `≥ 600px` → two-column row with equal flex

### Mode toggle (`mode_toggle.dart`)
- Each item gets `maxWidth / 2` of space
- `< 150px` per item → icon only
- `≥ 150px` per item → icon + label

---

## 9. Testing

**File:** `test/exp_calculator_test.dart`

Tests are organized in six groups:

| Group | What it covers |
|---|---|
| `exactitud` | Mathematical correctness for x ∈ {0, 1, −1, 2, −3, 10} |
| `tolerancia absoluta` | `realValue`, stopping criterion, error monotonicity, `percentError = relativeError × 100`, NaN at n=0 |
| `tolerancia aproximada` | All real-value fields are NaN, stopping criterion, result reasonableness |
| `estructura` | `iterations == history.length`, `finalValue == history.last.partialSum`, sequential `n`, `maxIterations` respected, minimum 2 iterations |
| `significantFigures` | Grows over iterations in absolute mode, always 0 in approximate mode |
| `Settings.copyWith` | All fields independently changeable, no field lost without argument |

Run with:
```bash
flutter test
```

---

## 10. Technical debt

### No dark mode support

The theme is configured with `brightness: Brightness.light` hardcoded and there is no `darkTheme` or `ThemeMode.system`. On devices with dark mode enabled the app forces the light theme.

### `significantFigures` undefined when error is exactly zero

When `relativeError == 0.0`, the condition `relativeError > 0` fails and `significantFigures` returns `0` instead of reflecting perfect convergence. The semantically correct value for zero error is not defined in the current model.

### Calculator limited to e^x

The architecture of `Settings`, `CalculationResult`, and `IterationData` is generic, but `ExpCalculator` is coupled to a single function. Extending the app to other Taylor series would require refactoring the service and possibly introducing a `SeriesCalculator` abstraction.
