app.directive('dialogPanel', function(){
      return {
        restrict: 'E',
        transclude: true,
        scope: { 
          header:'=',
          save:'&'
        },
        templateUrl: 'assets/angular/directives/Container.html',
        link:function(scope,element, attributes){
        }
      };
  })
  .directive('dialogHeader', function(){
      return {
        restrict: 'E',
        transclude: true,
        scope: { header:'=' },
        templateUrl: 'assets/angular/directives/Header.html',
        link:function(scope, element, attributes){
          console.log(scope.header)
          scope.onlick = function(){
            console.log(attributes)
          }
        }
      };

  })

