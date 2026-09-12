" Personal workbench v1-lite. Space + one key. See DEPLOY.md.
set nocompatible
scriptencoding utf-8
let g:kit_config = expand('<sfile>:p')
let mapleader = ' '
let g:kit_gap = get(g:, 'kit_gap', 2)
let g:kit_dark = get(g:, 'kit_dark', 1)
set encoding=utf-8 hidden confirm autoread
set fileencodings=utf-8,gb18030,latin1
set number relativenumber cursorline signcolumn=yes
set wrap linebreak breakindent
let &showbreak = '↪ '
set colorcolumn= laststatus=2 noshowmode showcmd
set mouse=a ttymouse=sgr
set splitbelow splitright scrolloff=5 sidescrolloff=8
set expandtab tabstop=4 softtabstop=4 shiftwidth=4 shiftround
set autoindent backspace=indent,eol,start virtualedit=block
set ignorecase smartcase incsearch hlsearch
set wildmenu wildmode=longest:full,full wildoptions=pum
set completeopt=menuone,noinsert,noselect pumheight=12
set list listchars=tab:»·,trail:·,nbsp:␣
let &fillchars = 'vert:│,fold: ,eob: '
set nofoldenable
set undofile undolevels=10000 history=1000
set writebackup nobackup updatetime=300
set timeout timeoutlen=500 ttimeout ttimeoutlen=50
let s:state = expand('~/.vim/kit-state')
for s:dir in ['undo', 'swap', 'backup']
  call mkdir(s:state . '/' . s:dir, 'p', 0700)
