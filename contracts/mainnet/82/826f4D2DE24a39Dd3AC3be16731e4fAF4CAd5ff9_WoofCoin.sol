/**
 *Submitted for verification at polygonscan.com on 2023-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WoofCoin {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public transactionFeeRate = 3;
    uint256 public holdingRewardRate = 2;
    uint256 public rewardLastUpdateTime;
    mapping(address => uint256) public lastHoldingBalance;
    mapping(address => uint256) public holdingRewards;

    uint256 public dailySwapLimit = 100000000;
    uint256 public dailySwappedAmount;
    uint256 public lastSwapTime;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public airdropTotalSupply = 50000000000 * 10 ** uint256(decimals);
    uint256 public airdropClaimAmount = 1000000;
    mapping(address => bool) public hasClaimedAirdrop;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        name = "Woof Coin";
        symbol = "WOOF";
        decimals = 18;
        totalSupply = 1000000000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        rewardLastUpdateTime = block.timestamp;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid recipient address");

        updateHoldingRewards(msg.sender);
        uint256 transactionFee = (_value * transactionFeeRate) / 100;
        uint256 netAmount = _value - transactionFee;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += netAmount;
        balanceOf[address(this)] += transactionFee;

        emit Transfer(msg.sender, _to, netAmount);
        emit Transfer(msg.sender, address(this), transactionFee);

        updateHoldingRewards(_to);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require(_to != address(0), "Invalid recipient address");

        updateHoldingRewards(_from);
        uint256 transactionFee = (_value * transactionFeeRate) / 100;
        uint256 netAmount = _value - transactionFee;

        balanceOf[_from] -= _value;
        balanceOf[_to] += netAmount;
        balanceOf[address(this)] += transactionFee;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, netAmount);
        emit Transfer(_from, address(this), transactionFee);

        updateHoldingRewards(_to);
        return true;
    }

    function mint(address _to, uint256 _value) external onlyOwner returns (bool) {
        require(_to != address(0), "Invalid recipient address");

        totalSupply += _value;
        balanceOf[_to] += _value;
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);

        updateHoldingRewards(_to);
        return true;
    }

    function burn(uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        updateHoldingRewards(msg.sender);

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, burnAddress, _value);

        return true;
    }

    function updateHoldingRewards(address _address) internal {
        uint256 currentTime = block.timestamp;
        uint256 lastUpdateTime = rewardLastUpdateTime;
        if (currentTime > lastUpdateTime) {
            uint256 timeDiff = currentTime - lastUpdateTime;
            uint256 holdingBalance = balanceOf[_address];

            uint256 reward = (holdingBalance * holdingRewardRate * timeDiff) / (100 * 86400);
            holdingRewards[_address] += reward;
            rewardLastUpdateTime = currentTime;
            lastHoldingBalance[_address] = holdingBalance;
        }
    }

    function claimHoldingReward() external {
        updateHoldingRewards(msg.sender);
        require(holdingRewards[msg.sender] > 0, "No holding rewards available");

        uint256 reward = holdingRewards[msg.sender];
        holdingRewards[msg.sender] = 0;
        balanceOf[msg.sender] += reward;

        emit Transfer(address(this), msg.sender, reward);
    }

    function claimAirdrop() external returns (bool) {
        require(!hasClaimedAirdrop[msg.sender], "Airdrop already claimed");
        require(totalSupply < airdropTotalSupply, "Airdrop tokens fully claimed");

        uint256 remainingAirdrop = airdropTotalSupply - totalSupply;
        require(remainingAirdrop >= airdropClaimAmount, "Insufficient airdrop tokens");

        balanceOf[msg.sender] += airdropClaimAmount;
        totalSupply += airdropClaimAmount;
        hasClaimedAirdrop[msg.sender] = true;

        emit Transfer(address(0), msg.sender, airdropClaimAmount);
        return true;
    }

    function swapTokens(uint256 _amount) external returns (bool) {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        require(_amount <= dailySwapLimit - dailySwappedAmount, "Exceeds daily swap limit");

        updateHoldingRewards(msg.sender);
        uint256 transactionFee = (_amount * transactionFeeRate) / 100;
        uint256 netAmount = _amount - transactionFee;

        balanceOf[msg.sender] -= _amount;
        balanceOf[address(this)] += transactionFee;

        dailySwappedAmount += _amount;
        lastSwapTime = block.timestamp;

        emit Transfer(msg.sender, address(this), transactionFee);
        emit Transfer(msg.sender, address(this), netAmount);

        return true;
    }

    function setDailySwapLimit(uint256 _limit) external onlyOwner {
        dailySwapLimit = _limit;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}