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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

/*
W: https://kingdomofants.io 

                ▒▒██            ██▒▒                
                    ██        ██                    
                    ██  ████  ██                    
                    ████▒▒▒▒████                    
████              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ████
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
  ██              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ██  
    ██            ██▒▒██▒▒▒▒██▒▒██            ██    
      ██          ▓▓▒▒▒▒████▒▒▒▒██          ██      
        ██          ████████████          ██        
          ██          ██▒▒▒▒██          ██          
            ██████████▒▒▒▒▒▒▒▒██████████            
                    ██▒▒▒▒▒▒▒▒██                    
          ████████████▒▒▒▒▒▒▒▒████████████          
        ██          ██▒▒▒▒▒▒▒▒██          ██        
      ██            ██▒▒▒▒▒▒▒▒██            ██      
    ██            ████▒▒▒▒▒▒▒▒████            ██    
  ██            ██    ████████    ██            ██  
██▒▒██        ██    ██▒▒▒▒▒▒▒▒██    ██        ██▒▒██
██▒▒██      ██      ██▒▒▒▒▒▒▒▒██      ██      ██▒▒██
████      ██        ██▒▒▒▒▒▒▒▒██        ██      ████
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██            ██▒▒▒▒██            ██        
      ████            ██▒▒▒▒██            ████      
    ██▒▒██              ████              ██▒▒██    
    ██████                                ██████    

* Howdy folks! Thanks for glancing over our contracts
* Y'all have a nice day! Enjoy the game
*/

pragma solidity ^0.8.13;

interface IANTCoin {

  function mint(
    address receipt,
    uint256 _amount
  ) external;

  function burn(
    address receipt,
    uint256 _amount
  ) external;

  function balanceOf(address account) external returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

/*
W: https://kingdomofants.io 

                ▒▒██            ██▒▒                
                    ██        ██                    
                    ██  ████  ██                    
                    ████▒▒▒▒████                    
████              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ████
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
  ██              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ██  
    ██            ██▒▒██▒▒▒▒██▒▒██            ██    
      ██          ▓▓▒▒▒▒████▒▒▒▒██          ██      
        ██          ████████████          ██        
          ██          ██▒▒▒▒██          ██          
            ██████████▒▒▒▒▒▒▒▒██████████            
                    ██▒▒▒▒▒▒▒▒██                    
          ████████████▒▒▒▒▒▒▒▒████████████          
        ██          ██▒▒▒▒▒▒▒▒██          ██        
      ██            ██▒▒▒▒▒▒▒▒██            ██      
    ██            ████▒▒▒▒▒▒▒▒████            ██    
  ██            ██    ████████    ██            ██  
██▒▒██        ██    ██▒▒▒▒▒▒▒▒██    ██        ██▒▒██
██▒▒██      ██      ██▒▒▒▒▒▒▒▒██      ██      ██▒▒██
████      ██        ██▒▒▒▒▒▒▒▒██        ██      ████
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██            ██▒▒▒▒██            ██        
      ████            ██▒▒▒▒██            ████      
    ██▒▒██              ████              ██▒▒██    
    ██████                                ██████    

* Howdy folks! Thanks for glancing over our contracts
* Y'all have a nice day! Enjoy the game
*/

pragma solidity ^0.8.13;

interface IBasicANT {

    struct BatchInfo {
        string name;
        string baseURI;
        uint256 minted;
        uint256 mintPrice;
        address tokenAddressForMint;
        uint256 tokenAmountForMint;
        bool mintMethod;
    }

    struct ANTInfo {
        uint256 level;
        uint256 remainPotions;
        uint256 batchIndex;
        uint256 tokenIdOfBatch;
    }

