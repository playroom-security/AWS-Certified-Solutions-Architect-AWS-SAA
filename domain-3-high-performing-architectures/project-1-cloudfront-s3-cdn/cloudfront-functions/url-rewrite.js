/**
 * SAA Study Project 3.1 - CloudFront Function: URL Rewriter
 * Rewrites clean URLs to their index.html equivalents.
 * e.g., /blog → /blog/index.html
 *       /about → /about/index.html
 *
 * Associate this function with the VIEWER REQUEST event.
 */

function handler(event) {
  var request = event.request;
  var uri = request.uri;

  // If URI ends with '/', append 'index.html'
  if (uri.endsWith('/')) {
    request.uri += 'index.html';
  }
  // If URI has no file extension, treat as directory and add /index.html
  else if (!uri.includes('.')) {
    request.uri += '/index.html';
  }

  return request;
}
