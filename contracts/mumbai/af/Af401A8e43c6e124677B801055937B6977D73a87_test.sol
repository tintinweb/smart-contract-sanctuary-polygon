/**
 *Submitted for verification at polygonscan.com on 2023-07-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test{
    address owner;

    constructor(address _owner){
        owner = _owner;
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    string public app = "YUNUUUUUUUUUUUUS";
    
    event Validate(
        string url,
        address sender
    );

    function validate(string memory _url) public onlyOwner returns (bool){
        emit Validate(_url,msg.sender);
        return true;
    }

}