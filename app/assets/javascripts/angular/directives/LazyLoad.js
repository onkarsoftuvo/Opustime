app.directive('lazyload', [ "lazyload", "$rootScope" ,function ( lazyload, $rootScope) {
    return {
        restrict: 'A',
       scope:false,
        link:function(scope,element, attributes){
            $rootScope.$watch('ScrollPer', function(){
                if($rootScope.ScrollPer > 90){
                    scope.$eval(attributes.lazyload);
                }
            }) 
        }
    };
}]);