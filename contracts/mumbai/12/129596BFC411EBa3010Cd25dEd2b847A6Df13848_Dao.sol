// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Eternity Deck DAO
 *
 * @notice DAO used to distributes funds from the
 *         Eternity Deck game
 */
contract Dao is Ownable, ReentrancyGuard {
  /**
   * @notice Addresses of the current DAO shareholders
   */
  address[] public shareholders;

  /**
   * @notice Ownership percentage of the current DAO shareholders
   *
   * @dev All ownerships must add up to 100.000 (100% ownership)
   */
  uint[] public shareholderOwnership;

  /** 
   * @notice Current balance of shareholders
   *
   * @notice Will also include balance of old shareholders who have not yet withdrawn their funds
   */
  mapping(address => uint) public shareholderBalance;

  /**
   * @dev Will allow execution only if shareholder with address 'addr' has at least 'amount' wei in his balance
   */
  modifier onlyIfShareholderHasBalance(address addr, uint amount) {
    require(shareholderBalance[addr] >= amount, "not enough funds");
    _;
  }

  /**
   * @dev Fired in changeShareholders()
   *
   * @param oldShareholders new shareholder addresses
   * @param oldShareholderOwnership new shareholder ownerships
   * @param newShareholders new shareholder addresses
   * @param newShareholderOwnership new shareholder ownerships
   */
  event ShareholdersChanged(
    address[] oldShareholders,
    uint[] oldShareholderOwnership,
    address[] newShareholders,
    uint[] newShareholderOwnership
  );

  /**
   * @dev Fired in distributeToShareholders()
   *
   * @param shareholders current shareholders
   * @param shareholderOwnership current shareholder ownership
   * @param value value in wei to be split between shareholders
   */
  event Payout(address[] shareholders, uint[] shareholderOwnership, uint256 value);

  /**
   * @dev Fired in withdraw()
   *
   * @param shareholderAddress shareholder withdrawing funds
   * @param value value being withdrawn
   */
  event Withdraw(address indexed shareholderAddress, uint256 value);

  /**
   * @dev Fired in forceWithdraw function
   *
   * @param owner address of current owner withdrawing funds
   * @param shareholderAddress address of shareholder from which owner is withdrawing funds
   * @param value value being withdrawn from shareholder by owner
   */
  event ForceWithdraw(address indexed owner, address indexed shareholderAddress, uint256 value);

  IERC20 eft;
 /**
   * @dev Deploys the DAO smart contract,
   *      assigns initial shareholders
   *
   * Emits a {ShareholdersChanged} event
   *
   * @param _shareholders initial shareholders
   * @param _shareholderOwnership initial shareholder ownership
   */
  constructor(address[] memory _shareholders, uint[] memory _shareholderOwnership) {
    changeShareholders(_shareholders, _shareholderOwnership);
    
    eft = IERC20(0x0E801D84Fa97b50751Dbf25036d067dCf18858bF);
  }

  /**
   * @dev Automatically distribute funds to shareholders
   *      on receival. It is recommended the distributeToShareholders()
   *      is used as this may run out of gas when called via `.transfer()`
  */
  fallback() external payable {
  }

  receive() external payable {
  }

/**
   * @dev Allows a shareholder to withdraw funds from his balance
   *
   * Emits a {Withdraw} event
   *
   * @param _amount amount to withdraw - must be lte shareholder balance
   */
  function withdraw(uint _amount) external nonReentrant onlyIfShareholderHasBalance(msg.sender, _amount) {
    shareholderBalance[msg.sender] -= _amount;
    bool success = eft.transfer(msg.sender, _amount);
    require(success, "can not withdraw");

    emit Withdraw(msg.sender, _amount);
  }

  /**
   * @dev Allows the DAO owner to forcefully withdraw shareholder funds from the DAO
   *
   * Emits a {ForceWithdraw} event
   *
   * @param _addr shareholder address to withdraw funds from
   * @param _amount amount to withdraw - must be lte _addr shareholder balance
   */
  function forceWithdraw(address _addr, uint _amount) external onlyOwner nonReentrant onlyIfShareholderHasBalance(_addr, _amount) {
    shareholderBalance[_addr] -= _amount;

    bool success = eft.transfer(_addr, _amount);
    require(success, "can not withdraw");

    emit ForceWithdraw(owner(), _addr, _amount);
  }

  /**
   * @notice Changes DAO shareholders
   *
   * @dev Restricted function only used by contract owner
   *
   * @dev Shareholder ownership must add up to 100.000(100%)
   *
   * Emits a {ShareholdersChanged} event
   *
   * @param _shareholders new shareholders
   * @param _shareholderOwnership new shareholder ownership
   */
  function changeShareholders(address[] memory _shareholders, uint[] memory _shareholderOwnership) public onlyOwner {
    // Length of _shareholders must match length of _shareholderOwnership
    require(_shareholders.length == _shareholderOwnership.length, "incompatible array length");

    // Must include at least one shareholder
    require(_shareholders.length > 0, "no shareholders");


    //_shareholders unique
    // Calculate sum of ownerships
    uint sum = 0;

    for(uint8 i = 0; i < _shareholderOwnership.length; i++) {
      // Zero address cannot be a shareholder
      require(_shareholders[i] != address(0), "zero address not accepted");
      
      sum += _shareholderOwnership[i];
    }

    // Ensure ownership matches 100.000 (100%)
    require(sum == 100_000, "ownership must sum to 100");

    // Emit event
    emit ShareholdersChanged(
      shareholders,
      shareholderOwnership,
      _shareholders,
      _shareholderOwnership
    );

    // Update shareholder addresses & ownership
    shareholders = _shareholders;
    shareholderOwnership = _shareholderOwnership;
  }

  /**
   * @dev Distributes sent ether funds to shareholders proportional to their ownership
   *
   * Emits a {Payout} event
   */
  function distributeToShareholders(uint256 _value) public onlyOwner{
    uint256 balance = eft.balanceOf(address(this));

    require(_value <= balance, "not enough funds");
    for(uint32 i; i < shareholders.length; i++) {
      shareholderBalance[shareholders[i]] += _value * shareholderOwnership[i] / 100_000;
    }
    emit Payout(shareholders, shareholderOwnership, _value);
  }


  function balance() public view returns (uint256){
    return eft.balanceOf(address(this));
  }

  
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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