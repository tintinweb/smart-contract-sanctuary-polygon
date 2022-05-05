/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

// File: contracts/sampleTest.sol

//SPDX-License-Identifier: do not use

pragma solidity 0.8.13;

contract TestEvent {

    event SampleEvent(address indexed _address, uint256 indexed _number, uint256[] _array);

    address public samepleAddress;

    function yeet(address _address, uint256 _number, uint256[] calldata _array) public {
        samepleAddress = _address;
        emit SampleEvent(_address, _number, _array);
    }

}