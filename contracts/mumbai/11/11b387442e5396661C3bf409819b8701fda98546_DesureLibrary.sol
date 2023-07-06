// SPDX-License-Identifier: Unlicensed
// Copyright © 2022 DeSure Inc

pragma solidity ^0.8.13;

library DesureLibrary {
    bytes32 public constant DESURE_BANK_CONTROLLER_ROLE = keccak256("DESURE_BANK_CONTROLLER_ROLE");
    bytes32 public constant DESURE_POOLS_CONTROLLER_ROLE = keccak256("DESURE_POOLS_CONTROLLER_ROLE");
    bytes32 public constant DESURE_RISK_FACTORS_CONTROLLER_ROLE = keccak256("DESURE_RISK_FACTORS_CONTROLLER_ROLE");
    bytes32 public constant DESURE_CLAIMS_CONTROLLER_ROLE = keccak256("DESURE_CLAIMS_CONTROLLER_ROLE");
    bytes32 public constant DESURE_MEMBERSHIP_CONTROLLER_ROLE = keccak256("DESURE_MEMBERSHIP_CONTROLLER_ROLE");
    bytes32 public constant DESURE_COURT_CONTROLLER_ROLE = keccak256("DESURE_COURT_CONTROLLER_ROLE");
    bytes32 public constant DESURE_ADDITIONAL_ROLE_1 = keccak256("DESURE_ADDITIONAL_ROLE_1");
    bytes32 public constant DESURE_ADDITIONAL_ROLE_2 = keccak256("DESURE_ADDITIONAL_ROLE_2");
    bytes32 public constant DESURE_ADDITIONAL_ROLE_3 = keccak256("DESURE_ADDITIONAL_ROLE_3");
    bytes32 public constant DESURE_ADDITIONAL_ROLE_4 = keccak256("DESURE_ADDITIONAL_ROLE_4");
    bytes32 public constant DESURE_ADDITIONAL_ROLE_5 = keccak256("DESURE_ADDITIONAL_ROLE_5");

    address public constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    uint16 public constant FULL_PERCENTAGE = 10000;
    uint8 public constant NUMBER_OF_MONTHS_TO_JOIN = 12;
    uint8 public constant MAX_MONTHS_BEFORE_DEATH_TILL_CLAIM  = 12;
}