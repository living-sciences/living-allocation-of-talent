% Step 8: white-men share of doctors+lawyers in 1960 vs 2010
global CaseName; CaseName='DocLawShare';
SetParameters; ReadCohortData; Names67Occupations;
diary DocLawShare.log;
disp('GroupNames (audit group ordering; expect WM=1):'); disp(GroupNames);
idx = find(strncmpi(ShortNames,'Doctor',6) | strncmpi(ShortNames,'Lawyer',6));
printf('Resolved occupation indices: %s\n', mat2str(idx(:)'));
disp('Resolved occupation names:'); disp(ShortNames(idx));
printf('NumPeople dims = %s ; Ngroups=%d Ncohorts=%d Nyears=%d\n', mat2str(size(NumPeople)), Ngroups, size(NumPeople,3), Nyears);
disp(['Decades: ' mat2str(Decades(:)')]);
yrs=[1960 2010];
for yy=1:2
  yi=find(Decades==yrs(yy));
  tot=0; wm=0;
  for o=idx(:)'
    for cc=1:size(NumPeople,3)
      for g=1:Ngroups
        v=NumPeople(o,g,cc,yi);
        if ~isnan(v); tot=tot+v; if g==1; wm=wm+v; end; end
      end
    end
  end
  printf('%d WM-share doctors+lawyers = %.4f   (WM=%.0f / total=%.0f)\n', yrs(yy), wm/tot, wm, tot);
end
diary off;
