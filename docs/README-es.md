# algex 📐

Aplicación Flutter que aproxima **e^x** usando el método de series de Taylor, con configuración de convergencia, análisis de errores y cuatro gráficas de convergencia en tiempo real.

---

## 🚀 Descripción general

algex implementa la expansión en serie de Taylor de e^x desde cero — sin librerías matemáticas externas — con control total sobre el criterio de convergencia, tolerancia y precisión. El motor de cálculo es Dart puro, completamente desacoplado de Flutter, y cubierto por pruebas unitarias.

Incluye:

- Calculadora de series de Taylor con dos modos de convergencia
- Análisis de error por iteración (absoluto, relativo, aproximado, porcentual)
- Seguimiento de cifras significativas por iteración
- Cuatro gráficas de convergencia renderizadas con fl_chart
- Ajustes persistentes vía SharedPreferences
- Layout responsivo con breakpoints para pantallas compactas y anchas

---

## 🎥 Demo

| Vista móvil | Vista escritorio |
|---|---|
| ![Versión móvil](demo/mobile.gif) | ![Versión escritorio](demo/desktop.gif) |
---

## ✨ Funciones visibles

- Ingresa cualquier valor real de x y calcula e^x por serie de Taylor
- Alterna entre convergencia por **error absoluto** (compara contra e^x real) y **error aproximado** (compara contra iteraciones consecutivas)
- Configura el valor de tolerancia y el máximo de iteraciones
- Visualiza el desglose por iteración: suma parcial, término, todos los tipos de error, cifras significativas
- Alterna entre tabla de iteraciones y gráficas con indicador deslizante animado
- Muestra u oculta el valor real de e^x junto a la aproximación
- Configura la precisión decimal (2–12 dígitos) para todos los valores mostrados
- Los ajustes persisten entre sesiones

---

## 🧠 Highlights técnicos

- **Calculadora Dart puro**
  - `ExpCalculator` no tiene dependencias de Flutter — lógica pura
  - Cubierta por pruebas unitarias en `test/exp_calculator_test.dart`
  - Maneja NaN/Infinity correctamente en todos los tipos de error y en ambos modos de convergencia

- **Manejo de estado sin librerías externas**
  - `InheritedNotifier<SettingsNotifier>` propaga los ajustes por el árbol de widgets
  - Sin Riverpod, sin Bloc, sin Provider — solo APIs core de Flutter
  - `SettingsScope.of(context)` para acceso limpio a cualquier profundidad

- **Persistencia**
  - Ajustes cargados asincrónicamente al inicio vía `SharedPreferences`
  - Escrituras paralelizadas con `Future.wait` — sin I/O de disco secuencial
  - Patrón `copyWith` mantiene los valores por defecto en un solo lugar en `Settings`

- **UI responsiva**
  - Breakpoints con `LayoutBuilder` en 400px (input), 600px (cards y métricas)
  - `ModeToggle` se colapsa a solo ícono por debajo de 150px por item
  - Todos los layouts probados en anchos compactos y anchos

- **Gráficas**
  - Cuatro gráficas comparten un único widget base `ChartCard`
  - Helpers compartidos: `chartAutoInterval`, `chartXInterval`, `chartValidSpots`, `chartTitles`, `chartBorder`, `chartGrid`
  - Intervalo del eje X calculado automáticamente desde el ancho disponible para evitar solapamiento de etiquetas
  - Fallback `ChartUnavailable` para modos donde el dato no es computable

---

## 🎯 Qué demuestra este proyecto

- Manejo de estado con `InheritedWidget` + `ChangeNotifier` sin paquetes de terceros
- Separación limpia entre lógica Dart pura (`core/`) y UI Flutter (`ui/`)
- Pruebas unitarias de lógica matemática con cobertura de casos borde
- Diseño de layout responsivo con `LayoutBuilder` y breakpoints
- Persistencia asíncrona con `SharedPreferences` usando escrituras paralelizadas
- Widgets animados personalizados: `AnimatedContainer`, `AnimatedAlign`, `TweenAnimationBuilder`
- Arquitectura de scroll basada en slivers (`CustomScrollView`, `SliverList`, `SliverAppBar`)

---

## 🏗 Arquitectura

El proyecto separa la lógica pura de la UI en dos capas independientes (ui + core).

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

➡️ Ver documentación técnica completa: [technical.md](technical.md)

---

## ⚙️ Instalación rápida

### Requisitos

- Flutter SDK `>=3.3.4`
- Dispositivo o emulador

### Clonar y ejecutar

```bash
git clone https://github.com/tristecsv/algex.git
cd algex

flutter pub get
dart run flutter_launcher_icons
flutter run
```

### Ejecutar pruebas

```bash
flutter test
```
