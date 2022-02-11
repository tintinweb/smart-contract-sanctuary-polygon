/**
 *Submitted for verification at polygonscan.com on 2022-02-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MovlToken is IERC20 {
    string public constant name = "MovlToken";

    string public constant symbol = "MOVL";

    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    uint256 constant totalSupply_ = 21000000 * 10**decimals;

    address private immutable creator;

    uint256 public burnt;

    constructor() {
        creator = msg.sender;
        balances[creator] = totalSupply_;
    }

    function totalSupply() public pure override returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256)
    {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens)
        public
        override
        returns (bool)
    {
        require(numTokens > 0);
        require(numTokens <= balances[msg.sender]);

        balances[msg.sender] -= numTokens;

        incrementBalanceAndEmitEvent(msg.sender, receiver, remainingAfterBurn(numTokens));

        return true;
    }

    function approve(address delegate, uint256 numTokens)
        public
        override
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;

        emit Approval(msg.sender, delegate, numTokens);

        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        override
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] -= numTokens;

        allowed[owner][msg.sender] -= numTokens;

        incrementBalanceAndEmitEvent(owner, buyer, remainingAfterBurn(numTokens));

        return true;
    }

    function multiTransfer(address[] calldata receivers, uint256 numTokens)
        external
    {
        uint256 remaining;
        uint256 burn;

        require(msg.sender == creator);

        require(numTokens > 0);
        require((numTokens * receivers.length) <= balances[msg.sender]);

        balances[msg.sender] -= (numTokens * receivers.length);

        (remaining, burn) = splitAmount(numTokens);

        burnt += (burn * receivers.length);

        // NB: remaining may be 0 here. This is still allowed to emit an event.

        for (uint256 i = 0; i < receivers.length; i++) {
            incrementBalanceAndEmitEvent(msg.sender, receivers[i], remaining);
        }
    }

    receive() external payable {
        revert("You must not send Eth to this contract!");
    }

    function incrementBalanceAndEmitEvent(address from, address to, uint256 numTokens)
        private
    {
        balances[to] += numTokens;
        emit Transfer(from, to, numTokens);
    }

    function splitAmount(uint256 numTokens)
        private
        pure
        returns (uint256 remaining, uint256 burn)
    {
        if (numTokens < 10) {
            burn = numTokens;
        } else {
            burn = numTokens / 10;
        }
        remaining = (numTokens - burn);
    }

    function remainingAfterBurn(uint256 numTokens)
        private
        returns (uint256 remaining)
    {
        uint256 burn;
        (remaining, burn) = splitAmount(numTokens);
        burnt += burn;
    }
}