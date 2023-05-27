// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract StakingContract {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public totalStaked;
    uint256 public fixedAPY;
    ERC20 public token;

    event StakeDeposited(
        address indexed staker,
        uint256 amount,
        uint256 endTime
    );
    event StakeWithdrawn(
        address indexed staker,
        uint256 amount,
        uint256 reward
    );

    constructor(address _tokenAddress, uint256 _fixedAPY) {
        token = ERC20(_tokenAddress);
        fixedAPY = _fixedAPY;
    }

    function deposit(uint256 _amount, uint256 _duration) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");

        uint256 endTime = block.timestamp + _duration;
        uint256 reward = (_amount * fixedAPY * _duration) / (100 * 365 days);

        stakes[msg.sender].push(Stake(_amount, block.timestamp, endTime));
        totalStaked[msg.sender] += _amount;

        emit StakeDeposited(msg.sender, _amount, endTime);

        // Transfer the staked tokens from the staker to this contract
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );

        // Transfer the reward tokens to the staker
        require(token.transfer(msg.sender, reward), "Token transfer failed");
    }

    function withdraw(uint256 _index) external {
        require(_index < stakes[msg.sender].length, "Invalid stake index");

        Stake memory stake = stakes[msg.sender][_index];
        require(block.timestamp >= stake.endTime, "Stake not yet matured");

        uint256 reward = calculateReward(
            stake.amount,
            stake.startTime,
            stake.endTime
        );

        // Transfer the staked tokens back to the staker
        require(
            token.transfer(msg.sender, stake.amount),
            "Token transfer failed"
        );

        // Transfer the reward tokens to the staker
        require(token.transfer(msg.sender, reward), "Token transfer failed");

        // Update stake and totalStaked data
        totalStaked[msg.sender] -= stake.amount;
        delete stakes[msg.sender][_index];

        emit StakeWithdrawn(msg.sender, stake.amount, reward);
    }

    function calculateReward(
        uint256 _amount,
        uint256 _startTime,
        uint256 _endTime
    ) internal view returns (uint256) {
        return
            (_amount * fixedAPY * (_endTime - _startTime)) / (100 * 365 days);
    }
}