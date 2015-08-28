//= require jquery
//= require jquery_ujs
//= require jquery_tablesorter
//= require bootstrap-sprockets

$(document).ready(function(){
  $("table").tablesorter( {sortList: [[0,0], [1,0]]} );
});
