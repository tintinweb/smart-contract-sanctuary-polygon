/**
 *Submitted for verification at polygonscan.com on 2022-12-29
*/

pragma solidity ^0.8.0;

// This contract has a single function that takes in a string,
// emits an event, and also saves the string to a public variable
contract KimaFinanceContract {
    string public savedString;
    event functionCalledWithParam(string param);

    function callFunction(string memory _param) public {
        savedString = _param;
        emit functionCalledWithParam(_param);
    }

    function getSavedString() public view returns (string memory) {
        return savedString;
    }
}