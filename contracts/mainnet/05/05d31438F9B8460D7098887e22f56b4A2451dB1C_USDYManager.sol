/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */

pragma solidity 0.8.16;

import "contracts/RWAHubOffChainRedemptions.sol";
import "contracts/usdy/blocklist/BlocklistClient.sol";
import "contracts/sanctions/SanctionsListClient.sol";
import "contracts/interfaces/IUSDYManager.sol";

contract USDYManager is
  RWAHubOffChainRedemptions,
  BlocklistClient,
  SanctionsListClient,
  IUSDYManager
{
  bytes32 public constant TIMESTAMP_SETTER_ROLE =
    keccak256("TIMESTAMP_SETTER_ROLE");

  mapping(bytes32 => uint256) public depositIdToClaimableTimestamp;

  constructor(
    address _collateral,
    address _rwa,
    address managerAdmin,
    address pauser,
    address _assetSender,
    address _feeRecipient,
    uint256 _minimumDepositAmount,
    uint256 _minimumRedemptionAmount,
    address blocklist,
    address sanctionsList
  )
    RWAHubOffChainRedemptions(
      _collateral,
      _rwa,
      managerAdmin,
      pauser,
      _assetSender,
      _feeRecipient,
      _minimumDepositAmount,
      _minimumRedemptionAmount
    )
    BlocklistClient(blocklist)
    SanctionsListClient(sanctionsList)
  {}

  /**
   * @notice Function to enforce blocklist and sanctionslist restrictions to be
   *         implemented on calls to `requestSubscription` and
   *         `claimRedemption`
   *
   * @param account The account to check blocklist and sanctions list status
   *                for
   */
  function _checkRestrictions(address account) internal view override {
    if (_isBlocked(account)) {
      revert BlockedAccount();
    }
    if (_isSanctioned(account)) {
      revert SanctionedAccount();
    }
  }

  /**
   * @notice Internal hook that is called by `claimMint` to enforce the time
   *         at which a user can claim their USDY
   *
   * @param depositId The depositId to check the claimable timestamp for
   *
   * @dev This function will call the `_claimMint` function in the parent
   *      once USDY-specific checks have been made
   */
  function _claimMint(bytes32 depositId) internal virtual override {
    if (depositIdToClaimableTimestamp[depositId] == 0) {
      revert ClaimableTimestampNotSet();
    }

    if (depositIdToClaimableTimestamp[depositId] > block.timestamp) {
      revert MintNotYetClaimable();
    }

    super._claimMint(depositId);
    delete depositIdToClaimableTimestamp[depositId];
  }

  /**
   * @notice Update blocklist address
   *
   * @param blocklist The new blocklist address
   */
  function setBlocklist(
    address blocklist
  ) external override onlyRole(MANAGER_ADMIN) {
    _setBlocklist(blocklist);
  }

  /**
   * @notice Update sanctions list address
   *
   * @param sanctionsList The new sanctions list address
   */
  function setSanctionsList(
    address sanctionsList
  ) external override onlyRole(MANAGER_ADMIN) {
    _setSanctionsList(sanctionsList);
  }

  /**
   * @notice Set the claimable timestamp for a list of depositIds
   *
   * @param claimTimestamp The timestamp at which the deposit can be claimed
   * @param depositIds The depositIds to set the claimable timestamp for
   */
  function setClaimableTimestamp(
    uint256 claimTimestamp,
    bytes32[] calldata depositIds
  ) external onlyRole(TIMESTAMP_SETTER_ROLE) {
    if (claimTimestamp < block.timestamp) {
      revert ClaimableTimestampInPast();
    }

    uint256 depositsSize = depositIds.length;
    for (uint256 i; i < depositsSize; ++i) {
      depositIdToClaimableTimestamp[depositIds[i]] = claimTimestamp;
      emit ClaimableTimestampSet(claimTimestamp, depositIds[i]);
    }
  }
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */

pragma solidity 0.8.16;

import "contracts/RWAHub.sol";
import "contracts/interfaces/IRWAHubOffChainRedemptions.sol";

abstract contract RWAHubOffChainRedemptions is
  RWAHub,
  IRWAHubOffChainRedemptions
{
  // To enable and disable off chain redemptions
  bool public offChainRedemptionPaused;

  // Minimum off chain redemption amount
  uint256 public minimumOffChainRedemptionAmount;

  constructor(
    address _collateral,
    address _rwa,
    address managerAdmin,
    address pauser,
    address _assetSender,
    address _feeRecipient,
    uint256 _minimumDepositAmount,
    uint256 _minimumRedemptionAmount
  )
    RWAHub(
      _collateral,
      _rwa,
      managerAdmin,
      pauser,
      _assetSender,
      _feeRecipient,
      _minimumDepositAmount,
      _minimumRedemptionAmount
    )
  {
    // Default to the same minimum redemption amount as for On-Chain
    // redemptions.
    minimumOffChainRedemptionAmount = _minimumRedemptionAmount;
  }

  /**
   * @notice Request a redemption to be serviced off chain.
   *
   * @param amountRWATokenToRedeem The requested redemption amount
   * @param offChainDestination    A hash of the destination to which
   *                               the request should be serviced to.
   */
  function requestRedemptionServicedOffchain(
    uint256 amountRWATokenToRedeem,
    bytes32 offChainDestination
  ) external nonReentrant ifNotPaused(offChainRedemptionPaused) {
    if (amountRWATokenToRedeem < minimumRedemptionAmount) {
      revert RedemptionTooSmall();
    }

    bytes32 redemptionId = bytes32(redemptionRequestCounter++);

    rwa.burnFrom(msg.sender, amountRWATokenToRedeem);

    emit RedemptionRequestedServicedOffChain(
      redemptionId,
      msg.sender,
      amountRWATokenToRedeem,
      offChainDestination
    );
  }

  /**
   * @notice Function to pause off chain redemptoins
   */
  function pauseOffChainRedemption() external onlyRole(PAUSER_ADMIN) {
    offChainRedemptionPaused = true;
    emit OffChainRedemptionPaused();
  }

  /**
   * @notice Function to unpause off chain redemptoins
   */
  function unpauseOffChainRedemption() external onlyRole(MANAGER_ADMIN) {
    offChainRedemptionPaused = false;
    emit OffChainRedemptionUnpaused();
  }

  /**
   * @notice Admin Function to set the minimum off chain redemption amount
   *
   * @param _minimumOffChainRedemptionAmount The new minimum off chain
   *                                         redemption amount
   */
  function setOffChainRedemptionMinimum(
    uint256 _minimumOffChainRedemptionAmount
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldMinimum = minimumOffChainRedemptionAmount;
    minimumOffChainRedemptionAmount = _minimumOffChainRedemptionAmount;
    emit OffChainRedemptionMinimumSet(
      oldMinimum,
      _minimumOffChainRedemptionAmount
    );
  }
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "contracts/external/chainalysis/ISanctionsList.sol";
import "contracts/sanctions/ISanctionsListClient.sol";

/**
 * @title SanctionsListClient
 * @author Ondo Finance
 * @notice This abstract contract manages state required for clients
 *         of the sanctions list
 */
abstract contract SanctionsListClient is ISanctionsListClient {
  // Sanctions list address
  ISanctionsList public override sanctionsList;

  /**
   * @notice Constructor
   *
   * @param _sanctionsList Address of the sanctions list contract
   */
  constructor(address _sanctionsList) {
    _setSanctionsList(_sanctionsList);
  }

  /**
   * @notice Sets the sanctions list address for this client
   *
   * @param _sanctionsList The new sanctions list address
   */
  function _setSanctionsList(address _sanctionsList) internal {
    if (_sanctionsList == address(0)) {
      revert SanctionsListZeroAddress();
    }
    address oldSanctionsList = address(sanctionsList);
    sanctionsList = ISanctionsList(_sanctionsList);
    emit SanctionsListSet(oldSanctionsList, _sanctionsList);
  }

  /**
   * @notice Checks whether an address has been sanctioned
   *
   * @param account The account to check
   */
  function _isSanctioned(address account) internal view returns (bool) {
    return sanctionsList.isSanctioned(account);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

/**SPDX-License-Identifier: BUSL-1.1
      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐
 */
pragma solidity 0.8.16;

interface IUSDYManager {
  function setClaimableTimestamp(
    uint256 claimDate,
    bytes32[] calldata depositIds
  ) external;

  /**
   * @notice Event emitted when claimable timestamp is set
   *
   * @param claimTimestamp The timestamp at which the mint can be claimed
   * @param depositId      The depositId that can claim at the given 
                           `claimTimestamp`
   */
  event ClaimableTimestampSet(
    uint256 indexed claimTimestamp,
    bytes32 indexed depositId
  );

  /// ERRORS ///
  error MintNotYetClaimable();
  error ClaimableTimestampInPast();
  error ClaimableTimestampNotSet();
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "contracts/interfaces/IBlocklist.sol";
import "contracts/interfaces/IBlocklistClient.sol";

/**
 * @title BlocklistClient
 * @author Ondo Finance
 * @notice This abstract contract manages state for blocklist clients
 */
abstract contract BlocklistClient is IBlocklistClient {
  // blocklist address
  IBlocklist public override blocklist;

  /**
   * @notice Constructor
   *
   * @param _blocklist Address of the blocklist contract
   */
  constructor(address _blocklist) {
    _setBlocklist(_blocklist);
  }

  /**
   * @notice Sets the blocklist address for this client
   *
   * @param _blocklist The new blocklist address
   */
  function _setBlocklist(address _blocklist) internal {
    if (_blocklist == address(0)) {
      revert BlocklistZeroAddress();
    }
    address oldBlocklist = address(blocklist);
    blocklist = IBlocklist(_blocklist);
    emit BlocklistSet(oldBlocklist, _blocklist);
  }

  /**
   * @notice Checks whether an address has been blocked
   *
   * @param account The account to check
   */
  function _isBlocked(address account) internal view returns (bool) {
    return blocklist.isBlocked(account);
  }
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "contracts/interfaces/IPricer.sol";
import "contracts/interfaces/IRWALike.sol";
import "contracts/external/openzeppelin/contracts/token/IERC20.sol";
import "contracts/external/openzeppelin/contracts/token/SafeERC20.sol";
import "contracts/interfaces/IRWAHub.sol";

// Additional Dependencies
import "contracts/external/openzeppelin/contracts/token/IERC20Metadata.sol";
import "contracts/external/openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "contracts/external/openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract RWAHub is IRWAHub, ReentrancyGuard, AccessControlEnumerable {
  using SafeERC20 for IERC20;
  // RWA Token contract
  IRWALike public immutable rwa;
  // Pointer to Pricer
  IPricer public pricer;
  // Address to receive deposits
  address public constant assetRecipient =
    0x3d7a5eDFCDCA0f9FDD066Fb94D306f2b4Cc7DB17;
  // Address to send redemptions
  address public assetSender;
  // Address fee recipient
  address public feeRecipient;
  // Mapping from deposit Id -> Depositor
  mapping(bytes32 => Depositor) public depositIdToDepositor;
  // Mapping from redemptionId -> Redeemer
  mapping(bytes32 => Redeemer) public redemptionIdToRedeemer;

  /// @dev Mint/Redeem Parameters
  // Minimum amount that must be deposited to mint the RWA token
  // Denoted in decimals of `collateral`
  uint256 public minimumDepositAmount;

  // Minimum amount that must be redeemed for a withdraw request
  uint256 public minimumRedemptionAmount;

  // Minting fee specified in basis points
  uint256 public mintFee = 0;

  // Redemption fee specified in basis points
  uint256 public redemptionFee = 0;

  // The asset accepted by the RWAHub
  IERC20 public collateral;

  // Decimal multiplier representing the difference between `rwa` decimals
  // In `collateral` token decimals
  uint256 public decimalsMultiplier;

  // Deposit counter to map subscription requests to
  uint256 public subscriptionRequestCounter = 1;

  // Redemption Id to map from
  uint256 public redemptionRequestCounter = 1;

  // Helper constant that allows us to specify basis points in calculations
  uint256 public constant BPS_DENOMINATOR = 10_000;

  // Pause variables
  bool redemptionPaused;
  bool subscriptionPaused;

  /// @dev Role based access control roles
  bytes32 public constant MANAGER_ADMIN = keccak256("MANAGER_ADMIN");
  bytes32 public constant MINTER_ADMIN = keccak256("MINTER_ADMIN");
  bytes32 public constant PAUSER_ADMIN = keccak256("PAUSER_ADMIN");
  bytes32 public constant PRICE_ID_SETTER_ROLE =
    keccak256("PRICE_ID_SETTER_ROLE");
  bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

  /// @notice constructor
  constructor(
    address _collateral,
    address _rwa,
    address managerAdmin,
    address pauser,
    address _assetSender,
    address _feeRecipient,
    uint256 _minimumDepositAmount,
    uint256 _minimumRedemptionAmount
  ) {
    if (_collateral == address(0)) {
      revert CollateralCannotBeZero();
    }
    if (_rwa == address(0)) {
      revert RWACannotBeZero();
    }
    if (_assetSender == address(0)) {
      revert AssetSenderCannotBeZero();
    }
    if (_feeRecipient == address(0)) {
      revert FeeRecipientCannotBeZero();
    }

    _grantRole(DEFAULT_ADMIN_ROLE, managerAdmin);
    _grantRole(MANAGER_ADMIN, managerAdmin);
    _grantRole(PAUSER_ADMIN, pauser);
    _setRoleAdmin(PAUSER_ADMIN, MANAGER_ADMIN);
    _setRoleAdmin(PRICE_ID_SETTER_ROLE, MANAGER_ADMIN);
    _setRoleAdmin(RELAYER_ROLE, MANAGER_ADMIN);

    collateral = IERC20(_collateral);
    rwa = IRWALike(_rwa);
    feeRecipient = _feeRecipient;
    assetSender = _assetSender;
    minimumDepositAmount = _minimumDepositAmount;
    minimumRedemptionAmount = _minimumRedemptionAmount;

    decimalsMultiplier =
      10 **
        (IERC20Metadata(_rwa).decimals() -
          IERC20Metadata(_collateral).decimals());
  }

  /*//////////////////////////////////////////////////////////////
                  Subscription/Redemption Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Function used by users to request subscription to the fund
   *
   * @param amount The amount of collateral one wished to deposit
   */
  function requestSubscription(
    uint256 amount
  )
    external
    virtual
    nonReentrant
    ifNotPaused(subscriptionPaused)
    checkRestrictions(msg.sender)
  {
    if (amount < minimumDepositAmount) {
      revert DepositTooSmall();
    }

    uint256 feesInCollateral = _getMintFees(amount);
    uint256 depositAmountAfterFee = amount - feesInCollateral;

    // Link the depositor to their deposit ID
    bytes32 depositId = bytes32(subscriptionRequestCounter);
    depositIdToDepositor[depositId] = Depositor(
      msg.sender,
      depositAmountAfterFee,
      0
    );

    // Increment the deposit counter
    ++subscriptionRequestCounter;

    if (feesInCollateral > 0) {
      collateral.safeTransferFrom(msg.sender, feeRecipient, feesInCollateral);
    }

    collateral.safeTransferFrom(
      msg.sender,
      assetRecipient,
      depositAmountAfterFee
    );

    emit MintRequested(
      msg.sender,
      depositId,
      amount,
      depositAmountAfterFee,
      feesInCollateral
    );
  }

  /**
   * @notice Function used to claim tokens corresponding to a deposit request
   *
   * @param depositIds An array containing the deposit Ids one wishes to claim
   *
   * @dev Implicitly does all transfer checks present in underlying `rwa`
   * @dev The priceId corresponding to a given depositId must be set prior to
   *      claiming a mint
   */
  function claimMint(
    bytes32[] calldata depositIds
  ) external virtual nonReentrant ifNotPaused(subscriptionPaused) {
    uint256 depositsSize = depositIds.length;
    for (uint256 i = 0; i < depositsSize; ++i) {
      _claimMint(depositIds[i]);
    }
  }

  /**
   * @notice Internal claim mint helper
   *
   * @dev This function can be overriden to implement custom claiming logic
   */
  function _claimMint(bytes32 depositId) internal virtual {
    Depositor memory depositor = depositIdToDepositor[depositId];
    // Revert if priceId is not set
    if (depositor.priceId == 0) {
      revert PriceIdNotSet();
    }

    uint256 price = pricer.getPrice(depositor.priceId);
    uint256 rwaOwed = _getMintAmountForPrice(
      depositor.amountDepositedMinusFees,
      price
    );

    delete depositIdToDepositor[depositId];
    rwa.mint(depositor.user, rwaOwed);

    emit MintCompleted(
      depositor.user,
      depositId,
      rwaOwed,
      depositor.amountDepositedMinusFees,
      price,
      depositor.priceId
    );
  }

  /**
   * @notice Function used by users to request a redemption from the fund
   *
   * @param amount The amount (in units of `rwa`) that a user wishes to redeem
   *               from the fund
   */
  function requestRedemption(
    uint256 amount
  ) external virtual nonReentrant ifNotPaused(redemptionPaused) {
    if (amount < minimumRedemptionAmount) {
      revert RedemptionTooSmall();
    }
    bytes32 redemptionId = bytes32(redemptionRequestCounter);
    redemptionIdToRedeemer[redemptionId] = Redeemer(msg.sender, amount, 0);

    ++redemptionRequestCounter;

    rwa.burnFrom(msg.sender, amount);

    emit RedemptionRequested(msg.sender, redemptionId, amount);
  }

  /**
   * @notice Function to claim collateral corresponding to a redemption request
   *
   * @param redemptionIds an Array of redemption Id's which ought to fulfilled
   *
   * @dev Implicitly does all checks present in underlying `rwa`
   * @dev The price Id corresponding to a redemptionId must be set prior to
   *      claiming a redemption
   */
  function claimRedemption(
    bytes32[] calldata redemptionIds
  ) external virtual nonReentrant ifNotPaused(redemptionPaused) {
    uint256 fees;
    uint256 redemptionsSize = redemptionIds.length;
    for (uint256 i = 0; i < redemptionsSize; ++i) {
      Redeemer memory member = redemptionIdToRedeemer[redemptionIds[i]];
      _checkRestrictions(member.user);
      if (member.priceId == 0) {
        // Then the price for this redemption has not been set
        revert PriceIdNotSet();
      }

      uint256 price = pricer.getPrice(member.priceId);
      uint256 collateralDue = _getRedemptionAmountForRwa(
        member.amountRwaTokenBurned,
        price
      );
      uint256 fee = _getRedemptionFees(collateralDue);
      uint256 collateralDuePostFees = collateralDue - fee;
      fees += fee;

      delete redemptionIdToRedeemer[redemptionIds[i]];

      collateral.safeTransferFrom(
        assetSender,
        member.user,
        collateralDuePostFees
      );

      emit RedemptionCompleted(
        member.user,
        redemptionIds[i],
        member.amountRwaTokenBurned,
        collateralDuePostFees,
        price
      );
    }
    if (fees > 0) {
      collateral.safeTransferFrom(assetSender, feeRecipient, fees);
    }
  }

  /*//////////////////////////////////////////////////////////////
                         Relayer Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Adds a deposit proof to the contract
   *
   * @param txHash                The transaction hash of the deposit
   * @param user                  The address of the user who made the deposit
   * @param depositAmountAfterFee The amount of the deposit after fees
   * @param feeAmount             The amount of the fees taken
   * @param timestamp             The timestamp of the deposit
   *
   * @dev txHash is used as the depositId in storage
   * @dev All amounts are in decimals of `collateral`
   */
  function addProof(
    bytes32 txHash,
    address user,
    uint256 depositAmountAfterFee,
    uint256 feeAmount,
    uint256 timestamp
  ) external override onlyRole(RELAYER_ROLE) checkRestrictions(user) {
    if (depositIdToDepositor[txHash].user != address(0)) {
      revert DepositProofAlreadyExists();
    }
    depositIdToDepositor[txHash] = Depositor(user, depositAmountAfterFee, 0);
    emit DepositProofAdded(
      txHash,
      user,
      depositAmountAfterFee,
      feeAmount,
      timestamp
    );
  }

  /*//////////////////////////////////////////////////////////////
                           PriceId Setters
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Admin function to associate a depositId with a given Price Id
   *
   * @param depositIds an Array of deposit Ids to be associated
   * @param priceIds   an Array of price Ids to be associated
   *
   * @dev Array size must match
   */
  function setPriceIdForDeposits(
    bytes32[] calldata depositIds,
    uint256[] calldata priceIds
  ) external virtual onlyRole(PRICE_ID_SETTER_ROLE) {
    uint256 depositsSize = depositIds.length;
    if (depositsSize != priceIds.length) {
      revert ArraySizeMismatch();
    }
    for (uint256 i = 0; i < depositsSize; ++i) {
      if (depositIdToDepositor[depositIds[i]].user == address(0)) {
        revert DepositorNull();
      }
      depositIdToDepositor[depositIds[i]].priceId = priceIds[i];
      emit PriceIdSetForDeposit(depositIds[i], priceIds[i]);
    }
  }

  /**
   * @notice Admin function to associate redemptionId with a given priceId
   *
   * @param redemptionIds an Array of redemptionIds to associate
   * @param priceIds  an Array of priceIds to associate
   */
  function setPriceIdForRedemptions(
    bytes32[] calldata redemptionIds,
    uint256[] calldata priceIds
  ) external virtual onlyRole(PRICE_ID_SETTER_ROLE) {
    uint256 redemptionsSize = redemptionIds.length;
    if (redemptionsSize != priceIds.length) {
      revert ArraySizeMismatch();
    }
    for (uint256 i = 0; i < redemptionsSize; ++i) {
      redemptionIdToRedeemer[redemptionIds[i]].priceId = priceIds[i];
      emit PriceIdSetForRedemption(redemptionIds[i], priceIds[i]);
    }
  }

  /*//////////////////////////////////////////////////////////////
                           Admin Setters
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Admin function to overwrite entries in the depoitIdToDepositor
   *         mapping
   *
   * @param depositIdToOverwrite  The depositId of the entry we wish to
   *                              overwrite
   * @param user                  The user for the new entry
   * @param depositAmountAfterFee The deposit value for the new entry
   * @param priceId               The priceId to be associated with the new
   *                              entry
   */
  function overwriteDepositor(
    bytes32 depositIdToOverwrite,
    address user,
    uint256 depositAmountAfterFee,
    uint256 priceId
  ) external onlyRole(MANAGER_ADMIN) {
    Depositor memory oldDepositor = depositIdToDepositor[depositIdToOverwrite];
    depositIdToDepositor[depositIdToOverwrite] = Depositor(
      user,
      depositAmountAfterFee,
      priceId
    );

    emit DepositorOverwritten(
      depositIdToOverwrite,
      oldDepositor.user,
      user,
      oldDepositor.priceId,
      priceId,
      oldDepositor.amountDepositedMinusFees,
      depositAmountAfterFee
    );
  }

  /**
   * @notice Admin function to overwrite entries in the redemptionIdToRedeemer
   *         mapping
   *
   * @param redemptionIdToOverwrite The redemptionId of the entry we wish to
   *                                overwrite
   * @param user                    The user for the new entry
   * @param rwaTokenAmountBurned        The burn amount for the new entry
   * @param priceId                 The priceID to be associated with the new
   *                                entry
   */
  function overwriteRedeemer(
    bytes32 redemptionIdToOverwrite,
    address user,
    uint256 rwaTokenAmountBurned,
    uint256 priceId
  ) external onlyRole(MANAGER_ADMIN) {
    Redeemer memory oldRedeemer = redemptionIdToRedeemer[
      redemptionIdToOverwrite
    ];
    redemptionIdToRedeemer[redemptionIdToOverwrite] = Redeemer(
      user,
      rwaTokenAmountBurned,
      priceId
    );
    emit RedeemerOverwritten(
      redemptionIdToOverwrite,
      oldRedeemer.user,
      user,
      oldRedeemer.priceId,
      priceId,
      oldRedeemer.amountRwaTokenBurned,
      rwaTokenAmountBurned
    );
  }

  /**
   * @notice Admin function to set the minimum amount required for a redemption
   *
   * @param _minimumRedemptionAmount The minimum amount required to submit a redemption
   *                        request
   */
  function setMinimumRedemptionAmount(
    uint256 _minimumRedemptionAmount
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldRedeemMinimum = minimumRedemptionAmount;
    minimumRedemptionAmount = _minimumRedemptionAmount;
    emit MinimumRedemptionAmountSet(oldRedeemMinimum, _minimumRedemptionAmount);
  }

  /**
   * @notice Admin function to set the minimum amount required for a deposit
   *
   * @param minDepositAmount The minimum amount required to submit a deposit
   *                         request
   */
  function setMinimumDepositAmount(
    uint256 minDepositAmount
  ) external onlyRole(MANAGER_ADMIN) {
    if (minDepositAmount < BPS_DENOMINATOR) {
      revert MinimumDepositAmountTooSmall();
    }
    uint256 oldMinimumDepositAmount = minimumDepositAmount;
    minimumDepositAmount = minDepositAmount;
    emit MinimumDepositAmountSet(oldMinimumDepositAmount, minDepositAmount);
  }

  /**
   * @notice Admin function to set the mint fee
   *
   * @param _mintFee The new mint fee specified in basis points
   *
   * @dev The maximum fee that can be set is 10_000 bps, or 100%
   */
  function setMintFee(uint256 _mintFee) external onlyRole(MANAGER_ADMIN) {
    if (_mintFee > BPS_DENOMINATOR) {
      revert FeeTooLarge();
    }
    uint256 oldMintFee = mintFee;
    mintFee = _mintFee;
    emit MintFeeSet(oldMintFee, _mintFee);
  }

  /**
   * @notice Admin function to set the redeem fee
   *
   * @param _redemptionFee The new redeem fee specified in basis points
   *
   * @dev The maximum fee that can be set is 10_000 bps, or 100%
   */
  function setRedemptionFee(
    uint256 _redemptionFee
  ) external onlyRole(MANAGER_ADMIN) {
    if (_redemptionFee > BPS_DENOMINATOR) {
      revert FeeTooLarge();
    }
    uint256 oldRedeemFee = redemptionFee;
    redemptionFee = _redemptionFee;
    emit RedemptionFeeSet(oldRedeemFee, _redemptionFee);
  }

  /**
   * @notice Admin function to set the address of the Pricer contract
   *
   * @param newPricer The address of the new pricer contract
   */
  function setPricer(address newPricer) external onlyRole(MANAGER_ADMIN) {
    address oldPricer = address(pricer);
    pricer = IPricer(newPricer);
    emit NewPricerSet(oldPricer, newPricer);
  }

  /**
   * @notice Admin function to set the address of `feeRecipient`
   *
   * @param newFeeRecipient The address of the new `feeRecipient`
   */
  function setFeeRecipient(
    address newFeeRecipient
  ) external onlyRole(MANAGER_ADMIN) {
    address oldFeeRecipient = feeRecipient;
    feeRecipient = newFeeRecipient;
    emit FeeRecipientSet(oldFeeRecipient, feeRecipient);
  }

  /**
   * @notice Admin function to set the address of `assetSender`
   *
   * @param newAssetSender The address of the new `assetSender`
   */
  function setAssetSender(
    address newAssetSender
  ) external onlyRole(MANAGER_ADMIN) {
    address oldAssetSender = assetSender;
    assetSender = newAssetSender;
    emit AssetSenderSet(oldAssetSender, newAssetSender);
  }

  /*//////////////////////////////////////////////////////////////
                            Pause Utils
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Modifier to check if a feature is paused
   *
   * @param feature The feature to check if paused
   */
  modifier ifNotPaused(bool feature) {
    if (feature) {
      revert FeaturePaused();
    }
    _;
  }

  /**
   * @notice Function to pause subscription to RWAHub
   */
  function pauseSubscription() external onlyRole(PAUSER_ADMIN) {
    subscriptionPaused = true;
    emit SubscriptionPaused(msg.sender);
  }

  /**
   * @notice Function to pause redemptions to RWAHub
   */
  function pauseRedemption() external onlyRole(PAUSER_ADMIN) {
    redemptionPaused = true;
    emit RedemptionPaused(msg.sender);
  }

  /**
   * @notice Function to unpause subscriptions to RWAHub
   */
  function unpauseSubscription() external onlyRole(MANAGER_ADMIN) {
    subscriptionPaused = false;
    emit SubscriptionUnpaused(msg.sender);
  }

  /**
   * @notice Function to unpause redemptions to RWAHub
   */
  function unpauseRedemption() external onlyRole(MANAGER_ADMIN) {
    redemptionPaused = false;
    emit RedemptionUnpaused(msg.sender);
  }

  /*//////////////////////////////////////////////////////////////
                      Check Restriction Utils
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Modifier to check restrictions status of an account
   *
   * @param account The account to check
   */
  modifier checkRestrictions(address account) {
    _checkRestrictions(account);
    _;
  }

  /**
   * @notice internal function to check restriction status
   *         of an address
   *
   * @param account The account to check restriction status for
   *
   * @dev This function is virtual to be overridden by child contract
   *      to check restrictions on a more granular level
   */
  function _checkRestrictions(address account) internal view virtual;

  /*//////////////////////////////////////////////////////////////
                           Math Utils
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Given amount of `collateral`, returns how much in fees
   *         are owed
   *
   *
   * @param collateralAmount Amount `collateral` to calculate fees
   *                         (in decimals of `collateral`)
   */
  function _getMintFees(
    uint256 collateralAmount
  ) internal view returns (uint256) {
    return (collateralAmount * mintFee) / BPS_DENOMINATOR;
  }

  /**
   * @notice Given amount of `collateral`, returns how much in fees
   *         are owed
   *
   * @param collateralAmount Amount of `collateral` to calculate fees
   *                         (in decimals of `collateral`)
   */
  function _getRedemptionFees(
    uint256 collateralAmount
  ) internal view returns (uint256) {
    return (collateralAmount * redemptionFee) / BPS_DENOMINATOR;
  }

  /**
   * @notice Given a deposit amount and priceId, returns the amount
   *         of `rwa` due
   *
   * @param depositAmt The amount deposited in units of `collateral`
   * @param price      The price associated with this deposit
   */
  function _getMintAmountForPrice(
    uint256 depositAmt,
    uint256 price
  ) internal view returns (uint256 rwaAmountOut) {
    uint256 amountE36 = _scaleUp(depositAmt) * 1e18;
    // Will revert with div by 0 if price not defined for a priceId
    rwaAmountOut = amountE36 / price;
  }

  /**
   * @notice Given a redemption amount and a priceId, returns the amount
   *         of `collateral` due
   *
   * @param rwaTokenAmountBurned The amount of `rwa` burned for a redemption
   * @param price                The price associated with this redemption
   */
  function _getRedemptionAmountForRwa(
    uint256 rwaTokenAmountBurned,
    uint256 price
  ) internal view returns (uint256 collateralOwed) {
    uint256 amountE36 = rwaTokenAmountBurned * price;
    collateralOwed = _scaleDown(amountE36 / 1e18);
  }

  /**
   * @notice Scale provided amount up by `decimalsMultiplier`
   *
   * @dev This helper is used for converting the collateral's decimals
   *      representation to the RWA amount decimals representation.
   */
  function _scaleUp(uint256 amount) internal view returns (uint256) {
    return amount * decimalsMultiplier;
  }

  /**
   * @notice Scale provided amount down by `decimalsMultiplier`
   *
   * @dev This helper is used for converting `rwa`'s decimal
   *      representation to the `collateral`'s decimal representation
   */
  function _scaleDown(uint256 amount) internal view returns (uint256) {
    return amount / decimalsMultiplier;
  }
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐
 */
pragma solidity 0.8.16;

interface IRWAHubOffChainRedemptions {
  function requestRedemptionServicedOffchain(
    uint256 amountRWATokenToRedeem,
    bytes32 offChainDestination
  ) external;

  function pauseOffChainRedemption() external;

  function unpauseOffChainRedemption() external;

  function setOffChainRedemptionMinimum(uint256 minimumAmount) external;

  /**
   * @notice Event emitted when redemption request is submitted
   *
   * @param redemptionId        The user submitting the redemption request
   * @param user                The user submitting the redemption request
   * @param rwaTokenAmountIn    The amount of cash being burned
   * @param offChainDestination Hash of destination to which the request
   *                            should be serviced to
   */
  event RedemptionRequestedServicedOffChain(
    bytes32 indexed redemptionId,
    address indexed user,
    uint256 rwaTokenAmountIn,
    bytes32 offChainDestination
  );

  /**
   * @notice Event emitted when the off chain redemption feature is
   *         paused
   *   */
  event OffChainRedemptionPaused();

  /**
   * @notice Event emitted when the off chain redemption feature is
   *         unpaused
   */
  event OffChainRedemptionUnpaused();

  /**
   * @notice Event emitted when the off chain redemption minimum is
   *         updated
   *
   * @param oldMinimum the old minimum redemption amount
   * @param newMinimum the new minimum redemption amount
   */
  event OffChainRedemptionMinimumSet(uint256 oldMinimum, uint256 newMinimum);
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐
 */
pragma solidity 0.8.16;

// This interface is not inherited directly by RWA, instead, it is a
// subset of functions provided by all RWA tokens that the RWA Hub
// Client uses.
import "contracts/external/openzeppelin/contracts/token/IERC20.sol";

interface IRWALike is IERC20 {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function burn(uint256 amount) external;

  function burnFrom(address from, uint256 amount) external;

  function grantRole(bytes32, address) external;
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

interface IPricer {
  /**
   * @notice Gets the latest price of the asset
   *
   * @return uint256 The latest price of the asset
   */
  function getLatestPrice() external view returns (uint256);

  /**
   * @notice Gets the price of the asset at a specific priceId
   *
   * @param priceId The priceId at which to get the price
   *
   * @return uint256 The price of the asset with the given priceId
   */
  function getPrice(uint256 priceId) external view returns (uint256);

  /**
   * @notice Adds a price to the pricer
   *
   * @param price     The price to add
   * @param timestamp The timestamp associated with the price
   *
   * @dev Updates the oracle price if price is the latest
   */
  function addPrice(uint256 price, uint256 timestamp) external;

  /**
   * @notice Updates a price in the pricer
   *
   * @param priceId The priceId to update
   * @param price   The price to set
   */
  function updatePrice(uint256 priceId, uint256 price) external;

  /**
   * @notice Updates a price in the pricer by pulling it from the oracle
   */
  function addLatestOraclePrice() external;
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐
 */
pragma solidity 0.8.16;

interface IRWAHub {
  // Struct to contain the deposit information for a given depositId
  struct Depositor {
    address user;
    uint256 amountDepositedMinusFees;
    uint256 priceId;
  }

  // Struc to contain withdrawal infromation for a given redemptionId
  struct Redeemer {
    address user;
    uint256 amountRwaTokenBurned;
    uint256 priceId;
  }

  function requestSubscription(uint256 amount) external;

  function claimMint(bytes32[] calldata depositIds) external;

  function requestRedemption(uint256 amount) external;

  function claimRedemption(bytes32[] calldata redemptionIds) external;

  function addProof(
    bytes32 txHash,
    address user,
    uint256 depositAmountAfterFee,
    uint256 feeAmount,
    uint256 timestamp
  ) external;

  function setPriceIdForDeposits(
    bytes32[] calldata depositIds,
    uint256[] calldata priceIds
  ) external;

  function setPriceIdForRedemptions(
    bytes32[] calldata redemptionIds,
    uint256[] calldata priceIds
  ) external;

  function setPricer(address newPricer) external;

  function overwriteDepositor(
    bytes32 depositIdToOverride,
    address user,
    uint256 depositAmountAfterFee,
    uint256 priceId
  ) external;

  function overwriteRedeemer(
    bytes32 redemptionIdToOverride,
    address user,
    uint256 rwaTokenAmountBurned,
    uint256 priceId
  ) external;

  /**
   * @notice Event emitted when fee recipient is set
   *
   * @param oldFeeRecipient Old fee recipient
   * @param newFeeRecipient New fee recipient
   */
  event FeeRecipientSet(address oldFeeRecipient, address newFeeRecipient);

  /**
   * @notice Event emitted when the assetSender is changed
   *
   * @param oldAssetSender The address of the old assetSender
   * @param newAssetSender The address of the new assetSender
   */
  event AssetSenderSet(address oldAssetSender, address newAssetSender);

  /**
   * @notice Event emitted when minimum deposit amount is set
   *
   * @param oldMinimum Old minimum
   * @param newMinimum New minimum
   *
   * @dev See inheriting contract for decimals representation
   */
  event MinimumDepositAmountSet(uint256 oldMinimum, uint256 newMinimum);

  /**
   * @notice Event emitted when a new redeem minimum is set.
   *         All units are in 1e18
   *
   * @param oldRedemptionMin The old redeem minimum value
   * @param newRedemptionMin The new redeem minimum value
   */
  event MinimumRedemptionAmountSet(
    uint256 oldRedemptionMin,
    uint256 newRedemptionMin
  );

  /**
   * @notice Event emitted when mint fee is set
   *
   * @param oldFee Old fee
   * @param newFee New fee
   *
   * @dev See inheriting contract for decimals representation
   */
  event MintFeeSet(uint256 oldFee, uint256 newFee);

  /**
   * @notice Event emitted when redeem fee is set
   *
   * @param oldFee Old fee
   * @param newFee New fee
   *
   * @dev see inheriting contract for decimal representation
   */
  event RedemptionFeeSet(uint256 oldFee, uint256 newFee);

  /**
   * @notice Event emitted when redemption request is submitted
   *
   * @param user         The user submitting the redemption request
   * @param redemptionId The id corresponding to a given redemption
   * @param rwaAmountIn The amount of cash being burned
   */
  event RedemptionRequested(
    address indexed user,
    bytes32 indexed redemptionId,
    uint256 rwaAmountIn
  );

  /**
   * @notice Event emitted when a mint request is submitted
   *
   * @param user                      The user requesting to mint
   * @param depositId                 The depositId of the request
   * @param collateralAmountDeposited The total amount deposited
   * @param depositAmountAfterFee     The value deposited - fee
   * @param feeAmount                 The fee amount taken
   *                                  (units of collateral)
   */
  event MintRequested(
    address indexed user,
    bytes32 indexed depositId,
    uint256 collateralAmountDeposited,
    uint256 depositAmountAfterFee,
    uint256 feeAmount
  );

  /**
   * @notice Event emitted when a redemption request is completed
   *
   * @param user                     The address of the user getting the funds
   * @param redemptionId             The id corresponding to a given redemption
   *                                 requested
   * @param rwaAmountRequested       Amount of RWA originally requested by the user
   * @param collateralAmountReturned Amount of collateral received by the user
   * @param price                    The price at which the redemption was
   *                                 serviced at
   */
  event RedemptionCompleted(
    address indexed user,
    bytes32 indexed redemptionId,
    uint256 rwaAmountRequested,
    uint256 collateralAmountReturned,
    uint256 price
  );

  /**
   * @notice Event emitted when a Mint request is completed
   *
   * @param user                      The address of the user getting the funds
   * @param depositId                 The depositId of the mint request
   * @param rwaAmountOut              The amount of RWA token minted to the
   *                                  user
   * @param collateralAmountDeposited The amount of collateral deposited
   * @param price                     The price set for the given
   *                                  deposit id
   * @param priceId                   The priceId used to determine price
   */
  event MintCompleted(
    address indexed user,
    bytes32 indexed depositId,
    uint256 rwaAmountOut,
    uint256 collateralAmountDeposited,
    uint256 price,
    uint256 priceId
  );

  /**
   * @notice Event emitted when a deposit has its corresponding priceId set
   *
   * @param depositIdSet The Deposit Id for which the price Id is being set
   * @param priceIdSet   The price Id being associate with a deposit Id
   */
  event PriceIdSetForDeposit(bytes32 depositIdSet, uint256 priceIdSet);

  /**
   * @notice Event Emitted when a redemption has its corresponding priceId set
   *
   * @param redemptionIdSet The Redemption Id for which the price Id is being
   *                        set
   * @param priceIdSet      The Price Id being associated with a redemption Id
   */
  event PriceIdSetForRedemption(bytes32 redemptionIdSet, uint256 priceIdSet);

  /**
   * @notice Event emitted when a new Pricer contract is set
   *
   * @param oldPricer The address of the old pricer contract
   * @param newPricer The address of the new pricer contract
   */
  event NewPricerSet(address oldPricer, address newPricer);

  /**
   * @notice Event emitted when deposit proof has been added
   *
   * @param txHash                Tx hash of the deposit
   * @param user                  Address of the user who made the deposit
   * @param depositAmountAfterFee Amount of the deposit after fees
   * @param feeAmount             Amount of fees taken
   * @param timestamp             Timestamp of the deposit
   */
  event DepositProofAdded(
    bytes32 indexed txHash,
    address indexed user,
    uint256 depositAmountAfterFee,
    uint256 feeAmount,
    uint256 timestamp
  );

  /**
   * @notice Event emitted when subscriptions are paused
   *
   * @param caller Address which initiated the pause
   */
  event SubscriptionPaused(address caller);

  /**
   * @notice Event emitted when redemptions are paused
   *
   * @param caller Address which initiated the pause
   */
  event RedemptionPaused(address caller);

  /**
   * @notice Event emitted when subscriptions are unpaused
   *
   * @param caller Address which initiated the unpause
   */
  event SubscriptionUnpaused(address caller);

  /**
   * @notice Event emitted when redemptions are unpaused
   *
   * @param caller Address which initiated the unpause
   */
  event RedemptionUnpaused(address caller);

  event DepositorOverwritten(
    bytes32 indexed depositId,
    address oldDepositor,
    address newDepositor,
    uint256 indexed oldPriceId,
    uint256 indexed newPriceId,
    uint256 oldDepositAmount,
    uint256 newDepositAmount
  );

  event RedeemerOverwritten(
    bytes32 indexed redemptionId,
    address oldRedeemer,
    address newRedeemer,
    uint256 indexed oldPriceId,
    uint256 indexed newPriceId,
    uint256 oldRWATokenAmountBurned,
    uint256 newRWATokenAmountBurned
  );

  /// ERRORS ///
  error PriceIdNotSet();
  error ArraySizeMismatch();
  error DepositTooSmall();
  error RedemptionTooSmall();
  error TxnAlreadyValidated();
  error CollateralCannotBeZero();
  error RWACannotBeZero();
  error AssetSenderCannotBeZero();
  error FeeRecipientCannotBeZero();
  error FeeTooLarge();
  error MinimumDepositAmountTooSmall();
  error DepositorNull();
  error RedeemerNull();
  error DepositProofAlreadyExists();
  error FeaturePaused();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "contracts/external/openzeppelin/contracts/token/IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "contracts/external/openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "contracts/external/openzeppelin/contracts/access/AccessControl.sol";
import "contracts/external/openzeppelin/contracts/utils/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is
  IAccessControlEnumerable,
  AccessControl
{
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      interfaceId == type(IAccessControlEnumerable).interfaceId ||
      super.supportsInterface(interfaceId);
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
  function getRoleMember(bytes32 role, uint256 index)
    public
    view
    virtual
    override
    returns (address)
  {
    return _roleMembers[role].at(index);
  }

  /**
   * @dev Returns the number of accounts that have `role`. Can be used
   * together with {getRoleMember} to enumerate all bearers of a role.
   */
  function getRoleMemberCount(bytes32 role)
    public
    view
    virtual
    override
    returns (uint256)
  {
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
  function _revokeRole(bytes32 role, address account)
    internal
    virtual
    override
  {
    super._revokeRole(role, account);
    _roleMembers[role].remove(account);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "contracts/external/openzeppelin/contracts/token/IERC20.sol";
import "contracts/external/openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(
        oldAllowance >= value,
        "SafeERC20: decreased allowance below zero"
      );
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(
        token,
        abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
      );
    }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata =
      address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(
        abi.decode(returndata, (bool)),
        "SafeERC20: ERC20 operation did not succeed"
      );
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "contracts/external/openzeppelin/contracts/access/IAccessControl.sol";
import "contracts/external/openzeppelin/contracts/utils/Context.sol";
import "contracts/external/openzeppelin/contracts/utils/Strings.sol";
import "contracts/external/openzeppelin/contracts/utils/ERC165.sol";

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
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      interfaceId == type(IAccessControl).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account)
    public
    view
    virtual
    override
    returns (bool)
  {
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
  function getRoleAdmin(bytes32 role)
    public
    view
    virtual
    override
    returns (bytes32)
  {
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
  function grantRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
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
  function revokeRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
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
    require(
      account == _msgSender(),
      "AccessControl: can only renounce roles for self"
    );

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "contracts/external/openzeppelin/contracts/access/IAccessControl.sol";

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
  function getRoleMember(bytes32 role, uint256 index)
    external
    view
    returns (address);

  /**
   * @dev Returns the number of accounts that have `role`. Can be used
   * together with {getRoleMember} to enumerate all bearers of a role.
   */
  function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
  function _contains(Set storage set, bytes32 value)
    private
    view
    returns (bool)
  {
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
  function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
  {
    return _remove(set._inner, value);
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool)
  {
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
  function at(Bytes32Set storage set, uint256 index)
    internal
    view
    returns (bytes32)
  {
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
  function values(Bytes32Set storage set)
    internal
    view
    returns (bytes32[] memory)
  {
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
  function remove(AddressSet storage set, address value)
    internal
    returns (bool)
  {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
  {
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
  function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
  {
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
  function values(AddressSet storage set)
    internal
    view
    returns (address[] memory)
  {
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
  function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
  {
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
  function at(UintSet storage set, uint256 index)
    internal
    view
    returns (uint256)
  {
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
  function values(UintSet storage set)
    internal
    view
    returns (uint256[] memory)
  {
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
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {AccessControl-_setupRole}.
   */
  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

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
  function toHexString(uint256 value, uint256 length)
    internal
    pure
    returns (string memory)
  {
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

import "contracts/external/openzeppelin/contracts/utils/IERC165.sol";

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
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
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
  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
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
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
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
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
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
  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
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
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
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

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "contracts/external/chainalysis/ISanctionsList.sol";

/**
 * @title ISanctionsListClient
 * @author Ondo Finance
 * @notice The client interface for sanctions contract.
 */
interface ISanctionsListClient {
  /// @notice Returns reference to the sanctions list that this client queries
  function sanctionsList() external view returns (ISanctionsList);

  /// @notice Sets the sanctions list reference
  function setSanctionsList(address sanctionsList) external;

  /// @notice Error for when caller attempts to set the `sanctionsList`
  ///         reference to the zero address
  error SanctionsListZeroAddress();

  /// @notice Error for when caller attempts to perform an action on a
  ///         sanctioned account
  error SanctionedAccount();

  /**
   * @dev Event for when the sanctions list reference is set
   *
   * @param oldSanctionsList The old list
   * @param newSanctionsList The new list
   */
  event SanctionsListSet(address oldSanctionsList, address newSanctionsList);
}

/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface ISanctionsList {
  function isSanctioned(address addr) external view returns (bool);
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

interface IBlocklist {
  function addToBlocklist(address[] calldata accounts) external;

  function removeFromBlocklist(address[] calldata accounts) external;

  function isBlocked(address account) external view returns (bool);

  /**
   * @notice Event emitted when addresses are added to the blocklist
   *
   * @param accounts The addresses that were added to the blocklist
   */
  event BlockedAddressesAdded(address[] accounts);

  /**
   * @notice Event emitted when addresses are removed from the blocklist
   *
   * @param accounts The addresses that were removed from the blocklist
   */
  event BlockedAddressesRemoved(address[] accounts);
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "contracts/interfaces/IBlocklist.sol";

/**
 * @title IBlocklistClient
 * @author Ondo Finance
 * @notice The client interface for the Blocklist contract.
 */
interface IBlocklistClient {
  /// @notice Returns reference to the blocklist that this client queries
  function blocklist() external view returns (IBlocklist);

  /// @notice Sets the blocklist reference
  function setBlocklist(address registry) external;

  /// @notice Error for when caller attempts to set the blocklist reference
  ///         to the zero address
  error BlocklistZeroAddress();

  /// @notice Error for when caller attempts to perform action on a blocked
  ///         account
  error BlockedAccount();

  /**
   * @dev Event for when the blocklist reference is set
   *
   * @param oldBlocklist The old blocklist
   * @param newBlocklist The new blocklist
   */
  event BlocklistSet(address oldBlocklist, address newBlocklist);
}