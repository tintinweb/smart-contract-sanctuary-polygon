/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract Test {
    struct Token {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalHoldersBalance;
    }

    struct TransferDetails {
        address from;
        address to;
        uint256 value;
    }

    Token public token;
    address private marketingWallet;
    address[] public holders;

    event Transfer(
        TransferDetails details,
        uint256 burnAmount,
        uint256 redistributionAmount,
        uint256 marketingAmount
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(address _marketingWallet) {
        token.name = "Test";
        token.symbol = "TST";
        token.decimals = 18;
        token.totalSupply = 4206966642069666000000000000000000;
        token.balances[msg.sender] = token.totalSupply;
        marketingWallet = _marketingWallet;
        holders.push(msg.sender);
        emit Transfer(
            TransferDetails({
                from: address(0),
                to: msg.sender,
                value: token.totalSupply
            }),
            0,
            0,
            0
        );
    }

    function balanceOf(address account) public view returns (uint256) {
        return token.balances[account];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Approve to zero address");
        token.allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address recip, uint256 amnt) public returns (bool) {
        transferFrom(msg.sender, recip, amnt);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(token.balances[sender] >= amount, "Insufficient balance");
        require(recipient != address(0), "Transfer to zero address");
        require(sender != recipient, "Self-transfer");

        uint256 burnAmount = amount / 100;
        uint256 redistributionAmount = amount / 100;
        uint256 marketingAmount = (amount / 100) * 8;
        uint256 transferAmount = amount -
            burnAmount -
            marketingAmount -
            redistributionAmount;
        require(
            amount ==
                transferAmount +
                    burnAmount +
                    marketingAmount +
                    redistributionAmount,
            "Transfer value invalid"
        );
        token.balances[sender] -= amount;
        token.balances[recipient] += transferAmount;
        token.balances[address(0)] += burnAmount;
        token.balances[marketingWallet] += marketingAmount;
        token.totalHoldersBalance += redistributionAmount;
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            uint256 holderRedistribution = (redistributionAmount *
                token.balances[holder]) / token.totalHoldersBalance;
            token.balances[holder] += holderRedistribution;
        }
        if (!isHolder(recipient)) {
            holders.push(recipient);
        }
        TransferDetails memory details = TransferDetails({
            from: sender,
            to: recipient,
            value: transferAmount
        });
        emit Transfer(
            details,
            burnAmount,
            redistributionAmount,
            marketingAmount
        );
        if (token.balances[sender] == 0) {
            token.allowances[sender][recipient] = 0;
        }
        burn(burnAmount);
        return true;
    }

    function burn(uint256 value) public returns (bool){
        token.balances[
            0x000000000000000000000000000000000000dEaD
        ] += value;
        token.totalSupply -= value;
        return true;
    }

    function isHolder(address _holder) private view returns (bool) {
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == _holder) {
                return true;
            }
        }
        return false;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        require(spender != address(0), "Approve to zero address");
        token.allowances[msg.sender][spender] += addedValue;
        emit Approval(
            msg.sender,
            spender,
            token.allowances[msg.sender][spender]
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        require(spender != address(0), "Approve to zero address");
        uint256 oldValue = token.allowances[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            token.allowances[msg.sender][spender] = 0;
        } else {
            token.allowances[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(
            msg.sender,
            spender,
            token.allowances[msg.sender][spender]
        );
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return token.allowances[owner][spender];
    }

    function name() public view returns (string memory) {
        return token.name;
    }

    function symbol() public view returns (string memory) {
        return token.symbol;
    }

    function decimals() public view returns (uint8) {
        return token.decimals;
    }

    function totalSupply() public view returns (uint256) {
        return token.totalSupply - token.balances[address(0)];
    }
}