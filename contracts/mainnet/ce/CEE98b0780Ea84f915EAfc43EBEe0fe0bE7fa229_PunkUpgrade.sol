// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IWofRacingContract {
    function freighPunkStats(uint256 punkID)
        external
        view
        returns (TokenStats memory);

    struct TokenStats {
        uint256 racesJoined;
        uint256 firstPlaces;
        uint256 secondPlaces;
        uint256 thirdPlaces;
        uint256 tokensWon;
    }
}

interface IWofToken {
    function balanceOf(address _address) external view returns (uint256);

    function increaseAllowance(address _to, uint256 _amount) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function transfer(address to, uint256 amount) external;

    function allowance(address owner, address spender)
        external
        returns (uint256);
}

contract PunkUpgrade is Ownable {
    IWofRacingContract public raceContract;
    IWofToken public wofToken;

    uint256 public baseXPEarned = 2;

    constructor(address _address, address _token) {
        raceContract = IWofRacingContract(_address);
        wofToken = IWofToken(_token);
    }

    struct SkillTree {
        uint256 id;
        string name;
        uint256 tier;
        string vehicle_type;
        uint256 price;
        uint256 req_level;
        uint256 wof_cost;
        uint256[] prereq;
        string description;
        Perks perks;
    }

    struct Perks {
        string branch;
        string event_tyepe;
        StatChange value;
    }

    //SEND AS WEI
    struct StatChange {
        uint256 max_speed; //SEND AS WEI
        uint256 max_range;
        uint256 max_capacity;
        uint256 fuel_efficiency;
        uint256 emission_rate;
    }

    struct XPFormula {
        uint256 place;
        uint256 amount;
    }
    //MAP SKILL TREES BY ID
    mapping(uint256 => SkillTree) public punkSkills;
    mapping(uint256 => uint256) public xpEarnedFormula;
    mapping(uint256 => uint256) public xpSpent;
    mapping(uint256 => uint256) public skillPointsSpent;

    mapping(uint256 => uint256[]) public ownedSkills;

    //TODO SET LEVEL SHIT INTO HERE
    function skillPointsEarned(uint256 _punkID) public view returns (uint256) {
        uint256 totalJoined = raceContract
            .freighPunkStats(_punkID)
            .racesJoined * baseXPEarned;

        uint256 firstPlaceEarned = raceContract
            .freighPunkStats(_punkID)
            .firstPlaces * xpEarnedFormula[1];
        uint256 secondPlaceEarned = raceContract
            .freighPunkStats(_punkID)
            .secondPlaces * xpEarnedFormula[2];
        uint256 thirdPlaceEarned = raceContract
            .freighPunkStats(_punkID)
            .thirdPlaces * xpEarnedFormula[2];

        return
            totalJoined +
            firstPlaceEarned +
            secondPlaceEarned +
            thirdPlaceEarned;
    }

    function xpSpentForPunk(uint256 _punkID) public view returns (uint256) {
        return xpSpent[_punkID];
    }

    function availableSkillPoints(uint256 _punkID)
        public
        view
        returns (uint256)
    {
        return skillPointsEarned(_punkID) - xpSpent[_punkID];
    }

    //TODO--- GET LEVEL THINGY
    function punkLevel(uint256 _punkID) public view returns (uint256) {}

    function buyUpgrade(uint256 _punkID, uint256 _upgradeID) public {
        require(
            punkSkills[_upgradeID].price <= availableSkillPoints(_punkID),
            "Not enough skill points"
        );
        require(
            punkSkills[_upgradeID].wof_cost <= wofToken.balanceOf(msg.sender),
            "Not enough WOF tokens"
        );
        require(
            punkSkills[_upgradeID].wof_cost <=
                wofToken.allowance(msg.sender, address(this)),
            "Increase allowance"
        );
        require(
            punkSkills[_upgradeID].req_level <= punkLevel(_punkID),
            "Punk level too low"
        );
        require(
            punkSkills[_upgradeID].price >= getAvailableSkillPoints(_punkID),
            "Not enough skill points"
        );
        //TRANSFER WOF IF UPGRADE COSTS
        skillPointsSpent[_punkID] += punkSkills[_upgradeID].price;

        if (punkSkills[_upgradeID].wof_cost > 0) {
            wofToken.transferFrom(
                msg.sender,
                address(this),
                punkSkills[_upgradeID].wof_cost
            );
        }
        ownedSkills[_punkID].push(_upgradeID);
    }

    function getAvailableSkillPoints(uint256 _punkID)
        public
        view
        returns (uint256)
    {
        uint256 level = getPunkLevel(_punkID);
        uint256 skillPoints = 1;
        if (level > 20) {
            skillPoints = 2;
        }
        if (level > 40) {
            skillPoints = 4;
        }
        if (level > 60) {
            skillPoints = 6;
        }
        if (level > 80) {
            skillPoints = 8;
        }
        return skillPoints - skillPointsSpent[_punkID];
    }

    function getPunkLevel(uint256 _punkID) public view returns (uint256) {
        uint256 xpEarned = skillPointsEarned(_punkID);
        uint256 level = 0;
        uint256 base = ((level * 1 ether) + 1 ether) / 4;
        uint256 xpToNext = base**2;

        while (xpToNext < (xpEarned * 1 ether)) {
            level++;
            base = ((level * 1 ether) + 1 ether) / 4;
            xpToNext = base**2;
        }
        return level;
    }

    function setBaseXPEarned(uint256 _baseXPEarned) public onlyOwner {
        baseXPEarned = _baseXPEarned;
    }

    function setXPEarnedFormula(XPFormula[] memory _array) public onlyOwner {
        for (uint256 i = 0; i < _array.length; i++) {
            xpEarnedFormula[_array[i].place] = _array[i].amount;
        }
    }

    function setRaceContract(address _address) public onlyOwner {
        raceContract = IWofRacingContract(_address);
    }

    function setWofToken(address _address) public onlyOwner {
        wofToken = IWofToken(_address);
    }

    //WIDTHRAW WOF TOKENS
    function withdraw(address _to, uint256 _amount) public onlyOwner {
        wofToken.transfer(_to, _amount);
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