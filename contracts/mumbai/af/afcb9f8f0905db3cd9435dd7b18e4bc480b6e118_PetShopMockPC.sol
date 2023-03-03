/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
contract PetShopMockPC {
    string private name;
    address private owner;

    event CreatedContract(address owner);
    event AddedNewName(address owner, string name);

    function initialize(string memory _name) external {
        name = _name;
        emit CreatedContract(msg.sender);
    }

    function whoIsTheOwner() public pure returns (address _owner) {
        return _owner;
    }

    function setNewName(string memory _name) public {
        name = _name;
        emit AddedNewName(owner, name);
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}