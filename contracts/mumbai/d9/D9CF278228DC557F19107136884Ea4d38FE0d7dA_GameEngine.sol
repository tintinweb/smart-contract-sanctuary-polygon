/**
 *Submitted for verification at polygonscan.com on 2022-08-07
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/GameEngine.sol



pragma solidity >=0.7.0 <0.9.0;



struct Player {
    uint256 id;
    string dna;
    uint256 rareBonus;
    uint256 speed;
    uint256 strength;
    uint256 reactivity;
    uint256 skills;
    uint256 health;
    uint256 maxHealth;
    uint256 price;
}

interface GenericContractInterface {
    function getPlayerStats (uint256 _id) external view returns(uint256, Player memory);
}


struct ChoosenPlayer {
    address collectionAddress;
    uint256 id;
    string role;
}

interface SoccerGameManagerInterface {
    function getSquadInfo (address _coach) external view returns(ChoosenPlayer [] memory);
} 


contract GameEngine is Ownable {

    mapping(address => bool) public approvedContracts;

    address public gameManagerAddress = 0xEce73acB489743A7D329c73593D320ea5Dc0D373;
    SoccerGameManagerInterface soccerGameManagerInstance = SoccerGameManagerInterface(gameManagerAddress);

    uint256 private minGoalkeeperReactivity;
    uint256 private maxGoalkeeperReactivity;

    uint256 private defenderSpeed;
    uint256 private defenderStrength;
    uint256 private defenderReactivity;

    uint256 private midfilderSkills;
    uint256 private midfilderStrength;
    uint256 private midfilderReactivity;

    uint256 private strikerStrength;
    uint256 private strikerSpeed;
    uint256 private strikerSkills;

    uint256 private minMalus;
    uint256 private maxMalus;

    uint256 private minBonus;
    uint256 private maxBonus;


    // game functions
    function linkStart(address _challenger, address _enemy) external view returns(uint256) {
        require(approvedContracts[msg.sender]);

        int challengerRating = getSquadRating(_challenger);
        int enemyRating = getSquadRating(_enemy);

        if(challengerRating - enemyRating >= 10){
            return 1;
        } else if(challengerRating - enemyRating <= -10){
            return 2;
        } else {
            return 0;
        }

    }


    function getSquadRating(address _coach) internal view returns (int) {
        ChoosenPlayer [] memory squad = soccerGameManagerInstance.getSquadInfo(_coach);
        int rating = 0;
        uint256 total = 0;
        uint256 randomizer = 7;

        for(uint256 i = 0; i < squad.length; i++) {

            ChoosenPlayer memory player = squad[i];
            Player memory playerStruct;

            GenericContractInterface genericContractInstance = GenericContractInterface(player.collectionAddress);
            (total, playerStruct) = genericContractInstance.getPlayerStats(player.id);

            if( keccak256(abi.encodePacked(player.role)) == keccak256(abi.encodePacked("goalkeeper")) ) {

                if(playerStruct.reactivity < minGoalkeeperReactivity) {
                    total -= ( random(randomizer, maxMalus - 1 ) + minMalus);
                    randomizer *= 7;
                } else if(playerStruct.reactivity > maxGoalkeeperReactivity) {
                    total += ( random(randomizer, maxBonus - 1 ) + minBonus);
                    randomizer *= 7;
                }

            } else if ( keccak256(abi.encodePacked(player.role)) == keccak256(abi.encodePacked("defender")) ) {

                    if(playerStruct.speed > defenderSpeed) {
                        total += ( random(randomizer, maxBonus - 1 ) + minBonus);
                        randomizer *= 7;
                    } else {
                        total -= ( random(randomizer, maxMalus - 1 ) + minMalus);
                        randomizer *= 7;
                    }

                    if (playerStruct.strength > defenderStrength) {
                        total += ( random(randomizer, maxBonus - 1 ) + minBonus);
                        randomizer *= 7;
                    } else {
                        total -= ( random(randomizer, maxMalus - 1 ) + minMalus);
                        randomizer *= 7;
                    }

                    if (playerStruct.reactivity > defenderReactivity) {
                        total += ( random(randomizer, maxBonus - 1 ) + minBonus);
                        randomizer *= 7;
                    } else {
                        total -= ( random(randomizer, maxMalus - 1 ) + minMalus);
                        randomizer *= 7;
                    }

            } else if ( keccak256(abi.encodePacked(player.role)) == keccak256(abi.encodePacked("midfilder")) ) {

                    if(playerStruct.skills > midfilderSkills) {
                        total += ( random(randomizer, maxBonus - 1 ) + minBonus);
                        randomizer *= 7;
                    } else {
                        total -= ( random(randomizer, maxMalus - 1 ) + minMalus);
                        randomizer *= 7;
                    }

                    if (playerStruct.strength > midfilderStrength) {
                        total += ( random(randomizer, maxBonus - 1 ) + minBonus);
                        randomizer *= 7;
                    } else {
                        total -= ( random(randomizer, maxMalus - 1 ) + minMalus);
                        randomizer *= 7;
                    }

                    if (playerStruct.reactivity > midfilderReactivity) {
                        total += ( random(randomizer, maxBonus - 1 ) + minBonus);
                        randomizer *= 7;
                    } else {
                        total -= ( random(randomizer, maxMalus - 1 ) + minMalus);
                        randomizer *= 7;
                    }

            } else if( keccak256(abi.encodePacked(player.role)) == keccak256(abi.encodePacked("striker")) ) {

                    if(playerStruct.skills > strikerSkills) {
                        total += ( random(randomizer, maxBonus - 1 ) + minBonus);
                        randomizer *= 7;
                    } else {
                        total -= ( random(randomizer, maxMalus - 1 ) + minMalus);
                        randomizer *= 7;
                    }

                    if (playerStruct.strength > strikerStrength) {
                        total += ( random(randomizer, maxBonus - 1 ) + minBonus);
                        randomizer *= 7;
                    } else {
                        total -= ( random(randomizer, maxMalus - 1 ) + minMalus);
                        randomizer *= 7;
                    }

                    if (playerStruct.speed > strikerSpeed) {
                        total += ( random(randomizer, maxBonus - 1 ) + minBonus);
                        randomizer *= 7;
                    } else {
                        total -= ( random(randomizer, maxMalus - 1 ) + minMalus);
                        randomizer *= 7;
                    }

            }

            rating += int(total);
        }

        return rating;
    }


    function random(uint256 randomizer, uint256 _maxValue) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number, randomizer))) % _maxValue;
    }
    // #############################################

    //setting functions

    function approveContract(address _contractAddress) public onlyOwner {
        approvedContracts[_contractAddress] = true;
    }


    function disapproveContract(address _contractAddress) public onlyOwner {
        approvedContracts[_contractAddress] = false;
    }


    function setGoalkeeper (uint256 _min, uint256 _max) public onlyOwner {
        minGoalkeeperReactivity = _min;
        maxGoalkeeperReactivity = _max;
    }


    function setDefender (uint256 _speed, uint256 _strength, uint256 _reactivity) public onlyOwner {
        defenderSpeed      = _speed;
        defenderStrength   = _strength;
        defenderReactivity = _reactivity;
    }


    function setMidfilder (uint256 _skills, uint256 _strength, uint256 _reactivity) public onlyOwner {
        midfilderSkills      = _skills;
        midfilderStrength   = _strength;
        midfilderReactivity = _reactivity;
    }


    function setStriker (uint256 _strength, uint256 _speed, uint256 _skills) public onlyOwner {
        strikerStrength  = _strength;
        strikerSpeed     = _speed;
        strikerSkills    = _skills;
    }


    function setMalus(uint256 _min, uint256 _max) public onlyOwner {
        minMalus = _min;
        maxMalus = _max; 
    }


    function setBonus(uint256 _min, uint256 _max) public onlyOwner {
        minBonus = _min;
        maxBonus = _max; 
    }
    // #############################################
}