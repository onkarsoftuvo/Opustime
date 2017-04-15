app.directive('customBookingIframe', function () {
  return {
    restrict: 'A',
    templateUrl: 'assets/angular/customIframeTemplate.html',
    link: function (scope, element) {
      var origin_location = location.origin.replace('http://','https://');      
      var url = origin_location+'/booking';
      // var url = location.origin+'/booking?comp_id='+scope.comp_id;
      var frameHeight = 300;
      var codeHolder = document.getElementById('iframeCode')
      var btnele = document.getElementById('frameHeight')
      btnele.value = frameHeight;
      
      //update code 
      function updateCode() {
        var buttoncode = '<iframe id="OB_iframe" src="' + url + '" style="width:100%; height:' + frameHeight + 'px; border: 1px solid rgb(128, 128, 128);"></iframe>';
        codeHolder.value = buttoncode;
      }
      updateCode();

      //text update
      btnele.addEventListener('keyup', function () {
        var k = this.value;
        var heightData = k.split('');
        for(i=0; i<heightData.length; i++){
          var makeInt = parseInt(heightData[i]);
          if(Number.isInteger(makeInt)){
            frameHeight = this.value;
            updateCode();
          }
          else{
           var newInt='';
           heightData.splice(i, 1);
           for(j=0; j<heightData.length; j++){
            newInt+=heightData[j];
           }
           frameHeight = parseInt(newInt);
           btnele.value = frameHeight;
           updateCode()
          }
        }
      })  
      var copyembeded = element.find('#copyembeded span');
      copyembeded.hide();
      var copyBtn = document.getElementById('copyembeded');
      copyBtn.addEventListener('click', function () {
        copyToClipboard();
        copyembeded.show(250);
        setTimeout(function(){ 
          copyembeded.hide(250);
        }, 2000);
      });

      //copy
      function copyToClipboard(elementId) {
        // Create a "hidden" input
        var aux = document.createElement('input');
        // Assign it the value of the specified element
        aux.setAttribute('value', codeHolder.value);
        // Append it to the body
        document.body.appendChild(aux);
        // Highlight its content
        aux.select();
        // Copy the highlighted text
        document.execCommand('copy');
        // Remove it from the body
        document.body.removeChild(aux);
      }

    }
  }
});
