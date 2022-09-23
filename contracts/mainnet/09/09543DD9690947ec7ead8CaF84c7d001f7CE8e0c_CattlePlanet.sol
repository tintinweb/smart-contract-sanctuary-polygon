// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IPlanet721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interface/IBvInfo.sol";
import "../interface/ICattle1155.sol";
import "./newUserRefer.sol";

contract CattlePlanet is OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public BVG;
    IERC20Upgradeable public BVT;
    IPlanet721 public planet;
    IBvInfo public bvInfo;
    uint public febLimit;
    uint public battleTaxRate;
    uint public federalPrice;
    uint[] public currentPlanet;
    uint public upGradePlanetPrice;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        battleTaxRate = 30;
        federalPrice = 500 ether;
        upGradePlanetPrice = 500 ether;
        setPlanetType(1, 10000, 100, 20);
        setPlanetType(3, 5000, 10, 10);
        setPlanetType(2, 1000, 0, 10);
    }

    struct PlanetInfo {
        address owner;
        uint tax;
        uint population;
        uint normalTaxAmount;
        uint battleTaxAmount;
        uint motherPlanet;
        uint types;
        uint membershipFee;
        uint populationLimit;
        uint federalLimit;
        uint federalAmount;
        uint totalTax;
    }

    struct PlanetType {
        uint populationLimit;
        uint federalLimit;
        uint planetTax;
    }

    struct UserInfo {
        uint level;
        uint planet;
        uint taxAmount;
    }

    struct ApplyInfo {
        uint applyAmount;
        uint applyTax;
        uint lockAmount;
    }

    mapping(uint => PlanetInfo) public planetInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(address => uint) public ownerOfPlanet;
    mapping(address => ApplyInfo) public applyInfo;
    mapping(address => bool) public admin;
    mapping(uint => PlanetType) public planetType;
    mapping(uint => uint) public battleReward;
    address public banker;
    address public mail;
    ICattle1155 public item;
    mapping(uint => mapping(uint => uint)) public planetBattleReward;
    uint public currentDeadLine;
    mapping(uint => mapping(uint => bool)) public planetRewClaimed;
    NewUserRefer public newRefer;

    struct RentInfo {
        address owner;
        address rentOwner;
        uint rentTime;
        uint rentAmount;
    }

    mapping(uint => RentInfo) public rentInfo;
    mapping(address => uint) public rentId;

    event BondPlanet(address indexed player, uint indexed tokenId);
    event ApplyFederalPlanet (address indexed player, uint indexed amount, uint indexed tax);
    event CancelApply(address indexed player);
    event NewPlanet(address indexed addr, uint indexed tokenId, uint indexed motherPlanet, uint types);
    event UpGradeTechnology(uint indexed tokenId, uint indexed tecNum);
    event UpGradePlanet(uint indexed tokenId);
    event AddTaxAmount(uint indexed PlanetID, address indexed player, uint indexed amount);
    event SetPlanetFee(uint indexed PlanetID, uint indexed fee);
    event BattleReward(uint[2] indexed planetID);
    event DeployBattleReward(uint indexed id, uint indexed amount);
    event DeployPlanetReward(uint indexed id, uint indexed amount);
    event ReplacePlanet(address indexed newOwner, uint indexed tokenId);
    event PullOutCard(address indexed player, uint indexed id);
    event AddArmor(address indexed addr, uint indexed tokenID);
    modifier onlyPlanetOwner(uint tokenId) {
        require(msg.sender == planetInfo[tokenId].owner, 'not planet Owner');
        if (rentInfo[tokenId].rentOwner == msg.sender) {
            require(block.timestamp < rentInfo[tokenId].rentTime, 'out of time');
        }
        _;
    }

    modifier onlyOriginalOwner(uint tokenId) {
        if (rentInfo[tokenId].owner == address(0)) {
            require(msg.sender == planetInfo[tokenId].owner, 'not owner');
        }
        else {
            require(msg.sender == rentInfo[tokenId].owner, 'not owner');
            require(block.timestamp > rentInfo[tokenId].rentTime, 'must cancel rent');
        }
        _;
    }

    modifier onlyAdmin(){
        require(admin[msg.sender], 'not admin');
        _;

    }

    modifier reFreshBattle(){
        uint temp = block.timestamp - (block.timestamp - 86400 * 2 + 3600 * 12) % (86400 * 7) + (86400 * 7);
        if (currentDeadLine != temp) {
            currentDeadLine = temp;
        }
        _;
    }

    function setAdmin(address addr, bool b) external onlyOwner {
        admin[addr] = b;
    }

    function setToken(address BVG_, address BVT_) external onlyOwner {
        BVG = IERC20Upgradeable(BVG_);
        BVT = IERC20Upgradeable(BVT_);
    }

    function setMail(address addr) external onlyOwner {
        mail = addr;
    }

    function setPlanet721(address planet721_) external onlyOwner {
        planet = IPlanet721(planet721_);
    }

    function setBvInfo(address BvInfo) external onlyOwner {
        bvInfo = IBvInfo(BvInfo);
    }

    function setPlanetType(uint types_, uint populationLimit_, uint federalLimit_, uint planetTax_) public onlyOwner {
        planetType[types_] = PlanetType({
        populationLimit : populationLimit_,
        federalLimit : federalLimit_,
        planetTax : planetTax_
        });
    }

    function setItem(address addr) external onlyOwner {
        item = ICattle1155(addr);
    }

    function getBVTPrice() public view returns (uint){
        if (address(bvInfo) == address(0)) {
            return 1e16;
        }
        return bvInfo.getBVTPrice();
    }


    function bondPlanet(uint tokenId) external {
        require(userInfo[msg.sender].planet == 0, 'already bond');
        require(planetInfo[tokenId].tax > 0, 'none exits planet');
        require(planetInfo[tokenId].population < planetInfo[tokenId].populationLimit, 'out of population limit');
        if (planetInfo[tokenId].membershipFee > 0) {
            uint need = planetInfo[tokenId].membershipFee;
            BVT.safeTransferFrom(msg.sender, planet.ownerOf(tokenId), need);
        }
        planetInfo[tokenId].population ++;
        userInfo[msg.sender].planet = tokenId;
        emit BondPlanet(msg.sender, tokenId);
    }

    function userTaxAmount(address addr) external view returns (uint){
        return userInfo[addr].taxAmount;
    }

    function setPlanetPopLimit(uint id, uint limit) external onlyOwner {
        planetInfo[id].populationLimit = limit;
    }

    function setFederalPrice(uint price_) external onlyOwner {
        federalPrice = price_;
    }

    function applyFederalPlanet(uint amount, uint tax_) external {
        require(userInfo[msg.sender].planet != 0, 'not bond planet');
        require(applyInfo[msg.sender].applyAmount == 0, 'have apply, cancel first');
        require(tax_ < 20, 'tax must lower than 20%');
        applyInfo[msg.sender].applyTax = tax_;
        applyInfo[msg.sender].applyAmount = amount;
        applyInfo[msg.sender].lockAmount = federalPrice;
        BVT.safeTransferFrom(msg.sender, address(this), amount + applyInfo[msg.sender].lockAmount);
        emit ApplyFederalPlanet(msg.sender, amount, tax_);
    }

    function cancelApply() external {
        require(userInfo[msg.sender].planet != 0, 'not bond planet');
        require(applyInfo[msg.sender].lockAmount > 0, 'have apply, cancel first');
        BVT.safeTransfer(msg.sender, applyInfo[msg.sender].applyAmount + applyInfo[msg.sender].lockAmount);
        delete applyInfo[msg.sender];
        emit CancelApply(msg.sender);

    }

    function addPlanetTax(uint tokenId, uint normalAmount, uint battleAmount) external onlyOwner {
        planetInfo[tokenId].normalTaxAmount += normalAmount;
        planetInfo[tokenId].battleTaxAmount += battleAmount;
    }

    function setBattleReward(uint tokenID, uint amount) external onlyOwner {
        battleReward[tokenID] = amount;
    }

    function claimTax(uint amount) external {
        uint tokenID = ownerOfPlanet[msg.sender];
        require(tokenID != 0, 'you are not owner');
        require(planetInfo[tokenID].normalTaxAmount >= amount, 'out of tax amount');
        BVT.safeTransfer(msg.sender, amount);
        planetInfo[tokenID].normalTaxAmount -= amount;
    }

    function setNewRefer(address addr) external onlyOwner {
        newRefer = NewUserRefer(addr);
    }

    function approveFedApply(address addr_, uint tokenId) onlyPlanetOwner(tokenId) external {
        require(applyInfo[addr_].lockAmount > 0, 'wrong apply address');
        require(planetInfo[tokenId].federalAmount < planetInfo[tokenId].federalLimit, 'out of federal Planet limit');
        BVT.safeTransfer(msg.sender, applyInfo[addr_].applyAmount);
        BVT.safeTransfer(address(0), applyInfo[addr_].lockAmount);
        uint id = planet.mint(addr_, 2);
        uint temp = ownerOfPlanet[addr_];
        require(temp == 0, 'already have 1 planet');
        planetInfo[id].tax = applyInfo[addr_].applyTax;
        planetInfo[id].motherPlanet = tokenId;
        planetInfo[tokenId].federalAmount ++;
        ownerOfPlanet[addr_] = id;
        planetInfo[id].federalLimit = 0;
        planetInfo[id].populationLimit = 1000;
        planetInfo[id].owner = addr_;
        planetInfo[id].types = 2;
        currentPlanet.push(id);
        delete applyInfo[addr_];
        emit NewPlanet(addr_, id, tokenId, 2);
    }

    function setPlanetOwner(uint id, address addr) external onlyOwner {
        planetInfo[id].owner = addr;
    }

    function setPlanetType(uint id, uint type_) external onlyOwner {
        planetInfo[id].types = type_;
    }

    function claimBattleReward(uint[2] memory planetId, bytes32 r, bytes32 s, uint8 v) reFreshBattle public {//index 0 for winner
        bytes32 hash = keccak256(abi.encodePacked(planetId));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "not banker");
        require(msg.sender == planetInfo[planetId[0]].owner, 'not planet owner');
        require(!planetRewClaimed[planetId[0]][currentDeadLine] || !planetRewClaimed[planetId[1]][currentDeadLine], 'claimed');
        uint rew1 = planetInfo[planetId[1]].battleTaxAmount - planetBattleReward[planetId[1]][currentDeadLine];
        uint rew0 = planetInfo[planetId[0]].battleTaxAmount - planetBattleReward[planetId[0]][currentDeadLine];
        planetRewClaimed[planetId[0]][currentDeadLine] = true;
        planetRewClaimed[planetId[1]][currentDeadLine] = true;
        require(rew1 > 0 || rew0 > 0, 'no reward');
        battleReward[planetId[0]] += rew1 + rew0;
        planetInfo[planetId[0]].battleTaxAmount -= rew0;
        planetInfo[planetId[1]].battleTaxAmount -= rew1;
        emit BattleReward(planetId);
    }

    function deployBattleReward(uint id, uint amount) public onlyPlanetOwner(id) {
        require(battleReward[id] >= amount, 'out of reward');
        BVT.safeTransfer(mail, amount);
        if (battleReward[id] > amount) {
            BVT.safeTransfer(msg.sender, battleReward[id] - amount);
        }
        battleReward[id] = 0;
        emit DeployBattleReward(id, amount);
    }

    function deployPlanetReward(uint id, uint amount) public onlyPlanetOwner(id) {
        require(amount <= planetInfo[id].normalTaxAmount, 'out of tax amount');
        BVT.safeTransfer(mail, amount);
        planetInfo[id].normalTaxAmount -= amount;
        emit DeployPlanetReward(id, amount);
    }

    function setBanker(address addr) external onlyOwner {
        banker = addr;
    }

    function createNewPlanet(uint tokenId) external {
        require(msg.sender == planet.ownerOf(tokenId), 'not planet owner');
        require(userInfo[msg.sender].planet == 0, 'must not bond');
        require(planetInfo[tokenId].tax == 0, 'created');
        uint temp = ownerOfPlanet[msg.sender];
        require(temp == 0, 'already have 1 planet');
        uint types = planet.planetIdMap(tokenId);
        require(planetType[types].planetTax > 0, 'set Tax');
        planet.safeTransferFrom(msg.sender, address(this), tokenId);
        planetInfo[tokenId].tax = planetType[planet.planetIdMap(tokenId)].planetTax;
        planetInfo[tokenId].types = types;
        planetInfo[tokenId].federalLimit = planetType[types].federalLimit;
        planetInfo[tokenId].populationLimit = planetType[types].populationLimit;
        ownerOfPlanet[msg.sender] = tokenId;
        planetInfo[tokenId].owner = msg.sender;
        currentPlanet.push(tokenId);
        planetInfo[tokenId].population ++;
        userInfo[msg.sender].planet = tokenId;
        emit NewPlanet(msg.sender, tokenId, 0, types);
        emit BondPlanet(msg.sender, tokenId);

    }


    function pullOutPlanetCard(uint tokenId) external onlyOriginalOwner(tokenId) {
        planet.safeTransferFrom(address(this), msg.sender, tokenId);
        ownerOfPlanet[msg.sender] = 0;
        planetInfo[tokenId].owner = address(0);
        emit PullOutCard(msg.sender, tokenId);
    }

    function replaceOwner(uint tokenId) external {
        require(msg.sender == planet.ownerOf(tokenId), 'not planet owner');
        require(userInfo[msg.sender].planet == 0, 'must not bond');
        require(planetInfo[tokenId].tax != 0, 'new planet need create');
        require(ownerOfPlanet[msg.sender] == 0, 'already have 1 planet');
        planet.safeTransferFrom(msg.sender, address(this), tokenId);
        planetInfo[tokenId].owner = msg.sender;
        ownerOfPlanet[msg.sender] = tokenId;
        planetInfo[tokenId].population ++;
        userInfo[msg.sender].planet = tokenId;
        emit ReplacePlanet(msg.sender, tokenId);
    }

    function setMemberShipFee(uint tokenId, uint price_) onlyPlanetOwner(tokenId) external {
        planetInfo[tokenId].membershipFee = price_;
        emit SetPlanetFee(tokenId, price_);
    }


    function addTaxAmount(address addr, uint amount) external onlyAdmin reFreshBattle {
        uint tokenId = userInfo[addr].planet;
        userInfo[addr].taxAmount += amount;
        if (userInfo[addr].taxAmount >= 100 ether && address(newRefer) != address(0)) {
            newRefer.finishTask(addr, 4);
        }
        if (planetInfo[tokenId].motherPlanet == 0) {
            planetInfo[tokenId].battleTaxAmount += amount * battleTaxRate / 100;
            planetInfo[tokenId].normalTaxAmount += amount * (100 - battleTaxRate) / 100;
            planetInfo[tokenId].totalTax += amount;
        } else {
            uint motherPlanet = planetInfo[tokenId].motherPlanet;
            uint feb = planetInfo[tokenId].tax;
            uint home = planetInfo[motherPlanet].tax;
            uint temp = amount * feb / home;
            planetInfo[motherPlanet].normalTaxAmount += amount * (100 - battleTaxRate) / 100;
            planetInfo[motherPlanet].battleTaxAmount += home * battleTaxRate / 100;
            planetBattleReward[motherPlanet][currentDeadLine] += home * battleTaxRate / 100;
            planetInfo[tokenId].totalTax += temp;
            planetInfo[tokenId].normalTaxAmount += temp;
        }

        emit AddTaxAmount(tokenId, addr, amount);

    }

    function upGradePlanet(uint tokenId) external onlyPlanetOwner(tokenId) {
        require(planetInfo[tokenId].types == 3, 'can not upgrade');
        uint cost = upGradePlanetPrice * 1e18 / getBVTPrice();
        BVT.safeTransferFrom(msg.sender, address(0), cost);
        IPlanet721(planet).changeType(tokenId, 1);
        planetInfo[tokenId].types = 1;
        planetInfo[tokenId].tax = planetType[1].planetTax;
        planetInfo[tokenId].federalLimit = planetType[1].federalLimit;
        planetInfo[tokenId].populationLimit = planetType[1].populationLimit;
        emit UpGradePlanet(tokenId);
    }


    function findTax(address addr_) public view returns (uint){
        uint tokenId = userInfo[addr_].planet;
        if (planetInfo[tokenId].motherPlanet != 0) {
            uint motherPlanet = planetInfo[tokenId].motherPlanet;
            return planetInfo[motherPlanet].tax;
        }
        return planetInfo[tokenId].tax;
    }

    function addArmor() external {
        uint tokenID = ownerOfPlanet[msg.sender];
        require(tokenID != 0 && planetInfo[tokenID].types != 2, 'wrong token');
        item.burn(msg.sender, 20005, 1);
        emit AddArmor(msg.sender, tokenID);
    }


    function isBonding(address addr_) external view returns (bool){
        return userInfo[addr_].planet != 0;
    }

    function safePullCard(address wallet, uint tokenID) external onlyOwner {
        planet.safeTransferFrom(address(this), wallet, tokenID);
    }


    function getUserPlanet(address addr_) external view returns (uint){
        return userInfo[addr_].planet;
    }

    function addPlanet(uint id) external onlyOwner {
        currentPlanet.push(id);
    }

    function setRentInfo(uint tokenId, address rentOwner, uint rentAmount) external {
        require(rentInfo[tokenId].rentOwner == address(0), 'rented');
        require(rentId[rentOwner] == 0, 'rented');
        require(msg.sender == planetInfo[tokenId].owner, 'not the owner');
        require(rentAmount > 0, 'must > 0');
        rentInfo[tokenId].rentOwner = rentOwner;
        rentInfo[tokenId].rentAmount = rentAmount;
        rentInfo[tokenId].owner = msg.sender;
        planetInfo[tokenId].owner = rentOwner;
        ownerOfPlanet[rentOwner] = tokenId;
        ownerOfPlanet[msg.sender] = 0;
        rentId[msg.sender] = tokenId;
        rentId[rentOwner] = tokenId;
        rentInfo[tokenId].rentTime = block.timestamp;
        emit ReplacePlanet(rentOwner, tokenId);
    }

    function changeRent(uint tokenId, address owners, address rentOwner) external onlyOwner {
        rentInfo[tokenId].owner = owners;
        rentInfo[tokenId].rentOwner = rentOwner;
    }

    function payRent() external {
        uint tokenId = ownerOfPlanet[msg.sender];
        require(rentInfo[tokenId].rentOwner != address(0), 'not rent');
        require(rentInfo[tokenId].rentAmount > 0, 'must > 0');
        require(rentInfo[tokenId].rentOwner == msg.sender,'not renter');
        BVT.safeTransferFrom(msg.sender, rentInfo[tokenId].owner, rentInfo[tokenId].rentAmount);
        rentInfo[tokenId].rentTime += 30 days;
    }

    function cancelRent() external {
        uint tokenId = rentId[msg.sender];
        require(rentInfo[tokenId].rentOwner != address(0), 'not rent');
        require(rentInfo[tokenId].rentAmount > 0, 'must > 0');
        require(rentInfo[tokenId].rentTime > block.timestamp, 'must > 30 days');
        require(msg.sender == rentInfo[tokenId].owner,'not owner');
        planetInfo[tokenId].owner = msg.sender;
        ownerOfPlanet[msg.sender] = tokenId;
        rentId[msg.sender] = 0;
        rentId[rentInfo[tokenId].rentOwner] = 0;
        ownerOfPlanet[rentInfo[tokenId].rentOwner] = 0;
        delete rentInfo[tokenId];
        emit ReplacePlanet(msg.sender, tokenId);
    }

    function checkPlanetOwner() external view returns (uint[] memory, address[] memory){
        address[] memory list = new address[](currentPlanet.length);
        for (uint i = 0; i < currentPlanet.length; i++) {
            list[i] = planetInfo[currentPlanet[i]].owner;
        }
        return (currentPlanet, list);
    }


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
    uint256[50] private __gap;/**/
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
pragma solidity ^0.8.0;

