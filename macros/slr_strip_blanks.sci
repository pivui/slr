// Author : Pierre Vuillemin (2017)
// License : BSD

function str = slr_strip_blanks(str)
   // Removes any blanks character at the end and at the beginning of a string.
   str = strsubst(str, '/(\\n{1,}|\s)*+$/', '', 'r')
   str = strsubst(str, '/^(\\n{1,}|\s)*/', '','r')
endfunction
