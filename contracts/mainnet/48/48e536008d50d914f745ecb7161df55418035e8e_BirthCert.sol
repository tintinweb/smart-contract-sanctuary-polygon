/**
 *Submitted for verification at polygonscan.com on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract BirthCert {

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

    function newCertificate(string memory name, string memory dob) onlyAdmin activity public {
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