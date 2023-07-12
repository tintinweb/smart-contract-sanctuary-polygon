/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserManagement {
    struct User {
        address userAddress;
        string role;
        string publicKey;
    }

    mapping(address => User) private users;
    mapping(address => bool) private loggedInUsers;

    event UserRegistered(address indexed userAddress, string role, string publicKey);

    function registerUser(string memory _role, string memory _publicKey) public {
        require(users[msg.sender].userAddress == address(0), "User already registered");
        
        users[msg.sender] = User(msg.sender, _role, _publicKey);
        emit UserRegistered(msg.sender, _role, _publicKey);
    }

    function login() public {
        require(users[msg.sender].userAddress != address(0), "User not registered");
        
        loggedInUsers[msg.sender] = true;
    }

    function logout() public {
        loggedInUsers[msg.sender] = false;
    }

    function getUserRole(address _userAddress) public view returns (string memory) {
        return users[_userAddress].role;
    }

    function getUserPublicKey(address _userAddress) public view returns (string memory) {
        return users[_userAddress].publicKey;
    }

    function isUserLoggedIn(address _userAddress) public view returns (bool) {
        return loggedInUsers[_userAddress];
    }
}
contract ImageUpload {
    struct Image {
        bytes32 hash;
        uint256 timestamp;
        address uploader;
    }

    mapping(bytes32 => Image) private images;

    event ImageUploaded(bytes32 indexed imageHash, uint256 timestamp, address indexed uploader);

    function uploadImage(bytes32 _imageHash) public {
        require(images[_imageHash].hash == bytes32(0), "Image already uploaded");
        
        images[_imageHash] = Image(_imageHash, block.timestamp, msg.sender);
        emit ImageUploaded(_imageHash, block.timestamp, msg.sender);
    }

    function getImageMetadata(bytes32 _imageHash) public view returns (bytes32, uint256, address) {
        Image memory image = images[_imageHash];
        require(image.hash != bytes32(0), "Image not found");
        
        return (image.hash, image.timestamp, image.uploader);
    }
}
contract Reporting {
    struct Report {
        bytes32 imageHash;
        address radiologist;
        string content;
    }

    mapping(bytes32 => Report) private reports;

    event ReportGenerated(bytes32 indexed imageHash, address indexed radiologist, string content);

    function generateReport(bytes32 _imageHash, string memory _content) public {
        require(reports[_imageHash].imageHash == bytes32(0), "Report already generated");
        
        reports[_imageHash] = Report(_imageHash, msg.sender, _content);
        emit ReportGenerated(_imageHash, msg.sender, _content);
    }

    function getReport(bytes32 _imageHash) public view returns (bytes32, address, string memory) {
        Report memory report = reports[_imageHash];
        require(report.imageHash != bytes32(0), "Report not found");
        
        return (report.imageHash, report.radiologist, report.content);
    }
}

contract ReportTemplate {
    struct Template {
        string templateId;
        string content;
    }

    mapping(string => Template) private templates;

    event TemplateAdded(string indexed templateId, string content);

    function addTemplate(string memory _templateId, string memory _content) public {
        require(bytes(_templateId).length > 0, "Template ID cannot be empty");
        require(bytes(_content).length > 0, "Template content cannot be empty");
      //  require(templates[_templateId].templateId == "", "Template with the same ID already exists");

        templates[_templateId] = Template(_templateId, _content);
        emit TemplateAdded(_templateId, _content);
    }

    function getTemplate(string memory _templateId) public view returns (string memory) {
        Template memory template = templates[_templateId];
        require(bytes(template.templateId).length > 0, "Template not found");

        return template.content;
    }
}

contract ReportTemplateUser {
    ReportTemplate private reportTemplateContract;

    constructor(address _reportTemplateContractAddress) {
        reportTemplateContract = ReportTemplate(_reportTemplateContractAddress);
    }

    function addTemplate(string memory _templateId, string memory _content) public {
        reportTemplateContract.addTemplate(_templateId, _content);
    }

    function getTemplate(string memory _templateId) public view returns (string memory) {
        return reportTemplateContract.getTemplate(_templateId);
    }
}