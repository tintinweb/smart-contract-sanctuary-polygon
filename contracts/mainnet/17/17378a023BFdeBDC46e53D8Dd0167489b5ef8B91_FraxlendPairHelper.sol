// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= FraxlendPairCore =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IFraxlendPair.sol";
import "./interfaces/IRateCalculator.sol";

contract FraxlendPairHelper {
    error OracleLTEZero(address _oracle);

    struct ImmutablesAddressBool {
        bool _borrowerWhitelistActive;
        bool _lenderWhitelistActive;
        address _assetContract;
        address _collateralContract;
        address _oracleMultiply;
        address _oracleDivide;
        address _rateContract;
        address _DEPLOYER_CONTRACT;
        address _COMPTROLLER_ADDRESS;
        address _FRAXLEND_WHITELIST;
    }

    struct ImmutablesUint256 {
        uint256 _oracleNormalization;
        uint256 _maxLTV;
        uint256 _liquidationFee;
        uint256 _maturity;
        uint256 _penaltyRate;
    }

    struct CurrentRateInfo {
        uint16 lastBlock;
        uint16 feeToProtocolRate; // Fee amount 1e5 precision
        uint32 lastTimestamp;
        uint64 ratePerSec;
    }

    struct VaultAccount {
        uint128 amount; // Total amount, analogous to market cap
        uint128 shares; // Total shares, analogous to shares outstanding
    }

    function getImmutableAddressBool(address _fraxlendPairAddress)
        external
        view
        returns (ImmutablesAddressBool memory)
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        return
            ImmutablesAddressBool({
                _assetContract: _fraxlendPair.asset(),
                _collateralContract: _fraxlendPair.collateralContract(),
                _oracleMultiply: _fraxlendPair.oracleMultiply(),
                _oracleDivide: _fraxlendPair.oracleDivide(),
                _rateContract: _fraxlendPair.rateContract(),
                _DEPLOYER_CONTRACT: _fraxlendPair.DEPLOYER_ADDRESS(),
                _COMPTROLLER_ADDRESS: _fraxlendPair.COMPTROLLER_ADDRESS(),
                _FRAXLEND_WHITELIST: _fraxlendPair.FRAXLEND_WHITELIST_ADDRESS(),
                _borrowerWhitelistActive: _fraxlendPair.borrowerWhitelistActive(),
                _lenderWhitelistActive: _fraxlendPair.lenderWhitelistActive()
            });
    }

    function getImmutableUint256(address _fraxlendPairAddress) external view returns (ImmutablesUint256 memory) {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        return
            ImmutablesUint256({
                _oracleNormalization: _fraxlendPair.oracleNormalization(),
                _maxLTV: _fraxlendPair.maxLTV(),
                _liquidationFee: _fraxlendPair.liquidationFee(),
                _maturity: _fraxlendPair.maturity(),
                _penaltyRate: _fraxlendPair.penaltyRate()
            });
    }

    function getUserSnapshot(address _fraxlendPairAddress, address _address)
        external
        view
        returns (
            uint256 _userAssetShares,
            uint256 _userBorrowShares,
            uint256 _userCollateralBalance
        )
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        _userAssetShares = _fraxlendPair.balanceOf(_address);
        _userBorrowShares = _fraxlendPair.userBorrowShares(_address);
        _userCollateralBalance = _fraxlendPair.userCollateralBalance(_address);
    }

    function getPairAccounting(address _fraxlendPairAddress)
        external
        view
        returns (
            uint128 _totalAssetAmount,
            uint128 _totalAssetShares,
            uint128 _totalBorrowAmount,
            uint128 _totalBorrowShares,
            uint256 _totalCollateral
        )
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (_totalAssetAmount, _totalAssetShares) = _fraxlendPair.totalAsset();
        (_totalBorrowAmount, _totalBorrowShares) = _fraxlendPair.totalBorrow();
        _totalCollateral = _fraxlendPair.totalCollateral();
    }

    function previewUpdateExchangeRate(address _fraxlendPairAddress) external view returns (uint256 _exchangeRate) {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        address _oracleMultiply = _fraxlendPair.oracleMultiply();
        address _oracleDivide = _fraxlendPair.oracleDivide();
        uint256 _oracleNormalization = _fraxlendPair.oracleNormalization();

        uint256 _price = uint256(1e36);
        if (_oracleMultiply != address(0)) {
            (, int256 _answer, , , ) = AggregatorV3Interface(_oracleMultiply).latestRoundData();
            if (_answer <= 0) {
                revert OracleLTEZero(_oracleMultiply);
            }
            _price = _price * uint256(_answer);
        }

        if (_oracleDivide != address(0)) {
            (, int256 _answer, , , ) = AggregatorV3Interface(_oracleDivide).latestRoundData();
            if (_answer <= 0) {
                revert OracleLTEZero(_oracleDivide);
            }
            _price = _price / uint256(_answer);
        }

        _exchangeRate = _price / _oracleNormalization;
    }

    function _isPastMaturity(uint256 _maturity, uint256 _timestamp) internal pure returns (bool) {
        return _maturity != 0 && _timestamp > _maturity;
    }

    function previewRateInterest(
        address _fraxlendPairAddress,
        uint256 _timestamp,
        uint256 _blockNumber
    )
        public
        view
        returns (
            uint256 _interestEarned,
            uint256 _newRate
        )
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (, , uint256 _UTIL_PREC, , , uint64 _DEFAULT_INT, , ) = _fraxlendPair.getConstants();

        // Add interest only once per block
        CurrentRateInfo memory _currentRateInfo;
        {
            (uint16 lastBlock, uint16 feeToProtocolRate, uint32 lastTimestamp, uint64 ratePerSec) = _fraxlendPair
                .currentRateInfo();
            _currentRateInfo = CurrentRateInfo({
                lastBlock: lastBlock,
                feeToProtocolRate: feeToProtocolRate,
                lastTimestamp: lastTimestamp,
                ratePerSec: ratePerSec
            });
        }

        // Pull some data from storage to save gas
        VaultAccount memory _totalAsset;
        VaultAccount memory _totalBorrow;
        {
            (uint128 _totalAssetAmount, uint128 _totalAssetShares) = _fraxlendPair.totalAsset();
            _totalAsset = VaultAccount({ amount: _totalAssetAmount, shares: _totalAssetShares });
            (uint128 _totalBorrowAmount, uint128 _totalBorrowShares) = _fraxlendPair.totalBorrow();
            _totalBorrow = VaultAccount({ amount: _totalBorrowAmount, shares: _totalBorrowShares });
        }

        // If there are no borrows, no interest accrues
        if (_totalBorrow.shares == 0 || _fraxlendPair.paused()) {
            if (!_fraxlendPair.paused()) {
                _currentRateInfo.ratePerSec = _DEFAULT_INT;
            }
            // _currentRateInfo.lastTimestamp = uint32(_timestamp);
            // _currentRateInfo.lastBlock = uint16(_blockNumber);
        } else {
            // NOTE: Violates Checks-Effects-Interactions pattern
            // Be sure to mark external version NONREENTRANT (even though rateContract is trusted)
            // Calc new rate
            if (_isPastMaturity(_fraxlendPair.maturity(), _timestamp)) {
                _newRate = uint64(_fraxlendPair.penaltyRate());
            } else {
                _newRate = IRateCalculator(_fraxlendPair.rateContract()).getNewRate(
                    abi.encode(
                        _currentRateInfo.ratePerSec,
                        _timestamp - _currentRateInfo.lastTimestamp,
                        (_totalBorrow.amount * _UTIL_PREC) / _totalAsset.amount,
                        _blockNumber - _currentRateInfo.lastBlock
                    ),
                    _fraxlendPair.rateInitCallData()
                );
            }

            // Calculate interest accrued
            _interestEarned =
                (_totalBorrow.amount * _currentRateInfo.ratePerSec * _timestamp - _currentRateInfo.lastTimestamp) /
                1e18;
        }
    }

    function previewRateInterestFees(
        address _fraxlendPairAddress,
        uint256 _timestamp,
        uint256 _blockNumber
    )
        external
        view
        returns (
            uint256 _interestEarned,
            uint256 _feesAmount,
            uint256 _feesShare,
            uint256 _newRate
        )
    {
        (_interestEarned, _newRate) = previewRateInterest(_fraxlendPairAddress, _timestamp, _blockNumber);
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (, uint16 _feeToProtocolRate, , ) = _fraxlendPair.currentRateInfo();
        (, , , uint256 _FEE_PRECISION, , , , ) = _fraxlendPair.getConstants();
        (uint128 _totalAssetAmount, uint128 _totalAssetShares) = _fraxlendPair.totalAsset();
        if (_feeToProtocolRate > 0) {
            _feesAmount = (_interestEarned * _feeToProtocolRate) / _FEE_PRECISION;
            _feesShare = (_feesAmount * _totalAssetShares) / (_totalAssetAmount - _feesAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.15;

interface IFraxlendPair {
    function CIRCUIT_BREAKER_ADDRESS() external view returns (address);

    function COMPTROLLER_ADDRESS() external view returns (address);

    function DEPLOYER_ADDRESS() external view returns (address);

    function FRAXLEND_WHITELIST_ADDRESS() external view returns (address);

    function addCollateral(uint256 _collateralAmount, address _borrower) external;

    function addInterest() external returns (uint256 _interestEarned);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function approvedBorrowers(address) external view returns (bool);

    function approvedLenders(address) external view returns (bool);

    function asset() external view returns (address);

    function assetsOf(address _depositor) external view returns (uint256 _assets);

    function assetsPerShare() external view returns (uint256 _assetsPerUnitShare);

    function balanceOf(address account) external view returns (uint256);

    function borrowAsset(
        uint256 _borrowAmount,
        uint256 _collateralAmount,
        address _receiver
    ) external returns (uint256 _shares);

    function borrowerWhitelistActive() external view returns (bool);

    function changeFee(uint16 _newFee) external;

    function collateralContract() external view returns (address);

    function convertToAssets(uint256 _shares) external view returns (uint256);

    function convertToShares(uint256 _amount) external view returns (uint256);

    function currentRateInfo()
        external
        view
        returns (
            uint16 lastBlock,
            uint16 feeToProtocolRate,
            uint32 lastTimestamp,
            uint64 ratePerSec
        );

    function decimals() external pure returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 _amount, address _receiver) external returns (uint256 _sharesReceived);

    function exchangeRateInfo() external view returns (uint32 lastTimestamp, uint224 exchangeRate);

    function getConstants()
        external
        pure
        returns (
            uint256 _LTV_PRECISION,
            uint256 _LIQ_PRECISION,
            uint256 _UTIL_PREC,
            uint256 _FEE_PRECISION,
            uint256 _EXCHANGE_PRECISION,
            uint64 _DEFAULT_INT,
            uint16 _DEFAULT_PROTOCOL_FEE,
            uint256 _MAX_PROTOCOL_FEE
        );

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function initialize(
        string calldata _name,
        address[] calldata _approvedBorrowers,
        address[] calldata _approvedLenders,
        bytes calldata _rateInitCallData
    ) external;

    function lenderWhitelistActive() external view returns (bool);

    function leveragedPosition(
        address _swapperAddress,
        uint256 _borrowAmount,
        uint256 _initialCollateralAmount,
        uint256 _amountCollateralOutMin,
        address[] calldata _path
    ) external returns (uint256 _totalCollateralBalance);

    function liquidate(uint256 _shares, address _borrower) external returns (uint256 _collateralForLiquidator);

    function liquidationFee() external view returns (uint256);

    function maturity() external view returns (uint256);

    function maxDeposit(address) external pure returns (uint256);

    function maxLTV() external view returns (uint256);

    function maxMint(address) external pure returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function mint(uint256 _shares, address _receiver) external returns (uint256 _amountReceived);

    function name() external view returns (string calldata);

    function oracleDivide() external view returns (address);

    function oracleMultiply() external view returns (address);

    function oracleNormalization() external view returns (uint256);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function penaltyRate() external view returns (uint256);

    function previewDeposit(uint256 _amount) external view returns (uint256);

    function previewMint(uint256 _shares) external view returns (uint256);

    function previewRedeem(uint256 _shares) external view returns (uint256);

    function previewWithdraw(uint256 _amount) external view returns (uint256);

    function rateContract() external view returns (address);

    function rateInitCallData() external view returns (bytes calldata);

    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256 _amountToReturn);

    function removeCollateral(uint256 _collateralAmount, address _receiver) external;

    function renounceOwnership() external;

    function repayAsset(uint256 _shares, address _borrower) external returns (uint256 _amountToRepay);

    function repayAssetWithCollateral(
        address _swapperAddress,
        uint256 _collateralToSwap,
        uint256 _amountAssetOutMin,
        address[] calldata _path
    ) external returns (uint256 _amountAssetOut);

    function setApprovedBorrowers(address[] calldata _borrowers, bool _approval) external;

    function setApprovedLenders(address[] calldata _lenders, bool _approval) external;

    function setSwapper(address _swapper, bool _approval) external;

    function swappers(address) external view returns (bool);

    function symbol() external view returns (string calldata);

    function totalAsset() external view returns (uint128 amount, uint128 shares);

    function totalAssets() external view returns (uint256);

    function totalBorrow() external view returns (uint128 amount, uint128 shares);

    function totalCollateral() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function updateExchangeRate() external returns (uint256 _exchangeRate);

    function userBorrowShares(address) external view returns (uint256);

    function userCollateralBalance(address) external view returns (uint256);

    function version() external view returns (string calldata);

    function withdraw(
        uint256 _amount,
        address _receiver,
        address _owner
    ) external returns (uint256 _shares);

    function withdrawFees(uint128 _shares, address _recipient) external returns (uint256 _amountToTransfer);
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.15;

interface IRateCalculator {
    function name() external pure returns (string memory);

    function requireValidInitData(bytes calldata _initData) external pure;

    function getConstants() external pure returns (bytes memory _calldata);

    function getNewRate(bytes calldata _data, bytes calldata _initData) external pure returns (uint64 _newRatePerSec);
}