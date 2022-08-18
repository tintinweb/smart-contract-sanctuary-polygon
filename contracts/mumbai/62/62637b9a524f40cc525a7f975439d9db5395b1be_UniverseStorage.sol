// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Context.sol";

/**
 * Universe Storage Contract for User
 */
contract UniverseStorage is Context {
    mapping(address => bool) private accessAllowed;

    address public userAddress;
    address public immutable universeFactory;

    bytes[] private userEncryptedPersonalInfo;

    event SetUserData(uint setTime);

    constructor() {
        universeFactory = _msgSender();
    }

    /**
     * @dev Initialize Contract
     */
    function initialize(address _userAddress) external {
        require(_msgSender() == universeFactory, "Universe: FORBIDDEN");
        userAddress = _userAddress;
        accessAllowed[_userAddress] = true;
    }

    /**
     * @dev Write User's Encryped Data on contract, only User call it
     */
    function writeUserData(bytes[] memory _inputData) external {
        require(msg.sender == userAddress, "Universe: Only Owner could write data");

        userEncryptedPersonalInfo = _inputData;

        emit SetUserData(block.timestamp);
    }

    /**
     * @dev Get User's Encryped Data on contract
     */
    function getUserData() external view returns (bytes[] memory info) {
        if(accessAllowed[msg.sender]) info = userEncryptedPersonalInfo;
    }

    /**
     * @dev Check User's Access Permission
     */
    function checkAllowance(address user) external view returns(bool allowed) {
        allowed = allowed ? accessAllowed[user] : false;
    }

    /**
     * @dev Set Permission to User
     */
    function setAllowance(address user, bool flag) external {
        require(msg.sender == userAddress, "Not user");
        
        accessAllowed[user] = flag;
    }
}