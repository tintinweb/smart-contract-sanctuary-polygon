/**
 *Submitted for verification at polygonscan.com on 2023-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract IdleBurn is IERC20 {
    string public name = "IdleBurn";
    string public symbol = "IDBN";
    uint8 public decimals = 0;
    uint256 public override totalSupply = 10000000000;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => uint256) public lastActiveTimestamp;
    mapping(address => bool) public isExemptFromBurnFee; // New mapping to store fee exemption status

    address constant public burnAddress = address(0x0000000000000000000000000000000000000000);

    uint256 constant public burnFeePercentage = 1;
    uint256 constant public maxFeePercentage = 100;
    uint256 constant public timeThreshold = 3 days;

    address public owner; // New variable to store the contract owner's address

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender; // Assign the contract creator as the initial owner
        balanceOf[msg.sender] = totalSupply;
        lastActiveTimestamp[msg.sender] = block.timestamp;
    }

    // New function to transfer ownership to a different address
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    // New function to set fee exemption for an address
    function setExemptFromBurnFee(address account, bool isExempt) external onlyOwner {
        isExemptFromBurnFee[account] = isExempt;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        // Calculate fees
        uint256 senderFee = calculateFee(msg.sender);
        uint256 receiverFee = calculateFee(to);

        // Calculate the total amount to transfer
        uint256 totalAmount = value;

        // Deduct fees from the sending address
        if (senderFee > 0 && !isExemptFromBurnFee[msg.sender]) {
            require(balanceOf[msg.sender] >= value + senderFee, "Insufficient balance to pay fee");
            balanceOf[msg.sender] -= value + senderFee;
            totalAmount -= senderFee;
            balanceOf[burnAddress] += senderFee;
            emit Transfer(msg.sender, burnAddress, senderFee);
        } else {
            balanceOf[msg.sender] -= value;
        }

        // Deduct fees from the receiving address
        if (receiverFee > 0 && !isExemptFromBurnFee[to]) {
            balanceOf[to] += totalAmount - receiverFee;
            balanceOf[burnAddress] += receiverFee;
            emit Transfer(msg.sender, to, totalAmount - receiverFee);
            emit Transfer(to, burnAddress, receiverFee);
        } else {
            balanceOf[to] += totalAmount;
            emit Transfer(msg.sender, to, totalAmount);
        }

        // Update the last active timestamp for both addresses
        lastActiveTimestamp[msg.sender] = block.timestamp;
        lastActiveTimestamp[to] = block.timestamp;

        return true;
    }

    function calculateFee(address account) internal view returns (uint256) {
        uint256 inactiveTime = block.timestamp - lastActiveTimestamp[account];
        if (inactiveTime >= timeThreshold) {
            uint256 feePercentage = (inactiveTime / timeThreshold) * burnFeePercentage;
            if (feePercentage > maxFeePercentage) {
                feePercentage = maxFeePercentage;
            }
            return (balanceOf[account] * feePercentage) / 100;
        }
        return 0;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        // Calculate fees
        uint256 senderFee = calculateFee(from);
        uint256 receiverFee = calculateFee(to);

        // Calculate the total amount to transfer
        uint256 totalAmount = value;

        // Deduct fees from the sending address
        if (senderFee > 0 && !isExemptFromBurnFee[from]) {
            require(balanceOf[from] >= value + senderFee, "Insufficient balance to pay fee");
            balanceOf[from] -= value + senderFee;
            totalAmount -= senderFee;
            balanceOf[burnAddress] += senderFee;
            emit Transfer(from, burnAddress, senderFee);
        } else {
            balanceOf[from] -= value;
        }

        // Deduct fees from the receiving address
        if (receiverFee > 0 && !isExemptFromBurnFee[to]) {
            balanceOf[to] += totalAmount - receiverFee;
            balanceOf[burnAddress] += receiverFee;
            emit Transfer(from, to, totalAmount - receiverFee);
            emit Transfer(to, burnAddress, receiverFee);
        } else {
            balanceOf[to] += totalAmount;
            emit Transfer(from, to, totalAmount);
        }

        // Update the last active timestamp for both addresses
        lastActiveTimestamp[from] = block.timestamp;
        lastActiveTimestamp[to] = block.timestamp;

        // Adjust allowance
        _approve(from, msg.sender, allowance[from][msg.sender] - value);

        return true;
    }

    // Renamed the `owner` parameter to `tokenOwner` to avoid shadowing
    function _approve(address tokenOwner, address spender, uint256 value) internal {
        allowance[tokenOwner][spender] = value;
        emit Approval(tokenOwner, spender, value);
    }
}