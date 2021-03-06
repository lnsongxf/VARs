function [B_draws, Sigma_draws] = SamplePosteriorBVAR_NIW(BVAR_NIW, num_draws)
% Returns a sample of size num_draws from the posterior distribution of
% a Bayesian Vector Autoregression (BVAR) with a 
% Normal-Inverse Wishart (NIW) prior.
% 
% ---------
% ARGUMENTS
% ---------
%
% BVAR_NIW:  struct containing posterior hyperparameters for a BVAR with
%            NIW prior.
% num_draws: integer, number of draws to return.
%
% -------
% OUTPUTS
% -------
%
% Here n and p denote the number of variables and lags included in the
% BVAR, and k = n * p + 1.
% 
% B_draws:     k-by-n-by-num_draws array containing draws of
%              coefficient matrices sampled from posterior distribution
%              of BVAR_NIW.
% Sigma_draws: n-by-n-by-num_draws array containing draws of
%              error covariance matrices sampled from posterior distribution
%              of BVAR_NIW.

% Unpack posterior hyperparameters from struct.
BPost = BVAR_NIW.BPost;
BetaPost = BPost(:);
OmegaPost = BVAR_NIW.OmegaPost;
PsiPost = BVAR_NIW.PsiPost;
dfPost = BVAR_NIW.dfPost;

% Set up arrays to store draws.
[k, n] = size(BPost);
B_draws = zeros(k, n, num_draws);
Sigma_draws = zeros(n, n, num_draws);

% Draw coefficients.
for i = 1:num_draws
    Sigma_draw = iwishrnd(PsiPost, dfPost);
    Beta_draw = mvnrnd(BetaPost, kron(Sigma_draw, OmegaPost));
    
    B_draws(:, :, i) = reshape(Beta_draw, k, n);
    Sigma_draws(:, :, i) = Sigma_draw;
end

end
