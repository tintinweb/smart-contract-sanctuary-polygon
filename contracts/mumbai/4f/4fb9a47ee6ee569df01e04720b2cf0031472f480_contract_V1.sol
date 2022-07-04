/**
 *Submitted for verification at polygonscan.com on 2022-07-03
*/

pragma solidity ^0.4.24;


contract ProxyStorage {
    address public implementation;
}
contract valueStorage {
    uint256 public value;
}
contract contract_V1 is ProxyStorage,valueStorage {
    function setvalue(uint256 _value) public {
        value = _value;
    }
    uint8 public a;
    uint8 public b;
    uint8 public c;
    constructor(uint8 aa,uint8 bb,uint8 cc) public {
        a = aa;
        b = bb;
        c = cc;
    }


}