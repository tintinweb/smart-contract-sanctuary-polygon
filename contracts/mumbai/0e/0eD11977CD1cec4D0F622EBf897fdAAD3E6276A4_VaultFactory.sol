// SPDX-License-Identifier: None
pragma solidity 0.8.19;

import "./Vault.sol";

contract VaultFactory {

    event newVault(address indexed creator, address indexed vault);

    address payable private owner;
    uint private creationFee;
    uint maxVaults;

    mapping(address => address[]) private users;

    constructor() {
        owner = payable(msg.sender);
        creationFee = 0;
        maxVaults = 5;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Denied.");
        _;
    }

    function createVault() external payable {
        require(msg.value == creationFee, "msg.value incorrect");
        require(users[msg.sender].length < maxVaults, "Cannot create more vaults");

        Vault v = new Vault(msg.sender);

        users[msg.sender].push(address(v));

        emit newVault(msg.sender, address(v));
    }

    function getVaults(address _user) external view returns (address[] memory) {
        return users[_user];
    }

    function changeOwner(address _newOwner) onlyOwner external {
        owner = payable(_newOwner);
    }

    function changeMaxVaults(uint _newMax) onlyOwner external {
        maxVaults = _newMax;
    }
}