/**
 *Submitted for verification at polygonscan.com on 2022-05-12
*/

pragma solidity >=0.4.21 <0.6.0;

contract Value {

    uint256 public value;
    uint256 public value2;

    event updateValue(uint256 value);
    event updateValue2(uint256 value);
    event donateMessage(string message);

    function setValue(uint256 newValue) public {
        value = newValue;

        emit updateValue(newValue);
    }

    function setValue2(uint256 newValue) public {
        value2 = newValue;

        emit updateValue2(newValue);
    }

    function donate(string memory message) payable public {
        emit donateMessage(message);
    }
}