%% lrt_penv
% Select the dimension of the partial envelope subspace using likelihood 
% ratio testing.

%% Syntax
%         u = lrt_penv(X, Y, alpha)
%         u = lrt_penv(X, Y, alpha, Opts)
%
%% Input
%
% *X*: A list containing the value of X1 and X2.
% 
% * X.X1: Predictors of main interest. An n by p1 matrix, n is the number of 
% observations, and p1 is the number of main predictors. The
% predictors can be univariate or multivariate, discrete or continuous.
% * X.X2: Covariates, or predictors not of main interest.  An n by p2 matrix,
% p2 is the number of covariates.
% 
% *Y*: Multivariate responses. An n by r matrix, r is the number of
% responses and n is number of observations. The responses must be 
% continuous variables.
% 
% *alpha*: Significance level for testing.  A real number between 0 and 1,
% often taken at 0.05 or 0.01.
% 
% *Opts*: A list containing the optional input parameters, to control the
% iterations in sg_min. If one or several (even all) fields are not
% defined, the default settings are used.
% 
% * Opts.maxIter: Maximum number of iterations.  Default value: 300.
% * Opts.ftol: Tolerance parameter for F.  Default value: 1e-10. 
% * Opts.gradtol: Tolerance parameter for dF.  Default value: 1e-7.
% * Opts.verbose: Flag to print out dimension selection process. 
% Logical 0 or 1. Default value: 0.
% * Opts.table: Flag to tabulate the results, which contains log 
% likelihood, test statistic, degrees of freedom and p-value for each test. 
% Logical 0 or 1. Default value: 0.
%
%% Output
%
% *u*: Dimension of the partial envelope subspace. An integer between 0 and r.

%% Description
% This function implements the likelihood ratio testing procedure to select
% the dimension of the partial envelope subspace, with pre-specified 
% significance level $$\alpha$.  

%% Example
%         load fiberpaper.dat
%         Y = fiberpaper(:, 1 : 4);
%         X.X1 = fiberpaper(:, 7);
%         X.X2 = fiberpaper(:, 5 : 6);
%         alpha = 0.01;
%         u = lrt_penv(X, Y, alpha)

function u = lrt_penv(X, Y, alpha, Opts)

if nargin < 3
    error('Inputs: X, Y and alpha should be specified!');
elseif nargin == 3
    Opts = [];
end

if (alpha < 0 || alpha > 1)
    error('alpha should be between [0, 1]!');
end

if isfield(Opts, 'table')
    if (Opts.table ~= 1)
        tableFlag = 0;
    else
        tableFlag = 1;
    end
else
    tableFlag = 0;
end

Opts = make_opts(Opts);
printFlag = Opts.verbose;
Opts.verbose = 0;

r = size(Y, 2);
llik = zeros(r + 1, 1);
tstat = zeros(r + 1, 1);
df = zeros(r + 1, 1);
pv = zeros(r + 1, 1);

ModelOutput0 = penv(X, Y, r, Opts);
llik(r + 1) = ModelOutput0.l;

for i = 0 : r - 1
    
    if printFlag == 1
        fprintf(['Current dimension ' int2str(i) '\n']);
    end
    
    ModelOutput = penv(X, Y, i, Opts);
	llik(i + 1) = ModelOutput.l;
    tstat(i + 1) = - 2 * (ModelOutput.l - ModelOutput0.l);
	df(i + 1) = ModelOutput0.paramNum - ModelOutput.paramNum;
	pv(i + 1) = 1 - chi2cdf(tstat(i + 1), df(i + 1));
    if pv(i + 1) > alpha
	    u = i;
	    break;
    end
    
end

if i == r - 1 && pv(i + 1) < alpha
    u = r;
end

if tableFlag == 1
    
    fprintf('\n u      log likelihood      test statistic     degrees of freedom    p-value\n');
    fprintf('----------------------------------------------------------------------------------\n');
    for i = 0 : u
        fprintf('%2d %15.3f %18.3f %18d %18.3f\n', i, llik(i + 1), tstat(i + 1), df(i + 1), pv(i + 1));
    end
    fprintf('%2d %15.3f\n', r, llik(r + 1));    
    fprintf('----------------------------------------------------------------------------------\n');
    
end