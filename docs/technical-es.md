# Documentación técnica — algex

## Tabla de contenidos

1. [Estructura](#1-estructura)
2. [Flujo principal](#2-flujo-principal)
3. [Motor de cálculo](#3-motor-de-cálculo)
4. [Manejo de estado](#4-manejo-de-estado)
5. [Persistencia](#5-persistencia)
6. [Arquitectura de UI](#6-arquitectura-de-ui)
7. [Sistema de gráficas](#7-sistema-de-gráficas)
8. [Diseño responsivo](#8-diseño-responsivo)
9. [Pruebas](#9-pruebas)
10. [Deuda técnica](#10-deuda-técnica)

---

## 1. Estructura

```
lib/
├── core/                        # Dart puro — sin dependencia de Flutter
│   ├── model/
│   │   ├── calculation_result.dart   # Resultado de una ejecución de cálculo
│   │   ├── iteration_data.dart       # Datos de una iteración individual
│   │   └── settings.dart             # Ajustes de la app + enum ToleranceType
│   └── service/
│       └── exp_calculator.dart       # Motor de la serie de Taylor
│
└── ui/                          # Capa Flutter
    ├── pages/
    │   ├── home_page.dart            # Pantalla principal
    │   └── settings_page.dart        # Pantalla de ajustes
    ├── state/
    │   └── settings_notifier.dart    # InheritedNotifier + ChangeNotifier
    └── widgets/
        ├── adjust/                   # Componentes de UI para ajustes
        │   ├── adjust_convergence.dart
        │   ├── adjust_visualization.dart
        │   ├── adjust_section_header.dart
        │   ├── adjust_textfield.dart
        │   └── chip_option.dart
        ├── charts/                   # Componentes de gráficas
        │   ├── chart_card.dart       # Card base + helpers compartidos
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

## 2. Flujo principal

### Cálculo de e^x

```
Usuario ingresa x → InputSliver valida el campo
        ↓
_HomePageState._calculateTaylor()
        ↓
SettingsScope.of(context) → lee Settings actual
        ↓
ExpCalculator.calculate(x, settings)
        ├── Computa serie de Taylor iteración por iteración
        ├── Registra IterationData por cada n
        └── Retorna CalculationResult cuando error < tolerance
        ↓
setState() → result + _usedTolerance actualizados
        ↓
        ├── ResultSummaryCard  → muestra resumen final
        ├── ModeToggle         → permite cambiar vista
        └── según ViewMode:
            ├── ViewMode.iterations → IterationsView (SliverList)
            └── ViewMode.charts    → 4 ChartCards
```

### Cambio de ajustes
```
Usuario modifica un ajuste en SettingsPage
        ↓
SettingsScope.of(context).settings = newSettings
        ↓
SettingsNotifier.set settings()
        ├── _settings = newSettings
        ├── notifyListeners() → UI reconstruye inmediatamente
        └── _save(s) async → escribe en SharedPreferences en background
        ↓
Widgets suscritos reconstruyen con nuevos valores
(AdjustConvergence, AdjustVisualization, ResultSummaryCard, IterationsView)
```

### Carga inicial
```
App arranca → _AppState crea SettingsNotifier()
        ↓
SettingsNotifier._load() async
        ├── SharedPreferences.getInstance()
        ├── Lee 5 claves individuales
        ├── _settings.copyWith(...) — null preserva defaults
        └── notifyListeners() → UI reconstruye con valores persistidos
```

---

## 3. Motor de cálculo

**Archivo:** `lib/core/service/exp_calculator.dart`

`ExpCalculator.calculate(x, settings)` es un método estático que calcula la serie de Taylor de $e^x$:

$$e^x = \sum_{n=0}^{\infty} \frac{x^n}{n!} = 1 + x + \frac{x^2}{2!} + \frac{x^3}{3!} + \cdots$$

### Cálculo del término

Cada término se calcula de forma incremental para evitar desbordamiento factorial:
```dart
// n=0: term = 1 (identidad)
// n>0: term_n = term_{n-1} * x / n
term = term * x / n;
```

Esto evita calcular `x^n` y `n!` de forma independiente, lo que causaría desbordamiento para `n` grandes.

### Tipos de error

Para cada iteración `n`, se calculan cuatro valores de error:

| Error | Fórmula | Disponible en |
|---|---|---|
| Aproximado | `\|sum_n - sum_{n-1}\| / \|sum_n\|` | Ambos modos |
| Absoluto | `\|e^x - sum_n\|` | Solo modo absoluto |
| Relativo | `errorAbsoluto / \|e^x\|` | Solo modo absoluto |
| Porcentual | `errorRelativo × 100` | Solo modo absoluto |

En **modo aproximado**, `realValue`, `absoluteError`, `relativeError` y `percentError` son todos `double.nan`. Esto es intencional — la calculadora no computa `exp(x)`, lo que la convierte en una aproximación iterativa pura.

### Cifras significativas

Se calculan a partir del error relativo usando la fórmula estándar:
```dart
significantFigures = floor(-log10(relativeError))
```

Solo disponible en modo absoluto (requiere `relativeError`). Siempre `0` en modo aproximado.

### Criterio de parada

El ciclo se detiene en la iteración `n > 0` cuando:
- **Modo absoluto:** `absoluteError < settings.tolerance`
- **Modo aproximado:** `approxError < settings.tolerance`

`n=0` nunca es una iteración de parada por diseño — la primera comparación de error significativa requiere una iteración previa.

Si ninguna iteración satisface el criterio, el ciclo termina en `maxIterations` y devuelve el estado final.

### Resultado

`CalculationResult` contiene:
- `finalValue` — la última suma parcial calculada
- `realValue` — `exp(x)` o `double.nan`
- `iterations` — número total de iteraciones ejecutadas
- `history` — `List<IterationData>` con la traza completa

`history.length == iterations` siempre es verdadero.

---

## 4. Manejo de estado

**Archivo:** `lib/ui/state/settings_notifier.dart`

La app usa `InheritedNotifier<SettingsNotifier>` — un patrón core de Flutter que combina un `InheritedWidget` (para propagación) con un `ChangeNotifier` (para reactividad). Sin paquetes de terceros.
```
App (StatefulWidget)
└── SettingsScope (InheritedNotifier<SettingsNotifier>)
    └── MaterialApp
        ├── HomePage
        └── SettingsPage
```

### SettingsScope

`SettingsScope` envuelve `InheritedNotifier` y expone un único acceso estático:
```dart
static SettingsNotifier of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
```

Cualquier widget que llame `SettingsScope.of(context)` se suscribe a los cambios y se reconstruye automáticamente cuando se llama `notifyListeners()`.

### SettingsNotifier

- Mantiene un único objeto de valor inmutable `Settings`
- El setter `settings` dispara `notifyListeners()` inmediatamente, luego ejecuta `_save()` de forma asíncrona
- `_load()` se llama en el constructor y llama `notifyListeners()` después de leer del disco
```dart
set settings(Settings s) {
  _settings = s;
  notifyListeners(); // La UI se actualiza inmediatamente
  _save(s);          // La escritura al disco ocurre en segundo plano
}
```

### Settings

`Settings` es una clase de valor inmutable con `copyWith`. Todos los campos tienen valores por defecto:

| Campo | Tipo | Por defecto |
|---|---|---|
| `maxIterations` | `int` | `100` |
| `tolerance` | `double` | `1e-6` |
| `toleranceType` | `ToleranceType` | `.absolute` |
| `showRealValue` | `bool` | `true` |
| `decimalPrecision` | `int` | `12` |

---

## 5. Persistencia

**Archivo:** `lib/ui/state/settings_notifier.dart`

Los ajustes se persisten en `SharedPreferences` usando claves individuales por campo.

### Carga

Al iniciar, `_load()` lee todas las claves y llama `_settings.copyWith(...)`. Si una clave no existe (primera instalación, datos borrados), `copyWith` recibe `null` para ese campo, lo que preserva el valor por defecto de `Settings()`. No se requiere lógica de fallback.
```dart
final index = _prefs!.getInt('toleranceType');
_settings = _settings.copyWith(
  toleranceType: index != null ? ToleranceType.values[index] : null,
  // null → copyWith conserva el valor por defecto
);
```

`ToleranceType` se almacena como su entero `.index` para evitar fragilidad con cadenas de texto.

### Guardado

Las escrituras se paralelizan con `Future.wait` — los cinco campos se escriben simultáneamente en lugar de secuencialmente:
```dart
await Future.wait([
  _prefs!.setInt('maxIterations', s.maxIterations),
  _prefs!.setDouble('tolerance', s.tolerance),
  _prefs!.setInt('toleranceType', s.toleranceType.index),
  _prefs!.setBool('showRealValue', s.showRealValue),
  _prefs!.setInt('decimalPrecision', s.decimalPrecision),
]);
```

La instancia de `SharedPreferences` se cachea en `_prefs` para evitar llamadas repetidas a `getInstance()`.

---

## 6. Arquitectura de UI

### Estructura de páginas

Ambas páginas usan `CustomScrollView` con slivers:
```
CustomScrollView
├── AlgexSliverAppBar    (fijo)
├── InputSliver          (solo home)
├── ResultSummaryCard    (home, condicional)
├── ModeToggle           (home, condicional)
└── IterationsView / Charts  (home, condicional)
```

`AlgexSliverAppBar` acepta un parámetro `showBackButton` en lugar de llamar `Navigator.canPop()` en tiempo de construcción — esto evita valores desactualizados cuando el estado del navigator no dispara una reconstrucción.

### Decisiones de jerarquía de widgets

**`AdjustConvergence`** es `StatefulWidget` porque gestiona dos `TextEditingController`s que deben sincronizarse con el notifier cuando los ajustes cambian externamente (ej. botón de restablecer). La sincronización se hace vía `_notifier.addListener(_syncControllers)`, configurado en `initState` a través de `addPostFrameCallback` (el context no está disponible antes del primer frame).

**`AdjustVisualization`** sigue el mismo patrón para su único controller de precisión.

### Snapshot de `_usedTolerance`

`HomePage` captura la tolerancia en el momento del cálculo en `_usedTolerance`. Esto evita que los colores de error mostrados cambien si el usuario modifica la tolerancia después de un cálculo, ya que los umbrales de color usan `tolerance` como punto de referencia.

### Configuración de ventana (escritorio)

En escritorio, `window_manager` establece un tamaño mínimo de ventana al inicio:
```dart
WindowOptions windowOptions = const WindowOptions(
  minimumSize: Size(300, 600),
);
```

Esto garantiza que el layout responsivo siempre tenga espacio suficiente para renderizar correctamente. El tamaño mínimo de 300px permite que el toggle de modo alcance su estado de solo íconos en el límite inferior.

---

## 7. Sistema de gráficas

**Archivo:** `lib/ui/widgets/charts/chart_card.dart`

Las cuatro gráficas comparten un único widget base `ChartCard` y un conjunto de funciones libres.

### ChartCard

Renderiza una `BaseCard` con título, leyenda y un `LayoutBuilder` que pasa el ancho disponible al constructor de la gráfica:
```dart
ChartCard(
  title: 'Título de la gráfica',
  legend: [...],
  chartBuilder: (width) {
    final xInterval = chartXInterval(width, pointCount);
    return LineChart(...);
  },
)
```

### Helpers compartidos

| Función | Propósito |
|---|---|
| `chartAutoInterval(series)` | Calcula el intervalo del eje Y desde el rango de datos / 5 |
| `chartXInterval(width, count)` | Limita las etiquetas del eje X a ~40px cada una para evitar solapamiento |
| `chartValidSpots(spots)` | Filtra valores Y de tipo NaN o Infinito |
| `chartTitles(...)` | Construye `FlTitlesData` con etiquetas inferior e izquierda |
| `chartBorder` | Getter de borde estándar |
| `chartGrid(...)` | Grid estándar con ambos ejes |

### Las cuatro gráficas

| Gráfica | Datos | Notas |
|---|---|---|
| `ConvergenceChart` | `partialSum` vs iteración | Agrega línea de referencia del valor real si está disponible |
| `ErrorChart` | `log₁₀(\|approxError\|)` y `log₁₀(\|relativeError\|)` | Escala logarítmica para visibilidad entre órdenes de magnitud |
| `TermDecayChart` | `log₁₀(\|term\|)` | Muestra el decaimiento exponencial de cada término |
| `SignificantFiguresChart` | `significantFigures` y `−log₁₀(relativeError)` | Muestra la relación de convergencia; solo modo absoluto |

`ChartUnavailable` se muestra cuando una gráfica no puede renderizarse en el modo actual.

---

## 8. Diseño responsivo

La app usa `LayoutBuilder` en tres niveles:

### Área de entrada (`input_sliver.dart`)
- `< 400px` → columna apilada (campo de texto encima del botón)
- `≥ 400px` → fila con proporción flex 3:2

### Cards de resultado y métricas (`result_summary_card.dart`, `iterations_view.dart`)
- `< 600px` → columna única, divisor entre tiles de info y de error
- `≥ 600px` → fila de dos columnas con flex igual

### Toggle de modo (`mode_toggle.dart`)
- Cada item recibe `maxWidth / 2` de espacio
- `< 150px` por item → solo ícono
- `≥ 150px` por item → ícono + etiqueta

---

## 9. Pruebas

**Archivo:** `test/exp_calculator_test.dart`

Las pruebas están organizadas en seis grupos:

| Grupo | Qué cubre |
|---|---|
| `exactitud` | Corrección matemática para x ∈ {0, 1, −1, 2, −3, 10} |
| `tolerancia absoluta` | `realValue`, criterio de parada, monotonicidad del error, `percentError = relativeError × 100`, NaN en n=0 |
| `tolerancia aproximada` | Todos los campos de valor real son NaN, criterio de parada, razonabilidad del resultado |
| `estructura` | `iterations == history.length`, `finalValue == history.last.partialSum`, `n` secuencial, `maxIterations` respetado, mínimo 2 iteraciones |
| `significantFigures` | Crece con las iteraciones en modo absoluto, siempre 0 en modo aproximado |
| `Settings.copyWith` | Todos los campos cambiables independientemente, ningún campo se pierde sin argumento |

Ejecutar con:
```bash
flutter test
```

---

## 10. Deuda técnica

### Sin soporte a dark mode

El tema está configurado con `brightness: Brightness.light` fijo y no hay `darkTheme` ni `ThemeMode.system`. En dispositivos con dark mode activado la app muestra el tema claro forzado.

### `significantFigures` indefinido cuando el error es exactamente cero

Cuando `relativeError == 0.0`, la condición `relativeError > 0` falla y `significantFigures` retorna `0` en lugar de reflejar convergencia perfecta. El valor semánticamente correcto para error cero no está definido en el modelo actual.

### Calculadora limitada a e^x

La arquitectura de `Settings`, `CalculationResult` e `IterationData` es genérica, pero `ExpCalculator` está acoplado a una única función. Extender la app a otras series de Taylor requeriría refactorizar el servicio y posiblemente introducir una abstracción del tipo `SeriesCalculator`.
