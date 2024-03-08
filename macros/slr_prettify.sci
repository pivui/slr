// Author : Pierre Vuillemin (2017)
// License : BSD

function slr_prettify(e,options)
   // Attempts to make a handle (e.g. a figure) pretty for articles.
   //
   // Syntax
   //    slr_prettify(h)
   //    slr_prettify(h, opt)
   //
   // Parameters
   //    h   (handle) : the thing to prettify
   //    opt (struct) : the options
   //
   // Description
   //    Given a handle, this routines attempts:
   //       * to transform the text it finds in latex,
   //       * to increase the font sizes,
   //       * to increase the thickness of lines.
   //
   //    Default values (of thickness, font sizes, etc.) can be modified by giving
   //    a structure containing the options to modify. The available options are:
   //       * title\_font\_size (4),
   //       * labels\_font\_size (3),
   //       * thicks\_font\_size (2),
   //       * leg\_font\_size (3),
   //       * line\_thickness (2),
   //       * xstring\_font\_size (2),
   //       * num\_format ('').
   //
   // Examples
   //    ~~~
   //    n = 1000;
   //    x = linspace(0,2*%pi,n);
   //    plot(x,sin(x),x,cos(x))
   //    h = gcf()
   //    title('$\text{Figure of }f_1(x)\text{ and }f_2(x)$')
   //    xlabel('$x\text{ (rad)}$')
   //    ylabel('$y$')
   //    legend('$f_1(x) = sin(x)$','$f_2(x) = cos(x)$')
   //    opt.line_thickness = 3
   //    opt.labels_font_size = 4
   //    slr_prettify(h, opt)
   //    ~~~
   
   // Options handling .........................................................
   if argn(2) < 2 then
      options = struct()
   end
   default_options = struct('title_font_size'   ,  4,...
                            'labels_font_size'  ,  3,...
                            'thicks_font_size'  ,  2,...
                            'num_format'        ,  '',...
                            'leg_font_size'     ,  3,...
                            'line_thickness'    ,  2,...
                            'xstring_font_size' ,  2)
   // Assignation of default options
   if ~and(isdef(fieldnames(default_options))) then
      options = slr_fill_fields(options, default_options, %T)
      slr_extract_fields(options)
   end
   // Switch case on the type of handle that has been provided .................
   select convstr(e.type,'l')
   case 'figure'
      slr_prettify_fig(e)
   case 'axes'
      slr_prettify_axes(e)
   case 'polyline'
      slr_prettify_polyline(e)
   case 'legend'
      slr_prettify_legend(e)
   case 'compound'
      slr_prettify_compound(e)
   case 'text'
      slr_prettify_text(e)
   end
endfunction

function slr_prettify_text(t)
   t.font_size = xstring_font_size
endfunction

function slr_prettify_fig(f)
   f.anti_aliasing   = '8x'
   for i = 1:length(f.children)
      slr_prettify(f.children(i))
   end
endfunction

function slr_prettify_axes(ax)
   // Axis thicks
   ax.font_size      = thicks_font_size
   ax.x_ticks.labels = slr_latexify(ax.x_ticks.labels)
   ax.y_ticks.labels = slr_latexify(ax.y_ticks.labels)
   ax.z_ticks.labels = slr_latexify(ax.z_ticks.labels)
   // Axis labels
   labels_name       = ['x_label','y_label','z_label']
   for name = labels_name
      label             = ax(name)
      label.font_size   = labels_font_size
      label.text        = slr_latexify(label.text)
   end
   // Title
   T                 = ax.title
   T.text            = slr_latexify(T.text)
   T.font_size       = title_font_size
   //
   for i = 1:length(ax.children)
      slr_prettify(ax.children(i))
   end
endfunction

function slr_prettify_polyline(po)
   po.thickness      = line_thickness
endfunction

function slr_prettify_legend(leg)
   leg.font_size     = leg_font_size
   leg.text          = slr_latexify(leg.text)
endfunction

function slr_prettify_compound(co)
   for i = 1:length(co.children)
      slr_prettify(co.children(i))
   end
endfunction

function str = slr_latexify(str)
   if str == '' then
      return
   end
   // Adds $ at the beginning and the end of a matrix of strings
   for i = 1:size(str,1)
      str(i) = '$' + slr_wrap_in_text(str(i)) + '$'
   end
endfunction

function out_str = slr_wrap_in_text(str)
   // In a string containing normal text and latex expressions between $, this
   // routines wraps the text part inside \text{.} macros
   // '$f(x) = sin(x)$ is a nice function' --> 'f(x) = sin(x)\text{ is a nice function}'
   str   = stripblanks(str)
   T     = tokens(str, '$')
   if part(str,1) ~= '$' then
      start = 1
   else
      start = 2
   end
   for i = start:2:size(T,1)
      t = T(i,:)
      if isnum(T(i,:)) & ~isempty(num_format)
         t = sprintf(num_format,eval(t))
      end
      T(i,:) = '\text{'+t+'}'
   end
   out_str = ''
   for i = 1:size(T,1)
      out_str = out_str + T(i,:)
   end
endfunction

function slr_extract_fields(stru)
   varNames    = fieldnames(stru)'
   varValues   = []
   for v = varNames
      varValues   = [varValues,'stru.'+v+'']
   end
   exStr = '[' + strcat(varNames,',') + '] = resume(' + strcat(varValues,',')+');'
   execstr(exStr)
endfunction
