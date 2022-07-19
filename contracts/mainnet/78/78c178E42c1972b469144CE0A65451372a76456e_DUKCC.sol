/**
 *Submitted for verification at polygonscan.com on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract DUKCC {

    mapping(address => bool) private isAdmin;

    bool private status = true;

    constructor() {
        isAdmin[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Access Denied");
        _;
    }

    modifier activity() {
        require(status == true, "Contract Ceased");
        _;
    }

    function newBatch(string memory hash, string memory issuer) onlyAdmin activity public {
    }

    function newAdmin(address id) onlyAdmin activity public {
        isAdmin[id] = true;
    }

    function revokeAdmin(address id) onlyAdmin activity public {
        isAdmin[id] = false;
    }

    function cease() onlyAdmin activity public {
        status = false;
    }

}