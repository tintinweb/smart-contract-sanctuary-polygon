// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Airdrop {

    IERC20 airdropToken;
    address owner;
    uint256 airdropAmount;

    modifier onlyAdmin() {
        require(msg.sender == owner, "Not admin");
        _;
    }

    event Claim(address indexed sender, uint256 amount);
    event WithdrawUnclaim(address owner, uint256 amount);
    event AdminChange(address newOwner);

    struct Claimed {
        bool eligible;
        bool claimed;
    }

    mapping (address => Claimed) public airdrop;

    constructor(address _tokenAddress, uint256 _amount, address[] memory _users) {
        owner = msg.sender;

        airdropToken = IERC20(_tokenAddress);
        airdropAmount = _amount;

        for (uint256 i = 0; i < _users.length; i++) {
            airdrop[_users[i]].eligible = true;
            airdrop[_users[i]].claimed = false;
        }
    }

    function claim() public {
        Claimed memory user = airdrop[msg.sender];

        require(airdropToken.balanceOf(address(this)) > 0, "No more airdrops left.");
        require(user.eligible, "Not eligible.");
        require(!user.claimed, "Airdrop already claimed.");

        user.claimed = true;
        airdrop[msg.sender] = user;

        emit Claim(msg.sender, airdropAmount);
        airdropToken.transfer(msg.sender, airdropAmount);
    }

    function withdrawRemainingTokens() public onlyAdmin {
        uint256 balance = airdropToken.balanceOf(address(this));
        airdropToken.transfer(owner, balance);

        emit WithdrawUnclaim(owner, balance);
    }

    function changeAdmin(address _newOwner) public onlyAdmin {
        owner = _newOwner;

        emit AdminChange(owner);
    }
}