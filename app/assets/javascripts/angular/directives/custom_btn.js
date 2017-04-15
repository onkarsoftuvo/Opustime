app.directive('customBookingBtn', function () {
  return {
    restrict: 'A',
    templateUrl: 'assets/angular/customBtnTemplate.html',
    link: function (scope, element) {
      // appending swatches
      var colors = [
        '#56b59d',
        '#2fcc71',
        '#3598dc',
        '#ab85ff',
        '#e884ff',
        '#f1c40f',
        '#e77e23',
        '#e84c3d',
        '#da1c5c',
        '#34495e'
      ];
      var colorLi = '';
      colors.forEach(function (code) {
        colorLi += '<li style="background:' + code + '" data-color="' + code + '"></li>'
      })
      document.querySelector('.swatches').innerHTML = colorLi;
      
      // buttion text input
      var ccode = '#56b59d'
      var btn_text = 'Book Now';
      var codeHolder = document.getElementById('code')
      var btnele = document.getElementById('btn_text')
      btnele.value = btn_text
      var preview = document.getElementById('OB_openbtn');
      
      //update code 
      function updateCode() {
        var origin_location = location.origin.replace('http://','https://');      
        // var url = origin_location+'/booking?comp_id='+scope.comp_id;
        window.opb_url=origin_location+'/booking';
        var buttoncode = '<div id="OB_Opus"><a href="javascript:void(0);" style="background-color:' + ccode + '" id="OB_openbtn" onClick="openIframe()">' + btn_text + '</a></div><script>window.opb_url="'+location.origin+'/booking"; var head = document.head, script = document.createElement("script");script.src = "'+location.origin+'/custom_btn/button.js";head.appendChild(script);link = document.createElement("link");link.type = "text/css";link.rel = "stylesheet";link.href = "'+location.origin+'/assets/main_app/custombtnStyle.css";head.appendChild(link);</script>';
        codeHolder.value = buttoncode;
        preview.style.backgroundColor = ccode;
        preview.innerHTML = btn_text
      }
      updateCode()      
      
      //color update
      element.find('.swatches li:first-child').addClass('active_color')
      NodeList.prototype.forEach = Array.prototype.forEach;
      var colorele = document.querySelectorAll('.swatches li');
      colorele.forEach(function (clr) {
        clr.addEventListener('click', function () {
          ccode = this.getAttribute('data-color');
          element.find('.swatches li').removeClass('active_color')
          this.setAttribute('class', 'active_color')
          updateCode();
        });
      })   

      //text update
      btnele.addEventListener('keyup', function () {
        btn_text = this.value;
        updateCode()
      });

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
