app.directive('dialogDashboard', function(){
      return {
        restrict: 'E',
        transclude: true,
        scope: { 
          header:'=',
          save:'&'
        },
        templateUrl: 'assets/angular/directives/dashboardAppointment.html',
        link:function(scope,element, attributes){
          
        }
      };
  })

