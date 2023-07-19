/**
 *Submitted for verification at polygonscan.com on 2023-07-19
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/Interfaces/IPriceFeed.sol

// License-Identifier: MIT

pragma solidity 0.6.11;

interface IPriceFeed {
    // --- Events ---
    event LastGoodPriceUpdated(uint256 _lastGoodPrice);

    // --- Function ---
    function fetchPrice() external returns (uint256);
}

// File contracts/Interfaces/ITellorCaller.sol

// License-Identifier: MIT

pragma solidity 0.6.11;

interface ITellorCaller {
    function getTellorCurrentValue(bytes32 _queryId)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );
}

// File contracts/Dependencies/AggregatorV3Interface.sol

// License-Identifier: MIT
// Code from https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.6.11;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File contracts/Dependencies/SafeMath.sol

// License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File contracts/Dependencies/Ownable.sol

// License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// File contracts/Dependencies/CheckContract.sol

// License-Identifier: MIT

pragma solidity 0.6.11;

contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_account)
        }
        require(size > 0, "Account code size cannot be zero");
    }
}

// File contracts/Dependencies/BaseMath.sol

// License-Identifier: MIT
pragma solidity 0.6.11;

contract BaseMath {
    uint256 public constant DECIMAL_PRECISION = 1e18;
}

// File contracts/Dependencies/console.sol

// License-Identifier: MIT

pragma solidity 0.6.11;

// Buidler's helper contract for console logging
library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function log() internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log()"));
        ignored;
    }

    function logInt(int256 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(int)", p0));
        ignored;
    }

    function logUint(uint256 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint)", p0));
        ignored;
    }

    function logString(string memory p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string)", p0));
        ignored;
    }

    function logBool(bool p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool)", p0));
        ignored;
    }

    function logAddress(address p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address)", p0));
        ignored;
    }

    function logBytes(bytes memory p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes)", p0));
        ignored;
    }

    function logByte(bytes1 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(byte)", p0));
        ignored;
    }

    function logBytes1(bytes1 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes1)", p0));
        ignored;
    }

    function logBytes2(bytes2 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes2)", p0));
        ignored;
    }

    function logBytes3(bytes3 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes3)", p0));
        ignored;
    }

    function logBytes4(bytes4 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes4)", p0));
        ignored;
    }

    function logBytes5(bytes5 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes5)", p0));
        ignored;
    }

    function logBytes6(bytes6 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes6)", p0));
        ignored;
    }

    function logBytes7(bytes7 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes7)", p0));
        ignored;
    }

    function logBytes8(bytes8 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes8)", p0));
        ignored;
    }

    function logBytes9(bytes9 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes9)", p0));
        ignored;
    }

    function logBytes10(bytes10 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes10)", p0));
        ignored;
    }

    function logBytes11(bytes11 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes11)", p0));
        ignored;
    }

    function logBytes12(bytes12 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes12)", p0));
        ignored;
    }

    function logBytes13(bytes13 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes13)", p0));
        ignored;
    }

    function logBytes14(bytes14 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes14)", p0));
        ignored;
    }

    function logBytes15(bytes15 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes15)", p0));
        ignored;
    }

    function logBytes16(bytes16 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes16)", p0));
        ignored;
    }

    function logBytes17(bytes17 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes17)", p0));
        ignored;
    }

    function logBytes18(bytes18 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes18)", p0));
        ignored;
    }

    function logBytes19(bytes19 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes19)", p0));
        ignored;
    }

    function logBytes20(bytes20 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes20)", p0));
        ignored;
    }

    function logBytes21(bytes21 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes21)", p0));
        ignored;
    }

    function logBytes22(bytes22 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes22)", p0));
        ignored;
    }

    function logBytes23(bytes23 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes23)", p0));
        ignored;
    }

    function logBytes24(bytes24 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes24)", p0));
        ignored;
    }

    function logBytes25(bytes25 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes25)", p0));
        ignored;
    }

    function logBytes26(bytes26 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes26)", p0));
        ignored;
    }

    function logBytes27(bytes27 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes27)", p0));
        ignored;
    }

    function logBytes28(bytes28 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes28)", p0));
        ignored;
    }

    function logBytes29(bytes29 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes29)", p0));
        ignored;
    }

    function logBytes30(bytes30 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes30)", p0));
        ignored;
    }

    function logBytes31(bytes31 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes31)", p0));
        ignored;
    }

    function logBytes32(bytes32 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes32)", p0));
        ignored;
    }

    function log(uint256 p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint)", p0));
        ignored;
    }

    function log(string memory p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string)", p0));
        ignored;
    }

    function log(bool p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool)", p0));
        ignored;
    }

    function log(address p0) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address)", p0));
        ignored;
    }

    function log(uint256 p0, uint256 p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint)", p0, p1)
        );
        ignored;
    }

    function log(uint256 p0, string memory p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string)", p0, p1)
        );
        ignored;
    }

    function log(uint256 p0, bool p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool)", p0, p1)
        );
        ignored;
    }

    function log(uint256 p0, address p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address)", p0, p1)
        );
        ignored;
    }

    function log(string memory p0, uint256 p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint)", p0, p1)
        );
        ignored;
    }

    function log(string memory p0, string memory p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string)", p0, p1)
        );
        ignored;
    }

    function log(string memory p0, bool p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool)", p0, p1)
        );
        ignored;
    }

    function log(string memory p0, address p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address)", p0, p1)
        );
        ignored;
    }

    function log(bool p0, uint256 p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint)", p0, p1)
        );
        ignored;
    }

    function log(bool p0, string memory p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string)", p0, p1)
        );
        ignored;
    }

    function log(bool p0, bool p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool)", p0, p1)
        );
        ignored;
    }

    function log(bool p0, address p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address)", p0, p1)
        );
        ignored;
    }

    function log(address p0, uint256 p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint)", p0, p1)
        );
        ignored;
    }

    function log(address p0, string memory p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string)", p0, p1)
        );
        ignored;
    }

    function log(address p0, bool p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool)", p0, p1)
        );
        ignored;
    }

    function log(address p0, address p1) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address)", p0, p1)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        uint256 p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        string memory p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,string)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        bool p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        address p2
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,address)", p0, p1, p2)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        bool p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3)
        );
        ignored;
    }

    function log(
        address p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        (bool ignored, ) = CONSOLE_ADDRESS.staticcall(
            abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3)
        );
        ignored;
    }
}

// File contracts/Dependencies/LiquityMath.sol

// License-Identifier: MIT

pragma solidity 0.6.11;

library LiquityMath {
    using SafeMath for uint256;

    uint256 internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint256 internal constant NICR_PRECISION = 1e20;

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a : _b;
    }

    /*
     * Multiply two decimal numbers and use normal rounding rules:
     * -round product up if 19'th mantissa digit >= 5
     * -round product down if 19'th mantissa digit < 5
     *
     * Used only inside the exponentiation, _decPow().
     */
    function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
        uint256 prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }

    /*
     * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by two functions that represent time in units of minutes:
     * 1) TroveManager._calcDecayedBaseRate
     * 2) CommunityIssuance._getCumulativeIssuanceFraction
     *
     * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
     * "minutes in 1000 years": 60 * 24 * 365 * 1000
     *
     * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
     * negligibly different from just passing the cap, since:
     *
     * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
     * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
     */
    function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {
        if (_minutes > 525600000) {
            _minutes = 525600000;
        } // cap to avoid overflow

        if (_minutes == 0) {
            return DECIMAL_PRECISION;
        }

        uint256 y = DECIMAL_PRECISION;
        uint256 x = _base;
        uint256 n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else {
                // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    function _computeNominalCR(uint256 _coll, uint256 _debt) internal pure returns (uint256) {
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt);
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(
        uint256 _coll,
        uint256 _debt,
        uint256 _price
    ) internal pure returns (uint256) {
        if (_debt > 0) {
            uint256 newCollRatio = _coll.mul(_price).div(_debt);

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return 2**256 - 1;
        }
    }
}

