/**
 *Submitted for verification at polygonscan.com on 2023-05-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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


abstract contract Level is Ownable {
  function createInstance(address _player) virtual public payable returns (address);
  function validateInstance(address payable _instance, address _player) virtual public returns (bool);
  function weight() virtual public pure returns (uint256);
}
contract Multicall {

     function multicall(bytes[] calldata data) public view returns (bytes[] memory results) {
         results = new bytes[](data.length);

       for (uint i; i < data.length; i++) {
         (bool success, bytes memory result) = address(this).staticcall(data[i]);
         require(success, "call failed");
         results[i] = result;
       }

       return results;
     }
}

contract Ethernaut is Multicall, Ownable {

  // ----------------------------------
  // Owner interaction
  // ----------------------------------

  mapping(address => bool) registeredLevels;
  mapping(string => bool) isBusyNick;
  mapping(address => string) public nicks;
  mapping(address => mapping(address => bool)) scores;
  mapping(address => uint256) levelSuccesses;

  uint256 startTime;
  uint256 duration;
  address[] levels;
  address[] users;

  // Only registered levels will be allowed to generate and validate level instances.
  function registerLevel(Level _level) public onlyOwner {
    require(!registeredLevels[address(_level)], "already registered");
    registeredLevels[address(_level)] = true;
    levels.push(address(_level));
  }

  // ----------------------------------
  // Get/submit level instances
  // ----------------------------------

  struct EmittedInstanceData {
    address player;
    Level level;
    bool completed;
  }

  mapping(address => EmittedInstanceData) emittedInstances;
  
  // user => level => instance
  mapping(address => mapping(address => address)) public userInstances;

  event NewPlayerLog(address indexed player, string nick);
  event LevelInstanceCreatedLog(address indexed player, address instance);
  event LevelCompletedLog(address indexed player, Level level);
  event NewScore(address indexed player, address level, uint256 score);


  modifier onlyRunning {
    require(startTime > 0, "round isn't started");
    require(startTime + duration > block.timestamp, "round have finished");
    _;
  }

  function start(uint256 _duration) external onlyOwner {
    startTime = block.timestamp;
    duration = _duration;
  }

  function register(string memory _nick) external onlyRunning {
    require(bytes(_nick).length > 0, "empty nick");
    require(!isBusyNick[_nick], "busy nick");
    require(bytes(nicks[msg.sender]).length == 0, "already registered");

    isBusyNick[_nick] = true;
    nicks[msg.sender] = _nick;

    users.push(msg.sender);

    emit NewPlayerLog(msg.sender, _nick);
  }

  function createLevelInstance(Level _level) public payable onlyRunning {
    require(bytes(nicks[msg.sender]).length > 0, "player is not registred");
    require(!scores[msg.sender][address(_level)], "already submitted");

    // Ensure level is registered.
    require(registeredLevels[address(_level)]);
    // Get level factory to create an instance.
    address instance = _level.createInstance{value:msg.value}(msg.sender);

    // Store emitted instance relationship with player and level.
    emittedInstances[instance] = EmittedInstanceData(msg.sender, _level, false);

    // save instance address for the user
    userInstances[msg.sender][address(_level)] = instance;

    // Retrieve created instance via logs.
    emit LevelInstanceCreatedLog(msg.sender, instance);
  }

  function submitLevelInstance(address payable _instance) public onlyRunning {
    // Get player and level.
    EmittedInstanceData storage data = emittedInstances[_instance];
    require(data.player == msg.sender); // instance was emitted for this player
    require(data.completed == false); // not already submitted
    require(!scores[msg.sender][address(data.level)], "already submitted");

    // Have the level check the instance.
    if(data.level.validateInstance(_instance, msg.sender)) {

      // Register instance as completed.
      data.completed = true;

      // Update score
      setScore(data.player, address(data.level));

      levelSuccesses[address(data.level)] += 1; // increase counter off level success completions

      // Notify success via logs.
      emit LevelCompletedLog(msg.sender, data.level);
    }
  }

  function getUserLevelScore(address _player, uint256 levelIndex) public view returns (uint256) {
    require(levelIndex < levels.length, "incorrect index");
    address _level = levels[levelIndex];
    if (!scores[_player][_level]) {
      return 0;
    }

    uint256 levelWeight = Level(_level).weight();
    uint256 levelHardness = levelSuccesses[_level] > 20 ? 20 : levelSuccesses[_level];
    return levelWeight * (40 - levelHardness) / 40;
  }

  function getUserTotalScore(address _player) external view returns (uint256) {
    uint256 totalScore = 0;
    for(uint256 i = 0; i < levels.length; ++i) {
      totalScore += getUserLevelScore(_player, i);
    }
    return totalScore;
  }

  function getUsers() external view returns (address[] memory) {
    return users;
  }

  function setScore(address _player, address _level) internal {
    scores[_player][_level] = true;

    emit NewScore(_player, _level, 1);
  }
}