var toast = {

    success_message: function (message) {
        var myToast = $.toast({
            text: message,
            icon: 'success',
            bgColor: 'green',
            showHideTransition: 'fade',
            position: 'bottom-right'
        });
    },

    error_message: function (message) {
        var myToast = $.toast({
            text: message,
            icon: 'error',
            hideAfter: false,
            bgColor: 'red',
            hideAfter : 5000,
            position: 'bottom-right'

        });
    },

    multiple_error_messages : function (array) {
        messgae = ''
        if (typeof(a) == 'object'){
            for ( var i = 0, l = array.length; i < l; i++ ) {
                messgae = messgae.concat(i+1+': '+array[i].error_name).concat(' '+array[i].error_msg)+'\n';
            }
        } else {
            messgae =  array
        }
        var myToast = $.toast({
            text: messgae,
            icon: 'error',
            hideAfter: false,
            bgColor: 'red',
            hideAfter : 5000,
            position: 'bottom-right'

        });
    }

};