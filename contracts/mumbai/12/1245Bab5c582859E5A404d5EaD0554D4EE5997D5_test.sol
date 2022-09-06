/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

pragma solidity 0.8.15;
contract test {
    bytes data;

    function addData(bytes calldata _data) public {
        data = _data;
    }

}