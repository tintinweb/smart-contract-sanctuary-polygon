// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;
contract a {
    function ff (uint256 _x) public view returns (uint256,uint256,uint256,uint256) {
        uint256 all = (block.number+_x+1)*(block.timestamp-_x-1);
        return (block.number,block.timestamp,all,_x+all%_x);
    }
}