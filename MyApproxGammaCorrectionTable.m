gammapower = 2.2;
approxInvGamma = repmat((0:255).^(1/gammapower),3,1)';
myGammaTableApprox = approxInvGamma/max(approxInvGamma(:));

save('myGammaTableApprox.mat','myGammaTableApprox');

