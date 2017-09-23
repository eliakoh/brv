var $current = null;
var shown = false;

$(function() {
  $current = $('#menu-root');
  setCurrentItem($current.children('li:first'))

  $('li[data-target]').addClass('has-children');

  window.addEventListener('message', function(event) {
    if (event.data.enableui) {
      $('.container').toggle();
      shown = !shown;
    }

    if(shown) {
      $current.show();
    }
  }, false);

  $(document).on('keydown', function(event) {
    if(shown) {
      event.preventDefault();
      var $currentLi = $current.children('li.current');
      switch(event.which) {
        case 37: // left
          if($current.attr('id') != 'menu-root') {
            var $previousLi = $('li[data-target="' + $current.data('id') + '"]');
            var $previousUl = $previousLi.parent('ul');
            changeMenu($current, $previousUl, $previousLi);
            $currentLi.removeClass('current');
          }
          else {
            closeMenu();
          }
        break;

        case 39: // right
        if($currentLi.data('target')) {
          $currentLi.trigger('click');
          $currentLi.removeClass('current');
        }
        else if($currentLi.data('callback')) {
          var obj = {
            callback: $currentLi.data('callback'),
            source: $currentLi.data('id')
          }
          $.post('http://brv_menu/callbackMenu', JSON.stringify(obj), function(data) {
            if($currentLi.data('close')) {
              closeMenu();
            }
          });
        }
        else if($currentLi.data('server-callback')) {
          var obj = {
            callback: $currentLi.data('server-callback'),
            source: $currentLi.data('id')
          }
          $.post('http://brv_menu/serverCallbackMenu', JSON.stringify(obj), function(data) {
            if($currentLi.data('close')) {
              closeMenu();
            }
          });
        }
        break;

        case 38: // up
        if($current.children('li').index($currentLi) > 0) {
          setCurrentItem($currentLi.prev())
          $currentLi.removeClass('current');
        }
        break;

        case 40: // down
        if($current.children('li').index($currentLi) < ($current.children('li').length - 1)) {
          setCurrentItem($currentLi.next());
          $currentLi.removeClass('current');
        }
        break;
      }
    }
  });

  $('li').on('click', function(e) {
    var target = $(this).data('target');
    if(target != '') {
      var $children = $('ul[data-id="' + target + '"]');
      if($children.length > 0) {
        changeMenu($current, $children);
      }
    }
  });

  function changeMenu(currentMenu, newMenu, currentLi) {
    currentMenu.hide(0, 350, function() {
      newMenu.show(0, function() {
        $current = newMenu;
        if(currentLi == undefined) {
          currentLi = $current.children('li:first');
        }
        setCurrentItem(currentLi);
      });
    })
  }

  function setCurrentItem($li) {
    $li.addClass('current');
    var offset = $current.scrollTop();
    var liTop = $li.position().top;

    if(liTop - $li.height() > $current.height()) {
      $current.scrollTop($current.height() + offset);
    }
    else if(liTop < $current.position().top) {
      $current.scrollTop(offset - $current.height());
    }

    if($li.data('desc')) {
      $('.footer').html('<span>' + $li.data('desc') + '</span>');
      $('.footer').show();
    }
    else {
      $('.footer').hide();
      $('.footer').html('');
    }
  }

  function closeMenu() {
    $('li.current').removeClass('current');

    $current = $('#menu-root');
    setCurrentItem($current.children('li:first'))

    shown = false;

    $('ul').hide();
    $('.container').hide();
    $.post('http://brv_menu/hideMenu', null);
  }
});
