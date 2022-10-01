//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import ".././interfaces/HTokenI.sol";
import "../utils/ErrorReporter.sol";
import "../interfaces/PriceOracleI.sol";
import "../interfaces/HivemindI.sol";
import "../hivemind/HivemindStorage.sol";

/**
 * @title Honey Protocol Hivemind
 * @notice Hivemind can be interpreted as the brain of the Honey Protocol, is the one who decides:
 * - who can borrow and how much it can borrow
 * - who can redeem and how much it can redeem
 * - who can transfer their hTokens
 * - enables different markets to be traded
 * @author Honey Finance Labs
 * @custom:coauthor m4rio
 * @custom:contributor BowTiedPickle
 */
contract Hivemind is HivemindStorage, HivemindI, ErrorReporter, AccessControlEnumerable, ReentrancyGuard {
  /// @notice version of this contract
  string public constant version = "v0.3";

  bytes32 public constant FACTORY = keccak256("FACTORY");
  bytes32 public constant PAUSABLE = keccak256("PAUSABLE");

  /// @notice Emitted when an admin supports a market
  event MarketListed(HTokenI indexed _hToken);

  /// @notice Emitted when an account enters a market
  event MarketEntered(HTokenI indexed _hToken, address _account);

  /// @notice Emitted when an account exits a market
  event MarketExited(HTokenI indexed _hToken, address _account);

  /// @notice Emitted when close factor is changed by admin
  event NewCloseFactor(uint256 _oldCloseFactorMantissa, uint256 _newCloseFactorMantissa);

  /// @notice Emitted when threshold is changed by the admin
  event ThresholdUpdated(uint256 _oldThreshold, uint256 _newThreshold);

  /// @notice Emitted when a collateral factor is changed by admin
  event NewCollateralFactor(HTokenI indexed _hToken, uint256 _oldCollateralFactorMantissa, uint256 _newCollateralFactorMantissa);

  /// @notice Emitted when price oracle is changed
  event NewPriceOracle(PriceOracleI _oldPriceOracle, PriceOracleI _newPriceOracle);

  /// @notice Emitted when an action is paused on a market
  event ActionPausedhToken(HTokenI indexed _hToken, string _action, bool _pauseState);

  /// @notice Emitted when borrow cap for a hToken is changed
  event NewBorrowCap(HTokenI indexed _hToken, uint256 _newBorrowCap);

  /// @notice Emitted when borrow cap guardian is changed
  event NewBorrowCapGuardian(address _oldBorrowCapGuardian, address _newBorrowCapGuardian);

  /// @notice Emitted when the cap for markets in per account is changed
  event MarketsInCapChanged(uint256 _oldCap, uint256 _newCap);

  // No collateralFactorMantissa may exceed this value
  uint256 internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

  uint256 private updateThreshold = 1 days;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(FACTORY, msg.sender);
  }

  /*** Public ***/

  /**
   * @notice Add assets to be included in account liquidity calculation
   * @param _hTokens The list of addresses of the hToken markets to be enabled
   */
  function enterMarkets(HTokenI[] calldata _hTokens) external override nonReentrant {
    uint256 len = _hTokens.length;

    for (uint256 i; i < len; ) {
      HTokenI hToken = _hTokens[i];
      addToMarketInternal(hToken, msg.sender);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Removes asset from sender's account liquidity calculation
   * @dev Sender must not have an outstanding borrow balance in the asset,
   *  or be providing necessary collateral for an outstanding borrow.
   * @param _hToken The address of the asset to be removed
   */
  function exitMarket(HTokenI _hToken) external override nonReentrant {
    /* Get sender tokensHeld and amountOwed underlying from the hToken */
    (uint256 tokensHeld, uint256 amountOwed, ) = _hToken.getAccountSnapshot(msg.sender);

    /* Fail if the sender has a borrow balance */
    if (amountOwed != 0) {
      revert HivemindError(Error.NONZERO_BORROW_BALANCE);
    }
    /* Fail if the sender is not permitted to redeem all of their tokens */
    redeemAllowed(_hToken, msg.sender, tokensHeld);

    Market storage marketToExit = markets[_hToken];

    /* Return true if the sender is not already ‘in’ the market */
    if (!marketToExit.accountMembership[msg.sender]) {
      return;
    }

    /* Set hToken account membership to false */
    delete marketToExit.accountMembership[msg.sender];

    /* Delete hToken from the account’s list of assets */
    HTokenI[] storage userAssetList = accountMarkets[msg.sender];
    uint256 len = userAssetList.length;
    uint256 assetIndex = len;

    for (uint256 i; i < len; ) {
      if (userAssetList[i] == _hToken) {
        assetIndex = i;
        break;
      }
      unchecked {
        ++i;
      }
    }

    // We *must* have found the asset in the list or our redundant data structure is broken
    assert(assetIndex < len);

    // copy last item in list to location of item to be removed, reduce length by 1
    userAssetList[assetIndex] = userAssetList[len - 1];
    userAssetList.pop();

    emit MarketExited(_hToken, msg.sender);
  }

  /**
   * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
   * @param _hToken The market to verify the borrow against
   * @param _borrower The account which would borrow the asset
   * @param _collateralId collateral Id, aka the NFT token Id
   * @param _borrowAmount The amount of underlying the account would borrow
   */
  function borrowAllowed(
    HTokenI _hToken,
    address _borrower,
    uint256 _collateralId,
    uint256 _borrowAmount
  ) external override nonReentrant {
    // Pausing is a very serious situation - we revert to sound the alarms
    if (marketPausedInfo[_hToken].borrowPaused) revert Paused();

    Market storage market = markets[_hToken];
    if (!market.isListed) {
      revert MarketError(Error.MARKET_NOT_LISTED);
    }

    if (!market.accountMembership[_borrower]) {
      // only hTokens may call borrowAllowed if borrower not in market
      if (msg.sender != address(_hToken)) revert WrongParams();

      // attempt to add borrower to the market
      addToMarketInternal(_hToken, _borrower);

      // it should be impossible to break the important invariant
      assert(market.accountMembership[_borrower]);
    }

    uint256 borrowCap = borrowCaps[_hToken];

    // Borrow cap of 0 corresponds to unlimited borrowing
    if (borrowCap != 0) {
      uint256 nextTotalBorrows = HTokenI(_hToken).totalBorrows() + _borrowAmount;
      if (nextTotalBorrows >= borrowCap) revert MarketError(Error.MARKET_CAP_BORROW_REACHED);
    }

    (, uint256 shortfall) = getHypotheticalAccountLiquidityBorrowInternal(_hToken, _collateralId, _borrowAmount);

    if (shortfall > 0) {
      revert HivemindError(Error.INSUFFICIENT_LIQUIDITY);
    }
  }

  function liquidationAllowed(HTokenI _hToken, uint256 _collateralId) external view override {
    // Pausing is a very serious situation - we revert to sound the alarms
    if (marketPausedInfo[_hToken].liquidationPaused) revert Paused();

    if (!markets[_hToken].isListed) {
      revert MarketError(Error.MARKET_NOT_LISTED);
    }

    (, uint256 shortfall) = getHypotheticalAccountLiquidityBorrowInternal(_hToken, _collateralId, 0);

    if (shortfall == 0) revert HivemindError(Error.LIQUIDATION_NOT_ALLOWED);
  }

  /*** Internal ***/

  /**
   * @notice Add the market to the borrower's "assets in" for liquidity calculations
   * @param _hToken The market to enter
   * @param _borrower The address of the account to modify
   */
  function addToMarketInternal(HTokenI _hToken, address _borrower) internal {
    Market storage marketToJoin = markets[_hToken];

    if (!marketToJoin.isListed) {
      // market is not listed, cannot join
      revert MarketError(Error.MARKET_NOT_LISTED);
    }

    if (marketToJoin.accountMembership[_borrower]) {
      // already joined
      return;
    }

    if (accountMarkets[_borrower].length == marketsInCap) revert HivemindError(Error.MAX_MARKETS_IN);

    // survived the gauntlet, add to list
    // NOTE: we store these somewhat redundantly as a significant optimization
    //  this avoids having to iterate through the list for the most common use cases
    //  that is, only when we need to perform liquidity checks
    //  and not whenever we want to check if an account is in a particular market
    marketToJoin.accountMembership[_borrower] = true;
    accountMarkets[_borrower].push(_hToken);

    emit MarketEntered(_hToken, _borrower);
  }

  /**
   * @notice adds a market (hToken), reverts if market already exists
   * @param _hToken the market to add
   */
  function addMarketInternal(HTokenI _hToken) internal {
    uint256 len = allMarkets.length;
    for (uint256 i; i < len; ) {
      if (allMarkets[i] == _hToken) revert MarketError(Error.MARKET_ALREADY_LISTED);
      unchecked {
        ++i;
      }
    }
    allMarkets.push(_hToken);
  }

  function getCollateralPriceInUnderlyingPrice(HTokenI _hToken) internal view returns (uint256) {
    PriceOracleI cachedOracle = oracle;
    uint8 decimals = _hToken.decimals();
    (uint128 nftPriceInETH, uint128 lastUpdated) = cachedOracle.getUnderlyingFloorNFTPrice(address(_hToken.collateralToken()), decimals);

    if (lastUpdated < block.timestamp && block.timestamp - lastUpdated > updateThreshold) revert OracleNotUpdated();
    // TODO check this
    uint256 underlyingPriceInUSD = uint256(cachedOracle.getUnderlyingPriceInUSD(_hToken.underlyingToken(), decimals));
    uint256 ethPrice = uint256(cachedOracle.getEthPrice(decimals));
    return (nftPriceInETH * ethPrice) / underlyingPriceInUSD;
  }

  /*** Views  ***/

  /**
   * @notice Checks if the account should be allowed to redeem tokens in the given market
   * @param _hToken The market to verify the redeem against
   * @param _redeemer The account which would redeem the tokens
   * @param _redeemTokens The number of hTokens to exchange for the underlying asset in the market
   */
  function redeemAllowed(
    HTokenI _hToken,
    address _redeemer,
    uint256 _redeemTokens
  ) public view override {
    if (marketPausedInfo[_hToken].redeemPaused) revert Paused();

    Market storage market = markets[_hToken];

    if (!market.isListed) {
      revert MarketError(Error.MARKET_NOT_LISTED);
    }
    // If the redeemer is not 'in' the market, then we can bypass the liquidity check
    if (!market.accountMembership[_redeemer]) {
      return;
    }
    // Otherwise, perform a hypothetical liquidity check to guard against shortfall, we don't do this YET
    // (, uint256 shortfall) = getHypotheticalAccountLiquidityRedeemInternal(_redeemer, _hToken, _redeemTokens);
    // if (shortfall > 0) {
    //   revert HivemindError(Error.INSUFFICIENT_LIQUIDITY);
    // }
  }

  /**
   * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
   * @param _hToken The market to hypothetically redeem/borrow in
   * @param _account The account to determine liquidity for
   * @param _redeemTokens The number of tokens to hypothetically redeem
   * @param _borrowAmount The amount of underlying to hypothetically borrow
   * @param _collateralId collateral Id, aka the NFT token Id
   * @return liquidity - hypothetical account liquidity in excess of collateral requirements
   * @return shortfall - hypothetical account shortfall below collateral requirements
   */
  function getHypotheticalAccountLiquidity(
    HTokenI _hToken,
    address _account,
    uint256 _collateralId,
    uint256 _redeemTokens,
    uint256 _borrowAmount
  ) external view override returns (uint256 liquidity, uint256 shortfall) {
    if (_redeemTokens > 0) (liquidity, shortfall) = getHypotheticalAccountLiquidityRedeemInternal(_hToken, _account, _redeemTokens);
    else (liquidity, shortfall) = getHypotheticalAccountLiquidityBorrowInternal(_hToken, _collateralId, _borrowAmount);
  }

  /**
   * @notice Returns the assets an account has entered
   * @param _account The address of the account to pull assets for
   * @return A dynamic list with the assets the account has entered
   */
  function getAssetsIn(address _account) external view override returns (HTokenI[] memory) {
    return accountMarkets[_account];
  }

  /**
   * @notice Returns whether the given account is entered in the given asset
   * @param _hToken The hToken to check
   * @param _account The address of the account to check
   * @return True if the account is in the asset, otherwise false.
   */
  function checkMembership(HTokenI _hToken, address _account) external view override returns (bool) {
    return markets[_hToken].accountMembership[_account];
  }

  /**
   * @notice Checks if the account should be allowed to transfer tokens in the given market
   * @param _hToken The market to verify the transfer against
   */
  function transferAllowed(HTokenI _hToken) external view override {
    // Pausing is a very serious situation - we revert to sound the alarms
    if (marketPausedInfo[_hToken].transferPaused) revert Paused();
  }

  /**
   * @notice Checks if the account should be allowed to repay a borrow in the given market
   * @param _hToken The market to verify the repay against
   * @param _repayAmount The amount of the underlying asset the account would repay
   * @param _collateralId collateral Id, aka the NFT token Id
   */
  function repayBorrowAllowed(
    HTokenI _hToken,
    uint256 _repayAmount,
    uint256 _collateralId
  ) external view override {
    if (!markets[_hToken].isListed) {
      revert MarketError(Error.MARKET_NOT_LISTED);
    }
  }

  /**
   * @notice checks if withdrawal are allowed for this token id
   * @param _hToken The market to verify the withdrawal from
   * @param _collateralId what to pay for
   */
  function withdrawalCollateralAllowed(HTokenI _hToken, uint256 _collateralId) external view override {
    if (!markets[_hToken].isListed) {
      revert MarketError(Error.MARKET_NOT_LISTED);
    }
    if (_hToken.getBorrowAmountForCollateral(_collateralId) != 0) revert HivemindError(Error.WITHDRAW_NOT_ALLOWED);
  }

  /**
   * @notice Return the length of all markets
   * @return the length
   */
  function getAllMarketsLength() external view override returns (uint256) {
    return allMarkets.length;
  }

  /**
   * @notice checks if a market exists and it's listed
   * @param _hToken the market we check to see if it exists
   * @return bool true or false
   */
  function marketExists(HTokenI _hToken) external view override returns (bool) {
    return markets[_hToken].isListed;
  }

  /**
   * @notice returns the collateral factor for a given market
   * @param _hToken the market we want the market of
   * @return collateral factor in 1e18
   */
  function getCollateralFactor(HTokenI _hToken) external view override returns (uint256) {
    return markets[_hToken].collateralFactorMantissa;
  }

  /**
   * @notice Determine what the account liquidity would be if the given amounts were redeemed
   * @param _hToken The market to hypothetically redeem/borrow in
   * @param _account The account to determine liquidity for
   * @param _redeemTokens The number of tokens to hypothetically redeem
   * @dev Note that we calculate the exchangeRateStored for each collateral hToken using stored data,
   *  without calculating accumulated interest. Also not used for now
   * @return liquidity - hypothetical account liquidity in excess of collateral requirements
   * @return shortfall - hypothetical account shortfall below collateral requirements
   */
  function getHypotheticalAccountLiquidityRedeemInternal(
    HTokenI _hToken,
    address _account,
    uint256 _redeemTokens
  ) internal view returns (uint256 liquidity, uint256 shortfall) {
    // For each asset the account is in
    uint256 sumCollateral;
    uint256 sumBorrowPlusEffects;
    uint256 len = accountMarkets[_account].length;

    // Caching external calls to save gas
    uint8 decimals = _hToken.decimals();
    uint256 oraclePriceMantissa = getCollateralPriceInUnderlyingPrice(_hToken);

    // Get the normalized price of the asset
    if (oraclePriceMantissa == 0) {
      revert HivemindError(Error.PRICE_ERROR);
    }

    for (uint256 i; i < len; ) {
      // Couldn't store accountMarkets[_account]'s pointer storage due to stackTooDeepError.
      HTokenI asset = accountMarkets[_account][i];

      // Read the balances and exchange rate from the _hToken
      (uint256 hTokenBalance, uint256 borrowBalance, uint256 exchangeRateMantissa) = asset.getAccountSnapshot(_account);

      // Pre-compute a conversion factor from tokens -> ether (normalized price value)
      uint256 tokensToDenom = (markets[asset].collateralFactorMantissa * exchangeRateMantissa) / 1e18;

      // sumCollateral += tokensToDenom * hTokenBalance
      sumCollateral += (tokensToDenom * hTokenBalance) / 10**decimals;

      // sumBorrowPlusEffects += oraclePrice * borrowBalance
      sumBorrowPlusEffects += (oraclePriceMantissa * borrowBalance) / 10**decimals;

      // Calculate effects of interacting with _hToken
      if (asset == _hToken) {
        // redeem effect
        // sumBorrowPlusEffects += tokensToDenom * redeemTokens
        sumBorrowPlusEffects += (tokensToDenom * _redeemTokens) / 10**decimals;

        // borrow effect
        // sumBorrowPlusEffects += oraclePrice * borrowAmount
        sumBorrowPlusEffects += oraclePriceMantissa * sumBorrowPlusEffects;
      }

      unchecked {
        ++i;
      }
    }

    // These are safe, as the underflow condition is checked first
    unchecked {
      if (sumCollateral > sumBorrowPlusEffects) {
        liquidity = sumCollateral - sumBorrowPlusEffects;
      } else {
        shortfall = sumBorrowPlusEffects - sumCollateral;
      }
    }
  }

  /**
   * @notice Determine what the account liquidity would be if the given amounts were borrowed
   * @param _hToken The market to hypothetically redeem/borrow in
   * @param _collateralId collateral Id, aka the NFT token Id
   * @param _borrowAmount The amount of underlying to hypothetically borrow
   * @dev Note that we calculate the exchangeRateStored for each collateral hToken using stored data,
   *  without calculating accumulated interest.
   * @return liquidity - hypothetical account liquidity in excess of collateral requirements
   * @return shortfall - hypothetical account shortfall below collateral requirements
   */
  function getHypotheticalAccountLiquidityBorrowInternal(
    HTokenI _hToken,
    uint256 _collateralId,
    uint256 _borrowAmount
  ) internal view returns (uint256 liquidity, uint256 shortfall) {
    uint256 sumCollateral = getCollateralPriceInUnderlyingPrice(_hToken);

    // Read the balances and exchange rate from the hToken
    uint256 borrowBalance = _hToken.getBorrowAmountForCollateral(_collateralId);

    if (sumCollateral == 0) {
      revert HivemindError(Error.PRICE_ERROR);
    }
    uint256 sumBorrowPlusEffects = borrowBalance + _borrowAmount;

    // computing collateral factor applied on the collateral total amount
    // collateral factor % from the NFT price
    sumCollateral = (markets[_hToken].collateralFactorMantissa * sumCollateral) / 1e18;
    unchecked {
      if (sumCollateral > sumBorrowPlusEffects) {
        liquidity = sumCollateral - sumBorrowPlusEffects;
      } else {
        shortfall = sumBorrowPlusEffects - sumCollateral;
      }
    }
  }

  /*** Admin Functions ***/

  /**
   * @notice Sets a new price oracle for the comptroller
   * @dev Admin function to set a new price oracle
   */
  function _setPriceOracle(PriceOracleI _newOracle) external {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Unauthorized();
    emit NewPriceOracle(oracle, _newOracle);

    oracle = _newOracle;
  }

  /**
   * @notice Sets the closeFactor used when liquidating borrows
   * @dev Admin function to set closeFactor
   * @param _newCloseFactorMantissa New close factor, scaled by 1e18
   */
  function _setCloseFactor(uint256 _newCloseFactorMantissa) external {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Unauthorized();

    emit NewCloseFactor(closeFactorMantissa, _newCloseFactorMantissa);
    closeFactorMantissa = _newCloseFactorMantissa;
  }

  /**
   * @notice Sets the collateralFactor for a market
   * @dev Admin function to set per-market collateralFactor
   * @param _hToken The market to set the factor on
   * @param _newCollateralFactorMantissa The new collateral factor, scaled by hToken decimals
   */
  function _setCollateralFactor(HTokenI _hToken, uint256 _newCollateralFactorMantissa) external {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(FACTORY, msg.sender)) revert Unauthorized();

    // Verify market is listed
    Market storage market = markets[_hToken];
    if (!market.isListed) {
      revert MarketError(Error.MARKET_NOT_LISTED);
    }

    // Check collateral factor <= 0.9
    if (collateralFactorMaxMantissa < _newCollateralFactorMantissa) {
      revert HivemindError(Error.INVALID_COLLATERAL_FACTOR);
    }

    // Caching external call to save gas
    uint8 decimals = _hToken.decimals();

    PriceOracleI cachedOracle = oracle;
    (uint128 oraclePrice, ) = cachedOracle.getUnderlyingFloorNFTPrice(address(_hToken.collateralToken()), decimals);
    // If collateral factor != 0, fail if price == 0
    if (
      _newCollateralFactorMantissa != 0 &&
      (cachedOracle.getUnderlyingPriceInUSD(_hToken.underlyingToken(), decimals) == 0 || oraclePrice == 0)
    ) {
      revert MarketError(Error.MARKET_NOT_LISTED);
    }

    // Emit event with asset, old collateral factor, and new collateral factor
    emit NewCollateralFactor(_hToken, market.collateralFactorMantissa, _newCollateralFactorMantissa);

    // Set market's collateral factor to new collateral factor, remember old value
    market.collateralFactorMantissa = _newCollateralFactorMantissa;
  }

  /**
   * @notice Add the market to the markets mapping and set it as listed
   * @dev Admin function to set isListed and add support for the market
   * @param _hToken The address of the market (token) to list
   */
  function _supportMarket(HTokenI _hToken) external {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(FACTORY, msg.sender)) revert Unauthorized();

    Market storage market = markets[_hToken];

    if (market.isListed) {
      revert MarketError(Error.MARKET_ALREADY_LISTED);
    }

    if (!_hToken.supportsInterface(type(HTokenI).interfaceId)) revert WrongParams();

    market.isListed = true;
    market.collateralFactorMantissa = 0;

    addMarketInternal(_hToken);

    emit MarketListed(_hToken);
  }

  /**
   * @notice Set the given borrow caps for the given hToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
   * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
   * @param _hTokens The addresses of the markets (tokens) to change the borrow caps for
   * @param _newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
   */
  function _setMarketBorrowCaps(HTokenI[] calldata _hTokens, uint256[] calldata _newBorrowCaps) external {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Unauthorized();

    uint256 numMarkets = _hTokens.length;
    uint256 numBorrowCaps = _newBorrowCaps.length;

    if (numMarkets == 0 || numMarkets != numBorrowCaps) revert WrongParams();

    for (uint256 i; i < numMarkets; ) {
      borrowCaps[_hTokens[i]] = _newBorrowCaps[i];
      emit NewBorrowCap(_hTokens[i], _newBorrowCaps[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Set the max assets per account
   * @param _newCap The addresses of the markets (tokens) to change the borrow caps for
   */
  function _setMarketsInCap(uint256 _newCap) external {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Unauthorized();

    emit MarketsInCapChanged(marketsInCap, _newCap);
    marketsInCap = _newCap;
  }

  /**
   * @notice pauses the borrows, transfers or redeems
   * @param _hToken market (hToken) to pause the component
   * @param _state true or false
   * @param _target what component we should pause
   */
  function _pauseComponent(
    HTokenI _hToken,
    bool _state,
    uint256 _target
  ) external {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(PAUSABLE, msg.sender)) revert Unauthorized();

    if (_target == 0) {
      if (!markets[_hToken].isListed) revert MarketError(Error.MARKET_NOT_LISTED);
      marketPausedInfo[_hToken].borrowPaused = _state;
      emit ActionPausedhToken(_hToken, "Borrow", _state);
    } else if (_target == 1) {
      marketPausedInfo[_hToken].transferPaused = _state;
      emit ActionPausedhToken(_hToken, "Transfer", _state);
    } else if (_target == 2) {
      marketPausedInfo[_hToken].redeemPaused = _state;
      emit ActionPausedhToken(_hToken, "Redeem", _state);
    } else if (_target == 3) {
      marketPausedInfo[_hToken].liquidationPaused = _state;
      emit ActionPausedhToken(_hToken, "Liquidation", _state);
    }
  }

  /**
   * @notice Sets the threshold of checking last update on the oracle side
   * @dev Admin function to set updateThreshold
   * @param _newThreshold New threshold
   */
  function _setUpdateThreshold(uint256 _newThreshold) external {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Unauthorized();

    emit NewCloseFactor(updateThreshold, _newThreshold);
    updateThreshold = _newThreshold;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 _interfaceId) public pure override returns (bool) {
    return _interfaceId == type(AccessControlEnumerable).interfaceId || _interfaceId == type(HivemindI).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
import "./HTokenInternalI.sol";

/**
 * @title Interface of HToken
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
interface HTokenI is HTokenInternalI {
  // ----- Lend side functions -----

  /**
   * @notice Deposit underlying ERC-20 asset and mint hTokens
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _amount Quantity of underlying ERC-20 to transfer in
   */
  function depositUnderlying(uint256 _amount) external;

  /**
   * @notice Redeem a specified amount of hTokens for their underlying ERC-20 asset
   * @param _amount Quantity of hTokens to redeem for underlying ERC-20
   */
  function redeem(uint256 _amount) external;

  /**
   * @notice Withdraws the specified _amount of underlying ERC-20 asset, consuming the minimum amount of hTokens necessary
   * @param _amount Quantity of underlying ERC-20 tokens to withdraw
   */
  function withdraw(uint256 _amount) external;

  // ----- Borrow side functions -----

  /**
   * @notice Deposit a specified token of the underlying ERC-721 asset and mint an ERC-1155 deposit coupon NFT
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _collateralId Token ID of underlying ERC-721 to be transferred in
   */
  function depositCollateral(uint256 _collateralId) external;

  /**
   * @notice Deposit multiple specified tokens of the underlying ERC-721 asset and mint ERC-1155 deposit coupons NFT
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _collateralIds Token IDs of underlying ERC-721 to be transferred in
   */
  function depositMultiCollateral(uint256[] calldata _collateralIds) external;

  /**
   * @notice Sender borrows assets from the protocol against the specified collateral asset
   * @dev Collateral must be deposited first.
   * @param _borrowAmount Amount of underlying ERC-20 to borrow
   * @param _collateralId Token ID of underlying ERC-721 to be borrowed against
   */
  function borrow(uint256 _borrowAmount, uint256 _collateralId) external;

  /**
   * @notice Sender repays their own borrow taken against the specified collateral asset
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _repayAmount Amount of underlying ERC-20 to repay
   * @param _collateralId Token ID of underlying ERC-721 to be repaid against
   */
  function repayBorrow(uint256 _repayAmount, uint256 _collateralId) external;

  /**
   * @notice Sender repays another user's borrow taken against the specified collateral asset
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _borrower User whose borrow will be repaid
   * @param _repayAmount Amount of underlying ERC-20 to repay
   * @param _collateralId Token ID of underlying ERC-721 to be repaid against
   */
  function repayBorrowBehalf(
    address _borrower,
    uint256 _repayAmount,
    uint256 _collateralId
  ) external;

  /**
   * @notice Burn a deposit coupon NFT and withdraw the associated underlying ERC-721 NFT
   * @param _collateralId collateral Id, aka the NFT token Id
   */
  function withdrawCollateral(uint256 _collateralId) external;

  /**
   * @notice Burn multiple deposit coupons NFT and withdraw the associated underlying ERC-721 NFTs
   * @param _collateralIds collateral Ids, aka the NFT token Ids
   */
  function withdrawMultiCollateral(uint256[] calldata _collateralIds) external;

  /**
   * @notice Triggers transfer of an NFT to the liquidation contract
   * @param _collateralId collateral Id, aka the NFT token Id representing the borrow position to liquidate
   */
  function liquidateBorrow(uint256 _collateralId) external;

  /**
   * @notice Pay off the entirety of a borrow position and burn the coupon
   * @dev May only be called by the liquidator
   * @param _borrower borrower who pays
   * @param _collateralId what to pay for
   */
  function closeoutLiquidation(address _borrower, uint256 _collateralId) external;

  /**
   * @notice accrues interests to a selected set of coupons
   * @param _ids ids of coupons to accrue interest
   * @return all accrued interest
   */
  function accrueInterestToCoupons(uint256[] calldata _ids) external returns (uint256);

  // ----- Utility functions -----

  /**
   * @notice A public function to sweep accidental ERC-20 transfers to this contract.
   * @dev Tokens are sent to the dao for later distribution, we use transfer and not safeTransfer as this is admin only method
   * @param _token The address of the ERC-20 token to sweep
   */
  function sweepToken(IERC20 _token) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

error Unauthorized();
error AccrueInterestError(ErrorReporter.Error error);
error WrongParams();
error Unexpected(string error);
error InvalidCoupon();
error HivemindError(ErrorReporter.Error error);
error AdminError(ErrorReporter.Error error);
error MarketError(ErrorReporter.Error error);
error HTokenError(ErrorReporter.Error error);
error LiquidatorError(ErrorReporter.Error error);
error Paused();
error NotOwner();
error ExternalFailure(string error);
error Initialized();
error Uninitialized();
error OracleNotUpdated();
error TransferError();
error StalePrice();

/**
 * @title Errors reported across Honey Finance Labs contracts
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
contract ErrorReporter {
  enum Error {
    UNAUTHORIZED, //0
    INSUFFICIENT_LIQUIDITY,
    INVALID_COLLATERAL_FACTOR,
    MAX_MARKETS_IN,
    MARKET_NOT_LISTED,
    MARKET_ALREADY_LISTED, //5
    MARKET_CAP_BORROW_REACHED,
    MARKET_NOT_FRESH,
    PRICE_ERROR,
    BAD_INPUT,
    AMOUNT_ZERO, //10
    NO_DEBT,
    LIQUIDATION_NOT_ALLOWED,
    WITHDRAW_NOT_ALLOWED,
    INITIAL_EXCHANGE_MANTISSA,
    TRANSFER_ERROR, //15
    COUPON_LOOKUP,
    TOKEN_INSUFFICIENT_CASH,
    BORROW_RATE_TOO_BIG,
    NONZERO_BORROW_BALANCE,
    AMOUNT_TOO_BIG, //20
    AUCTION_NOT_ACTIVE,
    AUCTION_FINISHED,
    AUCTION_NOT_FINISHED,
    AUCTION_PRICE_TOO_LOW,
    AUCTION_NO_BIDS, //25
    CLAWBACK_WINDOW_EXPIRED,
    CLAWBACK_WINDOW_NOT_EXPIRED,
    REFUND_NOT_OWED,
    TOKEN_LOOKUP_ERROR,
    INSUFFICIENT_WINNING_BID, //30
    TOKEN_DEBT_NONEXISTENT,
    AUCTION_SETTLE_FORBIDDEN,
    NFT20_PAIR_NOT_FOUND,
    NFTX_PAIR_NOT_FOUND,
    TOKEN_NOT_PRESENT, //35
    CANCEL_TOO_SOON,
    AUCTION_USER_NOT_FOUND
  }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./HTokenI.sol";

/**
 * @title PriceOracle interface for Chainlink oracles
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
interface PriceOracleI {
  /**
   * @notice requesting the floor price of the entire collection
   * @dev must have REQUESTOR_ROLE
   * @param _collection collection name
   * @param _pricingAsset the returned price currency eth/usd
   */
  function requestFloor(address _collection, string calldata _pricingAsset) external;

  /**
   * @notice requesting a price for an individual token id within a collection
   * @dev must have REQUESTOR_ROLE
   * @param _collection collection name
   * @param _pricingAsset the returned price currency eth/usd
   * @param _tokenId the token id we request the price for
   */
  function requestIndividual(
    address _collection,
    string calldata _pricingAsset,
    uint256 _tokenId
  ) external;

  /**
   * @notice returns the underlying price for the floor of a collection
   * @param _collection address of the collection
   * @param _decimals adjust decimals of the returned price
   */
  function getUnderlyingFloorNFTPrice(address _collection, uint256 _decimals) external view returns (uint128, uint128);

  /**
   * @notice returns the underlying price for an individual token id
   * @param _collection address of the collection
   * @param _tokenId token id within this collection
   * @param _decimals adjust decimals of the returned price
   */
  function getUnderlyingIndividualNFTPrice(
    address _collection,
    uint256 _tokenId,
    uint256 _decimals
  ) external view returns (uint256);

  /**
   * @notice returns the latest price for a given pair
   * @param _erc20 the erc20 we want to get the price for in USD
   * @param _decimals decimals to denote the result in
   */
  function getUnderlyingPriceInUSD(IERC20 _erc20, uint256 _decimals) external view returns (uint256);

  /**
   * @notice get price of eth
   * @param _decimals adjust decimals of the returned price
   */
  function getEthPrice(uint256 _decimals) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./HTokenI.sol";

/**
 * @title Interface of Hivemind
 * @author Honey Finance Labs
 * @custom:coauthor m4rio
 * @custom:contributor BowTiedPickle
 */
interface HivemindI {
  /**
   * @notice Add assets to be included in account liquidity calculation
   * @param _hTokens The list of addresses of the hToken markets to be enabled
   */
  function enterMarkets(HTokenI[] calldata _hTokens) external;

  /**
   * @notice Removes asset from sender's account liquidity calculation
   * @dev Sender must not have an outstanding borrow balance in the asset,
   *  or be providing necessary collateral for an outstanding borrow.
   * @param _hToken The address of the asset to be removed
   */
  function exitMarket(HTokenI _hToken) external;

  /**
   * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
   * @param _hToken The market to verify the borrow against
   * @param _borrower The account which would borrow the asset
   * @param _collateralId collateral Id, aka the NFT token Id
   * @param _borrowAmount The amount of underlying the account would borrow
   */
  function borrowAllowed(
    HTokenI _hToken,
    address _borrower,
    uint256 _collateralId,
    uint256 _borrowAmount
  ) external;

  /**
   * @notice Checks if the account should be allowed to redeem tokens in the given market
   * @param _hToken The market to verify the redeem against
   * @param _redeemer The account which would redeem the tokens
   * @param _redeemTokens The number of hTokens to exchange for the underlying asset in the market
   */
  function redeemAllowed(
    HTokenI _hToken,
    address _redeemer,
    uint256 _redeemTokens
  ) external view;

  /**
   * @notice Checks if the collateral is at risk of being liquidated
   * @param _hToken The market to verify the liquidation
   * @param _collateralId collateral Id, aka the NFT token Id
   */
  function liquidationAllowed(HTokenI _hToken, uint256 _collateralId) external view;

  /**
   * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
   * @param _hToken The market to hypothetically redeem/borrow in
   * @param _account The account to determine liquidity for
   * @param _redeemTokens The number of tokens to hypothetically redeem
   * @param _borrowAmount The amount of underlying to hypothetically borrow
   * @param _collateralId collateral Id, aka the NFT token Id
   * @return liquidity - hypothetical account liquidity in excess of collateral requirements
   * @return shortfall - hypothetical account shortfall below collateral requirements
   */
  function getHypotheticalAccountLiquidity(
    HTokenI _hToken,
    address _account,
    uint256 _collateralId,
    uint256 _redeemTokens,
    uint256 _borrowAmount
  ) external view returns (uint256 liquidity, uint256 shortfall);

  /**
   * @notice Returns the assets an account has entered
   * @param _account The address of the account to pull assets for
   * @return A dynamic list with the assets the account has entered
   */
  function getAssetsIn(address _account) external view returns (HTokenI[] memory);

  /**
   * @notice Returns whether the given account is entered in the given asset
   * @param _hToken The hToken to check
   * @param _account The address of the account to check
   * @return True if the account is in the asset, otherwise false.
   */
  function checkMembership(HTokenI _hToken, address _account) external view returns (bool);

  /**
   * @notice Checks if the account should be allowed to transfer tokens in the given market
   * @param _hToken The market to verify the transfer against
   */
  function transferAllowed(HTokenI _hToken) external;

  /**
   * @notice Checks if the account should be allowed to repay a borrow in the given market
   * @param _hToken The market to verify the repay against
   * @param _repayAmount The amount of the underlying asset the account would repay
   * @param _collateralId collateral Id, aka the NFT token Id
   */
  function repayBorrowAllowed(
    HTokenI _hToken,
    uint256 _repayAmount,
    uint256 _collateralId
  ) external view;

  /**
   * @notice checks if withdrawal are allowed for this token id
   * @param _hToken The market to verify the withdrawal from
   * @param _collateralId what to pay for
   */
  function withdrawalCollateralAllowed(HTokenI _hToken, uint256 _collateralId) external view;

  /**
   * @notice Return the length of all markets
   * @return the length
   */
  function getAllMarketsLength() external view returns (uint256);

  /**
   * @notice checks if a market exists and it's listed
   * @param _hToken the market we check to see if it exists
   * @return bool true or false
   */
  function marketExists(HTokenI _hToken) external view returns (bool);

  /**
   * @notice returns the collateral factor for a given market
   * @param _hToken the market we want the market of
   * @return collateral factor in 1e18
   */
  function getCollateralFactor(HTokenI _hToken) external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import ".././interfaces/HTokenI.sol";
import ".././interfaces/PriceOracleI.sol";

/**
/**
 * @title Honey Protocol Hivemind Storage
 * @notice Storage 
 * @author Honey Finance Labs
 * @custom:coauthor m4rio
 * @custom:contributor BowTiedPickle
 */
contract HivemindStorage {
  /**
   * @notice Oracle which gives the price of any given asset
   */
  PriceOracleI public oracle;

  /**
   * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
   */
  uint256 public closeFactorMantissa;

  /**
   * @notice A cap put on how many markets a single account can participate in (borrow or use as collateral)
   */
  uint256 public marketsInCap;

  /**
   * @notice Per-account mapping of "markets you are in", capped by marketsInCap
   */
  mapping(address => HTokenI[]) public accountMarkets;

  struct Market {
    /// @notice Whether or not this market is listed
    bool isListed;
    /**
     * @notice Multiplier representing the most one can borrow against their collateral in this market.
     *  For instance, 0.9e18 to allow borrowing 90% of collateral value.
     *  Must be between 0 (0%) and 1e18 (100%), and stored as a mantissa.
     */
    uint256 collateralFactorMantissa;
    /// @notice Per-market mapping of "accounts in this market"
    mapping(address => bool) accountMembership;
  }

  /**
   * @notice Official mapping of hTokens -> Market metadata
   * @dev Used e.g. to determine if a market is supported
   */
  mapping(HTokenI => Market) public markets;

  /**
   * @notice Info about functionalities being paused in a market
   */

  struct MarketPausedInfo {
    bool borrowPaused;
    bool transferPaused;
    bool redeemPaused;
    bool liquidationPaused;
  }

  mapping(HTokenI => MarketPausedInfo) public marketPausedInfo;

  /// @notice A list of all markets
  HTokenI[] public allMarkets;

  // @notice Borrow caps enforced by borrowAllowed for each hToken address. Defaults to zero which corresponds to unlimited borrowing.
  mapping(HTokenI => uint256) public borrowCaps;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title Interface of HToken Internal
 * @author Honey Finance Labs
 * @custom:coauthor m4rio
 * @custom:coauthor BowTiedPickle
 */
interface HTokenInternalI is IERC1155 {
  // Coupon NFT metadata
  struct Coupon {
    uint32 id; //coupon id
    uint8 active; // Whether this coupon is active and should be counted in calculations etc. 0 = not initialized, 1 = inactive, 2 = active
    address owner; // Who is the owner of this coupon, this changes at transfer
    uint256 collateralId; // tokenId of the collateral collection that is borrowed against
    uint256 borrowAmount; // Principal borrow balance, denominated in underlying ERC20 token. Updated when interest is accrued to the coupon.
    uint256 interestIndex; // Mantissa formatted borrow interestIndex. Updated when interest is accrued to the coupon.
  }

  struct Collateral {
    uint256 collateralId;
    bool active;
  }

  // ----- Informational -----

  function decimals() external view returns (uint8);

  // ----- Addresses -----

  function collateralToken() external view returns (IERC721);

  function underlyingToken() external view returns (IERC20);

  function hivemind() external view returns (address);

  function dao() external view returns (address);

  function interestRateModel() external view returns (address);

  function initialExchangeRateMantissa() external view returns (address);

  // ----- Fee Information -----

  function reserveFactorMantissa() external view returns (uint256);

  function reserveFactorMaxMantissa() external view returns (uint256);

  function borrowRateMaxMantissa() external view returns (uint256);

  function adminFeeMantissa() external view returns (uint256);

  function fuseFeeMantissa() external view returns (uint256);

  function reserveFactorPlusFeesMaxMantissa() external view returns (uint256);

  // ----- Protocol Accounting -----

  function totalBorrows() external view returns (uint256);

  function totalReserves() external view returns (uint256);

  function totalHTokenSupply() external view returns (uint256);

  function totalFuseFees() external view returns (uint256);

  function totalAdminFees() external view returns (uint256);

  function accrualBlockNumber() external view returns (uint256);

  function interestIndexStored() external view returns (uint256);

  function interestIndex() external view returns (uint256);

  function totalHiveFees() external view returns (uint256);

  function userToCoupons(address _user) external view returns (uint256);

  function collateralPerBorrowCouponId(uint256 _couponId) external view returns (Collateral memory);

  function borrowCoupons(uint256 _collateralId) external view returns (Coupon memory);

  // ----- Views -----

  /**
   * @notice get user's coupon
   * @param _user the user to search for
   * @return user's coupons
   */
  function getUserCoupons(address _user) external view returns (Coupon[] memory);

  /**
   * @notice get tokenIds of all a user's coupons
   * @param _user the user to search for
   * @return indices of user's coupons
   */
  function getUserCouponIndices(address _user) external view returns (uint256[] memory);

  /**
   * @notice get a specific coupon for an NFT
   * @param _collateralId collateral id
   * @return coupon
   */
  function getSpecificCouponByCollateralId(uint256 _collateralId) external view returns (Coupon memory);

  /**
   * @notice Get the number of coupons deposited aka active
   * @return depositedCoupons An array of coupons
   */
  function getActiveCoupons() external view returns (Coupon[] memory);

  /**
   * @notice Returns the current per-block borrow interest rate for this hToken
   * @return The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view returns (uint256);

  /**
   * @notice get outstanding debt of a coupon
   * @param _collateralId index of the borrowed coupon
   * @return Debt denominated in the underlying token
   */
  function getBorrowFromCoupon(uint256 _collateralId) external view returns (uint256);

  /**
   * @notice Get a snapshot of the account's balances, and the cached exchange rate
   * @dev This is used by hivemind to more efficiently perform liquidity checks.
   * @param _account Address of the account to snapshot
   * @return (token balance, borrow balance, exchange rate mantissa)
   */
  function getAccountSnapshot(address _account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /**
   * @notice Get borrow amount for a collateral
   * @param _collateralId collateral id we want to get the borrow amount for
   * @return The amount borrowed so far
   */
  function getBorrowAmountForCollateral(uint256 _collateralId) external view returns (uint256);

  /**
   * @notice returns the uri by calling the hTokenHelper
   * @param _id id of the token we want to get the uri
   */
  function uri(uint256 _id) external view returns (string memory);

  // ----- State Changing Permissionless -----

  /**
   * @notice Accrues all interest due to the protocol
   * @dev Call this before performing calculations using 'totalBorrows' or other contract-wide quantities
   */
  function accrueInterest() external;

  /**
   * @notice Accrue interest due on a single coupon
   * @dev Call before interacting with any coupon
   * @dev Updates contract global quantities
   * @param _couponId Coupon tokenId to accrue for
   * @return Amount of interest accrued
   */
  function accrueInterestToCoupon(uint256 _couponId) external returns (uint256);

  /**
   * @notice Accrue interest then return the up-to-date exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() external returns (uint256);

  /**
   * @notice Calculates the exchange rate from the underlying to the HToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return (error code, calculated exchange rate scaled by 1e18)
   */
  function exchangeRateStored() external view returns (uint256);

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying tokens owned by this contract
   */
  function getCashPrior() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}