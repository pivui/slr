// Author : Pierre Vuillemin (2017)
// License : BSD

function tab = slr_tabular(T, headers, entries, options)
   // Returns a formated tabular.
   //
   // Syntax
   //    tab = slr_tabular(title, headers, entries)
   //    tab = slr_tabular(title, headers, entries, options)
   //
   // Parameters
   //    title    : title of the table (string)
   //    headers  : headers of each column (list or matrix)
   //    entries  : entries of the table (list or matrix)
   //    options  : options for the formating (structure)
   //    tab      : formated tabular (string)
   //
   // Description
   //    This routine enables to create formated tables.
   //
   // Examples
   //    ~~~
   //    A        = rand(10,3);
   //    data     = [mean(A,'c'),max(A,'c'),min(A,'c')];
   //    T        = 'Table of results';
   //    headers  = list('Mean','Max','Min');
   //    opt.float_format = '%.3f';
   //    opt.count_lines = %T;
   //    tab      = slr_tabular(T, headers, data, opt);
   //    mprintf(tab)
   //    ~~~
   //

   // Options handling .........................................................
   if argn(2) < 4 then
      options = struct()
   end
   default_options   = struct('float_format' ,  '%.2f',...
                              'table_format' ,  'simple',...
                              'alignment'    ,     [],...
                              'padding'      ,     1,...
                              'count_lines'  ,     %F)
   //
   options           = slr_fill_fields(options, default_options, %T)
   // Reformating inputs .......................................................
   // Entries of the tab
   entries = slr_tabular_format_entries(entries)
   if options.count_lines
      for i = 1:length(entries)
         entries(i)(0) = sprintf('%d',i)
      end
   end
   entries = slr_tabular_stringify(entries, options.float_format)
   // Headers of the tab
   headers = slr_tabular_format_headers(headers)
   if options.count_lines & ~isempty(headers)
      headers(1)(0) = ''
   end
   headers = slr_tabular_stringify(headers, options.float_format)
   // Counting stuff ...........................................................
   ncols       = size(entries(1))
   if isempty(options.alignment)
      options.alignment = []
      for i=1:ncols
         options.alignment = [options.alignment, 'c']
      end
      if options.count_lines
         options.alignment(1) = 'r'
      end
   else
      if options.count_lines
         options.alignment(0) = 'r'
      end
   end
   symbols.npadding     = options.padding
   [tab_len, cols_len]  = slr_tabular_count_len(T, lstcat(headers,entries), ncols, options.padding)
   // Preparing format .........................................................
   symbols.lver         = ''
   symbols.rver         = ''
   symbols.mver         = ''
   symbols.rdec         = ''
   symbols.ldec         = ''
   function out = tabular_dec_text(t)
      out = %F
   endfunction
   symbols.dec          = tabular_dec_text
   top_bar              = ''
   in_bar               = ''
   bot_bar              = ''
   select options.table_format
   case 'simple'
      symbols.corner       = '+'
      symbols.lver         = '|'
      symbols.rver         = '|'
      symbols.mver         = '|'
      symbols.hor          = '-'
      top_bar              = slr_tabular_make_line_sep(tab_len, symbols)
      bot_bar              = top_bar
      head_bar             = slr_tabular_make_line_sep(tab_len, symbols, cols_len)
      in_bar               = head_bar
   case 'github-md'
      if ~isempty(T)
         mprintf('''%s'' formating does not accept a title. Discarding.\n', options.table_format)
         T = []
      end
      symbols.corner       = '|'
      symbols.lver         = '|'
      symbols.rver         = '|'
      symbols.mver         = '|'
      symbols.hor          = '-'
      head_bar             = slr_tabular_make_line_sep(tab_len, symbols, cols_len, options.alignment)
   case 'latex'
      al = options.alignment
      if options.count_lines
         al = [al(1),'|', al(2:$)]
      end
      top_bar              = '\\begin{table}\n\\begin{tabular}{'+strcat(al) + '}\n'
      head_bar             = '\\hline\n'
      bot_bar              = '\\end{tabular}\n'
      symbols.rver         = '\\\\'
      symbols.mver         = '&'
      symbols.rdec         = '$'
      symbols.ldec         = '$'
      symbols.dec          = isnum
      if ~isempty(T)
         bot_bar = bot_bar + '\\caption{' + T + '}\n'
      end
      bot_bar = bot_bar + '\\end{table}'
      T = ''
   else
      error('Unknown table format')
   end
   // Building the tabular .....................................................
   tab = top_bar
   if ~isempty(T) then
      title_len   = tab_len - 2 - 2 * symbols.npadding
      tab         = tab + tabular_make_line(list(T), list(title_len), list('c'), symbols)
      tab         = tab + top_bar
   end
   if ~isempty(headers) then
      tab = tab + tabular_make_line(headers(1), cols_len, options.alignment, symbols)
      tab = tab + head_bar
   end
   for line = entries
      if ~isempty(line)
         tab = tab + tabular_make_line(line, cols_len, options.alignment, symbols)
      else
         tab = tab + in_bar
      end
   end
   tab = tab + bot_bar
endfunction

function out = slr_tabular_justify(text, side, n)
   text     = stripblanks(text)
   n_text   = length(text)
   d        = n - n_text
   select side
   case 'l'
      out   = text + slr_tabular_blanks(d)
   case 'r'
      out   = slr_tabular_blanks(d) + text
   case 'c'
      if modulo(d,2) == 0
         n_l = d/2
         n_r = d/2
      else
         n_l = floor(d/2)
         n_r = ceil(d/2)
      end
      out = slr_tabular_blanks(n_l) + text + slr_tabular_blanks(n_r)
   end
endfunction

function out = slr_tabular_blanks(n)
   blank = ' '
   out   = slr_tabular_rep(blank, n)
endfunction

function out = slr_tabular_rep(symbol, n)
   out = ""
   for i = 1:n
      out = out + symbol
   end
endfunction

function [tab_len, cols_len] = slr_tabular_count_len(T, entries, ncols, npadding)
   if ~isempty(T) then
      title_len = length(stripblanks(T))
   else
      title_len = 0
   end
   cols_len = zeros(ncols,1)
   for line = entries
      for i = 1:length(line)
         cols_len(i) = max(cols_len(i), length(line(i)))
      end
   end
   tab_len  = sum(cols_len) + 2*npadding * ncols + 1 * (ncols+1)
   N        = title_len + 2  + 2
   if N > tab_len then
      rem      = modulo(N - tab_len, ncols)
      cols_len = cols_len + floor((N - tab_len) / ncols)
      tab_len  = title_len + 2 + 2 * npadding
      if rem ~= 0
         cols_len = cols_len + 1
         tab_len  = tab_len + (ncols-rem)
      end
   end
endfunction

function line = tabular_make_line(entries, cols_len, justif, symbols)
   line = symbols.lver
   for i = 1:length(entries)
      text  = slr_tabular_justify(entries(i), justif(i), cols_len(i))
      if symbols.dec(text)
         text = symbols.ldec + text + symbols.rdec
      end
      line = line + slr_tabular_add_padding(text, symbols.npadding)
      if i < length(entries)
         line = line + symbols.mver
      end
   end
   line = line + symbols.rver+ '\n'
endfunction

function str = slr_tabular_add_padding(str, n)
   blank = ' '
   str   = slr_tabular_rep(blank,n) + str + slr_tabular_rep(blank, n)
endfunction

function line = slr_tabular_make_line_sep(line_len, symbols, cols_len, alignment)
   if argn(2) == 2
      n_corner = 2
      line     = symbols.corner + slr_tabular_rep(symbols.hor, line_len - n_corner) + symbols.corner
   elseif argn(2) == 3
      line = symbols.corner
      for i = 1:length(cols_len)
         line = line + slr_tabular_rep(symbols.hor, cols_len(i) + 2*symbols.npadding)
         if i < length(cols_len)
            line = line + symbols.corner
         end
      end
      line = line + symbols.corner
   elseif argn(2) == 4
      line = symbols.corner
      for i = 1:length(cols_len)
         select alignment(i)
         case 'l'
            pre   = ':'
            post  = ''
         case 'c'
            pre   = ':'
            post  = pre
         case 'r'
            pre   = ''
            post  = ':'
         else
            pre   = ''
            post  = ''
         end
         add_size = length(pre) + length(post)
         line = line + pre + slr_tabular_rep(symbols.hor, cols_len(i) + 2*symbols.npadding -add_size) + post
         if i < length(cols_len)
            line = line + symbols.corner
         end
      end
      line = line + symbols.corner
   end
   line = line + '\n'

endfunction

function tab = slr_tabular_stringify(tab, float_format)
   if isempty(tab)
      return
   end
   for i=1:length(tab)
      line = tab(i)
      for j = 1:length(line)
         e = line(j)
         if typeof(e) == 'constant'
            tab(i)(j) = sprintf(float_format, e)
         end
      end
   end
endfunction

function tab = slr_tabular_mat_to_tab(mat)
   tab = list()
   for i = 1:size(mat,1)
      inner_list = list()
      for j = 1:size(mat,2)
         inner_list($+1) = mat(i,j)
      end
      tab(i) = inner_list
   end
endfunction

function entries = slr_tabular_format_entries(entries)
   if typeof(entries) == 'constant' | typeof(entries) == 'string'
      // If the input is a matrix, then it is turned into a list  which contains 
      // each row as a list
      entries  = slr_tabular_mat_to_tab(entries)
   elseif typeof(entries) == 'list'
      // if the input is already a list, then one goes through all its elements
      // (meant to represent lines) to turn matrix into list of elements.
      for i = 1:length(entries)
         line = entries(i)
         if typeof(line) == 'string' | typeof(line) == 'constant'
            inner_list = list()
            for j = 1:size(line, 2)
               inner_list($+1) = line(j)
            end
            entries(i) = inner_list
         end
      end
   end
endfunction

function headers = slr_tabular_format_headers(headers)
   if isempty(headers)
      return
   end
   if typeof(headers) == 'constant' | typeof(headers) == 'string' 
      headers = slr_tabular_mat_to_tab(headers)
   elseif typeof(headers) == 'list'
      headers = list(headers)
   end
endfunction

