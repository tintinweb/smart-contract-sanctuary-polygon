// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "./imageReport.sol";
import "./DoctorOp.sol";

contract Master {
    
    mapping(address => address[]) public userReports;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function createImageReport(address _user, address _doctor, string memory _reportType, string memory _originalImage, string memory _maskedImage) public onlyOwner returns (address) {
        userReports[_user].push(address(new ImageReport(_user, _doctor, _reportType, _originalImage, _maskedImage)));
        return (userReports[_user][userReports[_user].length - 1]);
    }

    function addReportofNewDoctor(address _user,address _doctor,string memory newAnalysis,string memory newDiagnosis,string memory signature)public onlyOwner returns (address){
        address temp =  address(new DoctorOpinoin(_user,_doctor,newDiagnosis,newAnalysis,signature));
        ImageReport((userReports[_user][userReports[_user].length - 1])).linkToNextReport(temp);
        return temp;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract ImageReport {
    
    mapping(address => bool) public isOwner;
    mapping(address => bool) public isDoctor;
    address nextReport;
    bool isEditable = true;
    string originalImage;
    string maskedImage;
    string analysis;
    string diagnosis;
    string reportType;
	string signature;

    constructor(address _user, address _doctor, string memory _reportType, string memory _originalImage, string memory _maskedImage) {
        isOwner[_user] = true;
        isOwner[_doctor] = true;
        isDoctor[_doctor] = true;
        originalImage = _originalImage;
        maskedImage = _maskedImage;
        reportType = _reportType;
    }

    modifier onlyOwner {
        require(isOwner[msg.sender], "Only the owner can perform this action");
        _;
    }

    modifier onlyDoctor {
        require(isDoctor[msg.sender], "Only the doctor can perform this action");
        _;
    }

    function addOwner(address _owner) public onlyOwner {
        isOwner[_owner] = true;
    }

    function addDoctor(address _doctor) public onlyOwner {
        isOwner[_doctor] = true;
        isDoctor[_doctor] = true;
    }

    function setData(string memory _analysis, string memory _diagnosis, string memory _signature) public onlyOwner onlyDoctor {
        require(isEditable, "The report is no longer editable");
        analysis = _analysis;
        diagnosis = _diagnosis;
		signature = _signature;
        isEditable = false;
    }

    function getAnalysis() public view onlyOwner returns (string memory) {
        return analysis;
    }

    function getDiagnosis() public view onlyOwner returns (string memory) {
        return diagnosis;
    }

    function getOriginalImage() public view onlyOwner returns (string memory) {
        return originalImage;
    }

    function getMaskedImage() public view onlyOwner returns (string memory) {
        return maskedImage;
    }

	function getReportType() public view onlyOwner returns (string memory) {
		return reportType;
	}

	function getSignature() public view onlyOwner returns (string memory) {
		return signature;
	}

    function linkToNextReport(address newReport) public onlyOwner returns (bool){
        nextReport = newReport;
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract DoctorOpinoin{ 
    mapping (address=>bool) public isDoctor;
    mapping (address => bool ) public isOwner;
    string diagnosis;
    string analysis;
	string signature;
    bool lock;
    address nextReprt;


    constructor(address owner,address _doctor,string  memory _diagnosis,string memory  _analysis,string  memory _signature ){
        isOwner[owner] = true;
        isDoctor[_doctor] = true;
        diagnosis = _diagnosis;
        analysis = _analysis;
        signature = _signature;
        lock = false;
    }

    modifier onlyDoctor{
        require(isDoctor[msg.sender],"Only Consult Doctor can view the report" );
        _;
    }

   

    function addDoctor(address _doc) public {
        isDoctor[_doc] = true;
    }


    function addDiagnosis(string  memory _diagnosis,string memory  _analysis,string  memory _signature) public onlyDoctor{
        require(lock,"Report is Locked By Doctor and you can't edit");
        diagnosis = _diagnosis;
        analysis = _analysis;
        signature = _signature;
    }

    function getDiagnosis() public view returns(string memory) {
        return diagnosis;
    }
    function getAnalysis() public view returns(string memory) {
        return analysis;
    }

    function linkToNext(address contractAddress) public  returns(address) {
        nextReprt = contractAddress;
        return contractAddress;
    }

   


}