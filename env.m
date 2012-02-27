%% env
% Fit the envelope model.

%% Usage
% [beta Sigma Gamma Gamma0 eta Omega Omega0 alpha l
% ratio]=env(X,Y,u)
%
% Input
%
% * X: Predictors. An n by p matrix, p is the number of predictors. The
% predictors can be univariate or multivariate, discrete or continuous.
% * Y: Multivariate responses. An n by r matrix, r is the number of
% responses and n is number of observations. The responses must be 
% continuous variables.
% * u: Dimension of the envelope. An integer between 0 and r.
%
% Output
% 
% stat: A list that contains the maximum likelihood estimators and some
% statistics.
% 
% * stat.beta: The envelope estimator of the regression coefficients $$\beta$. 
% An r by p matrix.
% * stat.Sigma: The envelope estimator of the error covariance matrix.  An r by
% r matrix.
% * stat.Gamma: The orthogonal basis of the envelope subspace. An r by u
% semi-orthogonal matrix.
% * stat.Gamma0: The orthogonal basis of the complement of the envelope
% subspace.  An r by r-u semi-orthogonal matrix.
% * stat.eta: The coordinates of $$\beta$ with respect to Gamma. An u by p
% matrix.
% * stat.Omega: The coordinates of Sigma with respect to Gamma. An u by u
% matrix.
% * stat.Omega0: The coordinates of Sigma with respect to Gamma0. An r-u by r-u
% matrix.
% * stat.alpha: The estimated intercept in the envelope model.  An r by 1
% vector.
% * stat.l: The maximized log likelihood function.  A real number.
% * stat.ratio: The asymptotic standard error ratio of the stanard multivariate 
% linear regression estimator over the envelope estimator, for each element 
% in $$\beta$.  An r by p matrix.

%% Description
% This function fits the envelope model to the responses and predictors,
% using the maximum likehood estimation.  When the dimension of the
% envelope is between 1 and r-1, we implemented the algorithm in Cook et
% al. (2010).  When the dimension is r, then the envelope model degenerates
% to the standard multivariate linear regression.  When the dimension is 0,
% it means that X and Y are uncorrelated, and the fitting is different.

%% References
% 
% * The codes is implemented based on the algorithm in Section 4.3 of Cook 
% et al (2010).
% * The Grassmann manifold optimization step calls the package sg_min 2.4.1
% by Ross Lippert (http://web.mit.edu/~ripper/www.sgmin.html).


function stat=env(X,Y,u)


% To Yi: 1) We need to do check something, e.g., if Y is discrete, the model cannot
% handle that, but I do not know how to check that either.  There are some
% other checks: u must be an interger between 0 and r, X and Y must have
% the same length.


global sigY;
global sigres;

%---preparation---
[n p]=size(X);
r=size(Y,2);
XC=center(X);
YC=center(Y);

sigX=cov(X,1);
sigY=cov(Y,1);

[beta_OLS sigres]=fit_OLS(X,Y);
eigtem=eig(sigY);


% With different u, the model will be different.  When u=0, X and Y are
% uncorrelated, so it should be fitted differently.  When u=r, the envelope
% model reduces to the standard model, and it also should be fitted
% differently.


if u>0 && u<r


    %---Compute \Gamma using sg_min---

    init=startv(X,Y,u);
    [l Gamma]=sg_min(init,'prcg','quiet');


    %---Compute the rest of the parameters based on \Gamma---
    Gamma0=grams(nulbasis(Gamma'));
    alpha=mean(Y)';
    beta=Gamma*Gamma'*beta_OLS;
    eta=Gamma'*beta;
    Omega=Gamma'*sigres*Gamma;
    Omega0=Gamma0'*sigY*Gamma0;
    Sigma1=Gamma*Omega*Gamma';
    Sigma2=Gamma0*Omega0*Gamma0';
    Sigma=Sigma1+Sigma2;
    stat.l=-n*r/2*(1+log(2*pi))-n/2*(l+log(prod(eigtem(eigtem>0))));

    %---compute asymptotic variance and get the ratios---
    asyfm=kron(inv(cov(X,1)),Sigma);
    temp=kron(eta*sigX*eta',inv(Omega0))+kron(Omega,inv(Omega0))+kron(inv(Omega),Omega0)-2*kron(eye(u),eye(r-u));
    asyem=kron(inv(sigX),Sigma1)+kron(eta',Gamma0)*inv(temp)*kron(eta,Gamma0');
    stat.ratio=reshape(sqrt(diag(asyfm)./diag(asyem)),r,p);
    stat.beta=beta;
    stat.Gamma=Gamma;
    stat.Gamma0=Gamma0;
    stat.eta=eta;
    stat.Omega=Omega;
    stat.Omega0=Omega0;
    stat.alpha=alpha;
    stat.np=r+u*p+r*(r+1)/2;
    
    
elseif u==0
    
    
    
    stat.beta=zeros(r,p);
    stat.Gamma=[];
    stat.eta=[];
    stat.Omega=[];
    stat.Gamma0=eye(r);
    stat.Sigma=sigY;
    stat.Omega0=sigY;
    stat.alpha=mean(Y)';
    stat.l=-n*r/2*(1+log(2*pi))-n/2*log(prod(eigtem(eigtem>0)));
    stat.ratio=ones(r,p);
    stat.np=r+u*p+r*(r+1)/2;
    

elseif u==r
    
    
    stat.beta=beta_OLS;
    stat.eta=beta_OLS;
    stat.Sigma=sigres;
    stat.Gamma=eye(r);
    stat.Gamma0=[];
    stat.Omega=sigres;
    stat.Omega0=[];
    stat.alpha=mean(Y)';
    eigtem=eig(sigres);
    stat.l=-n*r/2*(1+log(2*pi))-n/2*log(prod(eigtem(eigtem>0)));
    stat.ratio=ones(r,p);
    stat.np=r+u*p+r*(r+1)/2;
    
end
    
    
    