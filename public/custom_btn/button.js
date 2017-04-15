var checkExist = setInterval(function() {
   if ($('#OB_Opus').length) {
		console.log("Exists!");
		var OB_body = document.getElementById('OB_Opus')
		url = ''
		var bodyC = '<div class="OB_overlay" id="overlay" style="display:none"><div class="OB_Content"><iframe id="OB_iframe" src="' + url + '"></iframe><a class="OB_close" href="javascript:void(0)">x</a></div>'
		var linkb = document.getElementById('OB_openbtn');

		//OB_body.innerHTML = linkb.outerHTML+bodyC;
		function insertAfter(referenceNode, newNode) {
			referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
		}
		var el = document.createElement('div');
		el.innerHTML = bodyC
		insertAfter(linkb, el);

		var close = document.querySelector('.OB_close');
		close.addEventListener('click', function () {
			document.getElementById('overlay').style.display = 'none';
		});

		//closing frame
		var closeIt = document.querySelector('.OB_overlay');
		closeIt.addEventListener('click', function () {
			document.getElementById('overlay').style.display = 'none';
		});
		clearInterval(checkExist);
   }
}, 100);

// var OB_body = document.getElementById('OB_Opus')
// url = ''
// var bodyC = '<div class="OB_overlay" id="overlay" style="display:none"><div class="OB_Content"><iframe id="OB_iframe" src="' + url + '"></iframe><a class="OB_close" href="javascript:void(0)">x</a></div>'
// var linkb = document.getElementById('OB_openbtn');

// //OB_body.innerHTML = linkb.outerHTML+bodyC;
// function insertAfter(referenceNode, newNode) {
//   referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
// }
// var el = document.createElement('div');
// el.innerHTML = bodyC
// insertAfter(linkb, el);

//opening frame
function openIframe() {
  url = window.opb_url
  //url = url.replace('watch?v=', 'v/');
  if (document.getElementById('overlay') == null)
  	insertAfter(linkb, el);
  else
  	document.getElementById('overlay').style.display = 'block';
  var iframe = document.getElementById('OB_iframe');
  iframe.src = url;
}


//closing frame
// var close = document.querySelector('.OB_close');
// close.addEventListener('click', function () {
//   document.getElementById('overlay').style.display = 'none';
// });

// //closing frame
// var closeIt = document.querySelector('.OB_overlay');
// closeIt.addEventListener('click', function () {
//   document.getElementById('overlay').style.display = 'none';
// });

