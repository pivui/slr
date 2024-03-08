// Author : Pierre Vuillemin (2017)
// License : BSD

// Internal function called by slr_comments_to_xml()
function xml_str = slr_md_to_xml(str)
   str         = '\n '+str+' \n'
   // Escaping source code and latex equations
   [str, code_save, latex_save] = slr_md_to_xml_escape(str)
   // Parsing rules
   rules    = slr_md_to_xml_rules()
   //
   before = ''
   for r = rules
      pattern  = r.regexp
      mem      = []
      while %T
         [start, final, match, foundString] = regexp(str, pattern,'o')
         if isempty(start)
            if ~isempty(r.endStr) & ~isempty(before)
               str = before + newStr + r.endStr + after
            end
            break
         end
         before   = part(str, 1:start-1)
         after    = part(str, final+1:length(str))
         //
         [newStr, mem] = slr_md_rules_action(r.name, foundString, mem)
         //
         str      = before + newStr + after
      end
   end
   // Replacing escaped patterns
   escaped_pattern = list(list('\*','*'),list('\_','_'),list('\`','`'),list('\~','~'),list('\$','$'))
   for e = escaped_pattern
      str = strsubst(str, e(1), e(2))
   end
   // Replacing code
   saved_expr = lstcat(code_save, latex_save)
   for i = 1:length(saved_expr)
      str = strsubst(str, saved_expr(i)(1),saved_expr(i)(2))
   end
   //
   xml_str = strsplit(slr_strip_blanks(str),'\n')
endfunction

function [str, mem] = slr_md_rules_action(ruleName, str, mem)
   select ruleName
   case 'inlinecode'
      str = slr_xml('literal', str(1))
   case 'bold'
      str = slr_xml('bold',str(3))
   case 'italic'
      str = slr_xml('italic',str(3))
   case 'para'
      line = slr_strip_blanks(str(1))
      if isempty(line)
         str =''
         return
      end
      if ~isempty(regexp(line, '/^<\/?(simplelist|title|para|emphasis|member)/', 'o'))
         str = line
      else
         str = strsubst(slr_xml('para',line),'\n','') + '\n'
      end
   case 'ul'
      end_found = length(str(3))>0
      n_hyphens   = length(str(1))
      TAB         = slr_tabular_rep(' ',n_hyphens)
      item        = slr_item_para(str(2))
      item        = TAB + slr_xml_wrap(slr_strip_blanks(item), 'member')+'\n'
      if isempty(mem)
         str         = '\n\n<simplelist type=''vert'' columns=''1''>\n' + item
         mem.n_hyp   = list(n_hyphens)
      else
         mem_hyp = mem.n_hyp($)
         if mem_hyp == n_hyphens
            str = item
         elseif mem_hyp < n_hyphens
            TAB = slr_tabular_rep(' ',mem_hyp)
            str         = TAB + '<simplelist type=''vert'' columns=''1''>\n' + item
            mem.n_hyp($+1) = n_hyphens
         else
            TAB = slr_tabular_rep(' ',n_hyphens)
            str =  TAB + '</simplelist>\n' + item
            mem.n_hyp($) = null()
         end
         if end_found // Closure of list found
            for i = 1:length(mem.n_hyp)
               str = str +'</simplelist>\n'
            end
            mem = []
         end
      end
end
   // check https://github.com/Khan/simple-markdown/blob/master/simple-markdown.js
   // https://gist.github.com/jbroadway/2836900
endfunction

function str = slr_item_para(str)
   str   = '\n' + slr_strip_blanks(str) + '\n'
   RE    = '/\\n(.+?)(\.\h*\\n{1,})/'
   first = %T
   while %T
      [start, final, match, foundString] = regexp(str, RE,'o')
      if isempty(start)
         if first
            str = slr_xml('para',stripblanks(str))
         end
         break
      end
      first    = %F
      before   = part(str, 1:start-1)
      after    = part(str, final+1:length(str))
      newStr   = slr_xml('para',foundString(1) + '.')
      newStr   = strsubst(newStr,'\n','')
      //newStr   = strsubst(newStr,'/\h{2,}/','','r')
      str      = before + newStr + '\n'+ after
   end
endfunction

function [str, code_save, latex_save] = slr_md_to_xml_escape(str)
   id          = sprintf('%d',getdate('s'))
   code_re     = '/(~~~)\\n(.*?)\\n\h*\1/'
   code_save   = list()
   latex_re    = '/(\$)(?<!\\\$)(.*?)\1/'
   latex_save  = list()
   //   blatex_re    = '/(\$\$)(.*?)\1/'
