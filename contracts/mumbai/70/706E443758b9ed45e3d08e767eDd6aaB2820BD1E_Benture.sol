// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBenture.sol";
import "./interfaces/IBentureProducedToken.sol";



/// @title Dividend-Paying Token
contract Benture is IBenture, Ownable, ReentrancyGuard{

  /// @dev The contract must be able to receive ether to pay dividends with it
  receive() external payable {}

  /// @notice Distributes one token as dividends for holders of another token _equally _
  /// @param origToken The address of the token that is held by receivers
  ///        Can not be a zero address!
  ///        MUST be an address of a contract - not an address of EOA!
  /// @param distToken The address of the token that is to be distributed as dividends
  ///        Zero address for native token (ether, wei)
  /// @param amount The amount of distTokens to be distributed in total
  ///        NOTE: If dividends are to payed in ether then `amount` is the amount of wei (NOT ether!)
  function distributeDividendsEqual(address origToken, address distToken, uint256 amount) external nonReentrant() {
    require(origToken != address(0), "Benture: original token can not have a zero address!");
    // Check if the contract with the provided address has `holders()` function
    // NOTE: If `origToken` is not a contract address(e.g. EOA) this call will revert without a reason
    (bool yes, ) = origToken.call(abi.encodeWithSignature("holders()"));
    require(yes, "Benture: provided original token does not support required functions!");
    // Get all holders of the origToken
    address[] memory receivers = IBentureProducedToken(origToken).holders();
    require(receivers.length > 0, "Benture: no dividends receivers were found!");
    uint256 length = receivers.length;
    // Distribute dividends to each of the holders
    for (uint256 i = 0; i < length; i++) {
      if (distToken == address(0)){
        // Native tokens (wei)
        require(amount <= address(this).balance, "Benture: not enough dividend tokens to distribute!");
        (bool success, ) = receivers[i].call{value: amount / length}("");
        require(success, "Benture: dividends transfer failed!");
      } else {
        // Other ERC20 tokens
        bool res = IBentureProducedToken(distToken).transfer(receivers[i], amount / length);
        require(res, "Benture: dividends distribution failed!");
      }
    }

    emit DividendsDistributed(distToken, amount);
  }

  /// @notice Distributes one token as dividends for holders of another token _according to each user's balance_
  /// @param origToken The address of the token that is held by receivers
  ///        Can not be a zero address!
  /// @param distToken The address of the token that is to be distributed as dividends
  ///        Zero address for native token (ether, wei)
  /// @param weight The amount of origTokens required to get a single distToken
  ///        NOTE: If dividends are payed in ether then `weight` is the amount of origTokens required to get a single ether (NOT a single wei!)
  function distributeDividendsWeighted(address origToken, address distToken, uint256 weight) external nonReentrant() {
    // It is impossible to give distTokens for zero origTokens
    require(origToken != address(0), "Benture: original token can not have a zero address!");
    // Check if the contract with the provided address has `holders()` function
    // NOTE: If `origToken` is not a contract address(e.g. EOA) this call will revert without a reason
    (bool yes, ) = origToken.call(abi.encodeWithSignature("holders()"));
    require(yes, "Benture: provided original token does not support required functions!");
    require(weight >= 1, "Benture: weight is too low!");
    // Get all holders of the origToken
    address[] memory receivers = IBentureProducedToken(origToken).holders();
    require(receivers.length > 0, "Benture: no dividends receivers were found!");
    uint256 totalWeightedAmount = 0;
    // This function reverts if weight is incorrect.
    checkWeight(origToken, weight);
    // Distribute dividends to each of the holders
    for (uint256 i = 0; i < receivers.length; i++) {
      uint256 userBalance = IBentureProducedToken(origToken).balanceOf(receivers[i]);
      uint256 weightedAmount = userBalance / weight;
      // This amount does not have decimals
      totalWeightedAmount += weightedAmount;
      if (distToken == address(0)) {
        // Native tokens (wei)
        require(totalWeightedAmount * (1 ether) <= address(this).balance, "Benture: not enough dividend tokens to distribute with the provided weight!");
        // Value is the same as `weightedAmount * (1 ether)`
        (bool success, ) = receivers[i].call{value: userBalance * (1 ether) / weight}("");
        require(success, "Benture: dividends transfer failed!");
      } else {
        // Other ERC20 tokens
        // If total assumed amount of tokens to be distributed as dividends is higher than current contract's balance, than it is impossible to
        // distribute dividends.
        require(totalWeightedAmount <= IBentureProducedToken(distToken).balanceOf(address(this)), "Benture: not enough dividend tokens to distribute with the provided weight!");
        bool res = IBentureProducedToken(distToken).transfer(receivers[i], weightedAmount);
        require(res, "Benture: dividends distribution failed!");
      }
    }
    
    emit DividendsDistributed(distToken, totalWeightedAmount);
  
  }

  /// @notice Checks if provided weight is valid for current receivers
  /// @param origToken The address of the token that is held by receivers
  ///        Can not be a zero address!
  /// @param weight The amount of origTokens required to get a single distToken
  function checkWeight(address origToken, uint256 weight) public view {
    require(origToken != address(0), "Benture: original token can not have a zero address!");
    address[] memory receivers = IBentureProducedToken(origToken).holders();
    uint256 minBalance = type(uint256).max;
    // Find the lowest balance
    for (uint256 i = 0; i < receivers.length; i++) {
      uint256 singleBalance = IBentureProducedToken(origToken).balanceOf(receivers[i]);
      if (singleBalance < minBalance) {
        minBalance = singleBalance;
      }
    }
    // If none of the receivers has at least `weight` tokens then it means that no dividends can be distributed
    require(minBalance >= weight, "Benture: none of the receivers has enough tokens for the provided weight!");
  }


  /// @notice Calculates the minimum currently allowed weight.
  ///         Weight used in distributing dividends should be equal/greater than this
  /// @param origToken The address of the token that is held by receivers
  function calcMinWeight(address origToken) external view returns(uint256) {
    require(origToken != address(0), "Benture: original token can not have a zero address!");
    address[] memory receivers = IBentureProducedToken(origToken).holders();
    uint256 minBalance = type(uint256).max;
    // Find the lowest balance
    for (uint256 i = 0; i < receivers.length; i++) {
      uint256 singleBalance = IBentureProducedToken(origToken).balanceOf(receivers[i]);
      if (singleBalance < minBalance) {
        minBalance = singleBalance;
      }
    }
    // Minimum weight is the lowest balance
    uint256 minWeight = minBalance;
    return minWeight;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @title An interface for a custom ERC20 contract used in the bridge
interface IBentureProducedToken is IERC20 {

    /// @notice Returns the name of the token
    /// @return The name of the token
    function name() external view returns(string memory);

    /// @notice Returns the symbol of the token
    /// @return The symbol of the token
    function symbol() external view returns(string memory);

    /// @notice Returns number of decimals of the token
    /// @return The number of decimals of the token
    function decimals() external view returns(uint8);

    /// @notice Indicates whether the token is mintable or not
    /// @return True if the token is mintable. False - if it is not
    function mintable() external view returns(bool);

    /// @notice Returns the array of addresses of all token holders
    /// @return The array of addresses of all token holders
    function holders() external view returns (address[] memory);

    /// @notice Creates tokens and assigns them to account, increasing the total supply.
    /// @param to The receiver of tokens
    /// @param amount The amount of tokens to mint
    /// @dev Can only be called by the owner of the admin NFT
    /// @dev Can only be called when token is mintable
    function mint(address to, uint256 amount) external;

    /// @notice Burns user's tokens
    /// @param amount The amount of tokens to burn
    function burn(uint256 amount) external;

    /// @notice Indicates that a new ERC20 was created
    event ControlledTokenCreated(address indexed account, uint256 amount);

    /// @notice Indicates that a new ERC20 was burnt
    event ControlledTokenBurnt(address indexed account, uint256 amount);
    
    /// @notice Indicates that a new ERC20 was transfered
    event ControlledTokenTransferred(address indexed from, address indexed to, uint256 amount);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


/// @title Dividend-Paying Token Interface
 
/// @dev An interface for a dividend-paying token contract.
interface IBenture {


  /// @notice Distributes one token as dividends for holders of another token _equally _
  /// @param origToken The address of the token that is held by receivers
  ///        Can not be a zero address!
  ///        MUST be an address of a contract - not an address of EOA!
  /// @param distToken The address of the token that is to be distributed as dividends
  ///        Zero address for native token (ether, wei)
  /// @param amount The amount of distTokens to be distributed in total
  ///        NOTE: If dividends are to payed in ether then `amount` is the amount of wei (NOT ether!)
  function distributeDividendsEqual(address origToken, address distToken, uint256 amount) external;

  /// @notice Distributes one token as dividends for holders of another token _according to each user's balance_
  /// @param origToken The address of the token that is held by receivers
  ///        Can not be a zero address!
  /// @param distToken The address of the token that is to be distributed as dividends
  ///        Zero address for native token (ether, wei)
  /// @param weight The amount of origTokens required to get a single distToken
  ///        NOTE: If dividends are payed in ether then `weight` is the amount of origTokens required to get a single ether (NOT a single wei!)
  function distributeDividendsWeighted(address origToken, address distToken, uint256 weight) external;
  
  /// @notice Checks if provided weight is valid for current receivers
  /// @param origToken The address of the token that is held by receivers
  ///        Can not be a zero address!
  /// @param weight The amount of origTokens required to get a single distToken
  function checkWeight(address origToken, uint256 weight) external view;

  /// @notice Calculates the minimum currently allowed weight.
  ///         Weight used in distributing dividends should be equal/greater than this
  /// @param origToken The address of the token that is held by receivers
  function calcMinWeight(address origToken) external view returns(uint256);

  /// @dev Indicates that dividends were distributed
  /// @param distToken The address of dividend token that gets distributed
  /// @param amount The amount of distTokens to be distributed in total
  event DividendsDistributed(
    address indexed distToken,
    uint256 indexed amount
  );
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