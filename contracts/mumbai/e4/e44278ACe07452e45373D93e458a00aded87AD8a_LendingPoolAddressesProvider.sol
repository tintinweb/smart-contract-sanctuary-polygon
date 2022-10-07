// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from '../Dependency/openzeppelin/Ownable.sol';
import {ILendingPoolAddressesProvider} from '../Interface/ILendingPoolAddressesProvider.sol';
import {Errors} from '../Library/Helper/Errors.sol';

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
contract LendingPoolAddressesProvider is Ownable, ILendingPoolAddressesProvider {
  mapping(bytes32 => address) private _addresses;

  bytes32 private constant MAIN_ADMIN = 'MAIN_ADMIN';
  bytes32 private constant EMERGENCY_ADMIN = 'EMERGENCY_ADMIN';
  bytes32 private constant PRICE_ORACLE = 'PRICE_ORACLE';
  bytes32 private constant SWAP_ROUTER = 'SWAP_ROUTER';

  address[] private lendingPoolAddressArray;
  mapping(address => uint) private lendingPoolID;
  mapping(address => address) private lendingPoolConfigurator;
  mapping(address => bool) private lendingPoolValid;

  constructor(
    address mainAdmin,
    address emergencyAdmin,
    address oracleAddress,
    address swapRouterAddress
  ) {
    _addresses[MAIN_ADMIN] = mainAdmin;
    _addresses[EMERGENCY_ADMIN] = emergencyAdmin;
    _addresses[PRICE_ORACLE] = oracleAddress;
    _addresses[SWAP_ROUTER] = swapRouterAddress;
  }

  function _addPool(
    address poolAddress,
    address poolConfiguratorAddress
  ) internal {
    require(lendingPoolValid[poolAddress] != true, Errors.GetError(Errors.Error.LENDING_POOL_EXIST));
    lendingPoolValid[poolAddress] = true;
    lendingPoolID[poolAddress] = lendingPoolAddressArray.length;
    lendingPoolAddressArray.push(poolAddress);
    lendingPoolConfigurator[poolAddress] = poolConfiguratorAddress;
    emit PoolAdded(poolAddress, poolConfiguratorAddress);
  }

  function _removePool(address poolAddress) internal {
    require(lendingPoolValid[poolAddress] == true, Errors.GetError(Errors.Error.LENDING_POOL_NONEXIST));
    delete lendingPoolValid[poolAddress];
    delete lendingPoolConfigurator[poolAddress];
    delete lendingPoolID[poolAddress];
    emit PoolRemoved(poolAddress);
  }

  function getAllPools() external override view returns (address[] memory) {
    uint cachedPoolLength = lendingPoolAddressArray.length;
    uint poolNumber = 0;
    for (uint i = 0; i < cachedPoolLength; i++) {
        address cachedPoolAddress = lendingPoolAddressArray[i];
        if (lendingPoolValid[cachedPoolAddress] == true) {
            poolNumber = poolNumber + 1;
        }
    }
    address[] memory validPools = new address[](poolNumber);

    uint idx = 0;
    for (uint i = 0; i < cachedPoolLength; i++) {
        address cachedPoolAddress = lendingPoolAddressArray[i];
        if (lendingPoolValid[cachedPoolAddress] == true) {
            validPools[idx] = cachedPoolAddress;
            idx = idx + 1;
        }
    }
    return validPools;
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function addPool(address poolAddress, address poolConfiguratorAddress) external override onlyOwner {
    _addPool(poolAddress, poolConfiguratorAddress);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function removePool(address poolAddress) external override onlyOwner {
    _removePool(poolAddress);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function getLendingPool(uint id) external view override returns (address, bool) {
    return (lendingPoolAddressArray[id], lendingPoolValid[lendingPoolAddressArray[id]]);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function getLendingPoolID(address pool) external view override returns (uint) {
    return lendingPoolID[pool];
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function getLendingPoolConfigurator(address pool) external view override returns (address) {
    return lendingPoolConfigurator[pool];
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function setLendingPool(uint id, address pool, address poolConfiguratorAddress) external override onlyOwner {
    lendingPoolAddressArray[id] = pool;
    lendingPoolValid[pool] = true;
    lendingPoolConfigurator[pool] = poolConfiguratorAddress;
    emit LendingPoolUpdated(id, pool, poolConfiguratorAddress);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function setAddress(bytes32 id, address newAddress) external override onlyOwner {
    _addresses[id] = newAddress;
    emit AddressSet(id, newAddress);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function getAddress(bytes32 id) public view override returns (address) {
    return _addresses[id];
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function getMainAdmin() external view override returns (address) {
    return getAddress(MAIN_ADMIN);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function setMainAdmin(address admin) external override onlyOwner {
    _addresses[MAIN_ADMIN] = admin;
    emit ConfigurationAdminUpdated(admin);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function getEmergencyAdmin() external view override returns (address) {
    return getAddress(EMERGENCY_ADMIN);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function setEmergencyAdmin(address emergencyAdmin) external override onlyOwner {
    _addresses[EMERGENCY_ADMIN] = emergencyAdmin;
    emit EmergencyAdminUpdated(emergencyAdmin);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function getPriceOracle() external view override returns (address) {
    return getAddress(PRICE_ORACLE);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function setPriceOracle(address priceOracleAddress) external override onlyOwner {
    _addresses[PRICE_ORACLE] = priceOracleAddress;
    emit PriceOracleUpdated(priceOracleAddress);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function getSwapRouter() external view override returns (address) {
    return getAddress(SWAP_ROUTER);
  }

  /// @inheritdoc ILendingPoolAddressesProvider
  function setSwapRouter(address swapRouter) external override onlyOwner {
    _addresses[SWAP_ROUTER] = swapRouter;
    emit SwapRouterUpdated(swapRouter);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
pragma solidity ^0.8.0;

interface ILendingPoolAddressesProvider {
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress);
  event PoolAdded(address pool_address, address configuratorAddress);
  event LendingPoolUpdated(uint id, address pool, address lending_pool_configurator_address);
  event PoolRemoved(address pool_address);
  event SwapRouterUpdated(address dex);

  function getAllPools() external view returns (address[] memory);

  /**
   * @dev Returns the address of the LendingPool by id
   * @return The LendingPool address, if pool is valid
   **/
  function getLendingPool(uint id) external view returns (address, bool);

  function getLendingPoolID(address pool) external view returns (uint);

  function getLendingPoolConfigurator(address pool) external view returns (address);

  /**
   * @dev Updates the address of the LendingPool
   * @param pool The new LendingPool implementation
   **/
  function setLendingPool(uint id, address pool, address poolConfiguratorAddress) external;

  function addPool(address poolAddress, address poolConfiguratorAddress) external;

  function removePool(address poolAddress) external;

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) external view returns (address);

  function getMainAdmin() external view returns (address);

  function setMainAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracleAddress) external;

  function getSwapRouter() external view returns (address);

  function setSwapRouter(address dex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Strings} from "../../Dependency/openzeppelin/Strings.sol";

library Errors {
    using Strings for uint256;
    enum Error {
        /** KTOKEN, DTOKEN*/
        CALLER_MUST_BE_LENDING_POOL, // 0
        INVALID_BURN_AMOUNT,
        INVALID_MINT_AMOUNT,
        BORROW_ALLOWANCE_NOT_ENOUGH,
        /** Math library */
        MATH_MULTIPLICATION_OVERFLOW,
        MATH_DIVISION_BY_ZERO, // 5
        MATH_ADDITION_OVERFLOW,
        /** Configuration */
        LENDING_POOL_EXIST,
        LENDING_POOL_NONEXIST,
        /** Permission */
        CALLER_NOT_MAIN_ADMIN,
        CALLER_NOT_EMERGENCY_ADMIN, // 10
        /** LP */
        LP_NOT_CONTRACT,
        LP_IS_PAUSED,
        LP_POSITION_IS_PAUSED,
        LPC_RESERVE_LIQUIDITY_NOT_0,
        LPC_INVALID_CONFIGURATION, // 15
        LP_NO_MORE_RESERVES_ALLOWED,
        LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR,
        LP_LIQUIDATION_CALL_FAILED,
        LP_CALLER_MUST_BE_AN_KTOKEN,
        LP_LEVERAGE_INVALID, // 20
        LP_POSITION_INVALID,
        LP_LIQUIDATE_LP,
        LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN,
        /** Reserve Logic */
        RL_LIQUIDITY_INDEX_OVERFLOW,
        RL_BORROW_INDEX_OVERFLOW,
        RL_RESERVE_ALREADY_INITIALIZED, // 25
        RL_LIQUIDITY_RATE_OVERFLOW,
        RL_BORROW_RATE_OVERFLOW,
        /** Validation Logic */
        VL_INVALID_AMOUNT,
        VL_NO_ACTIVE_RESERVE,
        VL_NO_ACTIVE_RESERVE_POSITION, // 30
        VL_POSITION_COLLATERAL_NOT_ENABLED,
        VL_POSITION_LONG_NOT_ENABLED,
        VL_POSITION_SHORT_NOT_ENABLED,
        VL_RESERVE_FROZEN,
        VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE, // 35
        VL_TRANSFER_NOT_ALLOWED,
        VL_BORROWING_NOT_ENABLED,
        VL_INVALID_INTEREST_RATE_MODE_SELECTED,
        VL_COLLATERAL_BALANCE_IS_0,
        VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD, // 40
        VL_COLLATERAL_CANNOT_COVER_NEW_BORROW,
        VL_NO_DEBT_OF_SELECTED_TYPE,
        VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF,
        VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0,
        VL_SUPPLY_ALREADY_IN_USE, // 45
        VL_TRADER_ADDRESS_MISMATCH,
        VL_POSITION_NOT_OPEN,
        VL_POSITION_NOT_UNHEALTHY,
        VL_INCONSISTENT_FLASHLOAN_PARAMS,
        /** Collateral Manager */
        CM_NO_ERROR, // 50
        CM_NO_ACTIVE_RESERVE,
        CM_HEALTH_FACTOR_ABOVE_THRESHOLD,
        CM_COLLATERAL_CANNOT_BE_LIQUIDATED,
        CM_CURRRENCY_NOT_BORROWED,
        CM_NOT_ENOUGH_LIQUIDITY, // 55
        /** Liquidation Logic */
        LL_HEALTH_FACTOR_NOT_BELOW_THRESHOLD,
        LL_COLLATERAL_CANNOT_BE_LIQUIDATED,
        LL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER,
        LL_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE,
        LL_NO_ERRORS // 60
    }

    function GetError(Error error) internal pure returns (string memory error_string) {
        error_string = Strings.toString(uint(error));
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}