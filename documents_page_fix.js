/**
 * Complete Documents Page Fix
 * 
 * This script:
 * 1. Hides the filemanager tab
 * 2. Fixes API domain from eidbi.sphereemr.com to fms.sphereemr.com
 * 3. Handles errors gracefully
 * 
 * Add this script to your documents page to fix all issues
 */

(function() {
    'use strict';
    
    console.log('🔧 Initializing documents page fixes...');
    
    // ============================================
    // PART 1: Hide FileManager Tab
    // ============================================
    function hideFileManagerTab() {
        const selectors = [
            '[data-tab="filemanager"]',
            '[id*="filemanager"]',
            '[class*="filemanager"]',
            '[class*="file-manager"]',
            'a[href*="filemanager"]',
            'button[onclick*="filemanager"]',
            '.nav-tab[data-tab="filemanager"]',
            '.tab-filemanager',
            '#filemanager-tab',
            '#filemanagerTab',
        ];
        
        selectors.forEach(selector => {
            try {
                const elements = document.querySelectorAll(selector);
                elements.forEach(el => {
                    if (el && el.offsetParent !== null) {
                        el.style.display = 'none';
                        el.style.visibility = 'hidden';
                        el.setAttribute('data-hidden-by-script', 'true');
                    }
                });
            } catch (e) {}
        });
        
        // jQuery fallback
        if (typeof jQuery !== 'undefined') {
            try {
                jQuery('*').each(function() {
                    const $el = jQuery(this);
                    const text = $el.text().toLowerCase();
                    const id = ($el.attr('id') || '').toLowerCase();
                    const cls = ($el.attr('class') || '').toLowerCase();
                    const href = ($el.attr('href') || '').toLowerCase();
                    
                    if ((text.includes('file manager') || text.includes('filemanager') ||
                         id.includes('filemanager') || cls.includes('filemanager') ||
                         href.includes('filemanager')) && 
                        !$el.attr('data-hidden-by-script')) {
                        $el.hide();
                        $el.attr('data-hidden-by-script', 'true');
                    }
                });
            } catch (e) {}
        }
    }
    
    // ============================================
    // PART 2: Fix API Domain
    // ============================================
    function fixDomain(url) {
        if (!url) return url;
        if (url.includes('eidbi.sphereemr.com')) {
            const fixedUrl = url.replace(/eidbi\.sphereemr\.com/g, 'fms.sphereemr.com');
            console.log('🔧 Fixed domain:', url, '→', fixedUrl);
            return fixedUrl;
        }
        return url;
    }
    
    // Intercept jQuery ajax
    if (typeof jQuery !== 'undefined' && jQuery.ajax) {
        jQuery.ajaxSetup({
            beforeSend: function(jqXHR, settings) {
                // Fix domain for all API calls
                if (settings.url) {
                    settings.url = fixDomain(settings.url);
                }
                
                // Enhanced error handling for filemanager endpoints
                if (settings.url && settings.url.includes('filemanager')) {
                    const originalError = settings.error;
                    settings.error = function(xhr, status, error) {
                        console.error('❌ FileManager API Error:', {
                            url: settings.url,
                            status: xhr.status,
                            statusText: xhr.statusText,
                            error: error
                        });
                        
                        // User-friendly error messages
                        if (typeof toastr !== 'undefined') {
                            if (xhr.status === 500) {
                                toastr.error(
                                    'Unable to create folder. The server encountered an error. Please try again or contact support.',
                                    'Server Error',
                                    { timeOut: 6000, positionClass: 'toast-bottom-right' }
                                );
                            } else if (xhr.status === 403) {
                                toastr.warning(
                                    'You do not have permission to perform this action.',
                                    'Access Denied',
                                    { timeOut: 5000, positionClass: 'toast-bottom-right' }
                                );
                            } else if (xhr.status === 404) {
                                toastr.error(
                                    'The requested resource was not found. Please refresh the page.',
                                    'Not Found',
                                    { timeOut: 5000, positionClass: 'toast-bottom-right' }
                                );
                            }
                        }
                        
                        if (originalError && typeof originalError === 'function') {
                            originalError.call(this, xhr, status, error);
                        }
                    };
                }
            }
        });
    }
    
    // Intercept XMLHttpRequest
    if (typeof XMLHttpRequest !== 'undefined') {
        const originalOpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
            url = fixDomain(url);
            return originalOpen.call(this, method, url, async, user, password);
        };
    }
    
    // Fix page URLs
    function fixPageUrls() {
        document.querySelectorAll('a[href*="eidbi.sphereemr.com"]').forEach(link => {
            link.href = fixDomain(link.href);
        });
        document.querySelectorAll('form[action*="eidbi.sphereemr.com"]').forEach(form => {
            form.action = fixDomain(form.action);
        });
    }
    
    // ============================================
    // PART 3: Initialize Everything
    // ============================================
    function initialize() {
        hideFileManagerTab();
        fixPageUrls();
    }
    
    // Run immediately
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initialize);
    } else {
        initialize();
    }
    
    // Run after delays for dynamic content
    setTimeout(initialize, 500);
    setTimeout(initialize, 1000);
    setTimeout(initialize, 2000);
    
    // Watch for dynamically added content
    if (typeof MutationObserver !== 'undefined') {
        const observer = new MutationObserver(function() {
            hideFileManagerTab();
            fixPageUrls();
        });
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }
    
    console.log('✅ Documents page fixes initialized');
})();

