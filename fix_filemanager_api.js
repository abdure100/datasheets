/**
 * Fix FileManager API Domain and Handle Errors
 * 
 * This script intercepts filemanager API calls and:
 * 1. Updates the domain from eidbi.sphereemr.com to fms.sphereemr.com
 * 2. Handles errors gracefully
 * 3. Provides better error messages
 */

(function() {
    'use strict';
    
    console.log('🔧 Fixing filemanager API calls...');
    
    // Store original jQuery ajax if available
    let originalAjax;
    if (typeof jQuery !== 'undefined' && jQuery.ajax) {
        originalAjax = jQuery.ajax;
    }
    
    // Function to fix URL domain
    function fixDomain(url) {
        if (!url) return url;
        
        // Replace eidbi.sphereemr.com with fms.sphereemr.com
        if (url.includes('eidbi.sphereemr.com')) {
            const fixedUrl = url.replace(/eidbi\.sphereemr\.com/g, 'fms.sphereemr.com');
            console.log('🔧 Fixed domain:', url, '→', fixedUrl);
            return fixedUrl;
        }
        
        return url;
    }
    
    // Override jQuery ajax to intercept filemanager calls
    if (typeof jQuery !== 'undefined') {
        jQuery.ajaxSetup({
            beforeSend: function(jqXHR, settings) {
                // Check if this is a filemanager API call
                if (settings.url && settings.url.includes('filemanager')) {
                    // Fix the domain
                    settings.url = fixDomain(settings.url);
                    
                    // Add error handling
                    const originalError = settings.error;
                    settings.error = function(xhr, status, error) {
                        console.error('❌ FileManager API Error:', {
                            url: settings.url,
                            status: xhr.status,
                            statusText: xhr.statusText,
                            error: error,
                            response: xhr.responseText
                        });
                        
                        // Show user-friendly error message
                        if (xhr.status === 500) {
                            console.error('⚠️ Server error (500) - The server encountered an error processing the request');
                            // You can show a toast notification here if toastr is available
                            if (typeof toastr !== 'undefined') {
                                toastr.error('Unable to create folder. Please try again or contact support.', 'Server Error', {
                                    timeOut: 5000,
                                    positionClass: 'toast-bottom-right'
                                });
                            }
                        } else if (xhr.status === 403) {
                            console.error('⚠️ Forbidden (403) - You do not have permission to perform this action');
                            if (typeof toastr !== 'undefined') {
                                toastr.warning('You do not have permission to perform this action.', 'Access Denied', {
                                    timeOut: 5000,
                                    positionClass: 'toast-bottom-right'
                                });
                            }
                        }
                        
                        // Call original error handler if it exists
                        if (originalError && typeof originalError === 'function') {
                            originalError.call(this, xhr, status, error);
                        }
                    };
                }
            }
        });
        
        console.log('✅ jQuery ajax interceptor set up');
    }
    
    // Also intercept XMLHttpRequest for non-jQuery calls
    if (typeof XMLHttpRequest !== 'undefined') {
        const originalOpen = XMLHttpRequest.prototype.open;
        const originalSend = XMLHttpRequest.prototype.send;
        
        XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
            // Fix domain if it's a filemanager call
            if (url && url.includes('filemanager')) {
                url = fixDomain(url);
                console.log('🔧 Fixed XMLHttpRequest URL:', url);
            }
            return originalOpen.call(this, method, url, async, user, password);
        };
        
        XMLHttpRequest.prototype.send = function(data) {
            // Add error listener
            this.addEventListener('error', function() {
                if (this.responseURL && this.responseURL.includes('filemanager')) {
                    console.error('❌ XMLHttpRequest FileManager Error:', {
                        url: this.responseURL,
                        status: this.status,
                        statusText: this.statusText
                    });
                }
            });
            
            return originalSend.call(this, data);
        };
        
        console.log('✅ XMLHttpRequest interceptor set up');
    }
    
    // Fix any existing URLs in the page
    function fixPageUrls() {
        // Fix links
        const links = document.querySelectorAll('a[href*="eidbi.sphereemr.com"]');
        links.forEach(link => {
            link.href = fixDomain(link.href);
        });
        
        // Fix form actions
        const forms = document.querySelectorAll('form[action*="eidbi.sphereemr.com"]');
        forms.forEach(form => {
            form.action = fixDomain(form.action);
        });
        
        if (links.length > 0 || forms.length > 0) {
            console.log('✅ Fixed', links.length + forms.length, 'URLs in page');
        }
    }
    
    // Run on page load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', fixPageUrls);
    } else {
        fixPageUrls();
    }
    
    // Watch for dynamically added elements
    if (typeof MutationObserver !== 'undefined') {
        const observer = new MutationObserver(function(mutations) {
            fixPageUrls();
        });
        
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }
    
    console.log('✅ FileManager API fix script initialized');
})();

