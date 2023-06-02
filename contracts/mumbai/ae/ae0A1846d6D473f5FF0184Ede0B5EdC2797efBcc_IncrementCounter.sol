/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// Sources flattened with hardhat v2.14.1 https://hardhat.org

// File contracts/IncrementCounter.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract IncrementCounter {
    uint256 private counter;
    address private maticTokenAddress;
    mapping(address => uint256) private balances;

    event CounterIncremented(uint256 newValue);
    event TokensDeposited(address indexed account, uint256 amount);
    event TokensWithdrawn(address indexed account, uint256 amount);

    address payable owner;

     modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner!");
        _;
    }

    constructor(address _maticTokenAddress) {
        counter = 0;
        maticTokenAddress = _maticTokenAddress;
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }

    function incrementCounter() public {
        counter++;
        emit CounterIncremented(counter);
    }

    function depositTokens(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");

        IERC20 maticToken = IERC20(maticTokenAddress);
        require(
            maticToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        balances[msg.sender] += amount;
        emit TokensDeposited(msg.sender, amount);
    }

    function withdrawTokens() external payable onlyOwner{
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No tokens to withdraw");

        require(address(this).balance > 0, "No balance to withdraw");
        owner.transfer(address(this).balance);

        balances[msg.sender] = 0;
        emit TokensWithdrawn(msg.sender, amount);
    }
}