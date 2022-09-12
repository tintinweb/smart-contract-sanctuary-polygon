// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./interfaces/IFactory.sol";

/**
    @title Management contract
    @dev This contract is being used as a management contract of Nudge's Collections
       + Register/Unregister Owner/Owners of each collections
*/
contract Management {

    address private _factory;
    uint256 private _numOfAdmins;
    //  A list of Nudge's Admins
    mapping(address => bool) private _admins;

    //  A list of Owner/Owners of each collections
    //  collection -> Owner -> true/false
    mapping(address => mapping(address => bool)) private _owners;
    bool private _halted;

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only Admin");
        _;
    }

    modifier zeroAddr(address _account) {
        require(_account != address(0), "Set zero address");
        _;
    }

    event AdminUpdated(address indexed operator, address indexed account, bool isGranted);
    event OwnerUpdated(
        address indexed operator,
        address indexed collection,
        address indexed account,
        bool isGranted
    );

    constructor(address _admin) {
        require(_admin != address(0), "Set zero address");
        
        _setAdmin(_admin);
        emit AdminUpdated(address(0), _admin, true);
    }

    function grantAdmin(address _account) external onlyAdmin zeroAddr(_account) {
        _setAdmin(_account);

        emit AdminUpdated(msg.sender, _account, true);
    }

    function revokeAdmin(address _account) external onlyAdmin {
        address _operator = msg.sender;
        require(_account != _operator, "Unable to revoke self");
        require(isAdmin(_account), "Account not granted Admin role yet");

        delete _admins[_account];
        _numOfAdmins--;

        emit AdminUpdated(_operator, _account, false);
    }

    function grantOwner(address _collection, address _account) external onlyAdmin zeroAddr(_account) {
        require(
            IFactory(factory()).isExisted(_collection), "Collection not found"
        );

        _owners[_collection][_account] = true;

        emit OwnerUpdated(msg.sender, _collection, _account, true);
    }

    function revokeOwner(address _collection, address _account) external onlyAdmin {
        require(
            _owners[_collection][_account], "Collection or Owner yet not set"
        );

        delete _owners[_collection][_account];

        emit OwnerUpdated(msg.sender, _collection, _account, false);
    }

    function setFactory(address factory_) external onlyAdmin zeroAddr(factory_) {
        _factory = factory_;
    }

    function isAdmin(address _account) public view returns (bool) {
        return _admins[_account];
    }

    function isOwner(address _collection, address _account) external view returns (bool) {
        return _owners[_collection][_account];
    }

    function factory() public view returns (address) {
        return _factory;
    }

    function halted() external view returns (bool) {
        return _halted;
    }

    function _setAdmin(address _admin) private {
        _admins[_admin] = true;
        _numOfAdmins++;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IFactory {

    function isExisted(address _collection) external view returns (bool);
}