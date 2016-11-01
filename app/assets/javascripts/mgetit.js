(function() {

  var manage_result_options = function() {
    /*
      Show More Sources/Links/Results
    */
    // Hide all but the first link on page load and then
    // show the rest of the links when "show more" is clicked.

    var show_more_sources = document.getElementById('show-more-sources');
    var digital_sources = document.getElementById('fulltext-sources').children;

    if (show_more_sources) { // only if there are more sources to show

      for (var i = 0; i < digital_sources.length; i++) {
        if (i > 0) {
          addClass(digital_sources[i], 'hide')
        }
      }

      removeClass(show_more_sources, 'hide')

      show_more_sources.addEventListener('click', function(event) {
        event.preventDefault();

        addClass(show_more_sources, 'hide')

        for (var i = 0; i < digital_sources.length; i++) {
          removeClass(digital_sources[i], 'hide')
        }
      })
    }

  }

  var dismiss = function() {
    var dismiss_elements = document.getElementsByClassName('dismiss');

    for (var i = 0; i < dismiss_elements.length; i++) {
      var dismiss_element = dismiss_elements[i];

      dismiss_element.addEventListener('click', function() {
        var id_to_dismiss = dismiss_element.getAttribute('data-dismiss')

        addClass(document.getElementById(id_to_dismiss), 'hide')
      })
    }
  }

  /*
    Helper Functions
  */
  function addClass(el, className) {
    if (el.classList)
      el.classList.add(className)
    else if (!hasClass(el, className)) el.className += " " + className
  }

  function removeClass(el, className) {
    if (el.classList)
      el.classList.remove(className)
    else if (hasClass(el, className)) {
      var reg = new RegExp('(\\s|^)' + className + '(\\s|$)')
      el.className=el.className.replace(reg, ' ')
    }
  }

  document.addEventListener("DOMContentLoaded", function(event) {
    manage_result_options()
    dismiss()
  })

})();
