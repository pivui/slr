// Author : Pierre Vuillemin (2017)
// License : BSD

function out = slr_xml(key, varargin)
   // Formats text with xml tags.
   //
   // Syntax
   //    xml_str = slr_xml(key, args)
   //
   // Parameters
   //    key      (string) : type of the formatting that must be performed
   //    args              : content to be formatted
   //    xml_str  (string) : formatted string
   //
   select key
   case 'italic'
      out = slr_xml_wrap(varargin(1),'emphasis')
   case 'bold'
      out = slr_xml_wrap(varargin(1), struct('tag','emphasis','opt','role=""bold""'))
   case 'literal'
      out = slr_xml_wrap(varargin(1),'literal')
   case 'para'
      out = slr_xml_wrap(varargin(1), 'para')
   case 'link'
      out = slr_xml_wrap(varargin(1),struct('tag','link','opt','linkend=""'+varargin(1)+'""'))
   case 'latex'
      out = slr_xml_wrap(varargin(1),'latex')
//   case 'blatex'
//      out = slr_xml_wrap('para',slr_xml_wrap(varargin(1),'latex'))
   case 'simplelist'
      entries     = varargin(1)
      ITEM_TAG    = 'member'
      out         = []
      for e = entries
         out = [out;slr_xml_wrap(e, ITEM_TAG)]
      end
      //      
      default_opt = struct('type','vert','columns',1)
      opt         = struct()
      if length(varargin) == 2
         opt = varargin(2)
      end
      opt = slr_fill_fields(opt, default_opt)
      
      OPT_STR = 'type='''+opt.type+''''
      if opt.type ~= 'inline'
         OPT_STR = OPT_STR +' columns='''+string(opt.columns)+''''
      end
      //
      out = slr_xml_wrap(out,struct('tag','simplelist','opt',OPT_STR),%T)
   case 'code'
      out = slr_xml_wrap('<![CDATA[\n'+ varargin(1)+'\n]]>',struct('tag','programlisting','opt','role=""example""'))
   case 'variablelist'
      vars        = varargin(1)
      desc        = varargin(2)
      with_type   = %F
      if length(varargin) == 3
          with_type = varargin(3)
      end
      ITEM_TAG    = 'varlistentry'
      VAR_TAG     = 'term' //, 'filename' // in the official doc filename is also
      DESC_TAG    = ['listitem','para']
      out         = []
      for i = 1:length(vars)
         v        = vars(i)
         if with_type
            [v, vtype]  = slr_chop(v,'\(')
            if ~isempty(vtype)
               vtype    = slr_xml('italic','('+ vtype)
            else
               vtype    = ''
            end
            v           = stripblanks(v) + ' ' + stripblanks(vtype)
         end
         VAR_XML = slr_xml_wrap(v, VAR_TAG)
         d     = desc(i)
         item  = [VAR_XML;slr_xml_wrap(d, DESC_TAG)]
         out   = [out; slr_xml_wrap(item, ITEM_TAG, %T)]
      end
      // Outer wrap
      out   = slr_xml_wrap(out, 'variablelist', %T)
   else
      error(sprintf('Unknown key ''%s''',key))
   end
endfunction

function str = slr_xml_wrap(str, tag, as_matrix)
   // Wraps a string in given tags with some specified options.
   if argn(2)<3 then
      as_matrix = %F
   end
   TAB = '   '
   for i = max(size(tag)):-1:1
      t = tag(i)
      if ~isempty(t)
         opt = '';
         if typeof(t) == 'st'
            opt   = ' ' + t.opt;
            t     = t.tag;
         end
         if as_matrix then
            str = ['<' + t + opt + '>'; TAB + str; '</'+ t + '>']
         else
            if max(size(str))>1
               str = ['<' + t + opt + '>';str;'</'+ t + '>']
            else
               str = '<' + t + opt + '>' + str + '</'+ t + '>'
            end
         end
      end
   end
endfunction
