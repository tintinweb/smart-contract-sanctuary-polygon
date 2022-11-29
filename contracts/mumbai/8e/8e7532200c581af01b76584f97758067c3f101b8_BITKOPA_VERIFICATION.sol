/**
 *Submitted for verification at polygonscan.com on 2022-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BITKOPA_VERIFICATION{

    address private s_owner; //to store address of the owner
    mapping(address => bool ) public s_whiteListedAddresses; //to store whitelisted addresses


    constructor(){
        s_owner = msg.sender;
    }

    function addAddressToWhiteList(address[] memory _addr) external onlyOwner{
        uint8 i = 0;
        for (i; i < _addr.length; i++){
            s_whiteListedAddresses[_addr[i]] = true;
        }

    }
    function removeAddressFromWhiteList(address[] memory _addr) external onlyOwner{
        uint8 i = 0;
        for(i; i< _addr.length; i++){
            s_whiteListedAddresses[_addr[i]] = false;
        }
    }

    function checkVerificationStatus(address _addr) external view returns(bool status){
        status = s_whiteListedAddresses[_addr];
        return status;
    }

    //onlyOwner modifier
    modifier onlyOwner(){
        require(msg.sender == s_owner);
        _;
    }
}