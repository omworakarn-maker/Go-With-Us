import React from 'react';

export const BrandLogo: React.FC<Omit<React.ImgHTMLAttributes<HTMLImageElement>, 'src'>> = ({ className = '', alt = 'GoWithUs', ...props }) => (
    <img src="/brand/logo.png" alt={alt} className={`object-contain shrink-0 ${className}`} decoding="async" {...props} />
);
