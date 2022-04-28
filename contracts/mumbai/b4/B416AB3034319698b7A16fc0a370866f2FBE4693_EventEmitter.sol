/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

pragma solidity ^0.8.0;

contract EventEmitter {

    mapping(uint => bytes32) public data;

    uint public eventId = 1;
    uint public dataId = 0;
    uint public nextRequestId = 1;

    event ThisIsEvent(address sender, uint eventId);

    function emitEvent()
    external {
        emit ThisIsEvent(msg.sender, eventId);

        eventId++;
    }

    function requestData()
    external {
        nextRequestId++;
    }

    function writeData()
    external {
        while((nextRequestId - dataId) > 1) {
            bytes32 _data = keccak256(abi.encode(dataId));

            data[dataId] = _data;

            dataId++;
        }
    }

}