/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract whitelisting {

    mapping(address=>bool) public whitelistdata;
    address private admin;

    constructor() {
        admin = msg.sender;
    }

    function changeadmin(address add) public Owner {
        admin = add;
    }

    modifier Owner() {
        require(admin == msg.sender,"You are not admin");
        _;
    }

    function whitelist(address _add) external Owner{
        whitelistdata[_add] = true;
    }


    function verifyUser(address _whitelistedAddress) public view returns(bool) {
    bool userIsWhitelisted = whitelistdata[_whitelistedAddress];
    return userIsWhitelisted;
}

}