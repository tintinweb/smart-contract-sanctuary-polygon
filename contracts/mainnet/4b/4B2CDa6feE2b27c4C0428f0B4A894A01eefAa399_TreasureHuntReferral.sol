// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ITreasureHunt.sol";

contract TreasureHuntReferral is Ownable {
    mapping(address => string) public referralCode;
    mapping(string => address) public ownerOfCode;
    mapping(address => bool) public referral;
    mapping(address => bool) public referResult;
    uint256 public referReward;
    address public rewardPool;
    
    event ReferCode(address player, address codeOwner);

    modifier onlyRewardPool() {
        require(msg.sender == rewardPool, "You are not rewardpool!");
        _;
    }
    constructor(address _rewardPool) {
        rewardPool = _rewardPool;
        referReward = 5;
    }

    function registerCode(string memory code) public {
        require(isNewCode(code), "Already Exist!");
        if(bytes(referralCode[msg.sender]).length > 0) {
            delete ownerOfCode[referralCode[msg.sender]];
            delete referralCode[msg.sender];
        }
        ownerOfCode[code] = msg.sender;
        referralCode[msg.sender] = code;
    }

    function isNewCode(string memory code) public view returns(bool) {
        return ownerOfCode[code] == address(0); 
    }

    function readCode(address user) public view returns(string memory) {
        return referralCode[user];
    }

    function setReferral(address player, bool isReferral) public onlyRewardPool{
        referral[player] = isReferral;
    }

    function setReferReward(uint256 reward) public onlyOwner {
        referReward = reward;
    } 

    function checkCode(string memory code) public {
        require(referral[msg.sender], "You can't refer code!");
        address codeOwner = ownerOfCode[code];
        require(msg.sender != codeOwner, "Can't refer your code!");
        if (ownerOfCode[code] != address(0)) {
            referResult[msg.sender] = true; 
            ITreasureHunt(rewardPool).referralReward(codeOwner, referReward);
            emit ReferCode(msg.sender, ownerOfCode[code]);
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
    function referralReward(address, uint256) external;
    //seaport
    function isOnSeaport(address) external view returns(bool);
    function isSeaportOwner(address) external view returns(bool);
    function getSeaportOwnerByPlayer(address) external view returns(address);
    function transferSeaport(uint256) external;
    function owner() external view returns(address);
    //referral
    function setReferral(address, bool) external;
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