// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "./IConsentRegistry.sol";
import "./access/Ownable2Step.sol";

import {ArraysConsent} from "./lib/ArrayUtils.sol";

error ConsentRegistry_ConsentActive(uint32 id);
error ConsentRegistry_ConsentInactive(uint32 id);
error ConsentRegistry_ConsentsInactive(uint32[] arr);
error ConsentRegistry_ConsentNonExistent(uint32 id);
error ConsentRegistry_ConsentsNonExistent(uint32[] arr);
error ConsentRegistry_Error(string message);

contract ConsentRegistry is IConsentRegistry, Ownable2Step {

    using ArraysConsent for c.Consent[];

    mapping(uint32 => c.Consent) public consents;
    uint32 internal _consentsCount = 0;
    uint32[] internal _validConsentsArray;
    mapping(bytes32 => bool) internal hashHistory;
    //mapping(uint32 => uint32) internal validConsents;

    /**
     * @dev adds consent
     * @param name name of consent
     * @param label label of consent
     * @param consentHash hash of consent
     */
    function addConsent(string memory name, string memory label, bytes32 consentHash) external onlyOwner override {
        if (consentHash == 0) {
            revert ConsentRegistry_Error("Zero consent hash!");
        } else if (hashHistory[consentHash] == true) {
            revert ConsentRegistry_Error("Hash already exists.");
        } else {
            _consentsCount++;
            consents[_consentsCount] = c.Consent(_consentsCount, name, label, false, consentHash);
            hashHistory[consentHash] = true;

            emit ConsentAdded(_consentsCount, name, label, consentHash);
        }
    }

    /**
     * @dev deactivates the consent
     * @param id id of the consent
     */
    function deactivateConsent(uint32 id) external onlyOwner override {

        if (consents[id].consentHash == 0) {
            revert ConsentRegistry_ConsentNonExistent(id);
        } else if (!consents[id].active) {
            revert ConsentRegistry_ConsentInactive(id);
        } else {
            consents[id].active = false;

            emit ConsentDeactivated(id);
        }
    }

    /**
     * @dev activates the consent
     * @param id id of the consent
     */
    function activateConsent(uint32 id) external onlyOwner override {
         if (consents[id].consentHash == 0) {
            revert ConsentRegistry_ConsentNonExistent(id);
        } else if (consents[id].active) {
            revert ConsentRegistry_ConsentActive(id);
        } else {
            consents[id].active = true;

            emit ConsentActivated(id);
        }
    }

    /**
     * @dev calls internal function and returns all consents
     * @return string names of all consents
     */
    function getAllConsents() external view override returns (string memory) {
        return _getAllConsents();
    }
    
    /**
     * @dev calls internal function and returns all active consents
     * @return string names of all active consents
     */
    function getActiveConsents() external view override returns (string memory) {
        return _getActiveConsents();
    }

     /**
     * @dev internal function on which consents from given IDs exist
     * @param consentsIds array of consents
     * @return uint32[] array of existing consents
     */
    function _checkWhichConsentsExist(uint32[] memory consentsIds) internal returns (uint32[] memory) {
        delete _validConsentsArray;
        for (uint32 i = 0; i < consentsIds.length; i++) {
            if (consents[consentsIds[i]].consentHash != 0) {
                _validConsentsArray.push(consentsIds[i]);
            }
        }
        return _validConsentsArray;
    }

    /**
     * @dev internal function that all consents
     * @return string names of all consents
     */
    function _getAllConsents() internal view returns (string memory) {
        string memory tmp;
        uint32 count = 0;

        for (uint32 i = 1; i <= _consentsCount; i++) {
            if (count == 0) {
                tmp = consents[i].label;
            } else {
                tmp = string.concat(tmp, ', ', consents[i].label);
            }
            count++;
        }

        return tmp;
    }

    /**
     * @dev internal function that all active consents
     * @return string names of all active consents
     */
    function _getActiveConsents() internal view returns (string memory) {
        string memory filtered;
        uint32 count = 0;

        for (uint32 i = 1; i <= _consentsCount; i++) {
            if (consents[i].active) {
                if (count == 0){
                    filtered = consents[i].name;
                } else {
                    filtered = string.concat(filtered,', ',consents[i].name);

                }
                count++;

            }
        }

        return filtered;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import './IConsents.sol';
import './ConsentRegistry.sol';
import './access/Managers.sol';

import { ArraysUint32, ArraysBytes32 } from './lib/ArrayUtils.sol';

error Ownable_Error(string message);

contract Consents is IConsents, ConsentRegistry, Managers {
    using ArraysUint32 for uint32[];
    using ArraysBytes32 for bytes32[];

    enum ConsentState {
        NOT_AGREED,
        PREVIOUSLY_AGREED,
        AGREED
    }

    struct PersonConsentWithState {
        uint32 id;
        ConsentState state;
        string name;
        string label;
        bytes32 consentHash;
    }

    mapping(bytes32 => uint32[]) internal _personConsents;
    mapping(uint32 => mapping(bytes32 => ConsentState)) internal _consentPersonsMap;
    mapping(uint32 => bytes32[]) internal _consentPersonsArr;

    /**
     * @dev Updates patient's agreed consents
     * @param id hash of patient
     * @param agreedConsents array of agreed IDs
     */
    function updatePersonConsents(bytes32 id, uint32[] memory agreedConsents) external override {
        uint32[] memory nonExistentConsents = new uint32[](agreedConsents.length);
        uint32 nonExistentCount;

        for (uint32 i = 0; i < agreedConsents.length; i++) {
            if (consents[agreedConsents[i]].id == 0) {
                nonExistentConsents[nonExistentCount] = agreedConsents[i];
                nonExistentCount++;
            }
        }

        if (nonExistentCount > 0) {
            revert ConsentRegistry_ConsentsNonExistent(nonExistentConsents.take(nonExistentCount));
        }

        uint32[] memory currentConsents = _personConsents[id];
        uint32[] memory newConsents = agreedConsents.filterNotContained(currentConsents);

        uint32[] memory inactiveConsents = new uint32[](newConsents.length);
        uint32 inactiveCount;

        for (uint32 i = 0; i < newConsents.length; i++) {
            if (!consents[newConsents[i]].active) {
                inactiveConsents[inactiveCount] = newConsents[i];
                inactiveCount++;
            }
        }

        if (inactiveCount > 0) {
            revert ConsentRegistry_ConsentsInactive(inactiveConsents.take(inactiveCount));
        }

        if (newConsents.length > 0) {
            if (!_isManagerAllowedToChangeConsents(newConsents) && !_isOwner()) {
                revert Ownable_Error('Only contract owner or consents manager can add person consents');
            } else {
                emit PersonConsentsAgreed(id, newConsents);
            }
        }

        uint32[] memory withdrawnConsents = currentConsents.filterNotContained(agreedConsents);

        if (withdrawnConsents.length > 0) {
            if (!_isManagerAllowedToChangeConsents(withdrawnConsents) && !_isOwner()) {
                revert Ownable_Error('Only contract owner or consents manager can remove person consents');
            } else {
                emit PersonConsentsWithdrawn(id, withdrawnConsents);
            }
        }

        _personConsents[id] = agreedConsents;

        for (uint32 i = 0; i < newConsents.length; i++) {
            uint32 consentId = newConsents[i];

            if (_consentPersonsMap[consentId][id] == ConsentState.PREVIOUSLY_AGREED) {
                _consentPersonsMap[consentId][id] = ConsentState.AGREED;
            }

            if (_consentPersonsMap[consentId][id] == ConsentState.NOT_AGREED) {
                _consentPersonsMap[consentId][id] = ConsentState.AGREED;
                _consentPersonsArr[consentId].push(id);
            }
        }

        for (uint32 i = 0; i < withdrawnConsents.length; i++) {
            uint32 consentId = withdrawnConsents[i];

            _consentPersonsMap[consentId][id] = ConsentState.PREVIOUSLY_AGREED;
        }
    }

    /**
     * @dev Retreives all consents IDs a particular patient has given agreement to
     * @param id hash of patient
     * @return uint32[] array of agreed IDs
     */
    function personConsents(bytes32 id) external view returns (uint32[] memory) {
        return _personConsents[id];
    }

    /**
     * @dev Retreives all consents a particular patient has given agreement to
     * @param id hash of patient
     * @return PersonConsentsWithState[] agreed consents with their state
     */
    function personConsentsHashes(bytes32 id) external view returns (PersonConsentWithState[] memory) {
        PersonConsentWithState[] memory res = new PersonConsentWithState[](_personConsents[id].length);
        uint32 count = 0;
        for (uint32 i = 1; i <= _personConsents[id].length; i++) {
            c.Consent memory consent = consents[i];
            res[count] = PersonConsentWithState(
                consent.id,
                _consentPersonsMap[consent.id][id],
                consent.name,
                consent.label,
                consent.consentHash
            );
            count++;
        }
        return res;
    }

    /**
     * @dev Retrieves all patients that have given their agreement to a particular consent
     * @param id id of person
     * @return bytes32[] array of patients' hashes
     */
    function consentPersons(uint32 id) external view returns (bytes32[] memory) {
        bytes32[] memory ids = new bytes32[](_consentPersonsArr[id].length);
        uint32 count = 0;

        for (uint32 i = 0; i < ids.length; i++) {
            bytes32 hash = _consentPersonsArr[id][i];

            if (_consentPersonsMap[id][hash] == ConsentState.AGREED) {
                ids[count] = hash;
                count++;
            }
        }

        return ids.take(count);
    }

    /**
     * @dev Updates the consents that particular manager is allowed to manage
     * @param manager address of manager
     * @param consentsIds IDs of Consents particular manager is allowed to manage
     */
    //123
    function updateManager(address manager, uint32[] memory consentsIds) external override onlyOwner {
        uint32[] memory existingConsents = _checkWhichConsentsExist(consentsIds);
        if (existingConsents.length != consentsIds.length) {
            revert ConsentRegistry_ConsentsNonExistent(existingConsents);
        } else {
            _updateManager(manager, consentsIds);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ConsentStruct as c} from "./lib/ConsentStruct.sol";

interface IConsentRegistry {

    function addConsent(string memory _name, string memory _label, bytes32 _consentHash) external;

    function deactivateConsent(uint32 _id) external;

    function activateConsent(uint32 _id) external;

    function getAllConsents() external view returns (string memory);

    function getActiveConsents() external view returns (string memory);
    
    event ConsentAdded(uint32 indexed id, string name, string label, bytes32 consentHash);

    event ConsentDeactivated(uint32 indexed id);

    event ConsentActivated(uint32 indexed id);

    event ConsentUpdated(uint32 indexed id, bytes32 consentHash);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IConsents {

    function updatePersonConsents(bytes32 id, uint32[] memory agreedConsents) external;

    function personConsents(bytes32 id) external view returns (uint32[] memory);

    function consentPersons(uint32 id) external view returns (bytes32[] memory);

    function updateManager(address manager, uint32[] memory consentsIds) external;

    event PersonConsentsAgreed(bytes32 indexed id, uint32[] consents);

    event PersonConsentsWithdrawn(bytes32 indexed id, uint32[] consents);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IManagers {
    function isManager(address manager) external view returns (bool);

    function getManagerConsents(address manager) external view returns (uint32[] memory);

    function getManagers() external view returns (address[] memory);

    event ManagerWithConsentsChanged(address indexed manager, uint32[] consentsIds, address changedBy);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IManagers.sol";
import "./Ownable2Step.sol";

error Managers_Error(string msg);

/**
 * @title Managers Contract
 */
contract Managers is IManagers, Ownable2Step {

    mapping(address => uint32[]) private _managersToConsents;
    address[] private _managers;


    /**
     * @dev updates list of managers
     * @param manager of manager
     * @param consentsIds array of consentsIds
     */
    function _updateManager(address manager, uint32[] memory consentsIds) internal onlyOwner {
        if (manager == address(0)) {
            revert Managers_Error("Managers: Address is zero!");
        } else if(isDuplicate(consentsIds)){
            revert Managers_Error("Managers: Duplicated consents!");
        } else {
            if (consentsIds.length > 0 && _managersToConsents[manager].length == 0) {
                _managers.push(manager);
            }
            _managersToConsents[manager] = consentsIds;
            emit ManagerWithConsentsChanged(manager, consentsIds, _msgSender());
        }
    }

    /**
     * @dev returns a list of manager address
     * @return address array of addresses
     */
    function getManagers() external view override returns (address[] memory) {
        return _managers;
    }

    /**
     * @dev returns if an address is manager
     * @param manager address of wallet
     * @return bool if wallet is manager or not 
     */
    function isManager(address manager) public view override returns (bool) {
        return _managersToConsents[manager].length > 0;
    }

    /**
     * @dev returns list of consents an address is manager to
     * @param manager address of manager
     * @return uint32[] list of consents IDs
     */
    function getManagerConsents(address manager) external view override returns (uint32[] memory) {
        return _managersToConsents[manager];
    }

    /**
     * @dev returns if manager wallet of sender (if is manager) is allowed to change consents
     * @param consentsIds array of consent IDs
     * @return bool if true/false
     */
    function _isManagerAllowedToChangeConsents(uint32[] memory consentsIds) internal view returns (bool) {
        if (!isManager(_msgSender())) {
            return false;
        } else {
            uint32 [] memory managerConsents = _managersToConsents[_msgSender()];
            bool result = false;
            if (managerConsents.length > 0 && managerConsents.length >= consentsIds.length) {
                for (uint32 i = 0; i < consentsIds.length; i++) {
                    bool found = false;
                    for (uint32 mi = 0; mi < managerConsents.length; mi++) {
                        if (consentsIds[i] == managerConsents[mi]) {
                            found = true;
                        }
                    }
                    if (found == false) {
                        return false;
                    }
                }
                result = true;
            }
            return result;
        }
    }

    function isDuplicate(uint32 [] memory array) internal pure returns (bool) {
        uint len = array.length;
        for (uint i = 0; i < len; i++) {
            for (uint j = i + 1; j < len; j++) {
                if (array[i] == array[j]) {
                    return true;
                }
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.7.3 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

error Ownable_CallerNotOwner(address caller);
error Ownable_AddressIsZero();

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
        if (owner() != _msgSender()) {
            revert Ownable_CallerNotOwner(_msgSender());
        }
    }

    /**
    *   @dev Returins if the sender is ther owner
    */
    function _isOwner() internal view returns (bool) {
        return owner() == _msgSender();
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * "public -> external" diff from OpenZeppelin version
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        if (newOwner == address(0)) {
            revert Ownable_AddressIsZero();
        } else {
         _transferOwnership(newOwner);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ConsentStruct as c} from "./ConsentStruct.sol";

library ArraysUint32 {

    function filterNotContained(uint32[] memory a, uint32[] memory b) internal pure returns (uint32[] memory) {
        uint32[] memory filtered = new uint32[](a.length);
        uint32 count = 0;

        for (uint32 i = 0; i < a.length; i++) {
            bool isContained = false;

            for (uint32 j = 0; j < b.length; j++) {
                if (a[i] == b[j]) {
                    isContained = true;
                    break;
                }
            }

            if (!isContained) {
                filtered[count] = a[i];
                count++;
            }
        }

        return take(filtered, count);
    }

    function take(uint32[] memory arr, uint32 amount) internal pure returns (uint32[] memory) {
        uint32[] memory tmp = new uint32[](amount);

        for (uint32 i = 0; i < amount; i++) {
            tmp[i] = arr[i];
        }

        return tmp;
    }
}

library ArraysConsent {

    function take(c.Consent[] memory arr, uint32 amount) internal pure returns (c.Consent[] memory) {
        c.Consent[] memory tmp = new c.Consent[](amount);

        for (uint32 i = 0; i < amount; i++) {
            tmp[i] = arr[i];
        }

        return tmp;
    }
}

library ArraysBytes32 {

    function take(bytes32[] memory arr, uint32 amount) internal pure returns (bytes32[] memory) {
        bytes32[] memory tmp = new bytes32[](amount);

        for (uint32 i = 0; i < amount; i++) {
            tmp[i] = arr[i];
        }

        return tmp;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library ConsentStruct {

    struct Consent {
        uint32 id;
        string name;
        string label;
        bool active;
        bytes32 consentHash;
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