//   rules       = list(list('code',code_re,'\n\n','\n'),list('blatex',blatex_re,'',''),list('latex',latex_re,'',''))
   rules       = list(list('code',code_re,'\n\n','\n'),list('latex',latex_re,'',''))
//   blatex_save  = list()
   for i = 1:2
      iter = 0
      while %T
         iter = iter +1;
         [start, final, match, foundString] = regexp(str, rules(i)(2), 'o')
         if isempty(start)
            break
         end
         before   = part(str, 1:start-1)
         after    = part(str, final+1:length(str))
         expr_id  = rules(i)(1) + id + sprintf('%d',iter)
         execstr(rules(i)(1)+'_save($+1) = list(expr_id, slr_xml(rules(i)(1),foundString(2)))')

         str      = before + rules(i)(3) + expr_id + rules(i)(4) + after
      end
   end
//   latex_save = lstcat(latex_save,blatex_save)
   str         = '\n '+str+' \n'
endfunction

function rules = slr_md_to_xml_rules()
   RE    = 'regexp'
   NAME  = 'name'
   ES    = 'endStr'
   // load rules 
   rtype    = 'mdRules'
   ref_rule = slr_convert_arglist(list(RE,'',NAME,'',ES,[]))
   // rules
   rules    = list()
   // Ul list
   rules($+1) = list(RE    ,'/\\n(\h*)\*\h(.+?(?=(?:\\n\h*\*)|(\\n\h*\\n)))/',...//'/\\n(\h*)\*\h((?:(?!\\n(\h*)\*).)*)/',...
                     NAME  ,'ul',...
                     ES    ,'')//'</simplelist>')
   // Inline code
   rules($+1) = list(RE, '/`(.*?)`/',...
                     NAME,'inlinecode')
   // Bold
   rules($+1) = list(RE    ,'/(\*\*|__)(?<!(\\\*|\\_))(.*?)\1/', ...
                     NAME  ,'bold')
   // Italic
   rules($+1) = list(RE    ,'/(\*|_)(?<!(\\\*|\\_))(.*?)\1/', ...
                     NAME  ,'italic')
   // Paragraphs
   rules($+1) = list(RE    , '/\\n\h*\\n(.+?)(?=(\\n\h*\\n))/',...
                     NAME  , 'para')
   // Converting to structures
   for i = 1:length(rules)
      rules(i) = slr_fill_fields(slr_convert_arglist(rules(i)),ref_rule)
   end
endfunction




function bl = slr_md_all_bullet_list(str)
    //    disp(str)
    bl              = list()
    BEGIN_BULLET    = '/\\n{1,}\h*\*\h{1}/'
    rem_str         = str
    keep_looking    = %T
    while keep_looking
        [start, final, match]   = regexp(rem_str, BEGIN_BULLET,'o')
        if isempty(start) then
            break
        end
        d       = length(str) - length(rem_str)
        bl($+1) = slr_parse_bullet_list(str, d + start)
        rem_str = part(str, bl($).end:length(str))
    end
endfunction

function bl = slr_parse_bullet_list(str, start)
    function n = get_hyphens_number(str)
        str     = strsubst(str,'\n','')
        [s,f,m] = regexp(str,'/\h*/','o')
        n       = length(m)
    endfunction    
    remaining_str   = part(str, start:length(str))
    // Initial bullet
    [si, fi, mi]    = regexp(remaining_str, BEGIN_BULLET, 'o')
    ni              = get_hyphens_number(mi)
    // Some regexp
    NEXT_BULLET     = '/(\\n){1,}\h{'+string(ni)+'}\*\h{1}/' // must have the same identation as the previous one
    if ni == 0
        END_BULLET_LIST = '/(\\n){2,}/'
    else
        END_BULLET_LIST = '/(\\n){2,}[^\h{0,'+string(ni)+'}*]*/'
    end
    // Finding the end of the bullet list
    [se, fe, me]    = regexp(remaining_str, END_BULLET_LIST, 'o')
    if isempty(se) then
        se              = length(remaining_str)+1
        remaining_str   = remaining_str
    end
    remaining_str       = part(remaining_str,1:se-1)
    bl                  = struct('bullets',list(),'start',start,'end',start + se-1)
    // Parsing  bullets
    [s, f, m]    = regexp(remaining_str, NEXT_BULLET)
    s($+1) = length(remaining_str)+1
    for i = 1:length(f)
        bl.bullets($+1) = slr_strip_blanks(part(remaining_str,f(i):s(i+1)-1))
    end
endfunction


