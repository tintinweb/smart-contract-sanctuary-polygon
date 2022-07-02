/**
 *Submitted for verification at polygonscan.com on 2022-07-02
*/

pragma solidity ^0.4.24;


contract Proxy_Storage {
    address public implementation;
}
contract value_Storage {
    uint256 public value;
}
contract contrac_V2 is value_Storage,Proxy_Storage {
    function setvalue() public {
        value = value+1;
    }
}