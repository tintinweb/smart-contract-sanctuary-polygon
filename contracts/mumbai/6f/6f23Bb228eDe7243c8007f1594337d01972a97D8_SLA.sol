/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SLA {
    constructor(){
        provider_head_division = msg.sender;
    }

    modifier onlyProvider(){
        require(msg.sender == provider_head_division || msg.sender == provider_director, "Only provider can access this");
        _;
    }

    mapping(address => User) userDetail;
    mapping(uint256 => Application) public applicationDetail;
    mapping(uint256 => string) public notApprovedReason;

    address public provider_head_division;
    address public provider_director;
    uint256 public app_id = 0;

    uint256[] headApplicationList;
    uint256[] directorApplicationList;
    uint256[] headNegotiationList;
    uint256[] directorNegotiationList;

    enum DevelopmentType{PENGEMBANGAN, PERUBAHAN, PENGHAPUSAN}
    enum Type{NORMAL, RUTIN, DARURAT}
    enum Status{REQUEST, APPROVED1, APPROVED2, REJECTED, DONE}

    struct User {
        // address userId;
        uint256[] userApplicationList;
    }

    struct DevelopmentDetail {
        string currentCondition;
        string developmentProposal;
        string riskImpact;
    }

    struct SupportingDocument {
        bool businessProcess;
        bool procedure;
        bool relatedDocument;
    }

    struct OtherDetailApp {
        Type typeApp;
        uint256 dateUsed;
        string PICName;
        SupportingDocument supportingDocument;
        DevelopmentDetail developmentDetail;
    }

    struct Application {
        uint256 applicationID;
        DevelopmentType developmentType;
        string applicantName;
        string position;
        string division;
        string appName;
        OtherDetailApp otherDetailApp;
        // Type typeApp;
        // uint256 dateUsed;
        // string PICName;
        // SupportingDocument supportingDocument;
        // DevelopmentDetail developmentDetail;
        Status status;
    }

    function addApplication(
        DevelopmentType _developmentType,
        string memory _applicantName,
        string memory _position,
        string memory _division,
        string memory _appName,
        Type _typeApp,
        uint256 _dateUsed,
        string memory _PICName,
        SupportingDocument memory _supportingDocument,
        DevelopmentDetail memory _developmentDetail
    ) public {
        app_id++;

        User storage user = userDetail[msg.sender];
        user.userApplicationList.push(app_id);
        headApplicationList.push(app_id);

        Application storage application = applicationDetail[app_id];
        application.applicationID = app_id;
        application.developmentType = _developmentType;
        application.applicantName = _applicantName;
        application.position = _position;
        application.division = _division;
        application.appName = _appName;
        application.otherDetailApp.typeApp = _typeApp;
        application.otherDetailApp.dateUsed = _dateUsed;
        application.otherDetailApp.PICName = _PICName;
        application.otherDetailApp.supportingDocument = _supportingDocument;
        application.otherDetailApp.developmentDetail = _developmentDetail;
        application.status = Status.REQUEST;
    }

    function setProviderHead(address providerHead) public onlyProvider {
        provider_head_division = providerHead;
    }

    function setProviderDirector(address providerDirector) public onlyProvider {
        provider_director = providerDirector;
    }

    function removeAppId(uint256[] memory array, uint256 value) public {
        uint i = 0;
        while (array[i] != value && i<array.length){
            i++;
        }
        if (array[i] == value){
            array[i] == 0;
        }
    }

    function getUserDetail(address _userId) public view returns (uint256[] memory){
        return (userDetail[_userId].userApplicationList);
    }

    function getHeadApplicationList() public view returns (uint256[] memory){
        return headApplicationList;
    }

    function getDirectorApplicationList() public view returns (uint256[] memory){
        return directorApplicationList;
    }

    function getHeadNegotiationList() public view returns (uint256[] memory){
        return headNegotiationList;
    }

    function getDirectorNegotiationList() public view returns (uint256[] memory){
        return directorNegotiationList;
    }

    function headApproveApplication(uint256 _app_id) public onlyProvider {
        Application storage application = applicationDetail[_app_id];
        require(application.status == Status.REQUEST, "Application status must be request");
        application.status = Status.APPROVED1;
        directorApplicationList.push(_app_id);
    }

    function directorApproveApplication(uint256 _app_id) public onlyProvider {
        Application storage application = applicationDetail[_app_id];
        require(application.status == Status.APPROVED1, "Application status must be approved1");
        application.status = Status.APPROVED2;
    }

    function setNotApprovedReason(uint256 _app_id, string memory text) public onlyProvider {
        notApprovedReason[_app_id] = text;
    }

    function headEndApplication(uint256 _app_id) public onlyProvider {
        Application storage application = applicationDetail[_app_id];
        require(application.status == Status.APPROVED2, "Application status must be approved2");
        application.status = Status.DONE;
        headNegotiationList.push(_app_id);
    }

    function writeFormSLA(uint256 _app_id) public onlyProvider {

    }

    function checkUserRole(address _addr) public view returns(uint256){
        if (_addr == provider_head_division){
            return 0;
        }
        else if (_addr == provider_director){
            return 1;
        }
        else {
            return 2;
        }
    }
}