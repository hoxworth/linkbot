$(document).ready(function(e) {

  //make connection row appear darker and make the edit icon visible
  $('.connection-row-container').hover(
    function() {
      $(this).addClass('hover');
      $(this).children('.connection-row-glyph').removeClass('invisible');
    }, function() {
      $(this).removeClass('hover');
      $(this).children('.connection-row-glyph').addClass('invisible');
    }
  );

  //when the connection edit-glyph is clicked to modify a connection
  $('.connection-row-glyph').click(function() {
    textval = $(this).parent().children('.connection-row-value').text();
    //text in div is gone, form is present instead with user input, get the
    //placeholder for original text
    if (textval === "") {
      textval = $(this).parent().children('.connection-row-value').children('.connection-row-value-input').attr('placeholder');
    }

    $(this).parent().children('connection-row-value').children('.connection-row-value-input').remove();

    // create a new input
    input = document.createElement('input');
    $(input).attr('class', 'form-control connection-row-value-input');
    $(input).attr('type', 'email');
    $(input).attr('placeholder', textval);
    $(this).parent().children('.connection-row-value').text('');
    $(this).parent().children('.connection-row-value').append(input);
  });

  //Edit plugin config button is clicked
  $('.edit-config-button').click(function() {
    $(this).parent().parent().children('.configuration-container').toggleClass('invisible');
  });

  //'+' signed clicked on in plugin array configuration to add a new form
  $('.plugin-array-add-form').click(function() {
    input = document.createElement('input');
    $(input).attr('type', 'text');
    $(input).attr('class', 'form-control array-form');
    $(input).attr('placeholder', 'New Value');
    $(input).attr('added', 'true');
    $(this).parent().children('.form-control.array-form:last').after(input);
  });

});