    function ownerOf(uint256 tokenId) external view returns(address);
    function getMaxLevel() external view returns(uint256);
    function getANTInfo(uint256 tokenId) external view returns(ANTInfo memory);
    function getANTExperience(uint256 tokenId) external view returns(uint256);
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function downgradeLevel(uint256 tokenId, uint256 newLevel) external;
    function ownerANTUpgrade(uint256 tokenId, uint256 potionAmount) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

/*
W: https://kingdomofants.io 

                ▒▒██            ██▒▒                
                    ██        ██                    
                    ██  ████  ██                    
                    ████▒▒▒▒████                    
████              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ████
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
  ██              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ██  
    ██            ██▒▒██▒▒▒▒██▒▒██            ██    
      ██          ▓▓▒▒▒▒████▒▒▒▒██          ██      
        ██          ████████████          ██        
          ██          ██▒▒▒▒██          ██          
            ██████████▒▒▒▒▒▒▒▒██████████            
                    ██▒▒▒▒▒▒▒▒██                    
          ████████████▒▒▒▒▒▒▒▒████████████          
        ██          ██▒▒▒▒▒▒▒▒██          ██        
      ██            ██▒▒▒▒▒▒▒▒██            ██      
    ██            ████▒▒▒▒▒▒▒▒████            ██    
  ██            ██    ████████    ██            ██  
██▒▒██        ██    ██▒▒▒▒▒▒▒▒██    ██        ██▒▒██
██▒▒██      ██      ██▒▒▒▒▒▒▒▒██      ██      ██▒▒██
████      ██        ██▒▒▒▒▒▒▒▒██        ██      ████
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██            ██▒▒▒▒██            ██        
      ████            ██▒▒▒▒██            ████      
    ██▒▒██              ████              ██▒▒██    
    ██████                                ██████    

* Howdy folks! Thanks for glancing over our contracts
* Y'all have a nice day! Enjoy the game
*/

pragma solidity ^0.8.13;

interface IPremiumANT {

    struct BatchInfo {
        string name;
        string baseURI;
        uint256 minted;
        uint256 maxSupply;
        uint256 mintPrice;
    }

    struct ANTInfo {
        uint256 level;
        uint256 remainPotions;
        uint256 batchIndex;
        uint256 tokenIdOfBatch;
    }

