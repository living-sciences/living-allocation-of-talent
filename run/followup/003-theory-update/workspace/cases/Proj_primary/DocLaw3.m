global CaseName; CaseName='Benchmark';
SetParameters; HighQualityFigures=0; ReadCohortData; Names67Occupations;
idx = find(strncmpi(ShortNames,'Doctor',6) | strncmpi(ShortNames,'Lawyer',6));
printf('idx=%s names=%s\n', mat2str(idx(:)'), strjoin(ShortNames(idx),' | '));
yrs=[1960 2010 2023];
for yy=1:length(yrs)
  yi=find(Decades==yrs(yy)); tot=0; wm=0;
  for o=idx(:)'; for cc=1:size(NumPeople,3); for g=1:Ngroups
    v=NumPeople(o,g,cc,yi); if ~isnan(v); tot=tot+v; if g==1; wm=wm+v; end; end
  end; end; end
  printf('L9 %d WM-share doctors+lawyers = %.4f\n', yrs(yy), wm/tot);
end
