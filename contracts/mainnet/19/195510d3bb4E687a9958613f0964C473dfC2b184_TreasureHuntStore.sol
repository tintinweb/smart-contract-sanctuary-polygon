// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITreasureHunt.sol";

contract TreasureHuntStore is Ownable {
    address public tokenUSDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;  //mainnet
    // address public tokenUSDT = 0xe11A86849d99F524cAC3E7A0Ec1241828e332C62; //testnet;
    uint256 public supplyAmount; 
    address public rewardPool;
    uint256 public lockTime;
    uint256 public lowLimit;
    uint8 decimal;

    constructor(address _rewardPool) {
        rewardPool = _rewardPool;
        lockTime = block.timestamp + 5 * 365 days;
        decimal = ITreasureHunt(rewardPool).getDecimal();
        supplyAmount = 1000 * (10 ** decimal);
        lowLimit = 300 * (10 ** decimal);
    }
    
    function supplyRewardPool() public onlyOwner {
        require(checkSupply(), "You can't supply now!");
        IERC20(tokenUSDT).transfer(rewardPool, supplyAmount);
    }

    function checkSupply() public view returns(bool) {
        return lowLimit >= IERC20(tokenUSDT).balanceOf(rewardPool);
    }

    function releaseFund(uint256 amount, address acc) public onlyOwner {
        require(block.timestamp >= lockTime, "This contract is locked for 5 years!");
        IERC20(tokenUSDT).transfer(acc, amount);
    }

    function setSupplyUnit(uint256 amount) public onlyOwner {
        supplyAmount = amount * ITreasureHunt(rewardPool).getDecimal();
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
pragma solidity 0.8.14;

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
    function activePirates(address) external view returns(uint256[] memory);
    //ship
    function disJoinShips(uint256[] memory) external;
    function getShip(uint256) external view returns(Ship memory);
    function getShips(uint256[] memory) external view returns(Ship[] memory);
    function joinShips(uint256[] memory) external;
    function setShip(uint256, uint8, string memory) external;
    function transferShip(uint256) external;
    function activeShips(address) external view returns(uint256[] memory);

    //fleet
    function getFleetNumByOwner(address) external view returns(uint256);
    function getFleetInfo(uint256) external view returns(Fleet memory);
    function updateFleetFund(uint256, uint256, uint256) external;
    function reduceDoubleOrNothingLifeCycle(uint256, address) external;
    function setFleetRaidTime(uint256) external;
    function getTotalHakiByOwner(address) external view returns(uint256);
    function getMaxHakiByOwner(address) external view returns(uint256);
    function setFleetDurability(uint256, bool) external;
    function canRaid(uint256) external view returns(bool);
    function transferFleet(uint256) external;
    function setRepairCost(uint256, uint256) external;
    function resetRepairCost(uint256) external;
    function balanceOf(address) external view returns(uint256);
    //reward pool contract
    function transferBurnReward(address, uint256) external;
    function reward2Player(address, uint256) external;
    function payUsingReward(address, uint256, bool) external;
    function transferCost(uint256, bool) external;
    function updateExperience(address, uint256) external;
    function getDecimal() external view returns(uint8);
    function buyNFT(uint256, address) external;
    function cancelNFT(uint256) external;
    function resetTotalEarning(address) external;
    function resetEarningOnSeaport() external;
    function buySeaportFromAdmin(uint256) external;
    function readEarningOnSeaport(address) external view returns(uint256);
    function readTotalEarningOfSeaportOwner(address) external view returns(uint256);
    //seaport
    function isOnSeaport(address) external view returns(bool);
    function isSeaportOwner(address) external view returns(bool);
    function getSeaportOwnerByPlayer(address) external view returns(address);
    function transferSeaport(uint256) external;
    function owner() external view returns(address);
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
pragma solidity 0.8.14;

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
        uint256 RepairCost;
        uint256[] ships;
        uint256[] pirates; 
    }

    struct Goods {
        uint256 TokenID;
        address Owner;
        uint256 Price;
    }

    struct Member {
        address Player;
        uint256 HakiPower;
        uint256 Earning;
        uint16 PirateAmount;
        uint16 ShipAmount;
        uint16 FleetAmount;
    }

    struct Leader {
        address Player;
        uint16 PirateAmout;
        uint16 ShipAmount;
        uint16 FleetAmount;
        uint256 HakiPower;
        uint256 Size;
        uint256 TotalEarning;
        bool IsWP;
        uint256 ThresHaki;
    }
}