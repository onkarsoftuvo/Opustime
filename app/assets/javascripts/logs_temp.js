var adminApp = angular.module('adminApplication', ['ui.bootstrap', 'bw.paging']);

adminApp.controller('logsCtrl',['$scope', '$rootScope', '$http', '$filter', '$uibModal', function($scope, $rootScope, $http, $filter, $uibModal){
	$scope.firstTab = true;
	$scope.secondTab = false;
	$scope.thirdTab = false;
	$scope.fourthTab = false;
    $scope.loading = false;

	$scope.openFirst = function(){
		$scope.firstTab = true;
		$scope.secondTab = false;
		$scope.thirdTab = false;
	    $scope.fourthTab = false;
	}
	$scope.openSecond = function(){
		$scope.firstTab = false;
		$scope.secondTab = true;
		$scope.thirdTab = false;
	    $scope.fourthTab = false;
        $scope.allQbLogs($scope.currentQBPage, $scope.qbNoOfPage, $scope.qbBusiness, $scope.qbfilter.start, $scope.qbfilter.end);
	}
	$scope.openThird = function(){
		$scope.firstTab = false;
		$scope.secondTab = false;
		$scope.thirdTab = true;
	    $scope.fourthTab = false;
        $scope.allAULogs($scope.currentAUPage, $scope.auNoOfPage, $scope.auBusiness, $scope.aufilter.start, $scope.aufilter.end);
	}
	$scope.openFourth = function(){
		$scope.firstTab = false;
		$scope.secondTab = false;
		$scope.thirdTab = false;
	    $scope.fourthTab = true;
        $scope.allADLogs($scope.currentADPage, $scope.adNoOfPage, $scope.adfilter.start, $scope.adfilter.end);
	}

    /*-------------------company logs Start----------------------*/
    $scope.filter = {};
    $scope.startDate = {'opened' : false};
    $scope.endDate = {'opened' : false};
    $scope.openStart = function(){
        $scope.startDate.opened = true;    
    }
    $scope.openEnd = function(){
        $scope.endDate.opened = true;    
    }
    $scope.filter.start = new Date();
    $scope.todayDate = new Date();
    $scope.currentPage = 1;
    $scope.appHearders = ['Sr. No', 'Error Class Name', 'Error Message', 'Error Trace', 'Params', 'Target URL', 'Time Stamp']
    $scope.appNoOfPage = '10';
    $scope.filterBtnActive = false;

    //get all companies list
    $scope.companies = function(){
        $http.get('/admin/opustime_logs/company_list').success(function(result){
            $scope.allComps = result;
            $scope.appBusiness = ''+result[0].id;
            $scope.qbBusiness = ''+result[0].id;
            $scope.auBusiness = ''+result[0].id;
            $scope.users(result[0].id);
        });
    }
    $scope.companies();
    var doRun = 0;
    //get all users list
    $scope.users = function(id){
        $scope.loading = true;
        $http.get('/admin/opustime_logs/company_user_list?company_id='+id).success(function(result){
            $scope.allUsers = result;
            $scope.loading = false;
            if(doRun == 0){
                $scope.allLogs($scope.currentPage, $scope.appNoOfPage, $scope.appBusiness, $scope.appUsers, $scope.filter.start, $scope.filter.end)
                doRun = 1;
            }
        });
    }

    $scope.allLogs = function(pageno, perPage, comp, user, start, end){
        $scope.loading = true;
        var data = {'company_id' : comp, 'user_id' : user, 'start_date' : start, 'end_date' : end, 'page_no' : pageno, 'per_page' : perPage}
        data.start_date = start.getFullYear() +'-'+ addZero(start.getMonth()+1) +'-'+ start.getDate(); 
        if (data.end_date) {
            data.end_date = end.getFullYear() +'-'+ addZero(end.getMonth()+1) +'-'+ end.getDate(); 
        }
        if ($scope.filterBtnActive) {
            data.isFilter = true;
            $scope.filterBtnActive = false;
        }
        
        $http.post('/admin/opustime_logs/company_logs', data).success(function(result){
            $scope.loading = false;
            if (result.flag) {
                $scope.appLogsDetail = result;
                if ($scope.currentPage > 1) {
                    $scope.sr = ($scope.currentPage - 1) * parseInt(perPage) + 1;
                }
                else{
                    $scope.sr = 1;
                }
                $scope.appLogsDetail.data.forEach(function(list){
                   list.srNo = $scope.sr;
                   $scope.sr += 1;
                })
                $scope.total_showing = $scope.appLogsDetail.data.length;
                $scope.paginationItems = [];
                $scope.drinks = [];

                var totalPages = $scope.appLogsDetail.total_page;
                for(i=1; i<=totalPages; i++){
                    $scope.paginationItems.push({'pageno':i})
                }

            }
        });
    }

    //update company
    $scope.updateCompany = function(comp_id){
        $scope.appUsers = undefined;
        $scope.users(comp_id);
    }
    //filter company logs
    $scope.filterLog = function(perPage, user){
        $scope.filterBtnActive = true;
        $scope.allLogs($scope.currentPage, perPage, $scope.appBusiness, user, $scope.filter.start, $scope.filter.end)
    }

    // change per page enteries
    $scope.updatePerPage = function(perPage, user){
        $scope.allLogs($scope.currentPage, perPage, $scope.appBusiness, user, $scope.filter.start, $scope.filter.end)
    }

    /*//next page
    $scope.nextPage = function(perPage, user){
        if ($scope.appLogsDetail.total_page != $scope.currentPage) {
            $scope.currentPage = $scope.currentPage+1;
            $scope.allLogs($scope.currentPage, perPage, $scope.appBusiness, user, $scope.filter.start, $scope.filter.end)
        }
    }
    //previous page
    $scope.prePage = function(perPage, user){
        if ($scope.currentPage != 1) {
            $scope.currentPage = $scope.currentPage-1;
            $scope.allLogs($scope.currentPage, perPage, $scope.appBusiness, user, $scope.filter.start, $scope.filter.end)
        }
    }*/
    //change page
    $scope.updatePage = function(no, perPage, user){
        $scope.currentPage = parseInt(no);
        $scope.allLogs($scope.currentPage, perPage, $scope.appBusiness, user, $scope.filter.start, $scope.filter.end)
    }

    $scope.openView = function(data){
        $scope.modalInstance = $uibModal.open({
            templateUrl: 'appLog.html',
            controller: 'appLogCtrl',
            size: 'lg',
            resolve: {
              data: function () {
                return data;
              }
            }
        });
    }

    /*-------------------company logs Ends----------------------*/

    /*-------------------QuickBook logs Start----------------------*/


    $scope.qbfilter = {};
    $scope.startDateQB = {'opened' : false};
    $scope.endDateQB = {'opened' : false};
    $scope.openQBStart = function(){
        $scope.startDateQB.opened = true;    
    }
    $scope.openQBEnd = function(){
        $scope.endDateQB.opened = true;    
    }
    $scope.qbfilter.start = new Date();

    $scope.currentQBPage = 1;
    $scope.qbHearders = ['Sr. No', 'Model Id', 'Model Name', 'Action Name', 'Message', 'Status', 'Time Stamp']
    $scope.qbNoOfPage = '10';
    $scope.filterQBBtnActive = false;

    $scope.allQbLogs = function(pageno, perPage, comp, start, end){
        $scope.loading = true;
        var data = {'company_id' : comp, 'start_date' : start, 'end_date' : end, 'page_no' : pageno, 'per_page' : perPage}
        data.start_date = start.getFullYear() +'-'+ addZero(start.getMonth()+1) +'-'+ start.getDate(); 
        if (data.end_date) {
            data.end_date = end.getFullYear() +'-'+ addZero(end.getMonth()+1) +'-'+ end.getDate(); 
        }
        if ($scope.filterQBBtnActive) {
            data.isFilter = true;
            $scope.filterQBBtnActive = false;
        }
        
        $http.post('/admin/opustime/quickbooks_logs', data).success(function(result){
            $scope.loading = false;
            if (result.flag) {
                $scope.qbLogsDetail = result;
                if ($scope.currentQBPage > 1) {
                    $scope.srQB = ($scope.currentQBPage - 1) * parseInt(perPage) + 1;
                }
                else{
                    $scope.srQB = 1;
                }
                $scope.qbLogsDetail.data.forEach(function(list){
                   list.srNo = $scope.srQB;
                   $scope.srQB += 1;
                })
                $scope.total_showingQB = $scope.qbLogsDetail.data.length;
                $scope.qbPaginationItems = [];
                var totalPages = $scope.qbLogsDetail.total_page;
                for(i=1; i<=totalPages; i++){
                    $scope.qbPaginationItems.push({'pageno':i})
                }

            }
        });
    }

    //filter company logs
    $scope.filterQBLog = function(perPage){
        $scope.filterQBBtnActive = true;
        $scope.allQbLogs($scope.currentQBPage, perPage, $scope.qbBusiness, $scope.qbfilter.start, $scope.qbfilter.end)
    }
    // change per page enteries
    $scope.updateQBPerPage = function(perPage){
        $scope.allQbLogs($scope.currentQBPage, perPage, $scope.qbBusiness, $scope.qbfilter.start, $scope.qbfilter.end)
    }

    /*//next page
    $scope.nextQBPage = function(perPage){
        if ($scope.qbLogsDetail.total_page != $scope.currentQBPage) {
            $scope.currentQBPage = $scope.currentQBPage+1;
            $scope.allQbLogs($scope.currentQBPage, perPage, $scope.qbBusiness, $scope.qbfilter.start, $scope.qbfilter.end)
        }
    }
    //previous page
    $scope.preQBPage = function(perPage){
        if ($scope.currentQBPage != 1) {
            $scope.currentQBPage = $scope.currentQBPage-1;
            $scope.allQbLogs($scope.currentQBPage, perPage, $scope.qbBusiness, $scope.qbfilter.start, $scope.qbfilter.end)
        }
    }*/
    //change page
    $scope.updateQBPage = function(no, perPage){
        $scope.currentQBPage = parseInt(no);
        $scope.allQbLogs($scope.currentQBPage, perPage, $scope.qbBusiness, $scope.qbfilter.start, $scope.qbfilter.end)
    }

    $scope.openQBView = function(data){
        $scope.modalInstance = $uibModal.open({
            templateUrl: 'qbLog.html',
            controller: 'qbLogCtrl',
            size: 'lg',
            resolve: {
              data: function () {
                return data;
              }
            }
        });
    }


    /*-------------------QuickBook logs Ends----------------------*/

    /*-------------------authorized logs Start----------------------*/

    $scope.aufilter = {};
    $scope.startDateAU = {'opened' : false};
    $scope.endDateAU = {'opened' : false};
    $scope.openAUStart = function(){
        $scope.startDateAU.opened = true;    
    }
    $scope.openAUEnd = function(){
        $scope.endDateAU.opened = true;    
    }
    $scope.aufilter.start = new Date();

    $scope.currentAUPage = 1;
    $scope.auHearders = ['Sr. No', 'Transaction Id', 'Transaction Type', 'Action Name', 'Amount', 'Response Code', 'Response Message', 'Status', 'Time Stamp']
    $scope.auNoOfPage = '10';
    $scope.filterAUBtnActive = false;

    $scope.allAULogs = function(pageno, perPage, comp, start, end){
        $scope.loading = true;
        var data = {'company_id' : comp, 'start_date' : start, 'end_date' : end, 'page_no' : pageno, 'per_page' : perPage}
        data.start_date = start.getFullYear() +'-'+ addZero(start.getMonth()+1) +'-'+ start.getDate(); 
        if (data.end_date) {
            data.end_date = end.getFullYear() +'-'+ addZero(end.getMonth()+1) +'-'+ end.getDate(); 
        }
        if ($scope.filterAUBtnActive) {
            data.isFilter = true;
            $scope.filterAUBtnActive = false;
        }
        
        $http.post('/admin/opustime/authorizenet_logs', data).success(function(result){
            $scope.loading = false;
            if (result.flag) {
                $scope.auLogsDetail = result;
                if ($scope.currentAUPage > 1) {
                    $scope.srAU = ($scope.currentAUPage - 1) * parseInt(perPage) + 1;
                }
                else{
                    $scope.srAU = 1;
                }
                $scope.auLogsDetail.data.forEach(function(list){
                   list.srNo = $scope.srAU;
                   $scope.srAU += 1;
                })
                $scope.total_showingAU = $scope.auLogsDetail.data.length;
                $scope.auPaginationItems = [];
                var totalPages = $scope.auLogsDetail.total_page;
                for(i=1; i<=totalPages; i++){
                    $scope.auPaginationItems.push({'pageno':i})
                }

            }
        });
    }

    //filter company logs
    $scope.filterAULog = function(perPage){
        $scope.filterAUBtnActive = true;
        $scope.allAULogs($scope.currentAUPage, perPage, $scope.auBusiness, $scope.aufilter.start, $scope.aufilter.end)
    }
    // change per page enteries
    $scope.updateAUPerPage = function(perPage){
        $scope.allAULogs($scope.currentAUPage, perPage, $scope.auBusiness, $scope.aufilter.start, $scope.aufilter.end)
    }

    /*//next page
    $scope.nextAUPage = function(perPage){
        if ($scope.auLogsDetail.total_page != $scope.currentAUPage) {
            $scope.currentAUPage = $scope.currentAUPage+1;
            $scope.allAULogs($scope.currentAUPage, perPage, $scope.auBusiness, $scope.aufilter.start, $scope.aufilter.end)
        }
    }
    //previous page
    $scope.preAUPage = function(perPage){
        if ($scope.currentAUPage != 1) {
            $scope.currentAUPage = $scope.currentAUPage-1;
            $scope.allAULogs($scope.currentAUPage, perPage, $scope.auBusiness, $scope.aufilter.start, $scope.aufilter.end)
        }
    }*/
    //change page
    $scope.updateAUPage = function(no, perPage){
        $scope.currentAUPage = parseInt(no);
        $scope.allAULogs($scope.currentAUPage, perPage, $scope.auBusiness, $scope.aufilter.start, $scope.aufilter.end)
    }

    $scope.openAUView = function(data){
        $scope.modalInstance = $uibModal.open({
            templateUrl: 'auLog.html',
            controller: 'auLogCtrl',
            size: 'md',
            resolve: {
              data: function () {
                return data;
              }
            }
        });
    }

    /*-------------------authorized logs Ends----------------------*/
    
    /*-------------------admin logs Start----------------------*/

    $scope.adfilter = {};
    $scope.startDateAD = {'opened' : false};
    $scope.endDateAD = {'opened' : false};
    $scope.openADStart = function(){
        $scope.startDateAD.opened = true;    
    }
    $scope.openADEnd = function(){
        $scope.endDateAD.opened = true;    
    }
    $scope.adfilter.start = new Date();

    $scope.currentADPage = 1;
    $scope.adHearders = ['Sr. No', 'Error Class Name', 'Error Message', 'Error Trace', 'Params', 'Target URL', 'Time Stamp']
    $scope.adNoOfPage = '10';
    $scope.filterADBtnActive = false;

    $scope.allADLogs = function(pageno, perPage, start, end){
        $scope.loading = true;
        var data = {'start_date' : start, 'end_date' : end, 'page_no' : pageno, 'per_page' : perPage}
        data.start_date = start.getFullYear() +'-'+ addZero(start.getMonth()+1) +'-'+ start.getDate(); 
        if (data.end_date) {
            data.end_date = end.getFullYear() +'-'+ addZero(end.getMonth()+1) +'-'+ end.getDate(); 
        }
        if ($scope.filterADBtnActive) {
            data.isFilter = true;
            $scope.filterADBtnActive = false;
        }
        
        $http.post('/admin/opustime/admin_logs', data).success(function(result){
            $scope.loading = false;
            if (result.flag) {
                $scope.adLogsDetail = result;
                if ($scope.currentADPage > 1) {
                    $scope.srAD = ($scope.currentADPage - 1) * parseInt(perPage) + 1;
                }
                else{
                    $scope.srAD = 1;
                }
                $scope.adLogsDetail.data.forEach(function(list){
                   list.srNo = $scope.srAD;
                   $scope.srAD += 1;
                })
                $scope.total_showingAD = $scope.adLogsDetail.data.length;
                $scope.adPaginationItems = [];
                var totalPages = $scope.adLogsDetail.total_page;
                for(i=1; i<=totalPages; i++){
                    $scope.adPaginationItems.push({'pageno':i})
                }

            }
        });
    }

    //filter company logs
    $scope.filterADLog = function(perPage){
        $scope.filterADBtnActive = true;
        $scope.allADLogs($scope.currentADPage, perPage, $scope.adfilter.start, $scope.adfilter.end)
    }
    // change per page enteries
    $scope.updateADPerPage = function(perPage){
        $scope.allADLogs($scope.currentADPage, perPage, $scope.adfilter.start, $scope.adfilter.end)
    }

    /*//next page
    $scope.nextADPage = function(perPage){
        if ($scope.adLogsDetail.total_page != $scope.currentADPage) {
            $scope.currentADPage = $scope.currentADPage+1;
            $scope.allADLogs($scope.currentADPage, perPage, $scope.adfilter.start, $scope.adfilter.end)
        }
    }
    //previous page
    $scope.preADPage = function(perPage){
        if ($scope.currentADPage != 1) {
            $scope.currentADPage = $scope.currentADPage-1;
            $scope.allADLogs($scope.currentADPage, perPage, $scope.adfilter.start, $scope.adfilter.end)
        }
    }*/
    //change page
    $scope.updateADPage = function(no, perPage){
        $scope.currentADPage = parseInt(no);
        $scope.allADLogs($scope.currentADPage, perPage, $scope.adfilter.start, $scope.adfilter.end)
    }

    $scope.openADView = function(data){
        $scope.modalInstance = $uibModal.open({
            templateUrl: 'adLog.html',
            controller: 'adLogCtrl',
            size: 'lg',
            resolve: {
              data: function () {
                return data;
              }
            }
        });
    }

    /*-------------------admin logs Ends----------------------*/
    function addZero(data){
        if(data < 10){
            return '0' + data;
        }
        else{
            return data;
        }
    }

}])

adminApp.controller('appLogCtrl',['$scope', 'data', '$modalInstance', function($scope, data, $modalInstance){
    $scope.logData = data;
    $scope.close = function(){
        $modalInstance.dismiss('cancel');
    }
}]);
adminApp.controller('qbLogCtrl',['$scope', 'data', '$modalInstance', function($scope, data, $modalInstance){
    $scope.qbLogData = data;
    $scope.close = function(){
        $modalInstance.dismiss('cancel');
    }
}]);
adminApp.controller('auLogCtrl',['$scope', 'data', '$modalInstance', function($scope, data, $modalInstance){
    $scope.auLogData = data;
    $scope.close = function(){
        $modalInstance.dismiss('cancel');
    }
}]);
adminApp.controller('adLogCtrl',['$scope', 'data', '$modalInstance', function($scope, data, $modalInstance){
    $scope.adLogData = data;
    $scope.close = function(){
        $modalInstance.dismiss('cancel');
    }
}]);