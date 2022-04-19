// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import {Ownable} from "Ownable.sol";
import {ISeed} from "ISeed.sol";

error Unauthorized();

contract GameStats is Ownable {

    enum Class {
        Attacker,
        Defender,
        Supporter
    }

    struct Stats {
        uint256 attack;
        uint256 defense;
        uint256 initiative;
    }

    struct Bio {
        Class class;
        uint256 characterId;
        Stats stats;
    }

    uint256 highRange = 9;
    uint256 mediumRange = 7;
    uint256 lowRange = 5;

    mapping(uint256 => Bio) public tokenIdToBio;

    address private forlornHopeNFT;
    
    ISeed public seedCon;

    event GenerateBio(uint256 indexed _tokenId, uint256 _class, uint256 _characterId, uint256 _attack, uint256 _defense, uint256 _initiative);

    modifier onlyForlorn {   
        if (_msgSender() != address(forlornHopeNFT) || _msgSender() != owner()) {
            revert Unauthorized();
        }   
        _;
   }

    constructor(address _forlornHopeNFT, address _seedCon) {
        forlornHopeNFT = _forlornHopeNFT;
        setSeed(_seedCon);
    }

    function generateBio(uint256 tokenId, uint256 characterId, uint256 seedNumber) external {
        uint256 class = selectClass(seedNumber);
        // add onlyForlorn later
        Bio memory bio;
        bio.characterId = characterId;
        if (class == 0) {
            bio.class = Class.Attacker;
            bio.stats = attackerStats(seedNumber);
        }
        if(class == 1) {
            bio.class = Class.Defender;
            bio.stats = defenderStats(seedNumber);
        }
        if (class == 2) {
            bio.class = Class.Supporter;
            bio.stats = supporterStats(seedNumber);
        }
        tokenIdToBio[tokenId] = bio;
        emit GenerateBio(tokenId, class, characterId, bio.stats.attack, bio.stats.defense, bio.stats.initiative);
    }

    /*function assignRandomStats(uint256 classId) external view returns (uint256, uint256, uint256) {
        // sdaasdsad
    }*/

    function attackerStats(uint256 _seedNumber) public view returns(Stats memory) {
        Stats memory stats;
        stats.attack = 30 + randomStats(_seedNumber, highRange);
        stats.defense = 20 + randomStats(_seedNumber, mediumRange);
        stats.initiative = 10 + randomStats(_seedNumber, lowRange);
        return stats;
    }

    function defenderStats(uint256 _seedNumber) public view returns(Stats memory) {
        Stats memory stats;
        stats.attack = 20 + randomStats(_seedNumber, mediumRange);
        stats.defense = 30 + randomStats(_seedNumber, highRange);
        stats.initiative = 10 + randomStats(_seedNumber, lowRange);
        return stats;
    }

    function supporterStats(uint256 _seedNumber) public view returns(Stats memory) {
        Stats memory stats;
        stats.attack = 20 + randomStats(_seedNumber, mediumRange);
        stats.defense = 20 + randomStats(_seedNumber, mediumRange);
        stats.initiative = 20 + randomStats(_seedNumber, mediumRange);
        return stats;
    }

    function getTokenBio(uint256 tokenId) public view returns (Bio memory) {
        return tokenIdToBio[tokenId];
    }

    function selectClass(uint256 _seedNumber) internal view returns (uint256) {
        uint256 m = _seedNumber % 1000;
        if (m > 666) {
            return 0;
        } else if (m > 333) {
            return 1;
        } else {
            return 2;
        }
    }

    function randomStats(uint256 _seedNumber, uint256 range) internal view returns (uint256) {
        return
            (uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        _seedNumber
                    )
                )
            ) ^ _seedNumber) % (range) + 1 ;
    }

    function setForlornHopeNFT(address forlornHopeNFT_) public onlyOwner {
        forlornHopeNFT = forlornHopeNFT_;
    }

    function setSeed(address _seedCon) public onlyOwner {
        seedCon = ISeed(_seedCon);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT LICENSE
pragma solidity >=0.8.13;

interface ISeed {

    function random(uint256 _seedNumber) external view returns (uint256);

    function update(uint256 _seed) external returns (uint256);

    function generateAmount() external view returns (uint256);
}