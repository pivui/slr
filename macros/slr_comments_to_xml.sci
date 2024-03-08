// Author : Pierre Vuillemin (2017)
// License : BSD

function help_xml = slr_comments_to_xml(src, target)
//   
//   Generates the xml files of help from the head comments of a .sci file or a directory.
//   
//   Syntax
//      help_xml = slr_comments_to_xml(src)
//      help_xml = slr_comments_to_xml(src, help_dir)
//      
//   Parameters
//      src      (string) : source file or directory to be processed.
//      target   (string) : directory in which the help file(s) will be placed
//   
//   Description
//      This routines generates .xml help files based on the head comments of .sci
//      files. Note that the head comments can either be made with single line comments
//      or with block comments.
//      
//      In order for this routine to format the .xml file properly, the head comments
//      should comply with some simple formatting rules.
//      
//      In particular, the head comments should be divided in different sections 
//      which content is then specifically formatted. The predefined sections are:
//      'Syntax', 'Parameters', 'Description', 'Examples', 'See also', 'Used functions', 
//      'Authors' and 'Bibliography'.
//      To be recognised, these headlines should be alone on a line.
//      
//      The content of each section must also comply with some rules to be formatted
//      adequately:
//         * a one-line description of the function should be located between the
//         declaration of the function and the first section.
//         * __Syntax__: shows examples of call to the routine. There should be one 
//         example of call per line.
//         * __Parameters__: contains the list of input and output parameters with a 
//         short description.
//         The name of the parameter is separated from its description by a
//         ":" and the type of the parameter can be put in parenthesis just after 
//         its name.
//         Note that the description of the parameter can extends on several lines.
//         * __Description__: this section enables to describe more in-depth the
//         behaviour of the routine. 
//         To ease the formatting of the text, some markdown-like features are 
//         supported (see below).
//         * __Examples__: contains full use cases of the routine. The formatting is
//         similar to the description section and the code snippet become executable.
//         * __See also__: enables to provide links to similar functions. Each name must
//         be on a new line or be separated by a comma.
//         * __Bibliography__: contains references to the litterature. Each entry must
//         be separated from the other by a newline or a comma.
//         * __Authors__: contains a list of the authors. Each author must appear on a
//         different line.
//
//#  Markdown-like support
//       A basic markdown support is implemented for the sections description, 
//       examples, and any user defined section.
//       
//       It supports:
//          * __bold expressions__ are delimited with \*\* or \_\_
//          * _italic expression_ are delimited with \* or \_
//          * `literal expressions` are delimited with \`
//          * unordered lists are obtained using \* at the start of the line. Indentation
//          is then exploited to determine nested lists.
//          Paragraph in lists are obtained with a single newline. Note that they
//          must end with a point to be parsed correctly.
//          * code blocks are delimited with \~\~\~
//          * inline latex equations are delimited with \$
//
//
//   Examples
//      Here is an example of the results this function can produce
//
//      ~~~
//      target    = './';                            // where the xml file will be created
//      xml_str   = slr_comments_to_xml([], target); // with an empty source, it will apply to itself
//      my_title  = 'slr_comments_to_xml_demo';
//      xmltojar(target, my_title)                   // generate a jar file from the xml
//      ok = add_help_chapter(my_title,target);      // adding the help chapter
//      help();
//      ~~~
//      
//   See also
//      help
//      sci_to_demo
//   
//   Authors
//      Pierre Vuillemin
   
   
   // Defining some constants
   EXT      = '.sci'
   SEP      = filesep()
   tmp      = ver()
   SCI_VER  = tmp(1,2)
   TAG  = 'slr_comments_to_xml'
   // --------------------------------------------------------------------------
   // Handling inputs
   //---------------------------------------------------------------------------
   nargin   = argn(2)
   if nargin < 2 then
      target = []
   end
   
   if nargin == 0 | isempty(src) then
      // No input is provided: in that case, the content of 'slr_comments_to_xml' is 
      // copied to the TMP directory and used as a demo file.
      prog        = macr2tree(slr_comments_to_xml)
      prog.name   = prog.name + '_demo'
      txt         = tree2code(prog, %T)
      src         = TMPDIR + SEP + prog.name + EXT;
      mputl(txt, src);
      if (isdef("editor") | (funptr("editor") <> 0))
