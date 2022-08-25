/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

pragma solidity ^0.8.10;

contract testNft {
    string private _name;

    function setName(string memory name) public {
        _name = name;
    }

    function getName() public view returns (string memory){
        return _name;
    }

}