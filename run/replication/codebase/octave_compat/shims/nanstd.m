function y=nanstd(x,flag,dim)
 if nargin<2||isempty(flag), flag=0; end
 if nargin<3, dim=find(size(x)~=1,1); if isempty(dim), dim=1; end; end
 n=sum(~isnan(x),dim); m=nanmean(x,dim); d=x-m; d(isnan(d))=0;
 if flag==0, den=max(n-1,1); else, den=n; end
 y=sqrt(sum(d.^2,dim)./den);
end
