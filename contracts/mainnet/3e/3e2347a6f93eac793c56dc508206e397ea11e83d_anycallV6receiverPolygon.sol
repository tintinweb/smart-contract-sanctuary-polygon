/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract anycallV6receiverPolygon{
    event NewMsg(string msg);

    // The Polygon anycall address
    // address public anycallcontract=0xFC23152E04D6039b796c91C9E2FaAaeDc704B33f;

    // modifier onlyanyCall() {
    //     require(msg.sender == anycallcontract, "only Anycall contract can call this method");
    //     _;
    // }

    


    // anyExecute has to be role controlled by onlyanyCall so it's only called by anycall contract
    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result) {
        (string memory _msg) = abi.decode(_data, (string));  
        emit NewMsg(_msg);
        success=true;
        result=_data;

    }


    function anyExecuteTest(bytes memory _data) external {
        (string memory _msg) = abi.decode(_data, (string));  
        emit NewMsg(_msg);
    }

}