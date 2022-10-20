// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Unsafe} from "../utils/Unsafe.sol";
import {Counters} from "../utils/Counters.sol";
import {Ownable} from "../utils/Ownable.sol";

import {IOWProxy} from "./IOWProxy.sol";
import {ProxyBase} from "./ProxyBase.sol";

contract OWProxyV1 is IOWProxy, ProxyBase, Ownable {
    using Unsafe for uint256;
    using Counters for Counters.Counter;

    constructor() {
        /******** contractController setting ********/
        isActive = true;

        _initialSetContractType();
    }

    function contractActive() public override onlyOwner {
        super.contractActive();
    }

    function contractUnActive() public override onlyOwner {
        super.contractUnActive();
    }

    ///////////////////
    // Contract Type //
    ///////////////////

    function _initialSetContractType() private {
        string[16] memory initialContractTypes = [
            "Access",
            "Providing",
            "Milestone",
            "Currency",
            "Offering",
            "Minting",
            "OfferingDistribution",
            "ExternalRoyaltyDistribution",
            "Market",
            "IGT_NFT",
            "IGT_MT",
            "IStaking_NFT",
            "IStaking_MT",
            "GovernancePower",
            "Governance",
            "GovernanceVoting"
        ];

        for (
            uint256 i = 0;
            i < initialContractTypes.length;
            i = i.increment()
        ) {
            typeIds.increment();
            uint256 typeId = typeIds.current();

            contractTypes[typeId] = initialContractTypes[i];
            bytes32 name = keccak256(bytes(initialContractTypes[i]));
            typeByName[name] = typeId;
            emitCreate("ContractType", typeId);
        }
    }

    function addContractType(string calldata _type)
        external
        whenContractActive
        onlyOwner
    {
        if (isExistContractType(_type)) {
            revert AlreadyExistType();
        }
        if (bytes(_type).length < 1) {
            revert InvalidType();
        }

        typeIds.increment();
        uint256 typeId = typeIds.current();

        contractTypes[typeId] = _type;
        bytes32 name = keccak256(bytes(_type));
        typeByName[name] = typeId;

        emitCreate("ContractType", typeId);
    }

    ///////////////////////
    // Contract Type Set //
    ///////////////////////

    function setContractType(uint256 _typeId, string calldata _type)
        external
        onlyOwner
    {
        if (!isExistContractTypeById(_typeId)) {
            revert InvalidTypeId();
        }
        if (isExistContractType(_type)) {
            revert AlreadyExistType();
        }
        if (bytes(_type).length < 1) {
            revert InvalidType();
        }

        bytes32 name = keccak256(bytes(contractTypes[_typeId]));
        delete typeByName[name];
        contractTypes[_typeId] = _type;
        bytes32 newName = keccak256((bytes(_type)));
        typeByName[newName] = _typeId;
    }

    function removeContractType(uint256 _typeId) external onlyOwner {
        if (!isExistContractTypeById(_typeId)) {
            revert InvalidTypeId();
        }

        uint256 version = getLatestVersion(_typeId);
        for (uint256 i = 1; i <= version; i = i.increment()) {
            delete contracts[_typeId][i];
        }

        bytes32 name = keccak256(bytes(contractTypes[_typeId]));
        delete typeByName[name];
        delete contractTypes[_typeId];
        delete versions[_typeId];
    }

    ///////////////////////
    // Contract Type Get //
    ///////////////////////

    function isExistContractTypeById(uint256 _typeId)
        public
        view
        returns (bool)
    {
        return
            _typeId != 0 &&
            _typeId <= typeIds.current() &&
            0 < bytes(contractTypes[_typeId]).length;
    }

    function isExistContractType(string memory _type)
        public
        view
        returns (bool)
    {
        return getContractTypeId(_type) != 0;
    }

    function getContractTypeId(string memory _type)
        public
        view
        returns (uint256)
    {
        bytes32 name = keccak256(bytes(_type));
        return typeByName[name];
    }

    function getContractTypeById(uint256 _typeId)
        external
        view
        returns (string memory)
    {
        if (!isExistContractTypeById(_typeId)) {
            revert InvalidTypeId();
        }

        return contractTypes[_typeId];
    }

    function getContractTypeIds() external view returns (uint256[] memory) {
        uint256 typeCount;

        for (uint256 i = 1; i <= typeIds.current(); i = i.increment()) {
            if (0 < bytes(contractTypes[i]).length) {
                typeCount = typeCount.increment();
            }
        }

        uint256[] memory contractTypeIds = new uint256[](typeCount);
        uint256 index;

        for (uint256 i = 1; i <= typeIds.current(); i = i.increment()) {
            if (0 < bytes(contractTypes[i]).length) {
                contractTypeIds[index] = i;
                index = index.increment();
            }
        }

        return contractTypeIds;
    }

    function getContractTypes() external view returns (string[] memory) {
        uint256 typeCount;

        for (uint256 i = 1; i <= typeIds.current(); i = i.increment()) {
            if (0 < bytes(contractTypes[i]).length) {
                typeCount = typeCount.increment();
            }
        }

        string[] memory types = new string[](typeCount);
        uint256 index;

        for (uint256 i = 1; i <= typeIds.current(); i = i.increment()) {
            if (0 < bytes(contractTypes[i]).length) {
                types[index] = contractTypes[i];
                index = index.increment();
            }
        }

        return types;
    }

    //////////////
    // Contract //
    //////////////

    function addContract(uint256 _typeId, address _OWContract)
        external
        whenContractActive
        onlyOwner
    {
        if (!isExistContractTypeById(_typeId)) {
            revert InvalidTypeId();
        }

        versions[_typeId].increment();
        uint256 version = versions[_typeId].current();

        contracts[_typeId][version] = _OWContract;

        emit ContractAdded(_typeId, version, _OWContract, block.timestamp);
    }

    //////////////////
    // Contract Set //
    //////////////////

    function setContract(
        uint256 _typeId,
        uint256 _version,
        address _OWContract
    ) external onlyOwner {
        if (!isExistContractTypeById(_typeId)) {
            revert InvalidTypeId();
        }
        if (!isValidVersion(_typeId, _version)) {
            revert InvalidVersion();
        }

        contracts[_typeId][_version] = _OWContract;
    }

    function removeLatestContract(uint256 _typeId) external onlyOwner {
        if (!isExistContractTypeById(_typeId)) {
            revert InvalidTypeId();
        }

        uint256 version = getLatestVersion(_typeId);
        if (version < 1) {
            revert InvalidVersion();
        }

        delete contracts[_typeId][version];
        versions[_typeId].decrement();
    }

    //////////////////
    // Contract Get //
    //////////////////

    function getOWContractByTypeId(uint256 _typeId, uint256 _version)
        public
        view
        returns (address)
    {
        if (!isExistContractTypeById(_typeId)) {
            revert InvalidTypeId();
        }
        if (!isValidVersion(_typeId, _version)) {
            revert InvalidVersion();
        }

        return contracts[_typeId][_version];
    }

    function isValidVersion(uint256 _typeId, uint256 _version)
        public
        view
        returns (bool)
    {
        uint256 version = getLatestVersion(_typeId);
        return 0 < _version && _version <= version;
    }

    function getLatestVersion(uint256 _typeId) public view returns (uint256) {
        return versions[_typeId].current();
    }

    function getOWContractByType(string calldata _type, uint256 _version)
        external
        view
        returns (address)
    {
        uint256 typeId = getContractTypeId(_type);

        return getOWContractByTypeId(typeId, _version);
    }

    function getContractOfType(uint256 _typeId)
        public
        view
        returns (address[] memory)
    {
        if (!isExistContractTypeById(_typeId)) {
            revert InvalidTypeId();
        }

        uint256 version = getLatestVersion(_typeId);
        address[] memory contractOfType = new address[](version);
        uint256 index;

        for (uint256 i = 1; i <= version; i = i.increment()) {
            contractOfType[index] = contracts[_typeId][i];
            index = index.increment();
        }

        return contractOfType;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Unsafe {
    function increment(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/contracts/utils/Counters.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/contracts/access/Ownable.sol";

// SPDX-License-Identifier: MIT

import {ProxyBase} from "./ProxyBase.sol";

pragma solidity ^0.8.9;

interface IOWProxy {
    ///////////////////
    // Contract Type //
    ///////////////////

    function addContractType(string calldata _type) external;

    ///////////////////////
    // Contract Type Set //
    ///////////////////////

    function setContractType(uint256 _typeId, string calldata _type) external;

    function removeContractType(uint256 _typeId) external;

    ///////////////////////
    // Contract Type Get //
    ///////////////////////

    function isExistContractTypeById(uint256 _typeId)
        external
        view
        returns (bool);

    function isExistContractType(string calldata _type)
        external
        view
        returns (bool);

    function getContractTypeId(string calldata _type)
        external
        view
        returns (uint256);

    function getContractTypeById(uint256 _typeId)
        external
        view
        returns (string memory);

    function getContractTypeIds() external view returns (uint256[] memory);

    function getContractTypes() external view returns (string[] memory);

    //////////////
    // Contract //
    //////////////

    function addContract(uint256 _typeId, address _OWContract) external;

    //////////////////
    // Contract Set //
    //////////////////

    function setContract(
        uint256 _typeId,
        uint256 _version,
        address _OWContract
    ) external;

    function removeLatestContract(uint256 _typeId) external;

    //////////////////
    // Contract Get //
    //////////////////

    function getOWContractByTypeId(uint256 _typeId, uint256 _version)
        external
        view
        returns (address);

    function isValidVersion(uint256 _typeId, uint256 _version)
        external
        view
        returns (bool);

    function getLatestVersion(uint256 _typeId) external view returns (uint256);

    function getOWContractByType(string calldata _type, uint256 _version)
        external
        view
        returns (address);

    function getContractOfType(uint256 _typeId)
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Counters} from "../utils/Counters.sol";

import {OWBase} from "../core/OWBase.sol";
import {ProxyError} from "../errors/ProxyError.sol";
import {ContractController} from "../core/controller/ContractController.sol";

contract ProxyBase is OWBase, ContractController, ProxyError {
    Counters.Counter public typeIds;

    mapping(uint256 => string) internal contractTypes;
    mapping(uint256 => Counters.Counter) internal versions;
    mapping(uint256 => mapping(uint256 => address)) internal contracts;

    mapping(bytes32 => uint256) internal typeByName;

    event ContractAdded(
        uint256 typeId,
        uint256 version,
        address OWContract,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

pragma solidity ^0.8.9;

abstract contract OWBase {
    enum AccountType {
        Provider,
        Operator,
        Associator,
        Creator,
        DAO
    }

    event Create(string target, uint256 targetId, uint256 timestamp);

    function emitCreate(string memory _target, uint256 _targetId) internal {
        emit Create(_target, _targetId, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ProxyError {
    //////////////////
    // ContractType //
    //////////////////

    error AlreadyExistType();
    error InvalidType();
    error InvalidTypeId();

    //////////////
    // Contract //
    //////////////

    error InvalidVersion();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Context} from "../../utils/Context.sol";

import {ContractControllerError} from "../../errors/ContractControllerError.sol";

abstract contract ContractController is ContractControllerError, Context {
    bool public isActive;

    event ContractActive(address account, uint256 timestamp);
    event ContractUnActive(address account, uint256 timestamp);

    /////////////////////
    // Contract Active //
    /////////////////////

    modifier whenContractActive() {
        if (!isActive) {
            revert UnActive();
        }
        _;
    }

    function contractUnActive() public virtual {
        if (!isActive) {
            revert AlreadyUnActive();
        }

        isActive = false;
        emit ContractUnActive(_msgSender(), block.timestamp);
    }

    function contractActive() public virtual {
        if (isActive) {
            revert AlreadyActive();
        }

        isActive = true;
        emit ContractActive(_msgSender(), block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/contracts/utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ContractControllerError {
    error UnActive();
    error AlreadyUnActive();
    error AlreadyActive();
}