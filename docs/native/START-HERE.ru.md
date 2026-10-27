# Возврат к оригинальному Engine Simulator

## Текущий статус

**Текущая модернизированная нативная версия принята пользователем как хорошая
и приемлемая 2026-10-27.** Начните с [ACCEPTED-VERSION.ru.md](ACCEPTED-VERSION.ru.md):
там состав версии, команда запуска, результаты тестов и границы принятия.
Ниже сохранена история подготовки исходного baseline; её ранние формулировки
«ещё не подтверждено» не описывают текущий принятый статус.

Следующее отдельное направление — Ubuntu-сервер без звука и веб-интерфейс
для 2–3 пользователей: [../server/PLAN.ru.md](../server/PLAN.ru.md).

Главная цель текущего направления — выбор популярных двигателей, переставляемые
панели показателей, исторические и комбинированные графики. Последовательность
этапов и критерии готовности записаны в [PLAN.ru.md](PLAN.ru.md): сначала меню
выбора двигателя, затем RPM во времени и дальнейшая настройка панелей.

JS-порт остановлен по решению пользователя. Его история сохранена в ветке
`feat/js-port` (последний commit `0753beb`); ничего из неё не удалено/reset.
Оставшиеся локальные web dependency/build/diagnostic файлы сохранены и исключены
через /web/ в .gitignore нативной ветки, не удалены рекурсивно.
Активное направление — `feat/native-modernization`, созданное от исходного
`master` distribution-репозитория. Python не заменяет физику.

## Исходная программа

Открытый C++ оригинал `https://github.com/ange-yaghi/engine-sim` подключён как
Git submodule `native/`, закреплён на
`85f7c3b959a908ed5232ede4f1a4ac7eafe6b630`. Внутри локальная ветка `modernization`.
Это настоящий исходный solver/движок/DSP/UI, не JS-реализация и не исходники
закрытой Community Edition. Этот commit — исходная база; поверх неё теперь есть
локальные доработки принятой версии, перечисленные в ACCEPTED-VERSION.ru.md.

После обычного клонирования внешнего репозитория:

```powershell
git submodule update --init native
```

Вложенные dependencies оригинала при первом подключении не были инициализированы;
актуальная setup проверка ниже. Нужны отдельная проверка версий/лицензий и build
prerequisites, прежде чем запускать сборку.
MIT LICENSE основного upstream не является автоматической лицензией на каждый
звук/шрифт/графический ресурс или каждую зависимость. Мы не переиздаём эти assets.
Исторический Piranha licensing вопрос из предыдущего направления сохраняется
для будущего распространения; его нельзя выдавать за решённый.

## Первый обязательный milestone — запускаемая baseline-сборка

1. Найти/подготовить Windows C++ toolchain и CMake по native/README.md.
2. Проверить pinned зависимости и необходимые внешние SDK.
3. Собрать исходную программу БЕЗ изменения физики или UI.
4. Запустить исходный engine example и проверить изображение, звук и controls.
5. Только затем модернизировать интерфейс/настройки/загрузку моделей небольшими
   пакетами, сохраняющими рабочий desktop baseline. Realtime JS gate отменён
   как текущая задача, но нативная сборка здесь ещё не принята.

Начальная проверка: `cmake` и `cl` не найдены в PATH; Visual Studio locator
`vswhere.exe` не найден в стандартном расположении. Это не полный census всего
диска и не доказательство, что компилятор нигде не установлен. Готовая сборка
из Community Edition release может служить пользовательским baseline, но её
закрытый код нельзя модифицировать как C++ source.

Полная Release-сборка завершена; приложение запущено и окно отвечает. Изображение,
звук и управление ещё не подтверждены. Прежнюю Windows application-control блокировку
native test executable не обходить; если она затронет новую сборку, потребуется
разрешённая execution environment, а не отключение защиты агентом.

## Локальные изменения и коммиты

Изменения приложения делаются внутри `native/` и коммитятся сначала там;
затем внешний репозиторий фиксирует новый submodule pointer. Сейчас оба
репозитория используют локальные коммиты, push не выполняется. Перед будущей
публикацией потребуется собственный source fork/remote для новых native commits:
upstream remote автоматически не заменяется и туда не отправляются наши изменения.

## 2026-10-11 — разрешённая установка build prerequisites

