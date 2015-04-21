function p = normpdf(X, mu, sigma)
    A = sigma*((2*pi)^0.5);
    ex = -((X - mu).^2)/(2*sigma^2);
    p = exp(ex)/A;
end