angular.module('Zuluapp').config(function ($translateProvider) {
  $translateProvider.useStaticFilesLoader({
    prefix: 'assets/angular/common/language/lang-',
    suffix: '.json'
  });
  /*language translator*/
  lang = localStorage.getItem('preferredLang');
   if(lang == undefined){
     lang = 'en';
   }
   $translateProvider.preferredLanguage(lang);
});