Пользователь разрешил установку C++ Build Tools. Microsoft winget package
Microsoft.VisualStudio.2022.BuildTools 17.14.41 установлен с workload VCTools,
CMake tools, recommended components и --norestart. Подтверждены MSVC 19.44,
Windows SDK 10.0.26100.0 и CMake 3.31.6. Перезагрузка не требуется.
Защита Windows не отключается.

Pinned upstream submodules delta-studio/simple-2d-constraint-solver/csv-io/piranha
инициализированы в native/ без изменения их кода/gitlinks. direct-to-video также
инициализирован: оригинал требует его headers даже при DTV=OFF, без сборки encoder.
Это загрузка исходных build dependencies, не clearance
Piranha/assets для распространения нового executable.

Локальный Microsoft vcpkg подготовлен в .native-tools/vcpkg (исключён из git),
bootstrap проверил подпись executable, metrics отключены. Dependency manifest
tools/native/vcpkg.json фиксирует baseline 2023.04.15; custom triplet сохраняет
dynamic CRT и static Boost, как требует upstream. Compatibility/build пока не приняты.
Команда установки локального Boost:

```powershell
& .\.native-tools\vcpkg\vcpkg.exe install --x-manifest-root=tools/native --x-install-root=.native-tools/packages-baseline --overlay-triplets=tools/native/triplets --overlay-ports=tools/native/ports --triplet=x64-engine-sim --disable-metrics
```

WinFlexBison user-scope установка через winget превысила timeout и не считается
успешной. Вместо неё официальный portable ZIP 2.5.25 извлечён локально после
проверки SHA256 из winget manifest. win_flex 2.6.4 / win_bison 3.8.2 запускаются.
URL и hashes SDK записаны в tools/native/sdk-sources.json.

Первый vcpkg baseline (2026) собрал Boost 1.92, но SDL installation остановилась:
Windows application-control блокирует вспомогательный pkg-config.exe. Защиту
не обходили; вместо этого загружены официальные Visual C++ SDK SDL 2.32.10 и
SDL_image 2.8.12 с проверкой SHA256. Они не требуют pkg-config для этого проекта.

Первый CMake configure прошёл, физическое ядро engine-sim.lib собралось. Полная
сборка остановилась на Piranha src/path.cpp: Boost 1.92 удалил is_complete().
Исходники не правились: выбран vcpkg baseline 2023.04.15 для совместимого Boost.
Новый install root packages-baseline сохраняет предыдущие libraries отдельно;
новый build directory native/build/baseline исключает старый CMake cache.

Boost 1.82 packaging первоначально остановился: старый build helper ищет
boost_atomic-vc140-mt-gd.lib, но MSVC 14.4 создал boost_atomic-vc144-mt-gd.lib.
Локальный overlay tools/native/ports/boost-modular-build-helper добавляет vc144
в существующую нормализацию имён static libraries. Источник и MIT license
сохранены рядом. Это исправление packaging, не изменение приложения и не
переименование executable для обхода защиты. Повторная установка завершилась
успешно: Boost 1.82 установлен. Piranha и script interpreter собраны; затем
build остановился на отсутствующем direct-to-video/include/dtv.h. Закреплённый
submodule загружен, повторная сборка запущена. Исходники приложения не менялись.

`tools/native/build-baseline.ps1` собирает VS2022/x64, PIRANHA=ON, DTV=OFF,
Discord=OFF и проверяет exit codes. Физика/UI не менялись. Запуск приложения,
изображение, звук и controls ещё не подтверждены. При запуске используются
relative ../assets и ../dependencies: рабочая директория должна быть native/build,
а не папка Release с exe. Наличие exe само по себе не означает принятую сборку.

Последняя проверка: полный engine-sim-app.exe собран без изменений source.
Первый запуск завершился 0xC0000135 (missing DLL); dumpbin обнаружил импорт
d3dx10d_43.dll, отсутствующий в System32. run-baseline.ps1 копирует оригинальную
x64 DLL из pinned delta-studio runtime вместе с SDL SDK DLL, не перезаписывая
отличающиеся файлы. Повторный запуск жив через 10 секунд, окно Engine Sim v0.1.12a
отвечает. Проверка изображения/аудио/controls остаётся открытой.
