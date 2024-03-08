// Copyright (C) 2018 - Pierre Vuillemin
// Copyright (C) 2018 - Samuel Gougeon
mode(-1);
lines(0);
try
    v = getversion('scilab');
catch
    error(gettext('Scilab 5.0 or more is required.'));
end;
// ===================================================================
if ~with_module('development_tools') then
    error(msprintf(gettext('%s module not installed.'),'development_tools'));
end
// ===================================================================
TOOLBOX_NAME = 'slr';
TOOLBOX_TITLE = 'slr';
// ===================================================================
toolbox_dir = get_absolute_file_path('builder.sce');

tbx_builder_macros(toolbox_dir);
tbx_builder_help(toolbox_dir);
if v(1)>5 then
    tbx_build_loader(toolbox_dir);
    tbx_build_cleaner(toolbox_dir);
else
    tbx_build_loader(TOOLBOX_NAME, toolbox_dir);
    tbx_build_cleaner(TOOLBOX_NAME, toolbox_dir);
end
// ===================================================================
clear v toolbox_dir TOOLBOX_NAME TOOLBOX_TITLE;
