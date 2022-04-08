/**
 *Submitted for verification at polygonscan.com on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

contract GuessGame {
    address payable contractOwner;

    event Deposit(address indexed addr, uint256 amount, uint256 timestamp);
    event Play(
        address indexed playerAddress,
        uint256 amount,
        uint256 randomNumber,
        bool didWin,
        uint256 timestamp
    );
    event Withdraw(address indexed addr, uint256 amount, uint256 timestamp);

    constructor() {
        contractOwner = payable(msg.sender);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    function rand() private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / 100) * 100));
    }

    function play() public payable returns (bool) {
        // must play with at least 0.00001 ether
        require(msg.value >= 0.00001 ether);

        // contract needs to be loaded with minimum of what you can win
        require(getContractBalance() > msg.value * 2);

        address payable player = payable(address(msg.sender));
        uint256 randomNumber = rand();

        bool didWin = randomNumber < 42;

        player.transfer(msg.value * 2);

        emit Play(player, msg.value, randomNumber, didWin, block.timestamp);
        return didWin;
    }

    function withdraw() public payable {
        uint256 contractBalance = address(this).balance;
        contractOwner.transfer(contractBalance);
        emit Withdraw(contractOwner, contractBalance, block.timestamp);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}