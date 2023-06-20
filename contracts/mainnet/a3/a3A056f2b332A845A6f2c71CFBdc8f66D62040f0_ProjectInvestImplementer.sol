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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../TraitRegistryV3.sol";

contract ProjectInvestImplementer {
    uint8 public immutable implementerType = 7;    // logic
    uint16 public immutable traitId;
    string public version = "1.0.0";
    uint32 public reinvestCutOffTime = 60 * 60 * 24 * 7; //time before project end after wich reinvestments are not allowed
    uint32 public reinvestStartTime = 60 * 60 * 24 * 30; //time before project end after wich reinvestments are allowed
    uint8 internal constant EVENT_TYPE_NEW_PROJECT = 0;
    uint8 internal constant EVENT_TYPE_UPDATE_PROJECT = 1;

    event projectEvent(uint8 eventType, Project project, address destWallet, string uid);

    struct Project {
        uint8 investmentCurrency; // 0: EUR, 1: USD, 2: RON
        address erc20PaymentTokenAddress;
        uint256 minFundingTarget;
        uint256 maxFundingTarget;
        uint32 returnRate;
        uint256 fundingStart;
        uint256 fundingEnd;
        uint256 duration;
        uint32 feeRate;
        uint32 flatFee;
        uint256 minInvestmentPerUser;
        uint256 maxInvestmentPerUser;
        uint32 id; //id will be automatically overwritten when project is added to ensure uniqueness
    }
    
    TraitRegistryV3 public TraitRegistry;
    mapping(uint32=>Project) public projects;
    mapping(uint32=>mapping(bool => uint256)) public projectInvestments;
    mapping(uint32=>address) public projectWallets;
    uint32 public projectCount;

    constructor(address _registry, uint16 _traitId) {
        require(_registry != address(0), "ProjectInvestImplementer: Invalid registry address");
        traitId = _traitId;
        TraitRegistry = TraitRegistryV3(_registry);
    }

    function addProject(Project calldata _project, address destWallet, string calldata uid) external onlyAllowed validProject(_project) returns (uint32){
        require(destWallet != address(0), "ProjectInvestImplementer: Invalid destination wallet");

        projectCount++; //project id starts from 1. 0 id is reserved for non-existing projects
        projects[projectCount] = _project;
        projects[projectCount].id = projectCount; //overwrite id to ensure uniqueness
        projectWallets[projectCount] = destWallet;
        emit projectEvent(EVENT_TYPE_NEW_PROJECT, projects[projectCount], destWallet, uid);
        return projectCount;
    }

    function updateProject(Project calldata _project, address destWallet, uint32 projId) external onlyAllowed validProject(_project) {
        require(destWallet != address(0));
        require(_project.id == projId, "Invalid project id");
        projects[projId] = _project;
        projectWallets[projId] = destWallet;
        emit projectEvent(EVENT_TYPE_UPDATE_PROJECT, _project, destWallet, "");
    }

    function getProject(uint32 _projectId) external view returns (Project memory) {
        require(_projectId <= projectCount, "ProjectInvestImplementer: Project does not exist");
        return projects[_projectId];
    }

    function getProjectWallet(uint32 _projectId) external view returns (address) {
        require(_projectId <= projectCount, "ProjectInvestImplementer: Project does not exist");
        return projectWallets[_projectId];
    }

    function getProjectTotalInvestment(uint32 _projectId) external view returns (uint256) {
        return projectInvestments[_projectId][true] + projectInvestments[_projectId][false];
    }

    function getProjectInvestment(uint32 _projectId, bool isCrypto) external view returns (uint256) {
        return projectInvestments[_projectId][isCrypto];
    }

    function incrementProjectInvestment(uint32 _projectId, bool isCrypto, uint256 _value) external onlyAllowed {
        projectInvestments[_projectId][isCrypto] += _value;
    }

    function decrementProjectInvestment(uint32 _projectId, bool isCrypto, uint256 _value) external onlyAllowed {
        require(projectInvestments[_projectId][isCrypto] >= _value, "ProjectInvestImplementer: Not enough investment");
        projectInvestments[_projectId][isCrypto] -= _value;
    }

    function updateReinvestInterval(uint32 reinvestStart, uint32 reinvestCutoff) external onlyAllowed {
        reinvestStartTime = reinvestStart;
        reinvestCutOffTime = reinvestCutoff;
    }



    modifier onlyAllowed() {
        require(
            TraitRegistry.addressCanModifyTrait(msg.sender, traitId),
            "Implementer: Not Authorised" 
        );
        _;
    }

    modifier validProject(Project calldata _project) {
        require(_project.fundingEnd > _project.fundingStart, "ProjectInvestImplementer: Invalid funding end");
        require(_project.minFundingTarget > 0, "ProjectInvestImplementer: Invalid min funding target");
        require(_project.maxFundingTarget > _project.minFundingTarget, "ProjectInvestImplementer: Invalid max funding target");
        require(_project.minInvestmentPerUser > 0, "ProjectInvestImplementer: Invalid min investment per user");
        require(_project.maxInvestmentPerUser > _project.minInvestmentPerUser, "ProjectInvestImplementer: Invalid max investment per user");
        require(_project.duration > 0, "ProjectInvestImplementer: Invalid duration");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract TraitRegistryV3 is Ownable {

    struct traitStruct {
        uint16  id;
        uint8   traitType;       
        // internal 0 for normal, 1 for inverted, 2 for inverted range,
        // external 3 uint8 values, 4 uint256 values, 5 bytes32, 6 string 
        // external 7 uint8 custom logic
        uint16  start;
        uint16  end;
        address implementer;     // address of the smart contract that will implement extra functionality
        bool    enabled;         // frontend decides if it wants to hide or not
        string  name;
    }

    uint16 public traitCount;
    mapping(uint16 => traitStruct) public traits;

    // token data
    mapping(uint16 => mapping(uint16 => uint8) ) public tokenData;

    using EnumerableSet for EnumerableSet.AddressSet;
    // onlyOwner can change contractControllers and transfer it's ownership
    // any contractController can setData
    EnumerableSet.AddressSet contractController;

    // trait controller access designates sub contracts that can affect 1 or more traits
    mapping(uint16 => address ) public traitControllerById;
    mapping(address => uint16 ) public traitControllerByAddress;
    uint16 public traitControllerCount = 0;

    mapping(address => mapping(uint8 => uint8) ) public traitControllerAccess;


    /*
    *   Events
    */
    event contractControllerEvent(address _address, bool mode);
    event traitControllerEvent(address _address);
    
    // traits
    event newTraitEvent(string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end );
    event updateTraitEvent(uint16 indexed _id, string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end);
    event updateTraitDataEvent(uint16 indexed _id);
    // tokens
    event tokenTraitChangeEvent(uint16 indexed _traitId, uint16 indexed _tokenId, bool mode);

    function getTraits() public view returns (traitStruct[] memory)
    {
        traitStruct[] memory retval = new traitStruct[](traitCount);
        for(uint16 i = 0; i < traitCount; i++) {
            retval[i] = traits[i];
        }
        return retval;
    }

    function addTrait(
        traitStruct[] calldata _newTraits
    ) public onlyAllowed {

        for (uint8 i = 0; i < _newTraits.length; i++) {

            uint16 newTraitId = traitCount++;
            traitStruct storage newT = traits[newTraitId];
            newT.id =           _newTraits[i].id;
            newT.name =         _newTraits[i].name;
            newT.traitType =    _newTraits[i].traitType;
            newT.start =        _newTraits[i].start;
            newT.end =          _newTraits[i].end;
            newT.implementer =  _newTraits[i].implementer;
            newT.enabled =      _newTraits[i].enabled;

            emit newTraitEvent(newT.name, newT.implementer, newT.traitType, newT.start, newT.end );
            setTraitControllerAccess(address(newT.implementer), newTraitId, true);
            setTraitControllerAccess(owner(), newTraitId, true);
        }
    }

    function updateTrait(
        uint16 _traitId,
        string memory _name,
        address _implementer,
        uint8   _traitType,
        uint16  _start,
        uint16  _end,
        bool    _enabled
    ) public onlyAllowed {
        traits[_traitId].name = _name;
        traits[_traitId].implementer = _implementer;
        traits[_traitId].traitType = _traitType;
        traits[_traitId].start = _start;
        traits[_traitId].end = _end;
        traits[_traitId].enabled = _enabled;
        
        emit updateTraitEvent(_traitId, _name, _implementer, _traitType, _start, _end);
    }

    function setTrait(uint16 traitID, uint16 tokenId, bool _value) external onlyTraitController(traitID) {
        _setTrait(traitID, tokenId, _value);
    }

    function setTraitOnMultiple(uint16 traitID, uint16[] memory tokenIds, bool[] memory _value) public onlyTraitController(traitID) {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            _setTrait(traitID, tokenIds[i], _value[i]);
        }
    }

    function _setTrait(uint16 traitID, uint16 tokenId, bool _value) internal {
        bool emitvalue = _value;
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        if(traits[traitID].traitType == 1 || traits[traitID].traitType == 2) {
            _value = !_value; 
        }
        if(_value) {
            tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] | 2**bitPos);
        } else {
            tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] & ~(2**bitPos));
        }
        emit tokenTraitChangeEvent(traitID, tokenId, emitvalue);
    }

    // set trait data
    function setData(uint16 traitId, uint16[] calldata _ids, uint8[] calldata _data) public onlyTraitController(traitId) {
        for (uint16 i = 0; i < _data.length; i++) {
            tokenData[traitId][_ids[i]] = _data[i];
        }
        emit updateTraitDataEvent(traitId);
    }

    /*
    *   View Methods
    */

    /*
    * _perPage = 1250 in order to load 10000 tokens ( 10000 / 8; starting from 0 )
    */
    function getData(uint16 traitId, uint8 _page, uint16 _perPage) public view returns (uint8[] memory) {
        uint16 i = _perPage * _page;
        uint16 max = i + (_perPage);
        uint16 j = 0;
        uint8[] memory retValues = new uint8[](max);
        while(i < max) {
            retValues[j] = tokenData[traitId][i];
            j++;
            i++;
        }
        return retValues;
    }

    function getTokenData(uint16 tokenId) public view returns (uint8[] memory) {
        uint8[] memory retValues = new uint8[](getByteCountToStoreTraitData());
        // calculate positions for our token
        for(uint16 i = 0; i < traitCount; i++) {
            if(hasTrait(i, tokenId)) {
                uint8 byteNum = uint8(i / 8);
                retValues[byteNum] = uint8(retValues[byteNum] | 2 ** uint8(i - byteNum * 8));
            }
        }
        return retValues;
    }

    function getTraitControllerAccessData(address _addr) public view returns (uint8[] memory) {
        uint16 _returnCount = getByteCountToStoreTraitData();
        uint8[] memory retValues = new uint8[](_returnCount);
        for(uint8 i = 0; i < _returnCount; i++) {
            retValues[i] = traitControllerAccess[_addr][i];
        }
        return retValues;
    }

    function getByteCountToStoreTraitData() internal view returns (uint16) {
        uint16 _returnCount = traitCount/8;
        if(_returnCount * 8 < traitCount) {
            _returnCount++;
        }
        return _returnCount;
    }

    function getByteAndBit(uint16 _offset) public pure returns (uint16 _byte, uint8 _bit)
    {
        // find byte storig our bit
        _byte = uint16(_offset / 8);
        _bit = uint8(_offset - _byte * 8);
    }

    function getImplementer(uint16 traitID) public view returns (address implementer)
    {
        return traits[traitID].implementer;
    }

    function hasTrait(uint16 traitID, uint16 tokenId) public view returns (bool result)
    {
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        bool _result = tokenData[traitID][byteNum] & (0x01 * 2**bitPos) != 0;
        bool _returnVal = (traits[traitID].traitType == 1) ? !_result: _result;
        if(traits[traitID].traitType == 2) {
            // range trait
            if(traits[traitID].start <= tokenId && tokenId <= traits[traitID].end) {
                _returnVal = !_result;
            }
        }
        return _returnVal;
    }

    /*
    *   Admin Stuff
    */

    function setContractController(address _controller, bool _mode) public onlyOwner {
        if(_mode) {
            contractController.add(_controller);
        } else {
            contractController.remove(_controller);
        }
        emit contractControllerEvent(_controller, _mode);
    }

    function getContractControllerLength() public view returns (uint256) {
        return contractController.length();
    }

    function getContractControllerAt(uint256 _index) public view returns (address) {
        return contractController.at(_index);
    }

    function getContractControllerContains(address _addr) public view returns (bool) {
        return contractController.contains(_addr);
    }

    /*
    *   Trait Controllers
    */

    function indexTraitController(address _addr) internal {
        if(traitControllerByAddress[_addr] == 0) {
            uint16 controllerId = ++traitControllerCount;
            traitControllerByAddress[_addr] = controllerId;
            traitControllerById[controllerId] = _addr;
        }
    }

    function setTraitControllerAccessData(address _addr, uint8[] calldata _data) public onlyAllowed {
        indexTraitController(_addr);
        for (uint8 i = 0; i < _data.length; i++) {
            traitControllerAccess[_addr][i] = _data[i];
        }
        emit traitControllerEvent(_addr);
    }

    function setTraitControllerAccess(address _addr, uint16 traitID, bool _value) public onlyAllowed {
        indexTraitController(_addr);
        if(_addr != address(0)) {
            (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
            if(_value) {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] | 2**bitPos);
            } else {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] & ~(2**bitPos));
            }
        }
        emit traitControllerEvent(_addr);
    }
 
    function addressCanModifyTrait(address _addr, uint16 traitID) public view returns (bool result) {
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
        return traitControllerAccess[_addr][uint8(byteNum)] & (0x01 * 2**bitPos) != 0;
    }

    function addressCanModifyTraits(address _addr, uint16[] memory traitIDs) public view returns (bool result) {
        for(uint16 i = 0; i < traitIDs.length; i++) {
            if(!addressCanModifyTrait(_addr, traitIDs[i])) {
                return false;
            }
        }
        return true;
    }

    modifier onlyAllowed() {
        require(
            msg.sender == owner() || contractController.contains(msg.sender),
            "Not Authorised"
        );
        _;
    }
    
    modifier onlyTraitController(uint16 traitID) {
        require(
            addressCanModifyTrait(msg.sender, traitID),
            "Not Authorised"
        );
        _;
    }
}