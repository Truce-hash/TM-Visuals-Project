// Please see documentation at https://learn.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

// Write your JavaScript code.

var portfolioFilters = document.querySelector('[data-portfolio-filters]');
if (portfolioFilters) {
    var portfolioCards = document.querySelectorAll('[data-portfolio-category]');

    portfolioFilters.addEventListener('click', function (event) {
        var button = event.target.closest('[data-portfolio-filter]');
        if (!button) return;

        var selectedCategory = button.dataset.portfolioFilter.toLowerCase();
        portfolioFilters.querySelectorAll('[data-portfolio-filter]').forEach(function (filter) {
            var isActive = filter === button;
            filter.classList.toggle('is-active', isActive);
            filter.setAttribute('aria-pressed', isActive);
        });

        portfolioCards.forEach(function (card) {
            var cardCategory = card.dataset.portfolioCategory.toLowerCase();
            card.hidden = selectedCategory !== 'all' && cardCategory !== selectedCategory;
        });
    });
}
