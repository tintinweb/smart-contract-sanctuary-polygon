/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Blockpay {

    event Bill(address indexed seller, address indexed buyer, bytes cid);

    function transact(address  _buyer, bytes memory _cid) public {
        require(
            msg.sender != _buyer
        );
        emit Bill(msg.sender, _buyer, _cid);
    }
}