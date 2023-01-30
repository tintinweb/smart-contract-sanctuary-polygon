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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAccessControl } from "../interfaces/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Pellar + LightLink 2022

abstract contract Base is Ownable {
  // variable
  address public accessControlProvider = 0x3f0B50B7A270de536D5De35C11C2613284C4304e;

  // verified
  modifier onlyRoler(string memory _methodInfo) {
    require(_msgSender() == owner() || IAccessControl(accessControlProvider).hasRole(_msgSender(), address(this), _methodInfo), "Caller does not have permission");
    _;
  }

  // verified
  function setAccessControlProvider(address _contract) external onlyRoler("setAccessControlProvider") {
    accessControlProvider = _contract;
  }

  /* Internal */
  // reviewed
  // verified
  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  // reviewed
  // verified
  function getSigner(bytes memory _message, bytes memory _signature) internal pure returns (address) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(_message.length), _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAccessControl {
  function hasRole(
    address _account,
    address _contract,
    string memory _methodInfo
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChampionUtils {
  function isOwnerOf(address _account, uint256 _championID) external view returns (bool);

  function isOriginalOwnerOf(address _account, uint256 _championID) external view returns (bool);

  function getTokenContract(uint256 _championID) external view returns (address);

  function maxFightPerChampion() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Pellar + LightLink 2022

interface IZooKeeper {
  function transferERC20In(
    address _currency,
    address _from,
    uint256 _amount
  ) external;

  function transferERC20Out(
    address _currency,
    address _to,
    uint256 _amount
  ) external;

  function transferERC721In(
    address _currency,
    address _from,
    uint256 _tokenId
  ) external;

  function transferERC721Out(
    address _currency,
    address _to,
    uint256 _tokenId
  ) external;

  function transferERC1155In(
    address _currency,
    address _from,
    uint256 _id,
    uint256 _amount
  ) external;

  function transferERC1155Out(
    address _currency,
    address _to,
    uint256 _id,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { TournamentTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ITournamentService {
  function tournamentState() external view returns (address);

  function championUtils() external view returns (address);

  function zooKeeper() external view returns (address);

  function bindTournamentState(address _contract) external;

  function bindChampionUtils(address _contract) external;

  function bindZooKeeper(address _contract) external;

  /* */
  // reviewed
  function cancelTournament(
    uint64 _serviceId,
    uint64 _tournamentId,
    TournamentTypes.Configs memory _configs,
    TournamentTypes.Warrior[] memory _warriors
  ) external;

  function joinTournament(
    uint64 _serviceId,
    uint64 _tournamentId,
    TournamentTypes.Configs memory _configs, //
    bytes memory _userSignature,
    bytes memory _params
  ) external;

  // reviewed
  function completeTournament(
    uint64 _serviceId,
    uint64 _tournamentId,
    TournamentTypes.Configs memory _configs,
    TournamentTypes.DynamicFeeReceiver[] memory _receivers,
    TournamentTypes.Callback[] memory _callbacks
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { TournamentTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ITournamentState {
  function getTournament(uint64 _serviceId, uint64 _tournamentId) external view returns (TournamentTypes.Info memory);

  function participants(
    uint64 _serviceId,
    uint64 _tournamentId,
    uint256 _championId
  ) external view returns (bool);

  function championNonce(uint64 _serviceId, uint256 _championId, uint256 _nonce) external view returns (bool);

  function hashConfigs(TournamentTypes.Configs memory _configs) external pure returns (bytes32);

  function setChampionNonce(uint64 _serviceId, uint256 _championId, uint256 _nonce) external;

  function joinTournament(
    uint64 _serviceId,
    uint64 _tournamentId,
    TournamentTypes.Configs memory _configs,
    TournamentTypes.Warrior memory _warrior
  ) external;

  function completeTournament(
    uint64 _serviceId,
    uint64 _tournamentId,
    TournamentTypes.Configs memory _configs
  ) external;

  function cancelTournament(
    uint64 _serviceId,
    uint64 _tournamentId,
    TournamentTypes.Configs memory _configs
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Base } from "../../../../common/Base.sol";
import { IChampionUtils } from "../../../../interfaces/IChampionUtils.sol";
import { IZooKeeper } from "../../../../interfaces/IZooKeeper.sol";
import { TournamentTypes } from "../types/Types.sol";
import { ITournamentService } from "../interfaces/ITournamentService.sol";
import { ITournamentState } from "../interfaces/ITournamentState.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Pellar + LightLink 2022

contract TournamentService is Base, ITournamentService {
  // variables
  address public tournamentState;
  address public championUtils;
  address public zooKeeper;

  // reviewed
  function bindTournamentState(address _contract) external onlyRoler("bindTournamentState") {
    tournamentState = _contract;
  }

  // reviewed
  function bindChampionUtils(address _contract) external onlyRoler("bindChampionUtils") {
    championUtils = _contract;
  }

  function bindZooKeeper(address _contract) external onlyRoler("bindZooKeeper") {
    zooKeeper = _contract;
  }

  /* */
  // reviewed
  function cancelTournament(
    uint64 _serviceId,
    uint64 _tournamentId,
    TournamentTypes.Configs memory _configs,
    TournamentTypes.Warrior[] memory _warriors
  ) external virtual onlyRoler("cancelTournament") {
    TournamentTypes.Info memory tournament = ITournamentState(tournamentState).getTournament(_serviceId, _tournamentId);
    require(_warriors.length == tournament.total_registered, "Invalid warriors");

    uint16 size = uint16(_warriors.length);
    for (uint256 i = 0; i < size; i++) {
      require(ITournamentState(tournamentState).participants(_serviceId, _tournamentId, _warriors[i].id), "Invalid participant");
      IZooKeeper(zooKeeper).transferERC20Out(_configs.currency, _warriors[i].account, _configs.buy_in);
    }
    ITournamentState(tournamentState).cancelTournament(_serviceId, _tournamentId, _configs);
  }

  function joinTournament(
    uint64 _serviceId,
    uint64 _tournamentId,
    TournamentTypes.Configs memory _configs, //
    bytes memory _userSignature,
    bytes memory _params
  ) external virtual onlyRoler("joinTournament") {
    address signer = tx.origin;
    // service ID, tournamentId, ...
    uint64 serviceId;
    uint64 tournamentId;
    uint256[] memory championIds;
    uint16[] memory stances;
    uint256[] memory nonces;

    {
      address joiner;
      (serviceId, tournamentId, joiner, championIds, stances, nonces) = abi.decode(_params, (uint64, uint64, address, uint256[], uint16[], uint256[]));

      uint256 size = championIds.length;

      if (_userSignature.length > 0) {
        bytes memory _championsPacked;
        bytes memory _stancePacked;
        for (uint256 i = 0; i < size - 1; i++) {
          _championsPacked = abi.encodePacked(_championsPacked, Strings.toString(championIds[i]), ";");
          _stancePacked = abi.encodePacked(_stancePacked, Strings.toString(stances[i]), ";");
        }
        bytes memory message = abi.encodePacked(
          "Tournament Type: ", //
          Strings.toString(serviceId),
          ",",
          " Tournament ID: ",
          Strings.toString(tournamentId),
          ",",
          " Champion IDs: ",
          abi.encodePacked(_championsPacked, Strings.toString(championIds[size - 1])),
          ",",
          " Stances: ",
          abi.encodePacked(_stancePacked, Strings.toString(stances[size - 1]))
        );
        signer = getSigner(message, _userSignature);
      }
      require(signer == joiner, "Signer mismatch"); // require signature match with joiner
      require(_serviceId == serviceId, "Invalid service"); // require service ID match
      require(_tournamentId == tournamentId, "Invalid tournament"); // require tournament ID match
    }

    {
      uint256 size = championIds.length;
      IZooKeeper(zooKeeper).transferERC20In(_configs.currency, signer, _configs.buy_in * size);

      for (uint256 i = 0; i < size; i++) {
        require(IChampionUtils(championUtils).isOwnerOf(signer, championIds[i]), "Require owner"); // require owner of token
        require(!ITournamentState(tournamentState).championNonce(serviceId, championIds[i], nonces[i]), "Invalid nonce");
        ITournamentState(tournamentState).joinTournament(
          serviceId, //
          tournamentId,
          _configs,
          TournamentTypes.Warrior({ account: signer, id: championIds[i], stance: stances[i], nonce: nonces[i], data: "" })
        );
        ITournamentState(tournamentState).setChampionNonce(serviceId, championIds[i], nonces[i]);
      }
    }
  }

  // reviewed
  function completeTournament(
    uint64 _serviceId,
    uint64 _tournamentId,
    TournamentTypes.Configs memory _configs,
    TournamentTypes.DynamicFeeReceiver[] memory _receivers,
    TournamentTypes.Callback[] memory
  ) external virtual onlyRoler("completeTournament") {
    uint256 prizePool = _configs.buy_in * _configs.size + _configs.top_up;

    uint256 percentageAccumulated;
    for (uint256 i = 0; i < _receivers.length; i++) {
      uint256 funds = (prizePool * _receivers[i].percentage) / 10000;
      IZooKeeper(zooKeeper).transferERC20Out(_configs.currency, _receivers[i].account, funds);
      percentageAccumulated += _receivers[i].percentage;
    }

    require(percentageAccumulated == 10000, "Invalid percentage");

    ITournamentState(tournamentState).completeTournament(_serviceId, _tournamentId, _configs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Pellar + LightLink 2022

library CommonTypes {
  struct Object {
    bytes key; // convert string to bytes ie: bytes("other_key")
    bytes value; // output of abi.encode(arg);
  }
}

// this is for tournaments (should not change)
library TournamentTypes {
  // status
  enum Status {
    AVAILABLE,
    READY,
    COMPLETED,
    CANCELLED
  }

  struct Configs {
    address currency; // address of currency that support
    uint16 size;
    uint256 buy_in;
    uint256 top_up;
    bytes data;
  }

  struct Info {
    Status status;
    bytes32 configs;
    uint16 total_registered;
  }

  // id, owner, stance, position
  struct Warrior {
    address account;
    uint256 id;
    uint16 stance;
    uint256 nonce;
    bytes data; // <- for dynamic data
  }

  struct DynamicFeeReceiver {
    address account;
    uint256 percentage;
  }

  struct Callback {
    address account;
    bytes data;
  }
}