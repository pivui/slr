// Author : Pierre Vuillemin (2017)
// License : BSD

// Internal function called in slr_comments_to_xml() and slr_xml()
function [head, tail] = slr_chop(str, tok)
    i = regexp(str, "/" + tok + "/", "o");
    if isempty(i) then
        head = str;
        tail = [];
    else
        head = part(str, 1:i - 1);
        tail = part(str, i + 1:length(str));
    end
endfunction
