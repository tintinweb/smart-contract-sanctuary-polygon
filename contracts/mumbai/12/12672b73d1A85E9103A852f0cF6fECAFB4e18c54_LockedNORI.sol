// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "./ERC777PresetPausablePermissioned.sol";
import "./BridgedPolygonNORI.sol";
import {ScheduleUtils, Schedule, Cliff} from "./ScheduleUtils.sol";

/**
 * @title A wrapped BridgedPolygonNORI token contract for vesting and lockup
 *
 * @author Nori Inc.
 *
 * @notice Based on the mechanics of a wrapped ERC-777 token, this contract layers schedules over the withdrawal
 * functionality to implement _vesting_ (a revocable grant)
 * and _lockup_ (an irrevocable timelock on utility).
 *
 * ##### Behaviors and features
 *
 * ###### Grants
 *
 * - _Grants_ define lockup periods and vesting schedules for tokens
 * - A single grant per address is supported
 *
 * ###### Vesting
 *
 * - _Vesting_ is applied in scenarios where the tokens may need to be recaptured by Nori. This could either be due to
 * an employee leaving the company before being fully vested or because one of our suppliers incurs a carbon loss so
 * their restricted (unvested in the terminology of this contract). tokens need to be recaptured to mitigate the loss
 * and make the original buyer whole by using them to purchases new NRTs on their behalf.
 * - Tokens are released linearly from the latest cliff date to the end date of the grant based on the block.timestamp
 * of each block
 *
 * ###### Lockup
 *
 * - _Lockup_ refers to tokens that are guaranteed to be available to the grantee but are subject to a time delay before
 * they are usable / transferrable out of this smart contract. This is a standard mechanism used to avoid sudden floods
 * of liquidity in the BridgedPolygonNORI token that could severely depress the price.
 * - Unlock is always at the same time or lagging vesting
 * - Transfer of LockedNORI under lockup is forbidden
 *
 * ###### Cliffs
 *
 * - A _cliff_ refers to a period prior to which no tokens are vested or unlocked. Cliffs are defined by a date and an
 * amount which must be <= the overall grant amount.
 * - This contract supports a maximum of two distinct cliffs per grant. The effect of fewer cliffs can be achieve by
 * setting one of both cliff times to the start time or end time, and/or by setting the cliff amount to zero.
 *
 * ###### Additional behaviors and features
 *
 * - [Upgradeable](https://docs.openzeppelin.com/contracts/4.x/upgradeable)
 * - [Initializable](https://docs.openzeppelin.com/contracts/4.x/upgradeable#multiple-inheritance)
 * - [Pausable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
 *   - all functions that mutate state are pausable
 * - [Role-based access control](https://docs.openzeppelin.com/contracts/4.x/access-control)
 *    - TOKEN_GRANTER_ROLE
 *      - Can create token grants without sending BridgedPolygonNORI to the contract `createGrant`
 *    - PAUSER_ROLE
 *      - Can pause and unpause the contract
 *    - DEFAULT_ADMIN_ROLE
 *      - This is the only role that can add/revoke other accounts to any of the roles
 * - [Can receive BridgedPolygonNORI ERC-777 tokens](https://eips.ethereum.org/EIPS/eip-777#hooks)
 *   - BridgedPolygonNORI is wrapped and grants are created upon receipt
 * - [Limited ERC-777 functionality](https://eips.ethereum.org/EIPS/eip-777)
 *   - burn and operatorBurn will revert as only the internal variants are expected to be used
 *   - mint is not callable as only the internal variants are expected to be used when wrapping BridgedPolygonNORI
 * - [Limited ERC-20 functionality](https://docs.openzeppelin.com/contracts/4.x/erc20)
 *   - mint is not callable as only the internal variants are expected to be used when wrapping BridgedPolygonNORI
 *   - burn functions are not externally callable
 * - [Extended Wrapped ERC-20 functionality](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Wrapper)
 *   - In absence of a grant LockedNORI functions identically to a standard wrapped token
 *   - when a grant is defined, LockedNORI follows the restrictions noted above
 *
 * ##### Inherits
 *
 * - [ERC777Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc777#ERC777)
 * - [PausableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
 * - [AccessControlEnumerableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/access)
 * - [ContextUpgradeable](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)
 * - [Initializable](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable)
 * - [ERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#ERC165)
 *
 * ##### Implements
 *
 * - [IERC777RecipientUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc777#IERC777Recipient)
 * - [IERC777Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc777#IERC777)
 * - [IERC20Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20)
 * - [IAccessControlEnumerable](https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControlEnumerable)
 * - [IERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165)
 *
 * ##### Uses
 *
 * - [ScheduleUtils](./ScheduleUtils.md) for Schedule
 * - [MathUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#Math)
 *
 */
