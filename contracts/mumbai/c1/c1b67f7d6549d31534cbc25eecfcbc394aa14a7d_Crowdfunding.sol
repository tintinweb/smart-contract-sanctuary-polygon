/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
//import "hardhat/console.sol";

contract Crowdfunding {
    // Public variables
    string public name;
    string public description;
    string public url;
    address payable public wallet;
    uint256 public state = 1;
    uint256 public goal;
    uint256 public funds;

    constructor(
        string memory _name,
        string memory _description,
        string memory _url,
        uint256 _goal
    ) {
        name = _name;
        description = _description;
        url = _url;
        goal = _goal;
        wallet = payable(msg.sender);
    }

    function addFunds() public payable {
        wallet.transfer(msg.value);
        funds += msg.value;
    }

    function getFunds() public view returns (uint256) {
        return funds;
    }
}