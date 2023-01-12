// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Destination {

    uint256 public number = 0;

    event numberUpdated(uint256 number);

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result){
        (uint256 _number) = abi.decode(_data, (uint256));
        number = _number; 
        emit numberUpdated(number);
        success=true;
        result='';
    }
}