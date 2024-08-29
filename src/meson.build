musys_lang_deps = [
    dependency('gee-0.8'),
    dependency('libvala-0.56'),
    libmusys_dep,
]

musys_lang_src = files([
    'irgen/type-mapping.vala',
    'irgen/symbol-mapping.vala',
    'irgen/exprgen.vala',
    'irgen/generator.vala',
    'main.vala',
])

musys_lang_exe = executable(
    'musys-lang',
    sources: musys_lang_src,
    dependencies: musys_lang_deps,
    install: true,
)

message(musys_lang_exe.name())