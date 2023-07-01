// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract gatewayTransferV1 {
    address public admin;
    mapping(address => bool) public users;
    event TransferData(bytes data);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    modifier onlyAdminOrUser() {
        require(
            msg.sender == admin || users[msg.sender],
            "Only admin or users can call this function"
        );
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

    function transferGateway(
        bytes32 gatewayId,
        address newOwner
    ) external onlyAdmin payable {
        uint gasCost = 21000 * tx.gasprice; // Estimate the gas cost based on current gas price

        // Check if the admin has provided enough MATIC balance to cover the gas cost
        require(msg.value >= gasCost, "Insufficient MATIC balance");

        address gatewayTransferrer = 0xf8444576A32C0b3cc78c7A0B8BA703cA74E68AFb;

        (bool success, bytes memory data) = gatewayTransferrer.call{
            value: gasCost
        }(
            abi.encodeWithSignature(
                "transfer(bytes32,address)",
                gatewayId,
                newOwner
            )
        );
        require(success, "Gateway transfer failed");

        // Log the return data for debugging or informational purposes
        emit TransferData(data);

        // Refund excess MATIC to the admin
        if (msg.value > gasCost) {
            payable(admin).transfer(msg.value - gasCost);
        }
    }

}