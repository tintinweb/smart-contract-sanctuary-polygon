// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PlayToEarnNoodz is Ownable {
  address private admin;
  uint256 public contractBalance;
  uint256 public gameBalance;
  //for testing: noodzToken deployed from address in constructor arg
  // address noodzToken;
  IERC20 public noodzToken;
  uint256 public maxSupply;
  uint256 public unit = 1e18;
  uint256 public gameId;
  uint256 public questId;
  mapping(address => mapping(uint256 => NoodleJump)) public balances;
  mapping(address => mapping(uint256 => NJGames)) public gameBalances;

  event NewGame(uint256 id, address indexed player);
  event NewQuest(uint256 id, address indexed player);
  event PaymentsTokenChanged(IERC20 _noodzToken);

  struct NoodleJump {
    address treasury;
    uint256 balance;
    bool locked;
    bool spent;
  }

  struct NJGames {
    address treasury;
    uint256 balance;
    bool locked;
    bool spent;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "Just admins can unlock escrow");
    _;
  }

  constructor(IERC20 _noodzToken) {
    admin = msg.sender;
    gameId = 0;
    questId = 0;
    noodzToken = _noodzToken;
    maxSupply = noodzToken.totalSupply();
  }

  function setPaymentsToken(IERC20 _paymentsToken) external onlyAdmin {
    noodzToken = _paymentsToken;
    emit PaymentsTokenChanged(noodzToken);
  }

  function gameState(uint256 _gameId, address _player)
    external
    view
    returns (
      uint256,
      bool,
      address
    )
  {
    return (
      gameBalances[_player][_gameId].balance,
      gameBalances[_player][_gameId].locked,
      gameBalances[_player][_gameId].treasury
    );
  }

  function questState(uint256 _questId, address _player)
    external
    view
    returns (
      uint256,
      bool,
      address
    )
  {
    return (
      balances[_player][_questId].balance,
      balances[_player][_questId].locked,
      balances[_player][_questId].treasury
    );
  }

  function createGame(
    address _player,
    address _treasury,
    uint256 _p,
    uint256 _t
  ) external onlyAdmin returns (bool) {
    // NoodzToken token = NoodzToken(noodzToken);
    // require(
    //   token.approve(address(this), _amountHaha),
    //   "PlayToEarnNoodz: approval has failed"
    // );
    require(_p >= unit, "PlayToEarnNoodz: must insert 1 whole token");
    require(_t >= unit, "PlayToEarnNoodz: must insert more than 1 token");
    noodzToken.transferFrom(msg.sender, address(this), _t);
    noodzToken.transferFrom(_player, address(this), _p);

    gameBalance += (_p + _t);
    gameId++;

    gameBalances[_player][gameId].balance = (_p + _t);
    gameBalances[_player][gameId].treasury = _treasury;
    gameBalances[_player][gameId].locked = true;
    gameBalances[_player][gameId].spent = false;
    emit NewGame(gameId, _player);

    return true;
  }

  function createQuest(
    address _player,
    address _treasury,
    uint256 _prize
  ) external onlyAdmin returns (bool) {
    // NoodzToken token = NoodzToken(noodzToken);
    require(
      _prize >= unit,
      "PlayToEarnNoodz: prize must be at least 1 whole token "
    );
    noodzToken.transferFrom(msg.sender, address(this), _prize);
    // token.transferFrom(_player, address(this), _prize);
    contractBalance += (_prize);
    questId++;
    balances[_player][questId].balance = (_prize);
    balances[_player][questId].treasury = _treasury;
    balances[_player][questId].locked = true;
    balances[_player][questId].spent = false;
    emit NewQuest(questId, _player);

    return true;
  }

  function completedQuest(uint256 _questId, address _player)
    external
    onlyAdmin
    returns (bool)
  {
    // NoodzToken token = NoodzToken(noodzToken);
    balances[_player][_questId].locked = false;
    // maxSupply = noodzToken.totalSupply();
    require(
      balances[_player][_questId].balance < maxSupply,
      "PlayToEarnNoodz: prize exceeds balance in escrow"
    );
    noodzToken.transfer(_player, balances[_player][_questId].balance);
    contractBalance -= balances[_player][_questId].balance;
    balances[_player][_questId].spent = true;

    return true;
  }

  function failedQuest(uint256 _questId, address _player)
    external
    onlyAdmin
    returns (bool)
  {
    // NoodzToken token = NoodzToken(noodzToken);
    noodzToken.transfer(
      balances[_player][_questId].treasury,
      balances[_player][_questId].balance
    );
    contractBalance -= gameBalances[_player][_questId].balance;
    balances[_player][_questId].spent = true;

    return true;
  }

  function won(uint256 _gameId, address _player)
    external
    onlyAdmin
    returns (bool)
  {
    // NoodzToken token = NoodzToken(noodzToken);
    // maxSupply = noodzToken.totalSupply();
    gameBalances[_player][_gameId].locked = false;
    require(
      gameBalances[_player][_gameId].balance < maxSupply,
      "PlayToEarnNoodz: winnings exceed balance in escrow"
    );
    noodzToken.transfer(_player, balances[_player][_gameId].balance);
    gameBalance -= gameBalances[_player][_gameId].balance;
    gameBalances[_player][_gameId].spent = true;

    return true;
  }

  function lost(uint256 _gameId, address _player)
    external
    onlyAdmin
    returns (bool)
  {
    // NoodzToken token = NoodzToken(noodzToken);
    noodzToken.transfer(
      gameBalances[_player][_gameId].treasury,
      gameBalances[_player][_gameId].balance
    );
    //TODO: post transfer to validate transfer
    gameBalance -= gameBalances[_player][_gameId].balance;
    gameBalances[_player][_gameId].spent = true;

    return true;
  }

  function withdrawIfUnlocked(uint256 _gameId) external returns (bool) {
    require(
      gameBalances[msg.sender][_gameId].locked == false,
      "Escrow is locked"
    );
    require(
      gameBalances[msg.sender][_gameId].spent == false,
      "Already withdrawn"
    );

    // NoodzToken token = NoodzToken(noodzToken);
    noodzToken.transfer(msg.sender, gameBalances[msg.sender][_gameId].balance);
    gameBalance -= gameBalances[msg.sender][_gameId].balance;
    gameBalances[msg.sender][_gameId].spent = true;

    return true;
  }

  function withdrawQuest(uint256 _questId) external returns (bool) {
    require(balances[msg.sender][_questId].locked == false, "Escrow is locked");
    require(
      balances[msg.sender][_questId].spent == false,
      "Quest prize already withdrawn"
    );

    // NoodzToken token = NoodzToken(noodzToken);
    noodzToken.transfer(msg.sender, balances[msg.sender][_questId].balance);
    contractBalance -= balances[msg.sender][_questId].balance;
    balances[msg.sender][_questId].spent = true;

    return true;
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