# Local MSVC 14.4 compatibility overlay

Source: microsoft/vcpkg, tag 2023.04.15, commit
`501db0f17ef6df184fcdbfbe0f87cde2313b6ab1`, port
`boost-modular-build-helper` (tree `5c1a238cc20c885e785bc05a36b974deb5e02db7`).

Only functional change: normalize the `vc144` library suffix to `vc140`, just
as upstream already normalizes `vc141`, `vc142`, and `vc143`. This lets the
old Boost packaging find its atomic dependency with VS2022 17.14.
No executable is renamed, and no Windows application-control setting changes.
See LICENSE.txt for the vcpkg license.
