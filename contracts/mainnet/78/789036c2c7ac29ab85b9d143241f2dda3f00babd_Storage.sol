/**
 *Submitted for verification at polygonscan.com on 2023-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    bytes32 merkleRoot;
    string set1;
    address add;

   
    /**
     * @dev Constructor function that sets the initial values for the contract's variables.
     * @param _merkleRoot The root of the Merkle tree.
     * @param uri The metadata URI prefix.
     */
    constructor(
        bytes32 _merkleRoot,
        string  memory uri,
        address _payerAccount
    ) {
        merkleRoot = _merkleRoot;
        set1 = uri;
        add = _payerAccount;
    }

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}