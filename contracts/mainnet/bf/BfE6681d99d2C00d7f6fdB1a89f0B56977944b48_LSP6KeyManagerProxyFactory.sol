// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libs
import "@openzeppelin/contracts/proxy/Clones.sol";

// interfaces
import "./ILSP6KeyManagerProxy.sol";

// modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LSP6KeyManagerProxy.sol";

contract LSP6KeyManagerProxyFactory is Ownable {
    //
    // --- Errors
    //

    error LSP6KeyManagerProxyFactoryImplementationRequired();

    //
    // --- Storage
    //

    address public implementation;

    constructor() {
        implementation = address(new LSP6KeyManagerProxy());

        if (implementation == address(0)) {
            revert LSP6KeyManagerProxyFactoryImplementationRequired();
        }
    }

    function deployProxy(bytes32 salt, address universalProfile)
        public
        onlyOwner
        returns (address)
    {
        address clone = Clones.cloneDeterministic(implementation, salt);
        ILSP6KeyManagerProxy(clone).initialize(universalProfile);

        return clone;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface ILSP6KeyManagerProxy {
    function initialize(address universalProfile) external;
}

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

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// interfaces
import "./ILSP6KeyManagerProxy.sol";

// modules
import "@lukso/universalprofile-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManagerInit.sol";

contract LSP6KeyManagerProxy is ILSP6KeyManagerProxy, LSP6KeyManagerInit {
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {
        // when the base logic contract is deployed, the initialized flag should get set so its not
        // possible to call `initialize(...)`
    }

    function initialize(address universalProfile)
        public
        override(ILSP6KeyManagerProxy, LSP6KeyManagerInit)
    {
        super.initialize(universalProfile);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.6;

// modules
import "./LSP6KeyManagerInitAbstract.sol";

/**
 * @title Proxy implementation of a contract acting as a controller of an ERC725 Account, using permissions stored in the ERC725Y storage
 * @author Fabian Vogelsteller, Jean Cavallera
 * @dev all the permissions can be set on the ERC725 Account using `setData(...)` with the keys constants below
 */
contract LSP6KeyManagerInit is LSP6KeyManagerInitAbstract {
    /**
     * @inheritdoc LSP6KeyManagerInitAbstract
     */
    function initialize(address _account) public virtual override initializer {
        LSP6KeyManagerInitAbstract.initialize(_account);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.6;

// modules
import "./LSP6KeyManagerCore.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Proxy implementation of a contract acting as a controller of an ERC725 Account, using permissions stored in the ERC725Y storage
 * @author Fabian Vogelsteller, Jean Cavallera
 * @dev all the permissions can be set on the ERC725 Account using `setData(...)` with the keys constants below
 */
abstract contract LSP6KeyManagerInitAbstract is
    Initializable,
    LSP6KeyManagerCore
{
    /**
     * @notice Initiate the account with the address of the ERC725Account contract and sets LSP6KeyManager InterfaceId
     * @param _account The address of the ER725Account to control
     */
    function initialize(address _account) public virtual onlyInitializing {
        account = ERC725(_account);
        _registerInterface(_INTERFACEID_LSP6);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.6;

// modules
import "@erc725/smart-contracts/contracts/ERC725Y.sol";
import "@erc725/smart-contracts/contracts/ERC725.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

// interfaces
import "./ILSP6KeyManager.sol";

// libraries
import "../Utils/LSP6Utils.sol";

import "../Utils/ERC725Utils.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

// constants
import "./LSP6Constants.sol";
import "../LSP0ERC725Account/LSP0Constants.sol";
import "@erc725/smart-contracts/contracts/constants.sol";

/**
 * @dev address `from` is not authorised to `permission`
 * @param permission permission required
 * @param from address not-authorised
 */
error NotAuthorised(address from, string permission);

/**
 * @dev address `from` is not authorised to interact with `disallowedAddress` via account
 * @param from address making the request
 * @param disallowedAddress address that `from` is not authorised to call
 */
error NotAllowedAddress(address from, address disallowedAddress);

/**
 * @dev address `from` is not authorised to run `disallowedFunction` via account
 * @param from address making the request
 * @param disallowedFunction bytes4 function selector that `from` is not authorised to run
 */
error NotAllowedFunction(address from, bytes4 disallowedFunction);

/**
 * @dev address `from` is not authorised to set the key `disallowedKey` on the account
 * @param from address making the request
 * @param disallowedKey a bytes32 key that `from` is not authorised to set on the ERC725Y storage
 */
error NotAllowedERC725YKey(address from, bytes32 disallowedKey);

/**
 * @title Core implementation of a contract acting as a controller of an ERC725 Account, using permissions stored in the ERC725Y storage
 * @author Fabian Vogelsteller, Jean Cavallera
 * @dev all the permissions can be set on the ERC725 Account using `setData(...)` with the keys constants below
 */
abstract contract LSP6KeyManagerCore is ILSP6KeyManager, ERC165Storage {
    using ERC725Utils for ERC725Y;
    using LSP2Utils for ERC725Y;
    using LSP6Utils for ERC725;
    using Address for address;
    using ECDSA for bytes32;
    using ERC165Checker for address;

    ERC725 public account;
    mapping(address => mapping(uint256 => uint256)) internal _nonceStore;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC1271 ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ILSP6KeyManager
     */
    function getNonce(address _from, uint256 _channel)
        public
        view
        override
        returns (uint256)
    {
        uint128 nonceId = uint128(_nonceStore[_from][_channel]);
        return (uint256(_channel) << 128) | nonceId;
    }

    /**
     * @inheritdoc IERC1271
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public
        view
        override
        returns (bytes4 magicValue)
    {
        address recoveredAddress = ECDSA.recover(_hash, _signature);
        return
            (_PERMISSION_SIGN & account.getPermissionsFor(recoveredAddress)) ==
                _PERMISSION_SIGN
                ? _INTERFACE_ID_ERC1271
                : _ERC1271FAILVALUE;
    }

    /**
     * @inheritdoc ILSP6KeyManager
     */
    function execute(bytes calldata _data)
        external
        payable
        override
        returns (bytes memory)
    {
        _verifyPermissions(msg.sender, _data);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result_) = address(account).call{
            value: msg.value,
            gas: gasleft()
        }(_data);

        if (!success) {
            // solhint-disable reason-string
            if (result_.length < 68) revert();

            // solhint-disable no-inline-assembly
            assembly {
                result_ := add(result_, 0x04)
            }
            revert(abi.decode(result_, (string)));
        }

        emit Executed(msg.value, _data);
        return result_.length > 0 ? abi.decode(result_, (bytes)) : result_;
    }

    /**
     * @inheritdoc ILSP6KeyManager
     */
    function executeRelayCall(
        address _signedFor,
        uint256 _nonce,
        bytes calldata _data,
        bytes memory _signature
    ) external payable override returns (bytes memory) {
        require(
            _signedFor == address(this),
            "executeRelayCall: Message not signed for this keyManager"
        );

        bytes memory blob = abi.encodePacked(
            address(this), // needs to be signed for this keyManager
            _nonce,
            _data
        );

        address signer = keccak256(blob).toEthSignedMessageHash().recover(
            _signature
        );

        require(
            _isValidNonce(signer, _nonce),
            "executeRelayCall: Invalid nonce"
        );

        // increase nonce after successful verification
        _nonceStore[signer][_nonce >> 128]++;

        _verifyPermissions(signer, _data);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result_) = address(account).call{
            value: 0,
            gas: gasleft()
        }(_data);

        if (!success) {
            // solhint-disable reason-string
            if (result_.length < 68) revert();

            // solhint-disable no-inline-assembly
            assembly {
                result_ := add(result_, 0x04)
            }
            revert(abi.decode(result_, (string)));
        }

        emit Executed(msg.value, _data);
        return result_.length > 0 ? abi.decode(result_, (bytes)) : result_;
    }

    /**
     * @notice verify the nonce `_idx` for `_from` (obtained via `getNonce(...)`)
     * @dev "idx" is a 256bits (unsigned) integer, where:
     *          - the 128 leftmost bits = channelId
     *      and - the 128 rightmost bits = nonce within the channel
     * @param _from caller address
     * @param _idx (channel id + nonce within the channel)
     */
    function _isValidNonce(address _from, uint256 _idx)
        internal
        view
        returns (bool)
    {
        // idx % (1 << 128) = nonce
        // (idx >> 128) = channel
        // equivalent to: return (nonce == _nonceStore[_from][channel]
        return (_idx % (1 << 128)) == (_nonceStore[_from][_idx >> 128]);
    }

    /**
     * @dev verify the permissions of the _from address that want to interact with the `account`
     * @param _from the address making the request
     * @param _data the payload that will be run on `account`
     */
    function _verifyPermissions(address _from, bytes calldata _data)
        internal
        view
    {
        bytes4 erc725Function = bytes4(_data[:4]);

        if (erc725Function == account.setData.selector) {
            _verifyCanSetData(_from, _data);
        } else if (erc725Function == account.execute.selector) {
            _verifyCanExecute(_from, _data);

            address to = address(bytes20(_data[48:68]));
            _verifyAllowedAddress(_from, to);

            if (to.isContract()) {
                _verifyAllowedStandard(_from, to);

                if (_data.length >= 168) {
                    // extract bytes4 function selector from payload
                    _verifyAllowedFunction(_from, bytes4(_data[164:168]));
                }
            }
        } else if (erc725Function == account.transferOwnership.selector) {
            bytes32 permissions = account.getPermissionsFor(_from);

            if (!_hasPermission(_PERMISSION_CHANGEOWNER, permissions))
                revert NotAuthorised(_from, "TRANSFEROWNERSHIP");
        } else {
            revert("_verifyPermissions: unknown ERC725 selector");
        }
    }

    /**
     * @dev verify if `_from` has the required permissions to set some keys
     * on the linked ERC725Account
     * @param _from the address who want to set the keys
     * @param _data the ABI encoded payload `account.setData(keys, values)`
     * containing a list of keys-value pairs
     */
    function _verifyCanSetData(address _from, bytes calldata _data)
        internal
        view
    {
        bytes32 permissions = account.getPermissionsFor(_from);

        (bytes32[] memory inputKeys, ) = abi.decode(
            _data[4:],
            (bytes32[], bytes[])
        );

        bool isSettingERC725YKeys = false;

        // loop through the keys we are trying to set
        for (uint256 ii = 0; ii < inputKeys.length; ii++) {
            bytes32 key = inputKeys[ii];

            // prettier-ignore
            // if the key is a permission key
            if (bytes8(key) == _SET_PERMISSIONS_PREFIX) {
                _verifyCanSetPermissions(key, _from, permissions);

                // "nullify permission keys, 
                // so that they do not get check against allowed ERC725Y keys
                inputKeys[ii] = bytes32(0);

            // if the key is any other bytes32 key
            } else {
                isSettingERC725YKeys = true;
            }
        }

        if (isSettingERC725YKeys) {
            if (!_hasPermission(_PERMISSION_SETDATA, permissions))
                revert NotAuthorised(_from, "SETDATA");

            _verifyAllowedERC725YKeys(_from, inputKeys);
        }
    }

    function _verifyCanSetPermissions(
        bytes32 _key,
        address _from,
        bytes32 _callerPermissions
    ) internal view {
        // prettier-ignore
        // check if some permissions are already stored under this key
        if (bytes32(ERC725Y(account).getDataSingle(_key)) == bytes32(0)) {
            // if nothing is stored under this key,
            // we are trying to ADD permissions for a NEW address
            if (!_hasPermission(_PERMISSION_ADDPERMISSIONS, _callerPermissions))
                revert NotAuthorised(_from, "ADDPERMISSIONS");
        } else {
            // if there are already a value stored under this key,
            // we are trying to CHANGE the permissions of an address
            // (that has already some EXISTING permissions set)
            if (!_hasPermission(_PERMISSION_CHANGEPERMISSIONS, _callerPermissions)) 
                revert NotAuthorised(_from, "CHANGEPERMISSIONS");
        }
    }

    function _verifyAllowedERC725YKeys(
        address _from,
        bytes32[] memory _inputKeys
    ) internal view {
        bytes memory allowedERC725YKeysEncoded = ERC725Y(account).getDataSingle(
            LSP2Utils.generateBytes20MappingWithGroupingKey(
                _ADDRESS_ALLOWEDERC725YKEYS,
                bytes20(_from)
            )
        );

        // whitelist any ERC725Y key if nothing in the list
        if (allowedERC725YKeysEncoded.length == 0) return;

        bytes32[] memory allowedERC725YKeys = abi.decode(
            allowedERC725YKeysEncoded,
            (bytes32[])
        );

        bytes memory allowedKeySlice;
        bytes memory inputKeySlice;
        uint256 sliceLength;

        bool isAllowedKey;

        // save the not allowed key for cusom revert error
        bytes32 notAllowedKey;

        // loop through each allowed ERC725Y key retrieved from storage
        for (uint256 ii = 0; ii < allowedERC725YKeys.length; ii++) {
            // save the length of the slice
            // so to know which part to compare for each key we are trying to set
            (allowedKeySlice, sliceLength) = _extractKeySlice(
                allowedERC725YKeys[ii]
            );

            // loop through each keys given as input
            for (uint256 jj = 0; jj < _inputKeys.length; jj++) {
                // skip permissions keys that have been "nulled" previously
                if (_inputKeys[jj] == bytes32(0)) continue;

                // extract the slice to compare with the allowed key
                inputKeySlice = BytesLib.slice(
                    bytes.concat(_inputKeys[jj]),
                    0,
                    sliceLength
                );

                isAllowedKey =
                    keccak256(allowedKeySlice) == keccak256(inputKeySlice);

                // if the keys match, the key is allowed so stop iteration
                if (isAllowedKey) break;

                // if the keys do not match, save this key as a not allowed key
                notAllowedKey = _inputKeys[jj];
            }

            // if after checking all the keys given as input we did not find any not allowed key
            // stop checking the other allowed ERC725Y keys
            if (isAllowedKey == true) break;
        }

        // we always revert with the last not-allowed key that we found in the keys given as inputs
        if (isAllowedKey == false)
            revert NotAllowedERC725YKey(_from, notAllowedKey);
    }

    /**
     * @dev verify if `_from` has the required permissions to make an external call
     * via the linked ERC725Account
     * @param _from the address who want to run the execute function on the ERC725Account
     * @param _data the ABI encoded payload `account.execute(...)`
     */
    function _verifyCanExecute(address _from, bytes calldata _data)
        internal
        view
    {
        bytes32 permissions = account.getPermissionsFor(_from);

        uint256 operationType = uint256(bytes32(_data[4:36]));
        uint256 value = uint256(bytes32(_data[68:100]));

        require(
            operationType != 4,
            "_verifyCanExecute: operation 4 `DELEGATECALL` not supported"
        );

        (
            bytes32 permissionRequired,
            string memory operationName
        ) = _extractPermissionFromOperation(operationType);

        if (!_hasPermission(permissionRequired, permissions))
            revert NotAuthorised(_from, operationName);

        if (
            (value > 0) &&
            !_hasPermission(_PERMISSION_TRANSFERVALUE, permissions)
        ) {
            revert NotAuthorised(_from, "TRANSFERVALUE");
        }
    }

    /**
     * @dev verify if `_from` is authorised to interact with address `_to` via the linked ERC725Account
     * @param _from the caller address
     * @param _to the address to interact with
     */
    function _verifyAllowedAddress(address _from, address _to) internal view {
        bytes memory allowedAddresses = account.getAllowedAddressesFor(_from);

        // whitelist any address if nothing in the list
        if (allowedAddresses.length == 0) return;

        address[] memory allowedAddressesList = abi.decode(
            allowedAddresses,
            (address[])
        );

        for (uint256 ii = 0; ii < allowedAddressesList.length; ii++) {
            if (_to == allowedAddressesList[ii]) return;
        }
        revert NotAllowedAddress(_from, _to);
    }

    /**
     * @dev if `_from` is restricted to interact with contracts that implement a specific interface,
     * verify that `_to` implements one of these interface.
     * @param _from the caller address
     * @param _to the address of the contract to interact with
     */
    function _verifyAllowedStandard(address _from, address _to) internal view {
        bytes memory allowedStandards = ERC725Y(account).getDataSingle(
            LSP2Utils.generateBytes20MappingWithGroupingKey(
                _ADDRESS_ALLOWEDSTANDARDS,
                bytes20(_from)
            )
        );

        // whitelist any standard interface (ERC165) if nothing in the list
        if (allowedStandards.length == 0) return;

        bytes4[] memory allowedStandardsList = abi.decode(
            allowedStandards,
            (bytes4[])
        );

        for (uint256 ii = 0; ii < allowedStandardsList.length; ii++) {
            if (_to.supportsInterface(allowedStandardsList[ii])) return;
        }
        revert("Not Allowed Standards");
    }

    /**
     * @dev verify if `_from` is authorised to use the linked ERC725Account
     * to run a specific function `_functionSelector` at a target contract
     * @param _from the caller address
     * @param _functionSelector the bytes4 function selector of the function to run
     * at the target contract
     */
    function _verifyAllowedFunction(address _from, bytes4 _functionSelector)
        internal
        view
    {
        bytes memory allowedFunctions = account.getAllowedFunctionsFor(_from);

        // whitelist any function if nothing in the list
        if (allowedFunctions.length == 0) return;

        bytes4[] memory allowedFunctionsList = abi.decode(
            allowedFunctions,
            (bytes4[])
        );

        for (uint256 ii = 0; ii < allowedFunctionsList.length; ii++) {
            if (_functionSelector == allowedFunctionsList[ii]) return;
        }
        revert NotAllowedFunction(_from, _functionSelector);
    }

    /**
     * @dev compare the permissions `_addressPermission` of an address with `_requiredPermission`
     * @param _requiredPermission the permission required
     * @param _addressPermission the permission of address that we want to check
     * @return true if address has enough permissions, false otherwise
     */
    function _hasPermission(
        bytes32 _requiredPermission,
        bytes32 _addressPermission
    ) internal pure returns (bool) {
        return
            (_requiredPermission & _addressPermission) == _requiredPermission
                ? true
                : false;
    }

    function _extractKeySlice(bytes32 _key)
        internal
        pure
        returns (bytes memory keySlice_, uint256 sliceLength_)
    {
        // check each individual bytes of the allowed key, starting from the end (right to left)
        for (uint256 index = 31; index >= 0; index--) {
            // find where the first non-empty bytes starts (skip empty bytes 0x00)
            if (_key[index] != 0x00) {
                // stop as soon as we find a non-empty byte
                sliceLength_ = index + 1;
                keySlice_ = BytesLib.slice(bytes.concat(_key), 0, sliceLength_);
                break;
            }
        }
    }

    /**
     * @dev extract the required permission + a descriptive string, based on the `_operationType`
     * being run via ERC725Account.execute(...)
     * @param _operationType 0 = CALL, 1 = CREATE, 2 = CREATE2, etc... See ERC725X docs for more infos.
     * @return bytes32 the permission associated with the `_operationType`
     * @return string the opcode associated with `_operationType`
     */
    function _extractPermissionFromOperation(uint256 _operationType)
        internal
        pure
        returns (bytes32, string memory)
    {
        require(
            _operationType < 5,
            "_extractPermissionFromOperation: invalid operation type"
        );

        if (_operationType == 0) return (_PERMISSION_CALL, "CALL");
        if (_operationType == 1) return (_PERMISSION_DEPLOY, "CREATE");
        if (_operationType == 2) return (_PERMISSION_DEPLOY, "CREATE2");
        if (_operationType == 3) return (_PERMISSION_DEPLOY, "STATICCALL");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "./ERC725YCore.sol";

/**
 * @title ERC725 Y General key/value store
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Contract module which provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
contract ERC725Y is ERC725YCore {
    /**
     * @notice Sets the owner of the contract and register ERC725Y interfaceId
     * @param _newOwner the owner of the contract
     */
    constructor(address _newOwner) {
        // This is necessary to prevent a contract that implements both ERC725X and ERC725Y to call both constructors
        if (_newOwner != owner()) {
            OwnableUnset.initOwner(_newOwner);
        }

        _registerInterface(_INTERFACEID_ERC725Y);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "./ERC725X.sol";
import "./ERC725Y.sol";

/**
 * @title ERC725 bundle
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Bundles ERC725X and ERC725Y together into one smart contract
 */
contract ERC725 is ERC725X, ERC725Y {
    /**
     * @notice Sets the owner of the contract
     * @param _newOwner the owner of the contract
     */
    // solhint-disable no-empty-blocks
    constructor(address _newOwner) ERC725X(_newOwner) ERC725Y(_newOwner) {}

    // NOTE this implementation has not by default: receive() external payable {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @dev Contract acting as a controller of an ERC725 Account, using permissions stored in the ERC725Y storage
 */
interface ILSP6KeyManager is
    IERC1271
    /* is ERC165 */
{
    event Executed(uint256 indexed _value, bytes _data);

    /**
     * @notice get latest nonce for `_from` for channel ID: `_channel`
     * @dev use channel ID = 0 for sequential nonces, any other number for out-of-order execution (= execution in parallel)
     * @param _address caller address
     * @param _channel channel id
     */
    function getNonce(address _address, uint256 _channel)
        external
        view
        returns (uint256);

    /**
     * @notice execute the following payload on the ERC725Account: `_data`
     * @dev the ERC725Account will return some data on successful call, or revert on failure
     * @param _data the payload to execute. Obtained in web3 via encodeABI()
     * @return result_ the data being returned by the ERC725 Account
     */
    function execute(bytes calldata _data)
        external
        payable
        returns (bytes memory);

    /**
     * @dev allows anybody to execute given they have a signed message from an executor
     * @param _signedFor this KeyManager
     * @param _nonce the address' nonce (in a specific `_channel`), obtained via `getNonce(...)`. Used to prevent replay attack
     * @param _data obtained via encodeABI() in web3
     * @param _signature bytes32 ethereum signature
     * @return result_ the data being returned by the ERC725 Account
     */
    function executeRelayCall(
        address _signedFor,
        uint256 _nonce,
        bytes calldata _data,
        bytes memory _signature
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// constants
import "../LSP6KeyManager/LSP6Constants.sol";

// libraries
import "../Utils/LSP2Utils.sol";
import "..//Utils/ERC725Utils.sol";

library LSP6Utils {
    using LSP2Utils for bytes12;
    using ERC725Utils for IERC725Y;

    function getPermissionsFor(IERC725Y _account, address _address)
        internal
        view
        returns (bytes32)
    {
        bytes memory permissions = _account.getDataSingle(
            LSP2Utils.generateBytes20MappingWithGroupingKey(
                _ADDRESS_PERMISSIONS,
                bytes20(_address)
            )
        );

        if (bytes32(permissions) == bytes32(0)) {
            revert(
                "LSP6Utils:getPermissionsFor: no permissions set for this address"
            );
        }

        return bytes32(permissions);
    }

    function getAllowedAddressesFor(IERC725Y _account, address _address)
        internal
        view
        returns (bytes memory)
    {
        return
            _account.getDataSingle(
                LSP2Utils.generateBytes20MappingWithGroupingKey(
                    _ADDRESS_ALLOWEDADDRESSES,
                    bytes20(_address)
                )
            );
    }

    function getAllowedFunctionsFor(IERC725Y _account, address _address)
        internal
        view
        returns (bytes memory)
    {
        return
            _account.getDataSingle(
                LSP2Utils.generateBytes20MappingWithGroupingKey(
                    _ADDRESS_ALLOWEDFUNCTIONS,
                    bytes20(_address)
                )
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

library ERC725Utils {
    // internal functions

    /**
     * @dev Gets one value from account storage
     */
    function getDataSingle(IERC725Y _account, bytes32 _key)
        internal
        view
        returns (bytes memory)
    {
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = _key;
        bytes memory fetchResult = _account.getData(keys)[0];
        return fetchResult;
    }

    /**
     * @dev Initiates Map and ArrayKey and sets the length of the Array to `1` if it's not set before,
     * If it's already set, it decodes the arrayLength, increment it and adds Map and ArrayKey
     */
    function addMapAndArrayKey(
        IERC725Y _account,
        bytes32 _arrayKey,
        bytes32 _mapKey,
        address _sender,
        bytes4 _appendix
    ) internal view returns (bytes32[] memory keys, bytes[] memory values) {
        keys = new bytes32[](3);
        values = new bytes[](3);

        bytes memory rawArrayLength = getDataSingle(_account, _arrayKey);

        keys[0] = _arrayKey;
        keys[2] = _mapKey;

        values[1] = abi.encodePacked(_sender);

        if (rawArrayLength.length != 32) {
            keys[1] = _generateArrayKeyAtIndex(_arrayKey, 0);

            values[0] = abi.encodePacked(uint256(1));
            values[2] = abi.encodePacked(bytes8(0), _appendix);
        } else if (rawArrayLength.length == 32) {
            uint256 arrayLength = abi.decode(rawArrayLength, (uint256));
            uint256 newArrayLength = arrayLength + 1;

            keys[1] = _generateArrayKeyAtIndex(_arrayKey, newArrayLength - 1);

            values[0] = abi.encodePacked(newArrayLength);
            values[2] = abi.encodePacked(
                bytes8(uint64(arrayLength)),
                _appendix
            );
        }
    }

    /**
     * @dev Decrements the arrayLength, removes the Map, swaps the arrayKey that need to be removed with
     * the last `arrayKey` in the array and removes the last arrayKey with updating all modified entries
     */
    function removeMapAndArrayKey(
        IERC725Y _account,
        bytes32 _arrayKey,
        bytes32 mapHash,
        bytes32 _mapKeyToRemove
    ) internal view returns (bytes32[] memory keys, bytes[] memory values) {
        keys = new bytes32[](5);
        values = new bytes[](5);

        uint64 index = _extractIndexFromMap(_account, _mapKeyToRemove);
        bytes32 arrayKeyToRemove = _generateArrayKeyAtIndex(_arrayKey, index);

        bytes memory rawArrayLength = getDataSingle(_account, _arrayKey);
        uint256 arrayLength = abi.decode(rawArrayLength, (uint256));
        uint256 newLength = arrayLength - 1;

        keys[0] = _arrayKey;
        values[0] = abi.encodePacked(newLength);

        keys[1] = _mapKeyToRemove;
        values[1] = "";

        if (index == (arrayLength - 1)) {
            keys[2] = arrayKeyToRemove;
            values[2] = "";
        } else {
            bytes32 lastKey = _generateArrayKeyAtIndex(_arrayKey, newLength);
            bytes memory lastKeyValue = getDataSingle(_account, lastKey);

            bytes32 mapOfLastkey = generateMapKey(mapHash, lastKeyValue);
            bytes memory mapValueOfLastkey = getDataSingle(
                _account,
                mapOfLastkey
            );

            bytes memory appendix = BytesLib.slice(mapValueOfLastkey, 8, 4);

            keys[2] = arrayKeyToRemove;
            values[2] = lastKeyValue;

            keys[3] = lastKey;
            values[3] = "";

            keys[4] = mapOfLastkey;
            values[4] = abi.encodePacked(bytes8(index), appendix);
        }
    }

    function generateMapKey(bytes32 _mapHash, bytes memory _sender)
        internal
        pure
        returns (bytes32)
    {
        bytes memory mapKey = abi.encodePacked(
            bytes8(_mapHash),
            bytes4(0),
            _sender
        );
        return _generateBytes32Key(mapKey);
    }

    // private functions

    function _generateBytes32Key(bytes memory _rawKey)
        private
        pure
        returns (bytes32 key)
    {
        /* solhint-disable */
        assembly {
            key := mload(add(_rawKey, 32))
        }
        /* solhint-enable */
    }

    function _generateArrayKeyAtIndex(bytes32 _arrayKey, uint256 _index)
        private
        pure
        returns (bytes32)
    {
        bytes memory elementInArray = abi.encodePacked(
            bytes16(_arrayKey),
            bytes16(uint128(_index))
        );
        return _generateBytes32Key(elementInArray);
    }

    function _extractIndexFromMap(IERC725Y _account, bytes32 _mapKey)
        private
        view
        returns (uint64)
    {
        bytes memory indexInBytes = getDataSingle(_account, _mapKey);
        bytes8 indexKey;
        /* solhint-disable */
        assembly {
            indexKey := mload(add(indexInBytes, 32))
        }
        /* solhint-enable */
        return uint64(indexKey);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP6 = 0x6f4df48b;

/* solhint-disable */
// PERMISSION KEYS
// prettier-ignore
bytes8 constant _SET_PERMISSIONS_PREFIX           = 0x4b80742d00000000; // AddressPermissions:<...>
bytes12 constant _ADDRESS_PERMISSIONS = 0x4b80742d0000000082ac0000; // AddressPermissions:Permissions:<address> --> bytes32
bytes12 constant _ADDRESS_ALLOWEDADDRESSES = 0x4b80742d00000000c6dd0000; // AddressPermissions:AllowedAddresses:<address> --> address[]
bytes12 constant _ADDRESS_ALLOWEDFUNCTIONS = 0x4b80742d000000008efe0000; // AddressPermissions:AllowedFunctions:<address> --> bytes4[]
bytes12 constant _ADDRESS_ALLOWEDSTANDARDS = 0x4b80742d000000003efa0000; // AddressPermissions:AllowedStandards:<address> --> bytes4[]
bytes12 constant _ADDRESS_ALLOWEDERC725YKEYS = 0x4b80742d0000000090b80000; // AddressPermissions:AllowedERC725YKeys:<address> --> bytes32[]
/* solhint-enable */

// PERMISSIONS VALUES
// prettier-ignore
bytes32 constant _PERMISSION_CHANGEOWNER       = 0x0000000000000000000000000000000000000000000000000000000000000001; // [240 x 0 bits...] 0000 0000 0000 0001
bytes32 constant _PERMISSION_CHANGEPERMISSIONS = 0x0000000000000000000000000000000000000000000000000000000000000002; // [      ...      ] .... .... .... 0010
bytes32 constant _PERMISSION_ADDPERMISSIONS = 0x0000000000000000000000000000000000000000000000000000000000000004; // [      ...      ] .... .... .... 0100
bytes32 constant _PERMISSION_SETDATA = 0x0000000000000000000000000000000000000000000000000000000000000008; // [      ...      ] .... .... .... 1000
bytes32 constant _PERMISSION_CALL = 0x0000000000000000000000000000000000000000000000000000000000000010; // [      ...      ] .... .... 0001 ....
bytes32 constant _PERMISSION_STATICCALL = 0x0000000000000000000000000000000000000000000000000000000000000020; // [      ...      ] .... .... 0010 ....
bytes32 constant _PERMISSION_DELEGATECALL = 0x0000000000000000000000000000000000000000000000000000000000000040; // [      ...      ] .... .... 0100 ....
bytes32 constant _PERMISSION_DEPLOY = 0x0000000000000000000000000000000000000000000000000000000000000080; // [      ...      ] .... .... 1000 ....
bytes32 constant _PERMISSION_TRANSFERVALUE = 0x0000000000000000000000000000000000000000000000000000000000000100; // [      ...      ] .... 0001 .... ....
bytes32 constant _PERMISSION_SIGN = 0x0000000000000000000000000000000000000000000000000000000000000200; // [      ...      ] .... 0010 .... ....

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// >> INTERFACES

bytes4 constant _INTERFACE_ID_ERC725ACCOUNT = 0x63cb749b;

bytes4 constant _INTERFACE_ID_ERC1271 = 0x1626ba7e;

// >> OTHER

// ERC1271 - Standard Signature Validation
bytes4 constant _ERC1271MAGICVALUE = 0x1626ba7e;
bytes4 constant _ERC1271FAILVALUE = 0xffffffff;

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import "./interfaces/IERC725X.sol";
import "./interfaces/IERC725Y.sol";

// >> INTERFACES

// ERC725 - Smart Contract based Account
bytes4 constant _INTERFACEID_ERC725X = 0x44c028fe;
bytes4 constant _INTERFACEID_ERC725Y = 0x5a988c0f;

// >> OPERATIONS
uint256 constant OPERATION_CALL = 0;
uint256 constant OPERATION_CREATE = 1;
uint256 constant OPERATION_CREATE2 = 2;
uint256 constant OPERATION_STATICCALL = 3;
uint256 constant OPERATION_DELEGATECALL = 4;

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// constants
import "./constants.sol";

// interfaces
import "./interfaces/IERC725Y.sol";

// modules
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "./utils/OwnableUnset.sol";

/**
 * @title Core implementation of ERC725 Y General key/value store
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Contract module which provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
abstract contract ERC725YCore is OwnableUnset, ERC165Storage, IERC725Y {
    /**
     * @dev Map the keys to their values
     */
    mapping(bytes32 => bytes) internal store;

    /* Public functions */

    /**
     * @inheritdoc IERC725Y
     */
    function getData(bytes32[] memory keys)
        public
        view
        virtual
        override
        returns (bytes[] memory values)
    {
        values = new bytes[](keys.length);

        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = _getData(keys[i]);
        }

        return values;
    }

    /**
     * @inheritdoc IERC725Y
     */
    function setData(bytes32[] memory _keys, bytes[] memory _values)
        public
        virtual
        override
        onlyOwner
    {
        require(_keys.length == _values.length, "Keys length not equal to values length");
        for (uint256 i = 0; i < _keys.length; i++) {
            _setData(_keys[i], _values[i]);
        }
    }

    /* Internal functions */

    /**
     * @notice Gets singular data at a given `key`
     * @param key The key which value to retrieve
     * @return value The data stored at the key
     */
    function _getData(bytes32 key) internal view virtual returns (bytes memory value) {
        return store[key];
    }

    /**
     * @notice Sets singular data at a given `key`
     * @param key The key which value to retrieve
     * @param value The value to set
     */
    function _setData(bytes32 key, bytes memory value) internal virtual {
        store[key] = value;
        emit DataChanged(key, value);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for ERC725Y General key/value store
 * @dev ERC725Y provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
interface IERC725Y {
    /**
     * @notice Emitted when data at a key is changed
     * @param key The key which value is set
     * @param value The value to set
     */
    event DataChanged(bytes32 indexed key, bytes value);

    /**
     * @notice Gets array of data at multiple given keys
     * @param keys The array of keys which values to retrieve
     * @return values The array of data stored at multiple keys
     */
    function getData(bytes32[] memory keys) external view returns (bytes[] memory values);

    /**
     * @param keys The array of keys which values to set
     * @param values The array of values to set
     * @dev Sets array of data at multiple given `key`
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {DataChanged} event.
     */
    function setData(bytes32[] memory keys, bytes[] memory values) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Modified version of ERC173 with no constructor, instead should call `initOwner` function
 * Contract module which provides a basic access control mechanism, where
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
abstract contract OwnableUnset is Context {
    address private _owner;

    bool private _initiatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
     * @dev initiate the owner for the contract
     * It can be called once
     */
    function initOwner(address newOwner) internal {
        require(!_initiatedOwner, "Ownable: owner can only be initiated once");
        _initiatedOwner = true;
        _setOwner(newOwner);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for ERC725X General executor
 * @dev ERC725X provides the ability to call arbitrary functions at any other smart contract and itself,
 * including using `delegatecall`, `staticcall`, as well creating contracts using `create` and `create2`
 * This is the basis for a smart contract based account system, but could also be used as a proxy account system
 */
interface IERC725X {
    /**
     * @notice Emitted when a contract is created
     * @param operation The operation used to create a contract
     * @param contractAddress The created contract address
     * @param value The value sent to the created contract address
     */
    event ContractCreated(
        uint256 indexed operation,
        address indexed contractAddress,
        uint256 indexed value
    );

    /**
     * @notice Emitted when a contract executed.
     * @param operation The operation used to execute a contract
     * @param to The address where the call is executed
     * @param value The value sent to the created contract address
     * @param data The data sent with the call
     */
    event Executed(
        uint256 indexed operation,
        address indexed to,
        uint256 indexed value,
        bytes data
    );

    /**
     * @param operationType The operation to execute: CALL = 0 CREATE = 1 CREATE2 = 2 STATICCALL = 3 DELEGATECALL = 4
     * @param to The smart contract or address to interact with, `to` will be unused if a contract is created (operation 1 and 2)
     * @param value The value to transfer
     * @param data The call data, or the contract data to deploy
     * @dev Executes any other smart contract.
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {Executed} event, when a call is executed under `operationType` 0, 3 and 4
     * Emits a {ContractCreated} event, when a contract is created under `operationType` 1 and 2
     */
    function execute(
        uint256 operationType,
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "./ERC725XCore.sol";

/**
 * @title ERC725 X executor
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Implementation of a contract module which provides the ability to call arbitrary functions at any other smart contract and itself,
 * including using `delegatecall`, `staticcall` as well creating contracts using `create` and `create2`
 * This is the basis for a smart contract based account system, but could also be used as a proxy account system
 */
contract ERC725X is ERC725XCore {
    /**
     * @notice Sets the owner of the contract and register ERC725X interfaceId
     * @param _newOwner the owner of the contract
     */
    constructor(address _newOwner) {
        // This is necessary to prevent a contract that implements both ERC725X and ERC725Y to call both constructors
        if (_newOwner != owner()) {
            OwnableUnset.initOwner(_newOwner);
        }
        _registerInterface(_INTERFACEID_ERC725X);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// constants
import "./constants.sol";

// interfaces
import "./interfaces/IERC725X.sol";

// libraries
import "@openzeppelin/contracts/utils/Create2.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

// modules
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "./utils/OwnableUnset.sol";

/**
 * @title Core implementation of ERC725 X executor
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Implementation of a contract module which provides the ability to call arbitrary functions at any other smart contract and itself,
 * including using `delegatecall`, `staticcall` as well creating contracts using `create` and `create2`
 * This is the basis for a smart contract based account system, but could also be used as a proxy account system
 */
abstract contract ERC725XCore is OwnableUnset, ERC165Storage, IERC725X {
    /* Public functions */

    /**
     * @inheritdoc IERC725X
     */
    function execute(
        uint256 _operation,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public payable virtual override onlyOwner returns (bytes memory result) {
        uint256 txGas = gasleft();

        // prettier-ignore

        // CALL
        if (_operation == OPERATION_CALL) {
            result = executeCall(_to, _value, _data, txGas);

            emit Executed(_operation, _to, _value, _data);

        // STATICCALL
        } else if (_operation == OPERATION_STATICCALL) {
            result = executeStaticCall(_to, _data, txGas);

            emit Executed(_operation, _to, _value, _data);

        // DELEGATECALL
        } else if (_operation == OPERATION_DELEGATECALL) {
            address currentOwner = owner();
            result = executeDelegateCall(_to, _data, txGas);
            
            emit Executed(_operation, _to, _value, _data);

            require(owner() == currentOwner, "Delegate call is not allowed to modify the owner!");

        // CREATE
        } else if (_operation == OPERATION_CREATE) {
            address contractAddress = performCreate(_value, _data);
            result = abi.encodePacked(contractAddress);

            emit ContractCreated(_operation, contractAddress, _value);

        // CREATE2
        } else if (_operation == OPERATION_CREATE2) {
            bytes32 salt = BytesLib.toBytes32(_data, _data.length - 32);
            bytes memory data = BytesLib.slice(_data, 0, _data.length - 32);

            address contractAddress = Create2.deploy(_value, salt, data);
            result = abi.encodePacked(contractAddress);

            emit ContractCreated(_operation, contractAddress, _value);
    
        } else {
            revert("Wrong operation type");
        }
    }

    /* Internal functions */

    /**
     * @dev perform staticcall using operation 3
     * Taken from GnosisSafe: https://github.com/gnosis/safe-contracts/blob/main/contracts/base/Executor.sol
     *
     * @param to The address on which staticcall is executed
     * @param value The value to be sent with the call
     * @param data The data to be sent with the call
     * @param txGas The amount of gas for performing staticcall
     * @return The data from the call
     */
    function executeCall(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bytes memory) {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result) = to.call{gas: txGas, value: value}(data);

        if (!success) {
            // solhint-disable reason-string
            if (result.length < 68) revert();

            // solhint-disable no-inline-assembly
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        return result;
    }

    /**
     * @dev perform staticcall using operation 3
     * @param to The address on which staticcall is executed
     * @param data The data to be sent with the call
     * @param txGas The amount of gas for performing staticcall
     * @return The data from the call
     */
    function executeStaticCall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal view returns (bytes memory) {
        (bool success, bytes memory result) = to.staticcall{gas: txGas}(data);

        if (!success) {
            // solhint-disable reason-string
            if (result.length < 68) revert();

            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        return result;
    }

    /**
     * @dev perform delegatecall using operation 4
     * Taken from GnosisSafe: https://github.com/gnosis/safe-contracts/blob/main/contracts/base/Executor.sol
     *
     * @param to The address on which delegatecall is executed
     * @param data The data to be sent with the call
     * @param txGas The amount of gas for performing delegatecall
     * @return The data from the call
     */
    function executeDelegateCall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal returns (bytes memory) {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result) = to.delegatecall{gas: txGas}(data);

        if (!success) {
            // solhint-disable reason-string
            if (result.length < 68) revert();

            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        return result;
    }

    /**
     * @dev perform contract creation using operation 1
     * Taken from GnosisSafe: https://github.com/gnosis/safe-contracts/blob/main/contracts/libraries/CreateCall.sol
     *
     * @param value The value to be sent to the contract created
     * @param deploymentData The contract bytecode to deploy
     * @return newContract The address of the contract created
     */
    function performCreate(uint256 value, bytes memory deploymentData)
        internal
        returns (address newContract)
    {
        assembly {
            newContract := create(value, add(deploymentData, 0x20), mload(deploymentData))
        }

        require(newContract != address(0), "Could not deploy contract");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title ERC725 Utility library to encode key types
 * @author Jean Cavallera (CJ-42)
 * @dev based on LSP2 - ERC725Y JSON Schema
 *      https://github.com/lukso-network/LIPs/blob/master/LSPs/LSP-2-ERC725YJSONSchema.md
 */
library LSP2Utils {
    /* solhint-disable no-inline-assembly */
    function generateSingletonKey(string memory _keyName)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(bytes(_keyName));
    }

    function generateArrayKey(string memory _keyName)
        internal
        pure
        returns (bytes32)
    {
        bytes memory keyName = bytes(_keyName);

        // prettier-ignore
        require(
            keyName[keyName.length - 2] == 0x5b && // "[" in utf8 encoded
                keyName[keyName.length - 1] == 0x5d, // "]" in utf8
            "Missing empty square brackets \"[]\" at the end of the key name"
        );

        return keccak256(keyName);
    }

    function generateMappingKey(
        string memory _firstWord,
        string memory _lastWord
    ) internal pure returns (bytes32 key_) {
        bytes32 firstWordHash = keccak256(bytes(_firstWord));
        bytes32 lastWordHash = keccak256(bytes(_lastWord));

        bytes memory temporaryBytes = abi.encodePacked(
            bytes16(firstWordHash),
            bytes12(0),
            bytes4(lastWordHash)
        );

        assembly {
            key_ := mload(add(temporaryBytes, 32))
        }
    }

    function generateBytes20MappingKey(
        string memory _firstWord,
        address _address
    ) internal pure returns (bytes32 key_) {
        bytes32 firstWordHash = keccak256(bytes(_firstWord));

        bytes memory temporaryBytes = abi.encodePacked(
            bytes8(firstWordHash),
            bytes4(0),
            _address
        );

        assembly {
            key_ := mload(add(temporaryBytes, 32))
        }
    }

    function generateBytes20MappingWithGroupingKey(
        string memory _firstWord,
        string memory _secondWord,
        address _address
    ) internal pure returns (bytes32 key_) {
        bytes32 firstWordHash = keccak256(bytes(_firstWord));
        bytes32 secondWordHash = keccak256(bytes(_secondWord));

        bytes memory temporaryBytes = abi.encodePacked(
            bytes4(firstWordHash),
            bytes4(0),
            bytes2(secondWordHash),
            bytes2(0),
            _address
        );

        assembly {
            key_ := mload(add(temporaryBytes, 32))
        }
    }

    function generateBytes20MappingWithGroupingKey(
        bytes12 _keyPrefix,
        bytes20 _bytes20
    ) internal pure returns (bytes32) {
        bytes memory generatedKey = bytes.concat(_keyPrefix, _bytes20);
        bytes32 toBytes32Key;
        // solhint-disable-next-line
        assembly {
            toBytes32Key := mload(add(generatedKey, 32))
        }
        return toBytes32Key;
    }

    function generateJSONURLValue(
        string memory _hashFunction,
        string memory _json,
        string memory _url
    ) internal pure returns (bytes memory key_) {
        bytes32 hashFunctionDigest = keccak256(bytes(_hashFunction));
        bytes32 jsonDigest = keccak256(bytes(_json));

        key_ = abi.encodePacked(bytes4(hashFunctionDigest), jsonDigest, _url);
    }

    function generateASSETURLValue(
        string memory _hashFunction,
        string memory _assetBytes,
        string memory _url
    ) internal pure returns (bytes memory key_) {
        bytes32 hashFunctionDigest = keccak256(bytes(_hashFunction));
        bytes32 jsonDigest = keccak256(bytes(_assetBytes));

        key_ = abi.encodePacked(bytes4(hashFunctionDigest), jsonDigest, _url);
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