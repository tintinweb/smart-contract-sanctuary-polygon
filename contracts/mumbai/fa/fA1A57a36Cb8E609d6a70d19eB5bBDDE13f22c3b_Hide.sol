/**
 *Submitted for verification at polygonscan.com on 2022-08-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Log {
    event Logs(string);
    function log() external {
        emit Logs("Log was called");
    }
}

contract Hide {
    Log log ; 
    constructor(address _address){
        log = Log(_address);
    }

    function getLog()external {
        log.log();
    }

}