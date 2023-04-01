// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./AdamoBasicDocument.sol";
import "./AdamoSignatureRecorder.sol";

contract AdamoBasicDocumentFactory {
    address[] private adminUsers;
    address[] public documentsAddresses;
    uint64 private s_currentDocumentId;
    address public currentSignatureRecorder;
    uint16 private constant MAX_ADMINS = 10;
    mapping(address => bool) public isAdminUser;
    mapping(address => bool) public isValidDocument;

    error TooManyAdminUsers();
    error OwnerCantBeRemoved();
    error AdminUsersCantBeEmpty();
    error AdminUserAlreadyAdded();
    error UserToRemoveIsNotAdmin();

    event AdminUserAdded(address indexed adminUserAddress);
    event AdminUserRemoved(address indexed adminUserAddress);
    event DocumentCreated(
        address indexed documentContract,
        bytes32 indexed documentSalt,
        uint currentDocumentsLength
    );

    modifier onlyIfSignatureRecorderOwner() {
        require(
            msg.sender ==
                AdamoSignatureRecorder(currentSignatureRecorder)
                    .signatureRecorderOwner(),
            "You are not authorized"
        );
        _;
    }

    modifier onlyIfAdminUser() {
        require(isAdminUser[msg.sender] == true, "You are not authorized");
        _;
    }

    constructor(address _currentSignatureRecorder) {
        currentSignatureRecorder = _currentSignatureRecorder;
        addAdminUser(
            AdamoSignatureRecorder(currentSignatureRecorder)
                .signatureRecorderOwner()
        );
    }

    function getCurrentAdminUsers()
        external
        view
        onlyIfAdminUser
        returns (address[] memory _currentAdminUsers)
    {
        return adminUsers;
    }

    function getIfUserIsAdmin(
        address userToCheck
    ) external view returns (bool _userIsAdmin) {
        return isAdminUser[userToCheck];
    }

    function getCurrentDocumentId() external view returns (uint64) {
        return s_currentDocumentId;
    }

    function getIfIsValidDocument(
        address _documentToCheck
    ) external view returns (bool _isValidDocument) {
        return isValidDocument[_documentToCheck];
    }

    function addAdminUser(
        address _adminUserToAdd
    ) public onlyIfSignatureRecorderOwner returns (bool _success) {
        // Already maxed, cannot add any more admin users.
        if (adminUsers.length == MAX_ADMINS) revert TooManyAdminUsers();
        if (isAdminUser[_adminUserToAdd] == true)
            revert AdminUserAlreadyAdded();

        adminUsers.push(_adminUserToAdd);
        isAdminUser[_adminUserToAdd] = true;

        emit AdminUserAdded(_adminUserToAdd);
        return true;
    }

    function removeAdminUser(
        address _adminUserToRemove
    ) external onlyIfAdminUser returns (bool _success) {
        if (adminUsers.length == 1) revert AdminUsersCantBeEmpty();
        if (!isAdminUser[_adminUserToRemove]) revert UserToRemoveIsNotAdmin();
        if (
            _adminUserToRemove ==
            AdamoSignatureRecorder(currentSignatureRecorder)
                .signatureRecorderOwner()
        ) revert OwnerCantBeRemoved();

        uint256 lastAdminUserIndex = adminUsers.length - 1;
        for (uint256 i = 0; i < adminUsers.length; i++) {
            if (adminUsers[i] == _adminUserToRemove) {
                address last = adminUsers[lastAdminUserIndex];
                adminUsers[i] = last;
                adminUsers.pop();
                break;
            }
        }

        isAdminUser[_adminUserToRemove] = false;
        emit AdminUserRemoved(_adminUserToRemove);
        return true;
    }

    function changeSignatureRecorder(
        address _newSignatureRecorder
    ) public onlyIfSignatureRecorderOwner returns (bool success) {
        require(_newSignatureRecorder != address(0x0));
        require(_newSignatureRecorder != currentSignatureRecorder);

        currentSignatureRecorder = _newSignatureRecorder;
        return true;
    }

    function createDocument(
        string memory _documentFirstVersionHash,
        string[] memory _documentRequiredSignatures
    ) external onlyIfSignatureRecorderOwner returns (address _documentAddress) {
        bytes memory tempEmptyStringTest = bytes(_documentFirstVersionHash);
        require(tempEmptyStringTest.length != 0, "Send a valid document hash");
        require(
            _documentRequiredSignatures.length != 0,
            "There has to be at least one signer"
        );

        bytes32 salt = keccak256(abi.encodePacked(_documentFirstVersionHash));

        AdamoBasicDocument _basicDocumentContract = new AdamoBasicDocument{
            salt: salt
        }(_documentFirstVersionHash, _documentRequiredSignatures);

        documentsAddresses.push(address(_basicDocumentContract));
        isValidDocument[address(_basicDocumentContract)] = true;
        s_currentDocumentId++;

        emit DocumentCreated(
            address(_basicDocumentContract),
            salt,
            s_currentDocumentId
        );
        return address(_basicDocumentContract);
    }
}