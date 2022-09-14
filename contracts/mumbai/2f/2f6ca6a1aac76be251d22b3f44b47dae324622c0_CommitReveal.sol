/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CommitReveal {
    mapping(address => mapping (uint256 => bytes32)) public envelopesByaddress;
    mapping(string => uint256) public testimoney;

    uint256 private Id;

    // reveal a vote by providing the original vote and the salt
    function revealDescrip(string memory _description, uint256 _Id) external {
        require(keccak256(abi.encode(_description)) == envelopesByaddress[msg.sender][_Id],
            "description or Id do not match stored hash");
        testimoney[_description] += 1;
    }

    function saveDescrip(string memory _description) external returns (uint256){
        Id++;
        bytes32 hash = keccak256(abi.encode(_description));
        envelopesByaddress[msg.sender][Id] = hash;
        return Id;
    }
}