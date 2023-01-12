// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Destination {

    uint256 public number = 0;

    event NewMsg(string msg);

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result){
        (string memory _msg) = abi.decode(_data, (string));

        emit NewMsg(_msg);
        
        success=true;
        result='';
    }
}