//         editor(src)
      end
   end
   
   if isdir(src) then
      // If the src is a directory, then the routine is called for each *.sci file in the directory
      printf(gettext("%s: Reading from directory %s\n"), TAG, src);
      help_xml = list()
      files    = findfiles(src, '*.sci');   // read *.sci files from the src directory
      for i = 1:size(files,1)
         src_file       = src + SEP + files(i)
         help_xml($+1)  = slr_comments_to_xml(src_file, target)
         printf(gettext('%s: Processing of file: %s \n'), TAG, src_file)
      end
      printf(gettext('%s: processed %i files.\n'), TAG, i)
      return
   end
   // At this point the variable 'src' is a file
   if isempty(strindex(src, EXT)) then
      src = src + EXT;
   end
   if isempty(fileinfo(src)) then
      error(sprintf(gettext('%s: The file %s does not exist.\n'), TAG, src));
   end
   // --------------------------------------------------------------------------
   // Actual processing of the file
   // --------------------------------------------------------------------------
   //
   // 1. Name of the file is extracted from the src file and the xml header is created
   //
   function_name  = basename(src)
   help_xml       = get_xml_header(function_name)
   //
   // 2. Head comments are extracted from the src file and are processed
   //
   comments       = get_head_comments(src) // until head_comments is repaired
   if isempty(comments) then
      help_xml = ''
      return
   end
   // To avoid a specific treatement for the one-line description of the function, 
   // a fictious header section is created and added at the beginning of the comments
   comments       = ' \n header \n ' + comments
   // Default sections are completed with user-defined sections and sorted
   default_sec    = ['header', 'syntax', 'parameters', 'description', 'examples', 'see also', ..
                     'authors', 'bibliography', 'used functions']
   sections       = find_and_sort_sections(comments, default_sec)
   // The comments are then parsed to extract the content of each section.
   // The content of each section is stored in the corresponding field in the 
   // structure 'sections_content'.
   sections_content = find_sections_content(comments, sections)
   if isfield(sections_content, 'header') then
      // the name of the function is required for the header. Hence this field is
      // completed with the name of the function separated with ':'
      sections_content.header = function_name + ':' + sections_content.header
   end
   //
   // 3. Formatted help text is built from the extracted sections
   //
   for section = sections
      if isfield(sections_content, section)
         // If the section has been found, then it is processed and added to the 
         // help text
         section_content   = sections_content(section)
         section_xml       = section_txt_to_xml(section, section_content)
         help_xml          = [help_xml;'';section_xml]
         section_xml = ''
      end
   end
   help_xml = [help_xml;'</refentry>']
   // Writting to the target file
   if ~isempty(target) then
      target = target + filesep() + function_name + '.xml'
      fd = mopen(target,'wt')
      for i = 1:size(help_xml,1)
         mfprintf(fd, '%s\n',help_xml(i))
      end
      mclose(fd)
   end
