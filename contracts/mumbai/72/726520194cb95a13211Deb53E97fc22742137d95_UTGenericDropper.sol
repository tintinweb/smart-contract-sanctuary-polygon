//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IRandomNumberProvider.sol";
import "../interfaces/IRegistryConsumer.sol";
import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../interfaces/IECRegistry.sol";
import "../interfaces/IGenericDroppableStorage.sol";

contract UTGenericDropper {
    using Strings  for uint32; 

    uint256                         public constant     version                      = 20230622;

    bytes32                         public constant     DEFAULT_ADMIN_ROLE           = 0x00;
    string                          public constant     REGISTRY_KEY_GENERIC_DROPPER = "UT_GENERIC_DROPPER";
    string                          public constant     REGISTRY_KEY_RANDOM_CONTRACT = "RANDOMV2_SSP_TRAIT_DROPPER";
    bytes32                         public constant     TRAIT_DROPPER                = keccak256("TRAIT_DROPPER");          // For the user to access requestRandomDrop() and finalizeRandomDrop()
    bytes32                         public constant     TRAIT_DROP_ADMIN             = keccak256("TRAIT_DROP_ADMIN");       // For a contract who have generic access to write to any traits (like this contract)

    uint32                          public              currentDropCount;
    IRegistryConsumer               public              GalaxisRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);

    mapping(uint32 => dropStruct)   public              drops;
    mapping(uint256 => uint32)      public              requestToDropIndex;

    struct dropStruct {
        uint256                     requestId;
        uint32                      communityId;
        uint32                      registryNum;
        uint16                      traitId;
        address                     storageImplementer;
        uint256                     randomNumber;
        uint16                      rangeStart;
        uint16                      rangeEnd;
        uint16                      traitsToDrop;
        bool                        randomReceived;
        bool                        randomProcessed;
        mapping(uint16 => bool)     selectedIdxs;
    }

    struct dropStructReturn {
        uint32                      dropIndex;
        uint256                     requestId;
        uint32                      communityId;
        uint32                      registryNum;
        uint16                      traitId;
        address                     storageImplementer;
        uint256                     randomNumber;
        uint16                      rangeStart;
        uint16                      rangeEnd;
        uint16                      traitsToDrop;
        bool                        randomReceived;
        bool                        randomProcessed;
    }

    // Events
    event genericDropRequested(uint32 index);
    event genericDropProcess(uint32 index);
    event genericDropFinalized(uint32 index);

    /**
     * @dev Admin: drop traits to the selected interval
     * - TRAIT_DROPPER
     */
    function requestRandomDrop(uint32 _communityId, uint16 _traitId, uint32 _registryNum, uint16 _rangeStart, uint16 _rangeEnd, uint16 _traitsToDrop) external {

        // Validate if this contract is the current version to be used. Else fail
        address GenericDropperAddr = GalaxisRegistry.getRegistryAddress("UT_GENERIC_DROPPER");
        require(GenericDropperAddr == address(this), "UTGenericDropper: Not current GenericDropper");

        require(_rangeStart < _rangeEnd, "UTGenericDropper: Invalid range");
        require(_rangeEnd - _rangeStart + 1 >= _traitsToDrop, "UTGenericDropper: Trait count does not fit in range");
        (address crAddress, address ECrAddress) =_getRegistries(_communityId, _registryNum);
        require(CommunityRegistry(crAddress).isUserCommunityAdmin(DEFAULT_ADMIN_ROLE, msg.sender) || CommunityRegistry(crAddress).hasRole(TRAIT_DROPPER, msg.sender), "UTGenericDropper: Unauthorised");
        require(ECrAddress != address(0), "UTGenericDropper: Invalid registry to drop into");
        require(IECRegistry(ECrAddress).traitCount() > _traitId, "UTGenericDropper: invalid trait");
        IECRegistry.traitStruct memory traitData = IECRegistry(ECrAddress).getTrait(_traitId);
        require(traitData.traitType >= 3, "UTGenericDropper: not valid for badges");
        require(traitData.storageImplementer != address(0), "UTGenericDropper: no storage found for trait");

        dropStruct storage currentDrop = drops[++currentDropCount];
        currentDrop.communityId        = _communityId;
        currentDrop.traitId            = _traitId;
        currentDrop.registryNum        = _registryNum;
        currentDrop.storageImplementer = traitData.storageImplementer;
        currentDrop.rangeStart         = _rangeStart;
        currentDrop.rangeEnd           = _rangeEnd;
        currentDrop.traitsToDrop       = _traitsToDrop;
        currentDrop.requestId          = IRandomNumberProvider(GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
        requestToDropIndex[currentDrop.requestId] = currentDropCount;

        // Add role for the this dropper contract to be able to modify traits in TraitRegistry
        CommunityRegistry(crAddress).grantRole(TRAIT_DROP_ADMIN, address(this));

        emit genericDropRequested(currentDropCount);
    }

    /**
     * @dev Chainlink VRF callback
     */
    function process(uint256 _random, uint256 _requestId) external {

        require(msg.sender == GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT), "UTGenericDropper: process() Unauthorised caller");
        drops[requestToDropIndex[_requestId]].randomNumber = _random;
        drops[requestToDropIndex[_requestId]].randomReceived = true;
        emit genericDropProcess(requestToDropIndex[_requestId]);
    }

    /**
     * @dev Process the random number and distribute trait to tokens
     * - TRAIT_DROPPER
     */
    function finalizeRandomDrop(uint32 _dropIndex) public {         // onlyAllowed(_communityId, TRAIT_DROPPER) {
        dropStruct storage drop = drops[_dropIndex];
        require(drop.randomReceived, "UTGenericDropper: random not received");
        require(!drop.randomProcessed, "UTGenericDropper: drop already processed");
        (address crAddress, address ECrAddress) =_getRegistries(drop.communityId, drop.registryNum);
        require(CommunityRegistry(crAddress).isUserCommunityAdmin(DEFAULT_ADMIN_ROLE, msg.sender) || CommunityRegistry(crAddress).hasRole(TRAIT_DROPPER, msg.sender), "UTGenericDropper: Unauthorised");
        require(ECrAddress != address(0), "UTGenericDropper: Invalid registry to drop into");
        require(IECRegistry(ECrAddress).traitCount() > drop.traitId, "UTGenericDropper: invalid trait");
        IECRegistry.traitStruct memory traitData = IECRegistry(ECrAddress).getTrait(drop.traitId);
        require(traitData.traitType >= 3, "UTGenericDropper: not valid for badges");
        require(traitData.storageImplementer != address(0), "UTGenericDropper: no storage found for trait");

        uint16 rangeStart = drop.rangeStart;
        uint16 rangeEnd = drop.rangeEnd;
        uint16 range = rangeEnd - rangeStart + 1;
        uint16 traitsToDrop = drop.traitsToDrop;

        // Optimization: different routes based on estimation how saturated the drop interval would be
        if (traitsToDrop <= range / 2) {
            _drop(rangeStart, rangeEnd, traitData.storageImplementer, traitsToDrop, drop.randomNumber);
        } else {
            traitsToDrop = range - traitsToDrop;
            _inverseDrop(_dropIndex, rangeStart, rangeEnd, traitData.storageImplementer, traitsToDrop, drop.randomNumber);
        }

        drop.randomProcessed = true;
        emit genericDropFinalized(_dropIndex);
    }

    /**
     * @dev Return all open drops for the community
     */
    function getAtiveDrops(uint32 _communityId) public view returns (dropStructReturn[] memory)
    {
        uint16 retCount;

        // Count return length
        for(uint16 i = 1; i <= currentDropCount; i++) {       
            if (drops[i].communityId == _communityId && !drops[i].randomProcessed) {
                retCount++;
            }
        }

        dropStructReturn[] memory retval = new dropStructReturn[](retCount);
        uint16 pos;

        for(uint16 i = 1; i <= currentDropCount; i++) {       
            if (drops[i].communityId == _communityId && !drops[i].randomProcessed) {
                retval[pos].dropIndex = i;
                retval[pos].requestId = drops[i].requestId;
                retval[pos].communityId = drops[i].communityId;
                retval[pos].registryNum = drops[i].registryNum;
                retval[pos].traitId = drops[i].traitId;
                retval[pos].storageImplementer = drops[i].storageImplementer;
                retval[pos].randomNumber = drops[i].randomNumber;
                retval[pos].rangeStart = drops[i].rangeStart;
                retval[pos].rangeEnd = drops[i].rangeEnd;
                retval[pos].traitsToDrop = drops[i].traitsToDrop;
                retval[pos].randomReceived = drops[i].randomReceived;
                retval[pos].randomProcessed = drops[i].randomProcessed;
                pos++;
            }
        }
        return retval;
    }

    /**
     * @dev Drop traits randomly (optimal for trait amounts less then half of the range)
     */
    function _drop(uint16 _rangeStart, uint16 _rangeEnd, address storageImplementer, uint16 _traitsToDrop, uint256 _randomNumber) internal {

        uint16  offset;
        uint16  range = _rangeEnd - _rangeStart + 1;
        uint256 initRandom = _randomNumber;
        uint256 random = initRandom;
        uint16 dropCount;
        while (dropCount < _traitsToDrop) {
            if (random > range) {
                offset = 0;
                // while (offset < range && !IECRegistry(_ECrAddress).setTrait(_traitId, uint16((random + offset) % range + _rangeStart), true)) {
                // function addTraitToToken(uint16 _tokenId) external returns(bool wasSet);
                while (offset < range && !IGenericDroppableStorage(storageImplementer).addTraitToToken(uint16((random + offset) % range + _rangeStart))) {
                    offset++;
                }
                require(offset < range, "UTGenericDropper: Range full");
                dropCount++;
                random = random >> 1;
            } else {
                initRandom = uint256(keccak256(abi.encode(initRandom)));
                random = initRandom;
            }
        }
    }

    /**
     * @dev Drop traits randomly (optimal for trait amounts more then half of the range)
     */
    function _inverseDrop(uint32 _dropIndex, uint16 _rangeStart, uint16 _rangeEnd, address storageImplementer, uint16 _traitsToDrop, uint256 _randomNumber) internal {
        uint16 offset;

        dropStruct storage drop = drops[_dropIndex];

        uint16 range = _rangeEnd - _rangeStart + 1;
        uint16[] memory selectedTokens = new uint16[](range - _traitsToDrop);
        uint256 initRandom = _randomNumber;
        uint256 random = initRandom;

        uint16 dropCount;
        while (dropCount < _traitsToDrop) {
            if (random > range) {
                offset = 0;
                // while (offset < range && (drop.selectedIdxs[uint16((random + offset) % range + _rangeStart)] || IECRegistry(_ECrAddress).hasTrait(_traitId, uint16((random + offset) % range + _rangeStart)))) {
                //     offset++;
                // }
                while(true) {
                    uint16 pos = uint16((random + offset) % range + _rangeStart);
                    if (offset < range && (drop.selectedIdxs[pos] || IGenericDroppableStorage(storageImplementer).hasTrait(pos))) {
                        offset++;
                    } else {
                        break;
                    }
                }
                require(offset < range, "UTGenericDropper: Range full");
                drop.selectedIdxs[uint16((random + offset) % range + _rangeStart)] = true;

                dropCount++;
                random = random >> 1;
            } else {
                initRandom = uint256(keccak256(abi.encode(initRandom)));
                random = initRandom;
            }           
        }

        // Book inverse results into trait registry
        uint16 j;
        for (uint16 i = _rangeStart; i <= _rangeEnd; i++) {
            if (!drop.selectedIdxs[i]) {
                selectedTokens[j++] = i;
            }
        }
        dropCount = IGenericDroppableStorage(storageImplementer).addTraitOnMultiple(selectedTokens);

        require(dropCount + _traitsToDrop == range, "UTGenericDropper: Range full");
    }

    /**
     * @dev Read community registry and ECRegistry addresses
     */
    function _getRegistries(uint32 _communityId, uint32 _registryNum) internal view returns (address crAddress, address ECrAddress) {

        CommunityList COMMUNITY_LIST = CommunityList(GalaxisRegistry.getRegistryAddress("COMMUNITY_LIST"));
        (,crAddress,) = COMMUNITY_LIST.communities(_communityId);
        CommunityRegistry thisCommunityRegistry = CommunityRegistry(crAddress);

        ECrAddress = thisCommunityRegistry.getRegistryAddress(
            string(abi.encodePacked("TRAIT_REGISTRY_",
            _registryNum.toString())
        ));
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRandomNumberProvider {
    function requestRandomNumber() external returns (uint256 requestId);
    function requestRandomNumberWithCallback() external returns (uint256);
    function isRequestComplete(uint256 requestId) external view returns (bool isCompleted);
    function randomNumber(uint256 requestId) external view returns (uint256 randomNum);
    function setAuth(address user, bool grant) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRegistryConsumer {

    function getRegistryAddress(string memory key) external view returns (address) ;

    function getRegistryBool(string memory key) external view returns (bool);

    function getRegistryUINT(string memory key) external view returns (uint256) ;

    function getRegistryString(string memory key) external view returns (string memory) ;

    function isAdmin(address user) external view returns (bool) ;

    function isAppAdmin(address app, address user) external view returns (bool);

}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IGenericDroppableStorage {
    // Update one token to value TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return: bool - was the trait actually opened?
    function addTraitToToken(uint16 _tokenId) external returns(bool);

    // Update multiple token to value TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return: number of tokens actually set (not counting tokens already had the trait opened)
    function addTraitOnMultiple(uint16[] memory tokenIds) external returns(uint16 changes);

    // Was the trait activated (meaning it has non zero uint8 value)
    function hasTrait(uint16 _tokenId) external view returns(bool);

    // // Was the trait activated (meaning it has non zero uint8 value) on multiple token
    // function haveTrait(uint16[] memory _tokenId) external view returns(bool[] memory);

    // Read the generic part of the trait (the uint8 status value)
    function getUint8Value(uint16 _tokenId) external view returns(uint8);

    // Read the generic part of the trait for multiple tokens (the uint8 status value)
    function getUint8Values(uint16[] memory _tokenIds) external view returns (uint8[] memory);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IECRegistry {
    function addTrait(traitStruct[] memory) external; 
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] memory) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    // ---- Change start ----
    function setTrait(uint16 traitID, uint16 tokenID, bool) external returns (bool);
    function setTraitUnchecked(uint16 traitID, uint16 tokenId, bool _value) external;
    function setTraitOnMultiple(uint16 traitID, uint16[] memory tokenIds, bool _value) external returns(uint16 changes);
    function setTraitOnMultipleUnchecked(uint16 traitID, uint16[] memory tokenIds, bool[] memory _value) external;
    function getTrait(uint16 id) external view returns (traitStruct memory);
    function getTraits() external view returns (traitStruct[] memory);
    // ---- Change end ----
    function owner() external view returns (address);
    function contractController(address) external view returns (bool);
    function getDefaultTraitControllerByType(uint8) external view returns (address);
    function setDefaultTraitControllerType(address, uint8) external;
    function setTraitControllerAccess(address, uint16, bool) external;
    function traitCount() external view returns (uint16);

    struct traitStruct {
        uint16  id;
        uint8   traitType;              // 0 normal (1bit), 1 range, 2 inverted range, >=3 with storageImplementer
        uint16  start;
        uint16  end;
        bool    enabled;
        address storageImplementer;     // address of the smart contract that will implement the storage for the trait
        string  ipfsHash;
        string  name;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract CommunityList is AccessControlEnumerable { 

    bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");


    uint256                              public numberOfEntries;

    struct community_entry {
        string      name;
        address     registry;
        uint32      id;
    }
    
    mapping(uint32 => community_entry)  public communities;   // community_id => record
    mapping(uint256 => uint32)           public index;         // entryNumber => community_id for enumeration

    event CommunityAdded(uint256 pos, string community_name, address community_registry, uint32 community_id);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN,msg.sender);
    }

    function addCommunity(uint32 community_id, string memory community_name, address community_registry) external onlyRole(CONTRACT_ADMIN) {
        uint256 pos = numberOfEntries++;
        index[pos]  = community_id;
        communities[community_id] = community_entry(community_name, community_registry, community_id);
        emit CommunityAdded(pos, community_name, community_registry, community_id);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

interface IOwnable {
    function owner() external view returns (address);
}

contract CommunityRegistry is AccessControlEnumerable  {

    bytes32 public constant COMMUNITY_REGISTRY_ADMIN = keccak256("COMMUNITY_REGISTRY_ADMIN");


    uint32                      public  community_id;
    string                      public  community_name;
    address                     public  community_admin;

    mapping(bytes32 => address)         addresses;
    mapping(bytes32 => uint256)         uints;
    mapping(bytes32 => bool)            booleans;
    mapping(bytes32 => string)          strings;

   // mapping(address => bool)    public  admins;

    mapping(address => mapping(address => bool)) public app_admins;

    mapping (uint => string)    public  addressEntries;
    mapping (uint => string)    public  uintEntries;
    mapping (uint => string)    public  boolEntries;
    mapping (uint => string)    public  stringEntries;
    uint                        public  numberOfAddresses;
    uint                        public  numberOfUINTs;
    uint                        public  numberOfBooleans;
    uint                        public  numberOfStrings;

    uint                        public  nextAdmin;
    mapping(address => bool)    public  adminHas;
    mapping(uint256 => address) public  adminEntries;
    mapping(address => uint256) public  appAdminCounter;
    mapping(address =>mapping(uint256 =>address)) public appAdminEntries;

    address                     public  owner;

    bool                                initialised;

    bool                        public  independant;

    event IndependanceDay(bool gain_independance);

    modifier onlyAdmin() {
        require(isCommunityAdmin(COMMUNITY_REGISTRY_ADMIN),"CommunityRegistry : Unauthorised");
        _;
    }

    // function isCommunityAdmin(bytes32 role) public view returns (bool) {
    //     if (independant){        
    //         return(
    //             msg.sender == owner ||
    //             admins[msg.sender]
    //         );
    //     } else {            
    //        IAccessControlEnumerable ac = IAccessControlEnumerable(owner);   
    //        return(
    //             msg.sender == owner || 
    //             hasRole(DEFAULT_ADMIN_ROLE,msg.sender) ||
    //             ac.hasRole(role,msg.sender));
    //     }
    // }

    function isCommunityAdmin(bytes32 role) internal view returns (bool) {
        return isUserCommunityAdmin( role, msg.sender);
    }

    function isUserCommunityAdmin(bytes32 role, address user) public view returns (bool) {
        if (user == owner || hasRole(DEFAULT_ADMIN_ROLE,user) ) return true;
        if (independant){        
            return(
                hasRole(role,user)
            );
        } else {            
           IAccessControlEnumerable ac = IAccessControlEnumerable(owner);   
           return(
                ac.hasRole(role,user));
        }
    }

    function grantRole(bytes32 key, address user) public override(AccessControl,IAccessControl) onlyAdmin {
        _grantRole(key,user);
    }
 
    constructor (
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) {
        _init(_community_id,_community_admin,_community_name);
    }

    
    function init(
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) external {
        _init(_community_id,_community_admin,_community_name);
    }

    function _init(
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) internal {
        require(!initialised,"This can only be called once");
        initialised = true;
        community_id = _community_id;
        community_name  = _community_name;
        community_admin = _community_admin;
        _setupRole(DEFAULT_ADMIN_ROLE, community_admin); // default admin = launchpad
        owner = msg.sender;
    }



    event AdminUpdated(address user, bool isAdmin);
    event AppAdminChanged(address app,address user,bool state);
    //===
    event AddressChanged(string key, address value);
    event UintChanged(string key, uint256 value);
    event BooleanChanged(string key, bool value);
    event StringChanged(string key, string value);

    function setIndependant(bool gain_independance) external onlyAdmin {
        if (independant != gain_independance) {
                independant = gain_independance;
                emit IndependanceDay(gain_independance);
        }
    }


    function setAdmin(address user,bool status ) external onlyAdmin {
        if (status)
            _grantRole(COMMUNITY_REGISTRY_ADMIN,user);
        else
            _revokeRole(COMMUNITY_REGISTRY_ADMIN,user);
    }

    function hash(string memory field) internal pure returns (bytes32) {
        return keccak256(abi.encode(field));
    }

    function setRegistryAddress(string memory fn, address value) external onlyAdmin {
        bytes32 hf = hash(fn);
        addresses[hf] = value;
        addressEntries[numberOfAddresses++] = fn;
        emit AddressChanged(fn,value);
    }

    function setRegistryBool(string memory fn, bool value) external onlyAdmin {
        bytes32 hf = hash(fn);
        booleans[hf] = value;
        boolEntries[numberOfBooleans++] = fn;
        emit BooleanChanged(fn,value);
    }

    function setRegistryString(string memory fn, string memory value) external onlyAdmin {
        bytes32 hf = hash(fn);
        strings[hf] = value;
        stringEntries[numberOfStrings++] = fn;
        emit StringChanged(fn,value);
    }

    function setRegistryUINT(string memory fn, uint value) external onlyAdmin {
        bytes32 hf = hash(fn);
        uints[hf] = value;
        uintEntries[numberOfUINTs++] = fn;
        emit UintChanged(fn,value);
    }

    function setAppAdmin(address app, address user, bool state) external {
        require(
            msg.sender == IOwnable(app).owner() ||
            app_admins[app][msg.sender],
            "You do not have access permission"
        );
        app_admins[app][user] = state;
        if (state)
            appAdminEntries[app][appAdminCounter[app]++] = user;
        emit AppAdminChanged(app,user,state);
    }

    function getRegistryAddress(string memory key) external view returns (address) {
        return addresses[hash(key)];
    }

    function getRegistryBool(string memory key) external view returns (bool) {
        return booleans[hash(key)];
    }

    function getRegistryUINT(string memory key) external view returns (uint256) {
        return uints[hash(key)];
    }

    function getRegistryString(string memory key) external view returns (string memory) {
        return strings[hash(key)];
    }

 

    function isAppAdmin(address app, address user) external view returns (bool) {
        return 
            user == IOwnable(app).owner() ||
            app_admins[app][user];
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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