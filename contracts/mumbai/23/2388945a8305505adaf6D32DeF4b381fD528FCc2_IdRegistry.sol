// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IdRegistry
 * @author limone (@lim0n3)
 * @custom:version 2.0.0
 *
 * @notice IdRegistry lets any ETH address claim a unique Open Work ID (owId). An address can own
 *         one owId at a time and may transfer it to another address.
 *
 *         The IdRegistry starts in the seedable state where only a trusted caller can register
 *         owIds and later moves to an open state where any address can register an owId. The
 *         Registry implements a recovery system which lets the address that owns an owId nominate
 *         a recovery address that can transfer the owId to a new address after a delay.
 */
contract IdRegistry is Ownable {
  /* /////////////////////////////////////////////////////////////
                                   STRUCTS
      //////////////////////////////////////////////////////////////*/

  /**
   * @dev Contains the state of the most recent recovery attempt.
   * @param destination Destination of the current recovery or address(0) if no active recovery.
   * @param startTs Timestamp of the current recovery or zero if no active recovery.
   */
  struct RecoveryState {
    address destination;
    uint40 startTs;
  }

  /* /////////////////////////////////////////////////////////////
                                   ERRORS
      //////////////////////////////////////////////////////////////*/

  /// @dev Revert when the caller does not have the authority to perform the action.
  error Unauthorized();

  /// @dev Revert when the caller is required to have an owId but does not have one.
  error HasNoId();

  /// @dev Revert when the destination is required to be empty, but has an owId.
  error HasId();

  /// @dev Revert if trustedRegister is invoked after trustedCallerOnly is disabled.
  error Registrable();

  /// @dev Revert if register is invoked before trustedCallerOnly is disabled.
  error Seedable();

  /// @dev Revert if a recovery operation is called when there is no active recovery.
  error NoRecovery();

  /// @dev Revert when completeRecovery() is called before the escrow period has elapsed.
  error Escrow();

  /// @dev Revert when an invalid address is provided as input.
  error InvalidAddress();

  /* /////////////////////////////////////////////////////////////
                                   EVENTS
      //////////////////////////////////////////////////////////////*/

  /**
   * @dev Emit an event when a new Open Work ID is registered.
   *
   * @param to       The custody address that owns the owId
   * @param id       The owId that was registered.
   * @param recovery The address that can initiate a recovery request for the owId
   */
  event Register(address indexed to, uint256 indexed id, address recovery);

  /**
   * @dev Emit an event when a Open Work ID is transferred to a new custody address.
   *
   * @param from The custody address that previously owned the owId
   * @param to   The custody address that now owns the owId
   * @param id   The owId that was transferred.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  /**
   * @dev Emit an event when a Open Work ID's recovery address is updated
   *
   * @param id       The owId whose recovery address was updated.
   * @param recovery The new recovery address.
   */
  event ChangeRecoveryAddress(uint256 indexed id, address indexed recovery);

  /**
   * @dev Emit an event when a recovery request is initiated for a Open Work Id
   *
   * @param from The custody address of the owId being recovered.
   * @param to   The destination address for the owId when the recovery is completed.
   * @param id   The id being recovered.
   */
  event RequestRecovery(
    address indexed from,
    address indexed to,
    uint256 indexed id
  );

  /**
   * @dev Emit an event when a recovery request is cancelled
   *
   * @param by  The address that cancelled the recovery request
   * @param id  The id being recovered.
   */
  event CancelRecovery(address indexed by, uint256 indexed id);

  /**
   * @dev Emit an event when the trusted caller is modified.
   *
   * @param trustedCaller The address of the new trusted caller.
   */
  event ChangeTrustedCaller(address indexed trustedCaller);

  /**
   * @dev Emit an event when the trusted only state is disabled.
   */
  event DisableTrustedOnly();

  /* /////////////////////////////////////////////////////////////
                                  CONSTANTS
      //////////////////////////////////////////////////////////////*/

  uint256 private constant ESCROW_PERIOD = 3 days;

  /* /////////////////////////////////////////////////////////////
                                   STORAGE
      //////////////////////////////////////////////////////////////*/

  /**
   * @dev The last Open Work id that was issued.
   */
  uint256 internal idCounter;

  /**
   * @dev The Open Work Invite service address that is allowed to call trustedRegister.
   */
  address internal trustedCaller;

  /**
   * @dev The address is allowed to call _completeTransferOwnership() and become the owner. Set to
   *      address(0) when no ownership transfer is pending.
   */
  address internal pendingOwner;

  /**
   * @dev Allows calling trustedRegister() when set 1, and register() when set to 0. The value is
   *      set to 1 and can be changed to 0, but never back to 1.
   */
  uint256 internal trustedOnly = 1;

  /**
   * @notice Maps each address to a owId, or zero if it does not own a owId.
   */
  mapping(address => uint256) public idOf;

  /**
   * @dev Maps each owId to an address that can initiate a recovery.
   */
  mapping(uint256 => address) internal recoveryOf;

  /**
   * @dev Maps each owId to a RecoveryState.
   */
  mapping(uint256 => RecoveryState) internal recoveryStateOf;

  /* /////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
      //////////////////////////////////////////////////////////////*/

  /**
   * @notice Set the owner of the contract to the deployer and configure the trusted forwarder.
   *
   */
  // solhint-disable-next-line no-empty-blocks
  constructor() Ownable() {}

  /* /////////////////////////////////////////////////////////////
                               REGISTRATION LOGIC
      //////////////////////////////////////////////////////////////*/

  /**
   * @notice Register a new, unique Open Work ID (owId) to an address that doesn't have one during
   *         the seedable phase.
   *
   * @param to       Address which will own the owId
   * @param recovery Address which can recover the owId
   */
  function register(address to, address recovery) external {
    /* Revert if the contract is in the seedable (trustedOnly) state  */
    if (trustedOnly == 1) revert Seedable();

    _unsafeRegister(to, recovery);

    emit Register(to, idCounter, recovery);
  }

  /**
   * @notice Register a new unique Open Work ID (owId) for an address that does not have one. This
   *         can only be invoked by the trusted caller when trustedOnly is set to 1.
   *
   * @param to       The address which will control the owId
   * @param recovery The address which can recover the owId
   */
  function trustedRegister(address to, address recovery) external {
    /* Revert if the contract is not in the seedable(trustedOnly) state */
    if (trustedOnly == 0) revert Registrable();

    /**
     * Revert if the caller is not the trusted caller
     * Perf: Use msg.sender instead of msgSender() to save 100 gas since meta-tx are not needed
     */
    if (msg.sender != trustedCaller) revert Unauthorized();

    _unsafeRegister(to, recovery);

    emit Register(to, idCounter, recovery);
  }

  /**
   * @dev Registers a new, unique owId and sets up a recovery address for a caller without
   *      checking all invariants or emitting events.
   */
  function _unsafeRegister(address to, address recovery) internal {
    /* Revert if the destination(to) already has an owId */
    if (idOf[to] != 0) revert HasId();

    /**
     * Safety: idCounter cannot realistically overflow, and incrementing before assignment
     * ensures that the id 0 is never assigned to an address.
     */
    unchecked {
      idCounter++;
    }

    /* Perf: Don't check to == address(0) to save 29 gas since 0x0 can only register 1 owId */
    idOf[to] = idCounter;
    recoveryOf[idCounter] = recovery;
  }

  /* /////////////////////////////////////////////////////////////
                               TRANSFER LOGIC
      //////////////////////////////////////////////////////////////*/

  /**
   * @notice Transfer the owId owned by this address to another address that does not have an owId.
   *
   * @param to The address to transfer the owId to.
   */
  function transfer(address to) external {
    address sender = _msgSender();
    uint256 id = idOf[sender];

    /* Revert if sender does not own an owId */
    if (id == 0) revert HasNoId();

    /* Revert if destination(to) already has an owId */
    if (idOf[to] != 0) revert HasId();

    _unsafeTransfer(id, sender, to);
  }

  /**
   * @dev Transfer the owId to another address and reset recovery without checking invariants.
   */
  function _unsafeTransfer(uint256 id, address from, address to) internal {
    /* Transfer ownership of the owId between addresses */
    idOf[to] = id;
    delete idOf[from];

    /* Clear the recovery address and reset active recovery requests */
    delete recoveryStateOf[id];
    delete recoveryOf[id];

    emit Transfer(from, to, id);
  }

  /* /////////////////////////////////////////////////////////////
                               RECOVERY LOGIC
      //////////////////////////////////////////////////////////////*/

  /**
   * INVARIANT 1: If msgSender() is a recovery address for an address, the latter must own an owId
   *
   * 1. idOf[addr] = 0 && recoveryOf[idOf[addr]] == address(0) ∀ addr
   *
   * 2. _msgSender() != address(0) ∀ _msgSender()
   *
   * 3. recoveryOf[addr] != address(0) ↔ idOf[addr] != 0
   *    see register(), trustedRegister() and changeRecoveryAddress()
   *
   * 4. idOf[addr] == 0 ↔ recoveryOf[addr] == address(0)
   *    see transfer() and completeRecovery()
   */

  /**
   * INVARIANT 2: If an address has a non-zero RecoveryState.startTs, it must own an owId
   *
   * 1. idOf[addr] == 0  && recoveryStateOf[idOf[addr]].startTs == 0 ∀ addr
   *
   * 2. recoveryStateOf[idOf[addr]].startTs != 0 requires idOf[addr] != 0
   *    see requestRecovery()
   *
   * 3. idOf[addr] == 0 ↔ recoveryStateOf[id[addr]].startTs == 0
   *    see transfer() and completeRecovery()
   */

  /**
   * INVARIANT 3: RecoveryState.startTs and  RecoveryState.destination must both be zero or
   *              non-zero for a given owId. See register(), trustedRegister(),
   *              changeRecoveryAddress() and _unsafeTransfer() which enforce this.
   */

  /**
   * @notice Change the recovery address of the owId owned by the caller and reset active recovery
   *         requests.
   *
   * @param recovery The address which can recover the owId (set to 0x0 to disable recovery).
   */
  function changeRecoveryAddress(address recovery) external {
    /* Revert if the caller does not own an owId */
    uint256 id = idOf[_msgSender()];
    if (id == 0) revert HasNoId();

    /* Change the recovery address and reset active recovery requests */
    recoveryOf[id] = recovery;
    delete recoveryStateOf[id];

    emit ChangeRecoveryAddress(id, recovery);
  }

  /**
   * @notice Request a recovery of an owId to a new address if the caller is the recovery address.
   *
   * @param from The address that owns the owId
   * @param to   The address where the owId should be sent
   */
  function requestRecovery(address from, address to) external {
    /* Revert unless the caller is the recovery address */
    uint256 id = idOf[from];
    if (_msgSender() != recoveryOf[id]) revert Unauthorized();

    /**
     * Start the recovery by setting the startTs and destination of the request.
     *
     * Safety: id != 0 because of Invariant 1
     */
    recoveryStateOf[id].startTs = uint40(block.timestamp);
    recoveryStateOf[id].destination = to;

    emit RequestRecovery(from, to, id);
  }

  /**
   * @notice Complete a recovery request and transfer the owId if the caller is the recovery
   *         address and the escrow period has passed.
   *
   * @param from The address that owns the owId.
   */
  function completeRecovery(address from) external {
    /* Revert unless the caller is the recovery address */
    uint256 id = idOf[from];
    if (_msgSender() != recoveryOf[id]) revert Unauthorized();

    /* Revert unless a recovery exists */
    RecoveryState memory state = recoveryStateOf[id];
    if (state.startTs == 0) revert NoRecovery();

    /**
     * Revert unless the escrow period has passed
     * Safety: cannot overflow because state.startTs was a block.timestamp
     */
    unchecked {
      if (block.timestamp < state.startTs + ESCROW_PERIOD) {
        revert Escrow();
      }
    }

    /* Revert if the destination already has an owId */
    if (idOf[state.destination] != 0) revert HasId();

    /**
     * Assumption 1: we don't need to check that the id still lives in the address because a
     * transfer would have reset startTs to zero causing a revert
     *
     * Assumption 2: id != 0 because of Invariant 1 and 2 (either asserts this)
     */
    _unsafeTransfer(id, from, state.destination);
  }

  /**
   * @notice Cancel an active recovery request if the caller is the recovery address or the
   *         custody address.
   *
   * @param from The address that owns the id.
   */
  function cancelRecovery(address from) external {
    uint256 id = idOf[from];
    address sender = _msgSender();

    /* Revert unless the caller is the recovery address or the custody address */
    if (sender != from && sender != recoveryOf[id]) revert Unauthorized();

    /* Revert unless an active recovery exists */
    if (recoveryStateOf[id].startTs == 0) revert NoRecovery();

    /* Assumption: id != 0 because of Invariant 1 */
    delete recoveryStateOf[id];

    emit CancelRecovery(sender, id);
  }

  /* /////////////////////////////////////////////////////////////
                                OWNER ACTIONS
      //////////////////////////////////////////////////////////////*/

  /**
   * @notice Change the trusted caller by calling this from the contract's owner.
   *
   * @param _trustedCaller The address of the new trusted caller
   */
  function changeTrustedCaller(address _trustedCaller) external onlyOwner {
    /* Revert if the address is the zero address */
    if (_trustedCaller == address(0)) revert InvalidAddress();

    trustedCaller = _trustedCaller;

    emit ChangeTrustedCaller(_trustedCaller);
  }

  /**
   * @notice Disable trustedRegister() and transition from seedable to registrable, which allows
   *        anyone to register an owId. This must be called by the contract's owner.
   */
  function disableTrustedOnly() external onlyOwner {
    delete trustedOnly;
    emit DisableTrustedOnly();
  }

  /**
   * @notice Overriden to prevent a single-step transfer of ownership
   */
  function transferOwnership(
    address /*newOwner*/
  ) public view override onlyOwner {
    revert Unauthorized();
  }

  /**
   * @notice Start a request to transfer ownership to a new address ("pendingOwner"). This must
   *         be called by the owner, and can be cancelled by calling again with address(0).
   */
  function requestTransferOwnership(address newOwner) public onlyOwner {
    /* Revert if the newOwner is the zero address */
    if (newOwner == address(0)) revert InvalidAddress();

    pendingOwner = newOwner;
  }

  /**
   * @notice Complete a request to transfer ownership by calling from pendingOwner.
   */
  function completeTransferOwnership() external {
    /* Revert unless the caller is the pending owner */
    if (msg.sender != pendingOwner) revert Unauthorized();

    /* Safety: burning ownership is impossible since this can't be called from address(0) */
    _transferOwnership(msg.sender);

    /* Clean up state to prevent the function from being called again without a new request */
    delete pendingOwner;
  }
}