endfunction
//
//==============================================================================
//                          FORMATTING SECTIONS
//==============================================================================
//
function section_xml = section_txt_to_xml(section, content)
   // Formats the content of a section with xml tags.
   SECTION_TAG       = 'refsection'
   TITLE_TAG         = 'title'
   CONTENT_TAG       = ''
   inner_opt         = [];
   SECTION_TITLE     = capital_first_letter(section)
   content_as_mat    = %T
   as_matrix         = %T
   select section
   case 'header' // ............................................................
      SECTION_TAG    = 'refnamediv'
      CONTENT_TAG    = 'refpurpose'
      TITLE_TAG      = 'refname'
      [function_name, content] = chop(content, ':')
      SECTION_TITLE  = stripblanks(function_name)
      content        = stripblanks(get_rid_of_newlines(content))
   case 'syntax' // ............................................................
      SECTION_TAG    = 'refsynopsisdiv'
      CONTENT_TAG    = 'synopsis'
      content        = stripblanks(sprintf(content))
   case 'parameters' // ........................................................
      // Pre-processing content
      idx               = 1
      RE                = '/\\n(.*?)(?=:)/';
      content           = '\n '+content
      start             = regexp(content, RE)
      start($+1)        = length(content) + 1 
      params            = list()
      descs             = list()
      for i = 1:length(start)-1
         line           = part(content, start(i):start(i+1)-1)
         line           = get_rid_of_newlines(line)
         [param, desc]  = slr_chop(line,':')
         params($+1)    = stripblanks(param)
         descs($+1)     = stripblanks(desc)
      end
      // the section is directly formatted by slr_xml
      content           = slr_xml('variablelist', params, descs, %T)
      content_as_mat    = %T
   case 'authors' // ...........................................................
      content = sprintf(content)
      authors = list()
      for i = 1:size(content, 1)
         line = stripblanks(content(i))
         if ~isempty(line)
            authors($+1) = line
         end
      end
      content = slr_xml('simplelist',authors)
   case 'see also' // ..........................................................
      content           = content + '\n'
      content           = strsubst(content,',','\n')
      [start,final,ma]  = regexp(content,'/\\n/')
      start             = [start,length(content)]
      final             = [0, final]
      fun_list          = list()
      for i = 1:length(start)-1
         fun_name       = part(content,final(i)+1:start(i)-1)
         if ~isempty(fun_name)
            fun_name       = stripblanks(fun_name)
            fun_list($+1)  = slr_xml('link',fun_name)
         end
      end
      opt               = struct('type','inline')
      content           = slr_xml('simplelist', fun_list, opt)
   case 'description'
      // Other case, one parse the content with a markdown-like support
      content = slr_md_to_xml(content)
      content_as_mat = %T
   else
      content = slr_md_to_xml(content)
      content_as_mat = %T
   end
   inner_xml         = [slr_xml_wrap(SECTION_TITLE, TITLE_TAG);...
                        slr_xml_wrap(content, CONTENT_TAG, content_as_mat)]
   //
   section_xml       = slr_xml_wrap(inner_xml, SECTION_TAG, as_matrix)
endfunction
//
function [head, tail] = chop(str, tok)
    i = regexp(str, "/" + tok + "/", "o");
    if isempty(i) then
        head = str;
        tail = [];
    else
        head = part(str, 1:i - 1);
        tail = part(str, i + 1:length(str));
    end
endfunction
//
function Str = capital_first_letter(str)
   // Capitalizes the first letter of a string.
   Str = convstr(part(str,1),'u') + part(str,2:$)
endfunction
//
function str = get_rid_of_newlines(str)
   // Suppress the symbols \n in a string.
   str = get_rid_of(str, '\\n{1,}\h*')
endfunction
//
function str = get_rid_of(str, re)
   str = strsubst(str,'/'+re+'/','','r')
endfunction
//
//==============================================================================
//                          SPLITTING HEAD COMMENTS
//==============================================================================
//
function sorted_sections = find_and_sort_sections(txt, sections)
   // Find additional section delimited by '#' at the beginning of the line
   [start, final] = regexp(txt, '/\\n{1,}\h*\#/')
   for i = 1:length(final)
      sub_txt              = part(txt, final(i): length(txt))
//      [tmp,tmp,match]= regexp(sub_txt,'/(?<=\#).*?(?=\\n)/') // see: http://stackoverflow.com/questions/6109882/regex-match-all-characters-between-two-strings
      [tmp,tmp,tmp,match]  = regexp(sub_txt,'/(\\n){0,}\h*\#\h((?:(?!\\n).)*)/')
      sections($+1)        = stripblanks(match(2)) 
   end
   // Sort all the sections
   ns    = size(sections,2)
   pos   = zeros(ns,1)
   for i = 1:ns
      s        = sections(i)
      p        = regexp(txt, '/(?:^|\\n{1,}\h*\#{0,1}\h*)'+s+'\h*\\n{1,}/i')//'(?:$|\h*\\n{1,})/i')
      if isempty(p)
         p     = %inf // affecting %inf as position for absent sections
      end
      pos(i)   = p
   end
   [tmp, idx]        = gsort(pos, 'g', 'i')
   sorted_sections   = []
   for i = 1:sum(pos~=%inf) // discarding absent sections
      sorted_sections(1,$+1) = sections(idx(i))
   end
endfunction
//
function stxt = find_sections_content(txt, sections)
   stxt = struct()
   for section_name = sections
      s_content = extract_section_content(txt, section_name, sections);
      if ~isempty(s_content)
         stxt(section_name) = s_content;
      end
   end
