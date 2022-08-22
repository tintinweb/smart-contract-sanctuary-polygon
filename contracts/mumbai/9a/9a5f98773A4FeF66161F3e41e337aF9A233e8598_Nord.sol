// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Nord{
    constructor(){}

    event result(uint a);

    uint a = 246;
    uint b = 21;

    function safeMint() public view returns(uint, uint) {
        return (a,b);
    }

     function sol(uint c) public {
        a += c;
        emit result(a);
    }


}