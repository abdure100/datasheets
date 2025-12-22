/**
 * Hide FileManager Tab on Documents Index Page
 * 
 * This script hides the filemanager tab/button on the patient details documents page.
 * It prevents the 403 Forbidden error from appearing when the filemanager tries to load.
 * 
 * Usage: Add this script to your documents page or inject it via FileMaker web viewer
 */

(function() {
    'use strict';
    
    console.log('🔒 Hiding filemanager tab on documents page...');
    
    // Function to hide filemanager elements
    function hideFileManagerTab() {
        // Try multiple selectors to find the filemanager tab/button
        const selectors = [
            // Common tab/button selectors
            '[data-tab="filemanager"]',
            '[id*="filemanager"]',
            '[class*="filemanager"]',
            '[class*="file-manager"]',
            'a[href*="filemanager"]',
            'button[onclick*="filemanager"]',
            // More specific selectors
            '.nav-tab[data-tab="filemanager"]',
            '.tab-filemanager',
            '#filemanager-tab',
            '#filemanagerTab',
            // FileManager button/link patterns
            'a:contains("File Manager")',
            'button:contains("File Manager")',
            '[title*="File Manager"]',
            '[aria-label*="File Manager"]',
        ];
        
        let hidden = false;
        
        // Try each selector
        selectors.forEach(selector => {
            try {
                const elements = document.querySelectorAll(selector);
                elements.forEach(el => {
                    if (el && el.offsetParent !== null) { // Check if element is visible
                        el.style.display = 'none';
                        el.style.visibility = 'hidden';
                        el.setAttribute('data-hidden-by-script', 'true');
                        hidden = true;
                        console.log('✅ Hidden filemanager element:', selector);
                    }
                });
            } catch (e) {
                // Selector might not be valid, skip it
            }
        });
        
        // Also try jQuery if available (common in FileMaker web viewers)
        if (typeof jQuery !== 'undefined') {
            try {
                // Hide elements containing "filemanager" in various attributes
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
                        hidden = true;
                        console.log('✅ Hidden filemanager element via jQuery');
                    }
                });
            } catch (e) {
                console.log('⚠️ jQuery selector error:', e);
            }
        }
        
        // Prevent the loadFoldersAndFiles function from executing
        if (typeof window.loadFoldersAndFiles === 'function') {
            const originalLoadFoldersAndFiles = window.loadFoldersAndFiles;
            window.loadFoldersAndFiles = function() {
                console.log('🚫 Blocked loadFoldersAndFiles call');
                return false; // Prevent execution
            };
            console.log('✅ Blocked loadFoldersAndFiles function');
            hidden = true;
        }
        
        return hidden;
    }
    
    // Run immediately
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', hideFileManagerTab);
    } else {
        hideFileManagerTab();
    }
    
    // Also run after a short delay to catch dynamically loaded content
    setTimeout(hideFileManagerTab, 500);
    setTimeout(hideFileManagerTab, 1000);
    setTimeout(hideFileManagerTab, 2000);
    
    // Use MutationObserver to hide elements that are added dynamically
    if (typeof MutationObserver !== 'undefined') {
        const observer = new MutationObserver(function(mutations) {
            hideFileManagerTab();
        });
        
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
        
        console.log('✅ MutationObserver set up to watch for dynamically added elements');
    }
    
    console.log('✅ FileManager tab hiding script initialized');
})();
