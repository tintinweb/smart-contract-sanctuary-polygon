pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;



contract EIPTestCall {

    address exchange;

    constructor(address _exchange){
        exchange= _exchange;
    }

    function setEx(address _exchange) public{
        exchange= _exchange;
    }

    function testCall(bytes memory calldataValue)payable public returns (bool){
        (bool success, bytes memory returnData) = exchange.call{value:msg.value}(calldataValue);
        emit BatchResult(success,returnData);
        return success;
    }

    event BatchResult(bool success, bytes  returnData);



}