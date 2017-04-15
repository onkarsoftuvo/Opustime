angular.module('onlineBooking').config(function ($translateProvider) {
  $translateProvider.useStaticFilesLoader({
    prefix: 'assets/online_booking/language/language-',
    suffix: '.json'
  });
  /*language translator*/
  lang = localStorage.getItem('preferredLang');
   if(lang == undefined){
     lang = 'en';
   }
   $translateProvider.preferredLanguage(lang);
});
