%% mfoldcv_henv
% Use m-fold cross validation to select the dimension of the envelope subspace 
% for heteroscedastic envelope model.

%% Syntax
%         SelectOutput = mfoldcv_henv(X, Y, m)
%         SelectOutput = mfoldcv_henv(X, Y, m, Opts)

%% Input
%
% *X*: Group indicators. A matrix with n rows.  X can only have p unique
%  rows, where p is the number of groups. For example, if there 
% are two groups, X can only have 2 different kinds of rows, such as (0, 1)
% and (1, 0), or (1, 0, 10) and (0, 5, 6).  The number of columns is not
% restricted, as long as X only has p unique rows.
%
% *Y*: Multivariate responses. An n by r matrix, r is the number of
% responses and n is number of observations. The responses must be 
% continuous variables.
%
% *m*: A positive integer that is used to indicate m-fold cross validation.
% 
% *Opts*: A list containing the optional input parameters. If one or
% several (even all) fields are not defined, the default settings are used.
% 
% * Opts.verbose: Flag to print out dimension selection process, 
% logical 0 or 1. Default value: 0.
% * Opts.table: Flag to tabulate the results, which contains cross 
% validation error for each u.  Logical 0 or 1. Default value: 0.
% * Opts.perm: A positive integer indicating number permutations of the observations, 
% m-fold cross validation is run on each permutation. If not specified, the
% division is based on the sequential order of the observations.
% * Opts.seed: A real number that set the seeds for permutations. Default
% value is 1. 

%% Output
% 
% *SelectOutput*: A list containing the results of the selection.
% 
% * SelectOutput.u: The dimension of the envelope subspace selected by 
% m-fold cross validation.  An integer between 0 and r.
% * SelectOutput.PreErr: A vector containing prediction errors for each u 
% if Opts.perm is not specified, or a matrix with the element in the ith 
% row and jth column containing the prediction error for u=j-1 and ith 
% permutation of the observations.

%% Description
% This function implements m-fold cross validation to select the dimension
% of the envelope space, based on prediction performance.  For each u, the
% data is partitioned into m parts, each part is in turn used for testing 
% for the prediction performance while the rest m-1 parts are used for 
% training.  The dimension is selected as the one that minimizes the average 
% prediction errors. As Y is multivariate, the identity inner product is 
% used for computing the prediction errors.

%% Example
% 
%         load waterstrider.mat
%         Opts.table = 1; % Print out the table of average prediction error for each u
%         SelectOutput = mfoldcv_henv(X, Y, 5, Opts);
%         SelectOutput.u
% 
%         Opts.perm = 10; % Run 5-fold CV on 10 permutations
%         Opts.seed = 3; % Set seed for the permutations
%         Opts.table = 1;
%         SelectOutput = mfoldcv_henv(X, Y, 5, Opts);
%         SelectOutput.PreErr
%         mean(SelectOutput.PreErr) % Compute the average of prediction errors for each u
%         std(SelectOutput.PreErr) % Compute the standard deviations of the prediction errors for each u


function SelectOutput = mfoldcv_henv(X, Y, m, Opts)

if nargin < 3
    error('Inputs: X, Y, and m should be specified!');
elseif nargin == 3
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

X = double(X);
Y = double(Y);

Opts = make_opts(Opts);
printFlag = Opts.verbose;
Opts.verbose = 0;

[n, p] = size(X);

tempInd = min(floor((m - 1) * n / m) - 1, p);

if isfield(Opts, 'perm')

    if Opts.perm <= 0
        error('Number of permutations should be a positive integer!');
    end
    
    if isfield(Opts, 'seed')
        seed = ceil(Opts.seed);
    else
        seed = 1;
    end
    
    perm = ceil(Opts.perm);
    PreErr = zeros(perm, tempInd + 1);
    pe = zeros(perm,1);
    
    
    for w = 1 : perm
        
        rand('state', seed + w)
        ind = randsample(1 : n, n);
        X = X(ind, :);
        Y = Y(ind, :); 
        
        for j = 0 : tempInd

            if printFlag == 1
                fprintf(['Current dimension ' int2str(j + 1) '\n']);
            end

            for i = 1 : m

                index = true(n, 1);
                index((floor((i - 1) * n / m) + 1) : floor(i * n / m)) = 0;
                tempX = X(index, :);
                tempY = Y(index, :);
                ModelTemp = henv(tempX, tempY, j);

                testX = X(logical(1 - index), :);
                testY = Y(logical(1 - index), :);
                testN = size(testX, 1);
                sqe = 0;
                for k = 1 : testN
                    pred = predict_henv(ModelTemp, testX(k, :)', 'estimation');
                    sqe = sqe + (testY(k, :) - pred.value') * (testY(k, :)' - pred.value);
                end
                
                PreErr(w, j + 1) = PreErr(w, j + 1) + sqe;

            end

        end        
        
    end
    
    PreErr = sqrt(PreErr / n);
    
    pe = mean(PreErr);
    [~, ind] = min(pe);
    u = ind - 1;

    SelectOutput.u = u;
    SelectOutput.PreErr = PreErr;
    
    if tableFlag == 1

        fprintf('\n u      CV error      \n');
        fprintf('------------------------\n');
        for i = 0 : tempInd
            fprintf('%2d %12.3f\n', i, pe(i + 1));
        end
        fprintf('------------------------\n');

    end
    
    fprintf('\n');
    disp('The rows of PreErr corresponds to permutations, and the columns of PreErr corresponds to u.');
    fprintf('\n');

else

    PreErr = zeros(1, tempInd + 1);

    for j = 0 : tempInd

        if printFlag == 1
            fprintf(['Current dimension ' int2str(j + 1) '\n']);
        end

        for i = 1 : m

            index = true(n, 1);
            index((floor((i - 1) * n / m) + 1) : floor(i * n / m)) = 0;
            tempX = X(index, :);
            tempY = Y(index, :);
            ModelTemp = henv(tempX, tempY, j);

            testX = X(logical(1 - index), :);
            testY = Y(logical(1 - index), :);
            testN = size(testX, 1);
            sqe = 0;
            for k = 1 : testN
                pred = predict_henv(ModelTemp, testX(k, :)', 'estimation');
                sqe = sqe + (testY(k, :) - pred.value') * (testY(k, :)' - pred.value);
            end
            PreErr(j + 1) = PreErr(j + 1) + sqe;

        end

        PreErr(j + 1) = sqrt(PreErr(j + 1) / n);
    end


    [~, ind] = min(PreErr);
    u = ind - 1;

    SelectOutput.u = u;
    SelectOutput.PreErr = PreErr;
    
    if tableFlag == 1

        fprintf('\n u      CV error      \n');
        fprintf('------------------------\n');
        for i = 0 : tempInd
            fprintf('%2d %12.3f\n', i, PreErr(i + 1));
        end
        fprintf('------------------------\n');

    end
    
end