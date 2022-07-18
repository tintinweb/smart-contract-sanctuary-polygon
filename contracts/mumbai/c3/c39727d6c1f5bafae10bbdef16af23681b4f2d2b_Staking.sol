/**
 *Submitted for verification at polygonscan.com on 2022-07-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address _addr) external view returns(uint);
    function transfer(address _recipient, uint _amount) external returns(bool);
    function transferFrom(address _sender, address _recipient, uint _amount) external returns(bool);
}

contract Staking {
    IERC20 public immutable token;
    uint256 public constant STAKE_DURATION = 1 minutes;
    uint256 private constant PERCENTS = 100;
    struct Stake {
        uint256 amount;
        uint256 startTime;
    }
    mapping(address => Stake) public stakes;
    event CreateDeposit(address sender, uint256 amount);
    event WithdrawDeposit(address recicpient, uint256 amount);

    constructor(address _token) {
        require(_token != address(0), "!token");
        token = IERC20(_token);
    }

    function createDeposit(uint256 _amount) external {
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "!transfer"
        );
        stakes[msg.sender] = Stake(_amount, block.timestamp);
        emit CreateDeposit(msg.sender, _amount);
    }

    function withdrawDeposit() external {
        Stake memory stake = stakes[msg.sender];
        bool periodIsReached = (block.timestamp - stake.startTime) >=
            STAKE_DURATION;
        require(periodIsReached, "!period");
        uint256 amount = stake.amount + (stake.amount / PERCENTS);
        uint256 contractBalance = token.balanceOf(address(this));
        amount = amount > contractBalance ? contractBalance : amount;
        stakes[msg.sender] = Stake(0, 0);
        require(token.transfer(msg.sender, amount), "!transfer");
        emit WithdrawDeposit(msg.sender, amount);
    }
}