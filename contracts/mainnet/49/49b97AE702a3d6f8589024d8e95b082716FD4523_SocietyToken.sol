/**
 *Submitted for verification at polygonscan.com on 2023-07-12
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract SocietyToken {
    string public name = "Society Token";
    string public symbol = "SOCIETY";
    uint256 public totalSupply = 777 * 10**9 * 10**18; // 777 billion tokens
    uint8 public decimals = 18;
    uint256 public fixedTotalSupply = 77 * 10**6 * 10**18; // 77 million tokens

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public taxPercent = 5;
    uint256 public burnPercent = 2;
    uint256 public redistributionPercent = 3;

    uint256 public totalFees;
    uint256 public totalBurned;
    uint256 public totalRedistributed;

    uint256 public emissionRate;
    uint256 public emissionInterval;
    uint256 public lastHalvingBlock;

    address public rebatePool;
    address public owner;
    address public newOwner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address _rebatePool) {
        balanceOf[msg.sender] = totalSupply;
        rebatePool = _rebatePool;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        uint256 burnAmount = (_value * burnPercent) / 100;
        uint256 redistributionAmount = (_value * redistributionPercent) / 100;
        uint256 feeAmount = burnAmount + redistributionAmount;
        uint256 transferAmount = _value - feeAmount;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;

        // Burn tokens
        totalSupply -= burnAmount;
        totalBurned += burnAmount;

        // Add fees to total fees
        totalFees += feeAmount;

        // Redistribute fees to rebate pool
        balanceOf[rebatePool] += redistributionAmount;
        totalRedistributed += redistributionAmount;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, rebatePool, redistributionAmount);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");

        uint256 burnAmount = (_value * burnPercent) / 100;
        uint256 redistributionAmount = (_value * redistributionPercent) / 100;
        uint256 feeAmount = burnAmount + redistributionAmount;
        uint256 transferAmount = _value - feeAmount;

        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;

        // Burn tokens
        totalSupply -= burnAmount;
        totalBurned += burnAmount;

        // Add fees to total fees
        totalFees += feeAmount;

        // Redistribute fees to rebate pool
        balanceOf[rebatePool] += redistributionAmount;
        totalRedistributed += redistributionAmount;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, transferAmount);
        emit Transfer(_from, rebatePool, redistributionAmount);

        return true;
    }
    

    function perpetualBalance() public {
        uint256 emissionAmount = calculateEmissionAmount();

        // Emit tokens to the sender's account
        balanceOf[msg.sender] += emissionAmount;
        totalSupply += emissionAmount;

        emit Transfer(address(0), msg.sender, emissionAmount);
    }

    function calculateEmissionAmount() internal returns (uint256) {
        uint256 emissionAmount = 0;
        uint256 currentBlock = block.number;
        uint256 halvingCount = (currentBlock - lastHalvingBlock) / emissionInterval;

        for (uint256 i = 0; i < halvingCount; i++) {
            emissionRate /= 2;
            lastHalvingBlock += emissionInterval;
        }

        emissionAmount = emissionRate * (block.number - lastHalvingBlock);

        return emissionAmount;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "Only the new owner can accept ownership");
        owner = newOwner;
        newOwner = address(0);
    }
    function setRebatePool(address _newRebatePool) public onlyOwner {
    require(_newRebatePool != address(0), "Invalid new rebate pool address");
    rebatePool = _newRebatePool;
    }
}