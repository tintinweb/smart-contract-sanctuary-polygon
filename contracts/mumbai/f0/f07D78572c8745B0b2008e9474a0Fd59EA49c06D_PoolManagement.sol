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
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IAssetPool {
    struct UserAssetInfo {
        address asset;
        uint256 tokenId;
        uint256 amount;
    }

    function setPid(uint256 _pid) external;

    function isActivatedAsset(address _asset) external returns (bool);

    function liquidityByAsset(address _asset) external returns (uint256);

    function borrowsByAsset(address _asset) external returns (uint256);

    function updateBorrows(address _asset, uint256 _amount, bool _isIncrease) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IAssetPool.sol";

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IAssetPool1155 is IAssetPool {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IAssetPool.sol";

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IAssetPool721 is IAssetPool {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPlayerRental {
    struct OrderInfo {
        /// @dev order index, starts from 0
        uint32 orderId;
        /// @dev order expiration timestamp
        uint64 expireAt;
        /// @dev borrower address
        address user;
        /// @dev asset address
        address asset;
        /// @dev asset token Id
        uint256 tokenId;
        /// @dev asset amount
        uint256 amount;
    }

    struct RefToOrdersByUser {
        /// @dev user address in ordersByUser
        address user;
        /// @dev index of the order list in ordersByUser
        uint256 index;
    }

    function setPid(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPoolManagement {
    struct PoolInfo {
        string poolName;
        address assetPool721;
        address assetPool1155;
        address playerRental;
        address riskStrategy;
    }

    function isActivatedPool(uint256 _pid) external view returns (bool);

    function getPoolInfo(uint256 _pid) external view returns (string memory, address, address, address, address);

    function poolCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IRiskStrategy {
    function setPid(uint256 _pid) external;

    function getActualUtilizationRate(uint256 _totalLiquidity, uint256 _totalBorrows) external view returns (uint256);

    function getPXPCost(uint256 uActual) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IPoolManagement.sol";
import "../interfaces/IAssetPool721.sol";
import "../interfaces/IAssetPool1155.sol";
import "../interfaces/IPlayerRental.sol";
import "../interfaces/IRiskStrategy.sol";

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

contract PoolManagement is IPoolManagement, Ownable {
    /// @notice ParagonsDAO Asset Pools
    PoolInfo[] public pools;

    /// @dev PoolId -> Bool
    mapping(uint256 => bool) public isActivatedPool;

    error EmptyPoolName();
    error EmptyAssetPool();
    error ZeroAddress();
    error PoolIndexInvalid(uint256 pid);
    error PoolAlreadyActivated(uint256 pid);
    error PoolAlreadyDeactivated(uint256 pid);

    event PoolAdded(uint256 indexed pid, string indexed poolName, address playerRental, address riskStrategy);
    event PoolActivated(uint256 indexed pid);
    event PoolDeactivated(uint256 indexed pid);

    constructor() {}

    /// @notice Add the new pool
    /// @dev Only owner
    /// @dev The pool added is activated automatically
    /// @dev The pool added can't be removed but can be deactivated
    /// @param _poolName Pool name
    /// @param _assetPool721 ERC721 asset pool
    /// @param _assetPool1155 ERC1155 asset pool
    /// @param _playerRental PlayerRental contract of the pool
    /// @param _riskStrategy RiskStrategy contract of the pool
    /// @return pid Pool Id
    function addPool(
        string calldata _poolName,
        address _assetPool721,
        address _assetPool1155,
        address _playerRental,
        address _riskStrategy
    ) external onlyOwner returns (uint256 pid) {
        if (bytes(_poolName).length == 0) revert EmptyPoolName();
        if (_assetPool721 == address(0) && _assetPool1155 == address(0)) revert EmptyAssetPool();
        if (_playerRental == address(0)) revert ZeroAddress();
        if (_riskStrategy == address(0)) revert ZeroAddress();

        // add the new pool
        pools.push(
            PoolInfo({
                poolName: _poolName,
                assetPool721: _assetPool721,
                assetPool1155: _assetPool1155,
                playerRental: _playerRental,
                riskStrategy: _riskStrategy
            })
        );
        pid = pools.length - 1;
        isActivatedPool[pid] = true;

        // set the pid to pool-related contracts
        if (_assetPool721 != address(0)) {
            IAssetPool721(_assetPool721).setPid(pid);
        }
        if (_assetPool1155 != address(0)) {
            IAssetPool1155(_assetPool1155).setPid(pid);
        }
        IPlayerRental(_playerRental).setPid(pid);
        IRiskStrategy(_riskStrategy).setPid(pid);

        emit PoolAdded(pid, _poolName, _playerRental, _riskStrategy);
    }

    /// @notice Activate the pool
    /// @dev Only owner
    /// @param _pid Pool Id
    function activatePool(uint256 _pid) external onlyOwner {
        // check the pid
        if (_pid >= pools.length) revert PoolIndexInvalid(_pid);

        // check the activation status
        if (isActivatedPool[_pid]) revert PoolAlreadyActivated(_pid);

        // activate the pool
        isActivatedPool[_pid] = true;

        emit PoolActivated(_pid);
    }

    /// @notice Deactivate the pool
    /// @dev Only onwer
    /// @param _pid Pool Id
    function deactivatePool(uint256 _pid) external onlyOwner {
        // check the pid
        if (_pid >= pools.length) revert PoolIndexInvalid(_pid);

        // check the activation status
        if (!isActivatedPool[_pid]) revert PoolAlreadyDeactivated(_pid);

        // deactivate the pool
        isActivatedPool[_pid] = false;

        emit PoolDeactivated(_pid);
    }

    /// @notice Returns the pool info
    /// @param _pid Pool Id
    function getPoolInfo(
        uint256 _pid
    )
        external
        view
        returns (
            string memory poolName,
            address assetPool721,
            address assetPool1155,
            address playerRental,
            address riskStrategy
        )
    {
        return (
            pools[_pid].poolName,
            pools[_pid].assetPool721,
            pools[_pid].assetPool1155,
            pools[_pid].playerRental,
            pools[_pid].riskStrategy
        );
    }

    /// @dev Returns the number of pools
    function poolCount() external view returns (uint256) {
        return pools.length;
    }
}