" Hack to enable syntax for php files.
" TODO this breaks rainbow brackets.
call timer_start(0, { -> execute('syntax on')})
