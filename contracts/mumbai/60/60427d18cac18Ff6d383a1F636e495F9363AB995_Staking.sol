/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Staking {
    IERC20Token private stakingToken;

    uint256 public interestPerSecond = 4756468798; //formula (10^18 * interestInPercents / 100) / 365 / 24 / 60 / 60
    address public owner;
    address[] private stakers;
    uint256 public totalValueLocked;

    struct StakingInfo {
        address owner;
        uint256 stakingBalance;
        uint256 holdStart;
        uint256 accruedRewards;
        uint256 paidOutRewards;
        bool hasStaked;
        bool isStaking;
    }

    mapping(address => StakingInfo) public stakingInfo;

    bool public stopped = false;

    modifier runIn() {
        require(!stopped);
        _;
    }
    modifier stopIn() {
        require(stopped);
        _;
    }

    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 TVL
    );
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 TVL
    );

    constructor(address _token) {
        stakingToken = IERC20Token(_token);
        owner = msg.sender;
    }

    function updateStoped(bool _stopped) external {
        require(msg.sender == owner, "You are not the owner of the contract");
        stopped = _stopped;
    }

    function setInterest(uint256 _newInterest) public returns (bool) {
        require(msg.sender == owner, "You are not the owner of the contract");
        require(_newInterest > 0, "Interset should be more than 0");
        // for (uint8 i = 0; i < stakers.length; i++) {
        //     if (stakingInfo[stakers[i]].isStaking) {
        //         uint256 holdPeriod = block.timestamp -
        //             stakingInfo[stakers[i]].holdStart;
        //         uint256 reward = (holdPeriod * interestPerSecond) *
        //             (stakingInfo[stakers[i]].stakingBalance / 1e18);
        //         stakingInfo[stakers[i]].accruedRewards =
        //             stakingInfo[stakers[i]].accruedRewards +
        //             reward;
        //         stakingInfo[stakers[i]].holdStart = block.timestamp;
        //     }
        // }
        interestPerSecond = _newInterest;
        return true;
    }

    function stakeTokens(uint256 _amount) public runIn {
        require(_amount > 0, "You cannot stake nothing");
        uint256 _senderBalance = stakingToken.balanceOf(msg.sender);
        require(_senderBalance >= _amount, "You do not have enough tokens");

        if (stakingInfo[msg.sender].owner == address(0)) {
            stakingInfo[msg.sender] = StakingInfo(
                msg.sender,
                0,
                0,
                0,
                0,
                false,
                false
            );
        }

        StakingInfo storage _stakingInfo = stakingInfo[msg.sender];
        if (_stakingInfo.isStaking) {
            uint256 holdPeriod = block.timestamp - _stakingInfo.holdStart;
            uint256 reward = (holdPeriod * interestPerSecond) *
                (_stakingInfo.stakingBalance / 1e18);
            _stakingInfo.accruedRewards = _stakingInfo.accruedRewards + reward;
        }
        bool success = stakingToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(
            success == true,
            "You could not statke token. Failed to transfer token."
        );

        _stakingInfo.stakingBalance = _stakingInfo.stakingBalance + _amount;
        _stakingInfo.holdStart = block.timestamp;
        if (!_stakingInfo.hasStaked) {
            stakers.push(msg.sender);
        }
        _stakingInfo.isStaking = true;
        _stakingInfo.hasStaked = true;
        totalValueLocked = totalValueLocked + _amount;

        emit Deposit(msg.sender, _amount, block.timestamp, totalValueLocked);
    }

    function claimableRewards() public view returns (uint256) {
        StakingInfo storage _stakingInfo = stakingInfo[msg.sender];
        if (_stakingInfo.holdStart == 0) return _stakingInfo.accruedRewards;

        if (_stakingInfo.stakingBalance == 0)
            return _stakingInfo.accruedRewards;
        if (_stakingInfo.isStaking) {
            uint256 holdPeriod = block.timestamp - _stakingInfo.holdStart;
            uint256 reward = interestPerSecond *
                (_stakingInfo.stakingBalance / 1e18) *
                holdPeriod;
            return _stakingInfo.accruedRewards + reward;
        } else {
            return _stakingInfo.accruedRewards;
        }
    }

    function claimRewards() public {
        StakingInfo storage _stakingInfo = stakingInfo[msg.sender];

        if (_stakingInfo.isStaking) {
            uint256 holdPeriod = block.timestamp - _stakingInfo.holdStart;
            uint256 reward = interestPerSecond *
                (_stakingInfo.stakingBalance / 1e18) *
                holdPeriod;
            _stakingInfo.accruedRewards = _stakingInfo.accruedRewards + reward;
            _stakingInfo.paidOutRewards =
                _stakingInfo.paidOutRewards +
                _stakingInfo.accruedRewards;

            if (_stakingInfo.accruedRewards > 0) {
                bool success = stakingToken.transferFrom(
                    owner,
                    msg.sender,
                    _stakingInfo.accruedRewards
                );
                require(
                    success == true,
                    "You could not receive reward. Failed to transfer token."
                );
                _stakingInfo.accruedRewards = 0;
            }
            _stakingInfo.holdStart = block.timestamp;
        } else {
            if (_stakingInfo.accruedRewards > 0) {
                bool success = stakingToken.transferFrom(
                    owner,
                    msg.sender,
                    _stakingInfo.accruedRewards
                );
                require(
                    success == true,
                    "You could not receive reward. Failed to transfer token."
                );
                _stakingInfo.paidOutRewards =
                    _stakingInfo.paidOutRewards +
                    _stakingInfo.accruedRewards;
                _stakingInfo.accruedRewards = 0;
            }
            _stakingInfo.holdStart = 0;
        }
    }

    function unstakeTokens(uint256 _amount) public {
        StakingInfo storage _stakingInfo = stakingInfo[msg.sender];

        require(
            _stakingInfo.stakingBalance >= _amount,
            "Cannot unstake more than you staked"
        );
        uint256 holdPeriod = block.timestamp - _stakingInfo.holdStart;
        uint256 reward = interestPerSecond *
            (_stakingInfo.stakingBalance / 1e18) *
            holdPeriod;
        _stakingInfo.accruedRewards = _stakingInfo.accruedRewards + reward;
        bool success = stakingToken.transfer(msg.sender, _amount);
        require(success == true, "Something went wrong");
        _stakingInfo.stakingBalance = _stakingInfo.stakingBalance - _amount;
        totalValueLocked = totalValueLocked - _amount;
        if (_stakingInfo.stakingBalance > 0) {
            _stakingInfo.isStaking = true;
            _stakingInfo.holdStart = block.timestamp;
        } else if (_stakingInfo.stakingBalance == 0) {
            _stakingInfo.isStaking = false;
            _stakingInfo.holdStart = 0;
        }
        emit Withdraw(msg.sender, _amount, block.timestamp, totalValueLocked);
    }
}