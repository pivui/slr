// Author : Pierre Vuillemin (2017)
// License : BSD

function [ok, msg] = slr_check_arg(arg, arg_name, tests)
   // Performs some tests on an argument.
   //
   // Syntax
   //    slr_check_arg(arg, arg_name, tests)
   //    [ok, msg] = slr_check_arg(arg, arg_name, tests)
   //
   // Parameters
   //    arg               : the variable to be tested
   //    arg_name (string) : its name
   //    tests      (list) : a list containing the tests to be performed
   //    ok      (boolean) : answer of the tests
   //    msg      (string) : error message associated with the first failed test.
   //
   // Description
   //
   // Examples
   // 
   //    ~~~
   //    tests = list('type',['constant'])
   //    slr_check_arg(1, 'a', tests)
   //    ~~~
   //
   tests_struct = slr_convert_arglist(tests)
   for t = fieldnames(tests_struct)
      test_ref = tests_struct(t)
      select t
      case 'type' // test of type ..............................................
         ok = or(typeof(arg) == test_ref)
         if ~ok
            msg = 'Invalid type for parameter '''+arg_name+''': '''+typeof(arg)+''' ('''+test_ref+''' expected).\n'
         end
      case 'lt' // lower than ..................................................
         idx   = find(arg > test_ref)
         ok    = isempty(idx)
         if ~ok
            i     = idx(1)
            msg   = 'Invalid value for element '+string(i)+' of parameter '''+arg_name+''': '+string(arg(i))+' (must be <= '+string(test_ref(i))+').\n'
         end
      case 'gt' // greater than ................................................
         idx   = find(arg < test_ref)
         ok    = isempty(idx)
         if ~ok
            i     = idx(1)
            msg   = 'Invalid value for element '+string(i)+' of parameter '''+arg_name+''': '+string(arg(i))+' (must be >= '+string(test_ref(i))+').\n'
         end
      case 'size' // size ......................................................
         ok   = and(size(arg) == test_ref)
         if ~ok

            msg   = 'Invalid size of parameter '''+arg_name+''': '+strcat(string(size(arg)),'x')+' (must be '+strcat(string(test_ref),'x')+').\n'
         end
      end
      if ~ok
         break
      end
   end
   if argn(1) < 2  then
      if ~ok
         error(msg)
      end
   end
endfunction
