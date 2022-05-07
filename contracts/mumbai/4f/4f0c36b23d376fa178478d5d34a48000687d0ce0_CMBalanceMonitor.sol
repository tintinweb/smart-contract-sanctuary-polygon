/**
 *Submitted for verification at polygonscan.com on 2022-05-06
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: CMKeeper.sol

// CMKeeper.04


pragma solidity 0.8.9;



/**
 * @title The CMBalanceMonitor contract
 * @notice A keeper-compatible contract that monitors and funds eth addresses
 */
contract CMBalanceMonitor is KeeperCompatibleInterface, Ownable {
  // observed limit of 45K + 10k buffer
  uint256 private constant MIN_GAS_FOR_TRANSFER = 55_000;

  event FundsAdded(uint256 amountAdded, uint256 newBalance, address sender);
  event FundsWithdrawn(uint256 amountWithdrawn, address payee);
  event TopUpSucceeded(address indexed recipient);
  event TopUpFailed(address indexed recipient);
  event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);
  event MinWaitPeriodUpdated(uint256 oldMinWaitPeriod, uint256 newMinWaitPeriod);
  event TogglePaused(bool paused);
  event ToggleAdmin(address indexed account, bool isAdmin);

  error InvalidWatchList();
  error OnlyKeeperRegistry();
  error DuplicateAddress(address duplicate);
  error OnlyWhenNotPaused();
  error OnlyAdmin();

  struct Target {
    bool isActive;
    uint96 minBalanceWei;
    uint96 topUpAmountWei;
    uint32 lastTopUpTimestamp;
  }

  address private s_keeperRegistryAddress;
  uint256 private s_minWaitPeriodSeconds;
  address[] private s_watchList;
  mapping(address => Target) internal s_targets;
  mapping (address => bool) public isAdmin;
  bool public paused;

  /**
   * @param keeperRegistryAddress The address of the keeper registry contract
   * @param minWaitPeriodSeconds The minimum wait period for addresses between funding
   */
  constructor(address keeperRegistryAddress, uint256 minWaitPeriodSeconds) {
    setKeeperRegistryAddress(keeperRegistryAddress);
    setMinWaitPeriodSeconds(minWaitPeriodSeconds);
    paused = true;
  }

  /**
   * @notice Sets the list of addresses to watch and their funding parameters
   * @param addresses the list of addresses to watch
   * @param minBalancesWei the minimum balances for each address
   * @param topUpAmountsWei the amount to top up each address
   */
  function setWatchList(
    address[] calldata addresses,
    uint256[] calldata minBalancesWei,
    uint256[] calldata topUpAmountsWei
  ) external onlyAdmin {
    if (addresses.length != minBalancesWei.length || addresses.length != topUpAmountsWei.length) {
      revert InvalidWatchList();
    }
    address[] memory oldWatchList = s_watchList;
    for (uint256 idx = 0; idx < oldWatchList.length; idx++) {
      s_targets[oldWatchList[idx]].isActive = false;
    }
    for (uint256 idx = 0; idx < addresses.length; idx++) {
      if (s_targets[addresses[idx]].isActive) {
        revert DuplicateAddress(addresses[idx]);
      }
      if (addresses[idx] == address(0)) {
        revert InvalidWatchList();
      }
      if (topUpAmountsWei[idx] == 0) {
        revert InvalidWatchList();
      }
      s_targets[addresses[idx]] = Target({
        isActive: true,
        minBalanceWei: uint96(minBalancesWei[idx]),
        topUpAmountWei: uint96(topUpAmountsWei[idx]),
        lastTopUpTimestamp: 0
      });
    }
    s_watchList = addresses;
  }

  /**
   * @notice Gets a list of addresses that are under funded
   * @return list of addresses that are underfunded
   */
  function getUnderfundedAddresses() public view returns (address[] memory) {
    address[] memory watchList = s_watchList;
    address[] memory needsFunding = new address[](watchList.length);
    uint256 count = 0;
    uint256 minWaitPeriod = s_minWaitPeriodSeconds;
    uint256 balance = address(this).balance;
    Target memory target;
    for (uint256 idx = 0; idx < watchList.length; idx++) {
      target = s_targets[watchList[idx]];
      if (
        target.lastTopUpTimestamp + minWaitPeriod <= block.timestamp &&
        balance >= target.topUpAmountWei &&
        watchList[idx].balance < target.minBalanceWei
      ) {
        needsFunding[count] = watchList[idx];
        count++;
        balance -= target.topUpAmountWei;
      }
    }
    if (count != watchList.length) {
      assembly {
        mstore(needsFunding, count)
      }
    }
    return needsFunding;
  }

  /**
   * @notice Send funds to the addresses provided
   * @param needsFunding the list of addresses to fund (addresses must be pre-approved)
   */
  function topUp(address[] memory needsFunding) public onlyWhenNotPaused {
    uint256 minWaitPeriodSeconds = s_minWaitPeriodSeconds;
    Target memory target;
    for (uint256 idx = 0; idx < needsFunding.length; idx++) {
      target = s_targets[needsFunding[idx]];
      if (
        target.isActive &&
        target.lastTopUpTimestamp + minWaitPeriodSeconds <= block.timestamp &&
        needsFunding[idx].balance < target.minBalanceWei
      ) {
        bool success = payable(needsFunding[idx]).send(target.topUpAmountWei);
        if (success) {
          s_targets[needsFunding[idx]].lastTopUpTimestamp = uint32(block.timestamp);
          emit TopUpSucceeded(needsFunding[idx]);
        } else {
          emit TopUpFailed(needsFunding[idx]);
        }
      }
      if (gasleft() < MIN_GAS_FOR_TRANSFER) {
        return;
      }
    }
  }

  /**
   * @notice Get list of addresses that are underfunded and return keeper-compatible payload
   * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoded list of addresses that need funds
   */
  function checkUpkeep(bytes calldata)
    external
    view
    override
    onlyWhenNotPaused
    returns (bool upkeepNeeded, bytes memory performData)
  {
    address[] memory needsFunding = getUnderfundedAddresses();
    upkeepNeeded = needsFunding.length > 0;
    performData = abi.encode(needsFunding);
    return (upkeepNeeded, performData);
  }

  /**
   * @notice Called by keeper to send funds to underfunded addresses
   * @param performData The abi encoded list of addresses to fund
   */
  function performUpkeep(bytes calldata performData) external override onlyKeeperRegistry onlyWhenNotPaused {
    address[] memory needsFunding = abi.decode(performData, (address[]));
    topUp(needsFunding);
  }

  /**
   * @notice Withdraws the contract balance
   * @param amount The amount of eth (in wei) to withdraw
   * @param payee The address to pay
   */
  function withdraw(uint256 amount, address payable payee) external onlyOwner {
    require(payee != address(0));
    emit FundsWithdrawn(amount, payee);
    payee.transfer(amount);
  }

  /**
   * @notice Receive funds
   */
  receive() external payable {
    emit FundsAdded(msg.value, address(this).balance, msg.sender);
  }

  /**
   * @notice Sets the keeper registry address
   */
  function setKeeperRegistryAddress(address keeperRegistryAddress) public onlyAdmin {
    require(keeperRegistryAddress != address(0));
    emit KeeperRegistryAddressUpdated(s_keeperRegistryAddress, keeperRegistryAddress);
    s_keeperRegistryAddress = keeperRegistryAddress;
  }

  /**
   * @notice Sets the minimum wait period (in seconds) for addresses between funding
   */
  function setMinWaitPeriodSeconds(uint256 period) public onlyAdmin {
    emit MinWaitPeriodUpdated(s_minWaitPeriodSeconds, period);
    s_minWaitPeriodSeconds = period;
  }

  /**
   * @notice Gets the keeper registry address
   */
  function getKeeperRegistryAddress() external view returns (address keeperRegistryAddress) {
    return s_keeperRegistryAddress;
  }

  /**
   * @notice Gets the minimum wait period
   */
  function getMinWaitPeriodSeconds() external view returns (uint256) {
    return s_minWaitPeriodSeconds;
  }

  /**
   * @notice Gets the list of addresses being watched
   */
  function getWatchList() external view returns (address[] memory) {
    return s_watchList;
  }

  /**
   * @notice Gets configuration information for an address on the watchlist
   */
  function getAccountInfo(address targetAddress)
    external
    view
    returns (
      bool isActive,
      uint256 minBalanceWei,
      uint256 topUpAmountWei,
      uint256 lastTopUpTimestamp
    )
  {
    Target memory target = s_targets[targetAddress];
    return (target.isActive, uint256(target.minBalanceWei), uint256(target.topUpAmountWei), uint256(target.lastTopUpTimestamp));
  }

  /**
   * @notice Pauses/unpauses the contract, prevents executing performUpkeep
   */
  function togglePaused() external onlyAdmin {
    paused = !paused;
    emit TogglePaused(paused);
  }

  /**
   * @notice Adds/Removes admin privileges to an account
   */
  function toggleAdmin(address _account) external onlyOwner {
    isAdmin[_account] = !isAdmin[_account];
    emit ToggleAdmin(_account, isAdmin[_account]);
  }

  modifier onlyKeeperRegistry() {
    if (msg.sender != s_keeperRegistryAddress) {
      revert OnlyKeeperRegistry();
    }
    _;
  }
  modifier onlyWhenNotPaused() {
    if (paused) {
      revert OnlyWhenNotPaused();
    }
    _;
  }
  modifier onlyAdmin() {
    if (!isAdmin[msg.sender] && msg.sender != owner()) {
      revert OnlyAdmin();
    }
    _;
  }

}