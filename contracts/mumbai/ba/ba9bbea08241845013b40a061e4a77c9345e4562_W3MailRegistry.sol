/**
 *Submitted for verification at polygonscan.com on 2022-08-08
*/

pragma solidity 0.8.7;

interface WnsRegistryInterface {
    function owner() external view returns (address);
    function getWnsAddress(string memory _label) external view returns (address);
}

pragma solidity 0.8.7;

interface W3MailRegistrarInterface {
    function recoverSigner(bytes32 message, bytes memory sig) external pure returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract W3MailRegistry {

    address private WnsRegistry;
    WnsRegistryInterface wnsRegistry;

    constructor(address registry_) {
        WnsRegistry = registry_;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    function setRegistry(address _registry) public {
        require(msg.sender == wnsRegistry.owner(), "Not authorized.");
        WnsRegistry = _registry;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    mapping(address => mapping(uint256 => string)) private emailRegistry;
    mapping(address => uint256) private userIndex;

    function setEmail(string memory _email, address to) public {
     //   require(msg.sender == wnsRegistry.getWnsAddress("_w3mailRegistrar"));
        uint256 _userIndex = userIndex[to];
        emailRegistry[to][_userIndex] = _email;
        userIndex[to] = _userIndex + 1;
    }

    function getEmail(address user, uint256 index) public view returns (string memory) {
        require(msg.sender == wnsRegistry.getWnsAddress("_w3mailRegistrar"));
        return emailRegistry[user][index];
    }

    function getUserIndex(address user) public view returns (uint256) {
        return userIndex[user];
    }


}