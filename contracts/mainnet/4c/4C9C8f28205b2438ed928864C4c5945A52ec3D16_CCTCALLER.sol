/**
 *Submitted for verification at polygonscan.com on 2022-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CCT {
     function getOwner() public view returns(address){}
     function approve(address spender, uint amount) external returns (bool) {}
     function transfer(address recipient, uint amount) external returns (bool) {}
     function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {}
    function burn(uint amount) external {}

    function allowance(address owner, address spender) external view returns (uint){}
}

contract CCTCALLER {
    CCT c;
    address contractOwner;
    constructor () {
        c = CCT(0xcEb2A23B126DF262D9f15b5f3Fdf6F8eAa2b173C);
        contractOwner  = 0xd56E152d52692aa329e218196B0E38B4B1805c39;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not owner");
        _;
    }

    function approveCaller(address spender, uint amount) external onlyOwner returns (bool) {
        return c.approve(spender,amount);
    }

    function transferCaller(address recipient, uint amount) external onlyOwner returns (bool) {
        return c.transfer(recipient,amount);
    }

    function transferFromCaller( address sender, address recipient, uint amount ) external onlyOwner returns (bool) {
        return c.transferFrom(sender,recipient,amount);
    }

    function burnCaller(uint amount) external onlyOwner {
        c.burn(amount);
    }

    function allowanceCaller(address owner, address spender) external view returns (uint){
        return c.allowance(owner,spender);
    }

}