// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IPlanet.sol";
import "./cattle_items.sol";
import "../interface/IMating.sol";
import "../interface/Iprofile_photo.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../interface/ICompound.sol";
import "../interface/IMarket.sol";
import "../interface/IMail.sol";
import "./technology_tree.sol";
import "../interface/IPlanet721.sol";
import "../interface/Ibadge.sol";
import "./cattle_skin721.sol";
import "./milk.sol";

contract CheckInfo is OwnableUpgradeable {

    using StringsUpgradeable for uint256;
    ICOW public cattle;
    IPlanet public planet;
    Cattle1155 public item;
    IStable public stable;
    IMating public mating;
    IProfilePhoto public avatar;
    //------------------------
    ICompound public compound;
    MilkFactory public milk;
    IMarket public market;
    IMail public mail;
    TechnologyTree public tec;
    IPlanet721 public planet721;
    IBadge public badge;
    CattleSkin public skin;
    uint[] itemList;
    uint[] superSkinIdList;
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function setCattle(address addr_) external onlyOwner {
        cattle = ICOW(addr_);
    }

    function setTec(address addr) external onlyOwner {
        tec = TechnologyTree(addr);
    }

    function setPlanet(address addr_) external onlyOwner {
        planet = IPlanet(addr_);
    }

    function setItem(address addr_) external onlyOwner {
        item = Cattle1155(addr_);
    }

    function setSkin(address addr) external onlyOwner {
        skin = CattleSkin(addr);
    }

    function setStable(address addr_) external onlyOwner {
        stable = IStable(addr_);
    }

    function setMating(address addr) external onlyOwner {
        mating = IMating(addr);
    }

    function setProfilePhoto(address addr) external onlyOwner {
        avatar = IProfilePhoto(addr);
    }

    function setCompound(address addr) external onlyOwner {
        compound = ICompound(addr);
    }

    function setMilk(address addr) external onlyOwner {
        milk = MilkFactory(addr);
    }

    function setMail(address addr) external onlyOwner {
        mail = IMail(addr);
    }

    function setPlanet721(address addr) external onlyOwner {
        planet721 = IPlanet721(addr);
    }

    function setBadge(address addr) external onlyOwner {
        badge = IBadge(addr);
    }

    function setItemIdList(uint[] memory list) external onlyOwner{
        itemList = list;
    }

    function setSkinList(uint[] memory list) external onlyOwner{
        superSkinIdList = list;
    }


    function checkGenderBatch(uint[] memory tokenIDs) public view returns (uint[] memory list){
        list = new uint[](tokenIDs.length);
        for (uint i = 0; i < tokenIDs.length; i++) {
            list[i] = cattle.getGender(tokenIDs[i]);
        }
        return list;
    }

    function checkCreationBatch(uint[] memory tokenIDs) public view returns (bool[] memory list){
        list = new bool[](tokenIDs.length);
        for (uint i = 0; i < tokenIDs.length; i++) {
            list[i] = cattle.isCreation(tokenIDs[i]);
        }
        return list;
    }

    function checkAdultBatch(uint[] memory tokenIDs) public view returns (bool[] memory list){
        list = new bool[](tokenIDs.length);
        for (uint i = 0; i < tokenIDs.length; i++) {
            list[i] = cattle.getAdult(tokenIDs[i]);
        }
        return list;
    }

    function checkUserinfo(address addr) external view returns (uint stableAmount,
        uint[] memory cowList,
        uint[] memory gender,
        bool[] memory isCreation,
        bool[] memory isAdult){
        (stableAmount,) = stable.userInfo(addr);
        cowList = stable.checkUserCows(addr);
        gender = checkGenderBatch(cowList);
        isCreation = checkCreationBatch(cowList);
        isAdult = checkAdultBatch(cowList);
    }

    function checkMilkInfo(address addr) public view returns (uint amount, uint totalClaimed){
        amount = milk.checkUserStakeList(addr).length;
        (, totalClaimed) = milk.userInfo(addr);
    }

    function checkUserTec(address addr) public view returns(uint[] memory tecID,uint[] memory tecLevel){
        tecID = tec.checkTecList();
        tecLevel = tec.getUserTecLevelBatch(addr,tecID);
    }

    function checkItemBurnAmount() public view returns(uint[] memory,uint[] memory){
        uint[] memory lists = new uint[](itemList.length);
        for(uint i = 0; i < itemList.length; i++){
            (,,,lists[i],,,) = item.itemInfoes(itemList[i]);
        }

        return(itemList,lists);
    }

//    function checkSkinAmount() public view returns(uint[] memory,uint[] memory){
//        uint[] memory lists = new uint[](superSkinIdList.length);
//        for(uint i = 0; i < itemList.length; i++){
//            (,,,lists[i],,,) = skin.skinInfo(itemList[i]);
//        }
//
//        return(itemList,lists);
//    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICOW {
    function getGender(uint tokenId_) external view returns (uint);

    function getEnergy(uint tokenId_) external view returns (uint);

    function getAdult(uint tokenId_) external view returns (bool);

    function getAttack(uint tokenId_) external view returns (uint);

    function getStamina(uint tokenId_) external view returns (uint);

    function getDefense(uint tokenId_) external view returns (uint);

    function getPower(uint tokenId_) external view returns (uint);

    function getLife(uint tokenId_) external view returns (uint);

    function getBronTime(uint tokenId_) external view returns (uint);

    function getGrowth(uint tokenId_) external view returns (uint);

    function getMilk(uint tokenId_) external view returns (uint);

    function getMilkRate(uint tokenId_) external view returns (uint);
    
    function getCowParents(uint tokenId_) external view returns(uint[2] memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function mintNormall(address player, uint[2] memory parents) external;

    function mint(address player) external;

    function setApprovalForAll(address operator, bool approved) external;

    function growUp(uint tokenId_) external;

    function isCreation(uint tokenId_) external view returns (bool);

    function burn(uint tokenId_) external returns (bool);

    function deadTime(uint tokenId_) external view returns (uint);

    function addDeadTime(uint tokenId, uint time_) external;

    function checkUserCowListType(address player,bool creation_) external view returns (uint[] memory);
    
    function checkUserCowList(address player) external view returns(uint[] memory);
    
    function getStar(uint tokenId_) external view returns(uint);
    
    function mintNormallWithParents(address player) external;
    
    function currentId() external view returns(uint);
    
    function upGradeStar(uint tokenId) external;
    
    function starLimit(uint stars) external view returns(uint);
    
    function creationIndex(uint tokenId) external view returns(uint);
    
    
}

interface IBOX {
    function mint(address player, uint[2] memory parents_) external;

    function burn(uint tokenId_) external returns (bool);

    function checkParents(uint tokenId_) external view returns (uint[2] memory);

    function checkGrow(uint tokenId_) external view returns (uint[2] memory);

    function checkLife(uint tokenId_) external view returns (uint[2] memory);
    
    function checkEnergy(uint tokenId_) external view returns (uint[2] memory);
}

interface IStable {
    function isStable(uint tokenId) external view returns (bool);
    
    function rewardRate(uint level) external view returns(uint);

    function isUsing(uint tokenId) external view returns (bool);

    function changeUsing(uint tokenId, bool com_) external;

    function CattleOwner(uint tokenId) external view returns (address);

    function getStableLevel(address addr_) external view returns (uint);

    function energy(uint tokenId) external view returns (uint);

    function grow(uint tokenId) external view returns (uint);

    function costEnergy(uint tokenId, uint amount) external;
    
    function addStableExp(address addr, uint amount) external;
    
    function userInfo(address addr) external view returns(uint,uint);
    
    function checkUserCows(address addr_) external view returns (uint[] memory);
    
    function growAmount(uint time_, uint tokenId) external view returns(uint);
    
    function refreshTime() external view returns(uint);
    
    function feeding(uint tokenId) external view returns(uint);
    
    function levelLimit(uint index) external view returns(uint);
    
    function compoundCattle(uint tokenId) external;

    function growAmountItem(uint times,uint tokenID) external view returns(uint);

}

interface IMilk{
    function userInfo(address addr) external view returns(uint,uint);
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IPlanet{
    
    function isBonding(address addr_) external view returns(bool);
    
    function addTaxAmount(address addr,uint amount) external;
    
    function getUserPlanet(address addr_) external view returns(uint);
    
    function findTax(address addr_) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Cattle1155 is OwnableUpgradeable, ERC1155BurnableUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    mapping(address => mapping(uint => uint)) public minters;
    address public superMinter;
    mapping(address => bool) public admin;
    mapping(address => mapping(uint => uint))public userBurn;
    mapping(uint => uint) public itemType;
    uint public itemAmount;
    uint public burned;
    function setSuperMinter(address newSuperMinter_) public onlyOwner {
        superMinter = newSuperMinter_;
    }

    function setMinter(address newMinter_, uint itemId_, uint amount_) public onlyOwner {
        minters[newMinter_][itemId_] = amount_;
    }

    function setMinterBatch(address newMinter_, uint[] calldata ids_, uint[] calldata amounts_) public onlyOwner returns (bool) {
        require(ids_.length > 0 && ids_.length == amounts_.length, "ids and amounts length mismatch");
        for (uint i = 0; i < ids_.length; ++i) {
            minters[newMinter_][ids_[i]] = amounts_[i];
        }
        return true;
    }

    string private _name;
    string private _symbol;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    struct ItemInfo {
        uint itemId;
        string name;
        uint currentAmount;
        uint burnedAmount;
        uint maxAmount;
        uint[3] effect;
        bool tradeable;
        string tokenURI;
    }

    mapping(uint => ItemInfo) public itemInfoes;
    mapping(uint => uint) public itemLevel;
    string public myBaseURI;
    
    mapping(uint => uint) public itemExp;
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC1155_init('123456');
        _name = "Item";
        _symbol = "Item";
        myBaseURI = "123456";
    }
    // constructor() ERC1155("123456") {
    //     _name = "Item";
    //     _symbol = "Item";
    //     myBaseURI = "123456";
    // }
    
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        if (!admin[msg.sender]){
            require(itemInfoes[id].tradeable,'not tradeable');
        }
        
        _safeTransferFrom(from, to, id, amount, data);
    }
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        if(!admin[msg.sender]){
            for(uint i = 0; i < ids.length; i++){
                require(itemInfoes[ids[i]].tradeable,"not tradeable");
            }
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function setMyBaseURI(string memory uri_) public onlyOwner {
        myBaseURI = uri_;
    }

    function checkItemEffect(uint id_) external view returns (uint[3] memory){
        return itemInfoes[id_].effect;
    }

    function newItem(string memory name_, uint itemId_, uint maxAmount_, uint[3] memory effect_, uint types,bool tradeable_,uint level_,uint itemExp_, string memory tokenURI_) public onlyOwner {
        require(itemId_ != 0 && itemInfoes[itemId_].itemId == 0, "Cattle: wrong itemId");

        itemInfoes[itemId_] = ItemInfo({
        itemId : itemId_,
        name : name_,
        currentAmount : 0,
        burnedAmount : 0,
        maxAmount : maxAmount_,
        effect : effect_,
        tradeable : tradeable_,
        tokenURI : tokenURI_
        });
        itemType[itemId_] = types;
        itemLevel[itemId_] = level_;
        itemAmount ++;
        itemExp[itemId_] = itemExp_;
    }
    
    function setAdmin(address addr,bool b) external onlyOwner {
        admin[addr] = b;
    }

    function editItem(string memory name_, uint itemId_, uint maxAmount_, uint[3] memory effect_,uint types, bool tradeable_,uint level_, uint itemExp_, string memory tokenURI_) public onlyOwner {
        require(itemId_ != 0 && itemInfoes[itemId_].itemId == itemId_, "Cattle: wrong itemId");

        itemInfoes[itemId_] = ItemInfo({
        itemId : itemId_,
        name : name_,
        currentAmount : itemInfoes[itemId_].currentAmount,
        burnedAmount : itemInfoes[itemId_].burnedAmount,
        maxAmount : maxAmount_,
        effect : effect_,
        tradeable : tradeable_,
        tokenURI : tokenURI_
        });
        itemType[itemId_] = types;
        itemLevel[itemId_] = level_;
        itemExp[itemId_] = itemExp_;
    }
    
    function checkTypeBatch(uint[] memory ids)external view returns(uint[] memory){
        uint[] memory out = new uint[](ids.length);
        for(uint i = 0; i < ids.length; i++){
            out[i] = itemType[ids[i]];
        }
        return out;
    }

    function mint(address to_, uint itemId_, uint amount_) public returns (bool) {
        require(amount_ > 0, "K: missing amount");
        require(itemId_ != 0 && itemInfoes[itemId_].itemId != 0, "K: wrong itemId");

        if (superMinter != _msgSender()) {
            require(minters[_msgSender()][itemId_] >= amount_, "Cattle: not minter's calling");
            minters[_msgSender()][itemId_] -= amount_;
        }

        require(itemInfoes[itemId_].maxAmount - itemInfoes[itemId_].currentAmount >= amount_, "Cattle: Token amount is out of limit");
        itemInfoes[itemId_].currentAmount += amount_;

        _mint(to_, itemId_, amount_, "");

        return true;
    }


    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) public returns (bool) {
        require(ids_.length == amounts_.length, "K: ids and amounts length mismatch");

        for (uint i = 0; i < ids_.length; i++) {
            require(ids_[i] != 0 && itemInfoes[ids_[i]].itemId != 0, "Cattle: wrong itemId");

            if (superMinter != _msgSender()) {
                require(minters[_msgSender()][ids_[i]] >= amounts_[i], "Cattle: not minter's calling");
                minters[_msgSender()][ids_[i]] -= amounts_[i];
            }

            require(itemInfoes[ids_[i]].maxAmount - itemInfoes[ids_[i]].currentAmount >= amounts_[i], "Cattle: Token amount is out of limit");
            itemInfoes[ids_[i]].currentAmount += amounts_[i];
        }

        _mintBatch(to_, ids_, amounts_, "");

        return true;
    }



    function burn(address account, uint256 id, uint256 value) public override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "Cattle: caller is not owner nor approved"
        );

        itemInfoes[id].burnedAmount += value;
        burned += value;
        userBurn[account][id] += value;
        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "Cattle: caller is not owner nor approved"
        );

        for (uint i = 0; i < ids.length; i++) {
            itemInfoes[i].burnedAmount += values[i];
            userBurn[account][ids[i]] += values[i];
            burned += values[i];
        }
        _burnBatch(account, ids, values);
    }

    function tokenURI(uint256 itemId_) public view returns (string memory) {
        require(itemInfoes[itemId_].itemId != 0, "K: URI query for nonexistent token");

        string memory URI = itemInfoes[itemId_].tokenURI;
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, URI))
        : URI;
    }

    function _baseURI() internal view returns (string memory) {
        return myBaseURI;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IMating {
    function matingTime(uint tokenId) external view returns(uint);
    
    function lastMatingTime(uint tokenId) external view returns(uint);
    
    function userMatingTimes(address addr) external view returns(uint);

    function checkMatingTime(uint tokenId) external view returns (uint);

    function excessTimes(uint tokenId) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IProfilePhoto {
    function mintBabyBull(address addr_) external;

    function mintAdultBull(address addr_) external;

    function mintBabyCow(address addr_) external;

    function mintAdultCow(address addr_) external;

    function mintMysteryBox(address addr_) external;

    function getUserPhotos(address addr_) external view returns(uint[]memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICompound{
    function starExp(uint tokenId) external view returns(uint);
    
    function upgradeLimit(uint star_) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarket{
    function getSellingList(uint goodsType_, address addr_) external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMail{
    function bvgClaimed(address addr)external view returns(uint);
    function bvtClaimed(address addr)external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICattle1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IPlanet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./newUserRefer.sol";
contract TechnologyTree is OwnableUpgradeable {
    IStable public stable;
    IERC20 public BVT;
    mapping(address => mapping(uint => uint)) public userTec;

    struct TecInfo {
        uint levelLimit;
        uint types;
        uint[] effect;
        uint[] upgradeLimit;
    }

    mapping(uint => TecInfo) public tecInfo;
    uint[] tecList;
    mapping(uint => uint) tecIndex;
    NewUserRefer public newRefer;
    event FullTecLevel(address indexed player, uint indexed tecId);

    function setStable(address addr) external onlyOwner {
        stable = IStable(addr);
    }

    function setBVT(address addr) external onlyOwner {
        BVT = IERC20(addr);
    }

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        // newTechnology(3001,1,1,[100,95,90,80,70,50],[100,250,450,700,1000]);
        // newTechnology(3002,1,3,[0,4*3600,9*3600,16*3600,25*3600,36*3600],[100,250,450,700,1000]);
        // newTechnology(1001,2,1,[100,102,105,109,114,120],[100,250,450,700,1000]);
        // newTechnology(1002,2,3,[100,102,105,109,114,120],[100,250,450,700,1000]);
        // newTechnology(1003,2,5,[0,2,5,9,14,20],[100,250,450,700,1000]);
        // newTechnology(4001,3,1,[1000,1010,1025,1045,1070,1100],[100,250,450,700,1000]);
        // newTechnology(4003,3,3,[1000,1010,1025,1045,1070,1100],[100,250,450,700,1000]);
        // newTechnology(4004,3,3,[0,4,9,15,22,30],[100,250,450,700,1000]);
        // newTechnology(4002,3,5,[1000,1010,1025,1045,1070,1100],[100,250,450,700,1000]);
    }

    function newTechnology(uint ID, uint types_, uint levelLimit_, uint[] memory effect, uint[] memory upgradeLimit) public onlyOwner {
        require(tecIndex[ID] == 0, 'exist ID');
        tecInfo[ID].types = types_;
        tecInfo[ID].levelLimit = levelLimit_;
        tecInfo[ID].effect = effect;
        tecInfo[ID].upgradeLimit = upgradeLimit;
        tecIndex[ID] = tecList.length;
        tecList.push(ID);
    }

    function editTechnology(uint ID, uint types_, uint levelLimit_, uint[] memory effect, uint[] memory upgradeLimit) public onlyOwner {
        require(tecIndex[ID] != 0, 'nonexistent ID');
        tecInfo[ID].types = types_;
        tecInfo[ID].levelLimit = levelLimit_;
        tecInfo[ID].effect = effect;
        tecInfo[ID].upgradeLimit = upgradeLimit;
    }

    function buyTec(uint ID, uint amount) external {
        require(tecInfo[ID].types != 0, 'nonexistent ID');
        require(getUserTecLevel(msg.sender, ID) < 5,'out of level limit');
        uint level = stable.getStableLevel(msg.sender);
        uint oldLevel = getUserTecLevel(msg.sender, ID);
        require(level >= tecInfo[ID].levelLimit, 'not enough level');
        BVT.transferFrom(msg.sender, address(this), amount);
        userTec[msg.sender][ID] += amount;

        uint newLevel = getUserTecLevel(msg.sender, ID);
        if (newLevel > oldLevel && newLevel >= 2 && address(newRefer) != address(0)){
            newRefer.finishTask(msg.sender,3);
        }
        if (newLevel > oldLevel && newLevel == 5) {
            emit FullTecLevel(msg.sender, ID);
        }
    }
    function setNewRefer(address addr) external onlyOwner{
        newRefer = NewUserRefer(addr);
    }


    function buyTecBatch(uint[] memory ids, uint[] memory amounts) external {
        require(ids.length == amounts.length, 'wrong length');
        uint level = stable.getStableLevel(msg.sender);
        uint total;
        uint oldLevel;
        uint newLevel;
        for (uint i = 0; i < ids.length; i ++) {
            require(tecInfo[ids[i]].types != 0, 'nonexistent ID');
            require(level >= tecInfo[ids[i]].levelLimit, 'not enough level');
            oldLevel = getUserTecLevel(msg.sender, ids[i]);
            total += amounts[i];
            userTec[msg.sender][ids[i]] += amounts[i];
            newLevel = getUserTecLevel(msg.sender, ids[i]);
            if (newLevel > oldLevel && newLevel >= 2 && address(newRefer) != address(0)){
                newRefer.finishTask(msg.sender,3);
            }
            require(newLevel <= 5,'out of level limit');
            if (newLevel > oldLevel && newLevel == 5) {
                emit FullTecLevel(msg.sender, ids[i]);
            }
        }
        BVT.transferFrom(msg.sender, address(this), total);

    }

    function getUserTecLevel(address addr, uint ID) public view returns (uint out){
        uint amount = userTec[addr][ID];
        uint[] memory list = tecInfo[ID].upgradeLimit;

        for (uint i = 0; i < list.length; i ++) {
            if (amount < list[i] * 1e18) {
                out = i;
                return out;
            }
        }
        out = 5;
    }

    function checkTecEffet(uint ID) external view returns (uint[] memory){
        return tecInfo[ID].effect;
    }

    function checkTecList()public view returns(uint[] memory){
        return tecList;
    }

    function checkUserTecEffet(address addr, uint ID) external view returns (uint){
        return tecInfo[ID].effect[getUserTecLevel(addr, ID)];
    }

    function getUserTecLevelBatch(address addr, uint[] memory list) external view returns (uint[] memory out){
        out = new uint[](list.length);
        for (uint i = 0; i < list.length; i ++) {
            out[i] = getUserTecLevel(addr, list[i]);
        }
    }

    function checkUserExpBatch(address addr, uint[] memory list) public view returns (uint[] memory out){
        out = new uint[](list.length);
        for (uint i = 0; i < list.length; i ++) {
            out[i] = userTec[addr][list[i]];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IPlanet721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function planetIdMap(uint tokenId) external view returns (uint256 cardId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function mint(address player_, uint type_) external returns (uint256);
    
    function changeType(uint tokenId, uint type_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBadge{
    function mint(address player,uint skinId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function checkUserBadgeList(address player) external view returns (uint[] memory);
    function badgeIdMap(uint tokenID) external view returns(uint);
    function checkUserBadge(address player,uint ID) external view returns(uint[] memory);
    function checkBadgeEffect(uint badgeID) external view returns(uint);
    function checkUserBadgeIDList(address player) external view returns (uint[] memory);
    function burn(uint tokenId_) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CattleSkin is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint currentId = 1;
    address public superMinter;
    mapping(address => uint) public minters;
    mapping(uint => uint) public skinIdMap;
    uint[] eff;
    constructor() ERC721('Cattle Skin', 'Cattle Skin') {
        myBaseURI = "https://bv-test.blockpulse.net/api/nft/skin";
        superMinter = _msgSender();
        eff = [500, 0, 0, 0];
        skinInfo[10005] = SkinInfo({
        name : 'Baby Bomber',
        ID : 10005,
        level : 1,
        effect : eff,
        URI : '10005',
        burnAmount:0,
        currentAmount:0
        });
        skinInfo[10006] = SkinInfo({
        name : 'Evil Blaze Dryad',
        ID : 10006,
        level : 1,
        effect : eff,
        URI : '10006',
        burnAmount:0,
        currentAmount:0
        });
        skinInfo[10007] = SkinInfo({
        name : 'Space Explorer',
        ID : 10007,
        level : 2,
        effect : eff,
        URI : '10007',
        burnAmount:0,
        currentAmount:0
        });
        skinInfo[10008] = SkinInfo({
        name : 'Electric-Arc Spirit',
        ID : 10008,
        level : 2,
        effect : eff,
        URI : '10008',
        burnAmount:0,
        currentAmount:0
        });
        skinInfo[10009] = SkinInfo({
        name : 'tHolo Electro-Magnetizer',
        ID : 10009,
        level : 3,
        effect : eff,
        URI : '10009',
        burnAmount:0,
        currentAmount:0
        });
    }
    struct SkinInfo{
        string name;
        uint ID;
        uint level; //f 1 for epic 2 for lengend 3 for limit
        uint[] effect;//1 for attack 2 for defense 3 for stamia 4 for life
        string URI;
        uint burnAmount;
        uint currentAmount;
        
    }
    mapping(uint => SkinInfo) public skinInfo;
    function newSkin(string memory name, uint ID, uint level, uint[] memory effect,string memory URI_) external onlyOwner{
        require(skinInfo[ID].ID == 0,'exist ID');
        skinInfo[ID] = SkinInfo({
            name : name,
            ID : ID,
            level : level,
            effect : effect,
            URI : URI_,
            burnAmount:0,
            currentAmount:0
        });
    }
    
    function editSkin(string memory name, uint ID, uint level, uint[] memory effect,string memory URI_) external onlyOwner{
        require(skinInfo[ID].ID != 0,'nonexistent ID');
        skinInfo[ID] = SkinInfo({
            name : name,
            ID : ID,
            level : level,
            effect : effect,
            URI : URI_,
            burnAmount:skinInfo[ID].burnAmount,
            currentAmount:skinInfo[ID].currentAmount
        });
    }

    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }
    
    function checkSkinEffect(uint skinID) public view returns(uint[] memory){
        require(skinInfo[skinID].ID != 0,'wrong skin ID');
        return skinInfo[skinID].effect;
    }

    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function mint(address player,uint skinId) public {
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        require(skinInfo[skinId].ID != 0,'nonexistent ID');
        skinIdMap[currentId] = skinId;
        _mint(player, currentId);
        currentId ++;
        skinInfo[skinId].currentAmount++;
    }
    
    function mintBatch(address player, uint[] memory ids) public{
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] >= ids.length, 'no mint amount');
            minters[_msgSender()] -= ids.length;
        }
        for(uint i = 0; i < ids.length; i ++){
            require(skinInfo[ids[i]].ID != 0,'nonexistent ID');
            skinIdMap[currentId] = ids[i];
            _mint(player, currentId);
            currentId ++;
            skinInfo[ids[i]].currentAmount++;
        }
    }

    function checkUserSkinList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = token;
        }
        return list;
    }
    
    function checkUserSkinIDList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = skinIdMap[token];
        }
        return list;
    }
    
    function setBaseUri(string memory uri) public onlyOwner{
        myBaseURI = uri;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI,"/",skinIdMap[tokenId_].toString()));
    }


    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        _burn(tokenId_);
        skinInfo[skinIdMap[tokenId_]].burnAmount++;
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interface/IPlanet.sol";
import "../interface/ICattle1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ITec.sol";
import "../interface/Ibadge.sol";
import "./newUserRefer.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

contract MilkFactory is OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    ICOW public cattle;
    IStable public stable;
    IPlanet public planet;
    IERC20Upgradeable public BVT;
    ICattle1155 public cattleItem;
    uint public daliyOut;
    uint public rate;
    uint public totalPower;
    uint public debt;
    uint public lastTime;
    uint public cowsAmount;
    uint public timePerEnergy;
    uint constant acc = 1e10;
    uint public technologyId;


    struct UserInfo {
        uint totalPower;
        uint[] cattleList;
        uint cliamed;
    }

    struct StakeInfo {
        bool status;
        uint milkPower;
        uint tokenId;
        uint endTime;
        uint starrtTime;
        uint claimTime;
        uint debt;

    }

    mapping(address => UserInfo) public userInfo;
    mapping(uint => StakeInfo) public stakeInfo;

    uint public totalClaimed;
    ITec public tec;
    IBadge public badge;

    struct UserBadge {
        uint tokenID;
        uint badgeID;
        uint power;
    }

    mapping(address => UserBadge) public userBadge;
    uint randomSeed;
    mapping(uint => uint) public compoundRate;
    mapping(uint => uint) public compoundRew;
    NewUserRefer public newRefer;
    uint public taskAmount;
    event ClaimMilk(address indexed player, uint indexed amount);
    event RenewTime(address indexed player, uint indexed tokenId, uint indexed newEndTIme);
    event Stake(address indexed player, uint indexed tokenId);
    event UnStake(address indexed player, uint indexed tokenId);
    event Reward(address indexed player, uint indexed reward,uint indexed amount);

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        daliyOut = 100000e18;
        rate = daliyOut / 86400;
        timePerEnergy = 60;
        technologyId = 1;
        compoundRate[40001] = 500;
        compoundRate[40002] = 300;
        compoundRate[40003] = 100;
        compoundRew[40001] = 2;
        compoundRew[40002] = 6;
        compoundRew[40003] = 18;
    }

    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed)));
        randomSeed ++;
        return random % _length + 1;
    }

    function setCattle(address cattle_) external onlyOwner {
        cattle = ICOW(cattle_);
    }

    function setTec(address addr) external onlyOwner {
        tec = ITec(addr);
    }

    function setNewRefer(address addr) external onlyOwner{
        newRefer = NewUserRefer(addr);
    }

    function setTimePerEnergy(uint per) external onlyOwner{
        timePerEnergy = per;
    }

    function setBadge(address addr) external onlyOwner {
        badge = IBadge(addr);
    }

    function setItem(address item_) external onlyOwner {
        cattleItem = ICattle1155(item_);
    }

    function setStable(address stable_) external onlyOwner {
        stable = IStable(stable_);
    }

    function setDaily(uint amount )external onlyOwner{
        daliyOut = amount;
        rate = daliyOut / 86400;
    }

    function setPlanet(address planet_) external onlyOwner {
        planet = IPlanet(planet_);
    }

    function setBVT(address BVT_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
    }

    function checkUserStakeList(address addr_) public view returns (uint[] memory){
        return userInfo[addr_].cattleList;
    }

    function setTaskAmount(uint amount) external onlyOwner{
        taskAmount = amount;
    }

    function coutingDebt() public view returns (uint _debt){
        _debt = totalPower > 0 ? rate * (block.timestamp - lastTime) * acc / totalPower + debt : 0 + debt;
    }

    function coutingPower(address addr_, uint tokenId) public view returns (uint){
        uint milk = cattle.getMilk(tokenId) * tec.checkUserTecEffet(addr_, 1001) / 100;
        uint milkRate = cattle.getMilkRate(tokenId) * tec.checkUserTecEffet(addr_, 1002) / 100;
        uint power_ = (milkRate + milk) / 2;
        uint level = stable.getStableLevel(addr_);
        uint rates = stable.rewardRate(level);
        uint finalPower = power_ * rates / 100;
        return finalPower;
    }

    function caculeteCow(uint tokenId) public view returns (uint){
        StakeInfo storage info = stakeInfo[tokenId];
        if (!info.status) {
            return 0;
        }

        uint rew;
        uint tempDebt;
        if (info.claimTime < info.endTime && info.endTime < block.timestamp) {
            tempDebt = rate * (info.endTime - info.claimTime) * acc / totalPower;
            rew = info.milkPower * tempDebt / acc;
        } else {
            tempDebt = coutingDebt();
            rew = info.milkPower * (tempDebt - info.debt) / acc;
        }


        return rew;
    }

    function caculeteAllCow(address addr_) public view returns (uint){
        uint[] memory list = checkUserStakeList(addr_);
        uint rew;
        for (uint i = 0; i < list.length; i++) {
            rew += caculeteCow(list[i]);
        }
        if (userBadge[addr_].tokenID != 0) {
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[addr_].tokenID)));
            rew += caculeteCow(id);
        }
        return rew;
    }

    function userItem(uint tokenId, uint itemId, uint amount) public {
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        uint[3]memory effect = cattleItem.checkItemEffect(itemId);
        require(effect[0] > 0, 'wrong item');
        uint energyLimit = cattle.getEnergy(tokenId);
        uint value;
        if (amount * effect[0] >= energyLimit) {
            value = energyLimit;
        } else {
            value = amount * effect[0];
        }
        stakeInfo[tokenId].endTime += value * timePerEnergy;
        stable.addStableExp(msg.sender, cattleItem.itemExp(itemId) * amount);
        cattleItem.burn(msg.sender, itemId, amount);
        emit RenewTime(msg.sender, tokenId, stakeInfo[tokenId].endTime);
    }


    function claimAllMilk() public {
        uint[] memory list = checkUserStakeList(msg.sender);
        uint rew;
        for (uint i = 0; i < list.length; i++) {
            rew += caculeteCow(list[i]);
            if (block.timestamp >= stakeInfo[list[i]].endTime) {
                debt = coutingDebt();
                totalPower -= stakeInfo[list[i]].milkPower;
                userInfo[msg.sender].totalPower -=stakeInfo[list[i]].milkPower;
                lastTime = block.timestamp;
                delete stakeInfo[list[i]];
                stable.changeUsing(list[i], false);
                cowsAmount --;
                for (uint k = 0; k < userInfo[msg.sender].cattleList.length; k ++) {
                    if (userInfo[msg.sender].cattleList[k] == list[i]) {
                        userInfo[msg.sender].cattleList[k] = userInfo[msg.sender].cattleList[userInfo[msg.sender].cattleList.length - 1];
                        userInfo[msg.sender].cattleList.pop();
                    }
                }
            } else {
                stakeInfo[list[i]].claimTime = block.timestamp;
                stakeInfo[list[i]].debt = coutingDebt();
            }
        }
        if (userBadge[msg.sender].tokenID != 0) {
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            rew += caculeteCow(id);
        }
        uint tax = planet.findTax(msg.sender);
        uint taxAmuont = rew * tax / 100;
        totalClaimed += rew;
        planet.addTaxAmount(msg.sender, taxAmuont);
        BVT.transfer(msg.sender, rew - taxAmuont);
        BVT.transfer(address(planet), taxAmuont);
        userInfo[msg.sender].cliamed += rew - taxAmuont;
        if(address(newRefer) != address(0) &&userInfo[msg.sender].cliamed > taskAmount){
            newRefer.finishTask(msg.sender,0);
        }
        emit ClaimMilk(msg.sender, rew);
    }

    function removeList(address addr, uint index) public onlyOwner {
        uint length = userInfo[addr].cattleList.length;
        userInfo[addr].cattleList[index] = userInfo[addr].cattleList[length - 1];
        userInfo[addr].cattleList.pop();
    }

    function coutingEnergyCost(address addr, uint amount) public view returns (uint){
        uint rates = 100 - tec.checkUserTecEffet(addr, 1003);
        return (amount * rates / 100);
    }


    function stake(uint tokenId, uint energyCost) public {
        require(!stable.isUsing(tokenId), 'the cattle is using');
        require(stable.isStable(tokenId), 'not in the stable');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        require(cattle.getAdult(tokenId), 'must bu adult');
        stable.changeUsing(tokenId, true);
        uint tempDebt = coutingDebt();
        if (userInfo[msg.sender].cattleList.length == 0 && userBadge[msg.sender].tokenID != 0) {
            debt = tempDebt;
            totalPower += userBadge[msg.sender].power;
            lastTime = block.timestamp;
            userInfo[msg.sender].totalPower += userBadge[msg.sender].power;
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            stakeInfo[id] = StakeInfo({
            status : true,
            milkPower : userBadge[msg.sender].power,
            tokenId : id,
            endTime : block.timestamp + 86400000,
            starrtTime : block.timestamp,
            claimTime : block.timestamp,
            debt : tempDebt
            });
        }
        userInfo[msg.sender].cattleList.push(tokenId);
        uint power = coutingPower(msg.sender, tokenId);
        require(power > 0, 'only cow can stake');
        totalPower += power;
        lastTime = block.timestamp;
        debt = tempDebt;
        userInfo[msg.sender].totalPower += power;
        stakeInfo[tokenId] = StakeInfo({
        status : true,
        milkPower : power,
        tokenId : tokenId,
        endTime : findEndTime(tokenId, energyCost),
        starrtTime : block.timestamp,
        claimTime : block.timestamp,
        debt : tempDebt
        });
        stable.costEnergy(tokenId, coutingEnergyCost(msg.sender, energyCost));
        cowsAmount ++;
        emit Stake(msg.sender, tokenId);
    }

    function unStake(uint tokenId) public {
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        uint rew = caculeteCow(tokenId);
        uint tempDebt = coutingDebt();
        if (rew != 0) {
            uint tax = planet.findTax(msg.sender);
            uint taxAmuont = rew * tax / 100;
            planet.addTaxAmount(msg.sender, taxAmuont);
            BVT.transfer(msg.sender, rew - taxAmuont);
            BVT.transfer(address(planet), taxAmuont);
            userInfo[msg.sender].cliamed += rew - taxAmuont;
            totalClaimed += rew;
        }
        debt = tempDebt;
        totalPower -= stakeInfo[tokenId].milkPower;
        userInfo[msg.sender].totalPower -= stakeInfo[tokenId].milkPower;
        lastTime = block.timestamp;
        delete stakeInfo[tokenId];
        stable.changeUsing(tokenId, false);
        for (uint i = 0; i < userInfo[msg.sender].cattleList.length; i ++) {
            if (userInfo[msg.sender].cattleList[i] == tokenId) {
                userInfo[msg.sender].cattleList[i] = userInfo[msg.sender].cattleList[userInfo[msg.sender].cattleList.length - 1];
                userInfo[msg.sender].cattleList.pop();
            }
        }
        if (userInfo[msg.sender].cattleList.length == 0 && userBadge[msg.sender].tokenID != 0) {
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            rew = caculeteCow(id);
            if (rew != 0) {
                uint tax = planet.findTax(msg.sender);
                uint taxAmuont = rew * tax / 100;
                planet.addTaxAmount(msg.sender, taxAmuont);
                BVT.transfer(msg.sender, rew - taxAmuont);
                BVT.transfer(address(planet), taxAmuont);
                userInfo[msg.sender].cliamed += rew - taxAmuont;
                totalClaimed += rew;
            }
            userInfo[msg.sender].totalPower -= stakeInfo[id].milkPower;
            totalPower -= stakeInfo[id].milkPower;
            lastTime = block.timestamp;
        }
        cowsAmount--;
        emit UnStake(msg.sender, tokenId);
    }

    function setDaliyOut(uint out_) external onlyOwner {
        daliyOut = out_;
        rate = daliyOut / 86400;
    }

    function addBadge(uint tokenID) external {
        require(userBadge[msg.sender].tokenID == 0, 'had badge');
        badge.safeTransferFrom(msg.sender, address(this), tokenID);
        userBadge[msg.sender].tokenID = tokenID;
        userBadge[msg.sender].badgeID = badge.badgeIdMap(tokenID);
        userBadge[msg.sender].power = badge.checkBadgeEffect(userBadge[msg.sender].badgeID);
        if (userInfo[msg.sender].cattleList.length > 0) {
            uint tempDebt = coutingDebt();
            debt = tempDebt;
            totalPower += userBadge[msg.sender].power;
            userInfo[msg.sender].totalPower += userBadge[msg.sender].power;
            lastTime = block.timestamp;
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, tokenID)));
            stakeInfo[id] = StakeInfo({
            status : true,
            milkPower : userBadge[msg.sender].power,
            tokenId : id,
            endTime : block.timestamp + 86400000,
            starrtTime : block.timestamp,
            claimTime : block.timestamp,
            debt : tempDebt
            });
        }

    }

    function pullOutBadge() external {
        require(userBadge[msg.sender].tokenID != 0, 'have no badge');
        badge.safeTransferFrom(address(this), msg.sender, userBadge[msg.sender].tokenID);

        if(userInfo[msg.sender].cattleList.length > 0){
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            uint rew = caculeteCow(id);
            if (rew != 0) {
                uint tax = planet.findTax(msg.sender);
                uint taxAmuont = rew * tax / 100;
                planet.addTaxAmount(msg.sender, taxAmuont);
                BVT.transfer(msg.sender, rew - taxAmuont);
                BVT.transfer(address(planet), taxAmuont);
                userInfo[msg.sender].cliamed += rew - taxAmuont;
                totalClaimed += rew;

            }
            userInfo[msg.sender].totalPower -= stakeInfo[id].milkPower;
            debt = coutingDebt();
            totalPower -= stakeInfo[id].milkPower;
            lastTime = block.timestamp;
            delete stakeInfo[id];
        }


        delete userBadge[msg.sender];
    }

    function renewTime(uint tokenId, uint energyCost) public {
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        stable.costEnergy(tokenId, energyCost);
        stakeInfo[tokenId].endTime += energyCost * timePerEnergy;
        emit RenewTime(msg.sender, tokenId, stakeInfo[tokenId].endTime);
    }

    function setCompoundRate(uint badgeID, uint rates) external onlyOwner {
        compoundRate[badgeID] = rates;
    }

    function setCompoundRew(uint badgeId,uint rews) external onlyOwner{
        compoundRew[badgeId] = rews;
    }

    function findEndTime(uint tokenId, uint energyCost) public view returns (uint){
        uint energyTime = block.timestamp + energyCost * timePerEnergy;
        uint deadTime = cattle.deadTime(tokenId);
        if (energyTime <= deadTime) {
            return energyTime;
        } else {
            return deadTime;
        }
    }

    function compoundBadge(uint[3] memory tokenIDs) external {
        uint badgeID = badge.badgeIdMap(tokenIDs[0]);
        require(badgeID >= 40001 && badgeID <= 40003, 'wrong badge ID');
        require(badgeID == badge.badgeIdMap(tokenIDs[1]) && badge.badgeIdMap(tokenIDs[1]) == badge.badgeIdMap(tokenIDs[2]), 'wrong badgeID');
        badge.burn(tokenIDs[0]);
        badge.burn(tokenIDs[1]);
        badge.burn(tokenIDs[2]);
        uint _rate = compoundRate[badgeID];
        uint out = rand(1000);
        if (out <= _rate) {
            badge.mint(msg.sender, badgeID + 1);
            emit Reward(msg.sender,badgeID + 1,1);
        } else {
            cattleItem.mint(msg.sender,20004,compoundRew[badgeID]);
            emit Reward(msg.sender,20004,compoundRew[badgeID]);
        }
    }

    function compoundBadgeShred() external {
        cattleItem.burn(msg.sender,20004,3);
        uint out = rand(100);
        if(out <= 700){
            badge.mint(msg.sender, 40001);
            emit Reward(msg.sender,40001,1);
        }else{
            emit Reward(msg.sender,0,0);
        }
    }

    function setDebt(uint debt_) external onlyOwner{
        debt = debt_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Burnable_init() internal onlyInitializing {
    }

    function __ERC1155Burnable_init_unchained() internal onlyInitializing {
    }
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
pragma solidity ^0.8.4;

interface ICattle1155 {
    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) external returns (bool);

    function mint(address to_, uint cardId_, uint amount_) external returns (bool);

    function safeTransferFrom(address from, address to, uint256 cardId, uint256 amount, bytes memory data_) external;

    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external;

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function balanceOf(address account, uint256 tokenId) external view returns (uint);

    function burned(uint) external view returns (uint);

    function burn(address account, uint256 id, uint256 value) external;

    function checkItemEffect(uint id_) external view returns (uint[3] memory);
    
    function itemLevel(uint id_) external view returns (uint);
    
    function itemExp(uint id_) external view returns(uint);
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./refer.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./cattle_items.sol";
contract NewUserRefer is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public usdt;
    mapping(address => bool) public admin;
    mapping(address => bool) public isRefer;
    uint public reward;
    //    bool reward;
    //    bool stableLevel;
    //    bool grow;
    //    bool tec;
    //    bool tax;
    struct UserInfo {
        bool isRefer;
        bool[5] taskInfo;
        address invitor;
        uint claimed;
        address[] referList;
        uint referAmount;
        bool isDone;
        uint toClaim;
        uint finishAmount;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => uint) public taskAmount;
    mapping(address => bool) public claimedTaskReward;
    Cattle1155 public item;
    uint[] itemRewardID;
    uint[] itemRewardAmount;
    event Bond(address indexed player, address indexed invitor);
    event Claim(address indexed player, uint indexed amount);
    event FinishTask(address indexed player, uint indexed index);

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        reward = 5e6;
        item = Cattle1155(0xe1003955d629c6837cf31d4D059cf271bE1D2620);
        usdt = IERC20Upgradeable(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    }


    function setItem(address addr) external onlyOwner{
        item = Cattle1155(addr);
    }

    function rand(uint seed) public view returns(address){
        uint rands = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp,seed)));
        uint temp = type(uint160).max;
        return address(uint160(rands%temp));
    }


    function addReferList(address[] memory addrs, bool b) external onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            userInfo[addrs[i]].isRefer = b;
        }
    }

    function setUsdt(address addr) external onlyOwner {
        usdt = IERC20Upgradeable(addr);
    }

    function setReward(uint rew) external onlyOwner {
        reward = rew;
    }

    function setAdmin(address[] memory addrs, bool b) external onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            admin[addrs[i]] = b;
        }
    }

    function checkUserTask(address addr) public view returns (bool[5] memory){
        return userInfo[addr].taskInfo;
    }

    function checkUserReferList(address addr) public view returns (address[] memory){
        return userInfo[addr].referList;
    }

    function bond(address invitor) external {
        require(userInfo[invitor].isRefer, 'wrong invitor');
        require(!userInfo[msg.sender].isRefer, 'refer can not bond');
        require(userInfo[msg.sender].invitor == address(0), 'already bonded');
        userInfo[msg.sender].invitor = invitor;
        userInfo[invitor].referAmount++;
        userInfo[invitor].referList.push(msg.sender);
    }

    function finishTask(address addr, uint index) external {
        require(admin[msg.sender], 'not admin');
        UserInfo storage info = userInfo[addr];
        if (info.isRefer || info.invitor == address(0) || info.isDone) {
            return;
        }
        UserInfo storage referInfo = userInfo[info.invitor];
        if (info.taskInfo[index]) {
            return;
        }
        info.taskInfo[index] = true;
        taskAmount[addr]++;
        if (taskAmount[addr] >= 5) {
            info.isDone = true;
            referInfo.finishAmount ++;
            if (referInfo.finishAmount <= 10) {
                referInfo.toClaim += reward;
            }
        }

    }

    function setItemReward(uint[] memory ids,uint[] memory amounts) external onlyOwner{
        itemRewardID = ids;
        itemRewardAmount = amounts;
    }

    function setUserReferList(address addr,uint amount) external onlyOwner{
        for(uint i = 0; i < amount; i++){
            userInfo[addr].referList.push(rand(i));
        }
    }

    function claimReward() external {
        UserInfo storage info = userInfo[msg.sender];
        require(info.toClaim > 0, 'no reward');
        usdt.transfer(msg.sender, info.toClaim);
        info.claimed += info.toClaim;
        info.toClaim = 0;
    }

    function claimTaskReward() external {
        require(userInfo[msg.sender].isDone, 'not finish task');
        require(!claimedTaskReward[msg.sender], 'claimed');
        claimedTaskReward[msg.sender] = true;
        item.mintBatch(msg.sender,itemRewardID,itemRewardAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interface/ICOW721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Refer is Ownable{
    IStable public stable;
    struct UserInfo{
        address invitor;
        uint referDirect;
        address[] referList; 
    }
    event Bond(address indexed player, address indexed invitor);
    mapping(address => UserInfo) public userInfo;
    ICOW public cattle;
    
    function setStable(address addr) onlyOwner external{
        stable = IStable(addr);
    }

    function setCattle(address addr) external onlyOwner{
        cattle = ICOW(addr);
    }
    
    function bondInvitor(address addr) external{
        require(stable.checkUserCows(addr).length > 0 || cattle.balanceOf(addr) > 0,'wrong invitor');
        require(userInfo[msg.sender].invitor == address(0),'had invitor');
        userInfo[addr].referList.push(msg.sender);
        userInfo[addr].referDirect++;
        userInfo[msg.sender].invitor = addr;
        emit Bond(msg.sender,addr);
    }
    
    function checkUserInvitor(address addr) external view returns(address){
        return userInfo[addr].invitor;
    }
    
    function checkUserReferList(address addr) external view returns(address[] memory){
        return userInfo[addr].referList;
    }
    
    function checkUserReferDirect(address addr) external view returns(uint){
        return userInfo[addr].referDirect;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface ITec{
    
    function getUserTecLevelBatch(address addr,uint[] memory list) external view returns(uint[] memory out);
    
    function getUserTecLevel(address addr,uint ID) external view returns(uint out);
    
    function checkUserExpBatch(address addr,uint[] memory list) external view returns(uint[] memory out);
    
    function checkUserTecEffet(address addr, uint ID) external view returns(uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
//    uint256[50] private __gap;/**/
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}