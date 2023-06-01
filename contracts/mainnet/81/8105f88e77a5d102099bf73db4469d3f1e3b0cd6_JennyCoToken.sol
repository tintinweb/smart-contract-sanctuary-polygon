// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./AERC20.sol";
import "./Ownable.sol";

contract JennyCoToken is AERC20, Ownable {
    constructor(address jennyCoTeam) AERC20("JennyCoToken", "JCO") {
        transferOwnership(jennyCoTeam);
        _mint(jennyCoTeam, 250E24);
    }
}