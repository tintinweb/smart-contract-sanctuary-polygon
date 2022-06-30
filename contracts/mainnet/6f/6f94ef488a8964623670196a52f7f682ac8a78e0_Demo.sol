/**
 *Submitted for verification at polygonscan.com on 2022-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Demo{

    string[] public strs;

    constructor () {

    }

    function add(string calldata _string) external{
        strs.push(_string);
    }


    function callContract(address _addr) external {
        for(uint i = 1 ; i<5 ;i++) {
            ( bool success, bytes memory data) = _addr.call(abi.encodeWithSignature("uri(uint256)", i));
            require(success,"failed");
            (string memory str) =  abi.decode(data,(string));
            strs.push(str);
        }
    }

    function get() public view returns(string[] memory){
        return strs;
    } 

}