    function getANTExperience(uint256 tokenId) external view returns(uint256);
    function getANTInfo(uint256 tokenId) external view returns(ANTInfo memory);
    function getMaxLevel() external view returns(uint256);
    function ownerOf(uint256 tokenId) external view returns(address);
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function downgradeLevel(uint256 tokenId, uint256 newLevel) external;
    function ownerANTUpgrade(uint256 tokenId, uint256 potionAmount) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

/*
W: https://kingdomofants.io 

                ▒▒██            ██▒▒                
                    ██        ██                    
                    ██  ████  ██                    
                    ████▒▒▒▒████                    
████              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ████
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
  ██              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ██  
    ██            ██▒▒██▒▒▒▒██▒▒██            ██    
      ██          ▓▓▒▒▒▒████▒▒▒▒██          ██      
        ██          ████████████          ██        
          ██          ██▒▒▒▒██          ██          
            ██████████▒▒▒▒▒▒▒▒██████████            
                    ██▒▒▒▒▒▒▒▒██                    
          ████████████▒▒▒▒▒▒▒▒████████████          
        ██          ██▒▒▒▒▒▒▒▒██          ██        
      ██            ██▒▒▒▒▒▒▒▒██            ██      
    ██            ████▒▒▒▒▒▒▒▒████            ██    
  ██            ██    ████████    ██            ██  
██▒▒██        ██    ██▒▒▒▒▒▒▒▒██    ██        ██▒▒██
██▒▒██      ██      ██▒▒▒▒▒▒▒▒██      ██      ██▒▒██
████      ██        ██▒▒▒▒▒▒▒▒██        ██      ████
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██            ██▒▒▒▒██            ██        
      ████            ██▒▒▒▒██            ████      
    ██▒▒██              ████              ██▒▒██    
    ██████                                ██████    

* Howdy folks! Thanks for glancing over our contracts
* Y'all have a nice day! Enjoy the game
*/

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IPremiumANT.sol';
import './interfaces/IBasicANT.sol';
import './interfaces/IANTCoin.sol';

contract Workforce is Ownable, Pausable, ReentrancyGuard {

    using SafeMath for uint256;

    // stake information for ANT
    struct StakeANT {
        uint256 tokenId; // ant token id
        address owner; // owner of staked ant
        uint256 batchIndex; // batch index of ants
        uint256 antCStakeAmount; // ant coin amount
        uint256 originTimestamp; // staked timestamp
    }

    // Reference to ANTCoin
    IANTCoin public antCoin;
    // Reference to Basic ANT
    IBasicANT public basicANT;
    // Reference to PremiumANT
    IPremiumANT public premiumANT;

    // minters
    mapping(address => bool) private minters;
    // Workforce for Basic ANT
    mapping(uint256 => StakeANT) public basicANTWorkforce;
    // Workforce for Premium ANT
    mapping(uint256 => StakeANT) public premiumANTWorkforce;
    // staked token id array for Basic ANT
    mapping(address => uint256[]) public basicANTStakedNFTs;
    // staked token id array for Premium ANT
    mapping(address => uint256[]) public premiumANTStakedNFTs;
    // array indices of each token id for Basic ANT
    mapping(uint256 => uint256) public basicANTStakedNFTsIndicies;
    // array indices of each token id for Premium ANT
    mapping(uint256 => uint256) public premiumANTStakedNFTsIndicies;
    // maximum stake period
    uint256 public maxStakePeriod = 3 * 365 days; // 3 years
    // a cycle for reward
    uint256 public cycleStakePeriod = 1 * 365 days; // 1 year
    // total number of staked Basic ANTs
    uint256 public totalBasicANTStaked;
    // total number of staked Premium ANTs
    uint256 public totalPremiumANTStaked;
    // initialize level after unstaking ant
    uint256 public initLevelAfterUnstake = 1;
    // premium or basic ant batch index for getting extra apy
    uint256 public batchIndexForExtraAPY = 0;
    // extra apy for work ants
    uint256 public extraAPY = 500; // 500 => 5.00 %
    // antcoin stake limit amount for each ants
    uint256 public limitAntCoinStakeAmount = 60000 ether;

    // Events
    // basic ant stake event
    event WorkforceStakeBasicANT(uint256 id, address owner);
    // basic ant unstake event
    event WorkforceUnStakeBasicANT(uint256 id, address owner);
    // premium ant stake event
    event WorkforceStakePremiumANT(uint256 id, address owner);
    // premium ant unstake event
    event WorkforceUnStakePremiumANT(uint256 id, address owner);

    // modifier to check _msgSender has minter role
    modifier onlyMinter() {
        require(minters[_msgSender()], 'Workforce: Caller is not the minter');
        _;
    }

    constructor(IANTCoin _antCoin, IPremiumANT _premiumANT, IBasicANT _basicANT) {
        antCoin = _antCoin;
        premiumANT = _premiumANT;
        basicANT = _basicANT;
    }

    /**
    * ██ ███    ██ ████████
    * ██ ████   ██    ██
    * ██ ██ ██  ██    ██
    * ██ ██  ██ ██    ██
    * ██ ██   ████    ██
    * This section has internal only functions
    */

    /**
    * @notice Transfer ETH and return the success status.
    * @dev This function only forwards 30,000 gas to the callee.
    * @param to Address for ETH to be send to
    * @param value Amount of ETH to send
    */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    /**
    * ███████ ██   ██ ████████
    * ██       ██ ██     ██
    * █████     ███      ██
    * ██       ██ ██     ██
    * ███████ ██   ██    ██
    * This section has external functions
    */

    /**
    * @notice Check address has minterRole
    */

    function getMinterRole(address _address) public view returns(bool) {
        return minters[_address];
    }

    /**
    * @notice Return Premium ANT Stake information
    */

    function getPremiumANTStakeInfo(uint256 _tokenId) external view returns(StakeANT memory) {
        return premiumANTWorkforce[_tokenId];
    }

    /**
    * @notice Return Basic ANT Stake information
    */

    function getBasicANTStakeInfo(uint256 _tokenId) external view returns(StakeANT memory) {
        return basicANTWorkforce[_tokenId];
    }

    /**
    * @notice Return Staked Premium ANTs token ids
    * @param _owner user address to get the staked premium ant token ids
    */

    function getPremiumANTStakedByAddress(address _owner) public view returns(uint256[] memory) {
        return premiumANTStakedNFTs[_owner];
    }

    /**
    * @notice Return Staked Basic ANTs token ids
    * @param _owner user address to get the staked basic ant token ids
    */

    function getBasicANTStakedByAddress(address _owner) public view returns(uint256[] memory) {
        return basicANTStakedNFTs[_owner];
    }

    /**
    * @notice Return Basic ANT Stake information
    */

    function pendingRewardOfBasicToken(uint256 _tokenId) public view returns(uint256 pendingAmount) {
        StakeANT memory _stakeANTInfo = basicANTWorkforce[_tokenId];
        uint256 antExperience = basicANT.getANTExperience(_tokenId); // 3000 => 30.00%
        uint256 stakePeriod = block.timestamp.sub(_stakeANTInfo.originTimestamp);
        uint256 _extraAPY = _stakeANTInfo.batchIndex == batchIndexForExtraAPY ? extraAPY : 0; // extra 5% APY for worker ant
        if(stakePeriod > maxStakePeriod) {
            pendingAmount = _stakeANTInfo.antCStakeAmount.mul(antExperience.add(_extraAPY)).mul(maxStakePeriod).div(cycleStakePeriod.mul(10 ** 4));
        }
        else {
            pendingAmount = _stakeANTInfo.antCStakeAmount.mul(antExperience.add(_extraAPY)).mul(stakePeriod).div(cycleStakePeriod.mul(10 ** 4));
        }
    }

    /**
    * @notice Return Premium ANT Stake information
    */

    function pendingRewardOfPremiumToken(uint256 _tokenId) public view returns(uint256 pendingAmount) {
        StakeANT memory _stakeANTInfo = premiumANTWorkforce[_tokenId];
        uint256 antExperience = premiumANT.getANTExperience(_tokenId); // 3000 => 30.00%
        uint256 _extraAPY = _stakeANTInfo.batchIndex == batchIndexForExtraAPY ? extraAPY : 0; // extra 5% APY for worker ant
        uint256 stakePeriod = block.timestamp.sub(_stakeANTInfo.originTimestamp);
        if(stakePeriod > maxStakePeriod) {
            pendingAmount = _stakeANTInfo.antCStakeAmount.mul(antExperience.add(_extraAPY)).mul(maxStakePeriod).div(cycleStakePeriod).div(10 ** 4);
        }
        else {
            pendingAmount = _stakeANTInfo.antCStakeAmount.mul(antExperience.add(_extraAPY)).mul(stakePeriod).div(cycleStakePeriod).div(10 ** 4);
        }
    }

    /**
    * @notice Stake PremiumANT into Workforce with ANTCoin
    * @param _tokenId premium ant token id for stake
    * @param _antCAmount ant coin stake amount
    */

    function stakePremiumANT(uint256 _tokenId, uint256 _antCAmount) external whenNotPaused {
        require(premiumANT.ownerOf(_tokenId) == _msgSender(), 'Workforce: you are not owner of this token');
        require(_antCAmount <= limitAntCoinStakeAmount, "Workforce: ant coin stake amount exceed the limit amount");
        require(antCoin.balanceOf(_msgSender()) >= _antCAmount, 'Workforce: insufficient ant coin balance');
        IPremiumANT.ANTInfo memory _premiumANTInfo = premiumANT.getANTInfo(_tokenId);
        premiumANTWorkforce[_tokenId] = StakeANT({
            tokenId: _tokenId,
            owner: _msgSender(),
            antCStakeAmount: _antCAmount,
            batchIndex: _premiumANTInfo.batchIndex,
            originTimestamp: block.timestamp
        });
        premiumANTStakedNFTs[_msgSender()].push(_tokenId);
        premiumANTStakedNFTsIndicies[_tokenId] = premiumANTStakedNFTs[_msgSender()].length - 1;
        totalPremiumANTStaked += 1;
        premiumANT.transferFrom(_msgSender(), address(this), _tokenId);
        antCoin.transferFrom(_msgSender(), address(this), _antCAmount);
        emit WorkforceStakePremiumANT(_tokenId, _msgSender());
    }

    /**
    * @notice Stake BasicANT into Workforce with ANTCoin
    * @param _tokenId basic ant token id for stake
    * @param _antCAmount ant coin stake amount
    */

    function stakeBasicANT(uint256 _tokenId, uint256 _antCAmount) external whenNotPaused {
        require(basicANT.ownerOf(_tokenId) == _msgSender(), 'Workforce: you are not owner of this token');
        require(_antCAmount <= limitAntCoinStakeAmount, "Workforce: ant coin stake amount exceed the limit amount");
        require(antCoin.balanceOf(_msgSender()) >= _antCAmount, 'Workforce: insufficient ant coin balance');
        IBasicANT.ANTInfo memory _basicANTInfo = basicANT.getANTInfo(_tokenId);
        basicANTWorkforce[_tokenId] = StakeANT({
            tokenId: _tokenId,
            owner: _msgSender(),
            antCStakeAmount: _antCAmount,
            batchIndex: _basicANTInfo.batchIndex,
            originTimestamp: block.timestamp
        });
        basicANTStakedNFTs[_msgSender()].push(_tokenId);
        basicANTStakedNFTsIndicies[_tokenId] = basicANTStakedNFTs[_msgSender()].length - 1;
        totalBasicANTStaked += 1;
        basicANT.transferFrom(_msgSender(), address(this), _tokenId);
        antCoin.transferFrom(_msgSender(), address(this), _antCAmount);
        emit WorkforceStakeBasicANT(_tokenId, _msgSender());
    }

    /**
    * @notice UnStake Premium ANT from Workforce with reward
    * @param _tokenId Premium ant token id for unstake
    */

    function unStakePremiumANT(uint256 _tokenId) external whenNotPaused {
        StakeANT memory _stakeANTInfo = premiumANTWorkforce[_tokenId];
        require(_stakeANTInfo.owner == _msgSender(), 'Workforce: you are not owner of this premium ant');
        uint256 rewardAmount = pendingRewardOfPremiumToken(_tokenId);
        premiumANT.downgradeLevel(_tokenId, initLevelAfterUnstake);
        premiumANT.transferFrom(address(this), _msgSender(), _tokenId);
        antCoin.transfer(_msgSender(), _stakeANTInfo.antCStakeAmount);
        antCoin.mint(_msgSender(), rewardAmount);
        uint256 lastStakedNFTs = premiumANTStakedNFTs[_msgSender()][premiumANTStakedNFTs[_msgSender()].length - 1];
        premiumANTStakedNFTs[_msgSender()][premiumANTStakedNFTsIndicies[_tokenId]] = lastStakedNFTs;
        premiumANTStakedNFTsIndicies[premiumANTStakedNFTs[_msgSender()][premiumANTStakedNFTs[_msgSender()].length - 1]] = premiumANTStakedNFTsIndicies[_tokenId];
        premiumANTStakedNFTs[_msgSender()].pop();
        totalPremiumANTStaked -= 1;
        delete premiumANTStakedNFTsIndicies[_tokenId];
        delete premiumANTWorkforce[_tokenId];
        emit WorkforceUnStakePremiumANT(_tokenId, _msgSender());
    }

    /**
    * @notice UnStake Basic ANT from Workforce with reward
    * @param _tokenId Basic ant token id for unstake
    */

    function unStakeBasicANT(uint256 _tokenId) external whenNotPaused {
        StakeANT memory _stakeANTInfo = basicANTWorkforce[_tokenId];
        require(_stakeANTInfo.owner == _msgSender(), 'Workforce: you are not owner of this basic ant');
        uint256 rewardAmount = pendingRewardOfBasicToken(_tokenId);
        basicANT.downgradeLevel(_tokenId, initLevelAfterUnstake);
        basicANT.transferFrom(address(this), _msgSender(), _tokenId);
        antCoin.transfer(_msgSender(), _stakeANTInfo.antCStakeAmount);
        antCoin.mint(_msgSender(), rewardAmount);
        uint256 lastStakedNFTs = basicANTStakedNFTs[_msgSender()][basicANTStakedNFTs[_msgSender()].length - 1];
        basicANTStakedNFTs[_msgSender()][basicANTStakedNFTsIndicies[_tokenId]] = lastStakedNFTs;
        basicANTStakedNFTsIndicies[basicANTStakedNFTs[_msgSender()][basicANTStakedNFTs[_msgSender()].length - 1]] = basicANTStakedNFTsIndicies[_tokenId];
        basicANTStakedNFTs[_msgSender()].pop();
        totalBasicANTStaked -= 1;
        delete basicANTStakedNFTsIndicies[_tokenId];
        delete basicANTWorkforce[_tokenId];
        emit WorkforceUnStakeBasicANT(_tokenId, _msgSender());
    }

    /**
    *   ██████  ██     ██ ███    ██ ███████ ██████
    *  ██    ██ ██     ██ ████   ██ ██      ██   ██
    *  ██    ██ ██  █  ██ ██ ██  ██ █████   ██████
    *  ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██
    *   ██████   ███ ███  ██   ████ ███████ ██   ██
    * This section will have all the internals set to onlyOwner
    */

    /**
    * @notice Set ANTCoin contract address
    * @dev This function can only be called by the owner
    * @param _antCoin ANTCoin contract address
    */

    function setANTCoinContract(IANTCoin _antCoin) external onlyOwner {
        antCoin = _antCoin;
    }

    /**
    * @notice Set premium ant contract address
    * @dev This function can only be called by the owner
    * @param _premiumANT Premium ANT contract address
    */

    function setPremiumANTContract(IPremiumANT _premiumANT) external onlyOwner {
        premiumANT = _premiumANT;
    }

    /**
    * @notice Set basic ant contract address
    * @dev This function can only be called by the owner
    * @param _basicANT Basic ANT contract address
    */

    function setBasicANTContract(IBasicANT _basicANT) external onlyOwner {
        basicANT = _basicANT;
    }

    /**
    * @notice Set max stake period by timestamp
    * @dev This function can only be called by the owner
    * @param _maxStakePeriod max stake period timestamp
    */

    function setMaxStakePeriod(uint256 _maxStakePeriod) external onlyOwner {
        maxStakePeriod = _maxStakePeriod;
    }

    /**
    * @notice Set cycle stake period by timestamp
    * @dev This function can only be called by the owner
    * @param _cycleStakePeriod one reward cycle period timestamp
    */

    function setCycleStakePeriod(uint256 _cycleStakePeriod) external onlyOwner {
        cycleStakePeriod = _cycleStakePeriod;
    }

    /**
    * @notice Set init level after unstake ant
    * @dev This function can only be called by the owner
    * @param _level init level value
    */

    function setInitLevelAfterUnstake(uint256 _level) external onlyOwner {
        initLevelAfterUnstake = _level;
    }

    /**
    * @notice Set extra apy percentage
    * @dev This function can only be called by the owner
    * @param _extraAPY extra apy percentage e.g. 500 = 5.00 %
    */

    function setExtraAPY(uint256 _extraAPY) external onlyOwner {
        extraAPY = _extraAPY;
    }

    /**
    * @notice Set batch index for extra apy
    * @dev This function can only be called by the owner
    * @param _batchIndexForExtraAPY batch index value for extra apy
    */

    function setBatchIndexForExtraAPY(uint256 _batchIndexForExtraAPY) external onlyOwner {
        batchIndexForExtraAPY = _batchIndexForExtraAPY;
    }

    /**
    * @notice Set ant coin stake limit amount for each ants
    * @dev This function can only be called by the owner
    * @param _limitStakeAmount limit antcoin stake amount
    */

    function setLimitAntCoinStakeAmount(uint256 _limitStakeAmount) external onlyOwner {
        limitAntCoinStakeAmount = _limitStakeAmount;
    }

    /**
    * @notice Function to grant mint role
    * @dev This function can only be called by the owner
    * @param _address address to get minter role
    */
    function addMinterRole(address _address) external onlyOwner {
        minters[_address] = true;
    }

    /**
    * @notice Function to revoke mint role
    * @dev This function can only be called by the owner
    * @param _address address to revoke minter role
    */
    function revokeMinterRole(address _address) external onlyOwner {
        minters[_address] = false;
    }

    /**
    * enables owner to pause / unpause contract
    */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
    * @notice Allows owner to withdraw ETH funds to an address
    * @dev wraps _user in payable to fix address -> address payable
    * @param to Address for ETH to be send to
    * @param amount Amount of ETH to send
    */
    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(_safeTransferETH(to, amount));
    }

    /**
    * @notice Allows ownder to withdraw any accident tokens transferred to contract
    * @param _tokenContract Address for the token
    * @param to Address for token to be send to
    * @param amount Amount of token to send
    */
    function withdrawToken(
        address _tokenContract,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(to, amount);
    }
}