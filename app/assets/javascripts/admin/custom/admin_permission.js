$( document ).ready(function() {

    role  = {0: 'admin_user' , 1: 'sales_user' , 2:'marketing_user'}
    // Business Report selection
    $("input[class='icheck-me']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
        module_name = split_name_arr[0] ;
        split_name_arr.splice(-1,1)  // removing last element
        tag_name = split_name_arr.join("_") + "_"

        $("input[id^=" + tag_name + "]").each(function( index ) {
            if ($(this).parent().hasClass("checked")){
                data[role[index]] = true
            }else{
                data[role[index]] = false
            }
        });

        // setting value for current check box
        current_index = $(this).attr("id").split("_")[2]
        data[role[current_index-1]] = (event.type == "ifChecked" ? true : false)
        console.log(data)

        // ajax hit
        $.ajax({
            url: "/admin/user_permission/apply",
            data: {data: data , col_name:col_name , module_name: module_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });
});