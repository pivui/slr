// Author : Pierre Vuillemin (2017)
// License : BSD

function target = slr_fill_fields(target, ref, check_fields, tests)
   // fills a structure based on a reference structure.
   //
   // Syntax
   //    out_stru = slr_fill_fields(in_stru, ref_stru)
   //    out_stru = slr_fill_fields(in_stru, ref_stru, check_fields)
   //    out_stru = slr_fill_fields(in_stru, ref_stru, check_fields, tests)
   //
   // Parameters
   //    in_stru  (st or mlist) : variable to be filled
   //    ref_stru (st or mlist) : reference variable
   //    check_fields (boolean) : checks whether fields in in_stru are not in ref_stru
   //    tests           (list) : list of tests to perform on some fields
   
   if argn(2) < 3 then
      check_fields = %T
   end
   if argn(2) < 4 then
      tests = []
   end
   fields      = fieldnames(target)
   def_fields  = fieldnames(ref)
   // Checking for fields that are not default
   if check_fields then
      wrong_target   = setdiff(fields, def_fields)
      if ~isempty(wrong_target)
         warn_msg       = strcat(wrong_target',''', ''')
         disp('Warning: Invalid parameter(s): '''+warn_msg+'''')
         possible_target   = strcat(def_fields',''', ''')
         disp('Valid parameters are: '''+possible_target+'''.')
      end
   end
   // Tests on the values of existing fields
   if ~isempty(tests) then
      test_fields = intersect(fields,fieldnames(tests))
      for f = test_fields
         [ok, msg] = slr_check_arg(opt(f), f, tests(f))
      end
   end
   // Filling the fields that are not present
   for f = def_fields'
      if ~isfield(target, f)
         target(f) = ref(f)
      end
   end
endfunction
