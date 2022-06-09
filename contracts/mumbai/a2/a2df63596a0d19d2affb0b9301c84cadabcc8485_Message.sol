/**
 *Submitted for verification at polygonscan.com on 2022-06-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Message{
    string  msg;
    function setMsg(string memory _msg) public {
        msg=_msg;
    }
    function getMsg() public view returns(string memory){
        return msg;
    }
}