function s=wstd_compat(x,w,flag)
% Matlab-semantics std(x,w,nanflag) for vector weights w along dim 1 (column-wise).
 if nargin<3, flag='includenan'; end
 if isvector(x), x=x(:); end
 w=w(:); s=zeros(1,size(x,2));
 for j=1:size(x,2)
   xj=x(:,j); wj=w;
   if strcmp(flag,'omitnan'), k=~isnan(xj)&~isnan(wj); xj=xj(k); wj=wj(k); end
   mu=sum(wj.*xj)/sum(wj); s(j)=sqrt(sum(wj.*(xj-mu).^2)/sum(wj));
 end
end
