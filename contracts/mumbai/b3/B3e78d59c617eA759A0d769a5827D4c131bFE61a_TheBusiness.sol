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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TheBusiness is Ownable {

    uint256 public magicNumber = 532323;
    uint256 private basePlantId = 100_000_000_000;
    mapping(uint256 => uint256[]) public skillPool;
    mapping(uint256 => uint256[]) public skillZonePool;

    constructor() {
        skillZonePool[1] = [11, 12];
        skillZonePool[2] = [7,8,9,10];
        skillZonePool[3] = [1,2,3,4,5,6];

        skillPool[1] = [51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69];
        skillPool[2] = [26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50];
        skillPool[3] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25];
    }

    function _calculateRandom(address owner, uint256 randomNumber, uint256 module) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(owner, randomNumber))) % module + 1;
    }

    function _randomSkill(address owner, uint256 randomNumber) private view returns(uint256){
        // uint256 number =  randomNumber % 1000 + 1;
        uint256 number = _calculateRandom(owner, randomNumber, 1000);

        uint256 skill;
        if(number <= 700){
            skill = number % skillPool[3].length;
            return skillPool[3][skill];
        }else if(number > 700 && number <= 955){
            skill = number % skillPool[2].length;
            return skillPool[2][skill];
        }else{
            skill = number % skillPool[1].length;
            return skillPool[1][skill];
        }
    }

    function _randomSkillZone(address owner, uint256 randomNumber) private view returns(uint256){
        // uint256 number =  randomNumber % 1000 + 1;
        uint256 number = _calculateRandom(owner, randomNumber, 1000);

        uint256 skillZone;

        if(number <= 600){
            skillZone = number % skillZonePool[3].length;
            return skillZonePool[3][skillZone];
        }else if(number > 600 && number <= 980){
            skillZone = number % skillZonePool[2].length;
            return skillZonePool[2][skillZone];
        }else{
            skillZone = number % skillZonePool[1].length;
            return skillZonePool[1][skillZone];
        }
    }

    function _randomSupport(address owner, uint256 randomNumber) private pure returns(uint256) {
        // uint256 number =  randomNumber % 1000 + 1;
        uint256 number = _calculateRandom(owner, randomNumber, 1000);


        if(number <= 200){
            return 1;
        } else if(number > 200 && number <= 380){
            return 2;
        } else if(number > 380 && number <= 540){
            return 3;
        } else if(number > 540 && number <= 680){
            return 4;
        } else if(number > 680 && number <= 800){
            return 5;
        } else if(number > 800 && number <= 880){
            return 6;
        } else if(number > 880 && number <= 940){
            return 7;
        } else if(number > 940 && number <= 970){
            return 8;
        } else if(number > 970 && number <= 990){
            return 9;
        } else {
            return 10;
        }
    }

    function _randomSabotage(address owner, uint256 randomNumber) private pure returns(uint256){
        // uint256 number =  randomNumber % 1000 + 1;
        uint256 number = _calculateRandom(owner, randomNumber, 1000);


        if(number <= 200){
            return 1;
        } else if(number > 200 && number <= 380){
            return 2;
        } else if(number > 380 && number <= 540){
            return 3;
        } else if(number > 540 && number <= 680){
            return 4;
        } else if(number > 680 && number <= 800){
            return 5;
        } else if(number > 800 && number <= 880){
            return 6;
        } else if(number > 880 && number <= 940){
            return 7;
        } else if(number > 940 && number <= 970){
            return 8;
        } else if(number > 970 && number <= 990){
            return 9;
        } else {
            return 10;
        }
    }

    function setSP(uint256 _id, uint256[] memory _skills) external onlyOwner {
        skillPool[_id] = _skills;
    }

    function setSZP(uint256 _id, uint256[] memory _skillZone) external onlyOwner {
        skillZonePool[_id] = _skillZone;
    }

    function getIDs(address _owner, uint256 randomNumber, uint256 length) public view returns(uint256[] memory) {
        uint256[] memory ids = new uint256[](length);

        uint256 cummulativeRN = randomNumber;
        for(uint256 i = 0; i < length; i++){
            uint256 plantID = getID(_owner, cummulativeRN);
            ids[i] = plantID;

            if (plantID >= basePlantId) {
                cummulativeRN += magicNumber * 5;
            } else {
                cummulativeRN += magicNumber;
            }
        }
        return ids;
    }

    function getID(address _owner, uint256 randomNumber) public view returns(uint256){
        // uint256 number = randomNumber % 10000 + 1;
        uint256 number = _calculateRandom(_owner, randomNumber, 10000);

        if(number <= 9600){
            uint256 plantType = number % 9 + 1;
            uint256 plantID = basePlantId + plantType * 10**10;

            if(number <= 5500){ //common
                uint256 plantNumber = number % 2 + 1;
                plantID += plantNumber * 10**8;
            } else if (number > 5500 && number <= 8500){ //rare
                plantID += 3 * 10**8;
            } else if (number > 8500 && number <= 9400){ //epic
                plantID += 4 * 10**8;
            } else{ // legendary
                plantID += 5 * 10**8;
            }

            plantID += _randomSkill(_owner, randomNumber + magicNumber * 4) * 10**6 + _randomSkillZone(_owner, randomNumber + magicNumber * 3) * 10**4 + _randomSupport(_owner, randomNumber + magicNumber * 2) * 10**2 + _randomSabotage(_owner, randomNumber + magicNumber);
            return plantID;
        } else {
            uint256 plantType = 2_000_000_000 + (number + 1 % 9) * 10**8;

            if (number <= 9850) {
                return plantType + 1010101;
            } else if (number <= 9950) {
                return plantType + 2020102;
            } else if (number <= 9990) {
                return plantType + 3030103;
            } else {
                return plantType + 4040104;
            }

            /*
            plantID = 2_000_000_000;
            uint256 plantType = (number + 1) % 9;
            plantID += plantType * 10**8;
            
            if (number <= 9850) {
                plantID += 1 * 10**6 + 1 * 10 ** 4 +1 * 10**2 + 1; // common
            } else if (number <= 9950) {
                plantID += 2 * 10**6 + 2 * 10 ** 4 +1 * 10**2 + 2; // rare
            } else if (number <= 9990) {
                plantID += 3 * 10**6 + 3 * 10 ** 4 +1 * 10**2 + 3; // epic
            } else {
                plantID += 4 * 10**6 + 4 * 10 ** 4 + 1 * 10**2 + 4; // legendary
            }
            return plantID;
            */
        }
    } 
}