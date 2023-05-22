/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract AciDataCheckV2 {
    address private owner;
    uint private counter;
    mapping(string => string) private blocks;

    /* ********** Restriction ********* */
    modifier OnlyOwner() {
        require(msg.sender == owner, "Permission Denied");
        _;
    }

    /* ************* Events *********** */
    event BlockAdded(string _block_hash, string _block_pointer);

    constructor() {
        owner = msg.sender;
        counter = 0;
    }

    function transferOwnership(address newAddress) public OnlyOwner {
        require(newAddress != address(0), "Invalid Address");
        owner = newAddress;
    }

    /* *********** Function ********** */
    function addBlockPointerHash(
        string calldata _block_pointer,
        string calldata _block_hash
    ) external OnlyOwner {
        require(bytes(_block_pointer).length != 0, "Block pointer is empty");
        require(bytes(_block_hash).length != 0, "Block hash is empty");

        blocks[_block_pointer] = _block_hash;
        counter++;

        emit BlockAdded(_block_hash, _block_pointer);
    }

    function getBlockHash(
        string memory _block_pointer
    ) public view returns (string memory) {
        return blocks[_block_pointer];
    }

    function getNumberOfBlocksHashes() external view returns (uint) {
        return counter;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}