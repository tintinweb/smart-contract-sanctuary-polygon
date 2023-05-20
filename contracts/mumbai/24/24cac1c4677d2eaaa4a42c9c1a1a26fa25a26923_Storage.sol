/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    string public name;
    bool public boolean;
    uint256 public number;

    constructor (
        string memory initialStr,
        bool initialBool,
        uint256 initialNum
        ) {
            name = initialStr;
            boolean = initialBool;
            number = initialNum;
        }

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function storeNum(uint256 num) public {
        number = num;
    }

    function setName(string memory newMessage) public {
        name = newMessage;
    }

    function storeBoolean(bool b) public {
        boolean = b;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function getStringValue() public view returns (string memory){
        return name;
    }

    function getNumValue() public view returns (uint256){
        return number;
    }

    function getBoolValue() public view returns (bool){
        return boolean;
    }
}