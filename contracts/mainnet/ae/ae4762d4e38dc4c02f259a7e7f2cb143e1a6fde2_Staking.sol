// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Import any tokens
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./IStaking.sol";

// Start of the contract
contract Staking is ERC20, Ownable, IStaking {
    using SafeMath for uint256;

    // General setup of the contract
    address public token;

    address[] public stakers;

    uint256 public maxPoolBalance;
    uint256 public currentPoolBalance;
    uint256 public rewardPoolBalance;
    uint256 public earlyUnstakeAPY;
    uint256 public extraPeriodAPY;
    uint256 public maxPerStakeAmount;

    bool public isPaused;

    mapping(address => bool) public hasStaked;
    mapping(address => uint256) public stakingBalance; // A users total stakingBalance

    // multiple stakes
    struct StakeTerm {
        uint256 contractId;
        address stakerAddress;
        uint256 stakeAmount;
        uint256 contractDuration;
        uint256 perAPY;
        uint256 minStakingPeriod;
        uint256 contractStart;
        bool isWithdrawn;
        uint256 contractEnd;
        uint256 receivedReward;
    }

    // Creating a struct to create new term durations
    struct DurationTerm {
        uint256 durationId;
        uint256 noOfDays;
        uint256 perAPY;
        uint256 minStakingPeriod;
        bool isActive;
    }

    // An array of term duration which will be used to display on front-end using isActive status
    DurationTerm[] public durationTerms;
    mapping(address => StakeTerm[]) public stakeTerms;
    mapping(address => uint256) public stakeTermsLength;

    mapping(address => StakeTerm[]) public allStakeTerms;

    // Runs when contract is started only once, declares who the owner is (Who ever deployed)
    constructor(address _token) ERC20("Staked Day By Day", "sDBD") {
        token = _token;
        earlyUnstakeAPY = 15;
        extraPeriodAPY = 30;
        maxPoolBalance = 1000000000000000000000; // 1,000 Ether
        maxPerStakeAmount = 1000000000000000000000; // 1,000 Ether

        // initialising first 4 Duration terms
        DurationTerm memory flexiDuration = DurationTerm(1, 0, 30, 0, true);
        DurationTerm memory thirtyDaysDuration = DurationTerm(
            2,
            30,
            50,
            3,
            true
        );
        DurationTerm memory sixtyDaysDuration = DurationTerm(
            3,
            60,
            75,
            3,
            true
        );
        DurationTerm memory ninetyDaysDuration = DurationTerm(
            4,
            90,
            100,
            3,
            true
        );
        // Adding them to the array
        durationTerms.push(flexiDuration);
        durationTerms.push(thirtyDaysDuration);
        durationTerms.push(sixtyDaysDuration);
        durationTerms.push(ninetyDaysDuration);
    }

    function allStakeTermsLength()
        public
        view
        override
        onlyOwner
        returns (uint256)
    {
        return allStakeTerms[owner()].length;
    }

    function durationTermsLength() public view override returns (uint256) {
        return durationTerms.length;
    }

    function stake(
        uint256 _amount,
        uint256 _contractDuration,
        uint256 _perApy,
        uint256 _minStakingPeriod
    ) public override {
        // requirements
        require(
            isPaused == false,
            "Staking: staking has been paused by the owner"
        );
        require(
            _amount > 0 && _amount <= maxPerStakeAmount,
            "Staking: amount cannot be less than 0 or exceeds the max staking amount per stake event"
        );
        require(
            currentPoolBalance <= maxPoolBalance,
            "Staking: pool is full you cannot stake anymore"
        );
        require(
            currentPoolBalance.add(_amount) <= maxPoolBalance,
            "Staking: breaching maximum pool balance limit, try staking less"
        );
        stakeTermsLength[_msgSender()] = stakeTermsLength[_msgSender()].add(1);

        // save user stake information
        StakeTerm memory stakeTerm = StakeTerm({
            contractId: allStakeTerms[owner()].length + 1,
            stakerAddress: _msgSender(),
            stakeAmount: _amount,
            contractDuration: _contractDuration,
            perAPY: _perApy,
            minStakingPeriod: _minStakingPeriod,
            contractStart: block.timestamp,
            isWithdrawn: false,
            contractEnd: 0,
            receivedReward: 0
        });
        stakeTerms[_msgSender()].push(stakeTerm);
        allStakeTerms[owner()].push(stakeTerm);
        stakingBalance[_msgSender()] = stakingBalance[_msgSender()].add(
            _amount
        );
        // update pool balance
        currentPoolBalance = currentPoolBalance.add(_amount);
        // update staking status
        hasStaked[_msgSender()] = true;

        // mint the sDBD token
        _mint(_msgSender(), _amount);

        // transfer the stake
        IERC20(token).transferFrom(_msgSender(), address(this), _amount);
    }

    function unstake(uint256[] memory _terms) public override {
        // check the _terms length
        require(_terms.length > 0, "Staking: please select a term");
        for (uint256 i = 0; i < _terms.length; i++) {
            _unstake(_terms[i]);
        }
    }

    function _unstake(uint256 _termId) internal {
        StakeTerm memory unstakeTerm;
        uint256 index;
        for (; index < stakeTerms[_msgSender()].length; index++) {
            if (_termId == stakeTerms[_msgSender()][index].contractId) {
                unstakeTerm = stakeTerms[_msgSender()][index];
                break;
            }
        }
        require(
            !unstakeTerm.isWithdrawn,
            "Staking: the stake term has been already withdrawn"
        );

        uint256 amount = unstakeTerm.stakeAmount;
        uint256 contractEnd = block.timestamp;
        uint256 currentDuration = contractEnd.sub(unstakeTerm.contractStart);
        currentDuration = currentDuration.div(86400); // in Days

        if (unstakeTerm.contractDuration != 0) {
            require(
                currentDuration > unstakeTerm.minStakingPeriod * 1 days,
                "Staking: cannot unstake before the unstake minimum period"
            );
        }

        // calculate the reward
        uint256 reward = _calReward(
            amount,
            unstakeTerm.contractDuration,
            unstakeTerm.perAPY,
            currentDuration
        );

        require(
            reward <= rewardPoolBalance,
            "Staking: reward balace in the pool is low, cannot unstake until admin add more reward funds"
        );

        // burn the sDBD token
        _burn(_msgSender(), amount);

        // update the pool and user states
        currentPoolBalance = currentPoolBalance.sub(amount);
        rewardPoolBalance = rewardPoolBalance.sub(reward);
        stakingBalance[_msgSender()] = stakingBalance[_msgSender()].sub(amount);
        stakeTerms[_msgSender()][index].contractEnd = contractEnd;
        stakeTerms[_msgSender()][index].receivedReward = reward;
        stakeTerms[_msgSender()][index].isWithdrawn = true;
        allStakeTerms[owner()][_termId.sub(1)].contractEnd = contractEnd;
        allStakeTerms[owner()][_termId.sub(1)].receivedReward = reward;
        allStakeTerms[owner()][_termId.sub(1)].isWithdrawn = true;
        IERC20(token).transfer(_msgSender(), amount.add(reward));
    }

    function _calReward(
        uint256 _amount,
        uint256 _contractDuration,
        uint256 _perAPY,
        uint256 _currentDuration
    ) internal view returns (uint256) {
        // reward formula: reward = rewardRate * _currentDuration * amountInEther
        uint256 amountWithAPY = 0;
        // extra duration
        uint256 amountWithAPYAfterDuration = _amount.mul(extraPeriodAPY).div(
            36500
        );
        uint256 rewardAfterDuration = 0;
        uint256 reward = 0;

        // Unstake earlier
        if (_currentDuration < _contractDuration) {
            // early unstake
            amountWithAPY = _amount.mul(earlyUnstakeAPY).div(36500);
            reward = amountWithAPY.mul(_currentDuration);
        } else {
            amountWithAPY = _amount.mul(_perAPY).div(36500);
            // Flexible contract
            if (_contractDuration == 0) {
                reward = amountWithAPY.mul(_currentDuration);
            } else {
                uint256 rewardWithDuration = amountWithAPY.mul(
                    _contractDuration
                );
                uint256 durationAfterContractEnd = _currentDuration.sub(
                    _contractDuration
                );
                rewardAfterDuration = amountWithAPYAfterDuration.mul(
                    durationAfterContractEnd
                );
                reward = rewardWithDuration.add(rewardAfterDuration);
            }
        }

        return reward;
    }

    function toggleStaking() public override onlyOwner {
        isPaused = !isPaused;
    }

    function addToRewardPool(uint256 _amount) public override onlyOwner {
        require(_amount > 0, "Staking: amount cannot be 0");
        rewardPoolBalance = rewardPoolBalance.add(_amount);
        IERC20(token).transferFrom(_msgSender(), address(this), _amount);
    }

    function removeFromRewardPool(uint256 _amount) public override onlyOwner {
        require(_amount > 0, "Staking: amount cannot be 0 or less than 0");

        rewardPoolBalance = rewardPoolBalance.sub(_amount);
        IERC20(token).transfer(_msgSender(), _amount);
    }

    // Function to add new Term Durations
    function addDurationTerm(
        uint256 _noOfDays,
        uint256 _perAPY,
        uint256 _minStakingPeriod
    ) public override onlyOwner {
        for (uint256 i = 0; i < durationTerms.length; i++) {
            if (durationTerms[i].noOfDays == _noOfDays) {
                durationTerms[i].isActive = true;
                revert("Staking: The requested Duration Term already exists!");
            }
        }
        DurationTerm memory durationTerm = DurationTerm(
            durationTerms.length + 1,
            _noOfDays,
            _perAPY,
            _minStakingPeriod,
            true
        );
        durationTerms.push(durationTerm);
    }

    function setDurationTerm(
        uint256 _durationId,
        uint256 _perAPY,
        uint256 _minStakingPeriod,
        bool _isActive
    ) public override onlyOwner {
        for (uint256 i = 0; i < durationTerms.length; i++) {
            if (_durationId == durationTerms[i].durationId) {
                durationTerms[i].perAPY = _perAPY;
                durationTerms[i].minStakingPeriod = _minStakingPeriod;
                durationTerms[i].isActive = _isActive;
                break;
            }
        }
    }

    function setMaxPoolBalance(uint256 _newMaxPoolBalance)
        public
        override
        onlyOwner
    {
        require(
            maxPoolBalance != _newMaxPoolBalance,
            "Staking: new max pool balance cannot be the same"
        );
        maxPoolBalance = _newMaxPoolBalance;
    }

    function setEarlyUnstakeAPY(uint256 _apy) public override onlyOwner {
        require(_apy > 0, "Staking: apy cannot be 0");
        earlyUnstakeAPY = _apy;
    }

    function setExtraPeriodAPY(uint256 _apy) public override onlyOwner {
        require(_apy > 0, "Staking: apy cannot be 0");
        extraPeriodAPY = _apy;
    }

    function setMaxPerStakeAmount(uint256 _amount) public override onlyOwner {
        require(_amount > 0, "Staking: amount cannot be 0");
        maxPerStakeAmount = _amount;
    }
}