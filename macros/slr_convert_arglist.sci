// Author : Pierre Vuillemin (2017)
// License : BSD

function s = slr_convert_arglist(attr_list, out_type)
   // Creates a structure or mlist from a list of key-value pairs.
   //
   // Syntax
   //    s = slr_convert_arglist(attributes)
   //    s = slr_convert_arglist(attributes, mlist_type)
   //
   // Parameters
   //    attributes  (list)   : list of attributes with their values
   //    mlist_type  (string) : type of the mlist
   //    s  (struct or mlist) : structured data
   //
   // Description
   //    Converts a list that consists in a sequence of keys and their
   //    value, i.e. list('attr1', value1, ..., 'attrN',valueN)
   //    to a structure or a mlist.
   //
   // Examples
   //    Creation of a structure:
   //
   //       ~~~
   //       attr_list   = list('attr1', 1, 'attr2', 2)
   //       s           = slr_convert_arglist(attr_list)
   //       disp(typeof(s))
   //       s.attr1
   //       s.attr2
   //       ~~~
   //
   //    Creation of a mlist:
   //
   //       ~~~
   //       myType      = 'myType'
   //       attr_list   = list('attr1', 1, 'attr2', 2)
   //       m           = slr_convert_arglist(attr_list, myType)
   //       disp(typeof(m))
   //       m.attr1
   //       m.attr2
   //       ~~~
   //
   attr_names  = list(attr_list(1:2:$))
   attr_values = list(attr_list(2:2:$))
   // Convert list of attributes to array of attributes
   attributes     = []
   for a = attr_names
      attributes  = [attributes, a]
   end
   // Build the object
   if argn(2) < 2 | isempty(out_type) then
      s  = struct()
   else
      s  = mlist([out_type, attributes])
   end

   // Assign the initial values
   for i = 1:length(attr_values)
      field       = attr_names(i)
      s(field)    = attr_values(i)
   end
endfunction
