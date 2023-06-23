// SPDX-License-Identifier: None
pragma solidity 0.8.19;

import "./TimelockVault.sol";
import "./ITimelockVault.sol";

/**
* @title Ardoda Timelock Vault Factory.
* @author Etienne Cellier-Clarke
* @notice This is a factory used to deploy new Timelock Vault contracts onto the blockchain.
* @dev All function calls are currently implemented without side effects.
* @custom:propertyof DreamKollab Ltd.
*/
contract TimelockVaultFactory {

    event newVault(address indexed creator, address indexed vault);
    event transferredVaultOwnership(address indexed from, address indexed to);

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
        require(msg.sender == owner, "Error: Denied.");
        _;
    }

    /**
    * @notice A new vault is created for the transaction sender.
    * @param _timestamp Unix timestamp defining when the contents of the vault can be accessed.
    */
    function createVault(uint _timestamp) external payable {
        require(msg.value == creationFee, "Error: msg.value Incorrect.");
        require(users[msg.sender].length < maxVaults, "Error: Cannot create more Timelock Vaults.");
        require(block.timestamp <= _timestamp, "Error: Unlock date cannot be in the past.");

        TimelockVault v = new TimelockVault(msg.sender, _timestamp);

        users[msg.sender].push(address(v));

        emit newVault(msg.sender, address(v));
    }

    /**
    * @notice Fetch list of vaults owned by an address.
    * @param _user Target address.
    * @return array List of Vault addresses.
    */
    function getVaults(address _user) external view returns (address[] memory) {
        return users[_user];
    }

    /**
    * @notice Change owner of this factory contract.
    * @param _newOwner Address to be assigned as owner.
    */
    function changeOwner(address _newOwner) onlyOwner external {
        owner = payable(_newOwner);
    }

    /**
    * @notice Change the max number of vaults an address can own.
    * @param _newMax New number of vaults an address can own.
    */
    function changeMaxVaults(uint _newMax) onlyOwner external {
        maxVaults = _newMax;
    }

    /**
    * @notice Transfers ownership of vault;
    * @param _vault Address of vault to be transferred.
    * @param _target Target address that will become the new owner.
    */
    function transferVault(address _vault, address _target) external {
        
        require(users[_target].length < maxVaults, "Error: Transfer failed, target address has reach max vaults.");
        require(ITimelockVault(_vault).isOwner(msg.sender), "Error: Access denied.");
        
        // remove vault from user
        address[] memory arr = new address[](users[msg.sender].length - 1);
        uint index = 0;
        for(uint i = 0; i < users[msg.sender].length; i++) {
            if(users[msg.sender][i] != _vault) {
                arr[index] = users[msg.sender][i];
                index++;
            }
        }
        users[msg.sender] = arr;

        // add vault to user
        users[_target].push(_vault);

        // change owner
        ITimelockVault(_vault).changeOwner(_target);

        emit transferredVaultOwnership(msg.sender, _target);
    }
}