contract LockedNORI is
  IERC777RecipientUpgradeable,
  ERC777PresetPausablePermissioned
{
  using ScheduleUtils for Schedule;

  struct TokenGrant {
    Schedule vestingSchedule;
    Schedule lockupSchedule;
    uint256 grantAmount;
    uint256 claimedAmount;
    uint256 originalAmount;
    bool exists;
    uint256 lastRevocationTime;
    uint256 lastQuantityRevoked;
  }

  struct TokenGrantDetail {
    uint256 grantAmount;
    address recipient;
    uint256 startTime;
    uint256 vestEndTime;
    uint256 unlockEndTime;
    uint256 cliff1Time;
    uint256 cliff2Time;
    uint256 vestCliff1Amount;
    uint256 vestCliff2Amount;
    uint256 unlockCliff1Amount;
    uint256 unlockCliff2Amount;
    uint256 claimedAmount;
    uint256 originalAmount;
    uint256 lastRevocationTime;
    uint256 lastQuantityRevoked;
    bool exists;
  }

  struct CreateTokenGrantParams {
    address recipient;
    uint256 startTime;
    uint256 vestEndTime;
    uint256 unlockEndTime;
    uint256 cliff1Time;
    uint256 cliff2Time;
    uint256 vestCliff1Amount;
    uint256 vestCliff2Amount;
    uint256 unlockCliff1Amount;
    uint256 unlockCliff2Amount;
  }

  struct DepositForParams {
    address recipient;
    uint256 startTime;
  }

  /**
   * @notice Role conferring creation and revocation of token grants.
   */
  bytes32 public constant TOKEN_GRANTER_ROLE = keccak256("TOKEN_GRANTER_ROLE");

  /**
   * @notice Used to register the ERC777TokensRecipient recipient interface in the
   * ERC-1820 registry
   *
   * @dev Registering that LockedNORI implements the ERC777TokensRecipient interface with the registry is a
   * requiremnt to be able to receive ERC-777 BridgedPolygonNORI tokens. Once registered, sending BridgedPolygonNORI
   * tokens to this contract will trigger tokensReceived as part of the lifecycle of the BridgedPolygonNORI transaction
   */
  bytes32 public constant ERC777_TOKENS_RECIPIENT_HASH =
    keccak256("ERC777TokensRecipient");

  /**
   * @notice A mapping from grantee to grant
   */
  mapping(address => TokenGrant) private _grants;

  /**
   * @notice The BridgedPolygonNORI contract that this contract wraps tokens for
   */
  BridgedPolygonNORI private _bridgedPolygonNori;

  /**
   * @notice The [ERC-1820](https://eips.ethereum.org/EIPS/eip-1820) pseudo-introspection registry
   * contract
   *
   * @dev Registering that LockedNORI implements the ERC777TokensRecipient interface with the registry is a
   * requiremnt to be able to receive ERC-777 BridgedPolygonNORI tokens. Once registered, sending BridgedPolygonNORI
   * tokens to this contract will trigger tokensReceived as part of the lifecycle of the BridgedPolygonNORI transaction
   */
  IERC1820RegistryUpgradeable private _erc1820;

  /**
   * @notice Emitted on successful creation of a new grant.
   */
  event TokenGrantCreated(
    address indexed recipient,
    uint256 indexed amount,
    uint256 indexed startTime,
    uint256 vestEndTime,
    uint256 unlockEndTime
  );

  /**
   * @notice Emitted on when the vesting portion of an active grant is terminated.
   */
  event UnvestedTokensRevoked(
    uint256 indexed atTime,
    address indexed from,
    uint256 indexed quantity
  );

  /**
   * @notice Emitted on withdwal of fully unlocked tokens.
   */
  event TokensClaimed(
    address indexed from,
    address indexed to,
    uint256 quantity
  );

  /**
   * @notice This function is triggered when BridgedPolygonNORI is sent to this contract
   *
   * @dev Sending BridgedPolygonNORI to this contract triggers the tokensReceived hook defined by the ERC-777 standard
   * because this contract is a registered ERC777 tokens recipient.
   *
   * [See here for more](
   * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-777.md#erc777tokensrecipient-and-the-tokensreceived-hook)
   */
  function tokensReceived(
    address sender,
    address,
    address,
    uint256 amount,
    bytes calldata userData,
    bytes calldata operatorData
  ) external override {
    require(
      _msgSender() == address(_bridgedPolygonNori),
      "lNORI: not BridgedPolygonNORI"
    );
    require(
      hasRole(TOKEN_GRANTER_ROLE, sender),
      "lNORI: sender is missing role TOKEN_GRANTER_ROLE"
    );
    address to = abi.decode(userData, (address));
    require(to != address(0), "lNORI: token send missing required userData");
    _depositFor(amount, userData, operatorData);
  }

  /**
   * @notice Claim unlocked tokens and withdraw them to *to* address.
   *
   * @dev This function burns `amount` of `LockedNORI` and transfers `amount`
   * of `BridgedPolygonNORI` from the `LockedNORI` contract's balance to
   * `_msgSender()`'s balance.
   *
   * Enforcement of the availability of wrapped and unlocked tokens
   * for the `_burn` call happens in `_beforeTokenTransfer`
   *
   * ##### Requirements:
   *
   * - Can only be used when the contract is not paused.
   */
  function withdrawTo(address recipient, uint256 amount)
    external
    returns (bool)
  {
    TokenGrant storage grant = _grants[_msgSender()];
    super._burn(_msgSender(), amount, "", "");
    _bridgedPolygonNori.send(
      // solhint-disable-previous-line check-send-result, because this isn't a solidity send
      recipient,
      amount,
      ""
    );
    grant.claimedAmount += amount;
    emit TokensClaimed(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @notice Sets up a vesting + lockup schedule for recipient.
   *
   * @dev This function can be used as an alternative way to set up a grant that doesn't require
   * wrapping BridgedPolygonNORI first.
   *
   * ##### Requirements:
   *
   * - Can only be used when the contract is not paused.
   * - Can only be used when the caller has the `TOKEN_GRANTER_ROLE` role
   */
  function createGrant(
    uint256 amount,
    address recipient,
    uint256 startTime,
    uint256 vestEndTime,
    uint256 unlockEndTime,
    uint256 cliff1Time,
    uint256 cliff2Time,
    uint256 vestCliff1Amount,
    uint256 vestCliff2Amount,
    uint256 unlockCliff1Amount,
    uint256 unlockCliff2Amount
  ) external whenNotPaused onlyRole(TOKEN_GRANTER_ROLE) {
    bytes memory userData = abi.encode(
      recipient,
      startTime,
      vestEndTime,
      unlockEndTime,
      cliff1Time,
      cliff2Time,
      vestCliff1Amount,
      vestCliff2Amount,
      unlockCliff1Amount,
      unlockCliff2Amount
    );
    _createGrant(amount, userData);
  }

  /**
   * @notice Truncates a batch of vesting grants of amounts in a single go
   *
   * @dev Transfers any unvested tokens in `fromAccounts`'s grant to `to` and reduces the total grant size. No change
   * is made to balances that have vested but not yet been claimed whether locked or not.
   *
   * The behavior of this function can be used in two specific ways:
   * - To revoke all remaining revokable tokens in a batch (regardless of time), set amount to 0 in the `amounts` array.
   * - To revoke tokens at the current block timestamp, set atTimes to 0 in the `amounts` array.
   *
   * ##### Requirements:
   *
   * - Can only be used when the caller has the `TOKEN_GRANTER_ROLE` role
   * - The requirements of _beforeTokenTransfer apply to this function
   * - fromAccounts.length == toAccounts.length == atTimes.length == amounts.length
   */
  function batchRevokeUnvestedTokenAmounts(
    address[] calldata fromAccounts,
    address[] calldata toAccounts,
    uint256[] calldata atTimes,
    uint256[] calldata amounts
  ) external whenNotPaused onlyRole(TOKEN_GRANTER_ROLE) {
    require(
      fromAccounts.length == toAccounts.length,
      "lNORI: fromAccounts and toAccounts length mismatch"
    );
    require(
      toAccounts.length == atTimes.length,
      "lNORI: toAccounts and atTimes length mismatch"
    );
    require(
      atTimes.length == amounts.length,
      "lNORI: atTimes and amounts length mismatch"
    );
    for (uint256 i = 0; i < fromAccounts.length; i++) {
      _revokeUnvestedTokens(
        fromAccounts[i],
        toAccounts[i],
        atTimes[i],
        amounts[i]
      );
    }
  }

  /**
   * @notice Number of unvested tokens that were revoked if any.
   */
  function quantityRevokedFrom(address account)
    external
    view
    returns (uint256)
  {
    TokenGrant storage grant = _grants[account];
    return grant.originalAmount - grant.grantAmount;
  }

  /**
   * @notice Vested balance less any claimed amount at current block timestamp.
   */
  function vestedBalanceOf(address account) external view returns (uint256) {
    return _vestedBalanceOf(account, block.timestamp); // solhint-disable-line not-rely-on-time, this is time-dependent
  }

  /**
   * @notice Returns all governing settings for multiple grants
   *
   * @dev If a grant does not exist for an account, the resulting grant will be zeroed out in the return value
   */
  function batchGetGrant(address[] calldata accounts)
    public
    view
    returns (TokenGrantDetail[] memory)
  {
    TokenGrantDetail[] memory grantDetails = new TokenGrantDetail[](
      accounts.length
    );
    for (uint256 i = 0; i < accounts.length; i++) {
      grantDetails[i] = getGrant(accounts[i]);
    }
    return grantDetails;
  }

  /**
   * @notice Returns all governing settings for a grant.
   */
  function getGrant(address account)
    public
    view
    returns (TokenGrantDetail memory)
  {
    TokenGrant storage grant = _grants[account];
    return
      TokenGrantDetail(
        grant.grantAmount,
        account,
        grant.lockupSchedule.startTime,
        grant.vestingSchedule.endTime,
        grant.lockupSchedule.endTime,
        grant.lockupSchedule.cliffs[0].time,
        grant.lockupSchedule.cliffs[1].time,
        grant.vestingSchedule.cliffs[0].amount,
        grant.vestingSchedule.cliffs[1].amount,
        grant.lockupSchedule.cliffs[0].amount,
        grant.lockupSchedule.cliffs[1].amount,
        grant.claimedAmount,
        grant.originalAmount,
        grant.lastRevocationTime,
        grant.lastQuantityRevoked,
        grant.exists
      );
  }

  // todo document expected initialzation state
  function initialize(BridgedPolygonNORI bridgedPolygonNoriAddress)
    public
    initializer
  {
    address[] memory operators = new address[](1);
    operators[0] = _msgSender();
    __Context_init_unchained();
    __ERC165_init_unchained();
    __AccessControl_init_unchained();
    __AccessControlEnumerable_init_unchained();
    __Pausable_init_unchained();
    __ERC777PresetPausablePermissioned_init_unchained();
    __ERC777_init_unchained("Locked NORI", "lNORI", operators);
    _bridgedPolygonNori = bridgedPolygonNoriAddress;
    _ERC1820_REGISTRY.setInterfaceImplementer(
      address(this),
      ERC777_TOKENS_RECIPIENT_HASH,
      address(this)
    );
    _grantRole(TOKEN_GRANTER_ROLE, _msgSender());
  }

  /**
   * @notice Overridden standard ERC777.burn that will always revert
   *
   * @dev This function is not currently supported from external callers so we override it so that we can revert.
   */
  function burn(uint256, bytes memory) public pure override {
    revert("lNORI: burning not supported");
  }

  /**
   * @notice Overridden standard ERC777.operatorBurn that will always revert
   *
   * @dev This function is not currently supported from external callers so we override it so that we can revert.
   */
  function operatorBurn(
    address,
    uint256,
    bytes memory,
    bytes memory
  ) public pure override {
    revert("lNORI: burning not supported");
  }

  /**
   * @notice Unlocked balance less any claimed amount at current block timestamp.
   */
  function unlockedBalanceOf(address account) public view returns (uint256) {
    return _unlockedBalanceOf(account, block.timestamp);
  }

  /**
   * @notice Wraps minting of wrapper token and grant setup.
   *
   * @dev If `startTime` is zero no grant is set up. Satisfies situations where funding of the grant happens over time.
   *
   * @param amount uint256 Quantity of `_bridgedPolygonNori` to deposit
   * @param userData CreateTokenGrantParams or DepositForParams
   * @param operatorData bytes extra information provided by the operator (if any)
   */
  function _depositFor(
    uint256 amount,
    bytes calldata userData,
    bytes calldata operatorData
  ) internal returns (bool) {
    DepositForParams memory params = abi.decode(userData, (DepositForParams)); // todo error handling
    // If a startTime parameter is non-zero then set up a schedule
    // Validation happens inside _createGrant
    if (params.startTime > 0) {
      _createGrant(amount, userData);
    }
    require(
      _grants[params.recipient].exists,
      "lNORI: Cannot deposit without a grant"
    );
    super._mint(params.recipient, amount, userData, operatorData);
    return true;
  }

  /**
   * @notice Sets up a vesting + lockup schedule for recipient (implementation).
   *
   * @dev All grants must include a lockup schedule and can optionally *also*
   * include a vesting schedule.  Tokens are withdrawble once they are
   * vested *and* unlocked.
   *
   * This will be invoked via the `tokensReceived` callback for cases
   * where we have the tokens in hand at the time we set up the grant.
   *
   * It is also callable externally (see `grantTo`) to handle cases
   * where tokens are incrementally deposited after the grant is established.
   */
  function _createGrant(uint256 amount, bytes memory userData) internal {
    CreateTokenGrantParams memory params = abi.decode(
      userData,
      (CreateTokenGrantParams)
    );
    require(
      address(params.recipient) != address(0),
      "lNORI: Recipient cannot be zero address"
    );
    require(
      !hasRole(TOKEN_GRANTER_ROLE, params.recipient),
      "lNORI: Recipient cannot be grant admin"
    );
    require(
      params.startTime < params.unlockEndTime,
      "lNORI: unlockEndTime cannot be before startTime"
    );
    require(
      block.timestamp < params.unlockEndTime,
      "lNORI: unlockEndTime cannot be in the past"
    );
    require(!_grants[params.recipient].exists, "lNORI: Grant already exists");
    TokenGrant storage grant = _grants[params.recipient];
    grant.grantAmount = amount;
    grant.originalAmount = amount;
    grant.exists = true;
    if (params.vestEndTime > params.startTime) {
      require(
        params.vestCliff1Amount >= params.unlockCliff1Amount ||
          params.vestCliff2Amount >= params.unlockCliff2Amount,
        "lNORI: unlock cliff > vest cliff"
      );
      grant.vestingSchedule.totalAmount = amount;
      grant.vestingSchedule.startTime = params.startTime;
      grant.vestingSchedule.endTime = params.vestEndTime;
      grant.vestingSchedule.addCliff(
        params.cliff1Time,
        params.vestCliff1Amount
      );
      grant.vestingSchedule.addCliff(
        params.cliff2Time,
        params.vestCliff2Amount
      );
    }
    grant.lockupSchedule.totalAmount = amount;
    grant.lockupSchedule.startTime = params.startTime;
    grant.lockupSchedule.endTime = params.unlockEndTime;
    grant.lockupSchedule.addCliff(params.cliff1Time, params.unlockCliff1Amount);
    grant.lockupSchedule.addCliff(params.cliff2Time, params.unlockCliff2Amount);
    emit TokenGrantCreated(
      params.recipient,
      amount,
      params.startTime,
      params.vestEndTime,
      params.unlockEndTime
    );
  }

  /**
   * @notice Truncates a vesting grant.
   * This is an *admin* operation callable only by addresses having TOKEN_GRANTER_ROLE
   * (enforced in `batchRevokeUnvestedTokenAmounts`)
   *
   * @dev The implementation never updates underlying schedules (vesting or unlock)
   * but only the grant amount.  This avoids changing the behavior of the grant
   * before the point of revocation.  Anytime a vesting or unlock schedule is in
   * play the corresponding balance functions need to take care to never return
   * more than the grant amount less the claimed amount.
   *
   * Unlike in the `claim` function, here we burn `LockedNORI` from the grant holder but
   * send that `BridgedPolygonNORI` back to Nori's treasury or an address of Nori's
   * choosing (the *to* address).  The *claimedAmount* is not changed because this is
   * not a claim operation.
   */
  function _revokeUnvestedTokens(
    address from,
    address to,
    uint256 atTime,
    uint256 amount
  ) internal {
    require((atTime == 0 && amount > 0) || (atTime > 0 && amount == 0),
      "lNORI: Must specify a revocation time or aan amount not both");
    TokenGrant storage grant = _grants[from];
    require(grant.exists, "lNORI: no grant exists");
    require(
      _hasVestingSchedule(from),
      "lNORI: no vesting schedule for this grant"
    );
    uint256 revocationTime = atTime == 0 && amount > 0
      ? block.timestamp
      : atTime; // atTime of zero indicates a revocation by amount
    require(
      revocationTime >= block.timestamp,
      "lNORI: Revocation cannot be in the past"
    );
    uint256 vestedBalance = grant.vestingSchedule.availableAmount(
      revocationTime
    );
    require(vestedBalance < grant.grantAmount, "lNORI: tokens already vested");
    uint256 revocableQuantity = grant.grantAmount - vestedBalance;
    uint256 quantityRevoked;
    // amount of zero indicates revocation by time.  Amount becomes all remaining tokens
    // at *atTime*
    if (amount > 0) {
      require(amount <= revocableQuantity, "lNORI: too few unvested tokens");
      quantityRevoked = amount;
    } else {
      quantityRevoked = revocableQuantity;
    }
    grant.grantAmount = grant.grantAmount - quantityRevoked;
    grant.lastRevocationTime = revocationTime;
    grant.lastQuantityRevoked = quantityRevoked;
    super._burn(from, quantityRevoked, "", "");
    _bridgedPolygonNori.send(
      // solhint-disable-previous-line check-send-result, because this isn't a solidity send
      to,
      quantityRevoked,
      ""
    );
    emit UnvestedTokensRevoked(revocationTime, from, quantityRevoked);
  }

  /**
   * @notice Hook that is called before send, transfer, mint, and burn. Used used to disable transferring locked nori.
   *
   * @dev Follows the rules of hooks defined [here](
   *  https://docs.openzeppelin.com/contracts/4.x/extending-contracts#rules_of_hooks)
   *
   * ##### Requirements:
   *
   * - the contract must not be paused
   * - the recipient cannot be the zero address (e.g., no burning of tokens is allowed)
   * - One of the following must be true:
   *    - the operation is minting (which should ONLY occur when BridgedPolygonNORI is being wrapped via `_depositFor`)
   *    - the operation is a burn and _all_ of the following must be true:
   *      - the operator has TOKEN_GRANTER_ROLE
   *      - the operator is not operating on their own balance
   *      - the transfer amount is <= the sender's unlocked balance
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256 amount
  ) internal override {
    bool isMinting = from == address(0);
    bool isBurning = to == address(0);
    bool operatorIsGrantAdmin = hasRole(TOKEN_GRANTER_ROLE, operator);
    bool operatorIsNotSender = operator != from;
    bool ownerHasSufficientUnlockedBalance = amount <= unlockedBalanceOf(from);
    if (isBurning && operatorIsNotSender && operatorIsGrantAdmin) {
      require(balanceOf(from) >= amount, "lNORI: insufficient balance");
    } else if (!isMinting) {
      require(ownerHasSufficientUnlockedBalance, "lNORI: insufficient balance");
    }
    return super._beforeTokenTransfer(operator, from, to, amount);
  }

  /**
   * @notice Vested balance less any claimed amount at `atTime` (implementation)
   *
   * @dev Returns true if the there is a grant for *account* with a vesting schedule.
   */
  function _hasVestingSchedule(address account) private view returns (bool) {
    TokenGrant storage grant = _grants[account];
    return grant.exists && grant.vestingSchedule.startTime > 0;
  }

  /**
   * @notice Vested balance less any claimed amount at `atTime` (implementation)
   *
   * @dev If any tokens have been revoked then the schedule (which doesn't get updated) may return more than the total
   * grant amount. This is done to preserve the behavior of the vesting schedule despite a reduction in the total
   * quantity of tokens vesting.  i.o.w The rate of vesting does not change after calling `revokeUnvestedTokens`
   */
  function _vestedBalanceOf(address account, uint256 atTime)
    internal
    view
    returns (uint256)
  {
    TokenGrant storage grant = _grants[account];
    uint256 balance = this.balanceOf(account);
    if (grant.exists) {
      if (_hasVestingSchedule(account)) {
        balance =
          MathUpgradeable.min(
            grant.vestingSchedule.availableAmount(atTime),
            grant.grantAmount
          ) -
          grant.claimedAmount;
      } else {
        balance = grant.grantAmount - grant.claimedAmount;
      }
    }
    return balance;
  }

  /**
   * @notice Unlocked balance less any claimed amount
   *
   * @dev If any tokens have been revoked then the schedule (which doesn't get updated) may return more than the total
   * grant amount. This is done to preserve the behavior of the unlock schedule despite a reduction in the total
   * quantity of tokens vesting.  i.o.w The rate of unlocking does not change after calling `revokeUnvestedTokens`
   */
  function _unlockedBalanceOf(address account, uint256 atTime)
    internal
    view
    returns (uint256)
  {
    TokenGrant storage grant = _grants[account];
    uint256 balance = this.balanceOf(account);
    uint256 vestedBalance = _hasVestingSchedule(account)
      ? grant.vestingSchedule.availableAmount(atTime)
      : grant.grantAmount;
    if (grant.exists) {
      balance =
        MathUpgradeable.min(
          MathUpgradeable.min(
            vestedBalance,
            grant.lockupSchedule.availableAmount(atTime)
          ),
          grant.grantAmount
        ) -
        grant.claimedAmount;
    }
    return balance;
  }

  function _beforeOperatorChange(address, uint256) internal pure override {
    revert("lNORI: operator actions disabled");
  }

  function send(
    address,
    uint256,
    bytes memory
  ) public pure override {
    revert("lNORI: send disabled");
  }

  function operatorSend(
    address,
    address,
    uint256,
    bytes memory,
    bytes memory
  ) public pure override {
    revert("lNORI: operatorSend disabled");
  }

  function transfer(address, uint256) public pure override returns (bool) {
    revert("lNORI: transfer disabled");
  }

  function transferFrom(
    address,
    address,
    uint256
  ) public pure override returns (bool) {
    revert("lNORI: transferFrom disabled");
  }

  function _beforeRoleChange(bytes32 role, address account) override internal virtual {
    super._beforeRoleChange(role, account);
    if (role == TOKEN_GRANTER_ROLE) {
        require (!_grants[account].exists, "lNORI: Cannot assign role to a grant holder address");
    }
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777RecipientUpgradeable {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract ERC777PresetPausablePermissioned is
  ERC777Upgradeable,
  PausableUpgradeable,
  AccessControlEnumerableUpgradeable
{
  /**
   * @notice Role conferring the ability to pause and unpause mutable functions of the contract
   */
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
   * @notice Reserved storage slot for upgradeability
   *
   * @dev This empty reserved space is put in place to allow future versions to add new variables without shifting
   * down storage in the inheritance chain. See more [here](
   * https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)
   */
  uint256[50] private __gap;

  /**
   * @notice An event emitted when a batch of transfers are bundled into a single transaction
   */
  event SentBatch(
    address indexed from,
    address[] recipients,
    uint256[] amounts,
    bytes[] userData,
    bytes[] operatorData,
    bool[] requireReceptionAck
  );

  /**
   * @notice Batches multiple transfers into a single transaction
   *
   * @param recipients address[] list of recipient addresses
   * @param amounts uint256[] list of amounts to transfer
   * @param userData bytes[] list of extra information provided by the token holder (if any)
   * @param operatorData bytes[] list of extra information provided by the operator (if any)
   * @param requireReceptionAck list of requirements (if true, contract recipients are required to implement
   * ERC777TokensRecipient)
   *
   * Emits a SendBatch event.
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   */
  function batchSend(
    address[] memory recipients,
    uint256[] memory amounts,
    bytes[] memory userData,
    bytes[] memory operatorData,
    bool[] memory requireReceptionAck
  ) public {
    require(
      recipients.length == amounts.length,
      "ERC777PresetPausablePermissioned: recipient and amount length mismatch"
    );
    require(
      amounts.length == userData.length,
      "ERC777PresetPausablePermissioned: amounts and userData length mismatch"
    );
    require(
      userData.length == operatorData.length,
      "ERC777PresetPausablePermissioned: userData and operatorData length mismatch"
    );
    require(
      operatorData.length == requireReceptionAck.length,
      "ERC777PresetPausablePermissioned: operatorData and requireReceptionAck length mismatch"
    );
    for (uint256 i = 0; i < recipients.length; i++) {
      _send(
        _msgSender(),
        recipients[i],
        amounts[i],
        userData[i],
        operatorData[i],
        requireReceptionAck[i]
      );
    }
    emit SentBatch(
      _msgSender(),
      recipients,
      amounts,
      userData,
      operatorData,
      requireReceptionAck
    );
  }

  /**
   * @notice See ERC777-approve for details [here](
   * https://docs.openzeppelin.com/contracts/4.x/api/token/erc777#ERC777-approve-address-uint256-)
   *
   * @dev This function is a wrapper around ERC777-approve.
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   * - Accounts cannot have allowance issued by their operators.
   * - If `value` is the maximum `uint256`, the allowance is not updated on `transferFrom`. This is semantically
   * equivalent to an infinite approval.
   */
  function approve(address spender, uint256 value)
    public
    virtual
    override
    whenNotPaused
    returns (bool)
  {
    _beforeOperatorChange(spender, value);
    return super.approve(spender, value);
  }

  /**
   * @notice Authorize an operator to spend on behalf of the sender
   *
   * @dev See IERC777-authorizeOperator for details [here](
   * https://docs.openzeppelin.com/contracts/4.x/api/token/erc777#IERC777-authorizeOperator-address-)
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   */
  function authorizeOperator(address operator) public virtual override {
    _beforeOperatorChange(operator, 0);
    return super.authorizeOperator(operator);
  }

  /**
   * @notice Revoke an operator to disable their ability to spend on behalf of the sender
   *
   * @dev See IERC777-authorizeOperator for details [here](
   * https://docs.openzeppelin.com/contracts/4.x/api/token/erc777#IERC777-authorizeOperator-address-)
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   */
  function revokeOperator(address operator) public virtual override {
    _beforeOperatorChange(operator, 0);
    return super.revokeOperator(operator);
  }

  /**
   * @notice Pauses all functions that can mutate state
   *
   * @dev Used to effectively freeze a contract so that no state updates can occur
   *
   * ##### Requirements:
   *
   * - The caller must have the `PAUSER_ROLE`.
   */
  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @notice Unpauses **all** token transfers.
   *
   * @dev
   *
   * ##### Requirements:
   *
   * - The caller must have the `PAUSER_ROLE`.
   */
  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * @notice Returns the balances of a batch of addresses in a single call
   */
  function balanceOfBatch(address[] memory accounts)
    public
    view
    returns (uint256[] memory)
  {
    uint256[] memory batchBalances = new uint256[](accounts.length);
    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i]);
    }
    return batchBalances;
  }

  // solhint-disable-next-line func-name-mixedcase
  function __ERC777PresetPausablePermissioned_init_unchained()
    internal
    onlyInitializing
  {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(PAUSER_ROLE, _msgSender());
  }

  /**
   * @notice Hook that is called before granting/revoking operator allowances
   *
   * @dev This overrides the behavior of `approve`, `authorizeOperator, and `revokeOperator` with pausable behavior.
   * When the contract is paused, these functions will not be callable. Follows the rules of hooks defined
   * [here](https://docs.openzeppelin.com/contracts/4.x/extending-contracts#rules_of_hooks)
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   */
  function _beforeOperatorChange(address, uint256)
    internal
    virtual
    whenNotPaused
  {} // solhint-disable-line no-empty-blocks

  /**
   * @notice Hook that is called before granting/revoking roles via `grantRole`, `revokeRole`, `renounceRole`
   *
   * @dev This overrides the behavior of `_grantRole`, `_setupRole`, `_revokeRole`, and `_renounceRole` with pausable
   * behavior. When the contract is paused, these functions will not be callable. Follows the rules of hooks
   * defined [here](https://docs.openzeppelin.com/contracts/4.x/extending-contracts#rules_of_hooks)
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   */
  function _beforeRoleChange(bytes32, address) internal virtual whenNotPaused {} // solhint-disable-line no-empty-blocks

  /**
   * @notice A hook that is called before a token transfer occurs.
   *
   * @dev When the contract is paused, these functions will not be callable. Follows the rules of hooks defined
   * [here](https://docs.openzeppelin.com/contracts/4.x/extending-contracts#rules_of_hooks)
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256 amount
  ) internal virtual override whenNotPaused {
    super._beforeTokenTransfer(operator, from, to, amount);
  }

  /**
   * @notice Grants a role to an account.
   *
   * @dev Grants `role` to `account` if the `_beforeRoleGranted` hook is satisfied
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   * - The requirements of _beforeRoleGranted_ must be satisfied.
   */
  function _grantRole(bytes32 role, address account) internal virtual override {
    _beforeRoleChange(role, account);
    super._grantRole(role, account);
  }

  /**
   * @notice Revokes a role from an account.
   *
   * @dev Revokes `role` from `account` if the `_beforeRoleGranted` hook is satisfied
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   * - The requirements of _beforeRoleGranted_ must be satisfied.
   */
  function _revokeRole(bytes32 role, address account)
    internal
    virtual
    override
  {
    _beforeRoleChange(role, account);
    super._revokeRole(role, account);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./NORI.sol";

contract BridgedPolygonNORI is NORI {
  bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

  /**
   * @notice called when token is deposited on root chain
   * @dev Should be callable only by ChildChainManager
   * Should handle deposit by minting the required amount for user
   * Make sure minting is done only by this function
   * @param user user address for whom deposit is being done
   * @param depositData abi encoded amount
   */
  function deposit(address user, bytes calldata depositData)
    external
    onlyRole(DEPOSITOR_ROLE)
  {
    uint256 amount = abi.decode(depositData, (uint256));
    _mint(user, amount, depositData, "");
  }

  /**
   * @notice called when user wants to withdraw tokens back to root chain
   * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
   * @param amount amount of tokens to withdraw
   */
  function withdraw(uint256 amount) external {
    _burn(_msgSender(), amount, "", "");
  }

  /**
   * @notice initializes the BridgedPolygonNORI contract
   */
  function initialize(address childChainManagerProxy) public initializer {
    __BridgedPolygonNORI_init(childChainManagerProxy);
  }

  /**
   * @notice overrides the NORI initializer so that it reverts and is never initialized with a call to the mint function
   */
  function initialize() public override initializer {
    revert("BridgedPolygonNORI: disallowed");
  }

  /**
   * @notice Initializer variant that embeds the linearized calls to all parent initializers.
   * @dev Follows the multiple inheritance initializer rules defined [here](
   * https://docs.openzeppelin.com/contracts/3.x/upgradeable#multiple-inheritance). As a consequence,
   * calling two of these init functions can potentially initialize the same contract twice.
   */
  function __BridgedPolygonNORI_init(
    // solhint-disable-previous-line func-name-mixedcase
    address childChainManagerProxy
  ) internal onlyInitializing {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __AccessControl_init_unchained();
    __AccessControlEnumerable_init_unchained();
    __Pausable_init_unchained();
    __ERC777PresetPausablePermissioned_init_unchained();
    __ERC777_init_unchained("NORI", "NORI", new address[](0));
    __NORI_init_unchained();
    __BridgedPolygonNORI_init_unchained(childChainManagerProxy);
  }

  /**
   * @notice Initializer variant that does **not** embed linearized calls to any parent initializers.
   * @dev Follows the multiple inheritance initializer rules defined [here](
   * https://docs.openzeppelin.com/contracts/3.x/upgradeable#multiple-inheritance). As a consequence,
   * calling two of these init functions can potentially initialize the same contract twice.
   */
  function __BridgedPolygonNORI_init_unchained(
    // solhint-disable-previous-line func-name-mixedcase
    address childChainManagerProxy
  ) internal onlyInitializing {
    _grantRole(DEPOSITOR_ROLE, childChainManagerProxy);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

struct Cliff {
  uint256 time;
  uint256 amount;
}

struct Schedule {
  uint256 startTime;
  uint256 endTime;
  uint256 totalAmount;
  mapping(uint256 => Cliff) cliffs;
  uint256 cliffCount;
  uint256 totalCliffAmount;
}

/**
 * @dev Library encapsulating the logic around timed release schedules with cliffs.
 *
 * Supports an arbitrary number of stepwise cliff releases beyond which the remaining
 * amount is released linearly from the time of the final cliff to the end date.
 *
 * All time parameters are in unixtime for ease of comparison with block.timestamp
 * although all methods on ScheduleUtils take *atTime* as a parameter and do not
 * directly reason about the current block timestamp.
 *
 * See also {ScheduleTestHarness.sol} for a simple use of this library
 * for unit testing purposes.
 *
 * NOTE: All methods are internal so this library gets inlined into the consuming
 * contract and does not need to be deployed separately.
 *
 * Designed to be used i.e.:
 *
 * ```
 *  using ScheduleUtils for Schedule;
 *
 *  mapping(address => Schedule) schedules = Schedules;
 *  Schedule s = schedules[account];
 *  s.startTime = 1644436100;
 *  s.endTime = 1645436100;
 *  s.totalAmount = 1000000;
 *  s.addCliff(1644436200, 50000);
 *  s.amountAvailable(1644436200);
 * ```
 *
 */
library ScheduleUtils {
  /**
   * @dev Adds a cliff defined by *time* and *amount* to *schedule*
   *
   * *time* must be >= any existing cliff, >= schedule.startTime and <= schedule.endTime
   * *amount* must be <= (schedule.totalAmount - total of existing cliffs)
   */
  function addCliff(
    Schedule storage schedule,
    uint256 time,
    uint256 amount
  ) internal {
    uint256 cliffCount = schedule.cliffCount;
    if (schedule.cliffCount == 0) {
      require(
        time >= schedule.startTime,
        "ScheduleUtils: Cliff before schedule start"
      );
    } else {
      require(
        time >= schedule.cliffs[cliffCount - 1].time,
        "ScheduleUtils: Cliffs not chronological"
      );
    }
    require(
      time <= schedule.endTime,
      "ScheduleUtils: Cliffs cannot end after schedule"
    );
    require(
      schedule.totalCliffAmount + amount <= schedule.totalAmount,
      "ScheduleUtils: Cliff amounts exceed total"
    );
    Cliff storage cliff = schedule.cliffs[cliffCount];
    cliff.time = time;
    cliff.amount = amount;
    schedule.cliffCount += 1;
    schedule.totalCliffAmount += amount;
  }

  /**
   * @dev The total of unlocked cliff amounts in *schedule* at time *atTime*
   */
  function cliffAmountsAvailable(Schedule storage schedule, uint256 atTime)
    internal
    view
    returns (uint256)
  {
    uint256 available = 0;
    uint256 cliffCount = schedule.cliffCount;
    for (uint256 i = 0; i < cliffCount; i++) {
      if (atTime >= schedule.cliffs[i].time) {
        available += schedule.cliffs[i].amount;
      }
    }
    return MathUpgradeable.min(schedule.totalAmount, available);
  }

  /**
   * @dev The total amount of the linear (post-cliff) release available at *atTime*
   *
   * Will always be zero prior to the final cliff time and then increases linearly
   * util *schedule.endTime*.
   */
  function linearReleaseAmountAvailable(
    Schedule storage schedule,
    uint256 atTime
  ) internal view returns (uint256) {
    uint256 rampTotalAmount;
    // could happen if unvested tokens were revoked
    if (schedule.totalAmount >= schedule.totalCliffAmount) {
      rampTotalAmount = schedule.totalAmount - schedule.totalCliffAmount;
    } // else 0
    if (atTime >= schedule.endTime) {
      return rampTotalAmount;
    }
    uint256 rampStartTime = schedule.startTime;
    if (schedule.cliffCount > 0) {
      rampStartTime = schedule.cliffs[schedule.cliffCount - 1].time;
    }
    uint256 rampTotalTime = schedule.endTime - rampStartTime;
    return
      atTime < rampStartTime
        ? 0
        : (rampTotalAmount * (atTime - rampStartTime)) / rampTotalTime;
  }

  /**
   * @dev The total amount available at *atTime*
   *
   * Will always be zero prior to *schedule.startTime* and *amount*
   * after *schedule.endTime*.
   *
   * Equivalent to cliffAmountsAvailable + linearReleaseAmountAvailable.
   */
  function availableAmount(Schedule storage schedule, uint256 atTime)
    internal
    view
    returns (uint256)
  {
    return
      cliffAmountsAvailable(schedule, atTime) +
      linearReleaseAmountAvailable(schedule, atTime);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC777/ERC777.sol)

pragma solidity ^0.8.0;

import "./IERC777Upgradeable.sol";
import "./IERC777RecipientUpgradeable.sol";
import "./IERC777SenderUpgradeable.sol";
import "../ERC20/IERC20Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/IERC1820RegistryUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC777} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * Support for ERC20 is included in this contract, as specified by the EIP: both
 * the ERC777 and ERC20 interfaces can be safely used when interacting with it.
 * Both {IERC777-Sent} and {IERC20-Transfer} events are emitted on token
 * movements.
 *
 * Additionally, the {IERC777-granularity} value is hard-coded to `1`, meaning that there
 * are no special restrictions in the amount of tokens that created, moved, or
 * destroyed. This makes integration with ERC20 applications seamless.
 */
contract ERC777Upgradeable is Initializable, ContextUpgradeable, IERC777Upgradeable, IERC20Upgradeable {
    using AddressUpgradeable for address;

    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // This isn't ever read from - it's only used to respond to the defaultOperators query.
    address[] private _defaultOperatorsArray;

    // Immutable, but accounts may revoke them (tracked in __revokedDefaultOperators).
    mapping(address => bool) private _defaultOperators;

    // For each account, a mapping of its operators and revoked default operators.
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    // ERC20-allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev `defaultOperators` may be an empty array.
     */
    function __ERC777_init(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) internal onlyInitializing {
        __ERC777_init_unchained(name_, symbol_, defaultOperators_);
    }

    function __ERC777_init_unchained(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;

        _defaultOperatorsArray = defaultOperators_;
        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _defaultOperators[defaultOperators_[i]] = true;
        }

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }

    /**
     * @dev See {IERC777-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC777-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {ERC20-decimals}.
     *
     * Always returns 18, as per the
     * [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
     */
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC777-granularity}.
     *
     * This implementation always returns `1`.
     */
    function granularity() public view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC777-totalSupply}.
     */
    function totalSupply() public view virtual override(IERC20Upgradeable, IERC777Upgradeable) returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
     */
    function balanceOf(address tokenHolder) public view virtual override(IERC20Upgradeable, IERC777Upgradeable) returns (uint256) {
        return _balances[tokenHolder];
    }

    /**
     * @dev See {IERC777-send}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        _send(_msgSender(), recipient, amount, data, "", true);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Unlike `send`, `recipient` is _not_ required to implement the {IERC777Recipient}
     * interface if it is a contract.
     *
     * Also emits a {Sent} event.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");

        address from = _msgSender();

        _callTokensToSend(from, from, recipient, amount, "", "");

        _move(from, from, recipient, amount, "", "");

        _callTokensReceived(from, from, recipient, amount, "", "", false);

        return true;
    }

    /**
     * @dev See {IERC777-burn}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function burn(uint256 amount, bytes memory data) public virtual override {
        _burn(_msgSender(), amount, data, "");
    }

    /**
     * @dev See {IERC777-isOperatorFor}.
     */
    function isOperatorFor(address operator, address tokenHolder) public view virtual override returns (bool) {
        return
            operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }

    /**
     * @dev See {IERC777-authorizeOperator}.
     */
    function authorizeOperator(address operator) public virtual override {
        require(_msgSender() != operator, "ERC777: authorizing self as operator");

        if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[_msgSender()][operator];
        } else {
            _operators[_msgSender()][operator] = true;
        }

        emit AuthorizedOperator(operator, _msgSender());
    }

    /**
     * @dev See {IERC777-revokeOperator}.
     */
    function revokeOperator(address operator) public virtual override {
        require(operator != _msgSender(), "ERC777: revoking self as operator");

        if (_defaultOperators[operator]) {
            _revokedDefaultOperators[_msgSender()][operator] = true;
        } else {
            delete _operators[_msgSender()][operator];
        }

        emit RevokedOperator(operator, _msgSender());
    }

    /**
     * @dev See {IERC777-defaultOperators}.
     */
    function defaultOperators() public view virtual override returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    /**
     * @dev See {IERC777-operatorSend}.
     *
     * Emits {Sent} and {IERC20-Transfer} events.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), sender), "ERC777: caller is not an operator for holder");
        _send(sender, recipient, amount, data, operatorData, true);
    }

    /**
     * @dev See {IERC777-operatorBurn}.
     *
     * Emits {Burned} and {IERC20-Transfer} events.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), account), "ERC777: caller is not an operator for holder");
        _burn(account, amount, data, operatorData);
    }

    /**
     * @dev See {IERC20-allowance}.
     *
     * Note that operator and allowance concepts are orthogonal: operators may
     * not have allowance, and accounts with allowance may not be operators
     * themselves.
     */
    function allowance(address holder, address spender) public view virtual override returns (uint256) {
        return _allowances[holder][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address holder = _msgSender();
        _approve(holder, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Note that operator and allowance concepts are orthogonal: operators cannot
     * call `transferFrom` (unless they have allowance), and accounts with
     * allowance cannot call `operatorSend` (unless they are operators).
     *
     * Emits {Sent}, {IERC20-Transfer} and {IERC20-Approval} events.
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");
        require(holder != address(0), "ERC777: transfer from the zero address");

        address spender = _msgSender();

        _callTokensToSend(spender, holder, recipient, amount, "", "");

        _spendAllowance(holder, spender, amount);

        _move(spender, holder, recipient, amount, "", "");

        _callTokensReceived(spender, holder, recipient, amount, "", "", false);

        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual {
        _mint(account, amount, userData, operatorData, true);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If `requireReceptionAck` is set to true, and if a send hook is
     * registered for `account`, the corresponding function will be called with
     * `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(account != address(0), "ERC777: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, amount);

        // Update state variables
        _totalSupply += amount;
        _balances[account] += amount;

        _callTokensReceived(operator, address(0), account, amount, userData, operatorData, requireReceptionAck);

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Send tokens
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(from != address(0), "ERC777: send from the zero address");
        require(to != address(0), "ERC777: send to the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, to, amount, userData, operatorData);

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }

    /**
     * @dev Burn tokens
     * @param from address token holder address
     * @param amount uint256 amount of tokens to burn
     * @param data bytes extra information provided by the token holder
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _burn(
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal virtual {
        require(from != address(0), "ERC777: burn from the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, address(0), amount, data, operatorData);

        _beforeTokenTransfer(operator, from, address(0), amount);

        // Update state variables
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: burn amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _totalSupply -= amount;

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        _beforeTokenTransfer(operator, from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    /**
     * @dev See {ERC20-_approve}.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function _approve(
        address holder,
        address spender,
        uint256 value
    ) internal virtual {
        require(holder != address(0), "ERC777: approve from the zero address");
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    /**
     * @dev Call from.tokensToSend() if the interface is registered
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(from, _TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777SenderUpgradeable(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }

    /**
     * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
     * tokensReceived() was not registered for the recipient
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(to, _TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777RecipientUpgradeable(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (requireReceptionAck) {
            require(!to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC777: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes
     * calls to {send}, {transfer}, {operatorSend}, minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Sender.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 * their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777SenderUpgradeable {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820RegistryUpgradeable {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
library EnumerableSetUpgradeable {
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
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./ERC777PresetPausablePermissioned.sol";

contract NORI is ERC777PresetPausablePermissioned {
  function initialize() public virtual initializer {
    __NORI_init();
    _mint(
      _msgSender(),
      500_000_000 * 10**18, // 500,000,000 NORI
      "",
      ""
    );
  }

  /**
   * @notice Initializer variant that embeds the linearized calls to all parent initializers.
   * @dev Follows the multiple inheritance initializer rules defined [here](
   * https://docs.openzeppelin.com/contracts/3.x/upgradeable#multiple-inheritance). As a consequence,
   * calling two of these init functions can potentially initialize the same contract twice.
   */
  function __NORI_init() internal onlyInitializing {
    // solhint-disable-previous-line func-name-mixedcase
    __Context_init_unchained();
    __ERC165_init_unchained();
    __AccessControl_init_unchained();
    __AccessControlEnumerable_init_unchained();
    __Pausable_init_unchained();
    __ERC777PresetPausablePermissioned_init_unchained();
    __ERC777_init_unchained("NORI", "NORI", new address[](0));
    __NORI_init_unchained();
  }

  /**
   * @notice Initializer variant that does **not** embed linearized calls to any parent initializers.
   * @dev Follows the multiple inheritance initializer rules defined [here](
   * https://docs.openzeppelin.com/contracts/3.x/upgradeable#multiple-inheritance). As a consequence,
   * calling two of these init functions can potentially initialize the same contract twice.
   */
  function __NORI_init_unchained() internal onlyInitializing {
    // solhint-disable-previous-line no-empty-blocks, func-name-mixedcase
  }
}