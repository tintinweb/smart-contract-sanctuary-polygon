/**
 *Submitted for verification at polygonscan.com on 2022-07-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract anycallV6receiverPolygon{
    event NewMsg(string msg);



    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result){
        (string memory _msg) = abi.decode(_data, (string));  
        emit NewMsg(_msg);
        success=true;
        result='';

    }


    function anyExecuteTest(bytes memory _data) external {
        (string memory _msg) = abi.decode(_data, (string));  
        emit NewMsg(_msg);
    }

}