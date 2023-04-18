// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IBaseLevel.sol";

interface ISFStream {
    function getFlowRate(address superToken, address player) external view returns (int96);
}

interface IMCCrosschainServices {
    function getNewlandsGenesisBalance(address _user) external view returns (uint256);
}

error BaseLevel__TraderNotSet(address _trader);
error BaseLevel__SuperAddressNotSetUp();

contract BaseLevel is IBaseLevel, OwnableUpgradeable {
    mapping(address => mapping(uint => uint)) public traderCapacity;
    address public superAppAddress;
    address public superTokenAddress;
    address public superTokenLiteAddress;
    uint public superFluidPerLevel;
    address public crosschainServicesAddress;
    uint genesisLevel;

    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @notice get base level for user.
     * @param _user to get base level for.
     * @return _level returns level of user.
     */
    function getBaseLevel(address _user) public view returns (uint _level) {
        return 36;
        if (superFluidPerLevel == 0) revert("superFluidPerLevel not set");
        if (superAppAddress == address(0) || superTokenAddress == address(0) || superTokenLiteAddress == address(0))
            revert BaseLevel__SuperAddressNotSetUp();
        uint constantLevel = 6;
        if (IMCCrosschainServices(crosschainServicesAddress).getNewlandsGenesisBalance(_user) != 0) {
            return genesisLevel;
        }
        int96 sfLevel = ISFStream(superAppAddress).getFlowRate(superTokenAddress, _user);
        int96 sfLevelLite = ISFStream(superAppAddress).getFlowRate(superTokenLiteAddress, _user);
        if (sfLevel != 0 || sfLevelLite != 0)
            return (uint(uint96(sfLevel + sfLevelLite)) / superFluidPerLevel) + constantLevel;
        return constantLevel;
    }

    /// @inheritdoc IBaseLevel
    function getOrderCapacity(address _trader, address _user) external view override returns (uint _extraOrders) {
        if (traderCapacity[_trader][5] == 0) revert BaseLevel__TraderNotSet(_trader);
        uint userLevel = getBaseLevel(_user);
        return _getCapacity(userLevel, _trader);
    }

    /**
     * @notice Internal function to get order amount for ITrader depending on level.
     * @param _baseLevel order amount for input base level.
     * @param _trader ITrader address.
     * @return return order amount.
     */
    function _getCapacity(uint _baseLevel, address _trader) internal view returns (uint) {
        for (uint i = _baseLevel; i > 0; i--) {
            if (traderCapacity[_trader][i] != 0) {
                return traderCapacity[_trader][i];
            }
        }
        revert("invalid baseLevel");
    }

    /// @inheritdoc IBaseLevel
    function setOrderCapacity(
        address _trader,
        uint _fromLevel,
        uint _toLevel,
        uint _additionalOrders
    ) external override onlyOwner {
        if (_fromLevel > _toLevel) revert("_fromLevel is greater than _toLevel");

        for (uint i = _fromLevel; i <= _toLevel; i++) {
            traderCapacity[_trader][i] = _additionalOrders;
        }
    }

    /// @inheritdoc IBaseLevel
    function setSuperAppAddress(address _superAppAddress) external override onlyOwner {
        superAppAddress = _superAppAddress;
    }

    /// @inheritdoc IBaseLevel
    function setSuperTokens(address _superToken, address _superTokenLite) external override onlyOwner {
        superTokenAddress = _superToken;
        superTokenLiteAddress = _superTokenLite;
    }

    /// @inheritdoc IBaseLevel
    function setSuperFluidPerLevel(uint _superFluidPerLevel) external override onlyOwner {
        superFluidPerLevel = _superFluidPerLevel;
    }

    function setCrosschainServicesAddress(address _crosschainServices) external onlyOwner {
        crosschainServicesAddress = _crosschainServices;
    }

    function setGenesisLevel(uint _level) external onlyOwner {
        genesisLevel = _level;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface IBaseLevel {

    /**
    * @notice Set super app address.
    * @param _superAppAddress address of MissionControlStream.
    */
    function setSuperAppAddress(address _superAppAddress) external;

    /**
    * @notice Set sf flow per month per level.
    * @param _superFluidPerLevel flow per level.
    */
    function setSuperFluidPerLevel(uint _superFluidPerLevel) external;

    /**
    * @notice Set numbers of orders for a ITrader depending users level.
    * @param _trader address of ITrader.
    * @param _fromLevel from this level to _toLevel will be set to _additionalOrders.
    * @param _toLevel from this level to _fromLevel  will be set to _additionalOrders.
    * @param _additionalOrders number of orders a trader will have for input level range.
    */
    function setOrderCapacity(address _trader, uint _fromLevel, uint _toLevel, uint _additionalOrders) external;

    /**
    * @notice Set address for super token and super token lite.
    * @param _superToken address for super token.
    * @param _superTokenLite address for super token lite.
    */
    function setSuperTokens(address _superToken, address _superTokenLite) external;

    /**
    * @notice Get number of orders for a user for a ITrader.
    * @param _trader address of ITrader.
    * @param _user user to look up capacity for.
    */
    function getOrderCapacity(address _trader, address _user) external view returns(uint _extraOrders);

}