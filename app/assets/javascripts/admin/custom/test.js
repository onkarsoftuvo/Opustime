$( document ).ready(function() {
    
    role  = {0: "scheduler" , 1: "receptionist" , 2:"practitioner" , 3:"bookkeeper" , 4:"power receptionist" ,5:"administrator"}
    // appointment permission selection 
    $("input[id^='dashboard_']").on('ifChecked ifUnchecked', function(event){
	    data = {}
	    split_name_arr = $(this).attr("id").split("_")
	    col_name = split_name_arr[1] ; 
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
		  url: "/admin/permission/dashboard",
		  data: {data: data , col_name:col_name } ,
		  method: "POST" , 
		  dataType: "script",
		  beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
		});

    });

    // appointment permission selection
    $("input[id^='appnt_']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });



    // Patient permission selection
    $("input[id^='patient_']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/patient_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Patient_file permission selection
    $("input[id^='pntfile_']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/pntfile_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Announcement_message permission selection
    $("input[id^='announcemsg_']").on('ifChecked ifUnchecked', function(event){
        debugger
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/announcemsg_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // User_information permission selection
    $("input[id^='userinfo_']").on('ifChecked ifUnchecked', function(event){
        debugger
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/userinfo_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Invoice permission selection
    $("input[id^='invoice_']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/invoice_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Payment permission selection
    $("input[id^='payment_']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/payment_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Product permission selection
    $("input[id^='product_']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/product_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Expense permission selection
    $("input[id^='expense_']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/expense_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Contact permission selection
    $("input[id^='contact_']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/contact_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Communication permission selection
    $("input[id^='communication_']").on('ifChecked ifUnchecked', function(event){
        debugger
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/communication_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Medical permission selection
    $("input[id^='medical_']").on('ifChecked ifUnchecked', function(event){
        debugger
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/medical_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Treatment Notes permission selection
    $("input[id^='treatnote_']").on('ifChecked ifUnchecked', function(event){
        debugger
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/treatnote_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Treatment Notes permission selection
    $("input[id^='letter_']").on('ifChecked ifUnchecked', function(event){
        debugger
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/letter_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Treatment Notes permission selection
    $("input[id^='recall_']").on('ifChecked ifUnchecked', function(event){
        debugger
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/recall_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Treatment Notes permission selection
    $("input[id^='report_']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/report_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Data Export permission selection
    $("input[id^='dataexport_']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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

        // ajax hit
        $.ajax({
            url: "/admin/permission/dataexport_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

    // Setting permission selection
    $("input[id^='setting_']").on('ifChecked ifUnchecked', function(event){
        data = {}
        split_name_arr = $(this).attr("id").split("_")
        col_name = split_name_arr[1] ;
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
            url: "/admin/permission/setting_save",
            data: {data: data , col_name:col_name } ,
            method: "POST" ,
            dataType: "script",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))}
        });

    });

});