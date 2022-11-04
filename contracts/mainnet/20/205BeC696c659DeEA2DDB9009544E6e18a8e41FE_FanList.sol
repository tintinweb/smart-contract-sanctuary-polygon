//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Context } from '@openzeppelin/contracts/utils/Context.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { Fundable } from './Fundable.sol';

struct Info {
  string encryptedData;
  string campaign;
  uint addDate;
  bool exists;
}

contract FanList is Ownable, Fundable {
  mapping(address => Info) private fans;
  address[] private fanAddresses;
  string public publicKey;
  string public artistName;
  string public version = "2.0.0";

  event Added(address indexed account, uint listNumber);
  event Updated(address indexed account);

  constructor(string memory _artistName, string memory _publicKey, address _initialFunder) {
    artistName = _artistName;
    publicKey = _publicKey;
    _transferFunder(_initialFunder);
  }

  function add(address _address, string memory _campaign, string memory _encryptedData) public returns(uint listNumber) {
    require(_address == _msgSender() || _msgSender() == owner() || _msgSender() == funder(), 'Cannot add others.');
    require(!isListed(_address), 'Already listed.');
    fans[_address].encryptedData = _encryptedData;
    fans[_address].campaign = _campaign;
    fans[_address].addDate = block.timestamp;
    fans[_address].exists = true;
    fanAddresses.push(_address);
    emit Added(_address, fanAddresses.length - 1);
    return fanAddresses.length - 1;
  }

  function update(address _address, string memory _encryptedData) public returns(bool success) {
    require(_address == _msgSender() || _msgSender() == owner() || _msgSender() == funder(), 'Cannot update others.');
    require(isListed(_address), 'Not on list.');
    fans[_address].encryptedData = _encryptedData;
    emit Updated(_address);
    return true;
  }

  // item utility functions
  function isListed(address _address) public view returns(bool) {
    return fans[_address].exists;
  }
  function getIndex(address _address) public view returns(uint) {
    uint listLength = fanAddresses.length;
    for (uint i; i < listLength; i++) {
      if (fanAddresses[i] == _address) {
        return i;
      }
    }
    revert('Not Found');
  }
  function getFanForAddress(address _address) public view returns(Info memory) {
    return fans[_address];
  }

  // list utility functions
  function getListLength() public view returns(uint) {
    return fanAddresses.length;
  }
  function getList() public view returns(address[] memory) {
    return fanAddresses;
  }
  function getFullList() public view returns(address[] memory, Info[] memory) {
    uint listLength = fanAddresses.length;
    Info[] memory out = new Info[](listLength);
    for (uint i; i < listLength; i++) {
      out[i] = fans[fanAddresses[i]];
    }
    return (fanAddresses, out);
  }

  function getListPaged(uint offset, uint limit) public view returns(address[] memory) {
    require(offset >= 0, 'Invalid offset.');
    uint listLength = fanAddresses.length;
    if (offset >= listLength || limit <= 0) {
      return new address[](0);
    }

    uint len = Math.min(listLength - offset, limit);
    address[] memory out = new address[](len);
    for (uint i; i < len; i++) {
      uint idx = offset == 0 ? i : offset + i + 1;
      out[i] = fanAddresses[idx];
    }
    return out;
  }
  function getFullListPaged(uint offset, uint limit) public view returns(address[] memory, Info[] memory) {
    require(offset >= 0, 'Invalid offset.');
    uint listLength = fanAddresses.length;
    if (offset >= listLength || limit <= 0) {
      return (new address[](0), new Info[](0));
    }
    
    uint len = Math.min(listLength - offset, limit);
    Info[] memory out = new Info[](len);
    address[] memory addOut = new address[](len);
    for (uint i; i < len; i++) {
      uint idx = offset == 0 ? i : offset + i + 1;
      out[i] = fans[fanAddresses[idx]];
      addOut[i] = fanAddresses[idx];
    }
    return (addOut, out);
  }
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.17;

import { Context } from '@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an funder) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the funder account will be the one that deploys the contract. This
 * can later be changed with {transferFunder}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyFunder`, which can be applied to your functions to restrict their use to
 * the funder.
 */
abstract contract Fundable is Context {
    address private _funder;

    event FunderTransferred(address indexed previousFunder, address indexed newFunder);

    /**
     * @dev Throws if called by any account other than the funder.
     */
    modifier onlyFunder() {
        _checkFunder();
        _;
    }

    /**
     * @dev Returns the address of the current funder.
     */
    function funder() public view virtual returns (address) {
        return _funder;
    }

    /**
     * @dev Throws if the sender is not the funder.
     */
    function _checkFunder() internal view virtual {
        require(funder() == _msgSender(), "Fundable: caller is not the funder");
    }

    /**
     * @dev Leaves the contract without funder. It will not be possible to call
     * `onlyFunder` functions anymore. Can only be called by the current funder.
     *
     * NOTE: Renouncing funder will leave the contract without an funder,
     * thereby removing any functionality that is only available to the funder.
     */
    function renounceFunder() public virtual onlyFunder {
        _transferFunder(address(0));
    }

    /**
     * @dev Transfers funder of the contract to a new account (`newFunder`).
     * Can only be called by the current funder.
     */
    function transferFunder(address newFunder) public virtual onlyFunder {
        require(newFunder != address(0), "Fundable: new funder is the zero address");
        _transferFunder(newFunder);
    }

    /**
     * @dev Transfers funder of the contract to a new account (`newFunder`).
     * Internal function without access restriction.
     */
    function _transferFunder(address newFunder) internal virtual {
        address oldFunder = _funder;
        _funder = newFunder;
        emit FunderTransferred(oldFunder, newFunder);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}