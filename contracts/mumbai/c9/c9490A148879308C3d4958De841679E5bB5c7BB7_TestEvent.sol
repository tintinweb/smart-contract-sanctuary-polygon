/**
 *Submitted for verification at polygonscan.com on 2022-05-03
*/

// File: contracts/TestEvent.sol


pragma solidity 0.8.13;

contract TestEvent {

    event SampleEvent(address indexed _address, uint256 indexed _number, uint256[] _array);

    function yeet(address _address, uint256 _number, uint256[] calldata _array) public {
        emit SampleEvent(_address, _number, _array);
    }

}