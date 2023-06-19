// ==UserScript==
// @name         GitHub custom CSS
// @version      0.0.1
// @description  Custom CSS for github.com
// @author       Zhaoshen Zhai
// @match        https://github.com/*
// @run-at       document-start
// ==/UserScript==

(function IIFE() {
    'use strict';

    document.addEventListener('readystatechange', function onReadyStateChange() {
        if (document.readyState == 'interactive') {
            const style = document.createElement('style');
            document.head.appendChild(style);
            style.innerHTML = `

body, #repository-container-header, .gh-header, .Header, .color-bg-default, .Box, .Box-header, .form-control, .form-select, .ajax-pagination-form .ajax-pagination-btn, .tabnav-tab.selected, .tabnav-tab[aria-current]:not([aria-current=false]), .tabnav-tab[aria-selected=true], .timeline-comment, .timeline-comment-header, .TimelineItem-break, .discussion-timeline-actions, .page-responsive .previewable-comment-form .comment-form-head.tabnav .toolbar-commenting, .TimelineItem--condensed .TimelineItem-badge, .diffbar, .pr-toolbar.is-stuck, .markdown-body table tr, .color-bg-inset, .user-status-circle-badge, .menu, .gh-header-sticky.is-stuck+.gh-header-shadow, .pagination-loader-container, .markdown-body img, .AppHeader {
    background-color: #1E2127 !important;
}

.TimelineItem-badge {
    border: none !important;
}

.markdown-body table tr:nth-child(2n) {
    background-color: var(--color-canvas-subtle) !important;
}

.color-shadow-medium {
    box-shadow: none !important;
}

            `;
        }
    });
})();
