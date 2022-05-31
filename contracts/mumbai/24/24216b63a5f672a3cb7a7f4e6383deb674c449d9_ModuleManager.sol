/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ModuleManager {
    /**
     * @dev 
     */
    mapping (uint8 => address) private moduleManager;

    /**
     * @dev
     */
    enum Modules {
        Roles,      // Contrato de roles
        Categories, // Implementación del ERC1155 (padre)
        Market,     // Compra y venta del market
        Votation    // Contrato de votación
    }

    /**
     * @dev Module changed
     */
    event NewModule(uint8 function_, address newModule_);

    /**
     * @notice This module is 
     */
    constructor (address votation_) {
        moduleManager[uint8(Modules.Votation)] = votation_;
    }

    /**
     * @dev
     */
    modifier onlyVotation {
        if (msg.sender != moduleManager[uint8(Modules.Votation)]) revert('Invalid MSG.SENDER');
        _;
    }    

    /**
     * @notice
     */
    function setModule(uint8 module_, address address_) public onlyVotation {
        moduleManager[module_] = address_;
        emit NewModule(module_, address_);
    }

    /**
     * @notice Get module address
     * @param module_ Function of the module to get
     * @return address of the module
     */
    function getModule(uint8 module_) public view returns (address) {
        return moduleManager[module_];
    }

}