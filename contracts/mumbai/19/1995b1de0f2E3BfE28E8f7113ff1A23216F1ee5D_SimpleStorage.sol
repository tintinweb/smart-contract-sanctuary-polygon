/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

/**
 * @title Simple smart contract to Read / Wite data to chain
 * @author Nawar Hisso
 * @dev This contract implements basic `read` and `write` functions
 */
contract SimpleStorage {
    /**
     * @dev Variable to store data
     */
    string private _data;

    /**
     * @dev Function to write data to the `_data` variable
     * @param data The data to be written
     */
    function write(string memory data) public {
        _data = data;
    }

    /**
     * @dev Function to read data from the `_data` variable
     * @return string The stored data
     */
    function read() public view returns (string memory) {
        return _data;
    }
}