// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ITreasureHunt.sol";
import "./ITreasureHuntTrait.sol";

contract TreasureHuntMarketPlace is Initializable, ITreasureHuntTrait, OwnableUpgradeable {

    Goods[] pirateStore;
    Goods[] shipStore;
    Goods[] fleetStore;
    Goods[] seaportStore;

    mapping(uint256 => uint256) pirateIndex;
    mapping(uint256 => uint256) shipIndex;
    mapping(uint256 => uint256) fleetIndex;
    mapping(uint256 => uint256) seaportIndex;

    mapping(address => uint256) piratesNum;
    mapping(address => uint256) shipsNum;
    mapping(address => uint256) fleetsNum;
    mapping(address => uint256) seaportsNum;

    address public treasureHuntPirate;
    address public treasureHuntShip;
    address public treasureHuntFleet;
    address public treasureHuntSeaport;
    address public treasureHuntRewardPool;

    event PirateSold(address acc, uint256 tokenID);
    event ShipSold(address acc, uint256 tokenID);
    event FleetSold(address acc, uint256 tokenID);
    event SeaportSold(address acc, uint256 tokenID);

    event PirateSell(address acc, uint256 tokenID);
    event ShipSell(address acc, uint256 tokenID);
    event FleetSell(address acc, uint256 tokenID);
    event SeaportSell(address acc, uint256 tokenID);

    event PirateCanceled(address acc, uint256 tokenID);
    event ShipCanceled(address acc, uint256 tokenID);
    event FleetCanceled(address acc, uint256 tokenID);
    event SeaportCanceled(address acc, uint256 tokenID);

    function initialize(address _treasureHuntPirate, address _treasureHuntShip, address _treasureHuntFleet, address _treasureHuntSeaport, address _treasureHuntRewardPool) public initializer {
        __Ownable_init();
        treasureHuntPirate = _treasureHuntPirate;
        treasureHuntShip = _treasureHuntShip;
        treasureHuntFleet = _treasureHuntFleet;
        treasureHuntSeaport = _treasureHuntSeaport;
        treasureHuntRewardPool = _treasureHuntRewardPool;
    }

    function setTreasureHuntPirate(address _treasureHuntPirate) public onlyOwner {
        treasureHuntPirate = _treasureHuntPirate;
    }

    function setTreasureHuntShip(address _treasureHuntShip) public onlyOwner {
        treasureHuntShip = _treasureHuntShip;
    }

    function setTreasureHuntFleet(address _treasureHuntFleet) public onlyOwner {
        treasureHuntFleet = _treasureHuntFleet;
    }
    
    function setTreasureHuntSeaport(address _treasureHuntSeaport) public onlyOwner {
        treasureHuntSeaport = _treasureHuntSeaport;
    }

    function setTreasureHuntRewardPool(address _treasureHuntRewardPool) public onlyOwner {
        treasureHuntRewardPool = _treasureHuntRewardPool;
    }

    function getPiratesByOwner() public view returns(Goods[] memory) {
        Goods[] memory pirates = new Goods[](piratesNum[msg.sender]);
        uint256 count;
        for(uint i; i < pirateStore.length; i++) {
            if(pirateStore[i].Owner == msg.sender) {
                pirates[count++] = pirateStore[i];
            }
        } 
        return pirates;
    }

    function getPiratesOnStore() public view returns(Goods[] memory) {
        return pirateStore;
    }

    function sellPirate(uint256 tokenID, uint256 price) public {
        ITreasureHunt(treasureHuntPirate).transferPirate(tokenID);
        Goods memory pirate = Goods(tokenID, msg.sender, price);
        pirateStore.push(pirate);
        piratesNum[msg.sender] ++;
        pirateIndex[tokenID] = pirateStore.length - 1;
        emit PirateSell(msg.sender, tokenID);
    }

    function cancelPirate(uint256 tokenID) public {
        require(pirateStore[pirateIndex[tokenID]].Owner == msg.sender, "You are not the owner of this token!");
        Goods memory pirate =  pirateStore[pirateIndex[tokenID]];
        uint256 price = pirate.Price;
        ITreasureHunt(treasureHuntRewardPool).cancelNFT(price);
        ITreasureHunt(treasureHuntPirate).transferFrom(address(this), msg.sender, tokenID);

        pirateIndex[pirateStore[pirateStore.length - 1].TokenID] = pirateIndex[tokenID];
        pirateStore[pirateIndex[tokenID]] = pirateStore[pirateStore.length - 1];
        pirateStore.pop();

        piratesNum[msg.sender] --;

        delete pirateIndex[tokenID];
        emit PirateCanceled(msg.sender, tokenID);
    }

    function buyPirate(uint256 tokenID, address tokenOwner) public {
        require(pirateStore[pirateIndex[tokenID]].TokenID == tokenID, "Can't find that token!");
        Goods memory pirate =  pirateStore[pirateIndex[tokenID]];
        uint256 price = pirate.Price;
        ITreasureHunt(treasureHuntRewardPool).buyNFT(price, tokenOwner);
        ITreasureHunt(treasureHuntPirate).transferFrom(address(this), msg.sender, tokenID);

        pirateIndex[pirateStore[pirateStore.length - 1].TokenID] = pirateIndex[tokenID];
        pirateStore[pirateIndex[tokenID]] = pirateStore[pirateStore.length - 1];
        pirateStore.pop();

        piratesNum[tokenOwner] --;
        delete pirateIndex[tokenID];

        emit PirateSold(tokenOwner, tokenID);
    }

    function getShipsByOwner() public view returns(Goods[] memory) {
        Goods[] memory ships = new Goods[](shipsNum[msg.sender]);
        uint256 count;
        for(uint i; i < shipStore.length; i++) {
            if(shipStore[i].Owner == msg.sender) {
                ships[count++] = shipStore[i];
            }
        } 
        return ships;
    }

    function getShipsOnStore() public view returns(Goods[] memory) {
        return shipStore;
    }

    function sellShip(uint256 tokenID, uint256 price) public {
        ITreasureHunt(treasureHuntShip).transferShip(tokenID);
        Goods memory ship = Goods(tokenID, msg.sender, price);
        shipStore.push(ship);
        shipIndex[tokenID] = shipStore.length - 1;
        shipsNum[msg.sender]++;
        emit ShipSell(msg.sender, tokenID);
    }

    function cancelShip(uint256 tokenID) public {
        require(shipStore[shipIndex[tokenID]].Owner == msg.sender, "You are not the owner of this token!");
        Goods memory ship =  shipStore[shipIndex[tokenID]];
        uint256 price = ship.Price;
        ITreasureHunt(treasureHuntRewardPool).cancelNFT(price);
        ITreasureHunt(treasureHuntShip).transferFrom(address(this), msg.sender, tokenID);

        shipIndex[shipStore[shipStore.length - 1].TokenID] = shipIndex[tokenID];
        shipStore[shipIndex[tokenID]] = shipStore[shipStore.length - 1];
        shipStore.pop();
        shipsNum[msg.sender]--;
        delete shipIndex[tokenID];
        emit ShipCanceled(msg.sender, tokenID);
    }

    function buyShip(uint256 tokenID, address tokenOwner) public {
        require(shipStore[shipIndex[tokenID]].TokenID == tokenID, "Can't find that token!");
        Goods memory ship =  shipStore[shipIndex[tokenID]];
        uint256 price = ship.Price;
        ITreasureHunt(treasureHuntRewardPool).buyNFT(price, tokenOwner);
        ITreasureHunt(treasureHuntShip).transferFrom(address(this), msg.sender, tokenID);

        shipIndex[shipStore[shipStore.length - 1].TokenID] = shipIndex[tokenID];
        shipStore[shipIndex[tokenID]] = shipStore[shipStore.length - 1];
        shipStore.pop();
        shipsNum[tokenOwner]--;
        delete shipIndex[tokenID];
        emit ShipSold(tokenOwner, tokenID);
    }

    function getFleetsByOwner() public view returns(Goods[] memory) {
        Goods[] memory fleets = new Goods[](fleetsNum[msg.sender]);
        uint256 count;
        for(uint i; i < fleetStore.length; i++) {
            if(fleetStore[i].Owner == msg.sender) {
                fleets[count++] = fleetStore[i];
            }
        } 
        return fleets;
    }

    function getFleetsOnStore() public view returns(Goods[] memory) {
        return fleetStore;
    }

    function sellFleet(uint256 tokenID, uint256 price) public {
        ITreasureHunt(treasureHuntFleet).transferFleet(tokenID);
        Goods memory fleet = Goods(tokenID, msg.sender, price);
        fleetStore.push(fleet);
        fleetIndex[tokenID] = fleetStore.length - 1;
        fleetsNum[msg.sender] ++;
        emit FleetSell(msg.sender, tokenID);
    }

    function cancelFleet(uint256 tokenID) public {
        require(fleetStore[fleetIndex[tokenID]].Owner == msg.sender, "You are not the owner of this token!");
        Goods memory fleet =  fleetStore[fleetIndex[tokenID]];
        uint256 price = fleet.Price;
        ITreasureHunt(treasureHuntRewardPool).cancelNFT(price);
        ITreasureHunt(treasureHuntFleet).transferFrom(address(this), msg.sender, tokenID);

        fleetIndex[fleetStore[fleetStore.length - 1].TokenID] = fleetIndex[tokenID];
        fleetStore[fleetIndex[tokenID]] = fleetStore[fleetStore.length - 1];
        fleetStore.pop();

        fleetsNum[msg.sender] --;
        delete fleetIndex[tokenID];
        emit FleetCanceled(msg.sender, tokenID);
    }

    function buyFleet(uint256 tokenID, address tokenOwner) public {
        require(fleetStore[fleetIndex[tokenID]].TokenID == tokenID, "Can't find that token!");
        Goods memory fleet =  fleetStore[fleetIndex[tokenID]];
        uint256 price = fleet.Price;
        ITreasureHunt(treasureHuntRewardPool).buyNFT(price, tokenOwner);
        ITreasureHunt(treasureHuntFleet).transferFrom(address(this), msg.sender, tokenID);

        fleetIndex[fleetStore[fleetStore.length - 1].TokenID] = fleetIndex[tokenID];
        fleetStore[fleetIndex[tokenID]] = fleetStore[fleetStore.length - 1];
        fleetStore.pop();

        fleetsNum[tokenOwner] --;
        delete fleetIndex[tokenID];
        emit FleetSold(tokenOwner, tokenID);
    }

    function getSeaportsByOwner() public view returns(Goods[] memory) {
        Goods[] memory seaports = new Goods[](seaportsNum[msg.sender]);
        uint256 count;
        for(uint i; i < seaportStore.length; i++) {
            if(seaportStore[i].Owner == msg.sender) {
                seaports[count++] = seaportStore[i];
            }
        } 
        return seaports;
    }

    function getSeaportsOnStore() public view returns(Goods[] memory) {
        return seaportStore;
    }

    function sellSeaport(uint256 tokenID, uint256 price) public {
        ITreasureHunt(treasureHuntSeaport).transferSeaport(tokenID);
        Goods memory seaport = Goods(tokenID, msg.sender, price);
        seaportStore.push(seaport);
        seaportIndex[tokenID] = seaportStore.length - 1;
        seaportsNum[msg.sender]++;
        emit SeaportSell(msg.sender, tokenID);
    }

    function cancelSeaport(uint256 tokenID) public {
        require(seaportStore[seaportIndex[tokenID]].Owner == msg.sender, "You are not the owner of this token!");
        Goods memory seaport =  seaportStore[seaportIndex[tokenID]];
        uint256 price = seaport.Price;
        ITreasureHunt(treasureHuntRewardPool).cancelNFT(price);
        ITreasureHunt(treasureHuntSeaport).transferFrom(address(this), msg.sender, tokenID);

        seaportIndex[seaportStore[seaportStore.length - 1].TokenID] = seaportIndex[tokenID];
        seaportStore[seaportIndex[tokenID]] = seaportStore[seaportStore.length - 1];
        seaportStore.pop();

        seaportsNum[msg.sender]--;

        delete seaportIndex[tokenID];
        emit SeaportCanceled(msg.sender, tokenID);
    }

    function buySeaport(uint256 tokenID, address tokenOwner) public {
        require(seaportStore[seaportIndex[tokenID]].TokenID == tokenID, "Can't find that token!");
        require(seaportsNum[msg.sender] == 0, "You can't buy seaport before current one sold!");
        Goods memory seaport =  seaportStore[seaportIndex[tokenID]];
        uint256 price = seaport.Price;
        address admin = ITreasureHunt(treasureHuntSeaport).owner();
        if (admin == tokenOwner) {
            ITreasureHunt(treasureHuntRewardPool).buySeaportFromAdmin(price);
        } else {
            ITreasureHunt(treasureHuntRewardPool).buyNFT(price, tokenOwner);
        }
        ITreasureHunt(treasureHuntSeaport).transferFrom(address(this), msg.sender, tokenID);

        seaportIndex[seaportStore[seaportStore.length - 1].TokenID] = seaportIndex[tokenID];
        seaportStore[seaportIndex[tokenID]] = seaportStore[seaportStore.length - 1];
        seaportStore.pop();
        seaportsNum[tokenOwner]--;

        ITreasureHunt(treasureHuntRewardPool).resetTotalEarning(tokenOwner);

        delete seaportIndex[tokenID];
        emit SeaportSold(tokenOwner, tokenID);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./ITreasureHuntTrait.sol";

interface ITreasureHunt is ITreasureHuntTrait {
    function transferFrom(address, address, uint256) external;
    function setSeaport(uint256, uint8, uint16) external;
    //picker
    function randomPirate(uint256, string memory) external returns(bool);
    function randomShip(uint256, string memory) external returns(bool);
    function random(string memory, uint256) external view returns(uint256);
    //pirate
    function boardPirates(uint256[] memory) external;
    function getPirate(uint256) external view returns(Pirate memory);
    function setPirate(uint256, uint8, uint16, string memory) external;
    function unBoardPirates(uint256[] memory) external;
    function transferPirate(uint256) external;
    //ship
    function disJoinShips(uint256[] memory) external;
    function getShip(uint256) external view returns(Ship memory);
    function getShips(uint256[] memory) external view returns(Ship[] memory);
    function joinShips(uint256[] memory) external;
    function setShip(uint256, uint8, string memory) external;
    function transferShip(uint256) external;
    //fleet
    function getFleetNumByOwner(address) external view returns(uint256);
    function getFleetInfo(uint256) external view returns(Fleet memory);
    function updateFleetFund(uint256, uint256, uint256, bool) external;
    function setFleetRaidTime(uint256) external;
    function getTotalHakiByOwner(address) external view returns(uint256);
    function getMaxHakiByOwner(address) external view returns(uint256);
    function setFleetDurability(uint256, bool) external;
    function canRaid(uint256) external view returns(bool);
    function transferFleet(uint256) external;
    //reward pool contract
    function transferBurnReward(address, uint256) external;
    function reward2Player(address, uint256) external;
    function payUsingReward(address, uint256) external;
    function transferCost(uint256) external;
    function updateExperience(address, uint256) external;
    function getDecimal() external view returns(uint8);
    function getRepairCost(uint256) external view returns(uint256);
    function buyNFT(uint256, address) external;
    function cancelNFT(uint256) external;
    function resetTotalEarning(address) external;
    function resetEarningOnSeaport() external;
    function buySeaportFromAdmin(uint256) external;
    //seaport
    function isOnSeaport(address) external view returns(bool);
    function isSeaportOwner(address) external view returns(bool);
    function getSeaportOwnerByPlayer(address) external view returns(address);
    function transferSeaport(uint256) external;
    function owner() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


interface ITreasureHuntTrait {
    struct Pirate {
        string Name;
        uint256 TokenID;
        uint8 Star;
        uint256 HakiPower;
    }

    struct Ship {
        string Name;
        uint256 TokenID;
        uint8 Star;
    }

    struct Seaport {
        string Name;
        uint256 TokenID;
        uint8 Level;
        uint16 Current;
    }

    struct Fleet {
        uint256 TokenID;
        string Name;
        uint256 Energy;
        uint8 Rank;
        uint8 Contract;
        uint256 Fuel;
        bool Durability;
        uint256 RaidClock;
        uint8 LifeCycle;
        uint256 Power;
        uint256[] ships;
        uint256[] pirates; 
    }

    struct Goods {
        uint256 TokenID;
        address Owner;
        uint256 Price;
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