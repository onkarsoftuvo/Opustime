app.directive('helpbar', function(){
      return {
        restrict: 'E',
        templateUrl: 'assets/angular/directives/HelpBar.html',
        link:function(scope,element, attributes){
          scope.showHelpbar = function(){
            scope.show_help = true;
          }
          scope.show_help = false;
          scope.closeHelp = function(){
            scope.show_help = false
          }
        }
      };
  });