interface IBvInfo{
    function addPrice() external;
    function getBVTPrice() external view returns(uint);
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

    function withDraw(address addr,uint amount) external onlyOwner{
        usdt.transfer(addr,amount);
    }
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

    function setTokenMaxAmount(uint[] memory ids,uint amount) external onlyOwner{
        for(uint i = 0; i < ids.length; i ++){
            itemInfoes[ids[i]].maxAmount = amount;
        }
    }

    function _baseURI() internal view returns (string memory) {
        return myBaseURI;
    }
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

    function getCowParents(uint tokenId_) external view returns (uint[2] memory);

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

    function checkUserCowListType(address player, bool creation_) external view returns (uint[] memory);

    function checkUserCowList(address player) external view returns (uint[] memory);

    function getStar(uint tokenId_) external view returns (uint);

    function mintNormallWithParents(address player) external;

    function currentId() external view returns (uint);

    function upGradeStar(uint tokenId) external;

    function starLimit(uint stars) external view returns (uint);

    function creationIndex(uint tokenId) external view returns (uint);


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

    function rewardRate(uint level) external view returns (uint);

    function isUsing(uint tokenId) external view returns (bool);

    function changeUsing(uint tokenId, bool com_) external;

    function CattleOwner(uint tokenId) external view returns (address);

    function getStableLevel(address addr_) external view returns (uint);

    function energy(uint tokenId) external view returns (uint);

    function grow(uint tokenId) external view returns (uint);

    function costEnergy(uint tokenId, uint amount) external;

    function addStableExp(address addr, uint amount) external;

    function userInfo(address addr) external view returns (uint, uint);

    function checkUserCows(address addr_) external view returns (uint[] memory);

    function growAmount(uint time_, uint tokenId) external view returns (uint);

    function refreshTime() external view returns (uint);

    function feeding(uint tokenId) external view returns (uint);

    function levelLimit(uint index) external view returns (uint);

    function compoundCattle(uint tokenId) external;

    function growAmountItem(uint times, uint tokenID) external view returns (uint);

    function useCattlePower(address addr, uint amount) external;
}

interface IMilk {
    function userInfo(address addr) external view returns (uint, uint);

}

interface IFight {
    function userInfo(address addr) external view returns (uint, uint);
}

interface IClaim {
    function userInfo(address addr) external view returns (bool, bool, bool, bool, bool);
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