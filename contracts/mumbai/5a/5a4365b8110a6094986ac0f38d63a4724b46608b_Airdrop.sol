/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
interface ERC20 {
function transfer(address recipient, uint256 amount) external returns (bool);
function balanceOf(address account) external view returns (uint256);}
contract Airdrop {
    address public tokenAddress;
    uint256 public claimFee;
    address public owner;
    mapping(address => bool) public hasClaimed;
    event Claim(address indexed user, uint256 amount);
    event FeeWithdrawal(address indexed user, uint256 amount);
    modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function");
    _;}
    constructor(address _tokenAddress, uint256 _claimFee) {
        tokenAddress = _tokenAddress;
        claimFee = _claimFee;
        owner = msg.sender;}
    function claim() external payable {
        require(!hasClaimed[msg.sender], "Already claimed");
        require(msg.value >= claimFee, "Insufficient fee");
        hasClaimed[msg.sender] = true;
        ERC20 token = ERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to distribute");
    uint256 amount = 10000000000000000000000; // Auto claim with value
    require(token.transfer(msg.sender, amount), "Transfer failed");
    emit Claim(msg.sender, amount);}
    function setClaimFee(uint256 _claimFee) external onlyOwner {
    claimFee = _claimFee;}
    function withdraw() external onlyOwner {
    require(payable(msg.sender).send(address(this).balance));}
}