// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "./imageReport.sol";

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


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract ImageReport {
    
    mapping(address => bool) public isOwner;
    mapping(address => bool) public isDoctor;
    bool isEditable = true;
    string originalImage;
    string maskedImage;
    string analysis;
    string diagnosis;
    string reportType;

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

    function setData(string memory _analysis, string memory _diagnosis) public onlyOwner onlyDoctor {
        require(isEditable, "The report is no longer editable");
        analysis = _analysis;
        diagnosis = _diagnosis;
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

}