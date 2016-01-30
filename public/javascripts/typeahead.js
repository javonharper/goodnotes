$(function() {
  var artists = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: '/autocomplete/%QUERY'
  });

  artists.initialize();

  $('.artist-typeahead').typeahead(null, {
    name: 'artists',
    displayKey: 'value',
    source: artists.ttAdapter(),
    templates: {
      empty: ['<div class="empty-message">', 'No artists found', '</div>'].join('\n'),
      suggestion: _.template('<div class="autocomplete-suggestion"> <strong> <%= value %> </strong> </div>')
    }
  });

  $('.artist-typeahead').on('typeahead:selected', function(event, suggestion, dataset) {
      $('form').submit();
  });
});
