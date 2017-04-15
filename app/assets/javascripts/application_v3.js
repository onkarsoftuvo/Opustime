// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//= require jquery
//= require jquery_ujs
//= require jquery.remotipart
//= require_tree ./admin_dashboard
//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require dataTables/extras/dataTables.responsive
//= require 'icheck'
//= require bootstrap.min
//=require moment.min.js
//=require dataTable_redraw.js
//=require raphel.min.js
//= require Chart.bundle.min
//=require button_loader.min.js
//= require jquery.toast.min.js
//= require bootstrap-switch

 $(document).ready(function(){

 	var myvalues1 = [10,8,5,7,4,4,8];
        $('.dynamicsparkline').sparkline(myvalues1,{width: '80px',height: '50px', barColor: 'blue',lineWidth: 2}); 
 	 var myvalues = [2,30,13,58,85];
   $('.inlinesparkline').sparkline(myvalues,{width: '80px',height: '50px', barColor: 'blue',lineWidth: 2});
   var myvalues = [32,60,13,28,87];
   $('.inlinesparkline1').sparkline(myvalues,{width: '80px',height: '50px', barColor: 'blue',lineWidth: 2});
 });
    
 $(document).ready(function(){
      $(".dial").knob();
    });



$(document).ready(function() {
  $.AdminLTE.layout.activate();
});

$(document).on('page:load', function() {
  var o;
  o = $.AdminLTE.options;
  if (o.sidebarPushMenu) {
    $.AdminLTE.pushMenu.activate(o.sidebarToggleSelector);
  }
  $.AdminLTE.layout.activate();
});

/*$(document).ready(function() {
var oTable = $('#example1,#example2,#example3,#example4,#example5,#example6,#example7,#example8,#example9,#example10,#example11').dataTable( {
"oLanguage": {
"sEmptyTable": "No data Avaialable"

}
});
}); */
/*$(document).ready(function(){
  $("#tab").tabs({
      active: localStorage.getItem("currentTabIndex"),
      activate: function(event, ui) {
          localStorage.setItem("currentTabIndex", ui.newPanel[0].dataset["tabIndex"]);
      }
  });
});*/
