//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./transferGuards/ITransferGuard.sol";

struct AssetGuardConfig {
    ITransferGuard guardContract;
    bytes guardData;
}

struct AssetConfig {
    AssetGuardConfig[] guards;
}

contract FiboTransferAgent is Ownable {
    using SafeMath for uint256;

    event AssetTransferred(address indexed asset, address from, address to, uint256 quantity);

    struct AssetStatus {
        mapping(address => uint256) balances;
        uint256 totalSupply;
        AssetConfig config;
        bool exists;
    }

    mapping(address => AssetStatus) public assets;

    modifier onlyOwnerOrAsset(address asset) {
        require(assets[asset].exists, "unknown asset");
        require(msg.sender == owner() || msg.sender == asset, "unauthorized");
        _;
    }

    function register(AssetConfig calldata config) public {
        address token = msg.sender;
        require(!assets[token].exists, "already registered");

        validateGuards(config.guards);
        assets[token].config = config;
        assets[token].exists = true;
    }

    function updateAssetConfig(address asset, AssetConfig calldata config) external onlyOwner {
        require(assets[asset].exists, "unknown asset");
        validateGuards(config.guards);
        assets[asset].config = config;
    }

    function validateGuards(AssetGuardConfig[] memory guards) private {
        for (uint i = 0; i < guards.length; ++i) {
            (bool success, bytes memory returnData) = address(guards[i].guardContract).call(abi.encodePacked(guards[i].guardContract.isTransferGuard.selector, abi.encode()));

            require(success && returnData.length == 32 && abi.decode(returnData, (bytes32)) ==
                keccak256("checkTransfer(address,address,address,address,uint,bytes)"),
                "doesn't match interface");
        }
    }

    function validateTransfer(address asset, address initiator, address sender, address receiver, uint quantity) private {
        AssetGuardConfig[] storage guards = assets[asset].config.guards;
        for (uint i = 0; i < guards.length; ++i) {
            // this will revert if the transfer isn't valid
            guards[i].guardContract.checkTransfer(asset, initiator, sender, receiver, quantity, guards[i].guardData);
        }
    }

    function transfer(address asset, address initiator, address from, address to, uint256 quantity) public onlyOwnerOrAsset(asset) {
        require(assets[asset].balances[from] >= quantity, "insufficient quantity");
        (bool valid, uint256 newQuantity) = assets[asset].balances[to].tryAdd(quantity);
        require(valid, "recipient balance overflow");

        validateTransfer(asset, initiator, from, to, quantity);

        assets[asset].balances[from] -= quantity;
        assets[asset].balances[to] = newQuantity;

        emit AssetTransferred(asset, from, to, quantity);
    }

    function getBalance(address asset, address user) public view returns (uint256 balance) {
        balance = assets[asset].balances[user];
    }

    function totalSupply(address asset) public view returns (uint256 supply) {
        return assets[asset].totalSupply;
    }

    function mint(address asset, address initiator, address user, uint256 amount) public onlyOwnerOrAsset(asset) {
        bool valid;
        uint256 newBalance;
        uint256 newSupply;

        (valid, newBalance) = assets[asset].balances[user].tryAdd(amount);
        require(valid, "user balance overflow");

        (valid, newSupply) = assets[asset].totalSupply.tryAdd(amount);
        require(valid, "supply overflow");

        validateTransfer(asset, initiator, address(0), user, amount);

        assets[asset].balances[user] = newBalance;
        assets[asset].totalSupply = newSupply;
    }

    // no validation needed to burn
    function burn(address asset, address user, uint256 amount) public onlyOwnerOrAsset(asset) {
        require(assets[asset].balances[user] >= amount, "insufficient assets");
        assets[asset].balances[user] -= amount;
        assets[asset].totalSupply -= amount;
    }

    function assetConfig(address asset) external view returns (AssetConfig memory) {
        return assets[asset].config;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title an interface enabling pluggable criteria for transfer agents to validate transactions
 */
interface ITransferGuard {
    /**
     * @notice this function is called for any asset transfer, and should revert if the transfer is invalid
     * @param asset the address of the asset being transferred
     * @param initiator the address of the account initiating this transaction
     * @param sender the address of the account sending the asset
     * @param receiver the address of the account receiving the asset
     * @param quantity the number of tokens being sent
     * @param data any additional parameters needed to perform this check; this data is application-specific
     */
    function checkTransfer(address asset, address initiator, address sender, address receiver, uint quantity, bytes memory data) external;

    /// @notice contracts must implement this function to indicate that they can be used as a transfer guard
    /// @return result keccak256("checkTransfer(address,address,address,uint,bytes)") iff the contract supports this interface
    function isTransferGuard() external pure returns (bytes32);
}

abstract contract TransferGuardBase is ITransferGuard {
    bytes32 constant public _TRANSFER_GUARD_HASH =  keccak256("checkTransfer(address,address,address,address,uint,bytes)");

    function isTransferGuard() external pure override returns (bytes32) {
        return _TRANSFER_GUARD_HASH;
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