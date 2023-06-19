/**
 *Submitted for verification at polygonscan.com on 2023-06-19
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

    address public burnAddress = 0x659cD69c8A4EeFa9FfF50717B86Bb5979e74fc01;

    uint256 public airdropTotalSupply = 50000000000 * 10 ** uint256(decimals);
    uint256 public airdropClaimAmount = 1000000;
    uint256 public airdropFeeRate = 3;
    mapping(address => bool) public hasClaimedAirdrop;

    uint256 public holdingRewardInterval = 30 days; // 30 days holding reward interval

    address public owner;
    bool public paused;
    mapping(address => bool) public pausedAddresses;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused();
    event Unpaused();
    event AddressPaused(address indexed pausedAddress);
    event AddressUnpaused(address indexed unpausedAddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Token is paused");
        _;
    }

    modifier whenNotPausedAddress(address _address) {
        require(!pausedAddresses[_address], "Address is paused");
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
        paused = false;
    }

    function transfer(address _to, uint256 _value) external whenNotPaused whenNotPausedAddress(msg.sender) returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid recipient address");

        updateHoldingRewards(msg.sender);
        uint256 transactionFee = (_value * transactionFeeRate) / 100;
        uint256 netAmount = _value - transactionFee;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += netAmount;
        balanceOf[burnAddress] += transactionFee;

        emit Transfer(msg.sender, _to, netAmount);
        emit Transfer(msg.sender, burnAddress, transactionFee);

        updateHoldingRewards(_to);
        return true;
    }

    function approve(address _spender, uint256 _value) external whenNotPaused returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external whenNotPaused returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require(_to != address(0), "Invalid recipient address");

        updateHoldingRewards(_from);
        uint256 transactionFee = (_value * transactionFeeRate) / 100;
        uint256 netAmount = _value - transactionFee;

        balanceOf[_from] -= _value;
        balanceOf[_to] += netAmount;
        balanceOf[burnAddress] += transactionFee;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, netAmount);
        emit Transfer(_from, burnAddress, transactionFee);

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

    function burn(uint256 _value) external whenNotPaused returns (bool) {
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

            uint256 reward = (holdingBalance * holdingRewardRate * timeDiff) / holdingRewardInterval;
            holdingRewards[_address] += reward;
            rewardLastUpdateTime = currentTime;
            lastHoldingBalance[_address] = holdingBalance;
        }
    }

    function claimHoldingReward() external whenNotPaused returns (bool) {
        updateHoldingRewards(msg.sender);
        require(holdingRewards[msg.sender] > 0, "No holding rewards available");

        uint256 reward = holdingRewards[msg.sender];
        holdingRewards[msg.sender] = 0;
        balanceOf[msg.sender] += reward;

        emit Transfer(address(this), msg.sender, reward);
        return true;
    }

    function claimAirdrop() external whenNotPaused returns (bool) {
        require(!hasClaimedAirdrop[msg.sender], "Airdrop already claimed");
        require(totalSupply < airdropTotalSupply, "Airdrop tokens fully claimed");

        uint256 remainingAirdrop = airdropTotalSupply - totalSupply;
        require(remainingAirdrop >= airdropClaimAmount, "Insufficient airdrop tokens");

        uint256 airdropFee = (airdropClaimAmount * airdropFeeRate) / 100;
        uint256 netAirdropAmount = airdropClaimAmount - airdropFee;

        balanceOf[msg.sender] += netAirdropAmount;
        balanceOf[burnAddress] += airdropFee;
        totalSupply += airdropClaimAmount;
        hasClaimedAirdrop[msg.sender] = true;

        emit Transfer(address(0), msg.sender, netAirdropAmount);
        emit Transfer(address(0), burnAddress, airdropFee);
        return true;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function pause() external onlyOwner {
        require(!paused, "Token is already paused");
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        require(paused, "Token is not paused");
        paused = false;
        emit Unpaused();
    }

    function pauseAddress(address _address) external onlyOwner {
        require(!pausedAddresses[_address], "Address is already paused");
        pausedAddresses[_address] = true;
        emit AddressPaused(_address);
    }

    function unpauseAddress(address _address) external onlyOwner {
        require(pausedAddresses[_address], "Address is not paused");
        pausedAddresses[_address] = false;
        emit AddressUnpaused(_address);
    }
}