endfor
let &undodir = s:state . '/undo//'
let &directory = s:state . '/swap//'
let &backupdir = s:state . '/backup//'
if exists('+termguicolors') && ($COLORTERM =~# 'truecolor\|24bit' || $TERM =~# '256color')
  set termguicolors
endif
filetype plugin indent on
" The theme is embedded here, not an external colors/kit.vim file.
if get(g:,'colors_name','')==#'kit' | unlet g:colors_name | endif
syntax enable

function! KitTheme() abort
  let &background = g:kit_dark ? 'dark' : 'light'
  highlight clear
  let l:bg = g:kit_dark ? '#111827' : '#f5f5f0'
  let l:fg = g:kit_dark ? '#d7deea' : '#253249'
  execute 'hi Normal guifg=' . l:fg . ' guibg=' . l:bg . ' ctermfg=' . (g:kit_dark ? 253 : 235) . ' ctermbg=' . (g:kit_dark ? 234 : 255)
  hi Comment guifg=#8192ab gui=NONE ctermfg=103 cterm=NONE
  hi Statement guifg=#b48cdb gui=bold ctermfg=140 cterm=bold
  hi Type guifg=#58a6bb ctermfg=73
  hi Constant guifg=#cf955c ctermfg=173
  hi String guifg=#81ad75 ctermfg=108
  hi PreProc guifg=#bd9d52 ctermfg=179
  hi Function guifg=#729fd6 ctermfg=110
  hi Identifier guifg=NONE ctermfg=NONE
  hi Operator guifg=NONE ctermfg=NONE
  hi Delimiter guifg=NONE ctermfg=NONE
  hi Special guifg=#58a6bb ctermfg=73
  hi MatchParen guifg=#d6aa58 guibg=NONE gui=bold,underline ctermfg=179 ctermbg=NONE cterm=bold,underline term=underline
  hi LineNr guifg=#62738a ctermfg=60
  hi CursorLineNr guifg=#d6aa58 gui=bold ctermfg=179
  execute 'hi CursorLine guibg=' . (g:kit_dark ? '#192337' : '#e8eaf0') . ' ctermbg=' . (g:kit_dark ? 235 : 254) . ' gui=NONE cterm=NONE'
  hi SignColumn guibg=NONE ctermbg=NONE
  hi StatusLine guifg=#d7deea guibg=#293b56 ctermfg=253 ctermbg=24 gui=NONE cterm=NONE
  hi StatusLineNC guifg=#8192ab guibg=#202b3e ctermfg=103 ctermbg=236 gui=NONE cterm=NONE
  hi VertSplit guifg=#62738a guibg=NONE ctermfg=60 ctermbg=NONE
  hi Visual guibg=#3b526e ctermbg=24
  hi Search guifg=#111827 guibg=#d6aa58 ctermfg=234 ctermbg=179
  hi IncSearch guifg=#111827 guibg=#efac73 ctermfg=234 ctermbg=215
  hi Pmenu guifg=#d7deea guibg=#293b56 ctermfg=253 ctermbg=24
  hi PmenuSel guifg=#111827 guibg=#8db5e8 ctermfg=234 ctermbg=110
  hi Folded guifg=#8192ab guibg=NONE ctermfg=103 ctermbg=NONE
  hi NonText guifg=#62738a ctermfg=60
  hi SpecialKey guifg=#62738a ctermfg=60
  hi Error guifg=#ef8089 gui=underline ctermfg=210 cterm=underline
  hi Todo guifg=#d6aa58 guibg=NONE ctermfg=179 ctermbg=NONE
endfunction
call KitTheme()
function! KitStatus() abort
  return toupper(mode()) . '  ' . expand('%:~:.') . (&modified ? ' [+]' : '')
endfunction
let &statusline = '%{KitStatus()}%=%{&filetype} · %{&shiftwidth}空格 · %{&encoding}  %l:%c '
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_winsize = 25

" Clipboard: direct desktop clipboard first; OSC52 via tmux only as fallback.
function! KitClipCommand(read) abort
  if !empty($WAYLAND_DISPLAY) && executable(a:read ? 'wl-paste' : 'wl-copy')
    return a:read ? 'wl-paste --no-newline' : 'wl-copy > /dev/null 2>&1'
  endif
  let l:x = executable('xclip') ? 'xclip' : expand('~/.local/bin/xclip')
  if !empty($DISPLAY) && executable(l:x)
    return shellescape(l:x) . ' -selection clipboard ' . (a:read ? '-o' : '-i > /dev/null 2>&1')
  endif
  if executable(a:read ? 'pbpaste' : 'pbcopy')
    return a:read ? 'pbpaste' : 'pbcopy'
  endif
  return ''
endfunction
function! KitCopy(text) abort
  let l:cmd = KitClipCommand(0)
  if !empty(l:cmd)
    call system(l:cmd, a:text)
    if v:shell_error | echoerr '剪贴板写入失败，请检查 xclip/wl-copy 等剪贴板工具' | return | endif
    echo '已复制到系统剪贴板'
  elseif has('clipboard')
    call setreg('+', a:text)
  elseif !empty($TMUX) && executable('tmux')
    call system('tmux load-buffer -', a:text)
    call system('tmux set-buffer -w -- ' . shellescape(a:text))
    echo '已发送 OSC52；是否写入系统剪贴板取决于外层终端'
  else
    echoerr '无系统剪贴板工具；文本仍在 Vim 寄存器中'
  endif
endfunction
function! KitPaste() abort
  let l:cmd = KitClipCommand(1)
  if !empty(l:cmd)
    let l:text = system(l:cmd)
    if v:shell_error | echoerr '读取剪贴板失败' | return | endif
  elseif has('clipboard')
    let l:text = getreg('+')
  else
    echoerr '无法读取系统剪贴板' | return
  endif
  let l:save = getreginfo('z')
  call setreg('z', l:text)
  normal! "zp
  call setreg('z', l:save)
endfunction
" All yanks share one clipboard hook, including mouse release and Space-y.
xnoremap <silent> <LeftRelease> y
function! KitYankToClipboard() abort
  if get(v:event,'operator','')!=#'y' || get(v:event,'regname','')==#'_' | return | endif
  let l:text=join(v:event.regcontents,"\n")
  if v:event.regtype==#'V' | let l:text.="\n" | endif
  call KitCopy(l:text)
endfunction

" Pair insertion. Respect paste mode and syntax comments/strings.
function! KitIgnored(ln, col) abort
  return synIDattr(synID(a:ln, max([1,a:col]), 1), 'name') =~? 'comment\|string'
endfunction
function! KitPair(ch) abort
  let l:next = strpart(getline('.'), col('.')-1, 1)
  if l:next ==# a:ch && a:ch =~# '[])}"]' | return "\<Right>" | endif
  if &paste || KitIgnored(line('.'), col('.')-1) | return a:ch | endif
  let l:pairs = {'(':')', '[':']', '{':'}', '"':'"'}
  return has_key(l:pairs,a:ch) ? a:ch . l:pairs[a:ch] . "\<Left>" : a:ch
endfunction
function! KitBS() abort
  let l:pair = strpart(getline('.'), max([0,col('.')-2]), 2)
  return col('.') > 1 && index(['()', '[]', '{}', '""'], l:pair)>=0 ? "\<BS>\<Del>" : "\<BS>"
endfunction
function! KitEnter() abort
  let l:left = strpart(getline('.'),0,col('.')-1)
  let l:right = strpart(getline('.'),col('.')-1)
  if l:left =~# '{$' && l:right =~# '^}'
    return "\<CR>" . (&ft ==# 'ld' && indent('.')>0 ? "\<C-t>" : '') . "\<Esc>O"
  endif
  if &ft =~# 'verilog' && l:left =~# ';\s*$' && l:right =~# '^\s*$' && !KitIgnored(line('.'),col('.')-1)
    let l:pos=getpos('.')
    let l:module=search('^\s*module\>', 'bnWc')
    if l:module
      let l:header=(l:module<line('.') ? join(getline(l:module,line('.')-1),"\n")."\n" : '').l:left
      " Only the first terminating semicolon of a module header triggers this.
      if substitute(l:header,';\s*$','','') !~# ';'
        call cursor(l:module,match(getline(l:module),'\<module\>')+1)
        let l:end=searchpair('\<module\>','','\<endmodule\>','nW','KitIgnored(line("."),col("."))')
        call setpos('.',l:pos)
        if !l:end | return "\<CR>endmodule\<Esc>O" | endif
      endif
    endif
    call setpos('.',l:pos)
  endif
  if &ft =~# 'verilog' && l:left =~# '\<begin\>\s*\%(:\s*\w\+\)\?$' && !KitIgnored(line('.'),col('.')-1)
    let l:pos = getpos('.')
    let l:start = match(l:left, '\<begin\>')+1
    call cursor(line('.'),l:start)
    let l:end = searchpair('\<begin\>', '', '\<end\>', 'nW', 'KitIgnored(line("."),col("."))')
    call setpos('.',l:pos)
    if !l:end | return "\<CR>end\<Esc>O" | endif
  endif
  return "\<CR>"
endfunction
function! KitPairs() abort
  for l:ch in ['(',')','[',']','{','}','"']
    execute 'inoremap <buffer> <expr> ' . (l:ch=='"' ? '<Char-34>' : l:ch) . ' KitPair(' . string(l:ch) . ')'
  endfor
  inoremap <buffer> <expr> <BS> KitBS()
  inoremap <buffer> <CR> <C-r>=KitEnter()<CR>
endfunction


function! KitModuleBuild() abort
  let l:n=line('.')
  let l:ind=matchstr(getline('.'),'^\s*')
  call setline(l:n,l:ind.'module (')
  silent! undojoin
  call append(l:n,[l:ind.repeat(' ',shiftwidth()),l:ind.');','',l:ind.repeat(' ',shiftwidth()),l:ind.'endmodule'])
  call cursor(l:n,strlen(l:ind)+8)
  startinsert
endfunction
function! KitModulePorts() abort
  call cursor(line('.')+1,1)
  if getline('.') =~# '^\s*$'
    call setline('.',repeat(' ',indent(line('.')-1)+shiftwidth()))
    startinsert!
  else
    normal! ^
    startinsert
  endif
endfunction
" Small inline syntax expansions, all reached with the existing Tab key.
function! KitSyntaxForms() abort
  let l:f={
  \ 'always':['always @(<cursor>) begin','    ','end'],
  \ 'initial':['initial begin','    <cursor>','end'],
  \ 'begin':['begin','    <cursor>','end'],
  \ 'if':['if (<cursor>) begin','    ','end'],
  \ 'else':['else begin','    <cursor>','end'],
  \ 'case':['case (<cursor>)','    ','endcase'],
  \ 'casex':['casex (<cursor>)','    ','endcase'],
  \ 'casez':['casez (<cursor>)','    ','endcase'],
  \ 'default':['default: begin','    <cursor>','end'],
  \ 'for':['for (<cursor>; ; ) begin','    ','end'],
  \ 'while':['while (<cursor>) begin','    ','end'],
  \ 'repeat':['repeat (<cursor>) begin','    ','end'],
  \ 'forever':['forever begin','    <cursor>','end'],
  \ 'wait':['wait (<cursor>) begin','    ','end'],
  \ 'function':['function <cursor>;','    ','endfunction'],
  \ 'task':['task <cursor>;','    ','endtask'],
  \ 'generate':['generate','    <cursor>','endgenerate'],
  \ 'fork':['fork','    <cursor>','join'],
  \ 'assign':['assign <cursor> = ;'],
  \ 'parameter':['parameter <cursor> = ;'],
  \ 'localparam':['localparam <cursor> = ;']}
  if &ft==#'systemverilog'
    call extend(l:f,{
    \ 'always_ff':['always_ff @(<cursor>) begin','    ','end'],
    \ 'always_comb':['always_comb begin','    <cursor>','end'],
    \ 'always_latch':['always_latch begin','    <cursor>','end'],
    \ 'foreach':['foreach (<cursor>) begin','    ','end'],
    \ 'interface':['interface <cursor>;','    ','endinterface'],
    \ 'package':['package <cursor>;','    ','endpackage']})
  endif
  return l:f
endfunction
function! KitSyntaxBuild(word) abort
  let l:n=line('.')
  let l:ind=matchstr(getline('.'),'^\s*')
  let l:prefix=substitute(getline('.'),'\w\+\s*$','','')
  let l:forms=KitSyntaxForms()[a:word]
  let l:lines=[] | let l:target=[l:n,1]
  for l:i in range(len(l:forms))
    let l:s=(l:i==0?l:prefix:l:ind).l:forms[l:i]
    let l:mark=stridx(l:s,'<cursor>')
    if l:mark>=0
      let l:target=[l:n+l:i,l:mark+1]
      let l:s=substitute(l:s,'<cursor>','','')
    endif
    call add(l:lines,l:s)
  endfor
  call setline(l:n,l:lines[0])
  if len(l:lines)>1
    silent! undojoin
    call append(l:n,l:lines[1:])
  endif
  unlet! b:kit_decl
  call cursor(l:target[0],l:target[1])
  if l:target[1]>strlen(getline('.')) | startinsert! | else | startinsert | endif
endfunction
function! KitNextParameter(keyword) abort
  let l:ind=matchstr(getline('.'),'^\s*')
  let l:n=line('.')+1
  call append(line('.'),l:ind.a:keyword.'  = ;')
  unlet! b:kit_decl
  call cursor(l:n,strlen(l:ind)+strlen(a:keyword)+2)
  startinsert
endfunction
function! KitInsideBegin() abort
  let l:save=getpos('.')
  let l:start=searchpairpos('\<begin\>','','\<end\>','bnW','KitIgnored(line("."),col("."))')
  call setpos('.',l:save)
  return l:start[0]>0
endfunction
function! KitTab(back) abort
  if pumvisible() | return a:back ? "\<C-p>" : "\<C-n>" | endif
  let l:left = strpart(getline('.'),0,col('.')-1)
  let l:word = matchstr(l:left,'\w\+$')
  let l:right=strpart(getline('.'),col('.')-1)
  if &paste || KitIgnored(line('.'),col('.')-1) | return "\<Tab>" | endif
  let l:param=matchlist(getline('.'),'^\s*\(localparam\|parameter\)\s\+\w\+\s*=\s*\(.\{-}\)\s*;\s*$')
  if !a:back && !empty(l:param) && !empty(trim(l:param[2])) && (l:right =~# '^\s*;\s*$' || (l:left =~# ';\s*$' && l:right =~# '^\s*$'))
    return "\<Esc>:call KitNextParameter(".string(l:param[1]).")\<CR>"
  endif
  " Enter continues inside a begin/end block; semicolon + Tab finishes the
  " nearest block and resumes insertion at the next structural position.
  if !a:back && KitInsideBegin()
    if l:left =~# ';\s*$' && l:right =~# '^\s*\%(//.*\)\?$'
      return "\<Esc>:call KitBlock('next')\<CR>"
    endif
    if l:right =~# '^\s*;\s*\%(//.*\)\?$' && l:left =~# '\S\s*$'
      let l:skip=matchstr(l:right,'^\s*;')
      return repeat("\<Right>",strlen(l:skip))."\<Esc>:call KitBlock('next')\<CR>"
    endif
  endif
  " Leave a filled condition/name for its body; for loops have three fields.
  if l:left =~# '^\s*\%(end\s\+else\s\+\)\?for\s*(' && l:right =~# '^;\s*'
    return repeat("\<Right>",strlen(matchstr(l:right,'^;\s*')))
  endif
  if l:left =~# '^\s*\%(\%(end\s\+\)\?else\s\+\)\?\%(always\%(_ff\)\?\|if\|case[xz]\?\|for\|foreach\|while\|repeat\|wait\)\>' && (l:right =~# '^\s*)\s*\%(begin\)\?\s*$' || (l:left =~# ')\s*$' && l:right =~# '^\s*\%(begin\)\?\s*$'))
    return "\<Esc>:call KitModulePorts()\<CR>"
  endif
  if l:left =~# '^\s*\%(function\|task\|interface\|package\)\s\+\S' && l:right =~# '^;\s*$'
    return "\<Esc>:call KitModulePorts()\<CR>"
  endif
  if l:left =~# '^\s*\%(assign\|parameter\|localparam\)\s\+\w\+$' && l:right =~# '^\s\+=\s*'
    return repeat("\<Right>",strlen(matchstr(l:right,'^\s\+=\s*')))
  endif
  let l:forms=KitSyntaxForms()
  let l:keys=['always','initial','begin','if','else','case','casex','casez','default','for','while','repeat','forever','wait','function','task','generate','fork','assign','parameter','localparam']
  if &ft==#'systemverilog' | let l:keys+=['always_ff','always_comb','always_latch','foreach','interface','package'] | endif
  if strlen(l:word)>=2 && l:right =~# '^\s*$'
    let l:whole=l:left =~# '^\s*\w\+$'
    let l:inline=l:left =~# '\%()\|:\|\<else\>\)\s\+\w\+$'
    let l:afterend=l:left =~# '^\s*end\s\+\w\+$'
    let l:choices=has_key(l:forms,l:word)?[l:word]:filter(copy(l:keys),'stridx(v:val,l:word)==0')
    for l:kw in l:choices
      if l:whole || (l:inline && index(['begin','if'],l:kw)>=0) || (l:afterend && l:kw=='else')
        return "\<Esc>:call KitSyntaxBuild(".string(l:kw).")\<CR>"
      endif
    endfor
    if l:whole
      let l:ends=['endmodule','endcase','endfunction','endtask','endgenerate','end','join','posedge','negedge','genvar','integer','signed','unsigned']
      if &ft==#'systemverilog' | let l:ends+=['endinterface','endpackage','join_any','join_none'] | endif
      for l:kw in (index(l:ends,l:word)>=0?[l:word]:l:ends)
        if stridx(l:kw,l:word)==0 | return strpart(l:kw,strlen(l:word)) | endif
      endfor
    endif
  endif
  if l:left =~# '^\s*\w\+$' && strlen(l:word)>=2
    if stridx('module',l:word)==0 && !KitIgnored(line('.'),col('.')-1)
      unlet! b:kit_decl
      if strpart(getline('.'),col('.')-1) =~# '^\s*$'
        return "\<Esc>:call KitModuleBuild()\<CR>"
      endif
      return strpart('module',strlen(l:word)).' '
    endif
    for l:kw in (&ft==#'systemverilog'?['input','output','inout','wire','reg','logic']:['input','output','inout','wire','reg'])
      if stridx(l:kw,l:word)==0
        let b:kit_decl = {'ln':line('.'),'stage':0}
        return strpart(l:kw,strlen(l:word)) . repeat(' ',g:kit_gap)
      endif
    endfor
  endif
  if l:left =~# '^\s*module\s\+\w\+\s*$' && strpart(getline('.'),col('.')-1) =~# '^('
    return "\<Esc>:call KitModulePorts()\<CR>"
  endif
  if exists('b:kit_decl') && b:kit_decl.ln==line('.')
    unlet b:kit_decl
    let l:m = matchlist(l:left, '^\s*\w\+\s\+\(.*\)$')
    let l:width = empty(l:m) ? '' : trim(l:m[1])
    if empty(l:width) | return repeat(' ',16) | endif
    if l:width !~# '^\['
      return repeat("\<BS>",strchars(l:width)) . '[' . l:width . ']' . repeat(' ',g:kit_gap)
    endif
    let l:next = strpart(getline('.'),col('.')-1,1)
    return (l:next==# ']' ? "\<Right>" : '') . repeat(' ',g:kit_gap)
  endif
  return "\<Tab>"
endfunction

function! KitVerilog() abort
  let b:verilog_indent_modules=1
  call KitPairs()
  let b:match_words = '\<begin\>:\<end\>,\<case\>:\<endcase\>,\<module\>:\<endmodule\>,\<function\>:\<endfunction\>,\<task\>:\<endtask\>,\<generate\>:\<endgenerate\>'
  inoremap <buffer> <Tab> <C-r>=KitTab(0)<CR>
  inoremap <buffer> <S-Tab> <C-r>=KitTab(1)<CR>
endfunction

function! KitRow(text) abort
  let l:comment = matchstr(a:text, '\s\+//.*$')
  let l:s = trim(substitute(a:text,'\s\+//.*$','',''))
  if l:s =~# '/\*\|`\|"' | return [] | endif
  let l:term=matchstr(l:s,'[,;]$')
  let l:body=empty(l:term)?l:s:trim(strpart(l:s,0,strlen(l:s)-1))
  let l:d = matchlist(l:body, '^\(\%(input\|output\|inout\|wire\|reg\|logic\|parameter\|localparam\)\>\%(\s\+\%(signed\|unsigned\|integer\|logic\|wire\|reg\)\>\)*\)\s*\(\%(\[[^][]*\]\s*\)*\)\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\%(\s*\[[^][]*\]\)*\)\s*\(\%(=.*\)\?\)$')
  if !empty(l:d)
    if l:d[4] =~# ';' || KitTopComma(l:d[4]) | return [] | endif
    let l:width = substitute(l:d[2],'\[\s*','[','g')
    let l:width = substitute(l:width,'\s*\]',']','g')
    return ['decl',substitute(l:d[1],'\s\+',' ','g'),trim(l:width),l:d[3],empty(l:d[4])?'':'=',empty(l:d[4])?'':trim(strpart(l:d[4],1)),l:term,trim(l:comment)]
  endif
  let l:a = matchlist(l:s,'^\(\%(assign\s\+\)\?[a-zA-Z_$][a-zA-Z0-9_$]*\%(\[[^][]*\]\)*\)\s*\(<=\|=\)\s*\([^;]*\);$')
  if !empty(l:a) | return ['assign',l:a[1],l:a[2],l:a[3],';',trim(l:comment)] | endif
  let l:i = matchlist(l:s,'^\.\(\w\+\)\s*(\([^()]*\))\s*\([,]\?\)$')
  if !empty(l:i) | return ['inst','.'.l:i[1],trim(l:i[2]),l:i[3],trim(l:comment)] | endif
  let l:c=matchlist(l:s,"^\\([a-zA-Z0-9_$'?, ]\\+\\)\\s*:\\s*\\(begin\\|[^;]*;\\)$")
  if !empty(l:c) | return ['case',trim(l:c[1]),':',trim(l:c[2]),trim(l:comment)] | endif
  return []
endfunction

function! KitTopComma(text) abort
  let l:depth=0
  for l:ch in split(a:text,'\zs')
    if l:ch=~# '[([{]' | let l:depth+=1
    elseif l:ch=~# '[])}]' | let l:depth-=1
    elseif l:ch==#',' && l:depth==0 | return 1
    endif
    if l:depth<0 | return 1 | endif
  endfor
  return l:depth!=0
endfunction

function! KitRender(rows, ind) abort
  let l:rows=deepcopy(a:rows)
  if l:rows[0][0]=='decl'
    let l:dimwidths=[]
    let l:dimensions=[]
    for l:r in l:rows
      let l:dims=[] | let l:start=0
      while 1
        let l:m=matchstrpos(l:r[2],'\[[^][]*\]',l:start)
        if l:m[1]<0 | break | endif
        let l:expr=trim(strpart(l:m[0],1,strlen(l:m[0])-2))
        let l:i=len(l:dims)
        if len(l:dimwidths)<=l:i | call add(l:dimwidths,0) | endif
        let l:dimwidths[l:i]=max([l:dimwidths[l:i],strdisplaywidth(l:expr)])
        call add(l:dims,l:expr) | let l:start=l:m[2]
      endwhile
      call add(l:dimensions,l:dims)
    endfor
    for l:i in range(len(l:rows))
      let l:width=''
      for l:j in range(len(l:dimwidths))
        if l:j<len(l:dimensions[l:i])
          let l:expr=l:dimensions[l:i][l:j]
          let l:width.='['.repeat(' ',l:dimwidths[l:j]-strdisplaywidth(l:expr)).l:expr.']'
        else
          let l:width.=repeat(' ',l:dimwidths[l:j]+2)
        endif
      endfor
      let l:rows[l:i][2]=l:width
    endfor
  endif
  let l:w = repeat([0],10)
  for l:r in l:rows
    for l:i in range(1,len(l:r)-1) | let l:w[l:i]=max([l:w[l:i],strdisplaywidth(l:r[l:i])]) | endfor
  endfor
  let l:out=[]
  for l:r in l:rows
    let l:cells=copy(l:r[1:])
    let l:line=a:ind
    for l:i in range(len(l:cells))
      let l:line.=l:cells[l:i] . repeat(' ',max([0,l:w[l:i+1]-strdisplaywidth(l:cells[l:i])]))
      if l:i<len(l:cells)-1 && l:w[l:i+1]>0 | let l:line.=repeat(' ',g:kit_gap) | endif
    endfor
    if l:r[0]=='inst'
      let l:line=a:ind.l:r[1].repeat(' ',l:w[1]-strdisplaywidth(l:r[1])+g:kit_gap).'('.l:r[2].repeat(' ',l:w[2]-strdisplaywidth(l:r[2])).')'.l:r[3]
      if !empty(l:r[4]) | let l:line.=repeat(' ',g:kit_gap).l:r[4] | endif
    endif
    call add(l:out,substitute(l:line,'\s*$','',''))
  endfor
  return l:out
endfunction

function! KitAlign(first,last,group) abort
  let l:a=a:first | let l:b=a:last
  let l:base=KitRow(getline(l:a))
  if a:group
    if empty(l:base) | echo '此行不是可识别的单行声明、赋值或端口连接' | return | endif
    while l:a>1 && indent(l:a-1)==indent(a:first) && !empty(KitRow(getline(l:a-1))) && KitRow(getline(l:a-1))[0]==l:base[0] | let l:a-=1 | endwhile
    while l:b<line('$') && indent(l:b+1)==indent(a:first) && !empty(KitRow(getline(l:b+1))) && KitRow(getline(l:b+1))[0]==l:base[0] | let l:b+=1 | endwhile
  endif
  let l:view=winsaveview() | let l:lines=getline(l:a,l:b) | let l:i=0
  let l:oldline=getline('.')
  let l:tokenindex=strchars(substitute(strpart(l:oldline,0,col('.')-1),'\s','','g'))
  while l:i<len(l:lines)
    let l:r=KitRow(l:lines[l:i])
    if empty(l:r) | let l:i+=1 | continue | endif
    let l:ind=matchstr(l:lines[l:i],'^\s*') | let l:j=l:i+1 | let l:rows=[l:r]
    while l:j<len(l:lines)
      let l:next=KitRow(l:lines[l:j])
      if empty(l:next) || l:next[0]!=l:r[0] || matchstr(l:lines[l:j],'^\s*')!=l:ind | break | endif
      call add(l:rows,l:next) | let l:j+=1
    endwhile
    let l:lines[l:i:l:j-1]=KitRender(l:rows,l:ind) | let l:i=l:j
  endwhile
  call setline(l:a,l:lines)
  if l:view.lnum>=l:a && l:view.lnum<=l:b && strpart(l:oldline,l:view.col,1)!~# '\s'
    let l:seen=0 | let l:offset=0
    for l:ch in split(getline(l:view.lnum),'\zs')
      if l:ch!~# '\s'
        if l:seen==l:tokenindex | let l:view.col=l:offset | break | endif
        let l:seen+=1
      endif
      let l:offset+=strlen(l:ch)
    endfor
  endif
  call winrestview(l:view)
endfunction

function! KitDeleteBlock() abort
  if &ft !~# 'verilog' | echo '此操作用于 Verilog/SystemVerilog begin/end 块' | return | endif
  let l:view=winsaveview()
  let l:skip='KitIgnored(line("."),col("."))'
  let l:startpat='\<begin\>\|\<case\>\|\<casex\>\|\<casez\>'
  let l:endpat='\<end\>\|\<endcase\>'
  let l:word=expand('<cword>')
  " When the cursor is on a block header, select the opening token on that line.
  let l:open_col=match(getline('.'),'\<begin\>',col('.')-1)+1
  if !KitIgnored(line('.'),col('.')) && l:open_col>0 && col('.')<=l:open_col
    call cursor(line('.'),l:open_col)
    let l:start=[line('.'),col('.')]
  elseif !KitIgnored(line('.'),col('.')) && l:word =~# '^case\%(x\|z\)\?$'
    call search('\<case\%([xz]\)\?\>','bcW')
    let l:start=[line('.'),col('.')]
  else
    " An end/endcase token belongs to the block it closes, not its parent.
    if !KitIgnored(line('.'),col('.')) && l:word =~# '^end\%(case\)\?$'
      call search(l:endpat,'bcW')
    endif
    let l:start=searchpairpos(l:startpat,'',l:endpat,'bW',l:skip)
  endif
  if l:start[0]==0
    call winrestview(l:view)
    echo '没有找到当前 begin/end 或 case/endcase 块；未删除任何内容'
    return
  endif
  call cursor(l:start[0],l:start[1])
  let l:token=matchstr(strpart(getline(l:start[0]),l:start[1]-1),'^\w\+')
  let l:end=searchpairpos(l:startpat,'',l:endpat,'W',l:skip)
  if l:end[0]==0
    call winrestview(l:view)
    echo '缺少匹配的结束词；未删除任何内容'
    return
  endif
  let l:endtext=matchstr(strpart(getline(l:end[0]),l:end[1]-1),'^\%(endcase\|end\%(\s*:\s*\w\+\)\?\)')
  let l:lastcol=l:end[1]+strlen(l:endtext)-1
  let l:startline=getline(l:start[0])
  let l:before=strpart(l:startline,0,l:start[1]-1)
  " Include the controlling branch/statement. For `end else ... begin`, keep
  " the previous branch's end and remove from `else` onward.
  if l:token =~# '^case\%(x\|z\)\?$'
    let l:firstcol=match(l:startline,'\S')+1
  elseif l:before =~# '^\s*end\%(\s*:\s*\w\+\)\?\s\+else\>'
    let l:firstcol=matchend(l:startline,'^\s*end\%(\s*:\s*\w\+\)\?')+1
  elseif l:before =~# '^\s*$\|^\s*\%(if\|else\|always\%(_ff\|_comb\|_latch\)\?\|initial\|for\|foreach\|while\|repeat\|forever\|wait\|default\)\>'
    let l:firstcol=match(l:startline,'\S')+1
  elseif l:before =~# '^\s*\%([A-Za-z_$][A-Za-z0-9_$]*\|default\)\s*:'
    let l:firstcol=match(l:startline,'\S')+1
  else
    let l:firstcol=l:start[1]
  endif
  let l:prefix=strpart(l:startline,0,l:firstcol-1)
  let l:suffix=strpart(getline(l:end[0]),l:lastcol)
  " Removing the first branch promotes a following else-if/else body so the
  " remaining text is still a valid standalone block.
  if l:prefix =~# '^\s*$' && l:before =~# '^\s*if\>' && l:suffix =~# '^\s*else\>'
    let l:suffix=substitute(l:suffix,'^\s*else\s\+','','')
  endif
  let l:replacement=l:prefix.l:suffix
  if l:replacement =~# '^\s*$'
    execute l:start[0].','.l:end[0].'delete _'
  else
    call setline(l:start[0],l:replacement)
    if l:end[0]>l:start[0]
      silent! undojoin
      execute (l:start[0]+1).','.l:end[0].'delete _'
    endif
    call cursor(l:start[0],max([1,strlen(l:prefix)+1]))
  endif
  echo '已删除当前语法块；u 撤销'
endfunction
function! KitBlock(action) abort
  if a:action=='next' && KitLeavePorts() | return | endif
  let l:save=getpos('.')
  if expand('<cword>')!=#'begin' || KitIgnored(line('.'),col('.'))
    if !searchpair('\<begin\>','','\<end\>','bW','KitIgnored(line("."),col("."))')
      call setpos('.',l:save)
      echo '没有找到包围当前位置的 begin/end' | return
    endif
  endif
  let l:indent=indent('.')
  let l:end=searchpair('\<begin\>','','\<end\>','W','KitIgnored(line("."),col("."))')
  if !l:end | call setpos('.',l:save) | echo '缺少匹配 end' | return | endif
  if a:action=='pair' | return | endif
  let l:endcol=col('.')
  let l:tail=strpart(getline('.'),l:endcol-1)
  " An existing branch on the same line is the next useful editing position.
  if l:tail =~# '^end\%(\s*:\s*\w\+\)\?\s\+else\%\(\s\+if\>.*\)\?\s\+begin\>'
    let l:nextbegin=match(getline('.'),'\<begin\>',l:endcol)+1
    if l:nextbegin>0
      call cursor(line('.')+1,1)
      normal! ^
      startinsert
      return
    endif
  endif
  if getline('.') !~# '^\s*end\%(\s*:\s*\w\+\)\?\s*$'
    echo '当前 end 后还有代码，已定位；请确认下一步位置' | return
  endif
  let l:next=getline(line('.')+1)
  if l:next =~# '^\s*$\|^\s*end\|^\s*default\>'
    call append(line('.'),repeat(' ',l:indent)) | call cursor(line('.')+1,l:indent+1) | startinsert!
  else
    normal! j^
    startinsert
  endif
endfunction

function! KitLeavePorts() abort
  let l:save=getpos('.')
  try
    let l:start=search('^\s*\%(module\|endmodule\)\>', 'bWc')
    if !l:start || getline(l:start)!~# '^\s*module\>' | return 0 | endif
    let l:ind=indent(l:start)+shiftwidth()
    let l:finish=search(';\|^\s*\%(module\|endmodule\)\>', 'W')
    while l:finish && KitIgnored(line('.'),col('.'))
      let l:finish=search(';\|^\s*\%(module\|endmodule\)\>', 'W')
    endwhile
    if !l:finish || strpart(getline('.'),col('.')-1,1)!=#';' || l:save[1]>l:finish | return 0 | endif
  finally
    call setpos('.',l:save)
  endtry
  let l:target=l:finish+1
  if getline(l:target)=~# '^\s*$' && l:target<line('$') && getline(l:target+1)=~# '^\s*$'
    let l:target+=1
  endif
  if l:target>line('$') || getline(l:target)=~# '^\s*endmodule\>'
    call append(l:finish,repeat(' ',l:ind))
    let l:target=l:finish+1
  elseif getline(l:target)=~# '^\s*$'
    call setline(l:target,repeat(' ',l:ind))
  endif
  call cursor(l:target,1)
  if getline(l:target)=~# '^\s*$'
    startinsert!
  else
    normal! ^
    startinsert
  endif
  return 1
endfunction

function! KitComment(first,last) abort
  let l:lines=getline(a:first,a:last)
  let l:uncomment=empty(filter(copy(l:lines),'v:val !~# "^\\s*//" && v:val !~# "^\\s*$"'))
  call map(l:lines, l:uncomment ? 'substitute(v:val,"^\\(\\s*\\)// \\?","\\1","")' : 'substitute(v:val,"^\\(\\s*\\)\\ze\\S","\\1// ","")')
  call setline(a:first,l:lines)
endfunction

function! KitScratch(title,lines) abort
  botright new
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nowrap
  execute 'file ' . fnameescape(a:title)
  call setline(1,a:lines)
  setlocal nomodifiable
  nnoremap <silent> <buffer> q :close<CR>
endfunction

function! KitSelfCheck() abort
  let l:source=['input [7:0] a,','input [WIDTH-1:0] long_name,','output ready']
  let l:rows=map(copy(l:source),'KitRow(v:val)')
  if !empty(filter(copy(l:rows),'empty(v:val)')) | throw 'Kit: declaration parser failed' | endif
  let l:rendered=KitRender(l:rows,'')
  for l:i in range(len(l:source))
    if substitute(l:source[l:i],'\s','','g')!=#substitute(l:rendered[l:i],'\s','','g')
      throw 'Kit: alignment changed tokens'
    endif
  endfor
  if l:rendered!=#KitRender(map(copy(l:rendered),'KitRow(v:val)'), '')
    throw 'Kit: alignment is not idempotent'
  endif
  if match(l:rendered[0],'\]')!=match(l:rendered[1],'\]') | throw 'Kit: width columns differ' | endif
  if empty(KitRow('assign result = data;')) || empty(KitRow('.clk(clk),'))
    throw 'Kit: assignment or instance parser failed'
  endif
endfunction

" Direct actions: no dispatcher, no multi-level menus.
function! KitBuffers() abort
  let l:buffers = filter(getbufinfo(), 'v:val.listed')
  let l:labels = map(copy(l:buffers), 'v:val.bufnr . "  " . (empty(v:val.name) ? "[未命名]" : fnamemodify(v:val.name, ":~:.")) . (v:val.changed ? " [+]" : "")')
  let l:pick = inputlist(['选择文件：'] + map(l:labels, '(v:key+1) . ". " . v:val'))
  if l:pick>0 && l:pick<=len(l:buffers)
    execute 'buffer ' . l:buffers[l:pick-1].bufnr
  endif
endfunction
function! KitYank(visual) abort
  if a:visual
    let l:save=getreginfo('z')
    normal! gv"zy
    call setreg('z',l:save)
  else
    normal! yy
  endif
endfunction
function! KitHelp() abort
  call KitScratch('快捷键', [
  \ '精简版：普通模式按空格，再按一个键；插入模式先 Esc。',
  \ 'e 打开文件浏览器（方向键移动、Enter打开）',
  \ 'w 保存    q 退出 Vim（未保存时提示）    b 切换已打开文件',
  \ 'a 对齐全文（选中时仅选区）    c 注释/取消注释',
  \ 'j 跳出当前 begin/end；else/else if直接输入后Tab补全。',
  \ 'k 删除光标所在块：含if/else/always头或完整case；u撤销。',
  \ 'y 复制当前行或选区到系统剪贴板    p 系统粘贴',
  \ 'h 显示本帮助（按 q 关闭帮助）',
  \ '',
  \ 'inpu + Tab：补成 input，填写 7:0 再 Tab，填写名称。',
  \ '不填位宽直接 Tab；output/inout/wire/reg 同样操作。',
  \ '括号自动配对；begin 后回车补 end；空格a手动重排。',
  \ 'mod/module + Tab 生成框架；填模块名后Tab进端口；Esc后空格j跳到正文。',
  \ 'Tab结构：always initial begin if else case casex casez default',
  \ 'Tab循环：for while repeat forever wait；填条件后Tab进正文。',
  \ '块内语句分号后Tab：结束最近一层并跳到下一位置；Enter留在块内。',
  \ 'Tab结构：function task generate fork；自动生成对应结束词。',
  \ 'Tab赋值/参数：assign parameter localparam；填名称后Tab进值栏。',
  \ 'parameter/localparam填完值再Tab：下一行同类声明；Esc停止连续填写。',
  \ 'Tab结束词：end endcase endmodule endfunction endtask endgenerate join。',
  \ 'SystemVerilog另有：always_ff always_comb always_latch foreach interface package logic。',
  \ '缩写示例：alw/beg/cas/func/gen + Tab；end精确输入不会变成endmodule。',
  \ 'i 输入，Esc 返回；v/V 选字/行；/ 搜索，n/N 下一/上一处。',
  \ 'u 撤销，Ctrl-r重做；选区y或yy自动同步系统剪贴板，鼠标拖选松开复制。',
  \ 'tmux：Ctrl-b 后 v/s 分屏，方向键切换，z放大，q关闭，h帮助。'])
endfunction
nnoremap <silent> <leader>e :Lexplore<CR>
nnoremap <silent> <leader>w :write<CR>
nnoremap <silent> <leader>q :confirm qall<CR>
nnoremap <silent> <leader>b :call KitBuffers()<CR>
nnoremap <silent> <leader>a :call KitAlign(1,line('$'),0)<CR>
xnoremap <silent> <leader>a :<C-u>call KitAlign(line("'<"),line("'>"),0)<CR>
nnoremap <silent> <leader>c :call KitComment(line('.'),line('.'))<CR>
xnoremap <silent> <leader>c :<C-u>call KitComment(line("'<"),line("'>"))<CR>
nnoremap <silent> <leader>j :call KitBlock('next')<CR>
nnoremap <silent> <leader>k :call KitDeleteBlock()<CR>
silent! nunmap <leader>s
nnoremap <silent> <leader>y :call KitYank(0)<CR>
xnoremap <silent> <leader>y :<C-u>call KitYank(1)<CR>
nnoremap <silent> <leader>p :call KitPaste()<CR>
nnoremap <silent> <leader>h :call KitHelp()<CR>
" Remove the previous edition's insert-mode shortcuts on :source as well.
silent! iunmap <C-g>a
silent! iunmap <C-g>j
silent! iunmap <C-g>s
" This workstation uses .v for HDL, not the V programming language.
function! KitAttachHDL() abort
  let l:ext=tolower(expand('%:e'))
  let l:ft=index(['v','vh'],l:ext)>=0 ? 'verilog' : (index(['sv','svh'],l:ext)>=0 ? 'systemverilog' : '')
  if !empty(l:ft) && &l:filetype!=#l:ft
    let &l:filetype=l:ft
  endif
  if &l:filetype==#'verilog' || &l:filetype==#'systemverilog'
    call KitVerilog()
  endif
endfunction
augroup kit
  autocmd!
  autocmd TextYankPost * call KitYankToClipboard()
  autocmd BufRead,BufNewFile,BufEnter *.v,*.vh,*.sv,*.svh call KitAttachHDL()
  autocmd BufRead,BufNewFile *.lds,*.ldscript setfiletype ld
  autocmd FileType c,cpp,ld call KitPairs()
  autocmd FileType verilog,systemverilog call KitVerilog()
  autocmd FileType make setlocal noexpandtab
  autocmd FileType help,qf nnoremap <silent> <buffer> q :close<CR>
  autocmd BufReadPost * if line("'\"")>0 && line("'\"")<=line('$') | execute "normal! g\x60\"" | endif
  autocmd FocusGained * checktime
augroup END
call KitAttachHDL()
