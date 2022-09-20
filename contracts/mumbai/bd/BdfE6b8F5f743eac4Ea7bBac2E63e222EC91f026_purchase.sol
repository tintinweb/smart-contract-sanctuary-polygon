// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface USDC {

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract purchase {
    USDC public USDc;
    address owner;
    mapping(address => uint) public stakingBalance;

    constructor() {
        USDc = USDC(0xbe49ac1EadAc65dccf204D4Df81d650B50122aB2);
        owner = msg.sender;
    }
    function depositTokens(uint $USDC) public {

        // amount should be > 0

        // transfer USDC to this contract
        USDc.transferFrom(msg.sender, address(this), $USDC * 10 ** 6);
        
        // update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + $USDC * 10 ** 6;
    }

    // Unstaking Tokens (Withdraw)
    function withdrawalTokens() public {
        uint balance = stakingBalance[msg.sender];

        // balance should be > 0
        require (balance > 0, "staking balance cannot be 0");

        // Transfer USDC tokens to the users wallet
        USDc.transfer(msg.sender, balance);

        // reset balance to 0
        stakingBalance[msg.sender] = 0;
    }
}