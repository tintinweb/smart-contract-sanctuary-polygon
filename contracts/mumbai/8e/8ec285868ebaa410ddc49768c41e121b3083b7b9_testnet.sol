/**
 *Submitted for verification at polygonscan.com on 2022-05-14
*/

pragma solidity ^0.8.13;


contract testnet {
    string public test_data;

    constructor (string memory data_input) public {
        test_data = data_input;
    }
    
    function updater (string memory new_data) public {
        test_data = new_data;
    }
}