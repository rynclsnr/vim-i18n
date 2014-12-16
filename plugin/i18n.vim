let s:install_path=expand("<sfile>:p:h")

function! I18nTranslateString()
  " copy last visual selection to x register
  normal gv"xy
  let text = s:removeQuotes(s:strip(@x))
  let variables = s:findInterpolatedVariables(text)
  let key = s:askForI18nKey(s:generateI18nKey(text))
  let fullKey = s:determineFullKey(key)
  let @x = s:generateI18nCall(key, variables, "t('", "')")
  call s:addStringToYamlStore(text, fullKey)
  " replace selection
  normal gv"xp
endfunction

function! s:removeQuotes(text)
  let text = substitute(a:text, "^[\\\"']", "", "")
  let text = substitute(text, "[\\\"']$", "", "")
  return text
endfunction

function! s:strip(text)
  let text = substitute(a:text, "^\\s+", "", "g")
  let text = substitute(a:text, "\\s+$", "", "g")
  return text
endfunction

function! s:findInterpolatedVariables(text)
  let interpolations = []
  " match multiple occurrences of %{XXX} and fill interpolations with XXX
  call substitute(a:text, "\\v\\%\\{([^\\}]\+)\\}", "\\=add(interpolations, submatch(1))", "g")
  return interpolations
endfunction

function! s:generateI18nCall(key, variables, pre, post)
  if len(a:variables) ># 0
    return a:pre . a:key . "', " . s:generateI18nArguments(a:variables) . a:post
  else
    return a:pre . a:key . a:post
  endif
endfunction

function! s:generateI18nArguments(variables)
  let arguments = []
  for interpolation in a:variables
    call add(arguments, interpolation . ": ''")
  endfor
  return join(arguments, ", ")
endfunction

function! s:generateI18nKey(text)
  let text = substitute(a:text, "[~`!@#%&,=;'’:><//}//{/\"\\|\\.\\*\\-\\$\\^\\[\\]\\(\\)\\?]", "", "g")
  let text = substitute(text, "\\v\\s", "_", "g")
  let text = strpart(text, 0, 60)
  let text = "." . text
  return text
endfunction

function! s:askForI18nKey(key)
  call inputsave()
  let key = a:key
  let key = input('I18n key: ', key)
  call inputrestore()
  return key
endfunction

function! s:determineFullKey(key)
  if match(a:key, '\.') == 0
    let controller = expand("%:h:t")
    let view = substitute(expand("%:t:r:r"), '^_', '', '')
    let fullKey = controller . '.' . view . a:key
    return fullKey
  else
    return a:key
  end
endfunction

function! s:addStringToYamlStore(text, key)
  let yaml_path = s:askForYamlPath()
  let cmd = s:install_path . "/add_yaml_key '" . yaml_path . "' '" . a:key . "' '" . a:text . "'"
  call system(cmd)
endfunction

function! s:askForYamlPath()
  call inputsave()
  let path = ""
  if exists('g:I18nYamlPath')
    let path = g:I18nYamlPath
  else
    let path = input('YAML store: ', 'config/locales/en.yml', 'file')
    let g:I18nYamlPath = path
  endif
  call inputrestore()
  return path
endfunction

vnoremap <leader>z :call I18nTranslateString()<CR>