// File contracts/PriceFeed.sol

// License-Identifier: MIT

pragma solidity 0.6.11;

/*
 * PriceFeed for mainnet deployment, to be connected to Chainlink's live ETH:USD and CNY/USD
 * aggregator reference contracts, and a wrapper contract TellorCaller, which connects to
 * TellorMaster contract.
 * The PriceFeed calculates cross pair price for ETH/CNY via both connected oracles.
 *
 * The PriceFeed uses Chainlink as primary oracle, and Tellor as fallback. It contains logic for
 * switching oracles based on oracle failures, timeouts, and conditions for returning to the primary
 * Chainlink oracle.
 */
contract PriceFeed is Ownable, CheckContract, BaseMath, IPriceFeed {
    using SafeMath for uint256;

    string public constant NAME = "PriceFeed";

    AggregatorV3Interface public priceAggregatorEth; // Mainnet Chainlink aggregator ETH/USD
    AggregatorV3Interface public priceAggregatorCny; // Mainnet Chainlink aggregator CNY/USD
    ITellorCaller public tellorCaller; // Wrapper contract that calls the Tellor system

    // Core Liquity contracts
    address borrowerOperationsAddress;
    address troveManagerAddress;

    // Tellor queryId for ETH/USD Oracle
    bytes32 public immutable ETHUSD_TELLOR_REQ_ID =
        keccak256(abi.encode("SpotPrice", abi.encode("eth", "usd")));
    //Tellor queryId for CNY/USD Oracle
    bytes32 public immutable CNYUSD_TELLOR_REQ_ID =
        keccak256(abi.encode("SpotPrice", abi.encode("cny", "usd")));

    // Use to convert a price answer to an 18-digit precision uint
    uint256 public constant TARGET_DIGITS = 18;
    uint256 public constant TELLOR_DIGITS = 18;

    // Maximum time period allowed since Chainlink's latest round data timestamp, beyond which Chainlink is considered frozen.
    uint256 public constant TIMEOUT = 14400; // 4 hours: 60 * 60 * 4
    uint256 public constant CNY_TIMEOUT = 129600; // 36 hours: 60 * 60 * 36

    // Maximum deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
    uint256 public constant MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND = 5e17; // 50%

    /*
     * The maximum relative price difference between two oracle responses allowed in order for the PriceFeed
     * to return to using the Chainlink oracle. 18-digit precision.
     */
    uint256 public constant MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES = 5e16; // 5%

    // The last good price seen from an oracle by Liquity
    uint256 public lastGoodPrice;

    struct ChainlinkResponse {
        uint80 roundId;
        uint80 cnyRoundId;
        int256 answer;
        uint256 timestamp;
        uint256 cnyTimestamp;
        bool success;
        uint8 decimals;
    }

    struct TellorResponse {
        bool ifRetrieve;
        uint256 value;
        uint256 timestamp;
        uint256 cnyTimestamp;
        bool success;
    }

    enum Status {
        chainlinkWorking,
        usingTellorChainlinkUntrusted,
        bothOraclesUntrusted,
        usingTellorChainlinkFrozen,
        usingChainlinkTellorUntrusted
    }

    // The current status of the PricFeed, which determines the conditions for the next price fetch attempt
    Status public status;

    event LastGoodPriceUpdated(uint256 _lastGoodPrice);
    event PriceFeedStatusChanged(Status newStatus);

    // --- Dependency setters ---

    function setAddresses(
        address _priceAggregatorAddressEth,
        address _priceAggregatorAddressCny,
        address _tellorCallerAddress
    ) external onlyOwner {
        checkContract(_priceAggregatorAddressEth);
        checkContract(_priceAggregatorAddressCny);
        checkContract(_tellorCallerAddress);

        priceAggregatorEth = AggregatorV3Interface(_priceAggregatorAddressEth);
        priceAggregatorCny = AggregatorV3Interface(_priceAggregatorAddressCny);
        tellorCaller = ITellorCaller(_tellorCallerAddress);

        // Explicitly set initial system status
        status = Status.chainlinkWorking;

        // Get an initial price from Chainlink to serve as first reference for lastGoodPrice
        ChainlinkResponse memory chainlinkResponse = _getCurrentChainlinkResponse();
        ChainlinkResponse memory prevChainlinkResponse = _getPrevChainlinkResponse(
            chainlinkResponse.roundId,
            chainlinkResponse.cnyRoundId,
            chainlinkResponse.decimals
        );

        require(
            !_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse) &&
                !_chainlinkIsFrozen(chainlinkResponse),
            "PriceFeed: Chainlink must be working and current"
        );

        _storeChainlinkPrice(chainlinkResponse);

        _renounceOwnership();
    }

    // --- Functions ---

    /*
     * fetchPrice():
     * Returns the latest price obtained from the Oracle. Called by Liquity functions that require a current price.
     *
     * Also callable by anyone externally.
     *
     * Non-view function - it stores the last good price seen by Liquity.
     *
     * Uses a main oracle (Chainlink) and a fallback oracle (Tellor) in case Chainlink fails. If both fail,
     * it uses the last good price seen by Liquity.
     *
     */
    function fetchChainlinkPrice() external returns (uint256) {
        ChainlinkResponse memory chainlinkResponse = _getCurrentChainlinkResponse();
        return _storeChainlinkPrice(chainlinkResponse);
    }

    function fetchTellorPrice() external returns (uint256) {
        TellorResponse memory tellorResponse = _getCurrentTellorResponse();
        return _storeTellorPrice(tellorResponse);
    }
    
    function fetchPrice() external override returns (uint256) {
        // Get current and previous price data from Chainlink, and current price data from Tellor
        ChainlinkResponse memory chainlinkResponse = _getCurrentChainlinkResponse();
        ChainlinkResponse memory prevChainlinkResponse = _getPrevChainlinkResponse(
            chainlinkResponse.roundId,
            chainlinkResponse.cnyRoundId,
            chainlinkResponse.decimals
        );
        TellorResponse memory tellorResponse = _getCurrentTellorResponse();

        // --- CASE 1: System fetched last price from Chainlink  ---
        if (status == Status.chainlinkWorking) {
            // If Chainlink is broken, try Tellor
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {
                // If Tellor is broken then both oracles are untrusted, so return the last good price
                if (_tellorIsBroken(tellorResponse)) {
                    _changeStatus(Status.bothOraclesUntrusted);
                    return lastGoodPrice;
                }
                /*
                 * If Tellor is only frozen but otherwise returning valid data, return the last good price.
                 * Tellor may need to be tipped to return current data.
                 */
                if (_tellorIsFrozen(tellorResponse)) {
                    _changeStatus(Status.usingTellorChainlinkUntrusted);
                    return lastGoodPrice;
                }

                // If Chainlink is broken and Tellor is working, switch to Tellor and return current Tellor price
                _changeStatus(Status.usingTellorChainlinkUntrusted);
                return _storeTellorPrice(tellorResponse);
            }

            // If Chainlink is frozen, try Tellor
            if (_chainlinkIsFrozen(chainlinkResponse)) {
                // If Tellor is broken too, remember Tellor broke, and return last good price
                if (_tellorIsBroken(tellorResponse)) {
                    _changeStatus(Status.usingChainlinkTellorUntrusted);
                    return lastGoodPrice;
                }

                // If Tellor is frozen or working, remember Chainlink froze, and switch to Tellor
                _changeStatus(Status.usingTellorChainlinkFrozen);

                if (_tellorIsFrozen(tellorResponse)) {
                    return lastGoodPrice;
                }

                // If Tellor is working, use it
                return _storeTellorPrice(tellorResponse);
            }

            // If Chainlink price has changed by > 50% between two consecutive rounds, compare it to Tellor's price
            if (_chainlinkPriceChangeAboveMax(chainlinkResponse, prevChainlinkResponse)) {
                // If Tellor is broken, both oracles are untrusted, and return last good price
                if (_tellorIsBroken(tellorResponse)) {
                    _changeStatus(Status.bothOraclesUntrusted);
                    return lastGoodPrice;
                }

                // If Tellor is frozen, switch to Tellor and return last good price
                if (_tellorIsFrozen(tellorResponse)) {
                    _changeStatus(Status.usingTellorChainlinkUntrusted);
                    return lastGoodPrice;
                }

                /*
                 * If Tellor is live and both oracles have a similar price, conclude that Chainlink's large price deviation between
                 * two consecutive rounds was likely a legitmate market price movement, and so continue using Chainlink
                 */
                if (_bothOraclesSimilarPrice(chainlinkResponse, tellorResponse)) {
                    return _storeChainlinkPrice(chainlinkResponse);
                }

                // If Tellor is live but the oracles differ too much in price, conclude that Chainlink's initial price deviation was
                // an oracle failure. Switch to Tellor, and use Tellor price
                _changeStatus(Status.usingTellorChainlinkUntrusted);
                return _storeTellorPrice(tellorResponse);
            }

            // If Chainlink is working and Tellor is broken, remember Tellor is broken
            if (_tellorIsBroken(tellorResponse)) {
                _changeStatus(Status.usingChainlinkTellorUntrusted);
            }

            // If Chainlink is working, return Chainlink current price (no status change)
            return _storeChainlinkPrice(chainlinkResponse);
        }

        // --- CASE 2: The system fetched last price from Tellor ---
        if (status == Status.usingTellorChainlinkUntrusted) {
            // If both Tellor and Chainlink are live, unbroken, and reporting similar prices, switch back to Chainlink
            if (
                _bothOraclesLiveAndUnbrokenAndSimilarPrice(
                    chainlinkResponse,
                    prevChainlinkResponse,
                    tellorResponse
                )
            ) {
                _changeStatus(Status.chainlinkWorking);
                return _storeChainlinkPrice(chainlinkResponse);
            }

            if (_tellorIsBroken(tellorResponse)) {
                _changeStatus(Status.bothOraclesUntrusted);
                return lastGoodPrice;
            }

            /*
             * If Tellor is only frozen but otherwise returning valid data, just return the last good price.
             * Tellor may need to be tipped to return current data.
             */
            if (_tellorIsFrozen(tellorResponse)) {
                return lastGoodPrice;
            }

            // Otherwise, use Tellor price
            return _storeTellorPrice(tellorResponse);
        }

        // --- CASE 3: Both oracles were untrusted at the last price fetch ---
        if (status == Status.bothOraclesUntrusted) {
            /*
             * If both oracles are now live, unbroken and similar price, we assume that they are reporting
             * accurately, and so we switch back to Chainlink.
             */
            if (
                _bothOraclesLiveAndUnbrokenAndSimilarPrice(
                    chainlinkResponse,
                    prevChainlinkResponse,
                    tellorResponse
                )
            ) {
                _changeStatus(Status.chainlinkWorking);
                return _storeChainlinkPrice(chainlinkResponse);
            }

            // Otherwise, return the last good price - both oracles are still untrusted (no status change)
            return lastGoodPrice;
        }

        // --- CASE 4: Using Tellor, and Chainlink is frozen ---
        if (status == Status.usingTellorChainlinkFrozen) {
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {
                // If both Oracles are broken, return last good price
                if (_tellorIsBroken(tellorResponse)) {
                    _changeStatus(Status.bothOraclesUntrusted);
                    return lastGoodPrice;
                }

                // If Chainlink is broken, remember it and switch to using Tellor
                _changeStatus(Status.usingTellorChainlinkUntrusted);

                if (_tellorIsFrozen(tellorResponse)) {
                    return lastGoodPrice;
                }

                // If Tellor is working, return Tellor current price
                return _storeTellorPrice(tellorResponse);
            }

            if (_chainlinkIsFrozen(chainlinkResponse)) {
                // if Chainlink is frozen and Tellor is broken, remember Tellor broke, and return last good price
                if (_tellorIsBroken(tellorResponse)) {
                    _changeStatus(Status.usingChainlinkTellorUntrusted);
                    return lastGoodPrice;
                }

                // If both are frozen, just use lastGoodPrice
                if (_tellorIsFrozen(tellorResponse)) {
                    return lastGoodPrice;
                }

                // if Chainlink is frozen and Tellor is working, keep using Tellor (no status change)
                return _storeTellorPrice(tellorResponse);
            }

            // if Chainlink is live and Tellor is broken, remember Tellor broke, and return Chainlink price
            if (_tellorIsBroken(tellorResponse)) {
                _changeStatus(Status.usingChainlinkTellorUntrusted);
                return _storeChainlinkPrice(chainlinkResponse);
            }

            // If Chainlink is live and Tellor is frozen, just use last good price (no status change) since we have no basis for comparison
            if (_tellorIsFrozen(tellorResponse)) {
                return lastGoodPrice;
            }

            // If Chainlink is live and Tellor is working, compare prices. Switch to Chainlink
            // if prices are within 5%, and return Chainlink price.
            if (_bothOraclesSimilarPrice(chainlinkResponse, tellorResponse)) {
                _changeStatus(Status.chainlinkWorking);
                return _storeChainlinkPrice(chainlinkResponse);
            }

            // Otherwise if Chainlink is live but price not within 5% of Tellor, distrust Chainlink, and return Tellor price
            _changeStatus(Status.usingTellorChainlinkUntrusted);
            return _storeTellorPrice(tellorResponse);
        }

        // --- CASE 5: Using Chainlink, Tellor is untrusted ---
        if (status == Status.usingChainlinkTellorUntrusted) {
            // If Chainlink breaks, now both oracles are untrusted
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {
                _changeStatus(Status.bothOraclesUntrusted);
                return lastGoodPrice;
            }

            // If Chainlink is frozen, return last good price (no status change)
            if (_chainlinkIsFrozen(chainlinkResponse)) {
                return lastGoodPrice;
            }

            // If Chainlink and Tellor are both live, unbroken and similar price, switch back to chainlinkWorking and return Chainlink price
            if (
                _bothOraclesLiveAndUnbrokenAndSimilarPrice(
                    chainlinkResponse,
                    prevChainlinkResponse,
                    tellorResponse
                )
            ) {
                _changeStatus(Status.chainlinkWorking);
                return _storeChainlinkPrice(chainlinkResponse);
            }

            // If Chainlink is live but deviated >50% from it's previous price and Tellor is still untrusted, switch
            // to bothOraclesUntrusted and return last good price
            if (_chainlinkPriceChangeAboveMax(chainlinkResponse, prevChainlinkResponse)) {
                _changeStatus(Status.bothOraclesUntrusted);
                return lastGoodPrice;
            }

            // Otherwise if Chainlink is live and deviated <50% from it's previous price and Tellor is still untrusted,
            // return Chainlink price (no status change)
            return _storeChainlinkPrice(chainlinkResponse);
        }
    }

    // --- Helper functions ---

    /* Chainlink is considered broken if its current or previous round data is in any way bad. We check the previous round
     * for two reasons:
     *
     * 1) It is necessary data for the price deviation check in case 1,
     * and
     * 2) Chainlink is the PriceFeed's preferred primary oracle - having two consecutive valid round responses adds
     * peace of mind when using or returning to Chainlink.
     */
    function _chainlinkIsBroken(
        ChainlinkResponse memory _currentResponse,
        ChainlinkResponse memory _prevResponse
    ) internal view returns (bool) {
        return _badChainlinkResponse(_currentResponse) || _badChainlinkResponse(_prevResponse);
    }

    function _badChainlinkResponse(ChainlinkResponse memory _response) internal view returns (bool) {
        // Check for response call reverted
        if (!_response.success) {
            return true;
        }
        // Check for an invalid roundId that is 0
        if (_response.roundId == 0) {
            return true;
        }
        // Check for an invalid timeStamp that is 0, or in the future
        if (_response.timestamp == 0 || _response.timestamp > block.timestamp) {
            return true;
        }
        if (_response.cnyTimestamp == 0 || _response.cnyTimestamp > block.timestamp) {
            return true;
        }
        // Check for non-positive price
        if (_response.answer <= 0) {
            return true;
        }

        return false;
    }

    // Oracle is frozen if any of the connected data feeds timeouts
    function _chainlinkIsFrozen(ChainlinkResponse memory _response) internal view returns (bool) {
        return
            block.timestamp.sub(_response.timestamp) > TIMEOUT ||
            block.timestamp.sub(_response.cnyTimestamp) > CNY_TIMEOUT;
    }

    function _chainlinkPriceChangeAboveMax(
        ChainlinkResponse memory _currentResponse,
        ChainlinkResponse memory _prevResponse
    ) internal pure returns (bool) {
        uint256 currentScaledPrice = _scaleChainlinkPriceByDigits(
            uint256(_currentResponse.answer),
            _currentResponse.decimals
        );
        uint256 prevScaledPrice = _scaleChainlinkPriceByDigits(
            uint256(_prevResponse.answer),
            _prevResponse.decimals
        );

        uint256 minPrice = LiquityMath._min(currentScaledPrice, prevScaledPrice);
        uint256 maxPrice = LiquityMath._max(currentScaledPrice, prevScaledPrice);

        /*
         * Use the larger price as the denominator:
         * - If price decreased, the percentage deviation is in relation to the the previous price.
         * - If price increased, the percentage deviation is in relation to the current price.
         */
        uint256 percentDeviation = maxPrice.sub(minPrice).mul(DECIMAL_PRECISION).div(maxPrice);

        // Return true if price has more than doubled, or more than halved.
        return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
    }

    function _tellorIsBroken(TellorResponse memory _response) internal view returns (bool) {
        // Check for response call reverted
        if (!_response.success) {
            return true;
        }
        // Check for an invalid timeStamp that is 0, or in the future
        if (_response.timestamp == 0 || _response.timestamp > block.timestamp) {
            return true;
        }
        if (_response.cnyTimestamp == 0 || _response.cnyTimestamp > block.timestamp) {
            return true;
        }
        // Check for zero price
        if (_response.value == 0) {
            return true;
        }

        return false;
    }

    // Oracle is frozen if any of the connected data feeds timeouts
    function _tellorIsFrozen(TellorResponse memory _tellorResponse) internal view returns (bool) {
        return
            block.timestamp.sub(_tellorResponse.timestamp) > TIMEOUT ||
            block.timestamp.sub(_tellorResponse.cnyTimestamp) > CNY_TIMEOUT;
    }

    function _bothOraclesLiveAndUnbrokenAndSimilarPrice(
        ChainlinkResponse memory _chainlinkResponse,
        ChainlinkResponse memory _prevChainlinkResponse,
        TellorResponse memory _tellorResponse
    ) internal view returns (bool) {
        // Return false if either oracle is broken or frozen
        if (
            _tellorIsBroken(_tellorResponse) ||
            _tellorIsFrozen(_tellorResponse) ||
            _chainlinkIsBroken(_chainlinkResponse, _prevChainlinkResponse) ||
            _chainlinkIsFrozen(_chainlinkResponse)
        ) {
            return false;
        }

        return _bothOraclesSimilarPrice(_chainlinkResponse, _tellorResponse);
    }

    function _bothOraclesSimilarPrice(
        ChainlinkResponse memory _chainlinkResponse,
        TellorResponse memory _tellorResponse
    ) internal pure returns (bool) {
        uint256 scaledChainlinkPrice = _scaleChainlinkPriceByDigits(
            uint256(_chainlinkResponse.answer),
            _chainlinkResponse.decimals
        );
        uint256 scaledTellorPrice = _scaleTellorPriceByDigits(_tellorResponse.value);

        // Get the relative price difference between the oracles. Use the lower price as the denominator, i.e. the reference for the calculation.
        uint256 minPrice = LiquityMath._min(scaledTellorPrice, scaledChainlinkPrice);
        uint256 maxPrice = LiquityMath._max(scaledTellorPrice, scaledChainlinkPrice);
        uint256 percentPriceDifference = maxPrice.sub(minPrice).mul(DECIMAL_PRECISION).div(minPrice);

        /*
         * Return true if the relative price difference is <= 3%: if so, we assume both oracles are probably reporting
         * the honest market price, as it is unlikely that both have been broken/hacked and are still in-sync.
         */
        return percentPriceDifference <= MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES;
    }

    function _scaleChainlinkPriceByDigits(uint256 _price, uint256 _answerDigits)
        internal
        pure
        returns (uint256)
    {
        /*
         * Convert the price returned by the Chainlink oracle to an 18-digit decimal for use by Liquity.
         * At date of Liquity launch, Chainlink uses an 8-digit price, but we also handle the possibility of
         * future changes.
         *
         */
        uint256 price;
        if (_answerDigits >= TARGET_DIGITS) {
            // Scale the returned price value down to Liquity's target precision
            price = _price.div(10**(_answerDigits - TARGET_DIGITS));
        } else if (_answerDigits < TARGET_DIGITS) {
            // Scale the returned price value up to Liquity's target precision
            price = _price.mul(10**(TARGET_DIGITS - _answerDigits));
        }
        return price;
    }

    function _scaleTellorPriceByDigits(uint256 _price) internal pure returns (uint256) {
        return _price.mul(10**(TARGET_DIGITS - TELLOR_DIGITS));
    }

    function _changeStatus(Status _status) internal {
        status = _status;
        emit PriceFeedStatusChanged(_status);
    }

    function _storePrice(uint256 _currentPrice) internal {
        lastGoodPrice = _currentPrice;
        emit LastGoodPriceUpdated(_currentPrice);
    }

    function _storeTellorPrice(TellorResponse memory _tellorResponse) internal returns (uint256) {
        uint256 scaledTellorPrice = _scaleTellorPriceByDigits(_tellorResponse.value);
        _storePrice(scaledTellorPrice);

        return scaledTellorPrice;
    }

    function _storeChainlinkPrice(ChainlinkResponse memory _chainlinkResponse)
        internal
        returns (uint256)
    {
        uint256 scaledChainlinkPrice = _scaleChainlinkPriceByDigits(
            uint256(_chainlinkResponse.answer),
            _chainlinkResponse.decimals
        );
        _storePrice(scaledChainlinkPrice);

        return scaledChainlinkPrice;
    }

    // --- Oracle response wrapper functions ---

    function _getCurrentTellorResponse()
        internal
        view
        returns (TellorResponse memory tellorResponse)
    {
        // 1 Getting Tellor response from ETH/USD Oracle
        TellorResponse memory tellorResponseEth;

        try tellorCaller.getTellorCurrentValue(ETHUSD_TELLOR_REQ_ID) returns (
            bool ifRetrieve,
            uint256 value,
            uint256 _timestampRetrieved
        ) {
            // If call to Tellor succeeds, return the response and success = true
            tellorResponseEth.ifRetrieve = ifRetrieve;
            tellorResponseEth.value = value;
            tellorResponseEth.timestamp = _timestampRetrieved;
            tellorResponseEth.success = true;
        } catch {
            // If call to Tellor reverts, return a zero response with success = false
            return (tellorResponse);
        }

        // 2 Getting Tellor response from CNY/USD Oracle
        TellorResponse memory tellorResponseCny;
        try tellorCaller.getTellorCurrentValue(CNYUSD_TELLOR_REQ_ID) returns (
            bool ifRetrieve,
            uint256 value,
            uint256 _timestampRetrieved
        ) {
            // If call to Tellor succeeds, return the response and success = true
            tellorResponseCny.ifRetrieve = ifRetrieve;
            tellorResponseCny.value = value;
            tellorResponseCny.timestamp = _timestampRetrieved;
            tellorResponseCny.success = true;
        } catch {
            // If call to Tellor reverts, return a zero response with success = false
            return (tellorResponse);
        }

        // 3 Calculate cross pair price ETH/CNY and return the response

        // check both answers
        if (tellorResponseEth.value > 0 && tellorResponseCny.value > 0) {
            tellorResponse.ifRetrieve = true;
            tellorResponse.value = _getTellorDerivedPrice(
                tellorResponseEth.value,
                tellorResponseCny.value
            );
            tellorResponse.timestamp = tellorResponseEth.timestamp;
            tellorResponse.cnyTimestamp = tellorResponseCny.timestamp;
            tellorResponse.success = true;
        } else {
            // If any answer from Tellor returns zero, return a zero response with success = false
            return tellorResponse;
        }

        return tellorResponse;
    }

    function _getCurrentChainlinkResponse()
        internal
        view
        returns (ChainlinkResponse memory chainlinkResponse)
    {
        // 1 Getting chainlink response from ETH/USD Oracle
        ChainlinkResponse memory chainlinkResponseEth;

        // First, try to get current decimal precision:
        try priceAggregatorEth.decimals() returns (uint8 decimals) {
            // If call to Chainlink succeeds, record the current decimal precision
            chainlinkResponseEth.decimals = decimals;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }
        uint8 _currentDecimals = chainlinkResponseEth.decimals;

        // Secondly, try to get latest price data:
        try priceAggregatorEth.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256, /* startedAt */
            uint256 timestamp,
            uint80 /* answeredInRound */
        ) {
            // If call to Chainlink succeeds, return the response and success = true
            chainlinkResponseEth.roundId = roundId;
            chainlinkResponseEth.answer = answer;
            chainlinkResponseEth.timestamp = timestamp;
            chainlinkResponseEth.success = true;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }

        // 2 Getting chainlink response from CNY/USD Oracle
        ChainlinkResponse memory chainlinkResponseCny;

        // First, try to get current decimal precision:
        try priceAggregatorCny.decimals() returns (uint8 decimals) {
            // If call to Chainlink succeeds, record the current decimal precision
            chainlinkResponseCny.decimals = decimals;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }

        // Secondly, try to get latest price data:
        try priceAggregatorCny.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256, /* startedAt */
            uint256 timestamp,
            uint80 /* answeredInRound */
        ) {
            // If call to Chainlink succeeds, return the response and success = true
            chainlinkResponseCny.roundId = roundId;
            chainlinkResponseCny.answer = answer;
            chainlinkResponseCny.timestamp = timestamp;
            chainlinkResponseCny.success = true;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }

        // 3 Calculate cross pair price ETH/CNY and return the response
        // check both answers
        if (chainlinkResponseEth.answer > 0 && chainlinkResponseCny.answer > 0) {
            chainlinkResponse.roundId = chainlinkResponseEth.roundId;
            chainlinkResponse.cnyRoundId = chainlinkResponseCny.roundId;
            chainlinkResponse.decimals = chainlinkResponseEth.decimals;
            chainlinkResponse.timestamp = chainlinkResponseEth.timestamp;
            chainlinkResponse.cnyTimestamp = chainlinkResponseCny.timestamp;
            chainlinkResponse.answer = _getDerivedPrice(
                chainlinkResponseEth.answer,
                chainlinkResponseEth.decimals,
                chainlinkResponseCny.answer,
                chainlinkResponseCny.decimals,
                _currentDecimals
            );
            chainlinkResponse.success = true;
        } else {
            // If any answer from Chainlink aggregator returns zero, return a zero response with success = false
            return chainlinkResponse;
        }

        return chainlinkResponse;
    }

    function _getPrevChainlinkResponse(
        uint80 _ethRoundId,
        uint80 _cnyRoundId,
        uint8 _currentDecimals
    ) internal view returns (ChainlinkResponse memory prevChainlinkResponse) {
        /*
         * NOTE: Chainlink only offers a current decimals() value - there is no way to obtain the decimal precision used in a
         * previous round.  We assume the decimals used in the previous round are the same as the current round.
         */

        /*
         * NOTE: We assume that decimals for ETH/USD and CNY/USD oracles are the same (i.e. 8 digits)
         */

        // 1 Getting chainlink response from ETH/USD Oracle
        ChainlinkResponse memory chainlinkResponseEth;

        // Try to get the price data from the previous round:
        try priceAggregatorEth.getRoundData(_ethRoundId - 1) returns (
            uint80 roundId,
            int256 answer,
            uint256, /* startedAt */
            uint256 timestamp,
            uint80 /* answeredInRound */
        ) {
            // If call to Chainlink succeeds, return the response and success = true
            chainlinkResponseEth.roundId = roundId;
            chainlinkResponseEth.answer = answer;
            chainlinkResponseEth.timestamp = timestamp;
            chainlinkResponseEth.decimals = _currentDecimals;
            chainlinkResponseEth.success = true;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return prevChainlinkResponse;
        }

        // 2 Getting chainlink response from CNY/USD Oracle
        ChainlinkResponse memory chainlinkResponseCny;

        // Secondly, try to get latest price data:
        try priceAggregatorCny.getRoundData(_cnyRoundId - 1) returns (
            uint80 roundId,
            int256 answer,
            uint256, /* startedAt */
            uint256 timestamp,
            uint80 /* answeredInRound */
        ) {
            // If call to Chainlink succeeds, return the response and success = true
            chainlinkResponseCny.roundId = roundId;
            chainlinkResponseCny.answer = answer;
            chainlinkResponseCny.timestamp = timestamp;
            chainlinkResponseCny.decimals = _currentDecimals;
            chainlinkResponseCny.success = true;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return prevChainlinkResponse;
        }

        // 3 Calculate cross pair price ETH/CNY and return the response

        // check both answers
        if (chainlinkResponseEth.answer > 0 && chainlinkResponseCny.answer > 0) {
            prevChainlinkResponse.roundId = chainlinkResponseEth.roundId;
            prevChainlinkResponse.cnyRoundId = chainlinkResponseCny.roundId;
            prevChainlinkResponse.decimals = chainlinkResponseEth.decimals;
            prevChainlinkResponse.timestamp = chainlinkResponseEth.timestamp;
            prevChainlinkResponse.cnyTimestamp = chainlinkResponseCny.timestamp;
            prevChainlinkResponse.answer = _getDerivedPrice(
                chainlinkResponseEth.answer,
                chainlinkResponseEth.decimals,
                chainlinkResponseCny.answer,
                chainlinkResponseCny.decimals,
                _currentDecimals
            );
            prevChainlinkResponse.success = true;
        } else {
            // If any answer from Chainlink aggregator returns zero, return a zero response with success = false
            return prevChainlinkResponse;
        }

        return prevChainlinkResponse;
    }

    function _getDerivedPrice(
        int256 _basePrice,
        uint8 _baseDecimals,
        int256 _quotePrice,
        uint8 _quoteDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        uint256 decimals = 10**uint256(_decimals);
        uint256 basePrice = _scalePrice(uint256(_basePrice), _baseDecimals, _decimals);
        uint256 quotePrice = _scalePrice(uint256(_quotePrice), _quoteDecimals, _decimals);

        return int256(basePrice.mul(decimals).div(quotePrice));
    }

    function _getTellorDerivedPrice(uint256 _basePrice, uint256 _quotePrice)
        internal
        pure
        returns (uint256)
    {
        uint256 decimals = 10**uint256(TELLOR_DIGITS);
        return _basePrice.mul(decimals).div(_quotePrice);
    }

    function _scalePrice(
        uint256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (uint256) {
        if (_priceDecimals < _decimals) {
            return _price.mul(10**uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price.div(10**uint256(_priceDecimals - _decimals));
        }
        return _price;
    }
}