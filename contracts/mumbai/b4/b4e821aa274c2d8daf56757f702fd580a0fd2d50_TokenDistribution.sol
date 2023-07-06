/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenDistribution {
    address public owner;
    IBEP20 public token;
    uint256 public totalTokens;
    uint256 public totalAirdropped;
    uint256 public totalSold;
    uint256 public airdropAmount;
    mapping(address => uint256) public airdropBalances;
    mapping(address => uint256) public saleBalances;
    bool public airdropCompleted;
    bool public saleCompleted;

    event TokensAirdropped(address indexed recipient, uint256 amount);
    event TokensSold(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor(
        address _tokenAddress,
        uint256 _totalTokens,
        uint256 _airdropAmount
    ) {
        owner = msg.sender;
        token = IBEP20(_tokenAddress);
        totalTokens = _totalTokens;
        airdropAmount = _airdropAmount;
    }

    function claimAirdrop() external payable {
        require(!airdropCompleted, "Airdrop has already been completed");
        require(totalAirdropped + airdropAmount <= totalTokens, "Not enough tokens left for airdrop");
        require(msg.value >= 0.005 ether, "Insufficient payment for airdrop");

        airdropBalances[msg.sender] += airdropAmount;
        totalAirdropped += airdropAmount;

        emit TokensAirdropped(msg.sender, airdropAmount);
    }

    function claimToken() external payable {
        require(!saleCompleted, "Token sale has already ended");
        require(msg.value >= 0.01 ether, "Minimum purchase amount not met");

        uint256 amountToBuy = msg.value / getPrice();
        require(amountToBuy > 0, "Insufficient payment for token purchase");

        saleBalances[msg.sender] += amountToBuy;
        totalSold += amountToBuy;

        emit TokensSold(msg.sender, amountToBuy);
    }

    function setAirdropAmount(uint256 newAirdropAmount) external onlyOwner {
    require(!airdropCompleted, "Airdrop has already been completed");
    require(newAirdropAmount > 0, "Invalid airdrop amount");

    airdropAmount = newAirdropAmount;
    }

    function setTokenSaleAmount(uint256 newTokenSaleAmount) external onlyOwner {
        require(!saleCompleted, "Token sale has already ended");
        require(newTokenSaleAmount > 0, "Invalid token sale amount");

        totalTokens = newTokenSaleAmount;
    }


    function getPrice() public view returns (uint256) {
        return (totalTokens - totalSold) / airdropAmount;
    }

    function getTokenAddress() external view returns (address) {
    return address(token);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        require(saleCompleted, "Token sale has not ended yet");

        token.transfer(owner, amount);
    }

    function withdrawFunds(address payable recipient, uint256 amount) external onlyOwner {
        require(saleCompleted, "Token sale has not ended yet");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid withdrawal amount");

        require(address(this).balance >= amount, "Insufficient contract balance");

        recipient.transfer(amount);
    }

    function completeAirdrop() external onlyOwner {
        require(!airdropCompleted, "Airdrop has already been completed");
        require(totalAirdropped == totalTokens, "Not all tokens have been airdropped");

        airdropCompleted = true;
    }

    function completeSale() external onlyOwner {
        require(!saleCompleted, "Token sale has already ended");
        require(totalSold == totalTokens, "Not all tokens have been sold");

        saleCompleted = true;
    }

    function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Invalid new owner address");
    owner = newOwner;
    }

}