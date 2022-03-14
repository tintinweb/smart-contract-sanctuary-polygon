/**
 *Submitted for verification at polygonscan.com on 2022-03-13
*/

// File: SwixMocks/mocks/MockEcosystem.sol


// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;
contract MockEcosystem {

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);


    function grantRole(
        bytes32 role,
        address account,
        address sender
    )
        external
    {
        emit RoleGranted(role, account, sender);
    }

    function revokeRole(
        bytes32 role,
        address account,
        address sender
    )
        external
    {
        emit RoleRevoked(role, account, sender);
    }
    
}