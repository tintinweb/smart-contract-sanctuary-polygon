/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * Module order:
 *  0) Roles
 *  1) Collection
 *  2) Market
 *  3) Votation
 *  4) Market FAN-TOKEN
 */
contract ModuleManager {
    /**
     * @dev 
     */
    mapping (uint => address) private modules;

    /**
     * @dev Module changed
     */
    event NewModule(uint function_, address newModule_);

    /**
     * @notice This module is vital to add the another ones
     */
    constructor (address votation_) {
        modules[3] = votation_;
    }

    /**
     * @dev
     */
    modifier onlyVotation {
        if (msg.sender != modules[3]) revert('Invalid MSG.SENDER');
        _;
    }    

    /**
     * @notice
     */
    function setModule(uint module_, address address_) public onlyVotation {
        modules[module_] = address_;
        emit NewModule(module_, address_);
    }

    /**
     * @notice Get module address
     * @param module_ Function of the module to get
     * @return address of the module
     */
    function getModule(uint module_) public view returns (address) {
        return modules[module_];
    }

}