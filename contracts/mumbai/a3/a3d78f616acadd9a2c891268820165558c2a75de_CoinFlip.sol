/**
 *Submitted for verification at polygonscan.com on 2023-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract CoinFlip {

    // contract owner address
    address public owner;

    // amount of ETH on which user play
    uint256 public play_amount;

    // contract balance
    uint256 public bank;

    // percent, which user gets in case of win
    uint8 public percent;

    uint initialNumber;

    constructor(){
        owner = msg.sender;
        percent = 10;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the contract owner!");
        _;
    }

    function changePercent(
        uint8 new_percent
    ) public onlyOwner {
        require(new_percent > 0 && new_percent <= 100, "Percent must be greater than zero, lower or equal 100!");
        percent = new_percent;
    }

    function balanceOf() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        bank += msg.value;
    }

    function play(uint8 side) payable public {
        address payable walletAddress = payable(msg.sender);
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender))) % 101;

        require(randomNumber >= 0 && randomNumber <= 100, "Incorrect random number!");
        require(side == 1 || side == 2, "Side must be equal 1 or 2!");

        if(side == 1 && randomNumber <= 50) {
            uint256 amount = msg.value + ((msg.value / 100)*percent);
            (bool success, ) = walletAddress.call{value: amount}("");
            require(success);
        } else if(side == 2 && randomNumber >= 51) {
            uint256 amount = msg.value + ((msg.value / 100)*percent);
            (bool success, ) = walletAddress.call{value: amount}("");
            require(success);
        } else {

        }
    }
}