endfunction
//
function content = extract_section_content(txt, s, sections)
   // at this point the sections are already ordered
   content              = [];
   [tmp, final,match]   = regexp(txt, '/(\\n){1,}\h*\#{0,1}\h*'+s+'\h*\\n{1,}/i')
   id                   = final + 1
   // see https://superuser.com/questions/903168/how-should-i-write-a-regex-to-match-a-specific-word
   [tmp, sec_pos] = intersect(sections, s)
   if sec_pos == size(sections,2) then
      content = slr_strip_blanks(part(txt, id:length(txt)))
   else
      next_section   = sections(sec_pos + 1)
      start          = regexp(txt, '/(\\n){1,}\h*\#{0,1}\h*'+next_section+'\h*\\n{1,}/i')
      content = slr_strip_blanks(part(txt,id:start-1))
   end
endfunction
//
//==============================================================================
//                          EXTRACTING HEAD COMMENTS
//==============================================================================
//
function hc = get_head_comments(file_name)
   // Extracts the head comments from the first function in a file.
   BLANK    = ' ';
   file_d   = mopen(file_name, "rt");
   // Get the first line after function definition
   line     = " ";
   while isempty(strindex(line, "function ")) & ~meof(file_d) 
      line  = mgetl(file_d, 1); 
   end
   line     = mgetl(file_d,1);
   hc       = '\n';
   if line_begin_with(line, '//') then
      // If the comments are made with //, then the stopping condition is met when
      // a line does not start with
      function out = stop_condition(line)
         out =  ~line_begin_with(line, '//');
      endfunction
      function out = post_treat(str)
//         out   = strsubst(str, '/\\n{1,}\h*\/{2}/','','r') // not working atm due to a bug in strsubst
         [start, final, match]   = regexp(str, '/\\n{1,}\h*\/{2}/')
         match                   = unique(match)
         for i = 1:size(match,1)
            str = strsubst(str, match(i),'\n')
         end
         out = str
      endfunction
   elseif line_begin_with(line, '/*') then
      // if the comments are made with /* ...*/ then the stopping condition is met
      // when the line contains */
      function out = stop_condition(line)
         out = ~isempty(strindex(line, '*/'))
      endfunction

      function out = post_treat(str)
         dummy   = strsubst(str, '/*', '')
         out     = strsubst(dummy, '*/', '')
      endfunction
   else
      hc = [];
      return
   end

   while ~meof(file_d) & ~stop_condition(line)
      hc      = hc + line + '\n'
      line    = mgetl(file_d, 1)
   end
   mclose(file_d)
   hc = replace_tab_by_space(hc)
   hc = post_treat(hc + BLANK) // adding a blank at the end so that the split works fine
   // Remove white spaces in empty lines  (for some reason, the same method that the one used above segfault)
   hc = hc + '\n\n'
   [start,final,match]   = regexp(hc, '/(\\n)\h*(\\n)/') // Replace with strsubst when it is not longer buged
   tmp         = part(hc, 1: start(1)-1)
   start($+1)  = length(hc)
   for i = 1:length(final)-1
      tmp = tmp + '\n\n' + part(hc,final(i)+1:start(i+1)-1)
   end
   hc= tmp
endfunction
//
function out = line_begin_with(line, symbol)
   // Tests whether a given line begins with some symbol (excluding blanks)
   out = strindex(stripblanks(line), symbol)(1) == 1;
endfunction
//
function strOut = replace_tab_by_space(strIn)
   strOut = strsubst(strIn, ascii(9), part(" ",1:4));
endfunction
//
function txt = get_xml_header(function_name)
   txt = [
   "<?xml version=""1.0"" encoding=""UTF-8""?>"
   ""
   "<refentry version=""5.0-subset Scilab"" xml:id="""+function_name+""" xml:lang=""en"""
   "          xmlns=""http://docbook.org/ns/docbook"""
   "          xmlns:xlink=""http://www.w3.org/1999/xlink"""
   "          xmlns:svg=""http://www.w3.org/2000/svg"""
   "          xmlns:ns3=""http://www.w3.org/1999/xhtml"""
   "          xmlns:mml=""http://www.w3.org/1998/Math/MathML"""
   "          xmlns:scilab=""http://www.scilab.org"""
   "          xmlns:db=""http://docbook.org/ns/docbook"">"
   ""
   ];
endfunction
