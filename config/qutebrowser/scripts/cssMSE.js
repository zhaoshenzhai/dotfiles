// ==UserScript==
// @name         MSE custom CSS
// @version      0.0.1
// @description  Custom CSS for https://math.stackexchange.com
// @author       Zhaoshen Zhai
// @match        https://math.stackexchange.com/*
// @run-at       document-start
// ==/UserScript==

(function IIFE() {
    'use strict';

    document.addEventListener('readystatechange', function onReadyStateChange() {
        if (document.readyState == 'interactive') {
            const style = document.createElement('style');
            document.head.appendChild(style);
            style.innerHTML = `

/* body, #content, .s-topbar, .question-page, .unified-theme, .answer-votes.default {
    background-color: #1E2127 !important;
    color: #F8F8FF !important;
    border: none !important;
}

#h-related, #h-linked {
    color: #F8F8FF !important;
}

.question-page, .unified-theme {
    background-image: none !important;
}

.s-sidebarwidget.s-sidebarwidget__yellow, .site-header {
    border: none !important;
    content-visibility: hidden !important;
}

.answered-accepted {
    color: #18864B !important;
} */

            `;
        }
    });
})();
