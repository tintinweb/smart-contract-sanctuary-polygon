// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface ISpiralsImpactVault {
  function deposit(uint256 _amount, address _receiver) external;

  function withdraw(
    uint256 _amount,
    address _receiver,
    address _owner
  ) external;

  function balanceOf(address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./periphery/ISpiralsImpactVault.sol";

contract TestContract {
  /// @notice the ImpactSelf contract address. Used for permissions.
  address public impactSelf;

  /// @notice the token that will be deposited to Spirals (USDC or DAI)
  address public token;
  /// @notice the gToken received from Spirals (gUSDC or gDAI)
  address public gToken;
  /// @notice the amount deposited at each batch
  uint256 public amountToDeposit;
  /// @notice the time to wait to be able to fully withdraw the deposited tokens
  uint256 public vestingTime;

  /// @notice the gToken amount that has been deposited and is currently locked
  uint256 public locked;
  /// @notice the gToken amount that has been deposited and is currently vested
  uint256 public vested;
  /// @notice the timestamp of the last time there was a deposit (or the vesting vars were updated)
  uint256 public latestDepositTimestamp;

  /// @notice a dictionary keeping track of the users that already deposited. Used to prevent grieving attacks.
  mapping(address => bool) internal depositingUsers;

  /* ========== EVENTS ========== */

  event ImpactSelfUpdated(address newAddress);
  event VestingTimeUpdated(uint256 newVestingTime);
  event DepositedAmountUpdated(uint256 newAmount);
  event DepositedToSpirals(uint256 amount, address onBehalfOf);

  /* ========== CONSTRUCTOR & INITIALIZER ========== */

  // /// @custom:oz-upgrades-unsafe-allow constructor
  // constructor() {
  //   _disableInitializers();
  // }

  // function initialize(
  //   address _impactSelf,
  //   address _token,
  //   address _gToken
  // ) external virtual initializer {
  //   __Context_init_unchained();
  //   __Ownable_init_unchained();
  // }

  // function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  /* ========== MODIFIERS ========== */

  /**
   * @notice check whether the caller is the impactSelf contract.
   */
  modifier onlyImpactSelf() {
    require(msg.sender == impactSelf, "Only ImpactSelf can call this");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == impactSelf, "Only ImpactSelf can call this");
    _;
  }

  /**
   * @notice update the vesting variable to the current block timestamp.
   */
  modifier updateVestingVariables() {
    uint256 _currentlyLocked = locked;
    uint256 blockTimestamp = block.timestamp;
    uint256 vestedTillNow = _currentlyLocked > 0
      ? ((blockTimestamp - latestDepositTimestamp) * _currentlyLocked) / vestingTime
      : 0;
    locked -= vestedTillNow;
    vested += vestedTillNow;
    latestDepositTimestamp = blockTimestamp;
    _;
  }

  /* ========== VIEWS ========== */

  /**
   * @notice Calculate the amount that can be withdrawn now from the Spirals contracts
   */
  function getUpdatedWithdrawable() external view returns (uint256) {
    uint256 _currentlyLocked = locked;
    uint256 vestedTillNow = _currentlyLocked > 0
      ? ((block.timestamp - latestDepositTimestamp) * _currentlyLocked) / vestingTime
      : 0;
    return vested + vestedTillNow;
  }



  /* ========== SETTERS ========== */

  /**
   * @notice Set the amount that will be deposited each time `depositToSpirals` is called.
   */
  function setImpactSelf(address _impactSelf) external onlyOwner {
    require(_impactSelf != address(0), "Invalid address for _impactSelf");
    impactSelf = _impactSelf;

    emit ImpactSelfUpdated(_impactSelf);
  }

  /**
   * @notice Set the amount that will be deposited each time `depositToSpirals` is called.
   */
  function setAmountToDeposit(uint256 _amountToDeposit) external onlyOwner {
    require(_amountToDeposit > 0, "Cannot deposit 0");
    amountToDeposit = _amountToDeposit;

    emit DepositedAmountUpdated(_amountToDeposit);
  }

  /**
   * @notice Set the amount of time the tokens will be locked in the Spirals vault.
   */
  function setVestingTime(uint256 _vestingTime) external onlyOwner {
    require(_vestingTime > 1 days, "Vesting must be more than 1 day");
    vestingTime = _vestingTime;

    emit VestingTimeUpdated(_vestingTime);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Deposit `amountToDeposit` into a Spirals vault. The amount will be linearly vested over `vestingTime` time;
   * @dev if the contract doesn't own enough tokens to stake, it will skip the operation.
   * @param _onBehalfOf the user for whom we trigger the deposit.
   */
  function depositToSpirals(address _onBehalfOf)
    external
    onlyImpactSelf
    updateVestingVariables
  {
    uint256 _amount = amountToDeposit;
    IERC20 _token = IERC20(token);
    ISpiralsImpactVault _gToken = ISpiralsImpactVault(gToken);
    if (_token.balanceOf(address(this)) < _amount) {
      // not enough tokens to stake. Simply return to prevent failures in the caller.
      return;
    }

    if (depositingUsers[_onBehalfOf]) {
      // a deposit on behalf of this user has already been done. Simply return.
      return;
    }
    depositingUsers[_onBehalfOf] = true;

    // approve the Spirals contract to transfer the depositor's tokens
    bool successfulApproval = _token.approve(address(_gToken), _amount);
    require(successfulApproval);

    // deposit the amount in the Spirals vault
    uint256 initialAmount = _gToken.balanceOf(address(this));
    _gToken.deposit(_amount, address(this));
    locked += _gToken.balanceOf(address(this)) - initialAmount;

    emit DepositedToSpirals(_amount, _onBehalfOf);
  }

  /**
   * @notice Withdraw a certain amount from the Spirals Vault to the contract.
   * @param _amount the amount to withdraw from the Spirals Vault.
   */
  function withdrawFromVault(uint256 _amount) external onlyOwner updateVestingVariables {
    require(_amount > 0, "Cannot withdraw 0");
    require(_amount <= vested, "Amount higher than withdrawable");
    vested -= _amount;

    // withdraw the amount from the vault
    ISpiralsImpactVault(gToken).withdraw(_amount, address(this), address(this));
  }

  /**
   * @notice Withdraw all the withdrawable tokens from the Spirals Vault.
   */
  function withdrawAllFromVault() external onlyOwner updateVestingVariables {
    uint256 _withdrawable = vested;
    require(_withdrawable > 0, "Nothing to withdraw");
    vested = 0;

    // withdraw the amount from the vault
    ISpiralsImpactVault(gToken).withdraw(_withdrawable, address(this), address(this));
  }

  /**
   * @notice Withdraw some of the tokens to a specified address.
   * @param _destination the address that will receive the tokens.
   * @param _amount the amount of tokens to withdraw.
   */
  function withdrawTokens(address _destination, uint256 _amount) external onlyOwner {
    IERC20 _token = IERC20(token);
    require(_amount > 0, "Cannot withdraw 0");
    require(_amount <= _token.balanceOf(address(this)), "Amount higher than balance");

    // send the tokens to the destination address (not checked as it is controlled by the owner)
    //slither-disable-next-line unchecked-transfer
    _token.transfer(_destination, _amount);
  }

  /**
   * @notice Withdraw all the tokens to a specified address.
   * @param _destination the address that will receive the tokens.
   */
  function withdrawAllTokens(address _destination) external onlyOwner {
    IERC20 _token = IERC20(token);
    uint256 balance = _token.balanceOf(address(this));
    require(balance > 0, "Nothing to withdraw");

    // send the tokens to the destination address (not checked as it is controlled by the owner)
    //slither-disable-next-line unchecked-transfer
    _token.transfer(_destination, balance);
  }
}