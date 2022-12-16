/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    struct Record {
        uint256 timestamp;
        string data;
    }

    Record public rec;

    function store(Record memory _rec) public {
        rec.timestamp = _rec.timestamp;
        rec.data = _rec.data;
    }

    function retrieve() public view returns (Record memory){
        return rec;
    }
}