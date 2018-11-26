'use strict';
exports.handler = (event, context, callback) => {
    // Get contents of response
    const response = event.Records[0].cf.response;
    const headers = response.headers;

    // Set new headers 
    headers['strict-transport-security'] = [{key: 'Strict-Transport-Security', value: 'max-age=63072000;'}]; 
    headers['content-security-policy'] = [{key: 'Content-Security-Policy', value: "default-src 'none' ; script-src 'self' 'unsafe-inline' account.ridibooks.com data.ridibooks.com cdnjs.cloudflare.com ajax.googleapis.com www.googletagmanager.com www.google-analytics.com connect.facebook.net; style-src 'self' 'unsafe-inline' ; img-src 'self' data: www.google-analytics.com www.googletagmanager.com stats.g.doubleclick.net www.facebook.com; font-src 'self' data: themes.googleusercontent.com; connect-src api.pay.ridibooks.com account.ridibooks.com data.ridibooks.com ridibooks.com sentry.io www.google-analytics.com stats.g.doubleclick.net www.facebook.com; object-src 'none' ; frame-src staticxx.facebook.com connect.facebook.net; block-all-mixed-content; report-uri https://sentry.io/api/1307887/security/?sentry_key=0bc859e1423a42dc8728690b03bcedf0&sentry_environment=production;"}]; 
    headers['x-content-type-options'] = [{key: 'X-Content-Type-Options', value: 'nosniff'}]; 
    headers['x-frame-options'] = [{key: 'X-Frame-Options', value: 'DENY'}]; 
    headers['x-xss-protection'] = [{key: 'X-XSS-Protection', value: '1; mode=block'}]; 
    headers['referrer-policy'] = [{key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin'}];

    // Return modified response
    callback(null, response);
};
