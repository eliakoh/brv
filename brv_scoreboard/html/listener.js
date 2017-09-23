$(function() {
  window.addEventListener('message', function(event) {
    var item = event.data;
    if (item.meta && item.meta == 'close') {
      $('#wrap, #global').fadeToggle(function() {
        $('table').html('');
      });
      return;
    }
    var buf = $('#wrap');
    buf.find('table').append('<tr class="heading"><th>ID</th><th>Name</th><th>Kills</th><th>Rank</th></tr>');
    buf.find('table').append(item.text);

    var buf = $('#global');
    buf.find('table').append('<tr class="heading"><th>Name</th><th>Games</th><th>Wins</th><th>Kills</th></tr>');
    buf.find('table').append(item.global);
    var d = new Date(item.lastUpdated);
    var updated = d.toLocaleDateString('en-GB', {
      day : 'numeric',
      month : 'short',
      year : 'numeric',
      hour : 'numeric',
      minute : 'numeric'
    })
    $('#last-updated').html(updated);
    $('#wrap, #global').fadeToggle('fast');
  }, false);
});
