/**
 *Submitted for verification at polygonscan.com on 2023-06-11
*/

pragma solidity ^0.8.0;

contract Contribution {
    address payable public immutable owner;
    uint public totalContributed;
    bool public isReleased;
    uint256 public dropTime;

    event Contribution(address indexed contributor, uint256 amount);
    event FundsReleased();
    event Sweep();

    constructor(uint256 dropTime) {
        owner = payable(msg.sender);
        dropTime = dropTime;
    }

    function release() external {
        require(msg.sender == owner, "Only the contract owner can release funds");
        require(block.timestamp >= dropTime, "Funds cannot be released before the album drop time");
        isReleased = true;
        emit FundsReleased();
    }

    function contribute() external payable {
        require(msg.value >= 0.05 ether, "Contribution must be at least 0.05 ETH");
        totalContributed += msg.value;
        if (totalContributed >= 10 ether) {
            isReleased = true;
        }
        emit Contribution(msg.sender, msg.value);
    }

    function withdraw() external {
        require(msg.sender == owner, "Only the contract owner can withdraw funds");
        require(isReleased, "Funds have not yet been released");
        owner.transfer(address(this).balance);
        emit Sweep();
    }
}