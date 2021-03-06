function BVAR_NIW = EstimateBVAR_NIW(Y, BPrior, OmegaPrior, PsiPrior, dfPrior)
% Given data Y, estimate a Bayesian Vector Autoregression (BVAR) with a
% Normal-Inverse Wishart prior.
% 
% The VAR has n variables and p lags, and can be written as
%
% y_t = C + B_1 y_t-1 + ... + B_p y_t-p + e_t
% e_t ~ N(0, Sigma)
% 
% The coefficients are collected in the k-by-n matrix
% B = [C, B_1,..., B_p]' where k = n * p + 1. By writing
% x_t = [1, y'_t-1,..., y'_t-p]', we can express the VAR in row-vector
% form:
%
% y'_t = x'_t B + e'_t
%
% Stacking Y = (y_1,..., y_T)', X = (x_1,..., x_T)', and
% e = (e_1,..., e_T)' allows us to write
%
% Y = X B + e
%
% The Normal-Inverse Wishart prior is a conjugate prior for (B, Sigma).
% Let Beta = vec(B). The prior is given by:
%
% Sigma ~ Inverse-Wishart(PsiPrior, dfPrior)
% Beta | Sigma ~ Normal(vec(BPrior), kron(Sigma, OmegaPrior))
%
% where kron(M, N) denotes the Kronecker product of matrices M and N.
% 
% ---------
% ARGUMENTS
% ---------
%
% Y:          T-by-n matrix of data.
% BPrior:     k-by-n matrix, prior mean of B.
% OmegaPrior: k-by-k matrix, 'row' covariances for conditional prior of B.
% PsiPrior:   n-by-n matrix, scale parameter for Inverse-Wishart prior of Sigma.
% dfPrior:    scalar, degrees of freedom for Inverse-Wishart prior of Sigma.
%             Must be > n - 1 for prior to be defined, and > n + 1 for
%             prior mean to exist, in which case it is equal to
%             PsiPrior / (d - n - 1).
%
% -------
% OUTPUTS
% -------
%
% BVAR_NIW: struct with 4 fields:
%     BPost:     k-by-n matrix, posterior mean of B.
%     OmegaPost: k-by-k matrix, 'row' covariances for conditional posterior of B.
%     PsiPost:   n-by-n matrix, scale parameter for Inverse-Wishart posterior of Sigma.
%     dfPrior:   scalar, degrees of freedom for Inverse-Wishart posterior of Sigma.

%% Validate arguments.

% Check sizes.
[T, n] = size(Y);
k = size(BPrior, 1);
p = round((k - 1) / n);

if (n * p + 1 ~= k) ...
   || any(size(BPrior, 2) ~= n) ...
   || any(size(BPrior, 2) ~= n) ...
   || any(size(OmegaPrior) ~= [k, k]) ...
   || any(size(PsiPrior) ~= [n, n])

    error('Argument dimensions are inconsistent.')
end

if (dfPrior <= n - 1)
    error('Prior degrees of freedom must be > n - 1.')
end

% Create X matrix of RHS variables
X = ones(T - p, k);
for i = 1:p
    X(:, (2 + (i - 1) * n):(1 + i * n)) = Y((p + 1 - i):(T - i), :);
end

% Some useful computations to avoid repetition
Ytrimmed = Y((p + 1):end, :);
XprimeX = X' * X;
invXprimeX = inv(XprimeX);
XprimeY = X' * Ytrimmed;
BMLE = XprimeX \ XprimeY;
SigmaMLE = (Ytrimmed - X * BMLE)' * (Ytrimmed - X * BMLE);
invOmegaPrior = inv(OmegaPrior);

% Create structure 'BVAR_NIW' to store posterior hyperparameters
BVAR_NIW = struct;
BVAR_NIW.BPost = (XprimeX + invOmegaPrior) \ (XprimeY + OmegaPrior \ BPrior);
BVAR_NIW.OmegaPost = inv(XprimeX + invOmegaPrior);
BVAR_NIW.PsiPost = PsiPrior + SigmaMLE ...
                   + (BPrior - BMLE)' * ((OmegaPrior + invXprimeX) \ (BPrior - BMLE));
BVAR_NIW.dfPost = dfPrior + T;

end


