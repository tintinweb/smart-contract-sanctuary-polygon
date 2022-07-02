/**
 *Submitted for verification at polygonscan.com on 2022-07-02
*/

pragma solidity ^0.4.24;


contract ProxyStorage {
    address public implementation;
}
contract valueStorage {
    uint256 public value;
}
contract contract_V2 is ProxyStorage,valueStorage {
    function setvalue() public {
        value = value+1;
    }
}