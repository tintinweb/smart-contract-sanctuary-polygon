// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./Ownable.sol";

import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";

import "./IStabl3Staking.sol";
import "./ITreasury.sol";

contract ROI is Ownable, IStabl3StakingStruct {
    using SafeMathUpgradeable for uint256;

    uint256 private constant MAX_INT = 2 ** 256 - 1;

    uint8 private constant BUY_POOL = 0;

    uint8 private constant BOND_POOL = 1;

    uint8 private constant STAKE_POOL = 2;
    uint8 private constant STAKE_REWARD_POOL = 3;
    uint8 private constant LEND_POOL = 5;
    uint8 private constant LEND_REWARD_POOL = 6;

    uint8 private constant STAKING_TYPE_POOL = 20;

    // TODO remove
    uint256 private constant oneDayTime = 10;
    // uint256 private constant oneDayTime = 86400; // 1 day time in seconds

    ITreasury public treasury;

    IERC20 public immutable STABL3;

    IERC20 public UCD;

    IStabl3Staking public stabl3Staking;
    uint256 public maxPoolPercentage;
    uint256 public stakingTypePercentage;

    TimeWeightedAPR public timeWeightedAPR;
    uint256 public updateAPRLast;
    uint256 public updateTimestampLast;

    uint256 public contractCreationTime;

    uint8[] public returnPools;

    // storage

    /// @dev Saves all Time Weighted and current APRs corresponsing to their Time Weight
    mapping (uint256 => TimeWeightedAPR) public getTimeWeightedAPRs;
    mapping (uint256 => uint256) public getAPRs;

    /// @dev Contracts with permission to access ROI pool funds
    mapping (address => bool) public permitted;

    // events

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedPermission(address contractAddress, bool state);

    event APR(
        uint256 APR,
        uint256 reserves,
        uint256 totalRewardDistributed,
        uint256 timestamp
    );

    // constructor

    constructor(ITreasury _treasury) {
        treasury = _treasury;

        // TODO change
        STABL3 = IERC20(0xc3Bf0c0172E3638d383361801e9BF63B4FfE0d6e);

        // TODO change
        UCD = IERC20(0xB0124F5d0e906d3652d0b58F03E315eC42A57E9a);

        maxPoolPercentage = 700;
        stakingTypePercentage = 250;

        updateTimestampLast = block.timestamp;

        contractCreationTime = block.timestamp;

        returnPools = [0, 1];

        updatePermission(address(_treasury), true);
    }

    function updateTreasury(address _treasury) external onlyOwner {
        require(address(treasury) != _treasury, "ROI: Treasury is already this address");
        if (address(treasury) != address(0)) updatePermission(address(treasury), false);
        updatePermission(_treasury, true);
        emit UpdatedTreasury(_treasury, address(treasury));
        treasury = ITreasury(_treasury);
    }

    function updateUCD(address _ucd) external onlyOwner {
        require(address(UCD) != _ucd, "ROI: UCD is already this address");
        UCD = IERC20(_ucd);
    }

    function updateStabl3Staking(address _stabl3Staking) external onlyOwner {
        require(address(stabl3Staking) != _stabl3Staking, "ROI: Stabl3 Staking is already this address");
        if (address(stabl3Staking) != address(0)) updatePermission(address(stabl3Staking), false);
        updatePermission(_stabl3Staking, true);
        stabl3Staking = IStabl3Staking(_stabl3Staking);
    }

    function updateMaxPoolPercentage(uint256 _maxPoolPercentage) external onlyOwner {
        require(maxPoolPercentage != _maxPoolPercentage, "ROI: Max Pool Percentage is already this value");
        maxPoolPercentage = _maxPoolPercentage;
    }

    function updateReturnPools(uint8[] calldata _returnPools) external onlyOwner {
        returnPools = _returnPools;
    }

    function searchTimeWeightedAPR(uint256 _startTimeWeight, uint256 _endTimeWeight) external view returns (TimeWeightedAPR memory) {
        TimeWeightedAPR memory endTimeWeightedAPR;
        uint256 endAPR;

        for (uint256 i = _endTimeWeight ; i >= _startTimeWeight && i >= 0 ; i--) {
            if (getTimeWeightedAPRs[i].timeWeight != 0 || i == 0) {
                endTimeWeightedAPR.APR = getTimeWeightedAPRs[i].APR;
                endTimeWeightedAPR.timeWeight = i;

                endAPR = getAPRs[i];
                break;
            }
        }

        if (endTimeWeightedAPR.timeWeight != _endTimeWeight) {
            uint256 timeWeight = _endTimeWeight - endTimeWeightedAPR.timeWeight;

            endTimeWeightedAPR.APR += endAPR * timeWeight;
            endTimeWeightedAPR.timeWeight += timeWeight;
        }

        return endTimeWeightedAPR;
    }

    function updatePermission(address _contractAddress, bool _state) public onlyOwner {
        require(permitted[_contractAddress] != _state, "ROI: Contract Address is already this state");

        permitted[_contractAddress] = _state;

        if (_state) {
            delegateApprove(STABL3, _contractAddress, true);

            delegateApprove(UCD, _contractAddress, true);

            for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
                delegateApprove(treasury.allReservedTokens(i), _contractAddress, true);
            }
        }
        else {
            delegateApprove(STABL3, _contractAddress, false);

            delegateApprove(UCD, _contractAddress, false);

            for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
                delegateApprove(treasury.allReservedTokens(i), _contractAddress, false);
            }
        }

        emit UpdatedPermission(_contractAddress, _state);
    }

    function updatePermissionMultiple(address[] memory _contractAddresses, bool _state) public onlyOwner {
        for (uint256 i = 0 ; i < _contractAddresses.length ; i++) {
            updatePermission(_contractAddresses[i], _state);
        }
    }

    function getTotalRewardDistributed() public view returns (uint256) {
        uint256 totalRewardDistributed;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);

            if (treasury.isReservedToken(reservedToken)) {
                uint256 stakeRewardAmount = treasury.sumOfAllPools(STAKE_REWARD_POOL, reservedToken);
                uint256 lendRewardAmount = treasury.sumOfAllPools(LEND_REWARD_POOL, reservedToken);

                uint256 decimals = reservedToken.decimals();

                totalRewardDistributed +=
                    decimals < 18 ?
                    (stakeRewardAmount * (10 ** (18 - decimals))) + (lendRewardAmount * (10 ** (18 - decimals))) :
                    stakeRewardAmount + lendRewardAmount;
            }
        }

        return totalRewardDistributed;
    }

    function getReserves() public view returns (uint256) {
        uint256 totalReserves;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);

            if (treasury.isReservedToken(reservedToken)) {
                uint256 amountToken = reservedToken.balanceOf(address(this));

                uint256 decimals = reservedToken.decimals();

                totalReserves += decimals < 18 ? amountToken * (10 ** (18 - decimals)) : amountToken;
            }
        }

        totalReserves = totalReserves.add(stabl3Staking.withdrawnROIReserves()).safeSub(stabl3Staking.dormantROIReserves());

        return totalReserves;
    }

    // APR is in 18 decimals
    function getAPR() public view returns (uint256) {
        uint256 maxPool;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);

            if (treasury.isReservedToken(reservedToken)) {
                uint256 boughtAmount = treasury.getTreasuryPool(BUY_POOL, reservedToken);
                uint256 bondedAmount = treasury.getTreasuryPool(BOND_POOL, reservedToken);

                uint256 decimals = reservedToken.decimals();

                maxPool +=
                    decimals < 18 ?
                    (boughtAmount * (10 ** (18 - decimals))) + (bondedAmount * (10 ** (18 - decimals))) :
                    boughtAmount + bondedAmount;
            }
        }

        maxPool = maxPool.mul(maxPoolPercentage).div(1000);

        uint256 ROIReserves = getReserves();

        uint256 currentAPR = maxPool > 0 ? (ROIReserves * (10 ** 18)) / (maxPool) : 0;

        return currentAPR;
    }

    function validatePool(
        IERC20 _token,
        uint256 _amountToken,
        uint8 _stakingType,
        bool _isLending
    ) public view reserved(_token) returns (uint256 maxPool, uint256 currentPool) {
        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);

            if (treasury.isReservedToken(reservedToken)) {
                uint256 boughtAmount = treasury.getTreasuryPool(BUY_POOL, reservedToken);
                uint256 bondedAmount = treasury.getTreasuryPool(BOND_POOL, reservedToken);

                uint256 decimals = reservedToken.decimals();

                maxPool +=
                    decimals < 18 ?
                    (boughtAmount * (10 ** (18 - decimals))) + (bondedAmount * 10 ** (18 - decimals)) :
                    boughtAmount + bondedAmount;
            }
        }

        maxPool = maxPool.mul(maxPoolPercentage).div(1000);
        maxPool = maxPool.mul(stakingTypePercentage).div(1000);

        currentPool = treasury.getTreasuryPool(STAKING_TYPE_POOL + _stakingType, IERC20(address(0)));

        if (_isLending) {
            _amountToken = _amountToken.mul(1000 - stabl3Staking.lendingStabl3Percentage()).div(1000);
        }

        currentPool += _token.decimals() < 18 ? _amountToken * (10 ** (18 - _token.decimals())) : _amountToken;
    }

    function distributeReward(
        address _user,
        IERC20 _rewardToken,
        uint256 _amountRewardToken,
        uint8 _rewardPoolType
    ) external permission reserved(_rewardToken) {
        uint256 amountRewardTokenROI = _rewardToken.balanceOf(address(this));

        if (_amountRewardToken > amountRewardTokenROI) {
            if (amountRewardTokenROI != 0) {
                SafeERC20.safeTransfer(_rewardToken, _user, amountRewardTokenROI);

                _amountRewardToken -= amountRewardTokenROI;

                treasury.updatePool(_rewardPoolType, _rewardToken, 0, amountRewardTokenROI, 0, true);
            }

            uint256 decimalsRewardToken = _rewardToken.decimals();

            for (uint256 i = 0 ; i < treasury.allReservedTokensLength() && _amountRewardToken > 0 ; i++) {
                IERC20 reservedToken = treasury.allReservedTokens(i);

                if (
                    treasury.isReservedToken(reservedToken) &&
                    reservedToken != _rewardToken &&
                    _amountRewardToken != 0
                ) {
                    uint256 amountReservedTokenROI = reservedToken.balanceOf(address(this));

                    uint256 decimalsReservedToken = reservedToken.decimals();

                    uint256 amountRewardTokenConverted;
                    if (decimalsRewardToken > decimalsReservedToken) {
                        amountRewardTokenConverted = _amountRewardToken / (10 ** (decimalsRewardToken - decimalsReservedToken));
                    }
                    else if (decimalsRewardToken < decimalsReservedToken) {
                        amountRewardTokenConverted = _amountRewardToken * (10 ** (decimalsReservedToken - decimalsRewardToken));
                    }

                    if (amountRewardTokenConverted > amountReservedTokenROI) {
                        SafeERC20.safeTransfer(reservedToken, _user, amountReservedTokenROI);

                        treasury.updatePool(_rewardPoolType, reservedToken, 0, amountReservedTokenROI, 0, true);

                        if (decimalsRewardToken > decimalsReservedToken) {
                            _amountRewardToken -= amountReservedTokenROI * (10 ** (decimalsRewardToken - decimalsReservedToken));
                        }
                        else if (decimalsRewardToken < decimalsReservedToken) {
                            _amountRewardToken -= amountReservedTokenROI / (10 ** (decimalsReservedToken - decimalsRewardToken));
                        }
                    }
                    else {
                        SafeERC20.safeTransfer(reservedToken, _user, amountRewardTokenConverted);

                        treasury.updatePool(_rewardPoolType, reservedToken, 0, amountRewardTokenConverted, 0, true);

                        _amountRewardToken = 0;
                        break;
                    }
                }
            }
        }
        else {
            SafeERC20.safeTransfer(_rewardToken, _user, _amountRewardToken);

            treasury.updatePool(_rewardPoolType, _rewardToken, 0, _amountRewardToken, 0, true);
        }
    }

    function updateAPR() public permission {
        uint256 currentAPR = getAPR();

        uint256 reserves = getReserves();

        uint256 totalRewardDistributed = getTotalRewardDistributed();

        // Time Weighted APR Calculation
        uint256 timeWeight = (block.timestamp - updateTimestampLast) / oneDayTime;

        timeWeightedAPR.APR += updateAPRLast * timeWeight;
        timeWeightedAPR.timeWeight += timeWeight;

        updateAPRLast = currentAPR;
        updateTimestampLast += oneDayTime * timeWeight;

        getTimeWeightedAPRs[timeWeightedAPR.timeWeight].APR = timeWeightedAPR.APR;
        getTimeWeightedAPRs[timeWeightedAPR.timeWeight].timeWeight = timeWeightedAPR.timeWeight;
        getAPRs[timeWeightedAPR.timeWeight] = currentAPR;

        emit APR(currentAPR, reserves, totalRewardDistributed, block.timestamp);
    }

    /**
     * @dev Called when Treasury does not have enough funds
     * @dev Transfers funds from ROI to Treasury
     * @dev Updates values of both treasury and ROI pools
     */
    function returnFunds(IERC20 _token, uint256 _amountToken) external permission reserved(_token) {
        uint256 amountToUpdate = _amountToken;

        for (uint8 i = 0 ; i < returnPools.length ; i++) {
            uint256 amountPool = treasury.getROIPool(returnPools[i], _token);

            if (amountPool != 0) {
                if (amountPool < amountToUpdate) {
                    treasury.updatePool(returnPools[i], _token, 0, amountPool, 0, false);
                    treasury.updatePool(returnPools[i], _token, amountPool, 0, 0, true);

                    amountToUpdate -= amountPool;
                }
                else {
                    treasury.updatePool(returnPools[i], _token, 0, amountToUpdate, 0, false);
                    treasury.updatePool(returnPools[i], _token, amountToUpdate, 0, 0, true);

                    amountToUpdate = 0;
                    break;
                }
            }
        }

        require(amountToUpdate == 0, "ROI: Not enough funds in the specified pools");

        SafeERC20.safeTransfer(_token, address(treasury), _amountToken);
    }

    function delegateApprove(IERC20 _token, address _spender, bool _isApprove) public onlyOwner {
        if (_isApprove) {
            SafeERC20.safeApprove(_token, _spender, MAX_INT);
        }
        else {
            SafeERC20.safeApprove(_token, _spender, 0);
        }
    }

    // TODO remove
    // Testing only
    function testWithdrawAllFunds(IERC20 _token) external onlyOwner {
        SafeERC20.safeTransfer(_token, owner(), _token.balanceOf(address(this)));
    }

    // modifiers

    modifier permission() {
        require(permitted[msg.sender] || msg.sender == owner(), "ROI: Not permitted");
        _;
    }

    modifier reserved(IERC20 _token) {
        require(treasury.isReservedToken(_token), "ROI: Not a reserved token");
        _;
    }
}