" Templates
if has("autocmd")
  augroup templates
    autocmd BufNewFile */devotions/** 0r ~/.config/nvim/templates/devotions.skeleton
    autocmd VimEnter */devotions/** :call DevotionCurrentDate()
    autocmd BufNewFile */journal/** 0r ~/.config/nvim/templates/journal.skeleton
    autocmd VimEnter */journal/** :call JournalCurrentDate()
  augroup END
endif
fun JournalCurrentDate()
  exe "1,1g/Journal entry for/s/Journal entry for.*/Journal entry for " .
  \ strftime("%B %-d, %Y")
endfun
fun DevotionCurrentDate()
  exe "1,1g/Devotion for/s/Devotion for.*/Devotion for " .
  \ strftime("%B %-d, %Y")
endfun
