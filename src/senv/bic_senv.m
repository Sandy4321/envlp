%% bic_senv
% Select the dimension of the scaled envelope subspace using Bayesian
% information criterion.

%% Syntax
%         u = bic_senv(X, Y)
%         u = bic_senv(X, Y, Opts)
%
%% Input
%
% *X*: Predictors. An n by p matrix, p is the number of predictors and n 
% is the number of observations. The predictors can be univariate or 
% multivariate, discrete or continuous.
% 
% *Y*: Multivariate responses. An n by r matrix, r is the number of
% responses. The responses must be continuous variables.
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
% * Opts.table: Flag to tabulate the results, which contains BIC and log
% likelihood for each u. Logical 0 or 1. Default value: 0.
% * Opts.rep: Number of replicates for scales. This option imposes special 
% structure on scaling parameters. For example, if Opts.rep = [3 4], this 
% means that the first three responses have the same scale and the next 
% four responses share a different scale. The elements of this vector should 
% sum to r. If not specified, the default is [], then all responses will be
% scaled differently. If all responses have the same scale, input [r], then 
% the regular envelope will be applied to the data.
% The input should be a row vector.
%
%% Output
%
% *u*: Dimension of the scaled envelope. An integer between 0 and r.
% 
%% Description
% This function implements the Bayesian information criteria (BIC) to select
% the dimension of the scaled envelope subspace. 

%% Example
%
%         load('sales.txt')
%         Y = sales(:, 4 : 7);
%         X = sales(:, 1 : 3);
%         u = bic_senv(X, Y)

function u = bic_senv(X, Y, Opts)

if nargin < 2
    error('Inputs: X and Y should be specified!');
elseif nargin == 2
    Opts = [];
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

[n, r] = size(Y);
ic = zeros(r + 1, 1);
llik = zeros(r + 1, 1);

ModelOutput = senv(X, Y, r, Opts);
llik(r + 1) = ModelOutput.l;
ic(r + 1) = - 2 * ModelOutput.l + log(n) * ModelOutput.paramNum;

for i = 0 : r - 1
    
    if printFlag == 1
        fprintf(['Current dimension ' int2str(i) '\n']);
    end
    
    ModelOutput = senv(X, Y, i, Opts);
    llik(i + 1) = ModelOutput.l;
    ic(i + 1) = - 2 * ModelOutput.l + log(n) * ModelOutput.paramNum;
    
end

[~, u] = min(ic);
u = u - 1;

if tableFlag == 1
    
    fprintf('\n u      log likelihood      BIC\n');
    fprintf('--------------------------------------------\n');
    for i = 0 : r
        fprintf('%2d %15.3f   %12.3f\n', i, llik(i + 1), ic(i + 1));
    end
    fprintf('--------------------------------------------\n');
    
end