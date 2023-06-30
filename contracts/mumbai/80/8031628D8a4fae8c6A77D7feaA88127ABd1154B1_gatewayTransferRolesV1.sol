// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract gatewayTransferRolesV1 {
    address public admin;
    mapping(address => bool) public users;
    uint public number;
    event TransferData(bytes data);

     modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    modifier onlyAdminOrUser() {
        require(msg.sender == admin || users[msg.sender], "Only admin or users can call this function");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function assignUserRole(address user) public {
        require(msg.sender == admin, "Only admin can assign user roles");
        users[user] = true;
    }

    function removeUserRole(address user) public {
        require(msg.sender == admin, "Only admin can remove user roles");
        users[user] = false;
    }

    function transfer(bytes32 gatewayId, address newOwner) external onlyAdmin {
    address gatewayContract = 0xf8444576A32C0b3cc78c7A0B8BA703cA74E68AFb;
    uint gasCost = 21000 * tx.gasprice; // Estimate the gas cost based on current gas price

    // Check if the admin has provided enough allowance to cover the gas cost
    require(address(this).balance >= gasCost, "Insufficient allowance");

    (bool success, bytes memory data) = gatewayContract.call(abi.encodeWithSignature("transfer(bytes32,address)", gatewayId, newOwner));
    require(success, "Gateway transfer failed");

    // Log the return data for debugging or informational purposes
    emit TransferData(data);

    // Refund excess allowance to the admin
    if (address(this).balance > gasCost) {
        payable(admin).transfer(address(this).balance - gasCost);
    }
}

}