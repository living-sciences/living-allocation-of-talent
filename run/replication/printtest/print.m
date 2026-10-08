function print(varargin)
  args = varargin;
  isopt = @(s) ischar(s) && ~isempty(s) && s(1)=='-';
  % Force loose bbox for eps/ps to avoid epstool dependency
  if ~any(cellfun(@(x) ischar(x)&&strcmp(x,'-loose'), args))
    args{end+1} = '-loose';
  end
  try
    builtin('print', args{:});
  catch err
    try
      s=''; for i=1:numel(args); if ischar(args{i}); s=[s ' ' args{i}]; end; end
      warning('print_shim:fail','print shim failed for [%s]: %s', s, err.message);
    catch; end
  end
end
