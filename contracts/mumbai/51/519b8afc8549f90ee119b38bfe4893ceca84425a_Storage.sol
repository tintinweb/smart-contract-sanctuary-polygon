/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    uint[] indexes;
    mapping (uint => uint) example;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    function currentIndex() public view returns (uint256){
        return indexes.length;
    }

    function add(uint x) public {
        example[indexes.length] = x;
        indexes.push(indexes.length);
    }

    function retrieveByIndex(uint x) public view returns (uint256){
        return example[x];
    }

    function retrieveAll() public view returns (uint[] memory){
        uint[] memory ret = new uint[](indexes.length);
        for (uint i = 0; i < indexes.length; i++) {
        ret[i] = example[i];
        }
        return ret;
    }

}