// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface THIX {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function approveAndCall(address spender, uint256 amount)
        external
        returns (bool);

    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory data
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burnDelegated(address from, uint256 amount) external;

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function payRewards(address to, uint256 amount) external;

    function payRewardsAndCall(address to, uint256 amount) external;

    function payRewardsAndCall(
        address to,
        uint256 amount,
        bytes memory data
    ) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalRewardsPaid(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferAndCall(address to, uint256 amount)
        external
        returns (bool);

    function transferAndCall(
        address to,
        uint256 amount,
        bytes memory data
    ) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferFromAndCall(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) external returns (bool);

    function transferFromAndCall(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "abis/THIX.sol";

contract gatewayOnboardTransferV5 {
    address public admin;
    mapping(address => bool) public users;
    uint public number;
    event TransferData(bytes data);
    THIX tokenContract;
    address public tokenAddress = 0x82766B9447ba0b854103ea8A78163E14772811ad;

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
        tokenContract = THIX(tokenAddress);
    }

    function assignUserRole(address user) public {
        require(msg.sender == admin, "Only admin can assign user roles");
        users[user] = true;
    }

    function removeUserRole(address user) public {
        require(msg.sender == admin, "Only admin can remove user roles");
        users[user] = false;
    }

    function requestTHIXAllowance(uint256 amount) external onlyAdmin {
        // Request admin to approve THIX allowance
        require(
            tokenContract.approve(address(this), amount),
            "Failed to request THIX allowance approval"
        );
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

    function onboardGateway(
        uint8[] calldata versions,
        bytes32[] calldata gatewayIds,
        address[] calldata gateways,
        bytes[] calldata gatewaySignatures
    ) external onlyAdmin payable {
        uint gasCost = 21000 * tx.gasprice; // Estimate the gas cost based on current gas price
        uint thixFee;

        // Check if the admin has provided enough MATIC balance to cover the gas cost
        require(msg.value >= gasCost, "Insufficient MATIC balance");

        // Get the THIX onboarding fee from the GatewayOnboardingPlainBatch contract
        address onboardingContract = 0xe685A0826419Bc982c9278eA7798143Fe7CF9f11;
        (bool success, bytes memory data) = onboardingContract.call(
            abi.encodeWithSignature("onboardFeeInTHIX()")
        );
        require(success, "Failed to get onboarding fee");
        assembly {
            thixFee := mload(add(data, 0x20))
        }

        // Check if the admin has provided enough THIX allowance to cover the fee
        require(
            tokenContract.allowance(admin, address(this)) >= thixFee,
            "Insufficient THIX allowance"
        );
        

        // Execute the onboard function in the GatewayOnboardingPlainBatch contract
        (success, data) = onboardingContract.call(
            abi.encodeWithSignature(
                "onboard(uint8[],bytes32[],address[],bytes[],uint256)",
                versions,
                gatewayIds,
                gateways,
                gatewaySignatures,
                thixFee
            )
        );
        require(success, "Onboarding failed");

        // Log the return data for debugging or informational purposes
        emit TransferData(data);

        // Refund excess MATIC to the admin
        if (msg.value > gasCost) {
            payable(admin).transfer(msg.value - gasCost);
        }
    }
}