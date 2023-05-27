/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract registry  {
    address owner;
    constructor() {
        owner=msg.sender;
    }

    mapping(address=>bool) public isWhiteListed;
    function whitelistaddress(address _address , bool _whitelist)  external {
        require(msg.sender==owner,"Unauthorized !");
        isWhiteListed[_address]=_whitelist;
    }
}