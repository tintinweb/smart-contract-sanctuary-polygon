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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT


// State-related imports
/*
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
*/

// Computation-related imports
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
/*
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
*/


contract EmergentEngineInstance is Ownable, Pausable {

  /*
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableMap for EnumerableMap.UintToAddressMap;
  */

  // ** ** **
  //
  // EmergentEngineInstance is a proof-of-concept, decentralized, chain-native, state and computation engine built to power the metaverse
  // Together we manifest metaverse metaphysics emergent from collective cryptonautic consciousness
  //
  // ** ** **

  //
  // Event specifications
  //

  //
  // Versioning metadata
  //

  uint256 public constant VERSION = 84;
  string public constant CODENAME = "sandplay";

  //
  // Metaverse engine configuration constants follow
  //

  // How many "copies" of each basic data type the contract statically allocates at compile time

  uint256 public constant NUMBER_OF_COPIES = 32;
  
  //
  // Metaverse engine storage state follows
  //

  //
  // Emergent engine data type naming conventions
  //
  // uint256      <=>   posinaught
  // int256		    <=>   omninaught
  // bool		      <=>   falsitrue
  // bytes32      <=>   infonaught
  // address	    <=>   cryptonaut
  // string		    <=>   lexiqueue
  // bytes		    <=>   infoqueue
  //

  uint256[NUMBER_OF_COPIES] private posinaughtArray;
  int256[NUMBER_OF_COPIES] private omninaughtArray;
  bool[NUMBER_OF_COPIES] private falsitrueArray;
  bytes32[NUMBER_OF_COPIES] private infonaughtArray;
  address[NUMBER_OF_COPIES] private cryptonautArray;
  string[NUMBER_OF_COPIES] private lexiqueueArray;
  bytes[NUMBER_OF_COPIES] private infoqueueArray;

  //
  // Constructor, fallback, and receive functions
  //

  constructor() payable {}

  receive() external payable {}

  fallback() external payable {}

  //
  // Metaverse engine storage retrieval functions follow
  //

  //
  // Engine metadata retrieval
  //

  function getVersion () pure public returns (uint) {
    return VERSION;
  }

  function getCodename () pure public returns (string memory) {
    return CODENAME;
  }

  //
  // Engine configuration retrieval
  //

  function getNumberOfCopies () pure public returns (uint256) {
    return NUMBER_OF_COPIES;
  }

  //
  // Engine state retrieval
  //

  function getPosinaught (uint256 _copyIndex) view public returns (uint256) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");

    return posinaughtArray[_copyIndex];
  }

  function getOmninaught (uint256 _copyIndex) view public returns (int256) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");

    return omninaughtArray[_copyIndex];
  }

  function getFalsitrue (uint256 _copyIndex) view public returns (bool) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");

    return falsitrueArray[_copyIndex];
  }

  function getInfonaught (uint256 _copyIndex) view public returns (bytes32) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");

    return infonaughtArray[_copyIndex];
  }

  function getCryptonaut (uint256 _copyIndex) view public returns (address) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");

    return cryptonautArray[_copyIndex];
  }

  function getLexiqueue (uint256 _copyIndex) view public returns (string memory) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");

    return lexiqueueArray[_copyIndex];
  }

  function getInfoqueue (uint256 _copyIndex) view public returns (bytes memory) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");

    return infoqueueArray[_copyIndex];
  }


  //
  // Metaverse engine storage mutation functions follow
  //

  //
  // Engine state mutation
  //

  function setPosinaught (uint256 _copyIndex, uint256 _newPosinaut) public returns (uint256) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");

    posinaughtArray[_copyIndex] = _newPosinaut;
    return _newPosinaut;
  }

  function setOmninaught (uint256 _copyIndex, int256 _newOmninaught) public returns (int256) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");
    
    omninaughtArray[_copyIndex] = _newOmninaught;
    return _newOmninaught;
  }

  function setFalsitrue (uint256 _copyIndex, bool _newFalsitrue) public returns (bool) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");
    
    falsitrueArray[_copyIndex] = _newFalsitrue;
    return _newFalsitrue;
  }

  function setInfonaught (uint256 _copyIndex, bytes32 _newInfonaught) public returns (bytes32) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");
    
    infonaughtArray[_copyIndex] = _newInfonaught;
    return _newInfonaught;
  }

  function setCryptonaut (uint256 _copyIndex, address _newCryptonaut) public returns (address) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");
    
    cryptonautArray[_copyIndex] = _newCryptonaut;
    return _newCryptonaut;
  }

  function setLexiqueue (uint256 _copyIndex, string memory _newLexiqueue) public returns (string memory) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");
    
    lexiqueueArray[_copyIndex] = _newLexiqueue;
    return _newLexiqueue;
  }

  function setInfoqueue (uint256 _copyIndex, bytes memory _newInfoqueue) public returns (bytes memory) {
    require(_copyIndex >= 0 && _copyIndex < NUMBER_OF_COPIES, "Requested _copyIndex is invalid");
    
    infoqueueArray[_copyIndex] = _newInfoqueue;
    return _newInfoqueue;
  }

  //
  // Metaverse engine experimental functions follow
  //
 
}