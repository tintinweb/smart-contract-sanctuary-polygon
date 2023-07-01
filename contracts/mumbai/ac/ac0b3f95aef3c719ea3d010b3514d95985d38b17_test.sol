/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test{

    string public app = "YUNUUUUUUUUUUUUS";
    
    event Validate(
        string url,
        bool answer,
        address sender
    );

    function validate(string memory _url, bool answer) public returns (bool){
        emit Validate(_url,answer,msg.sender);
        return true;
    }

}