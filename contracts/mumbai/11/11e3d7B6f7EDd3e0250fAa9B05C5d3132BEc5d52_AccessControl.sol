/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// File: security/AccessControl.sol

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable public superAdmin;

    /// @dev Administrator of this contract.
    address payable public admin;

    /// @dev This event is fired after modifying superAdmin.
    event superAdminChanged(address indexed _from,address indexed _to,uint256 _time);

    /// @dev This event is fired after modifying admin.
    event adminChanged(address indexed _from,address indexed _to,uint256 _time);

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        emit superAdminChanged(superAdmin,addr,block.timestamp);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        emit adminChanged(admin,addr,block.timestamp);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}