pragma solidity 0.8;

import "./IPlayer.sol";
import "./ICTFFactory.sol";
import "./ICTF.sol";

contract CTFs {
  mapping(address => mapping(ICTFFactory => ICTF)) public instances;
  mapping(address => mapping(ICTFFactory => bool)) public challengeComplete;
  mapping(ICTFFactory => uint256) public instancesInit;
  mapping(ICTFFactory => uint256) public instancesFinished;

  IPlayer immutable public players;

  event CreateInstance(address indexed player, address instance);
  event CompleteInstance(address indexed player, address instance);
  constructor(address _players) {
    players = IPlayer(_players);
  }

  function createInstance(ICTFFactory _factory) public payable {
    require(players.canPlay(msg.sender), "Player is not allowed to play");
    uint256 _price = _factory.getPrice();
    // _price can be 0
    require(msg.value == _price, "Not enough ether");
    
    instances[msg.sender][_factory] = _factory.create{value: msg.value}(msg.sender);
    instancesInit[_factory] += 1;
    
    emit CreateInstance(msg.sender, address(instances[msg.sender][_factory]));
  }

  function getInstance(address _player, ICTFFactory _instance) public view returns (address) {
    return address(instances[_player][_instance]);
  }

  function complete(ICTFFactory _factory) external {
    require(players.canPlay(msg.sender), "Player is not allowed to play");
    
    ICTF _instance = instances[msg.sender][_factory];
    require(_instance.isComplete(), "Challenge is not complete");
    if(_instance.isComplete()) {
      delete instances[msg.sender][_factory];
      instancesFinished[_factory] += 1;
      challengeComplete[msg.sender][_factory] = true;

      emit CompleteInstance(msg.sender, address(_instance));
    }
  }
}

pragma solidity 0.8;

interface IPlayer {
	function canPlay(address) external view returns (bool);
}

pragma solidity 0.8;

import "./ICTF.sol";

interface ICTFFactory {
  function create(address) external payable returns(ICTF);
  function getPrice() external view returns (uint256);
}

pragma solidity 0.8;

interface ICTF {
  function isComplete() external view returns (bool);
}