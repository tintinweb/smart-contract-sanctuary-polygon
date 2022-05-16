// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITreasureHunt.sol";

contract TreasureHuntRewardPool is Initializable, OwnableUpgradeable {
    
    uint256 devAmt;
    address devWallet;
    address devWallet1;

    mapping(address => uint256) lastRaidTime;
    mapping(address => uint256) reward;
    mapping(uint256 => uint256) repairCost;
    mapping(uint256 => uint8) fleetRaidNum;

    mapping(address => bool) isReleaser;

    uint8 public islandNum;
    mapping(uint8 => uint256) islandsReward;
    mapping(uint8 => mapping(uint8 => uint8)) winPercentage;
    mapping(address => bool) playerDoubleWin;
    mapping(address => bool) playerRaidState;
    mapping(address => uint8) playerWinIsland;

    mapping(address => uint8) playerLevel;
    mapping(address => uint256) playerExp;
    mapping(uint8 => uint32) levelExp;
    mapping(uint8 => uint8) bonus;

    mapping(address => uint256) timeToWithdraw;
    uint256 public withdrawInterval;

    uint8 public fuelPercent;
    uint8 public energyPercent;
    uint8 public repairPercent;

    uint8 public mintRPercentForDev;
    uint8 public fundRPercentForDev;

    uint8 public dailyPercentForSeaport;
    uint8 public dailyPercentForRewardPool;

    uint8 public seaportClaimFee;
    uint8 public playerClaimPoolFee;
    uint8 public playerClaimDevFee;

    address public treasureHuntFleet;
    address public treasureHuntPicker;
    address public tokenUSDT;

    uint256 public lockTime;

    uint8 public decimal;

    bool public seaportActivate;
    uint256 public passiveIncomeThreshold;

    uint16 public islandHakiUnit;

    modifier onlyReleaser(address acc) {
        require(isReleaser[acc], "You are not a releaser!");
        _;
    }

    modifier onlyFleet(address acc) {
        require(acc == treasureHuntFleet, "You are not Fleet!");
        _;
    }

    modifier onlyWinner(address acc) {
        require(playerRaidState[acc], "You are not winner!");
        _;
    }

    modifier enoughFund(uint256 tokenID, uint8 islandNumber) {
        require(ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).Fuel >= islandsReward[islandNumber] * fuelPercent / 100, "You don't have enough fuel!");
        require(ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).Energy >= islandsReward[islandNumber] * energyPercent / 100, "You don't have enough energy!");
        require(ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).LifeCycle > 0, "Can't use this fleet anymore!");
        require(ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).Contract > 0, "You have no Contract!");
        require(ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).Power > islandHakiUnit * islandNumber, "You don't have enough haki power!");
        _;
    }

    modifier onSeaport(address player) {
        require(ITreasureHunt(treasureHuntFleet).isOnSeaport(player), "You are not on seaport!");
        _;
    }

    function initialize(address _treasureHuntFleet, address _treasureHuntPicker) public initializer {
        __Ownable_init();
        islandNum = 50;
        treasureHuntPicker = _treasureHuntPicker;
        treasureHuntFleet = _treasureHuntFleet;
        // decimal = 6; //mainnet
        decimal = 18; //testnet
        
        fuelPercent = 15;
        energyPercent = 15;
        repairPercent = 20;

        mintRPercentForDev = 80;
        fundRPercentForDev = 20;

        dailyPercentForSeaport = 2;
        dailyPercentForRewardPool = 1;

        seaportClaimFee= 8;
        playerClaimPoolFee= 5;
        playerClaimDevFee= 2;

        withdrawInterval = 7 days;

        levelExp[1] = 10000;
        levelExp[2] = 30000;
        levelExp[3] = 50000;
        levelExp[4] = 75000;
        levelExp[5] = 100000;

        bonus[0] = 0;
        bonus[1] = 10;
        bonus[2] = 15;
        bonus[3] = 20;
        bonus[4] = 25;
        bonus[5] = 30;

        // tokenUSDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;  //mainnet
        tokenUSDT = 0xe11A86849d99F524cAC3E7A0Ec1241828e332C62; //testnet
        
        seaportActivate = false;
        passiveIncomeThreshold = 10000;
        islandHakiUnit = 100;

        devWallet = 0x8E87655fa89f791c89e2c949333A35593DB6c610;
        devWallet1 = 0x7A419820688f895973825D3cCE2f836e78Be1eF4;

        lockTime = block.timestamp + 5 * 365 days;
    }

    function initlevelExp(uint32[] memory exps) public onlyOwner {
        require(exps.length == 5, "Incorrect length!");
        for(uint8 i; i < exps.length; i++) {
            levelExp[i + 1] = exps[i];
        }
    }

    function initBonus(uint8[] memory bonuses) public onlyOwner {
        require(bonuses.length == 5, "Incorrect length!");
        for(uint8 i; i < bonuses.length; i++) {
            bonus[i + 1] = bonuses[i];
        }
    }

    //raid island logic
    function initWinPercentage(
        uint8[] memory percentD
        , uint8[] memory percentC
        , uint8[] memory percentB
        , uint8[] memory percentA
        , uint8[] memory percentS
    ) public onlyOwner{
        require(percentD.length == islandNum, "Enter correct D number!");
        require(percentC.length == islandNum, "Enter correct C number!");
        require(percentB.length == islandNum, "Enter correct B number!");
        require(percentA.length == islandNum, "Enter correct A number!");
        require(percentS.length == islandNum, "Enter correct S number!");
        
        for (uint8 i; i < islandNum; i++) {
            winPercentage[i][1] = percentD[i];
            winPercentage[i][2] = percentC[i];
            winPercentage[i][3] = percentB[i];
            winPercentage[i][4] = percentA[i];
            winPercentage[i][5] = percentS[i];
        }
    }

    function initIslandRewards(uint16[] memory rewards) public onlyOwner {
        require(rewards.length == islandNum, "Enter correct number!");
        for(uint8 i; i < islandNum; i++) {
            islandsReward[i] = rewards[i] * (10 ** decimal);
        }
    }

    function getDecimal() public view returns(uint8) {
        return decimal;
    }

    function setFeePercents(uint8 fuelP, uint8 energyP, uint8 repairP) public onlyOwner {
        require(fuelP + energyP + repairP < 100, "Invalid value!");
        fuelPercent = fuelP;
        energyPercent = energyP;
        repairPercent = repairP;
    }

    function raidIsland(uint256 tokenID, uint8 islandNumber) public enoughFund(tokenID, islandNumber) onSeaport(msg.sender) {
        uint256 raidTime = ITreasureHunt(treasureHuntFleet).getFleetRaidTime(tokenID);
        require( raidTime == 0 || block.timestamp >= raidTime , "You have to wait to raid!");
        ITreasureHunt(treasureHuntFleet).setFleetRaidTime(tokenID);

        uint256 random = ITreasureHunt(treasureHuntPicker).random(string(abi.encodePacked(tokenID)), islandNumber);

        uint8 rank = ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).Rank;
        uint8 percentage = winPercentage[islandNumber][rank];

        uint8 chance = uint8(random % 100);

        uint256 fuel = islandsReward[islandNumber] * fuelPercent / 100;
        uint256 energy = islandsReward[islandNumber] * fuelPercent / 100;
        if(chance < percentage) {
            playerRaidState[msg.sender] = true;
            playerWinIsland[msg.sender] = islandNumber;

            ITreasureHunt(treasureHuntFleet).updateFleetFund(tokenID, fuel, energy, true);
        } else {
            playerRaidState[msg.sender] = false;
            ITreasureHunt(treasureHuntFleet).updateFleetFund(tokenID, fuel, energy, false);
        }

        repairCost[tokenID] += islandsReward[islandNumber] * repairPercent / 100;
        fleetRaidNum[tokenID] ++;

        lastRaidTime[msg.sender] = block.timestamp;
    }

    function readFleetRaidNumber(uint256 tokenID) public view returns(uint8) {
        return fleetRaidNum[tokenID];
    }

    function repairFleet(uint256 tokenID, bool isDirect) public {
        require(fleetRaidNum[tokenID] >= 5);
        if (isDirect) {
            IERC20(tokenUSDT).transferFrom(msg.sender, address(this), repairCost[tokenID] * (10 ** decimal));
        } else {
            payUsingReward(msg.sender, repairCost[tokenID]);
        }
        fleetRaidNum[tokenID] = 0;
    }

    function getFleetRaidNum(uint256 tokenID) public view returns(uint8) {
        return fleetRaidNum[tokenID];
    }

    function isWin(address acc) public view returns(bool) {
        return playerRaidState[acc];
    }

    function normalReward(address acc) public onlyWinner(acc){
        uint256 nReward = islandsReward[playerWinIsland[acc]] * (100 + bonus[playerLevel[acc]]) / 100; 
        nReward = nReward * (10 ** decimal);
        reward[acc] += nReward;
        updateRaidReward(acc, nReward);
    }

    function doubleReward(address acc) public onlyWinner(acc){
        uint256 random = ITreasureHunt(treasureHuntPicker).random(string(abi.encodePacked(block.coinbase)), block.gaslimit);
        uint8 chance = uint8(random % 100);
        if (chance < 50) {
            uint256 dReward = 2 * islandsReward[playerWinIsland[acc]] * (100 + bonus[playerLevel[acc]]) / 100; 
            dReward = dReward * (10 ** decimal);
            reward[acc] += dReward;
            updateRaidReward(acc, dReward);
            playerDoubleWin[acc] = true;
        } else {
            playerDoubleWin[acc] = false;
        }
    }

    function seaportPassiveIncome(address acc) internal returns(bool){
        uint256 power = ITreasureHunt(treasureHuntFleet).getTotalHakiByOwner(acc);
        return power >= passiveIncomeThreshold;
    }

    function setPassiveSeaportIncomeThreshold(uint256 threshold) public onlyOwner {
        passiveIncomeThreshold = threshold;
    }

    function isDoubleWin(address acc) public view returns(bool) {
        return playerDoubleWin[acc];
    }

    function getReward(address acc) public view returns(uint256) {
        return reward[acc];
    }

    function addReleaser(address acc) public onlyOwner {
        isReleaser[acc] = true;
    }

    function removeReleaser(address acc) public onlyOwner {
        isReleaser[acc] = false;
    }

    function payUsingReward(address acc, uint256 amt) public onlyReleaser(msg.sender){
        uint256 realAmt = amt * (10 ** decimal);
        require(tx.origin == acc, "You are not owner of this fund!");
        require(reward[acc] >= realAmt, "Insufficient fund!");
        reward[acc] -= realAmt;
    }

    function transferBurnReward(address acc, uint256 amt) public onlyReleaser(acc){
        uint256 realAmt = amt * (10 ** decimal);
        IERC20(tokenUSDT).transfer(acc, realAmt);
    }

    function transferCost(uint256 amt, bool isMint) public {
        uint256 realAmt = amt * (10 ** decimal);
        require(IERC20(tokenUSDT).balanceOf(tx.origin) >= realAmt, "Insuffient USDC!");

        IERC20(tokenUSDT).transferFrom(tx.origin, address(this), realAmt);
        if (isMint) {
            devAmt += realAmt * mintRPercentForDev / 100;
        } else {
            devAmt += realAmt * fundRPercentForDev / 100;
        }
    }

    function updateExperience(address acc, uint256 exp) public onlyFleet(msg.sender) {
        playerExp[acc] += exp;
        if (playerExp[acc] >= levelExp[playerLevel[acc] + 1]) {
            playerLevel[acc] ++;
        }
    }

    function readExperience(address acc) public view returns(uint256) {
        return playerExp[acc];
    }

    function readLevel(address acc) public view returns(uint8) {
        return playerLevel[acc];
    }

    function updateRaidReward(address acc, uint256 amt) private onSeaport(acc){
        address ownerOfSeaport = ITreasureHunt(treasureHuntFleet).getSeaportOwnerByPlayer(acc);
        if (seaportActivate && seaportPassiveIncome(ownerOfSeaport)) {
            reward[ownerOfSeaport] += amt * dailyPercentForSeaport / 100;
            reward[acc] -= amt * (dailyPercentForSeaport + dailyPercentForRewardPool) / 100;
        } else {
            reward[acc] -= amt * dailyPercentForRewardPool;
        }
    }

    function setSeaportActivate(bool act) public onlyOwner {
        seaportActivate = act;
    }

    function withdrawReward() public onSeaport(msg.sender) {
        require(timeToWithdraw[msg.sender] == 0 || block.timestamp >= timeToWithdraw[msg.sender], "Can't withdraw now!");
        timeToWithdraw[msg.sender] = block.timestamp + withdrawInterval;
        if(ITreasureHunt(treasureHuntFleet).isSeaportOwner(msg.sender)) {
            uint256 fee = reward[msg.sender] * seaportClaimFee / 100;
            reward[msg.sender] -= fee;
            devAmt += fee;
        } else {
            uint256 poolFee = reward[msg.sender] * playerClaimPoolFee / 100;
            uint256 devFee = reward[msg.sender] * playerClaimDevFee / 100;
            reward[msg.sender] -= (poolFee + devFee);
            devAmt += devFee;
        }
        IERC20(tokenUSDT).transfer(msg.sender, reward[msg.sender]);
    }

    function withdrawTime() public view returns(uint256) {
        if (block.timestamp <= timeToWithdraw[msg.sender]) {
            return timeToWithdraw[msg.sender] - block.timestamp;
        } else {
            return 0;
        }
    }

    function setIslandHakiUint(uint16 unit) public onlyOwner {
        islandHakiUnit = unit;
    }

    function readHakiPower(uint8 islandNumber) public view returns(uint32) {
        return islandHakiUnit * islandNumber;
    }

    function setTreasureHuntFleet(address _treasureHuntFleet) public onlyOwner {
        treasureHuntFleet = _treasureHuntFleet;
    }

    function setTreasureHuntPicker(address _treasureHuntPicker) public onlyOwner {
        treasureHuntPicker = _treasureHuntPicker;
    }

    function releaseReward() public onlyOwner {
        require(block.timestamp >= lockTime, "You can't release reward now!");
        IERC20(tokenUSDT).transfer(owner(), IERC20(tokenUSDT).balanceOf(address(this)));
    }

    function setMRPercentForDev(uint8 percent) public onlyOwner {
        mintRPercentForDev = percent;
    }

    function setFRPercentForDev(uint8 percent) public onlyOwner {
        fundRPercentForDev = percent;
    }

    function releaseFee() public onlyOwner {
        IERC20(tokenUSDT).transfer(devWallet, devAmt * 3 / 4);
        IERC20(tokenUSDT).transfer(devWallet1, devAmt / 4);
        devAmt = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./ITreasureHuntTrait.sol";

interface ITreasureHunt is ITreasureHuntTrait {
    function transferFrom(address, address, uint256) external;
    function setSeaport(uint256, uint8, uint16) external;
    //picker
    function randomPirate(uint256, string memory) external returns(bool);
    function randomShip(uint256, string memory) external returns(bool);
    function random(string memory, uint256) external returns(uint256);
    //pirate
    function boardPirates(uint256[] memory) external;
    function getPirate(uint256) external view returns(Pirate memory);
    function getPirates(uint256[] memory) external view returns(Pirate[] memory);
    function setPirate(uint256, uint8, uint16, string memory) external;
    function unBoardPirates(uint256[] memory) external;
    //ship
    function disJoinShips(uint256[] memory) external;
    function getShip(uint256) external view returns(Ship memory);
    function getShips(uint256[] memory) external view returns(Ship[] memory);
    function joinShips(uint256[] memory) external;
    function setShip(uint256, uint8, string memory) external;
    //fleet
    function getFleetNumByOwner(address) external view returns(uint256);
    function getFleetInfo(uint256) external view returns(Fleet memory);
    function updateFleetFund(uint256, uint256, uint256, bool) external;
    function getFleetRaidTime(uint256) external view returns(uint256);
    function setFleetRaidTime(uint256) external;
    function getTotalHakiByOwner(address) external view returns(uint256);
    //reward pool contract
    function transferBurnReward(address, uint256) external;
    function reward2Player(address, uint256) external;
    function payUsingReward(address, uint256) external;
    function transferCost(uint256, bool) external;
    function updateExperience(address, uint256) external;
    function getDecimal(uint8) external view;
    //seaport
    function isOnSeaport(address) external view returns(bool);
    function isSeaportOwner(address) external view returns(bool);
    function getSeaportOwnerByPlayer(address) external view returns(address);
    //random generator
    function getRandomWord() external view returns (uint256);
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
pragma solidity 0.8.13;

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
        uint16 Capacity;
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
        uint8 LifeCycle;
        uint256 Power;
        uint256[] ships;
        uint256[] pirates; 
    }
}