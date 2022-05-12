// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILongShort.sol";
import "../interfaces/IStakeBalance.sol";
import "../interfaces/IStaker.sol";

contract ProfileGetter {
  ILongShort longShort;
  IStakeBalance stakeBalance;
  IStaker staker;

  constructor(
    address _longShortAddress,
    address _stakeBalanceAddress,
    address _stakerAddress
  ) {
    longShort = ILongShort(_longShortAddress);
    stakeBalance = IStakeBalance(_stakeBalanceAddress);
    staker = IStaker(_stakerAddress);
  }

  /*╔═══════════════════════════╗
    ║       MINT & SHIFT        ║
    ╚═══════════════════════════╝*/

  struct UserMarketBalance {
    uint32 marketIndex;
    bool isLong;
    uint256 userNextPriceCurrent;
    uint256 latestPrice;
    uint256 tokenBalance;
    uint32 lastInteractionTimestamp;
  }

  struct UserLongAndShortMarketBalance {
    UserMarketBalance long;
    UserMarketBalance short;
  }

  /**
    @notice Returns the balance of a synthetic token owned or staked by a user.
    @dev Used in _getSyntheticMarketBalance - primarily split this function out to avoid stack too deep compilation
    errors.
    @param _marketIndex An uint32 which uniquely identifies a market.
    @param _isLong A boolean used to choose the synthetic token on the long or short side of the market.
    @param _user The address of the user for whom to execute the function for.
    @param _useStakeBalance The boolean value for whether to return the staked balance or synthetic token balance
    */
  function _getSynthTokenOrStakeBalance(
    uint32 _marketIndex,
    bool _isLong,
    address _user,
    bool _useStakeBalance
  ) private view returns (uint256) {
    if (_useStakeBalance) {
      return stakeBalance.userAmountStaked(_user, longShort.syntheticTokens(_marketIndex, _isLong));
    } else {
      return IERC20(longShort.syntheticTokens(_marketIndex, _isLong)).balanceOf(_user);
    }
  }

  /**
    @notice Returns a struct containing UserMarketBalance structs on both the long and short side of the market
    for synthetic assets (staked or unstaked)
    @dev Used in _getUserMarketBalances which takes these returned values and formats them into
    a simplified array of UserMarketBalance structs. Using as many inline references as possible to avoid
    stack to deep compilation errors.
    @param _marketIndex An uint32 which uniquely identifies a market.
    @param _user The address of the user for whom to execute the function for.
    @param _useStakeBalance The boolean value for whether to return the staked balance or synthetic token balance
    */
  function _getSyntheticMarketBalance(
    uint32 _marketIndex,
    address _user,
    bool _useStakeBalance
  ) private view returns (UserLongAndShortMarketBalance memory) {
    uint256 _userMarketUpdateIndex = longShort.userNextPrice_currentUpdateIndex(
      _marketIndex,
      _user
    );

    // If there is no currentUpdateIndex for a user we can assume they have no balances
    // in this market
    if (_userMarketUpdateIndex == 0) {
      UserLongAndShortMarketBalance memory deadMarketBalances;
      return deadMarketBalances;
    }

    (uint256 _latestPriceLong, uint256 _latestPriceShort) = longShort
      .get_syntheticToken_priceSnapshot(_marketIndex, longShort.marketUpdateIndex(_marketIndex));
    (uint32 _longLastInteractionTimestamp, ) = longShort.userLastInteractionTimestamp(
      _marketIndex,
      true,
      _user
    );
    (uint32 _shortLastInteractionTimestamp, ) = longShort.userLastInteractionTimestamp(
      _marketIndex,
      false,
      _user
    );

    return
      UserLongAndShortMarketBalance({
        long: UserMarketBalance({
          marketIndex: _marketIndex,
          isLong: true,
          userNextPriceCurrent: longShort.get_syntheticToken_priceSnapshot_side(
            _marketIndex,
            true,
            _userMarketUpdateIndex
          ),
          latestPrice: _latestPriceLong,
          tokenBalance: _getSynthTokenOrStakeBalance(_marketIndex, true, _user, _useStakeBalance),
          lastInteractionTimestamp: _longLastInteractionTimestamp
        }),
        short: UserMarketBalance({
          marketIndex: _marketIndex,
          isLong: false,
          userNextPriceCurrent: longShort.get_syntheticToken_priceSnapshot_side(
            _marketIndex,
            false,
            _userMarketUpdateIndex
          ),
          latestPrice: _latestPriceShort,
          tokenBalance: _getSynthTokenOrStakeBalance(_marketIndex, false, _user, _useStakeBalance),
          lastInteractionTimestamp: _shortLastInteractionTimestamp
        })
      });
  }

  /**
    @notice Returns an array of userMarketBalance structs of all synthetic tokens or staked tokens held by a user.
    @dev Used by getUserSyntheticMarketBalances and getUserStakedMarketBalances.
    @param _user The address of the user for whom to execute the function for.
    @param _useStakeBalance A bool representing whether to get staked market balances or synthetic market balances.
    */
  function _getUserMarketBalances(address _user, bool _useStakeBalance)
    private
    view
    returns (UserMarketBalance[] memory)
  {
    uint32 _latestMarket = longShort.latestMarket();

    UserMarketBalance[] memory _marketBalancesAllPossible = new UserMarketBalance[](
      _latestMarket * 2
    );

    uint32 _marketBalancesCount;

    for (uint32 i = 1; i <= _latestMarket; i++) {
      UserLongAndShortMarketBalance memory _markets = _getSyntheticMarketBalance(
        i,
        _user,
        _useStakeBalance
      );

      if (_markets.long.tokenBalance > 0) {
        _marketBalancesAllPossible[(i * 2) - 1] = _markets.long;
        _marketBalancesCount++;
      }

      if (_markets.short.tokenBalance > 0) {
        _marketBalancesAllPossible[(i * 2)] = _markets.short;
        _marketBalancesCount++;
      }
    }

    UserMarketBalance[] memory _userMarketBalances = new UserMarketBalance[](_marketBalancesCount);
    uint32 _currentMarketBalanceIndex = 0;
    for (uint32 i = 0; i < (_latestMarket * 2); i++) {
      UserMarketBalance memory _currentMarketBalance = _marketBalancesAllPossible[i];
      if (_currentMarketBalance.marketIndex > 0) {
        _userMarketBalances[_currentMarketBalanceIndex] = _currentMarketBalance;
        _currentMarketBalanceIndex++;
      }
    }
    return _userMarketBalances;
  }

  /**
    @notice Returns an array of userMarketBalance structs of all synthetic tokens held by a user.
    @dev Used by the dapp to get information for the user profile page in the event that the graph is down
    or slow
    @param _user The address of the user for whom to execute the function for.
    */
  function getUserSyntheticMarketBalances(address _user)
    public
    view
    returns (UserMarketBalance[] memory)
  {
    return _getUserMarketBalances(_user, false);
  }

  /**
    @notice Returns an array of userMarketBalance structs of all staked synthetic tokens held by a user.
    @dev Used by the dapp to get information for the user profile page in the event that the graph is down
    or slow
    @param _user The address of the user for whom to execute the function for.
    */
  function getUserStakedMarketBalances(address _user)
    public
    view
    returns (UserMarketBalance[] memory)
  {
    return _getUserMarketBalances(_user, true);
  }

  struct PendingAction {
    uint32 marketIndex;
    bool isLong;
    string actionType;
    uint256 amount;
  }

  struct MintShiftMarketSidePendingActions {
    PendingAction mint;
    PendingAction shift;
  }

  struct MintShiftMarketPendingActions {
    MintShiftMarketSidePendingActions long;
    MintShiftMarketSidePendingActions short;
    uint32 totalPendingActions;
  }

  /**
    @notice Returns the amount deposited on a users minting action in dai
    @dev Used in _getMintShiftMarketPendingActions
    @param _marketIndex An uint32 which uniquely identifies a market.
    @param _isLong a boolean that determines whether to target the long or short side of the market.
    @param _userAddress The address of the user for whom to execute the function for.
    @param _useStakerValues A boolean value to determine whether to get values from the longShort contract
    or the staker contract.
    */
  function _getMintDepositAmount(
    uint32 _marketIndex,
    bool _isLong,
    address _userAddress,
    bool _useStakerValues
  ) private view returns (uint256) {
    if (_useStakerValues) {
      return staker.userNextPrice_paymentToken_depositAmount(_marketIndex, _isLong, _userAddress);
    } else {
      return
        longShort.userNextPrice_paymentToken_depositAmount(_marketIndex, _isLong, _userAddress);
    }
  }

  /**
    @notice Returns the amount of synthetic tokens a user wishes to shift away from a market side
    @dev Used in _getMintShiftMarketPendingActions
    @param _marketIndex An uint32 which uniquely identifies a market.
    @param _isLong a boolean that determines whether to target the long or short side of the market.
    @param _userAddress The address of the user for whom to execute the function for.
    @param _useStakerValues A boolean value to determine whether to get values from the longShort contract
    or the staker contract.
    */
  function _getShiftTokenAmount(
    uint32 _marketIndex,
    bool _isLong,
    address _userAddress,
    bool _useStakerValues
  ) private view returns (uint256) {
    if (_useStakerValues) {
      return
        staker.userNextPrice_amountStakedSyntheticToken_toShiftAwayFrom(
          _marketIndex,
          _isLong,
          _userAddress
        );
    } else {
      return
        longShort.userNextPrice_syntheticToken_toShiftAwayFrom_marketSide(
          _marketIndex,
          _isLong,
          _userAddress
        );
    }
  }

  /**
    @notice Returns a struct of all Mint and Shift Pending Actions on both long and short sides of a given market
    for a given user
    @dev Used in getUserShiftAndMintPendingActions which takes these returned values and formats them into
    a simplified array of pendingActions.
    @param _marketIndex An uint32 which uniquely identifies a market.
    @param _user The address of the user for whom to execute the function for.
    @param _useStakerValues A boolean value to determine whether to get values from the longShort contract
    or the staker contract.
    */
  function _getMintShiftMarketPendingActions(
    uint32 _marketIndex,
    address _user,
    bool _useStakerValues
  ) private view returns (MintShiftMarketPendingActions memory) {
    // If the current "MarketUpdateIndex" is the same or ahead of the user's price
    // index of their position the action is not pending so we can return a dead value
    // check the currentUpdateIndex on the staker contract if _useStakerValues is true
    // else check it on the longsShort contract
    if (
      (longShort.userNextPrice_currentUpdateIndex(_marketIndex, _user) <=
        longShort.marketUpdateIndex(_marketIndex) &&
        !_useStakerValues) ||
      (staker.userNextPrice_stakedActionIndex(_marketIndex, _user) <=
        longShort.marketUpdateIndex(_marketIndex) &&
        _useStakerValues)
    ) {
      MintShiftMarketPendingActions memory deadPendingActions;
      return deadPendingActions;
    }

    // Used to tally the pending actions so that we can initialize an array of
    // fixed size that will represent all pending actions
    uint32 totalPendingActions;

    // Get deposit amounts on each side of the market and increment totalPendingActions
    // if there is a value greater than 0
    uint256 mintAmountLong = _getMintDepositAmount(_marketIndex, true, _user, _useStakerValues);

    if (mintAmountLong > 0) {
      totalPendingActions++;
    }

    uint256 mintAmountShort = _getMintDepositAmount(_marketIndex, false, _user, _useStakerValues);

    if (mintAmountShort > 0) {
      totalPendingActions++;
    }
    // Get shift amounts on each side of the market and increment totalPendingActions
    // if there is a value greater than 0
    uint256 shiftAmountLong = _getShiftTokenAmount(_marketIndex, true, _user, _useStakerValues);

    if (shiftAmountLong > 0) {
      totalPendingActions++;
    }

    uint256 shiftAmountShort = _getShiftTokenAmount(_marketIndex, false, _user, _useStakerValues);
    if (shiftAmountShort > 0) {
      totalPendingActions++;
    }

    // Return a struct with values for Mint and shift actions on both sides of the market
    return
      MintShiftMarketPendingActions({
        long: MintShiftMarketSidePendingActions({
          mint: PendingAction({
            marketIndex: _marketIndex,
            isLong: true,
            actionType: "Mint",
            amount: mintAmountLong
          }),
          shift: PendingAction({
            marketIndex: _marketIndex,
            isLong: true,
            actionType: "Shift",
            amount: shiftAmountLong
          })
        }),
        short: MintShiftMarketSidePendingActions({
          mint: PendingAction({
            marketIndex: _marketIndex,
            isLong: false,
            actionType: "Mint",
            amount: mintAmountShort
          }),
          shift: PendingAction({
            marketIndex: _marketIndex,
            isLong: false,
            actionType: "Shift",
            amount: shiftAmountShort
          })
        }),
        totalPendingActions: totalPendingActions
      });
  }

  /**
    @notice Returns an array of structs of all current mint and shift pending actions (awaiting a next price 
    update) for a given user
    @dev Used in getUserShiftAndMintPendingActions and getUserStakeShiftAndMintPendingActions
    @param _user The address of the user for whom to execute the function for.
    @param _useStakerValues A boolean value to determine whether to get values from the longShort contract
    or the staker contract.
    */
  function _getUserShiftAndMintPendingActions(address _user, bool _useStakerValues)
    private
    view
    returns (PendingAction[] memory)
  {
    uint32 _latestMarket = longShort.latestMarket();

    MintShiftMarketPendingActions[]
      memory _pendingActionsAllPossible = new MintShiftMarketPendingActions[](_latestMarket);

    uint32 _pendingActionsCount;

    for (uint32 i = 1; i <= _latestMarket; i++) {
      MintShiftMarketPendingActions
        memory _marketPendingActions = _getMintShiftMarketPendingActions(
          i,
          _user,
          _useStakerValues
        );

      _pendingActionsAllPossible[i - 1] = _marketPendingActions;

      _pendingActionsCount = _pendingActionsCount + _marketPendingActions.totalPendingActions;
    }

    PendingAction[] memory _userPendingActions = new PendingAction[](_pendingActionsCount);
    uint32 _currentPendingActionsIndex = 0;

    for (uint32 i = 0; i < _latestMarket; i++) {
      MintShiftMarketPendingActions memory _currentPendingAction = _pendingActionsAllPossible[i];
      if (_currentPendingAction.long.mint.amount > 0) {
        _userPendingActions[_currentPendingActionsIndex] = _currentPendingAction.long.mint;
        _currentPendingActionsIndex++;
      }
      if (_currentPendingAction.short.mint.amount > 0) {
        _userPendingActions[_currentPendingActionsIndex] = _currentPendingAction.short.mint;
        _currentPendingActionsIndex++;
      }
      if (_currentPendingAction.long.shift.amount > 0) {
        _userPendingActions[_currentPendingActionsIndex] = _currentPendingAction.long.shift;
        _currentPendingActionsIndex++;
      }
      if (_currentPendingAction.short.shift.amount > 0) {
        _userPendingActions[_currentPendingActionsIndex] = _currentPendingAction.short.shift;
        _currentPendingActionsIndex++;
      }
    }
    return _userPendingActions;
  }

  /**
    @notice Returns an array of structs of all current mint and shift pending actions in markets (awaiting a next price 
    update) for a given user
    @dev Used by the dapp to get information for the user profile page in the event that the graph is down
    or slow
    @param _user The address of the user for whom to execute the function for.
    */
  function getUserShiftAndMintPendingActions(address _user)
    public
    view
    returns (PendingAction[] memory)
  {
    return _getUserShiftAndMintPendingActions(_user, false);
  }

  /**
    @notice Returns an array of structs of all current mint and shift pending actions that have been staked 
    (awaiting a next price update) for a given user
    @dev Used by the dapp to get information for the user profile page in the event that the graph is down
    or slow
    @param _user The address of the user for whom to execute the function for.
    */
  function getUserStakeShiftAndMintPendingActions(address _user)
    public
    view
    returns (PendingAction[] memory)
  {
    return _getUserShiftAndMintPendingActions(_user, true);
  }

  struct RedeemMarketPendingActions {
    PendingAction long;
    PendingAction short;
    uint32 totalPendingActions;
  }

  /**
  @notice Returns a struct of all Redeem Pending Actions on both long and short sides of a given market
  for a given user
  @dev Used in getUserRedeemPendingActions which takes these returned values and formats them into
  a simplified array of pendingActions.
  @param _marketIndex An uint32 which uniquely identifies a market.
  @param _user The address of the user for whom to execute the function for.
  @param _useConfirmedRedeems The boolean value to determine whether to return confirmed actions or pending
  actions that are awaiting the next price update.
  */
  function _getRedeemPendingActions(
    uint32 _marketIndex,
    address _user,
    bool _useConfirmedRedeems
  ) public view returns (RedeemMarketPendingActions memory) {
    uint256 userMarketUpdateIndex = longShort.userNextPrice_currentUpdateIndex(_marketIndex, _user);

    uint256 currentMarketUpdateIndex = longShort.marketUpdateIndex(_marketIndex);

    bool redeemConfirmed = userMarketUpdateIndex <= currentMarketUpdateIndex;

    bool shouldReturnDeadAction = (redeemConfirmed && !_useConfirmedRedeems) ||
      (!redeemConfirmed && _useConfirmedRedeems);
    // If the current "MarketUpdateIndex" is the same or ahead of the user's price
    // index of their position the action is not pending so we can return a dead value
    if (shouldReturnDeadAction) {
      RedeemMarketPendingActions memory deadPendingActions;
      return deadPendingActions;
    }

    // Used to tally the pending actions so that we can initialize an array of
    // fixed size that will represent all pending actions
    uint32 totalPendingActions;

    // Get deposit amounts on each side of the market and increment totalPendingActions
    // if there is a value greater than 0
    uint256 redeemAmountLong = longShort.userNextPrice_syntheticToken_redeemAmount(
      _marketIndex,
      true,
      _user
    );
    if (redeemAmountLong > 0) {
      totalPendingActions++;
    }

    uint256 redeemAmountShort = longShort.userNextPrice_syntheticToken_redeemAmount(
      _marketIndex,
      false,
      _user
    );
    if (redeemAmountShort > 0) {
      totalPendingActions++;
    }

    // Return a struct with values for Mint and shift actions on both sides of the market
    return
      RedeemMarketPendingActions({
        long: PendingAction({
          marketIndex: _marketIndex,
          isLong: true,
          actionType: "Redeem",
          amount: redeemAmountLong
        }),
        short: PendingAction({
          marketIndex: _marketIndex,
          isLong: false,
          actionType: "Redeem",
          amount: redeemAmountShort
        }),
        totalPendingActions: totalPendingActions
      });
  }

  /**
  @notice Returns an array of structs of all current redeem pending or confirmed actions for a given user
  @dev Used by the getUserRedeemPendingActions and getUserRedeemConfirmedActions
  @param _user The address of the user for whom to execute the function for.
  @param _useConfirmedRedeems The boolean value to determine whether to return confirmed actions or pending
  actions that are awaiting the next price update.
  */
  function _getUserRedeemActions(address _user, bool _useConfirmedRedeems)
    public
    view
    returns (PendingAction[] memory)
  {
    uint32 _latestMarket = longShort.latestMarket();

    RedeemMarketPendingActions[]
      memory _pendingActionsAllPossible = new RedeemMarketPendingActions[](_latestMarket);

    uint32 _pendingActionsCount;

    for (uint32 i = 1; i <= _latestMarket; i++) {
      RedeemMarketPendingActions memory _marketPendingActions = _getRedeemPendingActions(
        i,
        _user,
        _useConfirmedRedeems
      );

      _pendingActionsAllPossible[i - 1] = _marketPendingActions;

      _pendingActionsCount = _pendingActionsCount + _marketPendingActions.totalPendingActions;
    }

    PendingAction[] memory _userPendingActions = new PendingAction[](_pendingActionsCount);
    uint32 _currentPendingActionsIndex = 0;

    for (uint32 i = 0; i < _latestMarket; i++) {
      RedeemMarketPendingActions memory _currentPendingAction = _pendingActionsAllPossible[i];
      if (_currentPendingAction.long.amount > 0) {
        _userPendingActions[_currentPendingActionsIndex] = _currentPendingAction.long;
        _currentPendingActionsIndex++;
      }
      if (_currentPendingAction.short.amount > 0) {
        _userPendingActions[_currentPendingActionsIndex] = _currentPendingAction.short;
        _currentPendingActionsIndex++;
      }
    }
    return _userPendingActions;
  }

  /**
  @notice Returns an array of structs of all current redeem pending actions (awaiting a next price 
  update) for a given user
  @dev Used by the dapp to get information for the user profile page in the event that the graph is down
  or slow
  @param _user The address of the user for whom to execute the function for.
  */
  function getUserRedeemPendingActions(address _user) public view returns (PendingAction[] memory) {
    return _getUserRedeemActions(_user, false);
  }

  /**
  @notice Returns an array of structs of all current redeem confirmed actions (awaiting a next price 
  update) for a given user
  @dev Used by the dapp to get information for the user profile page in the event that the graph is down
  or slow
  @param _user The address of the user for whom to execute the function for.
  */
  function getUserRedeemConfirmedActions(address _user)
    public
    view
    returns (PendingAction[] memory)
  {
    return _getUserRedeemActions(_user, true);
  }
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.10;

interface ILongShort {
  /*╔════════════════════════════╗
    ║           EVENTS           ║
    ╚════════════════════════════╝*/

  event Upgrade(uint256 version);
  event LongShortV1(address admin, address tokenFactory, address staker);

  event SystemStateUpdated(
    uint32 marketIndex,
    uint256 updateIndex,
    int256 underlyingAssetPrice,
    uint256 longValue,
    uint256 shortValue,
    uint256 longPrice,
    uint256 shortPrice
  );

  event SyntheticMarketCreated(
    uint32 marketIndex,
    address longTokenAddress,
    address shortTokenAddress,
    address paymentToken,
    int256 initialAssetPrice,
    string name,
    string symbol,
    address oracleAddress,
    address yieldManagerAddress
  );

  event NextPriceRedeem(
    uint32 marketIndex,
    bool isLong,
    uint256 synthRedeemed,
    address user,
    uint256 oracleUpdateIndex
  );

  event NextPriceSyntheticPositionShift(
    uint32 marketIndex,
    bool isShiftFromLong,
    uint256 synthShifted,
    address user,
    uint256 oracleUpdateIndex
  );

  event NextPriceDeposit(
    uint32 marketIndex,
    bool isLong,
    uint256 depositAdded,
    address user,
    uint256 oracleUpdateIndex
  );

  event NextPriceDepositAndStake(
    uint32 marketIndex,
    bool isLong,
    uint256 amountToStake,
    address user,
    uint256 oracleUpdateIndex
  );

  event OracleUpdated(uint32 marketIndex, address oldOracleAddress, address newOracleAddress);

  event NewMarketLaunchedAndSeeded(uint32 marketIndex, uint256 initialSeed, uint256 marketLeverage);

  event ExecuteNextPriceSettlementsUser(address user, uint32 marketIndex);

  event MarketFundingRateMultiplerChanged(uint32 marketIndex, uint256 fundingRateMultiplier_e18);

  function syntheticTokens(uint32, bool) external view returns (address);

  function assetPrice(uint32) external view returns (int256);

  function oracleManagers(uint32) external view returns (address);

  function latestMarket() external view returns (uint32);

  function marketUpdateIndex(uint32) external view returns (uint256);

  function batched_amountPaymentToken_deposit(uint32, bool) external view returns (uint256);

  function batched_amountSyntheticToken_redeem(uint32, bool) external view returns (uint256);

  function batched_amountSyntheticToken_toShiftAwayFrom_marketSide(uint32, bool)
    external
    view
    returns (uint256);

  function get_syntheticToken_priceSnapshot(uint32, uint256)
    external
    view
    returns (uint256, uint256);

  function get_syntheticToken_priceSnapshot_side(
    uint32,
    bool,
    uint256
  ) external view returns (uint256);

  function marketSideValueInPaymentToken(uint32 marketIndex)
    external
    view
    returns (uint128 marketSideValueInPaymentTokenLong, uint128 marketSideValueInPaymentTokenShort);

  function setUserTradeTimer(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external;

  function checkIfUserIsEligibleToTrade(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external;

  function checkIfUserIsEligibleToSendSynth(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external;

  function updateSystemState(uint32 marketIndex) external;

  function updateSystemStateMulti(uint32[] calldata marketIndex) external;

  function getUsersConfirmedButNotSettledSynthBalance(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external view returns (uint256 confirmedButNotSettledBalance);

  function executeOutstandingNextPriceSettlementsUser(address user, uint32 marketIndex) external;

  function shiftPositionNextPrice(
    uint32 marketIndex,
    uint256 amountSyntheticTokensToShift,
    bool isShiftFromLong
  ) external;

  function shiftPositionFromLongNextPrice(uint32 marketIndex, uint256 amountSyntheticTokensToShift)
    external;

  function shiftPositionFromShortNextPrice(uint32 marketIndex, uint256 amountSyntheticTokensToShift)
    external;

  function getAmountSyntheticTokenToMintOnTargetSide(
    uint32 marketIndex,
    uint256 amountSyntheticTokenShiftedFromOneSide,
    bool isShiftFromLong,
    uint256 priceSnapshotIndex
  ) external view returns (uint256 amountSynthShiftedToOtherSide);

  function mintLongNextPrice(uint32 marketIndex, uint256 amount) external;

  function mintShortNextPrice(uint32 marketIndex, uint256 amount) external;

  function mintAndStakeNextPrice(
    uint32 marketIndex,
    uint256 amount,
    bool isLong
  ) external;

  function redeemLongNextPrice(uint32 marketIndex, uint256 amount) external;

  function redeemShortNextPrice(uint32 marketIndex, uint256 amount) external;

  /* ══════ User specific ══════ */
  function userNextPrice_currentUpdateIndex(uint32 marketIndex, address user)
    external
    view
    returns (uint256);

  function userLastInteractionTimestamp(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint32 timestamp, uint224 effectiveAmountMinted);

  function userNextPrice_paymentToken_depositAmount(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);

  function userNextPrice_syntheticToken_redeemAmount(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);

  function userNextPrice_syntheticToken_toShiftAwayFrom_marketSide(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.10;

interface IStakeBalance {
  
  function userAmountStaked(address user, address token) external view returns (uint256);

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.10;

interface IStaker {
  /*╔════════════════════════════╗
    ║           EVENTS           ║
    ╚════════════════════════════╝*/

  event Upgrade(uint256 version);

  event StakerV1(
    address admin,
    address floatTreasury,
    address floatCapital,
    address floatToken,
    uint256 floatPercentage
  );

  event MarketAddedToStaker(
    uint32 marketIndex,
    uint256 exitFee_e18,
    uint256 period,
    uint256 multiplier,
    uint256 balanceIncentiveExponent,
    int256 balanceIncentiveEquilibriumOffset,
    uint256 safeExponentBitShifting
  );

  event AccumulativeIssuancePerStakedSynthSnapshotCreated(
    uint32 marketIndex,
    uint256 accumulativeFloatIssuanceSnapshotIndex,
    uint256 accumulativeLong,
    uint256 accumulativeShort
  );

  event StakeAdded(address user, address token, uint256 amount, uint256 lastMintIndex);

  event StakeWithdrawn(address user, address token, uint256 amount);

  event StakeWithdrawnWithFees(address user, address token, uint256 amount, uint256 amountFees);

  // Note: the `amountFloatMinted` isn't strictly needed by the graph, but it is good to add it to validate calculations are accurate.
  event FloatMinted(address user, uint32 marketIndex, uint256 amountFloatMinted);

  event MarketLaunchIncentiveParametersChanges(
    uint32 marketIndex,
    uint256 period,
    uint256 multiplier
  );

  event StakeWithdrawalFeeUpdated(uint32 marketIndex, uint256 stakeWithdralFee);

  event BalanceIncentiveParamsUpdated(
    uint32 marketIndex,
    uint256 balanceIncentiveExponent,
    int256 balanceIncentiveCurve_equilibriumOffset,
    uint256 safeExponentBitShifting
  );

  event FloatPercentageUpdated(uint256 floatPercentage);

  event NextPriceStakeShift(
    address user,
    uint32 marketIndex,
    uint256 amount,
    bool isShiftFromLong,
    uint256 userShiftIndex
  );

  function userAmountStaked(address, address) external view returns (uint256);

  function addNewStakingFund(
    uint32 marketIndex,
    address longTokenAddress,
    address shortTokenAddress,
    uint256 kInitialMultiplier,
    uint256 kPeriod,
    uint256 unstakeFee_e18,
    uint256 _balanceIncentiveCurve_exponent,
    int256 _balanceIncentiveCurve_equilibriumOffset
  ) external;

  function pushUpdatedMarketPricesToUpdateFloatIssuanceCalculations(
    uint32 marketIndex,
    uint256 marketUpdateIndex,
    uint256 longTokenPrice,
    uint256 shortTokenPrice,
    uint256 longValue,
    uint256 shortValue
  ) external;

  function stakeFromUser(address from, uint256 amount) external;

  function shiftTokens(
    uint256 amountSyntheticTokensToShift,
    uint32 marketIndex,
    bool isShiftFromLong
  ) external;

  function latestRewardIndex(uint32 marketIndex) external view returns (uint256);

  // TODO: couldn't get this to work!
  function safe_getUpdateTimestamp(uint32 marketIndex, uint256 latestUpdateIndex)
    external
    view
    returns (uint256);

  function mintAndStakeNextPrice(
    uint32 marketIndex,
    uint256 amount,
    bool isLong,
    address user
  ) external;

  /* ══════ Next price action management specific ══════ */

  function userNextPrice_stakedActionIndex(uint32 marketIndex, address userAddress)
    external
    view
    returns (uint256 stakedActionIndex);

  function userNextPrice_amountStakedSyntheticToken_toShiftAwayFrom(
    uint32 marketIndex,
    bool isLong,
    address userAddress
  ) external view returns (uint256 amountUserRequestedToShiftAwayFromLongOnNextUpdate);

  function userNextPrice_paymentToken_depositAmount(
    uint32 marketIndex,
    bool isLong,
    address userAddress
  ) external view returns (uint256 depositAmount);
}