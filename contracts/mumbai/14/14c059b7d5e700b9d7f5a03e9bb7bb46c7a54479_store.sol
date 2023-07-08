/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract store{
string public storage_;

    function store_mudila(string memory  s) public{

    storage_=s;
    }

}