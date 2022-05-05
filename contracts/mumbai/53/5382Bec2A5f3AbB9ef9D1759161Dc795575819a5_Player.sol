pragma solidity 0.8;

/// @title Player contract interface
/// @notice Keeps track of players names and if the pass the tutorial
/// @dev Explain to a developer any extra details
contract Player {
	mapping(address => uint) public playerLockUntil;
	mapping(address => bytes32) public playerName;

	event CreatePlayer(address indexed player, bytes32 name);
	event UpdateName(address indexed player, bytes32 name);
	event UpdateLock(address player);


	function createPlayer(bytes32 _name) public {
		playerName[msg.sender] = _name;
		if(playerLockUntil[msg.sender] == 0) {
			playerLockUntil[msg.sender] = block.timestamp + 5 * 365 days;
			emit CreatePlayer(msg.sender, _name);
		} else {
			emit UpdateName(msg.sender, _name);
		}
	}

  function updateLock(uint _lockUntil) public {
		// we use unchecked for gas optimization
		unchecked {
			playerLockUntil[msg.sender] += _lockUntil;
		}
		emit UpdateLock(msg.sender);
	}

	function canPlay(address _player) public view returns (bool) {
		return playerLockUntil[_player] > 0 &&
			playerLockUntil[_player] < block.timestamp
			&& playerName[_player] != 0x0000000000000000000000000000000000000000000000000000000000000000;
	}
}