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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SafeMath.sol";

contract ZombieFactory is Ownable{
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;
    using SafeMath for uint256;

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    mapping (uint => address) public zombieToOwner;
    mapping (address => uint) ownerZombieCount;
    uint cooldownTime = 1 days;

    struct Zombie{
        string name;
        uint dna;
        uint32 level;
        uint32 readyTime;
        uint16 winCount;
        uint16 lossCount;
    }

    event NewZombie(uint zombieId, string name, uint dna);

    Zombie[] public zombies;
    function _createZombie(string memory _name, uint256 _dna) internal {
        require(ownerZombieCount[msg.sender] == 0, "Not the first zombie!");
        zombies.push(Zombie(_name, _dna, 1, uint32(block.timestamp + cooldownTime), 0, 0));
        uint zombieId = zombies.length - 1; 
        zombieToOwner[zombieId] = msg.sender;
        ownerZombieCount[msg.sender] = ownerZombieCount[msg.sender].add(1);
        emit NewZombie(zombieId, _name, _dna);
    }
    function _generateRandomDna(string memory _str) private view returns (uint){
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }
    function createRandomZombie (string memory _name) public{
        uint randDna = _generateRandomDna(_name);
        _createZombie(_name, randDna);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './ZombieFactory.sol';

contract ZombieFeeding is ZombieFactory{
    KittyInterface kittyContract;

    function _triggerCooldown(Zombie storage _zombie) internal{
        _zombie.readyTime = uint32(block.timestamp + cooldownTime);
    }
    function _isReady(Zombie storage _zombie) internal view returns (bool){
        return (_zombie.readyTime <= block.timestamp);
    }

    function setKittyContractAddress(address _address) external onlyOwner {
        kittyContract = KittyInterface(_address);
    }

    function feedAndMultiply(uint _zombieId, uint _targetDna, string memory _species) internal isOwner(_zombieId){
        require(msg.sender == zombieToOwner[_zombieId], "Not the owner of the zombie");
        Zombie storage myZombie = zombies[_zombieId];
        require(_isReady(myZombie), "Can't feed yet");
        _targetDna = _targetDna % dnaModulus;
        uint newDna = (_targetDna + myZombie.dna)/2;

        if(keccak256(abi.encodePacked(_species)) == keccak256(abi.encodePacked("kitty"))){
            newDna = newDna - newDna % 100 + 99; // Replace last 2 digits with 99
        }

        _createZombie("NoName", newDna);
        _triggerCooldown(myZombie);
    }

    function feedOnKitty(uint _zombieId, uint kittyId) public{
        uint kittyDna;
        (,,,,,,,,,kittyDna) = kittyContract.getKitty(kittyId);
        feedAndMultiply(_zombieId, kittyDna, "kitty");
    }
    modifier isOwner (uint _zombieId){
        require(msg.sender == zombieToOwner[_zombieId], "No access!");
        _;
    }
}
abstract contract KittyInterface{
    function getKitty(uint256 _id) external virtual view returns(
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    );
}