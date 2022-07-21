/**
 *Submitted for verification at polygonscan.com on 2022-07-21
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

contract Lock30 {
    struct StakingInfo {
        address owner;
        uint256 lockedAmount;
        uint256 lockTime;
        uint256 lastClaim;
        uint256 nasmgPaidOutRewards;
        uint256 diboPaidOutRewards;
        uint256 diboInterestPerSecond;
    }

    IERC20Token private nasmgToken;
    IERC20Token private diboToken;
    uint256 public diboInterestForPeriod = 3000000000000000000;
    uint256 public diboPriceKRW = 1250000000000000000000;
    uint256 private nasmgInterestPerSecond = 4822530865; //formula: 10^18 * (interest/100) / lockPeriod
    address public owner;
    address[] private stakers;
    uint256 public lockPeriod = 2592000; //in seconds
    uint256 public totalValueLocked;

    mapping(address => StakingInfo) public lockOf;

    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 totalValueLocked
    );
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 totalValueLocked
    );

    constructor(address nasmg, address dibo) {
        nasmgToken = IERC20Token(nasmg);
        diboToken = IERC20Token(dibo);
        owner = msg.sender;
    }

    function setDiboInterest(uint256 _newInterest) public returns (bool) {
        require(msg.sender == owner, "You are not the owner of the contract");
        require(_newInterest > 0, "Interest should be more than 0");
        diboInterestForPeriod = _newInterest;
        return true;
    }

    function setDiboPriceKRW(uint256 _newPrice) public returns (bool) {
        require(msg.sender == owner, "You are not the owner of the contract");
        require(_newPrice > 0, "Interest should be more than 0");
        diboPriceKRW = _newPrice;
        return true;
    }

    function setNasmgInterest(uint256 _newInterest) public returns (bool) {
        require(msg.sender == owner, "You are not the owner of the contract");
        require(_newInterest > 0, "Interest should be more than 0");
        nasmgInterestPerSecond = _newInterest;
        return true;
    }

    function lock(uint256 _amount, uint256 _diboInterestPerSecond) public {
        require(
            lockOf[msg.sender].lockedAmount == 0,
            "You have already staked"
        );
        require(_amount >= 1e18, "You cannot stake nothing");
        lockOf[msg.sender] = StakingInfo(
            msg.sender,
            _amount,
            block.timestamp,
            block.timestamp,
            lockOf[msg.sender].nasmgPaidOutRewards,
            lockOf[msg.sender].diboPaidOutRewards,
            _diboInterestPerSecond
        );
        nasmgToken.transferFrom(msg.sender, address(this), _amount);
        totalValueLocked = totalValueLocked + _amount;
        emit Deposit(msg.sender, _amount, block.timestamp, totalValueLocked);
    }

    function withdraw() public {
        require(
            lockOf[msg.sender].lockedAmount > 0,
            "You are not staking anything"
        );
        require(
            block.timestamp >= lockOf[msg.sender].lockTime + lockPeriod,
            "Assets are still locked"
        );
        uint256 reward = nasmgInterestPerSecond *
            lockPeriod *
            (lockOf[msg.sender].lockedAmount / 1e18);
        nasmgToken.transferFrom(owner, msg.sender, reward);
        lockOf[msg.sender].nasmgPaidOutRewards =
            lockOf[msg.sender].nasmgPaidOutRewards +
            reward;
        uint256 diboPeriod = lockOf[msg.sender].lockTime +
            lockPeriod -
            lockOf[msg.sender].lastClaim;
        uint256 diboReward = lockOf[msg.sender].diboInterestPerSecond *
            diboPeriod;

        if (diboReward > 0) {
            diboToken.transferFrom(owner, msg.sender, diboReward);
            lockOf[msg.sender].diboPaidOutRewards =
                lockOf[msg.sender].diboPaidOutRewards +
                diboReward;
            lockOf[msg.sender].lastClaim = block.timestamp;
        }
        nasmgToken.transfer(msg.sender, lockOf[msg.sender].lockedAmount);
        totalValueLocked = totalValueLocked - lockOf[msg.sender].lockedAmount;
        emit Withdraw(
            msg.sender,
            lockOf[msg.sender].lockedAmount,
            block.timestamp,
            totalValueLocked
        );
        lockOf[msg.sender].lockedAmount = 0;
    }

    function claimDiboRewards() public {
        require(claimableRewards() > 0, "Nothing to claim");
        require(
            lockOf[msg.sender].lockedAmount > 0,
            "You are not staking anything"
        );
        uint256 period;
        if (block.timestamp >= lockOf[msg.sender].lockTime + lockPeriod) {
            period =
                (lockOf[msg.sender].lockTime + lockPeriod) -
                lockOf[msg.sender].lastClaim;
            lockOf[msg.sender].lastClaim =
                lockOf[msg.sender].lockTime +
                lockPeriod;
        } else {
            period = block.timestamp - lockOf[msg.sender].lastClaim;
            lockOf[msg.sender].lastClaim = block.timestamp;
        }
        uint256 reward = period * lockOf[msg.sender].diboInterestPerSecond;
        diboToken.transferFrom(owner, msg.sender, reward);
        lockOf[msg.sender].diboPaidOutRewards =
            lockOf[msg.sender].diboPaidOutRewards +
            reward;
    }

    function claimableRewards() public view returns (uint256) {
        if (lockOf[msg.sender].lockedAmount > 0) {
            uint256 period;
            if (block.timestamp >= lockOf[msg.sender].lockTime + lockPeriod) {
                period =
                    (lockOf[msg.sender].lockTime + lockPeriod) -
                    lockOf[msg.sender].lastClaim;
            } else {
                period = block.timestamp - lockOf[msg.sender].lastClaim;
            }
            uint256 claimableReward;
            claimableReward = period * lockOf[msg.sender].diboInterestPerSecond;
            return claimableReward;
        } else {
            return 0;
        }
    }
}