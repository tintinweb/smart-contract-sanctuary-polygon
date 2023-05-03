/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

pragma solidity ^0.8.0;

// 定义一个接口，包含 gatekeep 合约的 enter 函数
interface IGateKeep {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract MyContract {
    IGateKeep private gateKeep;
    address private gateKeepAddress = 0x6D2fC6B14baEeF80D4B3d8fc4E3888079F81b7ef;
    bytes8 private constant gateKey = 0x000000010000f232;

    constructor() {
        gateKeep = IGateKeep(gateKeepAddress);
    }

    function callEnter(address gateKeepAddress) public returns (bool) {
        return gateKeep.enter(gateKey);
    }
}