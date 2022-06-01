/**
 *Submitted for verification at polygonscan.com on 2022-05-31
*/

pragma solidity >=0.4.16 <0.9.0;
// SPDX-License-Identifier: MIT
contract  Storage {

    mapping(uint256 => string)public _data;

    function set(uint256 k, string memory v) public virtual{
        _data[k] = v;
    }
    function get(uint256 k) public view virtual returns (string memory) {
        return  _data[k];
    }
}