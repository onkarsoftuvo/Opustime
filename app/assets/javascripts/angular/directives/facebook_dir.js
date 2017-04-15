app.directive('customFacebook', function ($http) {
  return {
    FacebookPageId :'=',
    template: '<button class="btn btn-default add_online" type="button" ng-click="addTab()">Add Online Booking to Facebook</button>',
    link: function(scope){
      console.log(window.location.origin + '/#!/settings/online-booking');
     //local  
      /*window.FB.init({
        appId: '439980326202518',
        xfbml      : true,
        version: 'v2.6' // or v2.0, v2.1, v2.2, v2.3
      }); */
      
      //live
       window.FB.init({
          appId: '1104113702960985',
          xfbml      : true,
          version: 'v2.6' // or v2.0, v2.1, v2.2, v2.3
        });


      //staging
      //  window.FB.init({
      //      appId: '733316870157714',
      //      xfbml      : true,
      //      version: 'v2.6' // or v2.0, v2.1, v2.2, v2.3
      //  });
      scope.addTab = addTab;
      function addTab(){
        var host_url_link = window.location.origin;
          host_url_link = host_url_link.replace('http://','https://');

          /* var key='246100575767224'
               $http.put('settings/integrations/fb/page_id', {fb_page_id:key}).then(function(result){
                 console.log(result)
               })*/
        FB.ui({
          method: 'pagetab', 
          redirect_uri: host_url_link + '/#!/settings/online-booking'
        }, function(response){
          console.log(response);
          for (var key in response.tabs_added) {
            //key='246100575767224';
            $http.put('settings/integrations/fb/page_id', {fb_page_id:key}).then(function(result){
              console.log(result);
              scope.FacebookPageId.push(key)
            });
          }
        });
      }
    }
  };
});
