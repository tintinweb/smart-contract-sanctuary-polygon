// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TopGear.sol"; // Import the TopGearToken contract

contract FirstGearToken {
    string public name = "FIRST GEAR";
    string public symbol = "FG";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokenPurchase(address indexed buyer, uint256 tgAmount, uint256 fgAmount);

    TopGearToken public topGearToken; // Instance of the TopGearToken contract

    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
    }

    function setTopGearTokenAddress(address _topGearTokenAddress) external {
        topGearToken = TopGearToken(_topGearTokenAddress);
    }

    function buyTokens(uint256 _tgAmount) external {
        require(_tgAmount > 0, "TG amount must be greater than zero");
        require(address(topGearToken) != address(0), "TopGearToken address not set");

        // Transfer TG tokens from the sender to this contract
        require(topGearToken.transferFrom(msg.sender, address(this), _tgAmount), "TG transfer failed");

        // Calculate the FG token amount based on the TG token amount
        uint256 fgAmount = calculateFGAmount(_tgAmount);

        // Transfer FG tokens from this contract to the buyer
        _transfer(address(this), msg.sender, fgAmount);

        // Emit event to track the token purchase
        emit TokenPurchase(msg.sender, _tgAmount, fgAmount);
    }

    function calculateFGAmount(uint256 _tgAmount) internal pure returns (uint256) {
        // Define the conversion rate: FG tokens per TG token
        uint256 rate = 10; // 1 TG = 10 FG (for example)

        // Calculate the FG token amount based on the conversion rate
        return _tgAmount * rate;
    }

    function _approve(address _owner, address _spender, uint256 _value) internal {
        allowance[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
}