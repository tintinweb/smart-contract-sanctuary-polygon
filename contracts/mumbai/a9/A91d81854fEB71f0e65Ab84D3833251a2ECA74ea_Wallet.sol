// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.

// contracts/Wallet.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

// This is the main building block for smart contracts.
contract Wallet is ReentrancyGuard, Ownable {

  address private _hotWallet;

  event TransferEth(address indexed from, address indexed to, uint256 value);

  constructor(address wallet) {
    require(wallet != address(0x0), "wallet must be non-zero address.");
    _transferOwnership(_msgSender());
    _hotWallet = wallet;
  }

  function hotWallet() public view virtual returns (address) {
    return _hotWallet;
  }

  modifier onlyHotWallet() {
    require(hotWallet() == _msgSender(), "Wallet: caller is not the hot wallet");
    _;
  }

  function setNewHotWallet(address newHotWallet) public onlyOwner returns (bool) {
    require(newHotWallet != address(0x0), "newHotWallet must be non-zero address.");
    require(newHotWallet != hotWallet(), "newHotWallet and hotWallet are identity.");
    _hotWallet = newHotWallet;
    return true;
  }

  // Function to receive Ether. msg.data must be empty
  receive() external payable {}

  // Fallback function is called when msg.data is not empty
  fallback() external payable {}

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function getBalances(address[] memory _ids) public view returns (uint[] memory) {
    require(_ids.length > 0, "_ids array length must be non-zero.");

    uint256[] memory balances = new uint256[](_ids.length);

    for (uint256 i = 0; i < _ids.length; ++i) {
      uint balance;
      if (_ids[i] == address(0x0)) {
        balance = getBalance();
      } else {
        balance = IERC20(_ids[i]).balanceOf(address(this));
      }
      balances[i] = balance;
    }

    return balances;
  }

  function getHotWalletBalance() public view returns (uint) {
    return hotWallet().balance;
  }

  function getHotWalletBalances(address[] memory _ids) public view returns (uint[] memory) {
    require(_ids.length > 0, "_ids array length must be non-zero.");

    uint256[] memory balances = new uint256[](_ids.length);

    for (uint256 i = 0; i < _ids.length; ++i) {
      uint balance;
      if (_ids[i] == address(0x0)) {
        balance = getHotWalletBalance();
      } else {
        balance = IERC20(_ids[i]).balanceOf(hotWallet());
      }
      balances[i] = balance;
    }

    return balances;
  }

  function transferBatch(address[] memory _ids, address[] memory _tos, uint256[] memory _values) public nonReentrant onlyHotWallet {
  	require(_ids.length > 0, "_ids array length must be non-zero.");
  	require(_ids.length == _values.length, "_ids and _values array length must match.");
  	require(_ids.length == _tos.length, "_ids and _tos array length must match.");

  	for (uint256 i = 0; i < _ids.length; ++i) {
  		address id = _ids[i];
  		address to = _tos[i];
  		uint256 value = _values[i];

  		if (id == address(0x0)) {
  			_transfer(payable(to), value);
  		} else {
  			_transferToken(id, to, value);
  		}
  	}
  }

  function _transfer(address payable _to, uint256 _value) internal {
    require(_to != address(0x0), "_to must be non-zero address.");
    require(_value > 0, "_value must be non-zero.");
    require(_value <= getBalance(), "Not enough ETH balance.");

    (bool sent, ) = _to.call{value: _value}("");
    require(sent, "Failed to send Ether");
    emit TransferEth(address(this), _to, _value);
  }

  function _transferToken(address _id, address _to, uint256 _value) internal {
    require(_id != address(0x0), "_id must be non-zero address.");
    require(_to != address(0x0), "_to must be non-zero address.");
    require(_value > 0, "_value must be non-zero.");

    IERC20(_id).transferFrom(hotWallet(), _to, _value);
  }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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