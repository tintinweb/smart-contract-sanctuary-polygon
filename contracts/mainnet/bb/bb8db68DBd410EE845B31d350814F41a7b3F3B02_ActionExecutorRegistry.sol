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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { IRegistry } from './interfaces/IRegistry.sol';
import { IVault } from './interfaces/IVault.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { SystemVersionId } from './SystemVersionId.sol';
import { TargetGasReserve } from './crosschain/TargetGasReserve.sol';
import { ZeroAddressError } from './Errors.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './helpers/DecimalsHelper.sol' as DecimalsHelper;
import './DataStructures.sol' as DataStructures;
import './Constants.sol' as Constants;

contract ActionExecutorRegistry is SystemVersionId, TargetGasReserve, BalanceManagement, IRegistry {
    mapping(uint256 => address) public gatewayMap;
    uint256[] public gatewayTypeList;
    mapping(uint256 => DataStructures.OptionalValue) public gatewayTypeIndexMap;
    mapping(address => bool) public isGatewayAddress;

    mapping(uint256 => address) public routerMap;
    uint256[] public routerTypeList;
    mapping(uint256 => DataStructures.OptionalValue) public routerTypeIndexMap;
    mapping(uint256 => address) public routerTransferMap;

    mapping(uint256 => address) public vaultMap;
    uint256[] public vaultTypeList;
    mapping(uint256 => DataStructures.OptionalValue) public vaultTypeIndexMap;

    // Keys: vault type, chain id
    mapping(uint256 => mapping(uint256 => DataStructures.OptionalValue)) public vaultDecimalsTable;

    uint256[] public vaultDecimalsChainIdList;
    mapping(uint256 => DataStructures.OptionalValue) public vaultDecimalsChainIdIndexMap;

    uint256 public systemFee; // System fee in millipercent
    address public feeCollector;
    address public feeCollectorLocal;

    address[] public whitelist;
    mapping(address => DataStructures.OptionalValue) public whitelistIndexMap;

    // Swap amount limits with decimals = 18
    uint256 public swapAmountMin = 0;
    uint256 public swapAmountMax = Constants.INFINITY;

    uint256 private constant VAULT_DECIMALS_CHAIN_ID_WILDCARD = 0;
    uint256 private constant SYSTEM_FEE_LIMIT = 10_000; // Maximum system fee in millipercent = 10%

    event SetGateway(uint256 indexed gatewayType, address indexed gatewayAddress);
    event RemoveGateway(uint256 indexed gatewayType);

    event SetVault(uint256 indexed vaultType, address indexed vault);
    event RemoveVault(uint256 indexed vaultType);

    event SetVaultDecimals(uint256 indexed vaultType, DataStructures.KeyToValue[] decimalsData);
    event UnsetVaultDecimals(uint256 indexed vaultType, uint256[] chainIds);

    event SetRouter(uint256 indexed routerType, address indexed routerAddress);
    event RemoveRouter(uint256 indexed routerType);
    event SetRouterTransfer(uint256 indexed routerType, address indexed routerTransfer);

    event SetSystemFee(uint256 systemFee);
    event SetFeeCollector(address indexed feeCollector);
    event SetFeeCollectorLocal(address indexed feeCollector);

    event SetWhitelist(address indexed whitelistAddress, bool indexed value);

    event SetSwapAmountMin(uint256 value);
    event SetSwapAmountMax(uint256 value);

    error DuplicateGatewayAddressError();
    error GatewayNotSetError();
    error RouterNotSetError();
    error SwapAmountMaxLessThanMinError();
    error SwapAmountMinGreaterThanMaxError();
    error SystemFeeValueError();
    error VaultNotSetError();

    constructor(
        DataStructures.KeyToAddressValue[] memory _gateways,
        uint256 _systemFee, // System fee in millipercent
        address _feeCollector,
        address _feeCollectorLocal,
        uint256 _targetGasReserve,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        for (uint256 index; index < _gateways.length; index++) {
            DataStructures.KeyToAddressValue memory item = _gateways[index];

            _setGateway(item.key, item.value);
        }

        _setSystemFee(_systemFee);

        _setFeeCollector(_feeCollector);
        _setFeeCollectorLocal(_feeCollectorLocal);

        _setTargetGasReserve(_targetGasReserve);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    function setGateway(uint256 _gatewayType, address _gatewayAddress) external onlyManager {
        _setGateway(_gatewayType, _gatewayAddress);
    }

    function removeGateway(uint256 _gatewayType) external onlyManager {
        address gatewayAddress = gatewayMap[_gatewayType];

        if (gatewayAddress == address(0)) {
            revert GatewayNotSetError();
        }

        DataStructures.combinedMapRemove(
            gatewayMap,
            gatewayTypeList,
            gatewayTypeIndexMap,
            _gatewayType
        );

        delete isGatewayAddress[gatewayAddress];

        emit RemoveGateway(_gatewayType);
    }

    function setRouters(DataStructures.KeyToAddressValue[] calldata _routers) external onlyManager {
        for (uint256 index; index < _routers.length; index++) {
            DataStructures.KeyToAddressValue calldata item = _routers[index];

            _setRouter(item.key, item.value);
        }
    }

    function removeRouters(uint256[] calldata _routerTypes) external onlyManager {
        for (uint256 index; index < _routerTypes.length; index++) {
            uint256 routerType = _routerTypes[index];

            _removeRouter(routerType);
        }
    }

    function setRouterTransfer(uint256 _routerType, address _routerTransfer) external onlyManager {
        if (routerMap[_routerType] == address(0)) {
            revert RouterNotSetError();
        }

        AddressHelper.requireContractOrZeroAddress(_routerTransfer);

        routerTransferMap[_routerType] = _routerTransfer;

        emit SetRouterTransfer(_routerType, _routerTransfer);
    }

    function setVault(uint256 _vaultType, address _vault) external onlyManager {
        AddressHelper.requireContract(_vault);

        DataStructures.combinedMapSet(
            vaultMap,
            vaultTypeList,
            vaultTypeIndexMap,
            _vaultType,
            _vault
        );

        emit SetVault(_vaultType, _vault);
    }

    function removeVault(uint256 _vaultType) external onlyManager {
        DataStructures.combinedMapRemove(vaultMap, vaultTypeList, vaultTypeIndexMap, _vaultType);

        // - - - Vault decimals table cleanup - - -

        delete vaultDecimalsTable[_vaultType][VAULT_DECIMALS_CHAIN_ID_WILDCARD];

        uint256 chainIdListLength = vaultDecimalsChainIdList.length;

        for (uint256 index; index < chainIdListLength; index++) {
            uint256 chainId = vaultDecimalsChainIdList[index];

            delete vaultDecimalsTable[_vaultType][chainId];
        }

        // - - -

        emit RemoveVault(_vaultType);
    }

    function setVaultDecimals(
        uint256 _vaultType,
        DataStructures.KeyToValue[] calldata _decimalsData
    ) external onlyManager {
        if (vaultMap[_vaultType] == address(0)) {
            revert VaultNotSetError();
        }

        for (uint256 index; index < _decimalsData.length; index++) {
            DataStructures.KeyToValue calldata decimalsDataItem = _decimalsData[index];

            uint256 chainId = decimalsDataItem.key;

            vaultDecimalsTable[_vaultType][chainId] = DataStructures.OptionalValue(
                true,
                decimalsDataItem.value
            );

            if (chainId != VAULT_DECIMALS_CHAIN_ID_WILDCARD) {
                DataStructures.uniqueListAdd(
                    vaultDecimalsChainIdList,
                    vaultDecimalsChainIdIndexMap,
                    chainId
                );
            }
        }

        emit SetVaultDecimals(_vaultType, _decimalsData);
    }

    function unsetVaultDecimals(
        uint256 _vaultType,
        uint256[] calldata _chainIds
    ) external onlyManager {
        if (vaultMap[_vaultType] == address(0)) {
            revert VaultNotSetError();
        }

        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];
            delete vaultDecimalsTable[_vaultType][chainId];
        }

        emit UnsetVaultDecimals(_vaultType, _chainIds);
    }

    // System fee in millipercent
    function setSystemFee(uint256 _systemFee) external onlyManager {
        _setSystemFee(_systemFee);
    }

    function setFeeCollector(address _feeCollector) external onlyManager {
        _setFeeCollector(_feeCollector);
    }

    function setFeeCollectorLocal(address _feeCollector) external onlyManager {
        _setFeeCollectorLocal(_feeCollector);
    }

    function setWhitelist(address _whitelistAddress, bool _value) external onlyManager {
        if (_value) {
            DataStructures.uniqueAddressListAdd(whitelist, whitelistIndexMap, _whitelistAddress);
        } else {
            DataStructures.uniqueAddressListRemove(whitelist, whitelistIndexMap, _whitelistAddress);
        }

        emit SetWhitelist(_whitelistAddress, _value);
    }

    // Decimals = 18
    function setSwapAmountMin(uint256 _value) external onlyManager {
        if (_value > swapAmountMax) {
            revert SwapAmountMinGreaterThanMaxError();
        }

        swapAmountMin = _value;

        emit SetSwapAmountMin(_value);
    }

    // Decimals = 18
    function setSwapAmountMax(uint256 _value) external onlyManager {
        if (_value < swapAmountMin) {
            revert SwapAmountMaxLessThanMinError();
        }

        swapAmountMax = _value;

        emit SetSwapAmountMax(_value);
    }

    function localSettings(
        address _caller,
        uint256 _routerType
    ) external view returns (LocalSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            LocalSettings({
                router: router,
                routerTransfer: routerTransfer,
                systemFee: systemFee,
                feeCollectorLocal: feeCollectorLocal,
                isWhitelist: isWhitelist(_caller)
            });
    }

    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    ) external view returns (SourceSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            SourceSettings({
                gateway: gatewayMap[_gatewayType],
                router: router,
                routerTransfer: routerTransfer,
                vault: vaultMap[_vaultType],
                sourceVaultDecimals: vaultDecimals(_vaultType, block.chainid),
                targetVaultDecimals: vaultDecimals(_vaultType, _targetChainId),
                systemFee: systemFee,
                feeCollector: feeCollector,
                isWhitelist: isWhitelist(_caller),
                swapAmountMin: swapAmountMin,
                swapAmountMax: swapAmountMax
            });
    }

    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    ) external view returns (TargetSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            TargetSettings({
                router: router,
                routerTransfer: routerTransfer,
                vault: vaultMap[_vaultType],
                gasReserve: targetGasReserve
            });
    }

    function variableBalanceRepaymentSettings(
        uint256 _vaultType
    ) external view returns (VariableBalanceRepaymentSettings memory) {
        return VariableBalanceRepaymentSettings({ vault: vaultMap[_vaultType] });
    }

    function messageFeeEstimateSettings(
        uint256 _gatewayType
    ) external view returns (MessageFeeEstimateSettings memory) {
        return MessageFeeEstimateSettings({ gateway: gatewayMap[_gatewayType] });
    }

    function localAmountCalculationSettings(
        address _caller
    ) external view returns (LocalAmountCalculationSettings memory) {
        return
            LocalAmountCalculationSettings({
                systemFee: systemFee,
                isWhitelist: isWhitelist(_caller)
            });
    }

    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    ) external view returns (VaultAmountCalculationSettings memory) {
        return
            VaultAmountCalculationSettings({
                fromDecimals: vaultDecimals(_vaultType, _fromChainId),
                toDecimals: vaultDecimals(_vaultType, _toChainId),
                systemFee: systemFee,
                isWhitelist: isWhitelist(_caller)
            });
    }

    function swapAmountLimits(uint256 _vaultType) external view returns (uint256 min, uint256 max) {
        if (swapAmountMin == 0 && swapAmountMax == Constants.INFINITY) {
            min = 0;
            max = Constants.INFINITY;
        } else {
            uint256 toDecimals = vaultDecimals(_vaultType, block.chainid);

            min = (swapAmountMin == 0)
                ? 0
                : DecimalsHelper.convertDecimals(
                    Constants.DECIMALS_DEFAULT,
                    toDecimals,
                    swapAmountMin
                );

            max = (swapAmountMax == Constants.INFINITY)
                ? Constants.INFINITY
                : DecimalsHelper.convertDecimals(
                    Constants.DECIMALS_DEFAULT,
                    toDecimals,
                    swapAmountMax
                );
        }
    }

    function gatewayTypeCount() external view returns (uint256) {
        return gatewayTypeList.length;
    }

    function fullGatewayTypeList() external view returns (uint256[] memory) {
        return gatewayTypeList;
    }

    function routerTypeCount() external view returns (uint256) {
        return routerTypeList.length;
    }

    function fullRouterTypeList() external view returns (uint256[] memory) {
        return routerTypeList;
    }

    function vaultTypeCount() external view returns (uint256) {
        return vaultTypeList.length;
    }

    function fullVaultTypeList() external view returns (uint256[] memory) {
        return vaultTypeList;
    }

    function vaultDecimalsChainIdCount() external view returns (uint256) {
        return vaultDecimalsChainIdList.length;
    }

    function fullVaultDecimalsChainIdList() external view returns (uint256[] memory) {
        return vaultDecimalsChainIdList;
    }

    function whitelistCount() external view returns (uint256) {
        return whitelist.length;
    }

    function fullWhitelist() external view returns (address[] memory) {
        return whitelist;
    }

    function isWhitelist(address _account) public view returns (bool) {
        return whitelistIndexMap[_account].isSet;
    }

    function vaultDecimals(uint256 _vaultType, uint256 _chainId) public view returns (uint256) {
        DataStructures.OptionalValue storage optionalValue = vaultDecimalsTable[_vaultType][
            _chainId
        ];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        DataStructures.OptionalValue storage wildcardOptionalValue = vaultDecimalsTable[_vaultType][
            VAULT_DECIMALS_CHAIN_ID_WILDCARD
        ];

        if (wildcardOptionalValue.isSet) {
            return wildcardOptionalValue.value;
        }

        return Constants.DECIMALS_DEFAULT;
    }

    function _setGateway(uint256 _gatewayType, address _gatewayAddress) private {
        AddressHelper.requireContract(_gatewayAddress);

        if (isGatewayAddress[_gatewayAddress] && gatewayMap[_gatewayType] != _gatewayAddress) {
            revert DuplicateGatewayAddressError();
        }

        DataStructures.combinedMapSet(
            gatewayMap,
            gatewayTypeList,
            gatewayTypeIndexMap,
            _gatewayType,
            _gatewayAddress
        );

        isGatewayAddress[_gatewayAddress] = true;

        emit SetGateway(_gatewayType, _gatewayAddress);
    }

    function _setRouter(uint256 _routerType, address _routerAddress) private {
        AddressHelper.requireContract(_routerAddress);

        DataStructures.combinedMapSet(
            routerMap,
            routerTypeList,
            routerTypeIndexMap,
            _routerType,
            _routerAddress
        );

        emit SetRouter(_routerType, _routerAddress);
    }

    function _removeRouter(uint256 _routerType) private {
        DataStructures.combinedMapRemove(
            routerMap,
            routerTypeList,
            routerTypeIndexMap,
            _routerType
        );

        delete routerTransferMap[_routerType];

        emit RemoveRouter(_routerType);
    }

    function _setSystemFee(uint256 _systemFee) private {
        if (_systemFee > SYSTEM_FEE_LIMIT) {
            revert SystemFeeValueError();
        }

        systemFee = _systemFee;

        emit SetSystemFee(_systemFee);
    }

    function _setFeeCollector(address _feeCollector) private {
        feeCollector = _feeCollector;

        emit SetFeeCollector(_feeCollector);
    }

    function _setFeeCollectorLocal(address _feeCollector) private {
        feeCollectorLocal = _feeCollector;

        emit SetFeeCollectorLocal(_feeCollector);
    }

    function _routerAddresses(
        uint256 _routerType
    ) private view returns (address router, address routerTransfer) {
        router = routerMap[_routerType];
        routerTransfer = routerTransferMap[_routerType];

        if (routerTransfer == address(0)) {
            routerTransfer = router;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { ITokenBalance } from './interfaces/ITokenBalance.sol';
import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

abstract contract BalanceManagement is ManagerRole {
    error ReservedTokenError();

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(msg.sender, _tokenAmount);
        } else {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    function isReservedToken(address /*_tokenAddress*/) public view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

uint256 constant DECIMALS_DEFAULT = 18;
uint256 constant INFINITY = type(uint256).max;
uint256 constant MILLIPERCENT_FACTOR = 100_000;
address constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { ManagerRole } from '../roles/ManagerRole.sol';

abstract contract TargetGasReserve is ManagerRole {
    uint256 public targetGasReserve;

    event SetTargetGasReserve(uint256 gasReserve);

    function setTargetGasReserve(uint256 _gasReserve) external onlyManager {
        _setTargetGasReserve(_gasReserve);
    }

    function _setTargetGasReserve(uint256 _gasReserve) internal virtual {
        targetGasReserve = _gasReserve;

        emit SetTargetGasReserve(_gasReserve);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

struct OptionalValue {
    bool isSet;
    uint256 value;
}

struct KeyToValue {
    uint256 key;
    uint256 value;
}

struct KeyToAddressValue {
    uint256 key;
    address value;
}

struct AccountToFlag {
    address account;
    bool flag;
}

function combinedMapSet(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key,
    address _value
) returns (bool isNewKey) {
    isNewKey = !_keyIndexMap[_key].isSet;

    if (isNewKey) {
        uniqueListAdd(_keyList, _keyIndexMap, _key);
    }

    _map[_key] = _value;
}

function combinedMapRemove(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key
) returns (bool isChanged) {
    isChanged = _keyIndexMap[_key].isSet;

    if (isChanged) {
        delete _map[_key];
        uniqueListRemove(_keyList, _keyIndexMap, _key);
    }
}

function uniqueListAdd(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

function uniqueListRemove(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            uint256 lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

function uniqueAddressListAdd(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

function uniqueAddressListRemove(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            address lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

function uniqueAddressListUpdate(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    bool _flag
) returns (bool isChanged) {
    return
        _flag
            ? uniqueAddressListAdd(_list, _indexMap, _value)
            : uniqueAddressListRemove(_list, _indexMap, _value);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

error TokenBurnError();
error TokenMintError();
error ZeroAddressError();

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

error NonContractAddressError(address account);

function isContract(address _account) view returns (bool) {
    return _account.code.length > 0;
}

function requireContract(address _account) view {
    if (!isContract(_account)) {
        revert NonContractAddressError(_account);
    }
}

function requireContractOrZeroAddress(address _account) view {
    if (_account != address(0)) {
        requireContract(_account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

function convertDecimals(
    uint256 _fromDecimals,
    uint256 _toDecimals,
    uint256 _fromAmount
) pure returns (uint256) {
    if (_toDecimals == _fromDecimals) {
        return _fromAmount;
    } else if (_toDecimals > _fromDecimals) {
        return _fromAmount * 10 ** (_toDecimals - _fromDecimals);
    } else {
        return _fromAmount / 10 ** (_fromDecimals - _toDecimals);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

error SafeApproveError();
error SafeTransferError();
error SafeTransferFromError();
error SafeTransferNativeError();

function safeApprove(address _token, address _to, uint256 _value) {
    // 0x095ea7b3 is the selector for "approve(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x095ea7b3, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeApproveError();
    }
}

function safeTransfer(address _token, address _to, uint256 _value) {
    // 0xa9059cbb is the selector for "transfer(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0xa9059cbb, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferError();
    }
}

function safeTransferFrom(address _token, address _from, address _to, uint256 _value) {
    // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferFromError();
    }
}

function safeTransferNative(address _to, uint256 _value) {
    (bool success, ) = _to.call{ value: _value }(new bytes(0));

    if (!success) {
        revert SafeTransferNativeError();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { ISettings } from './ISettings.sol';

interface IRegistry is ISettings {
    function isGatewayAddress(address _account) external view returns (bool);

    function localSettings(
        address _caller,
        uint256 _routerType
    ) external view returns (LocalSettings memory);

    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    ) external view returns (SourceSettings memory);

    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    ) external view returns (TargetSettings memory);

    function variableBalanceRepaymentSettings(
        uint256 _vaultType
    ) external view returns (VariableBalanceRepaymentSettings memory);

    function messageFeeEstimateSettings(
        uint256 _gatewayType
    ) external view returns (MessageFeeEstimateSettings memory);

    function localAmountCalculationSettings(
        address _caller
    ) external view returns (LocalAmountCalculationSettings memory);

    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    ) external view returns (VaultAmountCalculationSettings memory);

    function swapAmountLimits(
        uint256 _vaultType
    ) external view returns (uint256 swapAmountMin, uint256 swapAmountMax);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface ISettings {
    struct LocalSettings {
        address router;
        address routerTransfer;
        uint256 systemFee;
        address feeCollectorLocal;
        bool isWhitelist;
    }

    struct SourceSettings {
        address gateway;
        address router;
        address routerTransfer;
        address vault;
        uint256 sourceVaultDecimals;
        uint256 targetVaultDecimals;
        uint256 systemFee;
        address feeCollector;
        bool isWhitelist;
        uint256 swapAmountMin;
        uint256 swapAmountMax;
    }

    struct TargetSettings {
        address router;
        address routerTransfer;
        address vault;
        uint256 gasReserve;
    }

    struct VariableBalanceRepaymentSettings {
        address vault;
    }

    struct MessageFeeEstimateSettings {
        address gateway;
    }

    struct LocalAmountCalculationSettings {
        uint256 systemFee;
        bool isWhitelist;
    }

    struct VaultAmountCalculationSettings {
        uint256 fromDecimals;
        uint256 toDecimals;
        uint256 systemFee;
        bool isWhitelist;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface ITokenBalance {
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface IVault {
    function asset() external view returns (address);

    function checkVariableTokenState() external view returns (address);

    function requestAsset(
        uint256 _amount,
        address _to,
        bool _forVariableBalance
    ) external returns (address assetAddress);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { RoleBearers } from './RoleBearers.sol';

abstract contract ManagerRole is Ownable, RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Manager');

    event SetManager(address indexed account, bool indexed value);
    event RenounceManagerRole(address indexed account);

    error OnlyManagerError();

    modifier onlyManager() {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    function setManager(address _account, bool _value) public onlyOwner {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetManager(_account, _value);
    }

    function renounceManagerRole() public onlyManager {
        _setRoleBearer(ROLE_KEY, msg.sender, false);

        emit RenounceManagerRole(msg.sender);
    }

    function isManager(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function managerCount() public view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    function fullManagerList() public view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    function _initRoles(
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) internal {
        address ownerAddress = _owner == address(0) ? msg.sender : _owner;

        for (uint256 index; index < _managers.length; index++) {
            setManager(_managers[index], true);
        }

        if (_addOwnerToManagers && !isManager(ownerAddress)) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import '../DataStructures.sol' as DataStructures;

abstract contract RoleBearers {
    mapping(bytes32 => address[]) private roleBearerTable;
    mapping(bytes32 => mapping(address => DataStructures.OptionalValue))
        private roleBearerIndexTable;

    function _setRoleBearer(bytes32 _roleKey, address _account, bool _value) internal {
        DataStructures.uniqueAddressListUpdate(
            roleBearerTable[_roleKey],
            roleBearerIndexTable[_roleKey],
            _account,
            _value
        );
    }

    function _isRoleBearer(bytes32 _roleKey, address _account) internal view returns (bool) {
        return roleBearerIndexTable[_roleKey][_account].isSet;
    }

    function _roleBearerCount(bytes32 _roleKey) internal view returns (uint256) {
        return roleBearerTable[_roleKey].length;
    }

    function _fullRoleBearerList(bytes32 _roleKey) internal view returns (address[] memory) {
        return roleBearerTable[_roleKey];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

abstract contract SystemVersionId {
    uint256 public constant SYSTEM_VERSION_ID = uint256(keccak256('Test 2023-02-09 A'));
}