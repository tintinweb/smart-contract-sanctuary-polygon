// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IWofRacingContract {
    function freightPunkStats(uint256 punkID)
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
    // ORIGINAL
    struct TokenStats {
        uint256 racesJoined;
        uint256 firstPlaces;
        uint256 secondPlaces;
        uint256 thirdPlaces;
        uint256 tokensWon;
    }
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
        uint256 price;
        uint256 req_level;
        uint256 wof_cost;
    }

    struct XPFormula {
        uint256 place;
        uint256 amount;
    }

    struct Skill {
        bool owned;
    }
    //MAP SKILL TREES BY ID
    mapping(uint256 => SkillTree) public punkSkills;
    mapping(uint256 => uint256) public xpEarnedFormula;
    mapping(uint256 => uint256) public skillPointsSpent;
    mapping(uint256 => mapping(uint256 => Skill)) public ownedSkills;

    function uploadSkilltree(SkillTree[] memory _array) public onlyOwner {
        for (uint256 i = 0; i < _array.length; i++) {
            punkSkills[_array[i].id] = _array[i];
        }
    }

    function availableSkillPoints(uint256 _punkID)
        public
        view
        returns (uint256)
    {
        return getAvailableSkillPoints(_punkID);
    }

    function buySkill(uint256 _punkID, uint256 _skillID) public {
        require(
            ownedSkills[_punkID][_skillID].owned == false,
            "Skill already owned"
        );
        require(
            punkSkills[_skillID].req_level <= getPunkLevel(_punkID),
            "Punk level too low"
        );
        require(
            punkSkills[_skillID].price <= getAvailableSkillPoints(_punkID),
            "Not enough skill points"
        );
        //TRANSFER WOF IF SKILL COSTS

        if (punkSkills[_skillID].wof_cost > 0) {
            require(
                punkSkills[_skillID].wof_cost <= wofToken.balanceOf(msg.sender),
                "Not enough WOF tokens"
            );
            require(
                punkSkills[_skillID].wof_cost <=
                    wofToken.allowance(msg.sender, address(this)),
                "Increase allowance"
            );
            wofToken.transferFrom(
                msg.sender,
                address(this),
                punkSkills[_skillID].wof_cost
            );
        }

        skillPointsSpent[_punkID] += punkSkills[_skillID].price;
        ownedSkills[_punkID][_skillID].owned = true;
    }

    function getAvailableSkillPoints(uint256 _punkID)
        public
        view
        returns (uint256)
    {
        uint256 level = getPunkLevel(_punkID);

        uint256 skillPoints = 0;
        uint256 substractLevel = 0;
        if (level > 80) {
            substractLevel = level - 80;
            skillPoints += substractLevel * 8;
            level = level - substractLevel;
        }
        if (level > 60) {
            substractLevel = level - 60;
            skillPoints += substractLevel * 6;
            level = level - substractLevel;
        }
        if (level > 40) {
            substractLevel = level - 40;
            skillPoints += substractLevel * 4;
            level = level - substractLevel;
        }
        if (level > 20) {
            substractLevel = level - 20;
            skillPoints += substractLevel * 2;
            level = level - substractLevel;
        }
        if (level < 21) {
            skillPoints += level;
        }
        return skillPoints - skillPointsSpent[_punkID];
    }

    function getPunkLevel(uint256 _punkID) public view returns (uint256) {
        uint256 earnedXp = xpEarned(_punkID);

        uint256 level = 0;
        uint256 base = (level + 1) * 4;

        uint256 xpToNext = base**2;

        while (xpToNext < earnedXp) {
            level++;
            base = (level + 1) * 4;
            xpToNext = base**2;
        }
        return level;
    }

    function setBaseXPEarned(uint256 _baseXPEarned) public onlyOwner {
        baseXPEarned = _baseXPEarned;
    }

    function xpEarned(uint256 _punkID) public view returns (uint256) {
        uint256 totalJoined = raceContract.freightPunkStats(_punkID).racesJoined *
            baseXPEarned;
        uint256 firstPlaceEarned = raceContract.freightPunkStats(_punkID).firstPlaces *
            xpEarnedFormula[1];
        uint256 secondPlaceEarned = raceContract.freightPunkStats(_punkID).secondPlaces *
            xpEarnedFormula[2];
        uint256 thirdPlaceEarned = raceContract.freightPunkStats(_punkID).thirdPlaces *
            xpEarnedFormula[3];

        return
            totalJoined +
            firstPlaceEarned +
            secondPlaceEarned +
            thirdPlaceEarned;
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