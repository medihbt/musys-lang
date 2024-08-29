project('musys-lang', ['c', 'vala'], version: '0.0.1')

libmusys_proj = subproject('musys')
libmusys_dep  = libmusys_proj.get_variable('musys_dep')
libmusys_inc = libmusys_proj.get_variable('musys_include')

subdir('src')
