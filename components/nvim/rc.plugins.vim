let s:dein_plugin_path = 'rc.plugins'
let s:plugins = keys(dein#get())

augroup plugin_hook
    autocmd!
augroup END

function s:_hook_path(plugin)
    return s:dein_plugin_path.'/'.a:plugin.'-after.vim'
endfunction

function s:_conf_path(plugin)
    return s:dein_plugin_path.'/'.a:plugin.'.vim'
endfunction

function s:register_hook(plugin)
    execute 'autocmd plugin_hook User' 'dein#source#'.a:plugin.
                \ ' source '.s:_hook_path(a:plugin)
endfunction

call map(deepcopy(s:plugins), 's:register_hook(v:val)')
let s:conf_paths = map(deepcopy(s:plugins), 's:_conf_path(v:val)')
for item in map(deepcopy(s:plugins), 's:_conf_path(v:val)')
    execute "runtime ".item
endfor

