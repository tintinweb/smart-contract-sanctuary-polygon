// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";
import "./Turtle.sol";
import "./Rabbit.sol";
import "./RVTUtils.sol";

contract RabbitsVsTurtles is ERC721Enumerable, Ownable {
  using Strings for uint256;

   mapping (uint256 => RVTUtils.Player) public players;

   uint256 public cost = 1 ether;
   uint256 public increaseAttackCost = 5 ether;
   uint256 public increaseDefenseCost = 5 ether;
   uint256 public increaseArmorCost = 10 ether;
   uint256 public increaseStaminaCost = 10 ether;
   uint256 public revivePlayerCost = 500 ether;

   event Attacked (uint256 indexed _eaterId, uint256 indexed _eatenId);
   event AttackIncreased (uint256 indexed _playerId);
   event DefenseIncreased (uint256 indexed _playerId);
   event ArmorIncreased (uint256 indexed _playerId);
   event StaminaIncreased (uint256 indexed _playerId);
   event Revived (uint256 indexed _playerId);

   constructor() ERC721("Rabbits Vs Turtles", "RVT") {}

  function mint() public payable {
    uint256 supply = totalSupply();
    
    RVTUtils.Player memory newPlayer = RVTUtils.Player(
        string(abi.encodePacked('Rabbits Vs Turtles #', uint256(supply + 1).toString())), 
        checkWhichTeamNewPlayerWillJoin(),
        "Rabbits Vs. Turtles is a new 100% on-chain, dynamic NFTs Multiplayer game. The NFTs change dynamically as the game progress and each NFT mirror the complete status of the player in the game. Ready to take your part and try to become the best of the best?",
        RVTUtils.generateArrayOfRandomNumbers(361, block.difficulty+30, block.timestamp, 50),
        true,
        block.timestamp,
        RVTUtils.randomNumStartingAt(1 ,100, block.difficulty+40, block.timestamp),
        RVTUtils.randomNumStartingAt(1 ,100, block.difficulty, block.timestamp+50),
        0,
        false
        );
    
    if (msg.sender != owner()) {
      require(msg.value >= cost);
    }
    players[supply + 1] = newPlayer;
    _safeMint(msg.sender, supply + 1);
    cost = (cost * 1001) / 1000;
}

  function getPlayerByIndex(uint256 _tokenId) public view returns(RVTUtils.Player memory) {
    require(_exists(_tokenId),"ERC721Metadata: Query for nonexistent token");
    RVTUtils.Player memory player = players[_tokenId];
    return player;
  }

  function checkWhichTeamNewPlayerWillJoin() public view returns(string memory) {
        return RVTUtils.checkWhichTeamNewPlayerWillJoin(getRabbitTeamSize(), getTurtleTeamSize());
    }
    
    function getGameInfo() public view returns(uint256[8] memory) {
        uint256 turtleCounter = 0;
        uint256 rabbitCounter = 0;
        uint256 aliveTurtleCounter = 0;
        uint256 aliveRabbitCounter = 0;
        uint256 deadTurtleCounter = 0;
        uint256 deadRabbitCounter = 0;
        uint256 revivedTurtleCounter = 0;
        uint256 revivedRabbitCounter = 0;
        for(uint256 i = 0; i < totalSupply()+1; i++) {
            RVTUtils.Player memory player = players[i];
                if(RVTUtils.compareStrings(player.playerType,"Turtle")) {
                    turtleCounter++;
                    if(player.alive) {
                        aliveTurtleCounter++;
                    } else {
                        deadTurtleCounter++;
                    }
                    if(player.revived) {
                        revivedTurtleCounter++;
                    }
                }else if(RVTUtils.compareStrings(player.playerType,"Rabbit")) {
                    rabbitCounter++;
                    if(player.alive) {
                        aliveRabbitCounter++;
                    } else {
                        deadRabbitCounter++;
                    }
                    if(player.revived) {
                        revivedRabbitCounter++;
                    }
                }
        }
        return [turtleCounter, rabbitCounter, aliveTurtleCounter, aliveRabbitCounter, deadTurtleCounter, deadRabbitCounter, revivedTurtleCounter, revivedRabbitCounter];
    }
    
    function getTurtleTeamSize() public view returns(uint256) {
        uint256 turtleCounter = 0;
        for(uint256 i = 0; i < totalSupply()+1; i++) {
            RVTUtils.Player memory player = players[i];
                if(RVTUtils.compareStrings(player.playerType,"Turtle")) {
                    turtleCounter++;
                }
        }
        return turtleCounter;
    }

    function getRabbitTeamSize() public view returns(uint256) {
        uint256 rabbitCounter = 0;
        for(uint256 i = 0; i < totalSupply()+1; i++) {
            RVTUtils.Player memory player = players[i];
            if(RVTUtils.compareStrings(player.playerType,"Rabbit")) {
                rabbitCounter++;
            }
        }
        return rabbitCounter;
    }

  function getPlayerType(uint256 _tokenId) public view returns(string memory) {
    require(_exists(_tokenId),"ERC721Metadata: Query for nonexistent token");
    RVTUtils.Player memory player = players[_tokenId];
    return player.playerType;
  }

  function attackPlayer(uint256 _attackerId, uint256 _attackedId) public {
    require(_exists(_attackerId),"ERC721Metadata: Query for nonexistent token");
    require(_exists(_attackedId),"ERC721Metadata: Query for nonexistent token");
    require(ownerOf(_attackerId) == msg.sender,"You are not the owner's of the attacker Player");
    require(isAlive(_attackedId),"Attacked player Id is already dead");
    require(isAlive(_attackerId),"Attacker player Id is already dead");
    require(!(keccak256(bytes(getPlayerType(_attackerId))) == keccak256(bytes(getPlayerType(_attackedId)))),"You cannot attack your own team");
    RVTUtils.Player storage attacker = players[_attackerId];
    RVTUtils.Player storage attacked = players[_attackedId];
    require(attacker.attack > attacked.defense && attacker.defense > attacked.attack,"You cannot attack because you are not strong enough");
    attacked.alive = false;
    attacker.kills = attacker.kills + 1;
    emit Attacked(_attackerId, _attackedId);
  }

  function increaseAttack(uint256 _tokenId) payable public {
    require(_exists(_tokenId),"ERC721Metadata: Query for nonexistent token");
    require(isAlive(_tokenId),"Dead player Id cannot increase attack");
    if (msg.sender != owner()) {
        require(msg.value >= increaseAttackCost, "You don't have enough money to increase attack");
    }
    RVTUtils.Player storage player = players[_tokenId];
    player.attack = player.attack + 5;
    emit AttackIncreased(_tokenId);
  }

  function increaseDefense(uint256 _tokenId) payable public {
    require(_exists(_tokenId),"ERC721Metadata: Query for nonexistent token");
    require(isAlive(_tokenId),"Dead player Id cannot increase defense");
    if (msg.sender != owner()) {
        require(msg.value >= increaseDefenseCost, "You don't have enough money to increase defense");
    }
    RVTUtils.Player storage player = players[_tokenId];
    player.defense = player.defense + 5;
    emit DefenseIncreased(_tokenId);
  }
  
    function increaseStamina(uint256 _tokenId) payable public {
    require(_exists(_tokenId),"ERC721Metadata: Query for nonexistent token");
    require(isAlive(_tokenId),"Dead player Id cannot increase stamina");
    if (msg.sender != owner()) {
        require(msg.value >= increaseStaminaCost, "You don't have enough money to increase stamina");
    }
    RVTUtils.Player storage player = players[_tokenId];
    player.attack = player.attack + 20;
    emit StaminaIncreased(_tokenId);
  }

  function increaseArmor(uint256 _tokenId) payable public {
    require(_exists(_tokenId),"ERC721Metadata: Query for nonexistent token");
    require(isAlive(_tokenId),"Dead player Id cannot increase armor");
    if (msg.sender != owner()) {
        require(msg.value >= increaseArmorCost, "You don't have enough money to increase armor");
    }
    RVTUtils.Player storage player = players[_tokenId];
    player.defense = player.defense + 20;
    emit ArmorIncreased(_tokenId);
  }

  function revivePlayer(uint256 _tokenId) payable public {
    require(_exists(_tokenId),"ERC721Metadata: Query for nonexistent token");
    require(!isAlive(_tokenId),"Player Id is already alive");
    require(ownerOf(_tokenId) == msg.sender,"You are not the owner's of the revived Player");
    if (msg.sender != owner()) {
        require(msg.value >= revivePlayerCost, "You don't have enough money to revive player");
    }
    RVTUtils.Player storage player = players[_tokenId];
    require(player.revived == false,"Player has already revived once, every player can only revive once");
    player.alive = true;
    player.revived = true;
    emit Revived(_tokenId);
  }

  function isAlive(uint256 _tokenId) public view returns(bool) {
    require(_exists(_tokenId),"ERC721Metadata: Query for nonexistent token");
    RVTUtils.Player memory player = players[_tokenId];
    return player.alive;
  }
  
  function buildImage(uint256 _tokenId) public view returns(string memory) {
    RVTUtils.Player memory currentPlayer = players[_tokenId];
    if(RVTUtils.compareStrings(currentPlayer.playerType, "Rabbit")) {
        return Base64.encode(Rabbit.RabbitString(currentPlayer, _tokenId));
    }else{
        return Base64.encode(Turtle.TurtleString(currentPlayer, _tokenId));
    }
  }
  
  function buildMetadata(uint256 _tokenId) public view returns(string memory) {
      RVTUtils.Player memory currentPlayer = players[_tokenId];
      return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          currentPlayer.name,
                          '", "description":"', 
                          currentPlayer.description,
                          '", "image": "', 
                          'data:image/svg+xml;base64,', 
                          buildImage(_tokenId),
                          '"}')))));
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
    return buildMetadata(_tokenId);
  }

  function setMintCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }
  
  function setIncreaseAttackCost(uint256 _newCost) public onlyOwner() {
    increaseAttackCost = _newCost;
  }
  
  function setIncreaseDefenseCost(uint256 _newCost) public onlyOwner() {
    increaseDefenseCost = _newCost;
  }

  function setArmorCost(uint256 _newCost) public onlyOwner() {
    increaseArmorCost = _newCost;
  }
  
  function setStaminaCost(uint256 _newCost) public onlyOwner() {
    increaseStaminaCost = _newCost;
  }

  function setReviveCost(uint256 _newCost) public onlyOwner() {
    revivePlayerCost = _newCost;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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
pragma solidity ^0.8.0;

library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT

import "./Turtle1.sol";
import "./Turtle2.sol";
import "./Turtle3.sol";
import "./TurtleHelper.sol";
import "./TurtleHelper2.sol";
import "./RVTUtils.sol";
import "./TurtleColorsHelper.sol";
import "./TurtleDeadHelper.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

pragma solidity >=0.8.0 <0.9.0;

library Turtle {
    using Strings for uint256;
    function TurtleString(RVTUtils.Player memory _player, uint256 _tokenId) public view returns (bytes memory) {
        RVTUtils.Player memory player = _player;
        if(player.alive){
            return bytes(
            abi.encodePacked(
                Turtle1.TurtleString(),
                TurtleHelper.TurtleString(),
                TurtleHelper2.TurtleString(),
                TurtleColorsHelper.TurtleString(player.colors),
                Turtle2.TurtleString(),
                Turtle3.TurtleString(player.attack.toString(), player.defense.toString(), player.kills, player.revived, _tokenId.toString(), player.mintTimestamp)
            ));
        }else{
            return bytes(
            abi.encodePacked(
                Turtle1.TurtleString(),
                TurtleHelper.TurtleString(),
                TurtleHelper2.TurtleString(),
                TurtleDeadHelper.TurtleString(player.attack.toString(), player.defense.toString(), player.kills, player.revived, _tokenId.toString(), player.mintTimestamp)
            ));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Rabbit1.sol";
import "./RabbitHelper.sol";
import "./Rabbit2.sol";
import "./Rabbit3.sol";
import "./Rabbit4.sol";
import "./RVTUtils.sol";
import "./RabbitColorsHelper.sol";
import "./RabbitDeadHelper.sol";
import "./RabbitDeadHelper2.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


library Rabbit {
    using Strings for uint256;
    function RabbitString(RVTUtils.Player memory _player, uint256 _tokenId) public view returns (bytes memory) {
        RVTUtils.Player memory player = _player;
        if(player.alive){
            return bytes(
            abi.encodePacked(
                Rabbit1.RabbitString(),
                RabbitHelper.RabbitString(),
                RabbitColorsHelper.RabbitString(player.colors),
                Rabbit2.RabbitString(),
                Rabbit3.RabbitString(),
                Rabbit4.RabbitString(player.attack.toString(), player.defense.toString(), player.kills, player.revived, _tokenId.toString(), player.mintTimestamp)
            ));
        }else {
            return bytes(
            abi.encodePacked(
                Rabbit1.RabbitString(),
                RabbitHelper.RabbitString(),
                RabbitDeadHelper.RabbitString(),
                RabbitDeadHelper2.RabbitString(player.attack.toString(), player.defense.toString(), player.kills, player.revived, _tokenId.toString(), player.mintTimestamp)
            ));
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library RVTUtils {
   using Strings for uint256;

    struct Player { 
      string name;
      string playerType;
      string description;
      string[] colors;
      bool alive;
      uint256 mintTimestamp;
      uint256 attack;
      uint256 defense;
      uint256 kills;
      bool revived;
   }
  
  function randomNum(uint256 _mod, uint256 _seed, uint _salt) public view returns(uint256) {
      uint256 num = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)));
      num = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt, num))) % _mod;
      return num;
  }
  
  function randomNumStartingAt(uint256 startingAt, uint256 _mod, uint256 _seed, uint _salt) public view returns(uint256) {
      uint256 num = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)));
      num = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt, num))) % _mod;
      return num + startingAt;
  }

  function generateArrayOfRandomNumbers(uint256 _mod, uint256 _seed, uint _salt, uint256 _length) public view returns(string[] memory) {
      string[] memory nums = new string[](_length); 
      for (uint256 i = 0; i < _length; i++) {
          nums[i] = randomNum(_mod, _seed, _salt + i).toString();
      }
      return nums;
  }
  
  function compareStrings(string memory _string1, string memory _string2) internal pure returns(bool) {
      return keccak256(bytes(_string1)) == keccak256(bytes(_string2));
  }
  
  function checkWhichTeamNewPlayerWillJoin(uint256 rabbitCounter, uint256 turtleCounter) public pure returns(string memory) {
      if(rabbitCounter > turtleCounter) {
            return "Turtle";
      } else if(rabbitCounter < turtleCounter) {
            return "Rabbit";
      } else {
            return "Turtle";
      }
    
   }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Turtle1 {
    function TurtleString() public pure returns (string memory) {
        string memory image = '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="-400 -450 2850 2850" xml:space="preserve"> <style type="text/css"> @font-face { font-family: "myFont"; src: url(data:application/font-woff2;charset=utf-8;base64,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';
        return image;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Turtle2 {
    function TurtleString() public pure returns (string memory) {
        string memory image = '<rect fill="url(#grad1)" x="-400" y="-500" width="2850" height="3000"/> <g> <path class="st1" d="M1463.84,1787.06c-10.46-29.65-28.49-55.23-40.11-84.3c48.83,0,98.25,0,147.08,0 c18.02,0,36.04,1.74,53.48-3.49c-38.95-48.83-84.3-93.02-122.66-142.43c-15.7-49.41-25.58-100.57-39.53-150.57 c-8.14-21.51,7.56-41.28,13.95-61.62c-6.98-9.88-13.37-20.35-19.77-30.23c71.51-83.13,143.01-165.68,214.52-248.82 c7.56-8.14,5.81-19.77,7.56-29.65c6.98-145.34,15.7-290.09,23.25-435.43c-1.16-8.14,4.07-13.37,10.46-16.28 c77.9-41.86,155.8-81.39,233.12-123.83c0-61.04,0.58-121.5-0.58-181.96c-115.11-22.67-230.21-43.6-344.74-65.69 c-41.86,40.69-80.81,83.71-121.5,124.99c-5.81,6.98-15.11,12.79-13.95,22.67c7.56,133.71,16.28,267.42,24.42,401.13 c-12.79,13.37-25.58,26.74-40.11,38.95c1.74-10.46,3.49-20.93,5.23-31.39c-81.39-23.84-163.36-45.93-244.75-69.18 c-84.88-22.09-169.17-48.83-254.63-69.18c-173.82,40.69-347.06,84.88-521.47,126.73c-9.88,2.91-21.51,3.49-27.9,13.37 c-93.02,115.69-186.03,230.79-279.05,346.48c20.35,44.76,43.02,88.36,63.95,133.13c-44.18,53.48-92.43,103.48-135.45,158.13 c7.56,2.33,15.11,2.91,22.67,2.33c61.04-4.65,122.66-10.46,183.71-15.11c11.05,23.25,21.51,46.51,35.46,68.02 c-44.76,47.09-88.36,95.34-132.55,143.59c-8.72,8.14,2.91,18.6,5.81,26.74c18.6,28.49,31.39,61.04,52.9,87.78 c63.37,1.74,126.73-1.16,190.1,0.58c22.09,16.28,38.37,39.53,60.46,55.81c107.55,2.33,215.1,0.58,322.65,1.16 c-1.74-8.72-3.49-17.44-6.98-25.58c-25.58-62.79-51.74-125.57-77.32-188.36c73.25,0,146.5,1.16,219.75-0.58 c61.04-13.37,120.92-30.81,182.54-43.6c-11.05,28.49-25.58,55.23-37.79,83.13c-7.56,13.37,4.07,26.74,8.14,39.53 c20.93,47.67,40.69,95.92,62.2,143.01C1252.23,1787.64,1358.04,1786.48,1463.84,1787.06z M1444.08,1773.69 c-91.27,2.33-183.12,1.16-274.4,0c63.95-53.48,127.31-106.97,192.43-158.71C1391.17,1666.72,1418.5,1720.2,1444.08,1773.69z M436.6,1471.97c-40.69-8.14-82.55-12.79-122.66-24.42c27.9-25,57.55-48.83,88.95-69.18c13.95,2.91,26.74,11.05,38.95,18.02 c38.37,22.09,77.32,42.44,116.27,63.95c26.16,15.12,55.23,26.16,79.06,45.93C569.73,1500.45,503.46,1483.01,436.6,1471.97z M488.92,1494.64c-33.14,54.65-66.27,109.87-101.74,163.36c-0.58-60.46-0.58-120.92-0.58-180.8 C421.49,1479.53,455.21,1487.08,488.92,1494.64z M425.56,1373.14c77.32-16.28,155.8-26.74,233.12-40.69 c89.53-14.53,179.05-31.39,269.16-44.76c-52.9,55.81-111.04,105.8-166.27,159.29c-24.42,23.25-48.83,46.51-74.41,68.02 C598.8,1469.64,512.18,1421.97,425.56,1373.14z M746.46,1156.3c61.62,39.53,124.41,75.57,184.87,116.27 c-144.17,26.74-288.93,48.83-433.1,74.41c-22.67,3.49-44.76,6.98-67.44,8.72c84.3-71.51,172.66-138.36,258.12-208.7 c6.4-4.07,12.21-12.21,20.93-11.63C723.21,1140.6,734.83,1148.74,746.46,1156.3z M722.63,1124.32 c197.08-94.76,394.73-187.19,592.39-280.79c30.81-14.53,59.88-32.56,93.02-40.69c-43.6,50.58-94.18,95.34-140.69,144.17 c-93.6,92.43-183.12,188.94-276.14,281.37c-12.79,12.79-23.84,26.74-38.95,36.62c-13.37-0.58-24.42-11.05-36.04-16.86 C851.68,1207.46,785.41,1167.92,722.63,1124.32z M845.29,1385.35c21.51-20.93,43.02-42.44,65.69-62.2 c20.93-18.02,38.95-41.28,66.27-50c97.08-31.39,192.43-69.18,290.67-97.67c-158.13,96.5-319.16,188.36-478.45,282.53 c-12.21,7.56-25.58,14.53-38.95,20.35C777.27,1442.9,813.9,1416.16,845.29,1385.35z M1221.42,1224.32 c51.74,1.74,102.9,5.23,154.64,9.3c-32.56,36.04-66.85,70.34-101.74,104.06C1255.14,1300.47,1238.28,1262.68,1221.42,1224.32z M1263.86,1348.14c-31.39,26.16-62.78,51.74-94.76,76.74c11.63-62.79,28.49-124.99,43.02-187.19 C1232.47,1273.15,1249.32,1310.35,1263.86,1348.14z M1390.59,1238.27c22.09,33.72,45.93,65.69,65.69,100.57 c-55.23,1.74-111.04,3.49-166.27,2.91C1321.41,1305.7,1356.87,1272.57,1390.59,1238.27z M1419.08,1256.29 c-8.14-11.05-16.28-22.09-23.84-33.14c-52.32-6.39-105.22-4.07-156.96-12.79c29.65-22.67,64.53-37.79,95.34-58.13 c12.21-7.56,13.95-23.25,18.6-35.46c25,2.91,49.41,9.88,73.25,18.02C1425.47,1175.48,1420.24,1215.6,1419.08,1256.29z M1091.2,1294.08c36.04-20.35,70.92-43.02,108.13-61.04c-15.11,66.85-27.32,134.29-47.67,199.98c-30.23-9.3-59.3-23.25-88.36-35.46 c-27.32-11.63-56.39-20.93-81.97-36.62C1016.2,1336.51,1054.57,1316.75,1091.2,1294.08z M1269.09,1360.35 c15.12,33.14,23.84,68.02,37.79,101.74c13.37,38.95,30.23,76.74,39.53,116.85c-31.39-17.44-57.55-43.02-86.62-63.37 c-30.23-25-62.2-47.09-91.27-72.67C1201.07,1414.42,1234.21,1386.51,1269.09,1360.35z M1478.37,1566.73 c-22.09,33.14-48.25,63.95-76.16,92.43c-11.63-16.86-22.67-34.88-27.9-54.65c-1.16-13.95,7.56-25.58,12.79-37.21 C1417.91,1564.98,1448.14,1564.98,1478.37,1566.73z M1392.34,1553.36c8.14-21.51,16.28-43.02,25-64.53 c23.84,18.02,42.44,41.86,61.62,64.53C1449.89,1555.68,1420.82,1555.68,1392.34,1553.36z M1600.46,1691.14 c-61.62,1.16-123.24,1.74-184.87-0.58c-2.33-5.23-5.23-10.46-6.98-15.7c27.9-35.46,56.39-70.92,87.2-104.06 C1531.28,1610.33,1567.9,1649.28,1600.46,1691.14z M1482.44,1535.34c-19.18-17.44-37.79-35.46-52.9-56.39 c-5.81-5.81-1.74-13.95,0.58-20.35c5.81-15.7,13.37-30.81,21.51-45.34C1462.1,1453.95,1473.72,1494.06,1482.44,1535.34z M1458.03,1353.37c-15.7,48.25-37.79,93.6-55.81,141.27c-13.37,29.07-22.09,60.46-38.37,88.36 c-27.32-75.57-54.65-151.73-81.97-227.31C1340.6,1353.96,1399.31,1351.05,1458.03,1353.37z M1616.73,1110.37 c-56.39,63.37-110.46,129.06-167.43,192.43c-8.72-12.21-20.35-24.42-18.02-40.69c1.74-42.44,4.07-84.88,7.56-127.31 c33.14-12.21,67.44-20.35,101.15-31.39c34.3-9.88,68.02-23.25,104.06-29.65C1635.92,1087.12,1626.62,1099.33,1616.73,1110.37z M1666.73,1035.38c-56.39-88.36-108.13-179.64-163.36-268.58c28.49-30.81,62.2-55.81,93.02-84.29 c30.81-26.16,59.88-55.23,92.43-79.64C1684.17,747.03,1673.13,891.2,1666.73,1035.38z M1510.35,740.64 c19.18-77.32,47.67-152.31,69.18-228.47c12.79,4.07,23.84,12.21,34.88,20.35c23.25,18.6,49.41,34.3,72.67,53.48 C1628.36,637.74,1570.81,691.22,1510.35,740.64z M1698.12,577.28c-33.72-23.25-68.6-45.93-99.41-73.25 c66.27-8.14,132.55-16.86,198.82-23.25c33.72-3.49,66.27-9.88,99.99-9.3C1831.83,508.1,1764.98,542.4,1698.12,577.28z M1592.9,490.08c31.39-56.39,65.69-111.04,100.57-165.68c44.76,22.09,86.62,49.41,130.8,73.83c30.23,18.6,62.2,33.72,91.27,54.65 C1808,466.82,1700.45,480.19,1592.9,490.08z M1932.41,444.73c-46.51-23.25-90.69-51.74-136.04-76.74 c-27.32-16.86-57.55-30.23-81.97-50.58c72.67-8.72,145.34-19.18,218.59-26.74C1934.15,341.83,1934.15,393.57,1932.41,444.73z M1812.65,265.1c26.74,5.23,54.07,8.14,79.64,17.44c-65.69,8.72-131.97,17.44-198.82,25c-25.58-26.16-50.58-52.9-74.99-79.64 C1683.01,240.68,1747.54,252.31,1812.65,265.1z M1601.04,228.47c26.16,26.16,51.74,52.9,76.16,80.81 c-62.2,13.37-124.41,25.58-187.77,34.88C1525.46,304.63,1563.25,266.26,1601.04,228.47z M1677.19,323.81 c-31.97,55.23-65.11,109.87-99.99,163.36c-32.56-41.86-66.85-83.13-94.76-128.48C1547.55,347.65,1611.5,333.11,1677.19,323.81z M1478.37,377.29c22.09,26.74,41.28,55.81,62.79,82.55c9.88,13.37,21.51,26.16,28.49,41.28c-4.07,26.16-15.11,50.58-22.09,75.57 c-16.86,50-29.65,101.74-49.41,151.15C1492.91,611,1481.86,494.15,1478.37,377.29z M1497.56,784.24 c23.83,30.81,41.28,66.27,62.78,99.41c32.56,56.97,69.18,111.04,99.41,168.59c-36.62,14.53-74.99,23.84-112.2,35.46 c-35.46,10.46-69.76,23.84-105.8,30.81C1458.03,1006.89,1480.12,895.86,1497.56,784.24z M1483.03,790.05 c-14.53,111.04-37.21,220.91-54.07,331.95c-25-4.65-49.41-10.46-72.09-22.09c23.84-83.71,51.16-166.26,74.99-249.98 C1438.84,823.77,1458.61,802.26,1483.03,790.05z M1366.76,1023.75c-11.63,37.79-21.51,76.74-36.04,113.94 c-62.79,23.84-126.73,44.18-189.52,66.85c-52.9,17.44-104.64,39.53-158.71,52.9c41.28-48.83,88.95-90.69,132.55-137.2 c84.3-86.04,168.59-172.66,254.05-257.54c20.35-20.35,39.53-42.44,62.2-60.46C1413.85,877.25,1388.85,949.92,1366.76,1023.75z M960.4,642.97c127.9,35.46,255.79,71.51,383.69,106.97c27.9,7.56,56.39,14.53,83.71,24.42c-23.84,15.12-49.41,25-74.41,37.21 c-201.15,95.92-402.29,191.26-603.44,286.02c-8.14,3.49-16.28,6.39-25,9.88c9.3-26.16,23.25-50,35.46-74.41 c55.23-107.55,109.87-215.68,164.52-323.81C936.56,687.15,945.86,663.9,960.4,642.97z M942.96,645.3 c-76.74,156.38-157.54,310.44-235.44,466.24c-15.7-12.79-27.32-29.07-40.11-44.76c-79.64-98.25-161.03-195.91-240.68-294.74 C598.22,727.85,770.88,687.15,942.96,645.3z M218.6,1020.84c65.69-80.81,129.64-162.78,196.49-242.42 c93.6,112.2,186.03,225.56,277.88,338.92c-181.96,0.58-364.5-3.49-546.46-4.07C168.02,1080.72,195.34,1051.66,218.6,1020.84z M408.12,1127.81c93.02,1.16,186.03,0.58,279.63,2.33c-31.97,30.23-68.02,55.81-101.74,83.71 c-61.04,48.25-120.34,98.83-182.54,145.92c-75.58-68.02-149.41-137.78-224.4-206.38c-8.72-8.14-16.86-16.86-24.42-26.16 C238.95,1123.74,323.82,1127.23,408.12,1127.81z M80.82,1396.98c21.51-29.65,47.09-55.23,70.92-83.13 c15.12-16.86,27.9-36.04,47.09-48.25c-7.56,41.86-23.84,82.55-37.79,122.66C136.05,1398.72,107.56,1395.23,80.82,1396.98z M175,1390c9.88-33.14,20.93-66.27,31.97-98.83c18.02,29.07,33.14,60.46,45.93,92.43C226.74,1387.09,201.16,1388.84,175,1390z M207.55,1258.61c-16.28-35.46-37.21-69.18-49.41-106.39c67.44,59.88,133.13,122.08,199.98,183.12 c12.21,10.46,24.42,20.93,33.14,34.88c-30.81,23.84-61.04,48.25-94.18,69.76C264.53,1381.28,237.2,1319.07,207.55,1258.61z M314.52,1462.67c19.77,2.33,39.53,5.81,59.3,9.88c0.58,12.21,5.81,30.23-10.46,34.88c-54.65,27.32-108.13,56.39-163.94,80.81 C236.62,1545.22,273.83,1502.2,314.52,1462.67z M373.24,1594.05c-56.97,4.07-113.36,9.88-170.33,10.46 c55.23-31.97,113.36-59.3,170.92-87.2C374.4,1542.89,374.4,1568.47,373.24,1594.05z M176.16,1619.05 c66.27-2.91,132.55-10.46,199.4-10.46c-1.74,8.72,1.16,20.93-9.88,24.42c-45.93,25.58-91.85,50.58-138.36,74.41 C207.55,1679.51,191.86,1649.28,176.16,1619.05z M254.64,1709.16c37.79-24.42,77.9-44.76,118.01-64.53 c2.91,16.28-1.16,35.46,11.05,48.25c4.65,5.81,9.3,11.05,13.95,16.86C349.98,1710.9,302.31,1711.48,254.64,1709.16z M396.49,1686.49c62.2-9.3,124.41-13.37,187.19-21.51c35.46-2.91,70.92-9.88,106.39-8.72c-12.21,9.3-25.58,16.86-39.53,23.25 c-58.13,27.9-114.53,58.72-173.24,86.04C448.23,1741.13,421.49,1714.97,396.49,1686.49z M780.18,1767.29 c-91.27,0.58-183.12,1.16-274.98-0.58c74.99-39.53,151.73-76.74,228.47-114.53C749.95,1689.97,765.65,1728.34,780.18,1767.29z M395.33,1673.7c11.05-26.16,27.9-49.41,42.44-73.25c22.09-34.3,42.44-69.18,64.53-103.48c33.72,7.56,74.41,3.49,99.99,30.81 c38.95,37.79,81.39,72.67,119.76,111.04C613.33,1649.86,504.62,1662.65,395.33,1673.7z M716.23,1611.49 c-15.11-9.88-29.65-21.51-42.44-33.72c-20.35-20.35-43.6-37.79-62.79-59.3c25,1.74,50,5.23,73.83,12.79 C695.88,1557.43,707.51,1584.17,716.23,1611.49z M705.18,1552.78c-2.33-8.72-4.65-18.02-6.39-27.32 c20.35-12.79,41.86-26.16,63.95-37.21c43.6,21.51,89.53,38.37,130.22,64.53C830.17,1555.68,767.39,1555.68,705.18,1552.78z M924.93,1551.03c-49.41-22.09-97.67-45.34-145.92-69.18c23.84-22.09,54.65-34.3,81.39-51.74c33.14-17.44,63.37-38.95,96.5-56.39 c9.3-5.81,19.18,1.74,28.49,4.65c-5.23,22.67-13.37,44.76-22.09,66.27C949.93,1480.11,940.05,1516.73,924.93,1551.03z M1062.71,1520.8c-40.69,8.72-80.23,22.09-121.5,27.9c15.7-55.23,38.37-108.71,56.97-163.94c50,17.44,98.25,41.28,148.24,60.46 c-5.81,20.35-13.37,40.69-26.16,58.72C1102.24,1513.24,1081.9,1515.57,1062.71,1520.8z M1159.22,1453.95 c52.32,36.04,100.57,77.32,151.15,115.11c12.21,8.72,24.42,18.6,35.46,29.07c-85.46,4.65-171.5,8.14-256.95,8.72 C1111.55,1555.1,1134.8,1504.52,1159.22,1453.95z M1181.31,1616.14c54.65-2.91,109.29-4.65,163.36-4.65 c-33.72,30.23-70.34,57.55-104.64,87.2c-29.65,23.25-56.39,49.41-87.2,70.34c-24.42-47.67-43.6-98.25-64.53-147.66 C1119.1,1616.14,1150.5,1617.89,1181.31,1616.14z"/> <path class="st2" d="M1601.04,228.47c-37.79,37.79-75.58,76.16-111.62,115.69c63.37-9.3,125.57-21.51,187.77-34.88 C1652.78,281.37,1627.2,254.63,1601.04,228.47z"/> <path class="st3" d="M1892.29,282.54c-25.58-9.3-52.9-12.21-79.64-17.44c-65.11-12.79-129.64-24.42-194.17-37.21 c24.42,26.74,49.41,53.48,74.99,79.64C1760.33,299.98,1826.6,291.26,1892.29,282.54z"/> <path class="st4" d="M1796.37,367.99c45.34,25,89.53,53.48,136.04,76.74c1.74-51.16,1.74-102.9,0.58-154.06 c-73.25,7.56-145.92,18.02-218.59,26.74C1738.82,337.76,1769.05,351.13,1796.37,367.99z"/> <path class="st5" d="M1677.19,323.81c-65.69,9.3-129.64,23.84-194.75,34.88c27.9,45.35,62.2,86.62,94.76,128.48 C1612.08,433.69,1645.22,379.04,1677.19,323.81z"/> <path class="st6" d="M1693.47,324.39c-34.88,54.65-69.18,109.29-100.57,165.68c107.55-9.88,215.1-23.25,322.65-37.21 c-29.07-20.93-61.04-36.04-91.27-54.65C1780.09,373.81,1738.24,346.48,1693.47,324.39z"/> <path class="st7" d="M1547.55,576.7c6.98-25,18.02-49.41,22.09-75.57c-6.98-15.11-18.6-27.9-28.49-41.28 c-21.51-26.74-40.69-55.81-62.79-82.55c3.49,116.85,14.53,233.7,19.77,350.55C1517.91,678.43,1530.7,626.69,1547.55,576.7z"/> <path class="st8" d="M1598.71,504.03c30.81,27.32,65.69,50,99.41,73.25c66.85-34.88,133.71-69.18,199.4-105.8 c-33.72-0.58-66.27,5.81-99.99,9.3C1731.26,487.17,1664.99,495.89,1598.71,504.03z"/> <path class="st9" d="M1614.41,532.51c-11.05-8.14-22.09-16.28-34.88-20.35c-21.51,76.16-50,151.15-69.18,228.47 c60.46-49.41,118.01-102.9,176.73-154.64C1663.82,566.81,1637.66,551.12,1614.41,532.51z"/>';
        return image;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library Turtle3 {
    using Strings for uint256;
    function TurtleString(string memory attack, string memory defense, uint256 kills, bool revived, string memory tokenId, uint256 mintTimestamp) public view returns (string memory) {
        string memory _daysAlive = calculateDaysAlive(mintTimestamp).toString();
        string memory _level = calculatePlayerLevel(mintTimestamp, kills).toString();
        string memory _revived = revivedToString(revived);
        string memory image1 = '<path class="st10" d="M1503.37,766.8c55.23,88.95,106.97,180.22,163.36,268.58c6.39-144.17,17.44-288.35,22.09-432.52 c-32.56,24.42-61.62,53.48-92.43,79.64C1565.58,710.99,1531.86,735.99,1503.37,766.8z"/> <path class="st11" d="M707.51,1111.53c77.9-155.8,158.71-309.86,235.44-466.24c-172.08,41.86-344.74,82.55-516.23,126.73 c79.64,98.83,161.03,196.49,240.68,294.74C680.19,1082.47,691.81,1098.74,707.51,1111.53z"/> <path class="st12" d="M760.41,1033.05c-12.21,24.42-26.16,48.25-35.46,74.41c8.72-3.49,16.86-6.4,25-9.88 c201.15-94.76,402.29-190.1,603.44-286.02c25-12.21,50.58-22.09,74.41-37.21c-27.32-9.88-55.81-16.86-83.71-24.42 c-127.9-35.46-255.79-71.51-383.69-106.97c-14.53,20.93-23.84,44.18-35.46,66.27C870.29,817.37,815.64,925.5,760.41,1033.05z"/> <path class="st13" d="M692.98,1117.35c-91.85-113.36-184.29-226.72-277.88-338.92c-66.85,79.64-130.8,161.61-196.49,242.42 c-23.25,30.81-50.58,59.88-72.09,92.43C328.47,1113.86,511.02,1117.93,692.98,1117.35z"/> <path class="st14" d="M1547.55,1087.7c37.21-11.63,75.57-20.93,112.2-35.46c-30.23-57.55-66.85-111.62-99.41-168.59 c-21.51-33.14-38.95-68.6-62.78-99.41c-17.44,111.62-39.53,222.66-55.81,334.27C1477.79,1111.53,1512.09,1098.16,1547.55,1087.7z" /> <path class="st15" d="M1428.96,1122c16.86-111.04,39.53-220.91,54.07-331.95c-24.42,12.21-44.18,33.72-51.16,59.88 c-23.84,83.71-51.16,166.27-74.99,249.98C1379.55,1111.53,1403.96,1117.35,1428.96,1122z"/> <path class="st16" d="M952.26,1265.01c15.11-9.88,26.16-23.84,38.95-36.62c93.02-92.43,182.54-188.94,276.14-281.37 c46.51-48.83,97.08-93.6,140.69-144.17c-33.14,8.14-62.2,26.16-93.02,40.69c-197.66,93.6-395.31,186.03-592.39,280.79 c62.79,43.6,129.06,83.13,193.59,123.83C927.84,1253.96,938.89,1264.43,952.26,1265.01z"/> <path class="st17" d="M1369.08,862.72c-85.46,84.88-169.75,171.5-254.05,257.54c-43.6,46.51-91.27,88.36-132.55,137.2 c54.07-13.37,105.81-35.46,158.71-52.9c62.79-22.67,126.73-43.02,189.52-66.85c14.53-37.21,24.42-76.16,36.04-113.94 c22.09-73.83,47.09-146.5,64.53-221.49C1408.61,820.28,1389.43,842.37,1369.08,862.72z"/> <path class="st18" d="M1438.84,1134.79c-3.49,42.44-5.81,84.88-7.56,127.31c-2.33,16.28,9.3,28.49,18.02,40.69 c56.97-63.37,111.04-129.06,167.43-192.43c9.88-11.05,19.18-23.25,27.32-36.62c-36.04,6.4-69.76,19.77-104.06,29.65 C1506.28,1114.44,1471.98,1122.58,1438.84,1134.79z"/> <path class="st19" d="M1333.62,1152.23c-30.81,20.35-65.69,35.46-95.34,58.13c51.74,8.72,104.64,6.4,156.96,12.79 c7.56,11.05,15.7,22.09,23.84,33.14c1.16-40.69,6.39-80.81,6.39-121.5c-23.84-8.14-48.25-15.11-73.25-18.02 C1347.57,1128.97,1345.83,1144.67,1333.62,1152.23z"/> <path class="st6" d="M403.47,1359.77c62.2-47.09,121.5-97.67,182.54-145.92c33.72-27.9,69.76-53.48,101.74-83.71 c-93.6-1.74-186.61-1.16-279.63-2.33c-84.3-0.58-169.17-4.07-253.47-0.58c7.56,9.3,15.7,18.02,24.42,26.16 C254.06,1221.99,327.89,1291.75,403.47,1359.77z"/> <path class="st20" d="M688.91,1147c-85.46,70.34-173.82,137.2-258.12,208.7c22.67-1.74,44.76-5.23,67.44-8.72 c144.17-25.58,288.93-47.67,433.1-74.41c-60.46-40.69-123.25-76.74-184.87-116.27c-11.63-7.56-23.25-15.7-36.62-20.93 C701.12,1134.79,695.3,1142.93,688.91,1147z"/> <path class="st21" d="M391.26,1370.23c-8.72-13.95-20.93-24.42-33.14-34.88c-66.85-61.04-132.55-123.24-199.98-183.12 c12.21,37.21,33.14,70.92,49.41,106.39c29.65,60.46,56.97,122.66,89.53,181.38C330.22,1418.48,360.45,1394.07,391.26,1370.23z"/> <path class="st22" d="M1267.93,1175.48c-98.25,28.49-193.59,66.27-290.67,97.67c-27.32,8.72-45.35,31.97-66.27,50 c-22.67,19.77-44.18,41.28-65.69,62.2c-31.39,30.81-68.02,57.55-94.76,93.02c13.37-5.81,26.74-12.79,38.95-20.35 C948.77,1363.84,1109.8,1271.99,1267.93,1175.48z"/> <path class="st47" d="M1376.06,1233.62c-51.74-4.07-102.9-7.56-154.64-9.3c16.86,38.37,33.72,76.16,52.9,113.36 C1309.2,1303.96,1343.5,1269.66,1376.06,1233.62z"/> <path class="st23" d="M1151.66,1433.02c20.35-65.69,32.56-133.13,47.67-199.98c-37.21,18.02-72.09,40.69-108.13,61.04 c-36.62,22.67-74.99,42.44-109.87,66.85c25.58,15.7,54.65,25,81.97,36.62C1092.36,1409.76,1121.43,1423.72,1151.66,1433.02z"/> <path class="st24" d="M1169.1,1424.88c31.97-25,63.37-50.58,94.76-76.74c-14.53-37.79-31.39-74.99-51.74-110.46 C1197.58,1299.89,1180.73,1362.09,1169.1,1424.88z"/> <path class="st25" d="M1456.28,1338.84c-19.77-34.88-43.6-66.85-65.69-100.57c-33.72,34.3-69.18,67.44-100.57,103.48 C1345.25,1342.33,1401.06,1340.58,1456.28,1338.84z"/> <path class="st26" d="M151.74,1313.84c-23.84,27.9-49.41,53.48-70.92,83.13c26.74-1.74,55.23,1.74,80.23-8.72 c13.95-40.11,30.23-80.81,37.79-122.66C179.65,1277.8,166.86,1296.98,151.74,1313.84z"/> <path class="st27" d="M761.58,1446.97c55.23-53.48,113.36-103.48,166.27-159.29c-90.11,13.37-179.64,30.23-269.16,44.76 c-77.32,13.95-155.8,24.42-233.12,40.69c86.62,48.83,173.24,96.5,261.61,141.85C712.74,1493.48,737.16,1470.22,761.58,1446.97z"/> <path class="st28" d="M175,1390c26.16-1.16,51.74-2.91,77.9-6.39c-12.79-31.97-27.9-63.37-45.93-92.43 C195.93,1323.73,184.88,1356.86,175,1390z"/> <path class="st29" d="M1281.88,1355.7c27.32,75.57,54.65,151.73,81.97,227.31c16.28-27.9,25-59.3,38.37-88.36 c18.02-47.67,40.11-93.02,55.81-141.27C1399.31,1351.05,1340.6,1353.96,1281.88,1355.7z"/> <path class="st30" d="M1346.41,1578.94c-9.3-40.11-26.16-77.9-39.53-116.85c-13.95-33.72-22.67-68.6-37.79-101.74 c-34.88,26.16-68.02,54.07-100.57,82.55c29.07,25.58,61.04,47.67,91.27,72.67C1288.86,1535.92,1315.02,1561.5,1346.41,1578.94z"/> <path class="st31" d="M985.39,1378.37c-9.3-2.91-19.18-10.46-28.49-4.65c-33.14,17.44-63.37,38.95-96.5,56.39 c-26.74,17.44-57.55,29.65-81.39,51.74c48.25,23.84,96.5,47.09,145.92,69.18c15.11-34.3,25-70.92,38.37-106.39 C972.02,1423.14,980.16,1401.04,985.39,1378.37z"/> <path class="st32" d="M558.1,1460.34c-38.95-21.51-77.9-41.86-116.27-63.95c-12.21-6.98-25-15.11-38.95-18.02 c-31.39,20.35-61.04,44.18-88.95,69.18c40.11,11.63,81.97,16.28,122.66,24.42c66.85,11.05,133.13,28.49,200.56,34.3 C613.33,1486.5,584.27,1475.46,558.1,1460.34z"/> <path class="st19" d="M1146.43,1445.23c-50-19.18-98.25-43.02-148.24-60.46c-18.6,55.23-41.28,108.71-56.97,163.94 c41.28-5.81,80.81-19.18,121.5-27.9c19.18-5.23,39.53-7.56,57.55-16.86C1133.06,1485.92,1140.61,1465.57,1146.43,1445.23z"/> <path class="st23" d="M1430.12,1458.6c-2.33,6.4-6.39,14.53-0.58,20.35c15.11,20.93,33.72,38.95,52.9,56.39 c-8.72-41.28-20.35-81.39-30.81-122.08C1443.49,1427.79,1435.94,1442.9,1430.12,1458.6z"/> <path class="st33" d="M1310.37,1569.05c-50.58-37.79-98.83-79.06-151.15-115.11c-24.42,50.58-47.67,101.15-70.34,152.89 c85.46-0.58,171.5-4.07,256.95-8.72C1334.78,1587.66,1322.57,1577.77,1310.37,1569.05z"/> <path class="st34" d="M373.82,1472.55c-19.77-4.07-39.53-7.56-59.3-9.88c-40.69,39.53-77.9,82.55-115.11,125.57 c55.81-24.42,109.29-53.48,163.94-80.81C379.63,1502.78,374.4,1484.76,373.82,1472.55z"/> <path class="st35" d="M387.19,1658c35.46-53.48,68.6-108.71,101.74-163.36c-33.72-7.56-67.44-15.11-102.32-17.44 C386.61,1537.08,386.61,1597.54,387.19,1658z"/> <path class="st36" d="M698.79,1525.45c1.74,9.3,4.07,18.6,6.39,27.32c62.2,2.91,124.99,2.91,187.77,0 c-40.69-26.16-86.62-43.02-130.22-64.53C740.65,1499.29,719.14,1512.66,698.79,1525.45z"/> <path class="st37" d="M1478.96,1553.36c-19.18-22.67-37.79-46.51-61.62-64.53c-8.72,21.51-16.86,43.02-25,64.53 C1420.82,1555.68,1449.89,1555.68,1478.96,1553.36z"/> <path class="st38" d="M502.3,1496.97c-22.09,34.3-42.44,69.18-64.53,103.48c-14.53,23.83-31.39,47.09-42.44,73.25 c109.29-11.05,218-23.84,326.72-34.88c-38.37-38.37-80.81-73.25-119.76-111.04C576.71,1500.45,536.01,1504.52,502.3,1496.97z"/> <path class="st39" d="M373.24,1594.05c1.16-25.58,1.16-51.16,0.58-76.74c-57.55,27.9-115.69,55.23-170.92,87.2 C259.87,1603.93,316.27,1598.12,373.24,1594.05z"/> <path class="st40" d="M611.01,1518.48c19.18,21.51,42.44,38.95,62.79,59.3c12.79,12.21,27.32,23.84,42.44,33.72 c-8.72-27.32-20.35-54.07-31.39-80.23C661,1523.71,636.01,1520.22,611.01,1518.48z"/> <path class="st41" d="M1374.31,1604.52c5.23,19.77,16.28,37.79,27.9,54.65c27.9-28.49,54.07-59.3,76.16-92.43 c-30.23-1.74-60.46-1.74-91.27,0.58C1381.87,1578.94,1373.15,1590.56,1374.31,1604.52z"/> <path class="st42" d="M1415.59,1690.55c61.62,2.33,123.25,1.74,184.87,0.58c-32.56-41.86-69.18-80.81-104.64-120.34 c-30.81,33.14-59.3,68.6-87.2,104.06C1410.36,1680.09,1413.26,1685.32,1415.59,1690.55z"/> <path class="st43" d="M375.56,1608.58c-66.85,0-133.13,7.56-199.4,10.46c15.7,30.23,31.39,60.46,51.16,88.36 c46.51-23.84,92.43-48.83,138.36-74.41C376.72,1629.51,373.82,1617.3,375.56,1608.58z"/> <path class="st36" d="M1240.02,1698.69c34.3-29.65,70.92-56.97,104.64-87.2c-54.07,0-108.71,1.74-163.36,4.65 c-30.81,1.74-62.2,0-93.02,5.23c20.93,49.41,40.11,99.99,64.53,147.66C1183.63,1748.11,1210.37,1721.95,1240.02,1698.69z"/> <path class="st44" d="M1169.68,1773.69c91.27,1.16,183.12,2.33,274.4,0c-25.58-53.48-52.9-106.97-81.97-158.71 C1296.99,1666.72,1233.63,1720.2,1169.68,1773.69z"/> <path class="st45" d="M372.66,1644.63c-40.11,19.77-80.23,40.11-118.01,64.53c47.67,2.33,95.34,1.74,143.01,0.58 c-4.65-5.81-9.3-11.05-13.95-16.86C371.49,1680.09,375.56,1660.91,372.66,1644.63z"/> <path class="st6" d="M780.18,1767.29c-14.53-38.95-30.23-77.32-46.51-115.11c-76.74,37.79-153.48,74.99-228.47,114.53 C597.05,1768.46,688.91,1767.87,780.18,1767.29z"/> <path class="st46" d="M690.07,1656.26c-35.46-1.16-70.92,5.81-106.39,8.72c-62.79,8.14-124.99,12.21-187.19,21.51 c25,28.49,51.74,54.65,80.81,79.06c58.72-27.32,115.11-58.13,173.24-86.04C664.49,1673.11,677.86,1665.56,690.07,1656.26z"/> </g> ';
        string memory image2 = string(abi.encodePacked('<text fill="#ffffff" x="-310" y="2180" class="small">Attack: ',attack,' &#9876;</text> <text fill="#ffffff" x="-310" y="2300" class="small">Defense: ',defense,' &#128737;</text> <text fill="#ffffff" x="-310" y="-255" class="small">Alive: ',_daysAlive,' Days &#9200;</text> '));
        string memory image3 = string(abi.encodePacked('<text fill="#ffffff" x="-310" y="-145" class="small">Level: ',_level,' &#127894;</text> <text fill="#ffffff" x="900" y="-300" class="small"># ',tokenId,'</text> <text fill="#ffffff" x="1840" y="-260" class="small">Revived: ',_revived,' </text> <text fill="#ffffff" x="715" y="2300" class="small">Kills Count: ',kills.toString(),' &#128128;</text> <text fill="#ffffff" x="1840" y="2300" class="small">Team Turtle &#129388;</text> </svg>'));
        string memory result = string(abi.encodePacked(image1, image2, image3));
        return result;
    }

    function calculateDaysAlive(uint256 timestamp) internal view returns(uint256) {
        return (((block.timestamp - timestamp) / 86400)+1);
    }

    function calculatePlayerLevel(uint256 timestamp, uint256 kills) internal view returns(uint256) {
        return calculateDaysAlive(timestamp)/10 + kills/2;
    }

    function revivedToString(bool revived) internal pure returns(string memory) {
        if (revived) {
            return "Yes &#128519;";
        } else {
            return "No &#128512;";
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library TurtleHelper {
    function TurtleString() public pure returns (string memory) {
        string memory image = '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) format("woff2"), url(data:application/font-woff;charset=utf-8;base64,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';
        return image;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library TurtleHelper2 {
    function TurtleString() public pure returns (string memory) {
        string memory image = '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) format("woff"); font-weight: normal; font-style: normal; }';
        return image;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library TurtleColorsHelper {
    function TurtleString(string[] memory colors) public pure returns (string memory) {
        string memory image1 = string(abi.encodePacked('.small { font: 71px myFont , Times New Roman , Times ; } .st0{fill:hsl(360, 100%, 65%);stroke:#BAE6FB;stroke-width:0.0938;stroke-miterlimit:10;} .st1{fill:#010101;} .st2{fill:hsl(',colors[0],', 90%, 70%);stroke:#9E95C9;stroke-width:0.0938;stroke-miterlimit:10;} .st3{fill:hsl(',colors[1],', 50%, 50%);stroke-width:0.0938;stroke-miterlimit:10;} .st4{fill:hsl(',colors[2],', 50%, 50%);stroke-width:0.0938;stroke-miterlimit:10;} .st5{fill:hsl(',colors[3],', 50%, 50%);stroke:#91C8EC;stroke-width:0.0938;stroke-miterlimit:10;} '));
        string memory image2 = string(abi.encodePacked('.st6{fill:hsl(',colors[4],', 45%, 36%);stroke:#E8742F;stroke-width:0.0938;stroke-miterlimit:10;} .st7{fill:hsl(',colors[5],', 30%, 50%);stroke:#5D9ED4;stroke-width:0.0938;stroke-miterlimit:10;} .st8{fill:hsl(',colors[6],', 75%, 65%);stroke:#DD2427;stroke-width:0.0938;stroke-miterlimit:10;} .st9{fill:hsl(',colors[7],', 90%, 70%);stroke:#74CAC4;stroke-width:0.0938;stroke-miterlimit:10;} '));
        string memory image3 = string(abi.encodePacked('.st10{fill:hsl(',colors[8],', 46%, 37%);stroke:#FFC858;stroke-width:0.0938;stroke-miterlimit:10;} .st11{fill:hsl(',colors[9],', 31%, 51%);stroke:#B2E0E4;stroke-width:0.0938;stroke-miterlimit:10;} .st12{fill:hsl(',colors[10],', 75%, 65%);stroke:#89C759;stroke-width:0.0938;stroke-miterlimit:10;} .st13{fill:hsl(',colors[11],', 90%, 70%);stroke:#D4C828;stroke-width:0.0938;stroke-miterlimit:10;} '));
        string memory image4 = string(abi.encodePacked('.st14{fill:hsl(',colors[12],', 47%, 38%);stroke:#B3AA35;stroke-width:0.0938;stroke-miterlimit:10;} .st15{fill:hsl(',colors[13],', 32%, 52%);stroke:#347338;stroke-width:0.0938;stroke-miterlimit:10;} .st16{fill:hsl(',colors[14],', 75%, 65%);stroke:#347439;stroke-width:0.0938;stroke-miterlimit:10;} .st17{fill:hsl(',colors[15],', 90%, 70%);stroke:#1B4F83;stroke-width:0.0938;stroke-miterlimit:10;} '));
        string memory image5 = string(abi.encodePacked('.st18{fill:hsl(',colors[16],', 48%, 39%);stroke:#CB4F28;stroke-width:0.0938;stroke-miterlimit:10;} .st19{fill:hsl(',colors[17],', 33%, 53%);stroke:#A22575;stroke-width:0.0938;stroke-miterlimit:10;} .st20{fill:hsl(',colors[18],', 75%, 65%);stroke:#B21E56;stroke-width:0.0938;stroke-miterlimit:10;} .st21{fill:hsl(',colors[19],', 90%, 70%);stroke:#524C9F;stroke-width:0.0938;stroke-miterlimit:10;} '));
        string memory image6 = string(abi.encodePacked('.st22{fill:hsl(',colors[20],', 49%, 40%);stroke:#2D1A4D;stroke-width:0.0938;stroke-miterlimit:10;} .st23{fill:hsl(',colors[21],', 34%, 54%);stroke:#2E358C;stroke-width:0.0938;stroke-miterlimit:10;} .st24{fill:hsl(',colors[22],', 75%, 65%);stroke:#799ED3;stroke-width:0.0938;stroke-miterlimit:10;} .st25{fill:hsl(',colors[23],', 90%, 70%);stroke:#F490B3;stroke-width:0.0938;stroke-miterlimit:10;} '));
        string memory image7 = string(abi.encodePacked('.st26{fill:hsl(',colors[24],', 50%, 41%);stroke:#E5732D;stroke-width:0.0938;stroke-miterlimit:10;} .st27{fill:hsl(',colors[25],', 35%, 55%);stroke:#833286;stroke-width:0.0938;stroke-miterlimit:10;} .st28{fill:hsl(',colors[26],', 75%, 65%);stroke:#B62226;stroke-width:0.0938;stroke-miterlimit:10;} .st29{fill:hsl(',colors[27],', 90%, 70%);stroke:#EB584D;stroke-width:0.0938;stroke-miterlimit:10;} '));
        string memory image8 = string(abi.encodePacked('.st30{fill:hsl(',colors[28],', 90%, 30%);stroke:#7D75B6;stroke-width:0.0938;stroke-miterlimit:10;} .st31{fill:hsl(',colors[29],', 36%, 56%);stroke:#17488B;stroke-width:0.0938;stroke-miterlimit:10;} .st32{fill:hsl(',colors[30],', 75%, 65%);stroke:#2E358B;stroke-width:0.0938;stroke-miterlimit:10;} .st33{fill:hsl(',colors[31],', 90%, 70%);stroke:#4A7ABD;stroke-width:0.0938;stroke-miterlimit:10;} '));
        string memory image9 = string(abi.encodePacked('.st34{fill:hsl(',colors[32],', 90%, 30%);stroke:#306BAF;stroke-width:0.0938;stroke-miterlimit:10;} .st35{fill:hsl(',colors[33],', 37%, 57%);stroke:#D1C829;stroke-width:0.0938;stroke-miterlimit:10;} .st36{fill:hsl(',colors[34],', 75%, 65%);stroke:#2E63AE;stroke-width:0.0938;stroke-miterlimit:10;} .st37{fill:hsl(',colors[35],', 90%, 70%);stroke:#514A9E;stroke-width:0.0938;stroke-miterlimit:10;} '));
        string memory image10 = string(abi.encodePacked('.st38{fill:hsl(',colors[36],', 90%, 30%);stroke:#A3CD3A;stroke-width:0.0938;stroke-miterlimit:10;} .st39{fill:hsl(',colors[37],', 38%, 58%);stroke:#C33790;stroke-width:0.0938;stroke-miterlimit:10;} .st40{fill:hsl(',colors[38],', 75%, 65%);stroke:#596F31;stroke-width:0.0938;stroke-miterlimit:10;} .st41{fill:hsl(',colors[39],', 90%, 70%);stroke:#6C6228;stroke-width:0.0938;stroke-miterlimit:10;} '));
        string memory image11 = string(abi.encodePacked('.st42{fill:hsl(',colors[40],', 90%, 20%);stroke:#4985C5;stroke-width:0.0938;stroke-miterlimit:10;} .st43{fill:hsl(',colors[41],', 90%, 30%);troke:#5D9CD4;stroke-width:0.0938;stroke-miterlimit:10;} .st44{fill:hsl(',colors[42],', 75%, 65%);stroke:#C23691;stroke-width:0.0938;stroke-miterlimit:10;} .st45{fill:hsl(',colors[43],', 90%, 70%);stroke:#8C67AC;stroke-width:0.0938;stroke-miterlimit:10;} '));
        string memory image12 = string(abi.encodePacked('.st46{fill:hsl(',colors[44],', 90%, 20%);stroke:#4193B4;stroke-width:0.0938;stroke-miterlimit:10;} .st47{fill:hsl(',colors[45],', 90%, 30%);stroke:#4985C5;stroke-width:0.0938;stroke-miterlimit:10;} </style> <defs><linearGradient cx="0.25" cy="0.25" r="0.75" id="grad1" gradientTransform="rotate(50)"> <stop offset="0%" stop-color="hsl(360, 50%, 50%)"/> <stop offset="50%" stop-color="hsl(350, 50%, 60%)"/> <stop offset="100%" stop-color="hsl(340, 50%, 50%)"/> </linearGradient> </defs>'));
        string memory result1 = string(abi.encodePacked(image1,image2,image3,image4,image5,image6,image7));
        string memory result2 = string(abi.encodePacked(image8,image9,image10,image11,image12));
        string memory result = string(abi.encodePacked(result1,result2));
        return result;

    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library TurtleDeadHelper {
    using Strings for uint256;
    function TurtleString(string memory attack, string memory defense, uint256 kills, bool revived, string memory tokenId, uint256 mintTimestamp) public view returns (string memory) {
        string memory _level = calculatePlayerLevel(mintTimestamp, kills).toString();
        string memory _revived = revivedToString(revived);
        string memory image1 = '.small { font: 71px myFont , Times New Roman , Times ; } .big { font: 75px myFont , Times New Roman , Times ; } .st0{fill:#d0d4d7;} </style> <rect class="st0" x="-400" y="-500" width="2850" height="3000"/> <g> <text x="650" y="-140" class="big" fill="#b90e16">Player Eliminated &#128565;</text> <path class="st1" d="M1463.84,1787.06c-10.46-29.65-28.49-55.23-40.11-84.3c48.83,0,98.25,0,147.08,0 c18.02,0,36.04,1.74,53.48-3.49c-38.95-48.83-84.3-93.02-122.66-142.43c-15.7-49.41-25.58-100.57-39.53-150.57 c-8.14-21.51,7.56-41.28,13.95-61.62c-6.98-9.88-13.37-20.35-19.77-30.23c71.51-83.13,143.01-165.68,214.52-248.82 c7.56-8.14,5.81-19.77,7.56-29.65c6.98-145.34,15.7-290.09,23.25-435.43c-1.16-8.14,4.07-13.37,10.46-16.28 c77.9-41.86,155.8-81.39,233.12-123.83c0-61.04,0.58-121.5-0.58-181.96c-115.11-22.67-230.21-43.6-344.74-65.69 c-41.86,40.69-80.81,83.71-121.5,124.99c-5.81,6.98-15.11,12.79-13.95,22.67c7.56,133.71,16.28,267.42,24.42,401.13 c-12.79,13.37-25.58,26.74-40.11,38.95c1.74-10.46,3.49-20.93,5.23-31.39c-81.39-23.84-163.36-45.93-244.75-69.18 c-84.88-22.09-169.17-48.83-254.63-69.18c-173.82,40.69-347.06,84.88-521.47,126.73c-9.88,2.91-21.51,3.49-27.9,13.37 c-93.02,115.69-186.03,230.79-279.05,346.48c20.35,44.76,43.02,88.36,63.95,133.13c-44.18,53.48-92.43,103.48-135.45,158.13 c7.56,2.33,15.11,2.91,22.67,2.33c61.04-4.65,122.66-10.46,183.71-15.11c11.05,23.25,21.51,46.51,35.46,68.02 c-44.76,47.09-88.36,95.34-132.55,143.59c-8.72,8.14,2.91,18.6,5.81,26.74c18.6,28.49,31.39,61.04,52.9,87.78 c63.37,1.74,126.73-1.16,190.1,0.58c22.09,16.28,38.37,39.53,60.46,55.81c107.55,2.33,215.1,0.58,322.65,1.16 c-1.74-8.72-3.49-17.44-6.98-25.58c-25.58-62.79-51.74-125.57-77.32-188.36c73.25,0,146.5,1.16,219.75-0.58 c61.04-13.37,120.92-30.81,182.54-43.6c-11.05,28.49-25.58,55.23-37.79,83.13c-7.56,13.37,4.07,26.74,8.14,39.53 c20.93,47.67,40.69,95.92,62.2,143.01C1252.23,1787.64,1358.04,1786.48,1463.84,1787.06z M1444.08,1773.69 c-91.27,2.33-183.12,1.16-274.4,0c63.95-53.48,127.31-106.97,192.43-158.71C1391.17,1666.72,1418.5,1720.2,1444.08,1773.69z M436.6,1471.97c-40.69-8.14-82.55-12.79-122.66-24.42c27.9-25,57.55-48.83,88.95-69.18c13.95,2.91,26.74,11.05,38.95,18.02 c38.37,22.09,77.32,42.44,116.27,63.95c26.16,15.12,55.23,26.16,79.06,45.93C569.73,1500.45,503.46,1483.01,436.6,1471.97z M488.92,1494.64c-33.14,54.65-66.27,109.87-101.74,163.36c-0.58-60.46-0.58-120.92-0.58-180.8 C421.49,1479.53,455.21,1487.08,488.92,1494.64z M425.56,1373.14c77.32-16.28,155.8-26.74,233.12-40.69 c89.53-14.53,179.05-31.39,269.16-44.76c-52.9,55.81-111.04,105.8-166.27,159.29c-24.42,23.25-48.83,46.51-74.41,68.02 C598.8,1469.64,512.18,1421.97,425.56,1373.14z M746.46,1156.3c61.62,39.53,124.41,75.57,184.87,116.27 c-144.17,26.74-288.93,48.83-433.1,74.41c-22.67,3.49-44.76,6.98-67.44,8.72c84.3-71.51,172.66-138.36,258.12-208.7 c6.4-4.07,12.21-12.21,20.93-11.63C723.21,1140.6,734.83,1148.74,746.46,1156.3z M722.63,1124.32 c197.08-94.76,394.73-187.19,592.39-280.79c30.81-14.53,59.88-32.56,93.02-40.69c-43.6,50.58-94.18,95.34-140.69,144.17 c-93.6,92.43-183.12,188.94-276.14,281.37c-12.79,12.79-23.84,26.74-38.95,36.62c-13.37-0.58-24.42-11.05-36.04-16.86 C851.68,1207.46,785.41,1167.92,722.63,1124.32z M845.29,1385.35c21.51-20.93,43.02-42.44,65.69-62.2 c20.93-18.02,38.95-41.28,66.27-50c97.08-31.39,192.43-69.18,290.67-97.67c-158.13,96.5-319.16,188.36-478.45,282.53 c-12.21,7.56-25.58,14.53-38.95,20.35C777.27,1442.9,813.9,1416.16,845.29,1385.35z M1221.42,1224.32 c51.74,1.74,102.9,5.23,154.64,9.3c-32.56,36.04-66.85,70.34-101.74,104.06C1255.14,1300.47,1238.28,1262.68,1221.42,1224.32z M1263.86,1348.14c-31.39,26.16-62.78,51.74-94.76,76.74c11.63-62.79,28.49-124.99,43.02-187.19 C1232.47,1273.15,1249.32,1310.35,1263.86,1348.14z M1390.59,1238.27c22.09,33.72,45.93,65.69,65.69,100.57 c-55.23,1.74-111.04,3.49-166.27,2.91C1321.41,1305.7,1356.87,1272.57,1390.59,1238.27z M1419.08,1256.29 c-8.14-11.05-16.28-22.09-23.84-33.14c-52.32-6.39-105.22-4.07-156.96-12.79c29.65-22.67,64.53-37.79,95.34-58.13 c12.21-7.56,13.95-23.25,18.6-35.46c25,2.91,49.41,9.88,73.25,18.02C1425.47,1175.48,1420.24,1215.6,1419.08,1256.29z M1091.2,1294.08c36.04-20.35,70.92-43.02,108.13-61.04c-15.11,66.85-27.32,134.29-47.67,199.98c-30.23-9.3-59.3-23.25-88.36-35.46 c-27.32-11.63-56.39-20.93-81.97-36.62C1016.2,1336.51,1054.57,1316.75,1091.2,1294.08z M1269.09,1360.35 c15.12,33.14,23.84,68.02,37.79,101.74c13.37,38.95,30.23,76.74,39.53,116.85c-31.39-17.44-57.55-43.02-86.62-63.37 c-30.23-25-62.2-47.09-91.27-72.67C1201.07,1414.42,1234.21,1386.51,1269.09,1360.35z M1478.37,1566.73 c-22.09,33.14-48.25,63.95-76.16,92.43c-11.63-16.86-22.67-34.88-27.9-54.65c-1.16-13.95,7.56-25.58,12.79-37.21 C1417.91,1564.98,1448.14,1564.98,1478.37,1566.73z M1392.34,1553.36c8.14-21.51,16.28-43.02,25-64.53 c23.84,18.02,42.44,41.86,61.62,64.53C1449.89,1555.68,1420.82,1555.68,1392.34,1553.36z M1600.46,1691.14 c-61.62,1.16-123.24,1.74-184.87-0.58c-2.33-5.23-5.23-10.46-6.98-15.7c27.9-35.46,56.39-70.92,87.2-104.06 C1531.28,1610.33,1567.9,1649.28,1600.46,1691.14z M1482.44,1535.34c-19.18-17.44-37.79-35.46-52.9-56.39 c-5.81-5.81-1.74-13.95,0.58-20.35c5.81-15.7,13.37-30.81,21.51-45.34C1462.1,1453.95,1473.72,1494.06,1482.44,1535.34z M1458.03,1353.37c-15.7,48.25-37.79,93.6-55.81,141.27c-13.37,29.07-22.09,60.46-38.37,88.36 c-27.32-75.57-54.65-151.73-81.97-227.31C1340.6,1353.96,1399.31,1351.05,1458.03,1353.37z M1616.73,1110.37 c-56.39,63.37-110.46,129.06-167.43,192.43c-8.72-12.21-20.35-24.42-18.02-40.69c1.74-42.44,4.07-84.88,7.56-127.31 c33.14-12.21,67.44-20.35,101.15-31.39c34.3-9.88,68.02-23.25,104.06-29.65C1635.92,1087.12,1626.62,1099.33,1616.73,1110.37z M1666.73,1035.38c-56.39-88.36-108.13-179.64-163.36-268.58c28.49-30.81,62.2-55.81,93.02-84.29 c30.81-26.16,59.88-55.23,92.43-79.64C1684.17,747.03,1673.13,891.2,1666.73,1035.38z M1510.35,740.64 c19.18-77.32,47.67-152.31,69.18-228.47c12.79,4.07,23.84,12.21,34.88,20.35c23.25,18.6,49.41,34.3,72.67,53.48 C1628.36,637.74,1570.81,691.22,1510.35,740.64z M1698.12,577.28c-33.72-23.25-68.6-45.93-99.41-73.25 c66.27-8.14,132.55-16.86,198.82-23.25c33.72-3.49,66.27-9.88,99.99-9.3C1831.83,508.1,1764.98,542.4,1698.12,577.28z M1592.9,490.08c31.39-56.39,65.69-111.04,100.57-165.68c44.76,22.09,86.62,49.41,130.8,73.83c30.23,18.6,62.2,33.72,91.27,54.65 C1808,466.82,1700.45,480.19,1592.9,490.08z M1932.41,444.73c-46.51-23.25-90.69-51.74-136.04-76.74 c-27.32-16.86-57.55-30.23-81.97-50.58c72.67-8.72,145.34-19.18,218.59-26.74C1934.15,341.83,1934.15,393.57,1932.41,444.73z M1812.65,265.1c26.74,5.23,54.07,8.14,79.64,17.44c-65.69,8.72-131.97,17.44-198.82,25c-25.58-26.16-50.58-52.9-74.99-79.64 C1683.01,240.68,1747.54,252.31,1812.65,265.1z M1601.04,228.47c26.16,26.16,51.74,52.9,76.16,80.81 c-62.2,13.37-124.41,25.58-187.77,34.88C1525.46,304.63,1563.25,266.26,1601.04,228.47z M1677.19,323.81 c-31.97,55.23-65.11,109.87-99.99,163.36c-32.56-41.86-66.85-83.13-94.76-128.48C1547.55,347.65,1611.5,333.11,1677.19,323.81z M1478.37,377.29c22.09,26.74,41.28,55.81,62.79,82.55c9.88,13.37,21.51,26.16,28.49,41.28c-4.07,26.16-15.11,50.58-22.09,75.57 c-16.86,50-29.65,101.74-49.41,151.15C1492.91,611,1481.86,494.15,1478.37,377.29z M1497.56,784.24 c23.83,30.81,41.28,66.27,62.78,99.41c32.56,56.97,69.18,111.04,99.41,168.59c-36.62,14.53-74.99,23.84-112.2,35.46 c-35.46,10.46-69.76,23.84-105.8,30.81C1458.03,1006.89,1480.12,895.86,1497.56,784.24z M1483.03,790.05 c-14.53,111.04-37.21,220.91-54.07,331.95c-25-4.65-49.41-10.46-72.09-22.09c23.84-83.71,51.16-166.26,74.99-249.98 C1438.84,823.77,1458.61,802.26,1483.03,790.05z M1366.76,1023.75c-11.63,37.79-21.51,76.74-36.04,113.94 c-62.79,23.84-126.73,44.18-189.52,66.85c-52.9,17.44-104.64,39.53-158.71,52.9c41.28-48.83,88.95-90.69,132.55-137.2 c84.3-86.04,168.59-172.66,254.05-257.54c20.35-20.35,39.53-42.44,62.2-60.46C1413.85,877.25,1388.85,949.92,1366.76,1023.75z M960.4,642.97c127.9,35.46,255.79,71.51,383.69,106.97c27.9,7.56,56.39,14.53,83.71,24.42c-23.84,15.12-49.41,25-74.41,37.21 c-201.15,95.92-402.29,191.26-603.44,286.02c-8.14,3.49-16.28,6.39-25,9.88c9.3-26.16,23.25-50,35.46-74.41 c55.23-107.55,109.87-215.68,164.52-323.81C936.56,687.15,945.86,663.9,960.4,642.97z M942.96,645.3 c-76.74,156.38-157.54,310.44-235.44,466.24c-15.7-12.79-27.32-29.07-40.11-44.76c-79.64-98.25-161.03-195.91-240.68-294.74 C598.22,727.85,770.88,687.15,942.96,645.3z M218.6,1020.84c65.69-80.81,129.64-162.78,196.49-242.42 c93.6,112.2,186.03,225.56,277.88,338.92c-181.96,0.58-364.5-3.49-546.46-4.07C168.02,1080.72,195.34,1051.66,218.6,1020.84z M408.12,1127.81c93.02,1.16,186.03,0.58,279.63,2.33c-31.97,30.23-68.02,55.81-101.74,83.71 c-61.04,48.25-120.34,98.83-182.54,145.92c-75.58-68.02-149.41-137.78-224.4-206.38c-8.72-8.14-16.86-16.86-24.42-26.16 C238.95,1123.74,323.82,1127.23,408.12,1127.81z M80.82,1396.98c21.51-29.65,47.09-55.23,70.92-83.13 c15.12-16.86,27.9-36.04,47.09-48.25c-7.56,41.86-23.84,82.55-37.79,122.66C136.05,1398.72,107.56,1395.23,80.82,1396.98z M175,1390c9.88-33.14,20.93-66.27,31.97-98.83c18.02,29.07,33.14,60.46,45.93,92.43C226.74,1387.09,201.16,1388.84,175,1390z M207.55,1258.61c-16.28-35.46-37.21-69.18-49.41-106.39c67.44,59.88,133.13,122.08,199.98,183.12 c12.21,10.46,24.42,20.93,33.14,34.88c-30.81,23.84-61.04,48.25-94.18,69.76C264.53,1381.28,237.2,1319.07,207.55,1258.61z M314.52,1462.67c19.77,2.33,39.53,5.81,59.3,9.88c0.58,12.21,5.81,30.23-10.46,34.88c-54.65,27.32-108.13,56.39-163.94,80.81 C236.62,1545.22,273.83,1502.2,314.52,1462.67z M373.24,1594.05c-56.97,4.07-113.36,9.88-170.33,10.46 c55.23-31.97,113.36-59.3,170.92-87.2C374.4,1542.89,374.4,1568.47,373.24,1594.05z M176.16,1619.05 c66.27-2.91,132.55-10.46,199.4-10.46c-1.74,8.72,1.16,20.93-9.88,24.42c-45.93,25.58-91.85,50.58-138.36,74.41 C207.55,1679.51,191.86,1649.28,176.16,1619.05z M254.64,1709.16c37.79-24.42,77.9-44.76,118.01-64.53 c2.91,16.28-1.16,35.46,11.05,48.25c4.65,5.81,9.3,11.05,13.95,16.86C349.98,1710.9,302.31,1711.48,254.64,1709.16z M396.49,1686.49c62.2-9.3,124.41-13.37,187.19-21.51c35.46-2.91,70.92-9.88,106.39-8.72c-12.21,9.3-25.58,16.86-39.53,23.25 c-58.13,27.9-114.53,58.72-173.24,86.04C448.23,1741.13,421.49,1714.97,396.49,1686.49z M780.18,1767.29 c-91.27,0.58-183.12,1.16-274.98-0.58c74.99-39.53,151.73-76.74,228.47-114.53C749.95,1689.97,765.65,1728.34,780.18,1767.29z M395.33,1673.7c11.05-26.16,27.9-49.41,42.44-73.25c22.09-34.3,42.44-69.18,64.53-103.48c33.72,7.56,74.41,3.49,99.99,30.81 c38.95,37.79,81.39,72.67,119.76,111.04C613.33,1649.86,504.62,1662.65,395.33,1673.7z M716.23,1611.49 c-15.11-9.88-29.65-21.51-42.44-33.72c-20.35-20.35-43.6-37.79-62.79-59.3c25,1.74,50,5.23,73.83,12.79 C695.88,1557.43,707.51,1584.17,716.23,1611.49z M705.18,1552.78c-2.33-8.72-4.65-18.02-6.39-27.32 c20.35-12.79,41.86-26.16,63.95-37.21c43.6,21.51,89.53,38.37,130.22,64.53C830.17,1555.68,767.39,1555.68,705.18,1552.78z M924.93,1551.03c-49.41-22.09-97.67-45.34-145.92-69.18c23.84-22.09,54.65-34.3,81.39-51.74c33.14-17.44,63.37-38.95,96.5-56.39 c9.3-5.81,19.18,1.74,28.49,4.65c-5.23,22.67-13.37,44.76-22.09,66.27C949.93,1480.11,940.05,1516.73,924.93,1551.03z M1062.71,1520.8c-40.69,8.72-80.23,22.09-121.5,27.9c15.7-55.23,38.37-108.71,56.97-163.94c50,17.44,98.25,41.28,148.24,60.46 c-5.81,20.35-13.37,40.69-26.16,58.72C1102.24,1513.24,1081.9,1515.57,1062.71,1520.8z M1159.22,1453.95 c52.32,36.04,100.57,77.32,151.15,115.11c12.21,8.72,24.42,18.6,35.46,29.07c-85.46,4.65-171.5,8.14-256.95,8.72 C1111.55,1555.1,1134.8,1504.52,1159.22,1453.95z M1181.31,1616.14c54.65-2.91,109.29-4.65,163.36-4.65 c-33.72,30.23-70.34,57.55-104.64,87.2c-29.65,23.25-56.39,49.41-87.2,70.34c-24.42-47.67-43.6-98.25-64.53-147.66 C1119.1,1616.14,1150.5,1617.89,1181.31,1616.14z"/> </g>';
        string memory image2 = string(abi.encodePacked('<text x="-310" y="2180" class="small">Attack: ',attack,' &#9876;</text> <text x="-310" y="2300" class="small">Defense: ',defense,' &#128737;</text> <text x="-310" y="-255" class="small">Dead &#128123;</text> '));
        string memory image3 = string(abi.encodePacked('<text x="-310" y="-145" class="small">Level: ',_level,' &#127894;</text> <text x="900" y="-300" class="small"># ',tokenId,'</text> <text x="1840" y="-260" class="small">Revived: ',_revived,' </text> <text x="715" y="2300" class="small">Kills Count: ',kills.toString(),' &#128128;</text> <text x="1840" y="2300" class="small">Team Turtle &#129388;</text> </svg>'));
        string memory result = string(abi.encodePacked(image1, image2, image3));
        return result;
    }

    function calculateDaysAlive(uint256 timestamp) internal view returns(uint256) {
        return (((block.timestamp - timestamp) / 86400)+1);
    }

    function calculatePlayerLevel(uint256 timestamp, uint256 kills) internal view returns(uint256) {
        return calculateDaysAlive(timestamp)/10 + kills/2;
    }

    function revivedToString(bool revived) internal pure returns(string memory) {
        if (revived) {
            return "Yes &#128519;";
        } else {
            return "No &#128512;";
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Rabbit1 {
    function RabbitString() public pure returns (string memory) {
        string memory image = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="-500 -200 2000 2000" xml:space="preserve"> <style type="text/css"> @font-face { font-family: "myFont"; src: url(data:application/font-woff2;charset=utf-8;base64,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) format("woff2"),';
        return image;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library RabbitHelper {
    function RabbitString() public pure returns (string memory) {
        string memory image = 'url(data:application/font-woff;charset=utf-8;base64,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';
        return image;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Rabbit2 {
    function RabbitString() public pure returns (string memory) {
        string memory image = ' <rect fill="url(#grad1)" x="-500" y="-500" width="2000" height="2300"/> <g> <g> <g id="XMLID_1_"> <g> <path class="st1" d="M108.05,521.75c7.31-9.72,14.88-19.76,22.39-29.43c16.75-19.48,37.83-36.51,64.46-52.07 c24.46-14.29,50.57-25.63,75.16-35.75l0.01-0.01v-0.02c-0.79-19.41-2.08-39.21-3.32-58.35c-1.74-26.76-3.53-54.42-4.03-81.63 c-0.27-14.65-0.15-27.99,0.37-40.78c0.58-14.36,1.63-27.67,3.23-40.68c1.41-10.44,1.88-21.39,2.33-31.98 c0.75-17.68,1.52-35.97,6.67-52.83c16.91-11.45,34.73-22.18,51.96-32.56c6.38-3.84,12.97-7.81,19.32-11.7 c4.93,14.57,10.14,29.21,15.18,43.38c5.89,16.56,11.98,33.7,17.57,50.57c6.27,18.9,11.27,35.54,15.28,50.9 c-6.99,26.64-16.19,52.93-25.08,78.36c-5.57,15.9-11.32,32.34-16.44,48.63c-5.74,18.26-10.08,34.42-13.27,49.41l-0.02,0.12 l0.07-0.09c4.71-6.28,8.2-13.67,11.57-20.82c3.14-6.67,6.4-13.57,10.63-19.52c2.28-3.2,4.65-5.86,7.25-8.17 c2.92-2.58,6.05-4.63,9.58-6.28c62.93-38.9,126.09-80.27,187.17-120.28c19.08-12.5,38.8-25.41,58.25-38.08 c-3.34,17.96-9.11,35.28-14.68,52.02c-4.43,13.29-9.01,27.04-12.33,41c-1.11,4.43-2.25,9.01-3.94,13.14 c-1.89,4.62-4.29,8.18-7.31,10.88c-12.93,12.07-26.32,23.57-39.27,34.7c-9.57,8.22-19.46,16.72-29.05,25.35 c-7.4,7.02-16.17,13.5-26.79,19.84c-9.48,5.65-19.55,10.68-29.3,15.53c-14.23,7.09-28.95,14.43-42.24,23.93l-0.01,0.01 c-7.08,14.16-13.04,27-18.21,39.22c-6.07,14.37-10.92,27.56-14.82,40.35c-0.93,19.81,1.29,39.61,3.43,58.75 c1.35,12,2.74,24.41,3.32,36.6c0.25,7.23,1.95,14.65,5.21,22.65c2.9,7.13,6.74,14.07,10.45,20.77 c2.59,4.68,5.27,9.52,7.61,14.38l0.01,0.02h0.01c14.34,0.47,29.5-1.44,44.16-3.29c15.77-1.99,32.08-4.06,47.68-3.22 c8.4,0.45,15.91,1.69,22.96,3.77c7.92,2.34,15.05,5.69,21.81,10.24c15.16,8.62,31.17,16.55,46.67,24.21 c23.7,11.73,48.22,23.87,70.45,38.84c15.75,15.55,31.89,31.31,47.49,46.55C759.31,789,802.4,831.08,842.8,873.67 c20.15,38.18,38.72,77.74,56.68,116c7.46,15.88,15.17,32.31,22.89,48.39l0.02,0.05l0.02-0.05 c10.24-27.98,18.28-57.22,26.06-85.49c4.66-16.97,9.49-34.51,14.74-51.59c5.88-19.14,11.68-35.67,17.73-50.53 c15.35,33.96,29.48,69.34,43.15,103.57c8.37,20.97,17.04,42.66,25.88,63.77c-1.89,2.46-3.78,4.91-5.66,7.37 c-30.92,40.28-60.11,78.31-91.92,116.48c-7.48,4.4-16.06,8.23-26.22,11.71c-9.07,3.11-18.54,5.65-27.7,8.11 c-9.72,2.61-19.77,5.32-29.39,8.7l-0.01,0.01l-0.01,0.01l-69.81,135.12c-1.81,2.97-3.22,6.08-4.32,9.52 c-0.98,3.06-1.69,6.31-2.16,9.94c-0.88,6.73-0.8,13.74-0.72,20.52c0.06,5.39,0.12,10.96-0.3,16.31 c-39.58-2.1-79.82-3.08-118.73-4.01c-44.49-1.08-90.48-2.19-135.72-4.99c-12.65-6.85-23.91-16.75-34.81-26.33 c-4.56-4-9.27-8.14-13.96-11.94c3.75-6,7.76-11.91,11.63-17.63c3.87-5.71,7.87-11.63,11.63-17.62 c15.48,0.3,31.05,0.86,46.11,1.4c22.06,0.79,44.87,1.6,67.23,1.6h0.03l-0.01-0.03c-0.32-1.13-0.63-2.29-0.93-3.41 c-1.67-6.15-3.4-12.51-6.07-18.27c-1.43-3.1-3.01-5.77-4.82-8.17c-2.03-2.7-4.31-4.97-6.95-6.95 c-13.21-12.81-26.55-25.95-39.44-38.66c-35.48-34.97-72.16-71.14-110.69-104.71l-0.04-0.03l-0.01,0.04 c-3.2,19.91-4.98,40.48-6.69,60.37c-1.77,20.44-3.59,41.57-6.95,62.03c-1.81,11.01-3.92,20.95-6.42,30.39 c-2.81,10.59-6.07,20.28-9.96,29.62c-4.21,16.25-18.11,25.28-31.55,34c-3.25,2.11-6.61,4.29-9.73,6.52 c-19.18,15.98-43.14,12.64-66.32,9.41c-9.38-1.3-19.08-2.66-28.22-2.66c6.71-20.97,12.67-38.6,18.75-55.49 c14.76,2.95,30.01,6,45.02,8.25l0.02,0.01v-0.03c1.65-16.28,3.37-32.85,5.04-48.87c5.16-49.76,10.51-101.22,14.48-152.31 l0.01-0.06l-0.04,0.04c-5.61,4.49-12.37,8.49-19.51,12.72c-10.58,6.27-21.52,12.75-29.04,21.18c-4.06,4.56-6.75,9.25-8.24,14.35 c-0.8,2.76-1.24,5.69-1.31,8.68c-0.07,3.15,0.29,6.48,1.04,9.91l0.01,0.01l0.01,0.01c5.11,2.63,9.31,5.97,12.82,10.22 c3.12,3.76,5.63,8.14,7.65,13.39c3.76,9.71,5.2,20.76,6.6,31.44c0.44,3.38,0.9,6.88,1.42,10.21 c-23.03-2.98-45.78-8.09-69.01-13.51c-2.5-5-5.13-10.08-7.67-15c-5.08-9.84-10.34-20.02-14.85-30.03 c-2.13-9.09-3.22-18.06-3.47-26.96c-0.05-1.84-0.06-3.67-0.04-5.5c0.01-1.12,0.04-2.24,0.08-3.36c0-0.01,0-0.01,0-0.01 c0.21-5.75,0.74-11.46,1.56-17.13c0.16-1.14,0.34-2.27,0.52-3.4c0.09-0.57,0.19-1.13,0.29-1.7c0.1-0.57,0.2-1.13,0.3-1.69 c0.16-0.93,0.34-1.85,0.53-2.78c0.1-0.49,0.19-0.97,0.3-1.47c0.12-0.61,0.26-1.23,0.39-1.85c0.12-0.55,0.24-1.1,0.37-1.66 c5.23-23.17,14.57-46.05,24.69-69.11l0.01-0.02l-0.02-0.01c-12.75-8.39-26.5-15.75-39.8-22.87 c-18.87-10.1-38.38-20.54-55.53-34.18c-8.99-28.4-16-57.54-22.78-85.72c-3.96-16.47-8.06-33.51-12.5-50.14 c-2.92-8.17-5.02-16.57-6.42-25.67c-1.24-8.12-1.89-16.61-1.99-25.98c-0.17-17.4,1.67-35.24,3.44-52.5 c1.71-16.57,3.47-33.7,3.47-50.48v-0.01l-0.01-0.01c-8.46-5.19-17.7-9.77-26.63-14.2c-15.76-7.82-32.05-15.9-45.42-27.84 c-2.2-10.97-3.64-22.05-5.02-32.76c-0.98-7.51-1.99-15.29-3.23-22.76C81.11,557.53,94.81,539.33,108.05,521.75z M80.12,608.68 c1.57,1.15,3.23,1.81,4.92,1.97c0.26,0.02,0.52,0.04,0.78,0.04c1.28,0,2.56-0.29,3.81-0.87c1.93-0.9,3.73-2.49,5.05-4.49 c1.31-1.97,2.11-4.26,2.27-6.43c0.17-2.49-0.51-4.7-1.92-6.42c-0.12-0.14-0.24-0.28-0.37-0.41c-0.51-0.54-1.08-1.03-1.74-1.45 c-1.69-1.26-3.43-2.02-5.19-2.25c-1.6-0.21-3.18,0.01-4.7,0.67c-1.85,0.81-3.5,2.22-4.77,4.09c-1.25,1.83-2.03,3.94-2.25,6.08 c-0.19,1.81,0.04,3.6,0.67,5.16C77.37,606.1,78.53,607.55,80.12,608.68z M92.13,581.29c4.43,2.03,9.01,4.13,13.51,6.38 l0.02,0.01l0.01-0.03c2.53-9.01,5.43-18.17,8.23-27.03c4.67-14.76,9.5-30.03,12.78-45.04l0.02-0.09l-0.07,0.07 c-13.41,13.41-24.97,28.79-36.16,43.68c-3.86,5.13-7.85,10.45-11.88,15.63l-0.02,0.02l0.03,0.01 C83.12,577.16,87.7,579.26,92.13,581.29z M86.87,628.95c20.66,11.81,42.02,24.02,63.81,35.28l0.02,0.01l0.01-0.02 c9.76-15.02,19.52-30.03,29.28-45.05l0.02-0.02l-0.03-0.01c-2.92-0.91-5.85-1.81-8.77-2.69c-2.66-0.8-5.32-1.59-7.98-2.36 c-1.49-0.43-2.98-0.86-4.48-1.3c-2.41-0.69-4.81-1.37-7.2-2.05c-2.09-0.59-4.17-1.18-6.24-1.75c-0.33-0.09-0.67-0.18-1-0.27 c-1.74-0.49-3.48-0.97-5.22-1.45c-0.01,0-0.01,0-0.01,0c-2.91-0.8-5.82-1.6-8.7-2.39c-0.18-0.05-0.37-0.1-0.55-0.15 c-6.92-1.89-14.07-3.86-21.18-5.86l-0.02-0.01l-0.01,0.01c-8.03,11.61-15.16,21.43-21.77,30.03l-0.02,0.02L86.87,628.95z M116.93,580.91c17.65-10.22,34.99-21.47,51.76-32.35c10.32-6.69,20.98-13.61,31.57-20.19l0.01-0.01v-0.02 c-1.57-27.52-3.05-52.38-5.26-78.07l-0.01-0.05l-0.04,0.03c-4.4,3.35-9,6.65-13.45,9.84c-11.58,8.29-23.56,16.87-33.84,27.7 l-0.01,0.01c-9.04,22.61-16.46,46.73-23.63,70.06c-2.33,7.58-4.74,15.43-7.15,23.03l-0.02,0.07L116.93,580.91z M172.29,607.68 c3.76,1.07,7.64,2.17,11.43,3.25l0.02,0.01l0.01-0.02c5.16-22.88,10.51-46.54,14.26-70.57l0.01-0.05l-0.05,0.03 c-2,1.25-4.01,2.53-6.06,3.81c-0.6,0.38-1.21,0.76-1.81,1.15c-1.27,0.79-2.54,1.6-3.82,2.41c-3.18,2.02-6.41,4.07-9.66,6.15 c-1.63,1.04-3.26,2.08-4.9,3.14c0,0,0,0.01-0.01,0.01c-6.56,4.23-13.21,8.56-19.86,12.99c0,0,0,0-0.01,0.01 c-1.66,1.1-3.32,2.22-4.98,3.33c-9.13,6.14-18.21,12.44-26.96,18.8l-0.04,0.03l0.05,0.02 C137.14,597.71,155.01,602.78,172.29,607.68z M189.71,950.23l0.01,0.05l0.04-0.04c17.78-25.4,36.02-51.19,53.66-76.13 c50.25-71.03,102.21-144.48,150.52-218.89l0.05-0.08l-0.09,0.04c-21.2,10.89-42.34,22.23-63.32,33.8 c-11.3,6.22-22.55,12.51-33.75,18.81c-19.2,10.82-38.23,21.7-57.02,32.43c-4,2.28-8.01,4.58-12.05,6.89 c-3.23,1.85-6.48,3.7-9.73,5.55c-0.44,0.25-0.87,0.49-1.3,0.74c-3.62,2.06-7.25,4.13-10.89,6.2c-1.91,1.08-3.81,2.17-5.72,3.25 c-5.72,3.25-11.45,6.49-17.2,9.73c-11.49,6.47-23.01,12.9-34.48,19.22l-0.02,0.01l0.01,0.02 C160.35,838.9,174.59,894.54,189.71,950.23z M149.2,780.59c19.62-10.92,39.13-21.8,58.5-32.61c5.28-2.95,10.56-5.89,15.82-8.84 c9.36-5.23,18.68-10.44,27.97-15.64c7.36-4.12,14.7-8.23,22.01-12.33c8.17-4.58,16.31-9.15,24.43-13.7 c5.38-3.01,10.75-6.03,16.1-9.04c21.48-12.07,42.73-24.02,63.69-35.85c4.9-2.76,9.79-5.52,14.65-8.26 c5.54-3.13,11.06-6.25,16.56-9.36l0.02-0.02l-0.02-0.02c-3.33-4.17-5.66-9.51-7.9-14.68c-1.97-4.53-3.83-8.81-6.32-12.36 c-1.33-1.92-2.72-3.43-4.24-4.64c-1.71-1.35-3.53-2.28-5.58-2.86h-0.01h-0.01c-19.38,4.06-39.09,8.74-58.56,13.9 c-19.01,5.04-38.36,10.68-57.51,16.78c-18.66,5.94-37.67,12.49-56.52,19.46c-11.45,4.24-23.06,8.71-34.68,13.36 c-6.98,2.79-13.96,5.65-20.93,8.56l-0.01,0.01l-0.01,0.07c-0.44,5.33-0.89,10.69-1.33,16.07c-0.22,2.64-0.43,5.29-0.65,7.95 c-0.14,1.74-0.28,3.48-0.42,5.22c-1.55,19.26-2.99,38.71-4.07,58.1c-0.4,6.92-0.74,13.82-1.02,20.7v0.05L149.2,780.59z M165.72,658.98c24.88-8.06,49.44-17.63,75.07-29.28l0.08-0.04l-0.09-0.01c-1.73-0.3-3.45-0.6-5.16-0.9 c-0.5-0.09-0.99-0.18-1.49-0.26c-2.83-0.49-5.63-0.99-8.42-1.47c-2.47-0.43-4.91-0.85-7.36-1.26c-1.03-0.18-2.06-0.35-3.09-0.52 c-0.93-0.16-1.87-0.31-2.8-0.46c-7.51-1.24-15.02-2.38-22.72-3.39l-0.02-0.01l-0.01,0.02c-8.93,12.98-17.01,25.61-24.02,37.53 l-0.04,0.06L165.72,658.98z M192.73,613.19c7.59,1.05,15.19,2.2,22.55,3.32c13.68,2.08,27.83,4.23,42.01,5.69l0.02,0.01 l0.01-0.02c6.43-21.23,13.5-42.74,20.34-63.55c11.57-35.2,23.54-71.59,32.96-108.35l0.02-0.07l-0.06,0.04 c-33.6,25.02-69.03,52.52-100.6,84.08l-0.01,0.01c-4.71,16.03-8,32.95-11.19,49.3c-1.89,9.71-3.84,19.76-6.08,29.53l-0.01,0.03 H192.73z M203.23,966.01c28.9,16.89,58.66,33.87,87.45,50.29c28.79,16.42,58.56,33.4,87.46,50.29l0.04,0.02v-0.04 c0.44-13.64,1.87-27.66,3.26-41.21c1.67-16.4,3.41-33.35,3.43-49.94c0.01-8.93-0.46-17.03-1.44-24.77 c-1.11-8.68-2.82-16.69-5.24-24.47c-6.17-24.38-12.03-49.31-17.69-73.44c-7.42-31.61-15.08-64.29-23.6-96.21l-0.01-0.05 l-0.04,0.04l-55.4,79.28c-25.07,35.88-50.14,71.75-75.22,107.64c-0.57,0.92-1.33,2-2.14,3.14c-1.61,2.27-3.43,4.84-4.7,7.42 c-1.47,3.01-1.9,5.42-1.3,7.39C198.7,963.41,200.44,964.96,203.23,966.01z M209.22,520.08v0.05l0.04-0.03 c29.29-23.19,57.96-47.18,85.88-70.8c6.45-5.45,12.85-10.88,19.21-16.27l0.03-0.03l-0.04-0.02c-0.85-0.42-1.69-0.85-2.55-1.27 c-1.71-0.85-3.43-1.7-5.15-2.55c-4.32-2.12-8.67-4.24-12.94-6.32c-4.27-2.08-8.64-4.2-12.95-6.33c-1.72-0.85-3.45-1.7-5.15-2.55 c-0.85-0.42-1.7-0.85-2.55-1.27l-0.01-0.01l-0.01,0.01c-15.22,7.11-30.8,14.37-46.61,21.15c-7.19,3.08-14.43,6.06-21.7,8.87 l-0.02,0.01v0.02C204.72,469.03,207.11,496.16,209.22,520.08z M260.29,1148.43c7.89,0.75,15.72,1.71,23.29,2.63 c7.56,0.92,15.38,1.88,23.26,2.62h0.02v-0.02c0.4-5.91,1-11.66,1.59-17.22c0.54-5.18,1.06-10.07,1.41-15.07l0.01-0.02 l-0.05-0.02c-1.02-0.46-2.03-0.93-3.05-1.39c-1.76-0.8-3.53-1.6-5.31-2.41c-11.54-5.23-23.29-10.49-34.95-15.39 c-2.07-0.87-4.13-1.73-6.2-2.57l-0.04-0.01v48.86H260.29z M262.59,1089.89c3.2,1.39,6.41,2.79,9.65,4.2 c2.13,0.93,4.26,1.86,6.41,2.8c7.58,3.31,15.26,6.7,23.04,10.18c2.22,1,4.44,2,6.67,3.01c2.23,1.01,4.48,2.03,6.72,3.06 l0.02,0.01l0.01-0.01c11.85-9.01,24.27-17.9,36.28-26.51c7.05-5.05,14.34-10.27,21.52-15.53l0.04-0.02l-0.04-0.02 c-10.95-6.05-22.18-11.97-33.05-17.7c-17.41-9.18-35.41-18.67-52.53-28.85l-0.02-0.01l-0.01,0.03 c-2.75,7.25-5.64,14.63-8.42,21.77c-5.58,14.27-11.35,29.02-16.35,43.54l-0.01,0.02L262.59,1089.89z M282.04,1194.2l0.01,0.01 h0.01c17.28,3.01,34.83,6.82,51.8,10.51l0.04,0.01l-0.01-0.04c-1.47-11.81-3-24.02-5.26-36.78v-0.02h-0.02 c-1.75-0.38-3.53-0.74-5.32-1.11c-1.2-0.24-2.41-0.47-3.62-0.71c-2.44-0.47-4.91-0.93-7.43-1.37 c-11.26-1.99-23.38-3.75-36.59-5.29c-0.17-0.02-0.34-0.04-0.52-0.06c-1.31-0.15-2.63-0.3-3.96-0.45 c-2.34-0.26-4.71-0.52-7.12-0.77l-0.05-0.01l4.52,9.05C273.03,1176.19,277.54,1185.19,282.04,1194.2z M267.81,620.7 c33.79-8.45,71.24-18.23,117.86-30.78l0.02-0.01v-0.02c-2.95-36.16-6-73.56-10.51-110.35v-0.01l-0.01-0.01 c-11.08-8.18-21.97-16.78-32.51-25.1c-5.83-4.6-11.87-9.37-17.79-13.94l-0.03-0.02l-0.01,0.03 c-19.51,60.04-38.59,121.08-57.04,180.11l-0.03,0.1L267.81,620.7z M278.29,393.22c0,3.42,0.69,6.42,2.13,9.15 c1.27,2.43,3.11,4.6,5.6,6.62c1.45,1.18,3.06,2.23,4.76,3.23c0.68,0.4,1.38,0.78,2.09,1.15c1.07,0.56,2.16,1.1,3.27,1.61 c1.48,0.69,2.99,1.36,4.51,2.01c0.76,0.32,1.51,0.65,2.27,0.97c5.68,2.42,11.56,4.92,15.92,8.31l0.03,0.02l0.01-0.04 c6-24.79,11.35-50.73,16.52-75.82v-0.01l-0.01-0.01c-2.64-3.57-5.27-7.19-7.9-10.83c-1.26-1.75-2.53-3.5-3.78-5.26 c-4.8-6.67-9.55-13.37-14.23-19.94c-9-12.67-18.23-25.65-27.65-38.4c-1.57-2.13-3.15-4.24-4.73-6.35 c-1.58-2.11-3.17-4.21-4.77-6.3l-0.05-0.06v0.08C272.96,302.85,274.92,345.33,278.29,393.22z M273.03,242.34 c1.49,3.2,3.12,6.44,4.91,9.76c0.71,1.32,1.45,2.66,2.21,4c1.52,2.69,3.14,5.43,4.87,8.22c2.16,3.49,4.48,7.07,6.97,10.75 c7.12,10.5,14.94,20.85,22.51,30.86c7.26,9.6,14.76,19.52,21.58,29.5l0.05,0.07v-0.09c1.47-87.08,3-177.13,3.75-265.74v-0.04 l-0.04,0.02c-3.18,1.83-6.41,3.68-9.54,5.46c-15.95,9.1-32.44,18.51-47.52,29.82l-0.01,0.01v0.01c-2.82,24.17-5.3,46-7.13,68.41 C273.55,199.16,272.69,221.72,273.03,242.34L273.03,242.34z M306.84,1310.57c6.18-1.24,21.27-4.35,28.43-6.72 c-5.29,5.29-15.72,15.72-20.94,20.94l-0.04,0.04l0.06,0.01c5.25,0.25,10.59,0.67,15.75,1.08c8.19,0.65,16.61,1.32,24.97,1.32 c2.19,0,4.38-0.05,6.56-0.15h0.01c12.01-5.85,27.39-13.96,39.79-24.96c6.15-5.46,11.24-11.35,15.11-17.48 c4.31-6.84,7.31-14.28,8.92-22.13l0.01-0.05l-0.05,0.02c-16.76,7.36-31.53,14.26-45.14,21.11 c-15.59,7.84-29.78,15.66-43.39,23.9c0.8-3.26,1.07-6.16,0.79-8.63c-0.26-2.32-1.02-4.34-2.25-6c-1.81-2.45-4.66-4.21-8.7-5.36 c-3.16-0.91-7.11-1.46-12.41-1.74h-0.02l-0.01,0.02c-2.29,6.1-6.07,19.03-7.51,24.77l-0.01,0.04L306.84,1310.57z M378.02,470.47 l0.14,0.11l0.01-0.04c3.38-9.2,7.64-18.48,11.75-27.45c6.19-13.48,12.58-27.42,16.26-41.6c1.99-7.64,3.04-14.73,3.22-21.67 c0.21-7.79-0.68-15.2-2.71-22.64l-0.01-0.04l-0.03,0.03c-3.38,3-6.73,6.05-10.05,9.13c-5.79,5.35-11.5,10.8-17.14,16.3 c-4.09,3.96-8.13,7.95-12.14,11.94c-2.11,2.1-4.22,4.2-6.32,6.3c-1.05,1.05-2.1,2.09-3.15,3.15c-1.05,1.05-2.09,2.09-3.14,3.14 c-8.29,8.29-16.87,16.87-25.38,25.13l-0.02,0.02l0.02,0.02C345.07,445,361.82,457.95,378.02,470.47z M342.14,404.5 c26.51-23.9,52.09-48.19,76.53-72.63c1.36-1.35,2.71-2.71,4.06-4.07c0-0.01,0-0.01,0.01-0.01c2.7-2.72,5.38-5.43,8.05-8.15 c0.01-0.01,0.01-0.01,0.01-0.01c3.77-3.84,7.51-7.67,11.21-11.52c10.77-11.15,21.27-22.31,31.51-33.48l0.09-0.1l-0.12,0.05 c-14.24,6.53-29.22,14.74-45.79,25.1c-13.54,8.46-27.01,17.64-40.1,26.62c-1.22,0.83-2.43,1.66-3.64,2.49 c-1.45,0.99-2.92,2-4.4,3.02c-2.46,1.69-4.95,3.39-7.42,5.07l-0.01,0.01c-5.61,7.29-10.57,16-15.17,26.64 c-4.09,9.46-7.5,19.49-10.8,29.18c-0.16,0.49-0.33,0.97-0.5,1.46c-0.3,0.9-0.62,1.81-0.93,2.72c-0.86,2.52-1.75,5.07-2.63,7.56 l-0.04,0.1L342.14,404.5z M375.24,875.74c6.44,26.87,13.09,54.66,19.4,81.99v0.02h0.02c39.74,3.75,80.9,6.8,120.7,9.75 l0.19,0.01v-0.03L493.03,821.1c0-10.39-9.53-14.04-17.94-17.27c-1.35-0.52-2.62-1-3.84-1.52c-5.14-2.05-10.33-4.14-15.52-6.22 c-1.9-0.77-3.8-1.53-5.7-2.3c-4.24-1.71-8.47-3.41-12.64-5.09c-14.93-6.02-30.11-12.14-45.31-18.18 c-3.79-1.51-7.59-3.01-11.38-4.51c-0.01,0-0.01-0.01-0.02-0.01c-2.97-1.18-5.94-2.34-8.9-3.5c-8.42-3.3-16.81-6.56-25.14-9.74 l-0.04-0.02l0.01,0.05C355.6,793.78,365.58,835.45,375.24,875.74z M347.35,309.26l0.05-0.11c7.64-18.35,14.62-36.72,20.74-54.61 c6.39-18.69,12.04-37.44,16.8-55.74l0.01-0.01l-0.01-0.01c-2.78-12.63-6.59-26.19-11.66-41.43c-4.52-13.6-9.6-27.27-14.52-40.48 c-3.28-8.81-6.66-17.93-9.85-26.93l-0.05-0.14v0.15c0,27.28-0.65,55.14-1.27,82.08c-1.04,45.03-2.11,91.59-0.24,137.13 L347.35,309.26z M347.37,741.55c42.21,8.18,84.82,16.27,126.85,24.19c6.28,1.18,12.56,2.36,18.81,3.54 c11.42,2.15,22.79,4.29,34.08,6.41c14.99,2.82,30.11,5.66,45.31,8.53c6.28,1.18,12.58,2.37,18.88,3.56 c1.83,0.35,3.66,0.69,5.49,1.04c5.22,0.99,10.46,1.97,15.69,2.97c8.89,1.68,17.79,3.37,26.69,5.07 c10.58,2.01,21.16,4.03,31.74,6.06c12.02,2.31,24.04,4.62,36.01,6.94l0.05,0.01l-0.02-0.05c-5.63-12.33-11.07-25.17-16.33-37.6 c-5.36-12.66-10.82-25.56-16.64-38.29c-4.52-9.91-9.26-19.7-14.33-29.21l-0.01-0.01l-0.03-0.02c-0.01-0.01-0.02-0.01-0.03-0.02 c-8.23-4.38-16.5-8.79-24.83-13.2c-37.93-20.12-76.72-40.37-115.5-58.84h-0.01c-34.53,1.5-68.88,5.32-102.09,9.01h-0.01 l-0.02,0.04c-22.87,32.46-46.53,66.04-69.79,99.81l-0.02,0.03L347.37,741.55z M363.9,1281.29c22.52-9.76,44.65-21.2,66.05-32.27 l0.03-0.01v-0.02c2.03-23.68,5.49-47.6,8.83-70.73c4.07-28.16,8.29-57.29,9.94-86.16v-0.01l-0.01-0.01 c-20.67-44.05-37.85-79.35-54.05-111.11l-0.04-0.07l-0.01,0.09c-8.09,63.31-14.16,127.94-20.04,190.44 c-3.39,36.03-6.89,73.3-10.74,109.83v0.04L363.9,1281.29z M573.25,834.29c3.07,1.22,6.13,2.44,9.18,3.66 c0.4,0.16,0.79,0.31,1.18,0.47c6.72,2.67,13.49,5.37,20.28,8.08c12.31,4.9,24.72,9.87,37.14,14.87 c14.99,6.04,30,12.16,44.87,18.31h0.01l0.02,0.01v-0.01l0.01-0.02c3.75-10.13,7.76-20.24,11.63-30.02 c3.88-9.78,7.89-19.9,11.64-30.03l0.01-0.03l-0.03-0.01c-35.53-6.44-71.57-13.42-106.86-20.32c-6.89-1.35-13.76-2.7-20.58-4.04 c-6.91-1.35-13.85-2.72-20.81-4.07c-1.24-0.24-2.48-0.48-3.72-0.73c-6.97-1.36-13.96-2.72-20.98-4.09 c-45.81-8.89-92.39-17.67-138.57-25.31l-0.2-0.03l0.18,0.08C455.36,787.18,515.13,811.15,573.25,834.29z M438.22,1049.38 c2.31,4.71,4.63,9.41,6.96,14.08c2.91,5.84,5.83,11.64,8.76,17.39l0.02,0.04l0.02-0.04c1.06-1.71,2.12-3.42,3.17-5.14 c0.59-0.96,1.18-1.92,1.76-2.89c0.62-1.01,1.24-2.03,1.85-3.04c0.65-1.07,1.29-2.14,1.93-3.22c0.97-1.63,1.95-3.26,2.92-4.9 c0-0.01,0-0.01,0-0.01c2.41-4.09,4.8-8.19,7.17-12.31c0.32-0.57,0.65-1.13,0.97-1.7c1.05-1.83,2.09-3.66,3.13-5.49 c0,0,0.01-0.01,0.01-0.01c1.23-2.17,2.46-4.35,3.68-6.53c0-0.01,0.01-0.01,0.01-0.01c1.22-2.17,2.42-4.35,3.63-6.52 c9.71-17.54,19.11-35.2,28.34-52.56l0.02-0.04h-0.04c-25.65-2.56-51.84-4.47-77.17-6.31c-3.26-0.24-6.55-0.48-9.86-0.72 c-4.09-0.3-8.2-0.6-12.32-0.91c-0.23-0.02-0.46-0.04-0.68-0.05c-2.8-0.21-5.61-0.43-8.42-0.65c-1.63-0.12-3.27-0.25-4.9-0.38 h-0.05l0.03,0.05C411.88,994.57,424.93,1022.28,438.22,1049.38z M416.04,368.45c0.92,5.9,1.88,12.01,2.62,18.01l0.01,0.04 l0.03-0.02c13.39-5.82,26.23-12,38.16-18.38c12.8-6.84,25-14.13,36.26-21.69c11.97-8.02,23.26-16.6,33.58-25.49 c10.88-9.38,21.02-19.4,30.13-29.78l0.07-0.08l-0.09,0.04c-30.75,10.88-61.14,24.08-90.52,36.84 c-9.71,4.22-19.6,8.51-29.57,12.75c-5.54,2.35-11.08,4.69-16.64,6.98c-2.22,';
        return image;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Rabbit3 {
    function RabbitString() public pure returns (string memory) {
        string memory image = '0.92-4.45,1.83-6.66,2.73l-0.02,0.01v0.01v0.02 C414.16,356.44,415.11,362.54,416.04,368.45z M439.71,326.43c16.79-5.17,34.88-11.72,55.31-20.04 c18.22-7.42,36.58-15.52,54.34-23.35c2.7-1.19,5.42-2.39,8.16-3.6c4.1-1.81,8.25-3.63,12.39-5.44c4.15-1.81,8.3-3.61,12.44-5.38 l0.01-0.01l0.01-0.01c13.51-20.55,18.31-45.39,22.96-69.39c1.27-6.6,2.59-13.41,4.06-19.94l0.02-0.07l-0.06,0.04 c-11.66,9.34-24.56,17.44-37.03,25.28c-9.83,6.18-19.99,12.56-29.49,19.52c-10.66,7.79-19.35,15.49-26.56,23.52 c-8.5,8.76-17.49,17.41-26.19,25.77c-17.39,16.73-35.37,34.04-50.38,53.05l-0.05,0.07L439.71,326.43z M459.2,1091.36 c9.54,9.12,19.12,18.35,28.6,27.53c4.21,4.07,8.41,8.14,12.58,12.19c3.13,3.03,6.25,6.06,9.34,9.06 c4.13,4.01,8.28,8.04,12.45,12.08c0,0,0,0,0.01,0.01c8.33,8.07,16.73,16.2,25.19,24.33c21.14,20.33,42.6,40.7,64.22,60.44 l0.05,0.05l-0.01-0.07c-2.82-21.33-7.22-42.6-11.48-63.16c-3.69-17.82-7.5-36.24-10.29-54.69c-2.08-18.72-3.95-37.62-5.77-55.9 c-2.76-27.85-5.61-56.66-9.24-85.23l-0.01-0.02h-0.02c-1.07,0.09-2.16,0.16-3.25,0.19c-3.98,0.15-8.08-0.02-12.14-0.25 c-1-0.05-2-0.12-3-0.18c-5.85-0.35-11.89-0.71-17.66-0.3c-6.47,0.46-11.87,1.86-16.51,4.29h-0.01l-0.01,0.01 c-14.18,21.49-26.65,44.27-38.71,66.3c-7.78,14.22-15.83,28.93-24.35,43.3l-0.01,0.02L459.2,1091.36z M498.99,1312.82 c5.82,3.6,11.22,8.2,16.45,12.65c2.23,1.91,4.51,3.85,6.84,5.73c0.58,0.47,1.17,0.94,1.76,1.4c1.77,1.38,3.57,2.72,5.41,3.97 c4.13,2.81,8.12,4.94,12.11,6.46c1.32,0.51,2.65,0.95,3.98,1.32c9.43,0.54,18.88,1.02,28.36,1.46c2.95,0.13,5.9,0.27,8.85,0.4 c12.44,0.55,24.88,1.03,37.31,1.46c24.86,0.86,49.62,1.54,73.97,2.2c29.04,0.79,59.06,1.61,88.73,2.73l0.03,0.01v-30.08 l-0.02-0.01c-17.52-3.5-35.33-7.15-52.55-10.68c-34.44-7.05-70.06-14.35-105.08-20.85c-36.04-3-73.06-3-108.85-3h-0.02 l-0.01,0.01c-0.75,1.03-1.49,2.07-2.23,3.11c-0.73,1.04-1.46,2.08-2.17,3.11c-1.44,2.08-2.85,4.14-4.23,6.17 c-1.73,2.53-3.5,5.12-5.31,7.72c-0.72,1.04-1.46,2.08-2.2,3.11c-0.37,0.52-0.74,1.03-1.12,1.55l-0.02,0.02L498.99,1312.82z M505.78,846.7c0.7,4.73,1.41,9.47,2.12,14.22c0.12,0.8,0.24,1.61,0.37,2.42c0.95,6.36,1.92,12.72,2.89,19.1 c1.47,9.58,2.96,19.16,4.49,28.74c0.85,5.33,1.71,10.66,2.58,15.98c0.32,1.95,0.64,3.9,0.96,5.85c1.34,8.08,2.7,16.14,4.1,24.16 c0.65,3.7,1.3,7.4,1.96,11.09v0.02h0.02c5.16,0,10.41,0.13,15.47,0.25c5.01,0.12,10.09,0.24,15.17,0.24 c7.63,0,15.26-0.27,22.65-1.24l0.02-0.01c23.28-17.21,45.98-35.8,67.92-53.78c10.64-8.72,21.66-17.74,32.67-26.54l0.04-0.03 l-0.04-0.01c-3.71-1.55-7.42-3.09-11.13-4.63c-7.43-3.08-14.86-6.14-22.31-9.18c-7.45-3.04-14.91-6.08-22.37-9.1 c-7.43-3-14.86-5.99-22.28-8.96c-33.54-13.43-66.97-26.54-99.78-39.42l-0.08-0.04l0.01,0.09 C502.75,826.1,504.26,836.38,505.78,846.7z M593.49,1063.74c2.41,19.14,4.91,38.93,6.08,58.39l0.01,0.02v0.01l0.02-0.01 c94.36-21.04,189.92-43.74,282.33-65.7c9.98-2.37,19.96-4.74,29.96-7.11l0.05-0.01l-0.04-0.03 c-86.35-61.93-157.67-112.02-224.45-157.64l-0.02-0.01l-0.02,0.01c-18.14,15.66-37.01,30.65-55.27,45.14 c-7.48,5.94-15.08,11.98-22.68,18.1c-1.3,1.05-2.61,2.1-3.91,3.16c-2.49,2.02-4.98,4.04-7.46,6.08 c-3.78,3.1-7.54,6.21-11.27,9.34v0.01l-0.01,0.01v0.01c-0.41,13.49,0.1,28.25,1.57,45.12 C589.69,1033.65,591.62,1048.95,593.49,1063.74z M615.21,1202.73c5.37,26.14,10.92,53.16,14.39,80.05v0.02h0.01h0.02 c23.65,4.13,47.51,9.09,70.57,13.89c23.06,4.8,46.91,9.76,70.56,13.88l0.08,0.02l-0.06-0.06c-1.63-1.67-3.26-3.34-4.89-5.02 c-8.22-8.44-16.55-16.97-24.96-25.56c-1.63-1.66-3.25-3.32-4.88-4.98c-8.4-8.57-16.89-17.19-25.47-25.85 c-12.01-12.13-24.18-24.33-36.5-36.56c-3.52-3.5-7.05-6.99-10.59-10.48c-1.77-1.75-3.54-3.5-5.32-5.24 c-3.55-3.5-7.11-6.98-10.69-10.48c-3.57-3.49-7.16-6.98-10.75-10.47c-3.59-3.49-7.2-6.97-10.81-10.45 c-7.23-6.96-14.49-13.9-21.79-20.81l-0.05-0.05l0.01,0.08C607.25,1163.99,611.29,1183.68,615.21,1202.73z M749.74,1275.07 c12.05,11.87,24.5,24.14,36.76,36.25l0.02,0.03l0.02-0.04c9.2-18.4,18.59-36.92,27.98-55.34c1.97-3.86,3.94-7.72,5.91-11.56 c7.43-14.52,14.85-28.95,22.16-43.19c4.46-8.68,8.95-17.41,13.45-26.19c3-5.85,6-11.7,9.01-17.59 c16.55-32.34,33.15-65.11,49.11-97.61l0.02-0.05l-0.05,0.01c-16.08,3.4-32.2,6.89-48.33,10.44c-12.9,2.84-25.83,5.72-38.74,8.64 c-0.01,0.01-0.01,0.01-0.02,0.01c-9.69,2.19-19.38,4.39-29.07,6.62c-46.03,10.57-92,21.48-137.46,32.4 c-4.85,1.16-9.69,2.33-14.54,3.49c-1.53,0.37-3.06,0.74-4.59,1.1c-4.84,1.16-9.66,2.33-14.48,3.48 c-7.11,1.71-14.21,3.42-21.29,5.13l-0.05,0.01l0.04,0.04C652.94,1179.7,702.15,1228.18,749.74,1275.07z M699.73,772.36 c0.76,1.77,1.52,3.53,2.3,5.28c0.51,1.16,1.02,2.3,1.53,3.45c1.44,3.24,2.91,6.47,4.41,9.68c0.81,1.74,1.63,3.47,2.47,5.2 c0.83,1.73,1.67,3.45,2.52,5.17c1.7,3.43,3.43,6.84,5.22,10.22l0.01,0.01l0.01,0.01c24.47,14.43,50.87,25.87,76.4,36.93 c4.99,2.16,10.15,4.4,15.19,6.61l0.12,0.05l-0.09-0.09c-19.57-21.37-40.69-43.32-62.77-65.21 c-20.67-20.49-42.74-41.49-65.59-62.4l-0.09-0.08l0.04,0.11C687.28,742.18,693.27,757.36,699.73,772.36z M694.16,884.17 l0.01,0.01c4.86,3.34,9.72,6.71,14.57,10.1c3.23,2.25,6.47,4.52,9.7,6.79c1.61,1.14,3.23,2.27,4.84,3.41 c3.23,2.28,6.44,4.56,9.66,6.83c12.86,9.13,25.63,18.28,38.17,27.27c5.58,4.01,11.2,8.03,16.83,12.06 c14.08,10.08,28.31,20.21,42.68,30.25c4.9,3.42,9.82,6.84,14.75,10.24c0.86,0.59,1.72,1.18,2.58,1.77 c2.03,1.4,4.07,2.8,6.11,4.18c2.31,1.58,4.63,3.16,6.95,4.73c4.37,2.97,8.76,5.91,13.15,8.83c2.6,1.73,5.2,3.45,7.81,5.16 c9.16,6.03,18.37,11.95,27.64,17.76l0.07,0.04l-0.04-0.07c-10.56-24.08-22.28-48.34-33.6-71.8 c-8.81-18.24-17.92-37.1-26.45-55.81c-1.44-2.7-2.73-5.62-3.97-8.45c-1.99-4.5-4.04-9.15-6.77-13.1 c-3.07-4.43-6.68-7.45-11.04-9.25c-6.78-3.32-13.6-6.66-20.46-10.01c-3.82-1.86-7.66-3.73-11.51-5.6 c-14.54-7.06-29.23-14.11-44-21c-4.66-2.17-9.34-4.33-14.02-6.47c-0.01,0-0.01,0-0.01-0.01c-4.68-2.14-9.37-4.26-14.06-6.35 c-2.34-1.05-4.69-2.08-7.04-3.12l-0.02-0.01l-0.01,0.04c-7.38,19.92-15.01,40.52-22.51,61.54v0.01L694.16,884.17L694.16,884.17z M875.86,1158.18c24.17-6.66,46.4-13.48,66.06-20.27l0.02-0.01l-0.01-0.02c-1.2-4.8-2.41-9.63-3.63-14.49 c-0.56-2.23-1.13-4.47-1.69-6.71c-0.19-0.76-0.38-1.52-0.58-2.28c-1.04-4.12-2.09-8.26-3.16-12.4 c-3.11-12.06-6.33-24.18-9.71-36.19l-0.02-0.06l-0.03,0.05c-17.19,29.89-33.09,60.95-47.29,92.33l-0.02,0.05L875.86,1158.18z M941.13,1099.61c2.77,10.33,5.63,21.02,8.26,31.53l0.01,0.05l0.04-0.04c4.55-5.38,9.01-10.86,13.42-16.37 c5.86-7.35,11.6-14.76,17.24-22.09c1.41-1.83,2.81-3.65,4.21-5.47c4.06-5.28,8.25-10.74,12.43-16.12l0.01-0.01l-0.01-0.01 c-7.67-13.26-14.97-26.87-22.02-40.03c-8.07-15.08-16.43-30.68-25.27-45.54l-0.03-0.05l-0.02,0.06c-1.97,6.9-4.56,13.74-7.29,21 c-7.53,19.94-15.32,40.55-9.23,61.59C935.5,1078.59,938.37,1089.28,941.13,1099.61z M985.69,1032.87 c5.63,10.25,11.44,20.84,17,31.47l0.02,0.04l0.02-0.03c6-7.88,12.3-15.89,18.39-23.65c6.09-7.75,12.39-15.77,18.39-23.65 l0.01-0.01l-0.01-0.01c-18.68-47.82-38.38-96.31-58.55-144.13l-0.03-0.07l-0.02,0.07c-3.31,13.21-7.39,26.4-11.35,39.16 c-5.94,19.13-12.07,38.92-15.67,59.19v0.01v0.01C963.35,992.16,974.71,1012.86,985.69,1032.87z"/><path class="st3" d="M76.05,599.22c-0.2,1.95,0.05,3.76,0.75,5.35c0.15,0.35,0.33,0.7,0.52,1.03c0.2,0.33,0.41,0.66,0.65,0.97 c0.24,0.3,0.5,0.6,0.78,0.89c0.41,0.42,0.88,0.82,1.39,1.18c2.97,2.18,6.33,2.58,9.46,1.13c3.92-1.82,6.98-6.39,7.28-10.88 c0.18-2.69-0.62-5.03-2.27-6.79c-0.13-0.13-0.26-0.26-0.39-0.39c-0.41-0.38-0.85-0.73-1.35-1.05v-0.01 c-2.33-1.74-4.48-2.33-6.3-2.33c-1.38,0-2.58,0.33-3.54,0.75C79.32,590.71,76.52,594.78,76.05,599.22z"/> <path class="st6" d="M86.92,628.92c20.65,11.8,42,24,63.76,35.26c9.75-15,19.5-30,29.25-45c-10.56-3.29-21.12-6.34-31.53-9.26 c-4.16-1.16-8.29-2.31-12.4-3.44c-2.06-0.57-4.12-1.13-6.17-1.69c-1.57-0.43-3.16-0.87-4.76-1.31 c-1.91-0.52-3.82-1.05-5.75-1.58c-1.52-0.42-3.05-0.85-4.58-1.27c-2.02-0.57-4.05-1.13-6.07-1.7 C100.64,610.52,93.53,620.33,86.92,628.92z"/> <path class="st7" d="M90.53,559.27c-3.85,5.13-7.84,10.43-11.86,15.61c4.49,2.25,9.06,4.34,13.48,6.36 c4.42,2.03,8.99,4.12,13.48,6.37c2.53-9,5.43-18.15,8.23-27c4.66-14.74,9.48-29.97,12.76-44.95 C113.25,529.05,101.7,544.41,90.53,559.27z"/> <path class="st8" d="M124.09,557.86c-2.32,7.56-4.73,15.39-7.13,22.97c17.63-10.21,34.95-21.45,51.7-32.32 c10.31-6.69,20.97-13.6,31.55-20.19c-1.57-27.49-3.05-52.34-5.25-78.01c-4.39,3.34-8.98,6.63-13.42,9.82 c-11.58,8.29-23.55,16.87-33.83,27.68C138.67,510.42,131.26,534.54,124.09,557.86z"/> <path class="st9" d="M197.95,540.4c-24.4,15.34-52.55,33.25-77.98,51.74c17.22,5.53,35.07,10.6,52.33,15.5 c3.75,1.07,7.62,2.16,11.41,3.25C188.87,588.03,194.2,564.4,197.95,540.4z"/> <path class="st11" d="M154.21,788.67c-1.92,1.06-3.83,2.11-5.74,3.17c11.93,47.06,26.16,102.65,41.27,158.32 c17.77-25.38,36-51.16,53.63-76.08c3.79-5.35,7.59-10.72,11.4-16.11c6.58-9.31,13.18-18.65,19.79-28.03 c2.24-3.18,4.48-6.36,6.72-9.54c3.17-4.51,6.35-9.02,9.52-13.54c4.76-6.78,9.52-13.59,14.28-20.41 c3.17-4.54,6.34-9.1,9.51-13.65c3.17-4.56,6.33-9.12,9.49-13.7c4.74-6.86,9.46-13.73,14.18-20.62 c3.14-4.59,6.28-9.19,9.41-13.79c15.64-23.01,31.09-46.16,46.18-69.4c-16.3,8.37-32.55,17.01-48.74,25.81 c-4.85,2.64-9.7,5.3-14.54,7.97c-11.29,6.22-22.54,12.5-33.73,18.8c-12.79,7.21-25.51,14.44-38.13,21.64 c-6.32,3.61-12.6,7.2-18.86,10.77c-5.33,3.05-10.7,6.11-16.1,9.2c-11.59,6.62-23.31,13.29-35.06,19.93 c-3.82,2.16-7.65,4.31-11.48,6.46c0,0.01,0,0.01-0.01,0.01c-3.83,2.15-7.66,4.3-11.49,6.43 C161.87,784.43,158.04,786.56,154.21,788.67z"/> <path class="st12" d="M149.22,780.52c72.84-40.55,144.18-80.48,212.69-119.08c4.55-2.56,9.09-5.12,13.61-7.67 c4.49-2.53,8.98-5.07,13.45-7.59c3.72-2.1,7.44-4.2,11.14-6.29c2.93-1.65,5.86-3.31,8.78-4.96c-3.32-4.17-5.65-9.51-7.89-14.67 c-3.91-8.98-7.6-17.47-16.08-19.83c-18.85,3.95-37.66,8.39-56.49,13.33c-1.18,0.31-2.35,0.62-3.53,0.93 c-1.35,0.35-2.69,0.71-4.03,1.08c-0.88,0.24-1.77,0.48-2.66,0.72c-0.13,0.04-0.26,0.07-0.38,0.1c-1.99,0.54-3.98,1.09-5.96,1.64 c-2.05,0.57-4.09,1.14-6.13,1.72c-0.68,0.19-1.36,0.38-2.04,0.58c-23.69,6.78-47.12,14.27-70.31,22.41 c-1.95,0.69-3.91,1.38-5.86,2.08c-1.98,0.71-3.96,1.42-5.95,2.14c-1.08,0.39-2.17,0.78-3.26,1.18 c-3.57,1.3-7.14,2.62-10.72,3.96c-0.02,0.01-0.04,0.02-0.06,0.02c-16.8,6.29-33.72,13.01-50.81,20.16v0.04 c-0.44,5.33-0.89,10.69-1.33,16.06c-1.94,23.51-3.81,47.43-5.15,71.23C149.85,766.74,149.51,773.64,149.22,780.52z"/> <path class="st13" d="M189.74,621.45c-8.91,12.96-16.98,25.56-23.98,37.46c24.83-8.04,49.34-17.59,74.92-29.22 c-1.09-0.19-2.18-0.38-3.26-0.57c-1.1-0.19-2.19-0.38-3.29-0.57c-0.01-0.01-0.02-0.01-0.02-0.01 C219.03,625.91,204.77,623.41,189.74,621.45z"/> <path class="st14" d="M199.43,954.04c-1.47,2.99-1.89,5.4-1.3,7.35c0.62,1.99,2.33,3.53,5.12,4.57 c28.9,16.89,58.66,33.87,87.45,50.29c28.78,16.42,58.53,33.39,87.42,50.28c0.44-13.63,1.87-27.63,3.25-41.17 c3.36-32.84,6.83-66.79-3.25-99.16c-6.18-24.38-12.03-49.32-17.69-73.44c-7.41-31.59-15.08-64.25-23.59-96.16l-55.37,79.23 c-25.07,35.88-50.14,71.75-75.21,107.64c-0.58,0.93-1.34,2-2.15,3.14c-0.9,1.27-1.88,2.64-2.78,4.06 c-0.3,0.47-0.59,0.94-0.87,1.42C200.1,952.75,199.75,953.39,199.43,954.04z"/> <path class="st15" d="M198.83,583.64c-1.89,9.7-3.84,19.73-6.07,29.5c7.58,1.05,15.18,2.2,22.53,3.32 c13.67,2.07,27.81,4.22,41.98,5.69c6.42-21.23,13.49-42.74,20.33-63.53c11.56-35.17,23.52-71.55,32.94-108.28 c-33.57,25-68.98,52.49-100.52,84.03C205.31,550.38,202.02,567.29,198.83,583.64z"/> <path class="st17" d="M204.77,442.78c0,26.25,2.39,53.34,4.5,77.25c4.51-3.56,8.99-7.15,13.46-10.75 c31.31-25.19,61.88-51.1,91.56-76.27c-6.74-3.37-13.79-6.8-20.6-10.11c-3.42-1.66-6.89-3.35-10.35-5.05 c-2.59-1.27-5.18-2.55-7.74-3.82c-0.85-0.42-1.7-0.85-2.55-1.27c-8.3,3.87-16.7,7.79-25.19,11.66 c-2.83,1.29-5.67,2.57-8.52,3.84c-7.12,3.18-14.3,6.3-21.53,9.29c-2.89,1.19-5.79,2.37-8.68,3.52 C207.68,441.65,206.23,442.22,204.77,442.78z"/> <path class="st19" d="M260.32,1099.65v48.73c7.88,0.75,15.7,1.71,23.26,2.62c7.55,0.92,15.36,1.88,23.23,2.62 c0.4-5.9,1-11.64,1.58-17.19c0.55-5.17,1.06-10.05,1.42-15.04l-0.02-0.01c-2.03-0.92-4.06-1.85-6.1-2.77s-4.09-1.85-6.14-2.78 C285.22,1110.26,272.7,1104.71,260.32,1099.65z"/> <path class="st20" d="M262.58,1089.83l0.02,0.01c1.3,0.57,2.59,1.13,3.9,1.69c1.81,0.79,3.64,1.58,5.46,2.38 c5.47,2.38,11,4.8,16.58,7.26c2.16,0.95,4.33,1.91,6.5,2.88c4.41,1.95,8.85,3.95,13.32,5.97c2.23,1,4.47,2.03,6.72,3.06 c11.85-9.01,24.26-17.9,36.26-26.5c7.03-5.04,14.31-10.26,21.49-15.5c-6.84-3.78-13.78-7.5-20.68-11.16 c-2.76-1.46-5.51-2.92-8.25-4.36c-1.37-0.72-2.73-1.44-4.09-2.16c-17.4-9.17-35.4-18.65-52.51-28.83 c-2.75,7.25-5.63,14.62-8.41,21.75C273.34,1060.58,267.58,1075.33,262.58,1089.83z"/> <path class="st21" d="M264.09,1158.19l4.48,8.97c4.5,9,9.01,18.01,13.51,27.01c17.26,3,34.8,6.81,51.75,10.5 c-1.47-11.8-3-23.99-5.25-36.73c-1.17-0.25-2.34-0.5-3.53-0.74c-1.18-0.24-2.38-0.48-3.59-0.72c-1.09-0.22-2.19-0.43-3.3-0.64 c-0.23-0.04-0.46-0.09-0.69-0.13c-2.25-0.42-4.54-0.83-6.86-1.24c-0.2-0.04-0.4-0.07-0.61-0.1c-2.33-0.4-4.7-0.79-7.11-1.18 C290.98,1161.29,278.12,1159.64,264.09,1158.19z"/> <path class="st22" d="M267.84,620.62l-0.01,0.02c33.77-8.45,71.2-18.22,117.79-30.77c-2.95-36.15-6-73.53-10.5-110.31 c-11.08-8.18-21.97-16.78-32.5-25.09c-5.83-4.6-11.85-9.35-17.76-13.91C305.35,500.58,286.29,561.6,267.84,620.62z"/> <path class="st23" d="M272.33,263.43c0.68,39.48,2.65,81.93,6,129.79c0,14.23,12.5,19.55,24.6,24.69 c3.54,1.51,7.17,3.04,10.46,4.82c0.65,0.35,1.3,0.72,1.92,1.09c0.63,0.37,1.23,0.76,1.82,1.16c0.59,0.4,1.16,0.8,1.7,1.22 c6-24.77,11.34-50.7,16.5-75.77c-8.71-11.82-17.45-24.12-25.91-36.02c-1.37-1.92-2.75-3.86-4.13-5.8 c-5.41-7.61-10.9-15.3-16.47-22.96c-1.55-2.13-3.11-4.27-4.67-6.39C280.25,273.93,276.31,268.64,272.33,263.43z"/> <path class="st24" d="M282.84,104.97c-4.94,42.31-10.53,90.26-9.76,137.35c10.65,22.82,26.32,43.54,41.47,63.57 c7.24,9.57,14.73,19.47,21.54,29.44c1.47-87.04,3-177.04,3.75-265.61c-3.17,1.83-6.39,3.66-9.5,5.44 C314.4,84.26,297.91,93.67,282.84,104.97z"/> <path class="st26" d="M314.36,1285.8c-2.28,6.09-6.05,18.96-7.49,24.71c6.24-1.25,21.39-4.38,28.48-6.75l0.1-0.03l-0.08,0.08 c-5.24,5.24-15.71,15.71-20.97,20.97c5.23,0.26,10.55,0.68,15.7,1.08c10.33,0.82,21.02,1.67,31.53,1.17 c27.76-13.51,57.05-31.73,63.78-64.49c-35.16,15.44-63.29,29.74-88.53,45.02l-0.05,0.03l0.02-0.06 c1.6-6.39,1.13-11.19-1.43-14.65C331.36,1287.41,322.5,1286.23,314.36,1285.8z"/> <path class="st3" d="M332.59,429.15c-1.07,1.04-2.13,2.08-3.19,3.11c15.72,12.72,32.46,25.66,48.66,38.18l0.09,0.07 c3.38-9.2,7.63-18.46,11.74-27.42c12.39-27,25.2-54.91,16.78-85.84c-2.25,2-4.49,4.02-6.72,6.05c-1.69,1.55-3.37,3.1-5.05,4.66 c-6.06,5.64-12.03,11.38-17.93,17.14c-5.37,5.26-10.68,10.53-15.94,15.77c-2.11,2.1-4.2,4.2-6.28,6.28 c-3.11,3.11-6.25,6.25-9.42,9.41c-2.11,2.11-4.23,4.21-6.36,6.32C336.84,424.97,334.71,427.06,332.59,429.15z"/> <path class="st28" d="M342.69,402.94c-0.17,0.48-0.34,0.97-0.51,1.45c47.07-42.44,91.21-86.08,131.2-129.7 c-10.89,4.99-21.51,10.66-31.9,16.72c-1.89,1.1-3.77,2.22-5.65,3.35c-17.82,10.72-35.01,22.53-51.86,34.09 c-1.45,0.99-2.92,2-4.4,3.01c-2.46,1.69-4.95,3.39-7.41,5.07c-12.51,16.25-19.35,36.36-25.97,55.8 c-0.82,2.39-1.65,4.84-2.49,7.28C343.37,400.99,343.03,401.97,342.69,402.94z"/> <path class="st44" d="M347.64,172.02c-1.04,44.99-2.11,91.51-0.24,137.01c15.58-37.42,28.2-74.5,37.49-110.23 c-6.19-28.15-16.35-55.48-26.18-81.91c-3.26-8.77-6.63-17.83-9.8-26.79C348.9,117.32,348.26,145.13,347.64,172.02z"/> <path class="st17" d="M378.08,697.38c-10.23,14.62-20.48,29.36-30.66,44.13c11.97,2.32,23.98,4.63,36,6.94 c6.09,1.17,12.18,2.33,18.28,3.5c1.6,0.3,3.21,0.62,4.82,0.92c14.18,2.7,28.35,5.39,42.48,8.06 c26.27,4.98,52.4,9.89,78.14,14.73c11.3,2.13,22.68,4.27,34.12,6.42c10.89,2.05,21.83,4.11,32.8,6.19 c37.48,7.08,75.33,14.27,112.86,21.55c-5.62-12.31-11.05-25.14-16.31-37.56c-9.52-22.5-19.38-45.76-30.96-67.49l-0.02-0.01 c-45.75-24.35-93.06-49.53-140.34-72.05c-34.53,1.5-68.87,5.32-102.08,9.01l-0.01,0.02c-4.29,6.08-8.6,12.21-12.94,18.37 c-2.88,4.1-5.78,8.22-8.68,12.34c-0.01,0.01-0.01,0.01-0.01,0.02c-2.9,4.13-5.8,8.26-8.72,12.42c0,0.01-0.01,0.01-0.01,0.02 C383.91,689.05,380.99,693.21,378.08,697.38z"/>';
        return image;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library Rabbit4 {
    using Strings for uint256;
    function RabbitString(string memory attack, string memory defense, uint256 kills, bool revived, string memory tokenId, uint256 mintTimestamp) public view returns (string memory) {
        string memory _daysAlive = calculateDaysAlive(mintTimestamp).toString();
        string memory _level = calculatePlayerLevel(mintTimestamp, kills).toString();
        string memory _revived = revivedToString(revived);
        string memory image1 = '<path class="st43" d="M376.91,764.58c-10.13-3.99-20.24-7.92-30.26-11.75c9.01,40.97,18.98,82.62,28.63,122.9 c6.44,26.87,13.09,54.65,19.4,81.97c39.73,3.75,80.88,6.8,120.68,9.74l0.13,0.01L492.98,821.1c0-1.62-0.23-3.08-0.66-4.39 c-0.09-0.26-0.18-0.52-0.27-0.77c-0.15-0.38-0.32-0.75-0.5-1.1c-0.12-0.23-0.25-0.46-0.38-0.69c-0.07-0.11-0.14-0.22-0.21-0.33 c-0.21-0.33-0.44-0.65-0.68-0.96c-0.24-0.31-0.49-0.61-0.76-0.9c-0.18-0.19-0.36-0.38-0.55-0.57c-3.54-3.53-8.93-5.59-13.91-7.5 c-1.35-0.52-2.62-1-3.84-1.52c-2.81-1.13-5.64-2.26-8.48-3.4c-4.24-1.7-8.51-3.42-12.75-5.12c-1.44-0.58-2.88-1.16-4.32-1.74 c-2.79-1.12-5.57-2.24-8.32-3.35c-5.6-2.26-11.24-4.53-16.9-6.81c-3.23-1.3-6.47-2.6-9.71-3.9c-3.23-1.3-6.47-2.6-9.72-3.89 c-2.61-1.05-5.22-2.09-7.84-3.13c-0.37-0.15-0.74-0.3-1.12-0.44C387.02,768.57,381.96,766.57,376.91,764.58z"/> <path class="st27" d="M473.49,274.61c-41.29,45.04-85.58,88.58-131.37,129.87c8.26-23.27,15.01-48.05,30.03-67.57 C405.18,314.39,437.45,291.12,473.49,274.61z M473.38,274.69c-10.89,4.99-21.51,10.66-31.9,16.72c-1.89,1.1-3.77,2.22-5.65,3.35 c-17.82,10.72-35.01,22.52-51.86,34.08c-1.45,1-2.92,2-4.4,3.02c-2.46,1.69-4.95,3.39-7.41,5.07 c-12.51,16.25-19.35,36.36-25.97,55.8c-0.82,2.39-1.65,4.84-2.49,7.28c-0.34,0.98-0.68,1.95-1.02,2.92 c-0.17,0.48-0.34,0.97-0.51,1.45C389.25,361.95,433.38,318.31,473.38,274.69z"/> <path class="st13" d="M374.65,1171.44c-3.39,36.02-6.89,73.27-10.73,109.79c22.5-9.76,44.61-21.19,66-32.26 c2.03-23.68,5.49-47.59,8.84-70.72c4.07-28.16,8.28-57.29,9.93-86.15c-5.16-11-10.11-21.46-14.88-31.45 c-0.6-1.25-1.19-2.49-1.78-3.73s-1.18-2.46-1.77-3.68c-0.88-1.83-1.75-3.64-2.61-5.44c-1.15-2.4-2.3-4.77-3.43-7.12 c-2.55-5.29-5.05-10.44-7.52-15.47c0-0.01-0.01-0.01-0.01-0.01c-2.19-4.47-4.35-8.85-6.47-13.16 c-2.67-5.39-5.29-10.65-7.87-15.8c-1.04-2.05-2.06-4.09-3.08-6.12c-0.01-0.01-0.01-0.01-0.01-0.01 c-1.02-2.03-2.05-4.04-3.06-6.03c-0.51-1-1.02-1.99-1.52-2.98C386.59,1044.36,380.52,1108.96,374.65,1171.44z"/> <path class="st30" d="M397.86,761.11c7.64,3.45,15.31,6.87,23.01,10.25c3.26,1.44,6.53,2.86,9.81,4.29 c50.77,22.04,102.57,42.66,152.96,62.72c8.39,3.34,16.86,6.7,25.36,10.1c25.53,10.19,51.43,20.6,76.91,31.15 c3.75-10.12,7.75-20.22,11.63-30c3.87-9.77,7.87-19.88,11.63-30c-42.45-7.69-85.64-16.16-127.41-24.35 C521.58,783.48,459.37,771.29,397.86,761.11z"/> <path class="st31" d="M403.76,967.87c-1.52-0.12-3.03-0.24-4.55-0.35c17.7,37.62,36.01,76.52,54.76,113.27 c21-33.76,40.07-69.61,58.51-104.27c-25.63-2.56-51.81-4.47-77.13-6.31c-7.59-0.55-15.34-1.11-23.13-1.7 C409.4,968.3,406.58,968.09,403.76,967.87z"/> <path class="st28" d="M413.46,350.44c0.75,6,1.71,12.1,2.62,18c0.92,5.89,1.88,11.99,2.62,17.98 c31.46-13.68,58.95-28.89,82.86-45.88c0.7-0.51,1.4-1,2.1-1.5c1.39-1.01,2.77-2.02,4.14-3.04c0.69-0.51,1.37-1.02,2.05-1.53 c0.66-0.5,1.33-1,1.99-1.51c0.01-0.01,0.02-0.02,0.04-0.03c1.34-1.03,2.67-2.07,3.99-3.11c0.91-0.72,1.81-1.44,2.72-2.17 c0.62-0.5,1.24-1,1.85-1.5c0.49-0.41,0.97-0.8,1.46-1.21c0.59-0.49,1.18-0.97,1.76-1.47c0.63-0.54,1.27-1.07,1.9-1.61 c0.62-0.53,1.24-1.06,1.85-1.59c0.01-0.01,0.02-0.02,0.03-0.03c1.75-1.52,3.47-3.05,5.18-4.59c0.12-0.12,0.24-0.23,0.36-0.33 c8.49-7.72,16.4-15.76,23.76-24.15c-1.92,0.68-3.84,1.37-5.75,2.06c-2.87,1.05-5.75,2.11-8.62,3.19 c-25.81,9.73-51.28,20.79-76.05,31.55c-2.48,1.08-4.98,2.16-7.48,3.25c-10.55,4.58-21.28,9.21-32.04,13.71 c-2.22,0.93-4.44,1.86-6.66,2.77C417.9,348.64,415.68,349.54,413.46,350.44z"/> <path class="st32" d="M490.1,273.37c-17.37,16.72-35.33,33.99-50.33,52.99c37.39-11.52,74.08-27.71,109.57-43.36 c10.79-4.76,21.95-9.69,32.97-14.41c13.5-20.54,18.31-45.36,22.95-69.37c1.27-6.56,2.59-13.35,4.05-19.87 c-11.65,9.31-24.53,17.4-36.98,25.24c-9.82,6.17-19.82,12.46-29.36,19.43s-18.64,14.65-26.67,23.59 C507.79,256.36,498.79,265.01,490.1,273.37z"/> <path class="st33" d="M459.25,1091.34c6.35,6.07,12.72,12.19,19.07,18.32c2.66,2.56,5.32,5.13,7.97,7.7 c7.9,7.64,15.75,15.25,23.48,22.75c33.06,32.07,67.24,65.24,101.81,96.81c-2.82-21.31-7.22-42.55-11.47-63.09 c-3.69-17.82-7.51-36.25-10.29-54.7c-0.26-2.34-0.52-4.68-0.77-7.03c-0.71-6.5-1.39-13.03-2.05-19.51 c-1.02-9.88-1.99-19.71-2.95-29.36c-2.76-27.84-5.62-56.63-9.24-85.2c-0.52,0.04-1.04,0.09-1.57,0.12 c-1.05,0.07-2.11,0.1-3.17,0.12c-4.5,0.08-9.12-0.2-13.63-0.47c-11.71-0.71-23.81-1.43-34.14,3.98 c-14.18,21.48-26.64,44.26-38.71,66.29C475.81,1062.27,467.76,1076.97,459.25,1091.34z"/> <path class="st35" d="M500.16,1311.25c-0.37,0.52-0.74,1.03-1.11,1.55c4.35,2.7,8.48,5.96,12.48,9.3 c1.33,1.11,2.64,2.23,3.95,3.34c0.56,0.47,1.12,0.96,1.69,1.44c0.28,0.24,0.56,0.48,0.85,0.72c0.57,0.47,1.13,0.96,1.7,1.43 c0.71,0.59,1.43,1.18,2.16,1.77c0.43,0.35,0.86,0.7,1.3,1.05c0.58,0.46,1.17,0.92,1.76,1.38c6.2,4.76,12.87,8.91,20.63,11.08 c49.44,2.83,99.79,4.2,148.48,5.52c9.12,0.25,18.34,0.51,27.62,0.77c12.75,0.36,25.59,0.74,38.44,1.16 c7.56,0.26,15.11,0.52,22.65,0.8v-29.98c-17.51-3.5-35.32-7.15-52.54-10.68c-34.44-7.05-70.06-14.34-105.08-20.85 c-36.03-3-73.03-3-108.83-3c-3,4.13-5.86,8.32-8.63,12.38c-1.38,2.02-2.79,4.09-4.22,6.15c-0.71,1.04-1.44,2.08-2.17,3.11 C500.9,1310.21,500.54,1310.73,500.16,1311.25z"/> <path class="st29" d="M501.29,815.89c7.38,50.17,15.01,102.04,24.01,152.32c5.16,0,10.4,0.12,15.46,0.24 c12.54,0.3,25.5,0.61,37.81-1c23.28-17.2,45.97-35.79,67.92-53.77c10.64-8.71,21.64-17.73,32.63-26.52 c-22.77-9.51-45.69-18.86-68.59-28.06c-6.38-2.56-12.75-5.12-19.12-7.66c-5.02-2-10.04-3.99-15.04-5.98 c-14.09-5.6-28.13-11.14-42.1-16.63c-7.37-2.9-14.71-5.79-22.03-8.65C508.58,818.75,504.93,817.32,501.29,815.89z"/> <path class="st36" d="M586.86,973.51c-0.91,30.07,2.95,60.65,6.67,90.22c2.41,19.13,4.91,38.91,6.09,58.36 c94.34-21.04,189.89-43.74,282.29-65.7c9.96-2.36,19.93-4.73,29.9-7.1c-86.33-61.91-157.63-111.98-224.39-157.6 c-6.17,5.33-12.42,10.57-18.71,15.75c-1.8,1.49-3.59,2.96-5.4,4.43c0,0.01,0,0.01-0.01,0.01c-6.43,5.24-12.88,10.41-19.29,15.52 c-3.98,3.17-7.93,6.31-11.86,9.43c-2.8,2.23-5.63,4.47-8.45,6.72c-1.89,1.5-3.78,3.01-5.68,4.52 C607.61,956.41,597.1,964.9,586.86,973.51z"/> <path class="st37" d="M604.14,1144.72c3.17,19.32,7.21,38.99,11.12,58c0.33,1.63,0.67,3.27,1.01,4.91 c0.67,3.28,1.35,6.57,2.02,9.88c1.95,9.6,3.86,19.3,5.63,29.05c0.1,0.56,0.21,1.13,0.3,1.69c0.57,3.09,1.11,6.19,1.63,9.3 c0.52,3.09,1.03,6.19,1.51,9.28c0.83,5.31,1.6,10.62,2.28,15.92c23.65,4.13,47.49,9.09,70.56,13.89 c23.04,4.79,46.85,9.74,70.47,13.87c-8.13-8.36-16.36-16.8-24.69-25.3c-3.33-3.4-6.67-6.81-10.03-10.24 c-5.87-5.99-11.79-12-17.75-18.04c-3.07-3.11-6.15-6.22-9.24-9.35C675.16,1213.46,640.06,1178.75,604.14,1144.72z"/> <path class="st38" d="M720.55,1103.64c-38.6,9.13-76.99,18.38-114.89,27.51c47.34,48.53,96.54,97.01,144.12,143.88 c12.04,11.86,24.49,24.12,36.74,36.22c18.39-36.79,37.53-74.04,56.04-110.06c23.76-46.25,48.33-94.08,71.54-141.34 c-7.12,1.51-14.25,3.03-21.39,4.57c-7.5,1.61-14.99,3.25-22.5,4.9c-3.61,0.79-7.23,1.59-10.85,2.39 c-2.16,0.47-4.32,0.96-6.49,1.44c-30.98,6.89-62.02,14-92.99,21.23c-0.19,0.04-0.38,0.09-0.57,0.13 C746.38,1097.53,733.45,1100.58,720.55,1103.64z"/> <path class="st39" d="M681.49,727.37c11.06,28.01,22.5,56.98,36.73,83.96c24.47,14.43,50.86,25.87,76.38,36.92 c4.95,2.15,10.07,4.37,15.08,6.56C771.84,813.46,728.7,770.58,681.49,727.37z"/> <path class="st10" d="M716.72,822.64c-7.37,19.91-15,40.51-22.5,61.51c9.71,6.67,19.43,13.46,29.1,20.29 c11.29,7.96,22.52,15.97,33.62,23.92c4.76,3.41,9.49,6.8,14.2,10.18c8.37,6,16.8,12.05,25.28,18.1 c3.76,2.69,7.54,5.38,11.33,8.06c33.16,23.55,67.12,47.05,101.82,68.78c-10.55-24.05-22.26-48.29-33.57-71.72 c-8.81-18.24-17.92-37.11-26.45-55.81c-1.44-2.7-2.73-5.63-3.98-8.45c-3.98-9.01-8.09-18.32-17.78-22.32 C791.65,857.47,754.27,839.17,716.72,822.64z"/> <path class="st40" d="M923.14,1065.89c-17.17,29.85-33.05,60.88-47.24,92.23c24.13-6.66,46.34-13.47,65.98-20.25 C935.98,1114.28,929.88,1089.89,923.14,1065.89z"/> <path class="st41" d="M930.74,1052.28c0,5.24,0.65,10.5,2.19,15.8c1.31,5.25,2.69,10.55,4.07,15.83 c1.39,5.28,2.8,10.53,4.18,15.7c0.69,2.58,1.39,5.18,2.08,7.79c0.44,1.66,0.88,3.31,1.32,4.98c0.61,2.28,1.21,4.57,1.81,6.86 c1.03,3.96,2.05,7.92,3.03,11.85c12.12-14.32,23.66-29.36,34.83-43.89c4.05-5.28,8.24-10.73,12.42-16.11 c-1.54-2.66-3.06-5.33-4.57-8.02c-1.32-2.33-2.61-4.66-3.9-7c-1.85-3.35-3.68-6.7-5.49-10.05c-2.72-5.02-5.4-10.02-8.04-14.95 c-8.07-15.07-16.41-30.64-25.24-45.49c-1.97,6.88-4.55,13.71-7.28,20.94C936.52,1021.42,930.74,1036.71,930.74,1052.28z"/> <path class="st42" d="M969.62,912.06c-5.93,19.13-12.07,38.91-15.67,59.17c9.46,20.91,20.81,41.6,31.79,61.61 c5.61,10.24,11.42,20.82,16.98,31.43c3.75-4.92,7.61-9.89,11.47-14.82c2.31-2.96,4.62-5.89,6.9-8.8 c1.52-1.94,3.06-3.89,4.6-5.85c4.62-5.89,9.28-11.87,13.79-17.78c-18.66-47.79-38.35-96.25-58.52-144.05 C977.65,886.17,973.57,899.33,969.62,912.06z"/> </g> </g> </g> </g> ';
        string memory image2 = string(abi.encodePacked('<text fill="#ffffff" x="-440" y="1650" class="small">Attack: ',attack,' &#9876;</text> <text fill="#ffffff" x="-440" y="1730" class="small">Defense: ',defense,' &#128737;</text> <text fill="#ffffff" x="-440" y="-70" class="small">Alive: ',_daysAlive,' Days &#9200;</text> <text fill="#ffffff" x="-440" y="6" class="small">Level: ',_level,' &#127894;</text>'));
        string memory image3 = string(abi.encodePacked(' <text fill="#ffffff" x="405" y="-95" class="small"># ',tokenId,'</text> <text fill="#ffffff" x="1065" y="-70" class="small">Revived: ',_revived,'</text> <text fill="#ffffff" x="295" y="1730" class="small">Kills Count: ',kills.toString(),' &#128128;</text> <text fill="#ffffff" x="1060" y="1730" class="small">Team Rabbit &#129365;</text> </svg>'));
        string memory result = string(abi.encodePacked(image1,image2,image3));
        return result;
    }

    function calculateDaysAlive(uint256 timestamp) internal view returns(uint256) {
        return (((block.timestamp - timestamp) / 86400)+1);
    }

    function calculatePlayerLevel(uint256 timestamp, uint256 kills) internal view returns(uint256) {
        return calculateDaysAlive(timestamp)/10 + kills/2;
    }

    function revivedToString(bool revived) internal pure returns(string memory) {
        if (revived) {
            return "Yes &#128519;";
        } else {
            return "No &#128512;";
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library RabbitColorsHelper {
    function RabbitString(string[] memory colors) public pure returns (string memory) {
        string memory image1 = string(abi.encodePacked('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) format("woff"); font-weight: normal; font-style: normal; } .small { font: 50px myFont , Times New Roman , Times ; } .st0{fill:hsl(235, 100%,65%);} .st1{fill:#151515;} .st3{fill:#D42528;} .st6{fill:hsl(',colors[0],', 50%, 50%);} .st7{fill:hsl(',colors[1],', 50%, 50%);} .st8{fill:hsl(',colors[2],', 50%, 50%);}  .st9{fill:hsl(',colors[3],', 50%, 50%);}'));
        string memory image2 = string(abi.encodePacked('.st10{fill:hsl(',colors[4],', 90%, 20%);} .st11{fill:hsl(',colors[5],', 50%, 50%);} .st12{fill:hsl(',colors[6],', 75%, 65%);} .st13{fill:hsl(',colors[7],', 90%, 70%);}'));
        string memory image3 = string(abi.encodePacked('.st14{fill:hsl(',colors[8],', 90%, 20%);} .st15{fill:hsl(',colors[9],', 50%, 50%);} .st17{fill:hsl(',colors[10],', 75%, 65%);} .st18{fill:hsl(',colors[11],', 90%, 70%);}'));
        string memory image4 = string(abi.encodePacked('.st19{fill:hsl(',colors[12],', 90%, 20%);} .st20{fill:hsl(',colors[13],', 50%, 50%);} .st21{fill:hsl(',colors[14],', 75%, 65%);} .st22{fill:hsl(',colors[15],', 90%, 70%);} '));
        string memory image5 = string(abi.encodePacked('.st23{fill:hsl(',colors[16],', 90%, 20%);} .st24{fill:hsl(',colors[17],', 50%, 50%);} .st26{fill:hsl(',colors[18],', 75%, 65%);} .st28{fill:hsl(',colors[19],', 90%, 70%);}'));
        string memory image6 = string(abi.encodePacked('.st29{fill:hsl(',colors[20],', 90%, 20%);} .st30{fill:hsl(',colors[21],', 50%, 50%);} .st31{fill:hsl(',colors[22],', 75%, 65%);} .st32{fill:hsl(',colors[23],', 90%, 70%);}'));
        string memory image7 = string(abi.encodePacked('.st33{fill:hsl(',colors[24],', 90%, 20%);} .st35{fill:hsl(',colors[25],', 50%, 50%);} .st36{fill:hsl(',colors[26],', 75%, 65%);} .st37{fill:hsl(',colors[27],', 90%, 70%);}'));
        string memory image8 = string(abi.encodePacked('.st38{fill:hsl(',colors[28],', 90%, 20%);} .st39{fill:hsl(',colors[29],', 50%, 50%);} .st40{fill:hsl(',colors[30],', 75%, 65%);} .st41{fill:hsl(',colors[31],', 90%, 70%);}'));
        string memory image9 = string(abi.encodePacked('.st42{fill:hsl(',colors[32],', 90%, 20%);} .st43{fill:hsl(',colors[33],', 50%, 50%);} .st44{fill:hsl(',colors[34],', 75%, 65%);} </style>  <defs> <linearGradient cx="0.25" cy="0.25" r="0.75" id="grad1" gradientTransform="rotate(45)"> <stop offset="0%" stop-color="hsl(220, 310%, 50%)"/> <stop offset="50%" stop-color="hsl(230, 310%, 60%)"/> <stop offset="100%" stop-color="hsl(245, 201%, 50%)"/> </linearGradient> </defs>'));
        string memory result = string(abi.encodePacked(image1,image2,image3,image4,image5,image6,image7,image8,image9));
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library RabbitDeadHelper {
    function RabbitString() public pure returns (string memory) {
        string memory image1 = string(abi.encodePacked('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) format("woff"); font-weight: normal; font-style: normal; } .small { font: 50px myFont , Times New Roman , Times ; } .big { font:  53px myFont , Times New Roman , Times ; } .st0{fill:#d0d4d7;} '));
        string memory image2 = string(abi.encodePacked('</style> <rect class="st0" x="-500" y="-500" width="2000" height="2300"/> <text x="210" y="10" class="big" fill="#b90e16">Player Eliminated &#128565;</text> <g> <g> <g id="XMLID_1_"> <g> <path class="st1" d="M108.05,521.75c7.31-9.72,14.88-19.76,22.39-29.43c16.75-19.48,37.83-36.51,64.46-52.07 c24.46-14.29,50.57-25.63,75.16-35.75l0.01-0.01v-0.02c-0.79-19.41-2.08-39.21-3.32-58.35c-1.74-26.76-3.53-54.42-4.03-81.63 c-0.27-14.65-0.15-27.99,0.37-40.78c0.58-14.36,1.63-27.67,3.23-40.68c1.41-10.44,1.88-21.39,2.33-31.98 c0.75-17.68,1.52-35.97,6.67-52.83c16.91-11.45,34.73-22.18,51.96-32.56c6.38-3.84,12.97-7.81,19.32-11.7 c4.93,14.57,10.14,29.21,15.18,43.38c5.89,16.56,11.98,33.7,17.57,50.57c6.27,18.9,11.27,35.54,15.28,50.9 c-6.99,26.64-16.19,52.93-25.08,78.36c-5.57,15.9-11.32,32.34-16.44,48.63c-5.74,18.26-10.08,34.42-13.27,49.41l-0.02,0.12 l0.07-0.09c4.71-6.28,8.2-13.67,11.57-20.82c3.14-6.67,6.4-13.57,10.63-19.52c2.28-3.2,4.65-5.86,7.25-8.17 c2.92-2.58,6.05-4.63,9.58-6.28c62.93-38.9,126.09-80.27,187.17-120.28c19.08-12.5,38.8-25.41,58.25-38.08 c-3.34,17.96-9.11,35.28-14.68,52.02c-4.43,13.29-9.01,27.04-12.33,41c-1.11,4.43-2.25,9.01-3.94,13.14 c-1.89,4.62-4.29,8.18-7.31,10.88c-12.93,12.07-26.32,23.57-39.27,34.7c-9.57,8.22-19.46,16.72-29.05,25.35 c-7.4,7.02-16.17,13.5-26.79,19.84c-9.48,5.65-19.55,10.68-29.3,15.53c-14.23,7.09-28.95,14.43-42.24,23.93l-0.01,0.01 c-7.08,14.16-13.04,27-18.21,39.22c-6.07,14.37-10.92,27.56-14.82,40.35c-0.93,19.81,1.29,39.61,3.43,58.75 c1.35,12,2.74,24.41,3.32,36.6c0.25,7.23,1.95,14.65,5.21,22.65c2.9,7.13,6.74,14.07,10.45,20.77 c2.59,4.68,5.27,9.52,7.61,14.38l0.01,0.02h0.01c14.34,0.47,29.5-1.44,44.16-3.29c15.77-1.99,32.08-4.06,47.68-3.22 c8.4,0.45,15.91,1.69,22.96,3.77c7.92,2.34,15.05,5.69,21.81,10.24c15.16,8.62,31.17,16.55,46.67,24.21 c23.7,11.73,48.22,23.87,70.45,38.84c15.75,15.55,31.89,31.31,47.49,46.55C759.31,789,802.4,831.08,842.8,873.67 c20.15,38.18,38.72,77.74,56.68,116c7.46,15.88,15.17,32.31,22.89,48.39l0.02,0.05l0.02-0.05 c10.24-27.98,18.28-57.22,26.06-85.49c4.66-16.97,9.49-34.51,14.74-51.59c5.88-19.14,11.68-35.67,17.73-50.53 c15.35,33.96,29.48,69.34,43.15,103.57c8.37,20.97,17.04,42.66,25.88,63.77c-1.89,2.46-3.78,4.91-5.66,7.37 c-30.92,40.28-60.11,78.31-91.92,116.48c-7.48,4.4-16.06,8.23-26.22,11.71c-9.07,3.11-18.54,5.65-27.7,8.11 c-9.72,2.61-19.77,5.32-29.39,8.7l-0.01,0.01l-0.01,0.01l-69.81,135.12c-1.81,2.97-3.22,6.08-4.32,9.52 c-0.98,3.06-1.69,6.31-2.16,9.94c-0.88,6.73-0.8,13.74-0.72,20.52c0.06,5.39,0.12,10.96-0.3,16.31 c-39.58-2.1-79.82-3.08-118.73-4.01c-44.49-1.08-90.48-2.19-135.72-4.99c-12.65-6.85-23.91-16.75-34.81-26.33 c-4.56-4-9.27-8.14-13.96-11.94c3.75-6,7.76-11.91,11.63-17.63c3.87-5.71,7.87-11.63,11.63-17.62 c15.48,0.3,31.05,0.86,46.11,1.4c22.06,0.79,44.87,1.6,67.23,1.6h0.03l-0.01-0.03c-0.32-1.13-0.63-2.29-0.93-3.41 c-1.67-6.15-3.4-12.51-6.07-18.27c-1.43-3.1-3.01-5.77-4.82-8.17c-2.03-2.7-4.31-4.97-6.95-6.95 c-13.21-12.81-26.55-25.95-39.44-38.66c-35.48-34.97-72.16-71.14-110.69-104.71l-0.04-0.03l-0.01,0.04 c-3.2,19.91-4.98,40.48-6.69,60.37c-1.77,20.44-3.59,41.57-6.95,62.03c-1.81,11.01-3.92,20.95-6.42,30.39 c-2.81,10.59-6.07,20.28-9.96,29.62c-4.21,16.25-18.11,25.28-31.55,34c-3.25,2.11-6.61,4.29-9.73,6.52 c-19.18,15.98-43.14,12.64-66.32,9.41c-9.38-1.3-19.08-2.66-28.22-2.66c6.71-20.97,12.67-38.6,18.75-55.49 c14.76,2.95,30.01,6,45.02,8.25l0.02,0.01v-0.03c1.65-16.28,3.37-32.85,5.04-48.87c5.16-49.76,10.51-101.22,14.48-152.31 l0.01-0.06l-0.04,0.04c-5.61,4.49-12.37,8.49-19.51,12.72c-10.58,6.27-21.52,12.75-29.04,21.18c-4.06,4.56-6.75,9.25-8.24,14.35 c-0.8,2.76-1.24,5.69-1.31,8.68c-0.07,3.15,0.29,6.48,1.04,9.91l0.01,0.01l0.01,0.01c5.11,2.63,9.31,5.97,12.82,10.22 c3.12,3.76,5.63,8.14,7.65,13.39c3.76,9.71,5.2,20.76,6.6,31.44c0.44,3.38,0.9,6.88,1.42,10.21 c-23.03-2.98-45.78-8.09-69.01-13.51c-2.5-5-5.13-10.08-7.67-15c-5.08-9.84-10.34-20.02-14.85-30.03 c-2.13-9.09-3.22-18.06-3.47-26.96c-0.05-1.84-0.06-3.67-0.04-5.5c0.01-1.12,0.04-2.24,0.08-3.36c0-0.01,0-0.01,0-0.01 c0.21-5.75,0.74-11.46,1.56-17.13c0.16-1.14,0.34-2.27,0.52-3.4c0.09-0.57,0.19-1.13,0.29-1.7c0.1-0.57,0.2-1.13,0.3-1.69 c0.16-0.93,0.34-1.85,0.53-2.78c0.1-0.49,0.19-0.97,0.3-1.47c0.12-0.61,0.26-1.23,0.39-1.85c0.12-0.55,0.24-1.1,0.37-1.66 c5.23-23.17,14.57-46.05,24.69-69.11l0.01-0.02l-0.02-0.01c-12.75-8.39-26.5-15.75-39.8-22.87 c-18.87-10.1-38.38-20.54-55.53-34.18c-8.99-28.4-16-57.54-22.78-85.72c-3.96-16.47-8.06-33.51-12.5-50.14 c-2.92-8.17-5.02-16.57-6.42-25.67c-1.24-8.12-1.89-16.61-1.99-25.98c-0.17-17.4,1.67-35.24,3.44-52.5 c1.71-16.57,3.47-33.7,3.47-50.48v-0.01l-0.01-0.01c-8.46-5.19-17.7-9.77-26.63-14.2c-15.76-7.82-32.05-15.9-45.42-27.84 c-2.2-10.97-3.64-22.05-5.02-32.76c-0.98-7.51-1.99-15.29-3.23-22.76C81.11,557.53,94.81,539.33,108.05,521.75z M80.12,608.68 c1.57,1.15,3.23,1.81,4.92,1.97c0.26,0.02,0.52,0.04,0.78,0.04c1.28,0,2.56-0.29,3.81-0.87c1.93-0.9,3.73-2.49,5.05-4.49 c1.31-1.97,2.11-4.26,2.27-6.43c0.17-2.49-0.51-4.7-1.92-6.42c-0.12-0.14-0.24-0.28-0.37-0.41c-0.51-0.54-1.08-1.03-1.74-1.45 c-1.69-1.26-3.43-2.02-5.19-2.25c-1.6-0.21-3.18,0.01-4.7,0.67c-1.85,0.81-3.5,2.22-4.77,4.09c-1.25,1.83-2.03,3.94-2.25,6.08 c-0.19,1.81,0.04,3.6,0.67,5.16C77.37,606.1,78.53,607.55,80.12,608.68z M92.13,581.29c4.43,2.03,9.01,4.13,13.51,6.38 l0.02,0.01l0.01-0.03c2.53-9.01,5.43-18.17,8.23-27.03c4.67-14.76,9.5-30.03,12.78-45.04l0.02-0.09l-0.07,0.07 c-13.41,13.41-24.97,28.79-36.16,43.68c-3.86,5.13-7.85,10.45-11.88,15.63l-0.02,0.02l0.03,0.01 C83.12,577.16,87.7,579.26,92.13,581.29z M86.87,628.95c20.66,11.81,42.02,24.02,63.81,35.28l0.02,0.01l0.01-0.02 c9.76-15.02,19.52-30.03,29.28-45.05l0.02-0.02l-0.03-0.01c-2.92-0.91-5.85-1.81-8.77-2.69c-2.66-0.8-5.32-1.59-7.98-2.36 c-1.49-0.43-2.98-0.86-4.48-1.3c-2.41-0.69-4.81-1.37-7.2-2.05c-2.09-0.59-4.17-1.18-6.24-1.75c-0.33-0.09-0.67-0.18-1-0.27 c-1.74-0.49-3.48-0.97-5.22-1.45c-0.01,0-0.01,0-0.01,0c-2.91-0.8-5.82-1.6-8.7-2.39c-0.18-0.05-0.37-0.1-0.55-0.15 c-6.92-1.89-14.07-3.86-21.18-5.86l-0.02-0.01l-0.01,0.01c-8.03,11.61-15.16,21.43-21.77,30.03l-0.02,0.02L86.87,628.95z M116.93,580.91c17.65-10.22,34.99-21.47,51.76-32.35c10.32-6.69,20.98-13.61,31.57-20.19l0.01-0.01v-0.02 c-1.57-27.52-3.05-52.38-5.26-78.07l-0.01-0.05l-0.04,0.03c-4.4,3.35-9,6.65-13.45,9.84c-11.58,8.29-23.56,16.87-33.84,27.7 l-0.01,0.01c-9.04,22.61-16.46,46.73-23.63,70.06c-2.33,7.58-4.74,15.43-7.15,23.03l-0.02,0.07L116.93,580.91z M172.29,607.68 c3.76,1.07,7.64,2.17,11.43,3.25l0.02,0.01l0.01-0.02c5.16-22.88,10.51-46.54,14.26-70.57l0.01-0.05l-0.05,0.03 c-2,1.25-4.01,2.53-6.06,3.81c-0.6,0.38-1.21,0.76-1.81,1.15c-1.27,0.79-2.54,1.6-3.82,2.41c-3.18,2.02-6.41,4.07-9.66,6.15 c-1.63,1.04-3.26,2.08-4.9,3.14c0,0,0,0.01-0.01,0.01c-6.56,4.23-13.21,8.56-19.86,12.99c0,0,0,0-0.01,0.01 c-1.66,1.1-3.32,2.22-4.98,3.33c-9.13,6.14-18.21,12.44-26.96,18.8l-0.04,0.03l0.05,0.02 C137.14,597.71,155.01,602.78,172.29,607.68z M189.71,950.23l0.01,0.05l0.04-0.04c17.78-25.4,36.02-51.19,53.66-76.13 c50.25-71.03,102.21-144.48,150.52-218.89l0.05-0.08l-0.09,0.04c-21.2,10.89-42.34,22.23-63.32,33.8 c-11.3,6.22-22.55,12.51-33.75,18.81c-19.2,10.82-38.23,21.7-57.02,32.43c-4,2.28-8.01,4.58-12.05,6.89 c-3.23,1.85-6.48,3.7-9.73,5.55c-0.44,0.25-0.87,0.49-1.3,0.74c-3.62,2.06-7.25,4.13-10.89,6.2c-1.91,1.08-3.81,2.17-5.72,3.25 c-5.72,3.25-11.45,6.49-17.2,9.73c-11.49,6.47-23.01,12.9-34.48,19.22l-0.02,0.01l0.01,0.02 C160.35,838.9,174.59,894.54,189.71,950.23z M149.2,780.59c19.62-10.92,39.13-21.8,58.5-32.61c5.28-2.95,10.56-5.89,15.82-8.84 c9.36-5.23,18.68-10.44,27.97-15.64c7.36-4.12,14.7-8.23,22.01-12.33c8.17-4.58,16.31-9.15,24.43-13.7 c5.38-3.01,10.75-6.03,16.1-9.04c21.48-12.07,42.73-24.02,63.69-35.85c4.9-2.76,9.79-5.52,14.65-8.26 c5.54-3.13,11.06-6.25,16.56-9.36l0.02-0.02l-0.02-0.02c-3.33-4.17-5.66-9.51-7.9-14.68c-1.97-4.53-3.83-8.81-6.32-12.36 c-1.33-1.92-2.72-3.43-4.24-4.64c-1.71-1.35-3.53-2.28-5.58-2.86h-0.01h-0.01c-19.38,4.06-39.09,8.74-58.56,13.9 c-19.01,5.04-38.36,10.68-57.51,16.78c-18.66,5.94-37.67,12.49-56.52,19.46c-11.45,4.24-23.06,8.71-34.68,13.36 c-6.98,2.79-13.96,5.65-20.93,8.56l-0.01,0.01l-0.01,0.07c-0.44,5.33-0.89,10.69-1.33,16.07c-0.22,2.64-0.43,5.29-0.65,7.95 c-0.14,1.74-0.28,3.48-0.42,5.22c-1.55,19.26-2.99,38.71-4.07,58.1c-0.4,6.92-0.74,13.82-1.02,20.7v0.05L149.2,780.59z M165.72,658.98c24.88-8.06,49.44-17.63,75.07-29.28l0.08-0.04l-0.09-0.01c-1.73-0.3-3.45-0.6-5.16-0.9 c-0.5-0.09-0.99-0.18-1.49-0.26c-2.83-0.49-5.63-0.99-8.42-1.47c-2.47-0.43-4.91-0.85-7.36-1.26c-1.03-0.18-2.06-0.35-3.09-0.52 c-0.93-0.16-1.87-0.31-2.8-0.46c-7.51-1.24-15.02-2.38-22.72-3.39l-0.02-0.01l-0.01,0.02c-8.93,12.98-17.01,25.61-24.02,37.53 l-0.04,0.06L165.72,658.98z M192.73,613.19c7.59,1.05,15.19,2.2,22.55,3.32c13.68,2.08,27.83,4.23,42.01,5.69l0.02,0.01 l0.01-0.02c6.43-21.23,13.5-42.74,20.34-63.55c11.57-35.2,23.54-71.59,32.96-108.35l0.02-0.07l-0.06,0.04 c-33.6,25.02-69.03,52.52-100.6,84.08l-0.01,0.01c-4.71,16.03-8,32.95-11.19,49.3c-1.89,9.71-3.84,19.76-6.08,29.53l-0.01,0.03 H192.73z M203.23,966.01c28.9,16.89,58.66,33.87,87.45,50.29c28.79,16.42,58.56,33.4,87.46,50.29l0.04,0.02v-0.04 c0.44-13.64,1.87-27.66,3.26-41.21c1.67-16.4,3.41-33.35,3.43-49.94c0.01-8.93-0.46-17.03-1.44-24.77 c-1.11-8.68-2.82-16.69-5.24-24.47c-6.17-24.38-12.03-49.31-17.69-73.44c-7.42-31.61-15.08-64.29-23.6-96.21l-0.01-0.05 l-0.04,0.04l-55.4,79.28c-25.07,35.88-50.14,71.75-75.22,107.64c-0.57,0.92-1.33,2-2.14,3.14c-1.61,2.27-3.43,4.84-4.7,7.42 c-1.47,3.01-1.9,5.42-1.3,7.39C198.7,963.41,200.44,964.96,203.23,966.01z M209.22,520.08v0.05l0.04-0.03 c29.29-23.19,57.96-47.18,85.88-70.8c6.45-5.45,12.85-10.88,19.21-16.27l0.03-0.03l-0.04-0.02c-0.85-0.42-1.69-0.85-2.55-1.27 c-1.71-0.85-3.43-1.7-5.15-2.55c-4.32-2.12-8.67-4.24-12.94-6.32c-4.27-2.08-8.64-4.2-12.95-6.33c-1.72-0.85-3.45-1.7-5.15-2.55 c-0.85-0.42-1.7-0.85-2.55-1.27l-0.01-0.01l-0.01,0.01c-15.22,7.11-30.8,14.37-46.61,21.15c-7.19,3.08-14.43,6.06-21.7,8.87 l-0.02,0.01v0.02C204.72,469.03,207.11,496.16,209.22,520.08z M260.29,1148.43c7.89,0.75,15.72,1.71,23.29,2.63 c7.56,0.92,15.38,1.88,23.26,2.62h0.02v-0.02c0.4-5.91,1-11.66,1.59-17.22c0.54-5.18,1.06-10.07,1.41-15.07l0.01-0.02 l-0.05-0.02c-1.02-0.46-2.03-0.93-3.05-1.39c-1.76-0.8-3.53-1.6-5.31-2.41c-11.54-5.23-23.29-10.49-34.95-15.39 c-2.07-0.87-4.13-1.73-6.2-2.57l-0.04-0.01v48.86H260.29z M262.59,1089.89c3.2,1.39,6.41,2.79,9.65,4.2 c2.13,0.93,4.26,1.86,6.41,2.8c7.58,3.31,15.26,6.7,23.04,10.18c2.22,1,4.44,2,6.67,3.01c2.23,1.01,4.48,2.03,6.72,3.06 l0.02,0.01l0.01-0.01c11.85-9.01,24.27-17.9,36.28-26.51c7.05-5.05,14.34-10.27,21.52-15.53l0.04-0.02l-0.04-0.02 c-10.95-6.05-22.18-11.97-33.05-17.7c-17.41-9.18-35.41-18.67-52.53-28.85l-0.02-0.01l-0.01,0.03 c-2.75,7.25-5.64,14.63-8.42,21.77c-5.58,14.27-11.35,29.02-16.35,43.54l-0.01,0.02L262.59,1089.89z M282.04,1194.2l0.01,0.01 h0.01c17.28,3.01,34.83,6.82,51.8,10.51l0.04,0.01l-0.01-0.04c-1.47-11.81-3-24.02-5.26-36.78v-0.02h-0.02 c-1.75-0.38-3.53-0.74-5.32-1.11c-1.2-0.24-2.41-0.47-3.62-0.71c-2.44-0.47-4.91-0.93-7.43-1.37 c-11.26-1.99-23.38-3.75-36.59-5.29c-0.17-0.02-0.34-0.04-0.52-0.06c-1.31-0.15-2.63-0.3-3.96-0.45 c-2.34-0.26-4.71-0.52-7.12-0.77l-0.05-0.01l4.52,9.05C273.03,1176.19,277.54,1185.19,282.04,1194.2z M267.81,620.7 c33.79-8.45,71.24-18.23,117.86-30.78l0.02-0.01v-0.02c-2.95-36.16-6-73.56-10.51-110.35v-0.01l-0.01-0.01 c-11.08-8.18-21.97-16.78-32.51-25.1c-5.83-4.6-11.87-9.37-17.79-13.94l-0.03-0.02l-0.01,0.03 c-19.51,60.04-38.59,121.08-57.04,180.11l-0.03,0.1L267.81,620.7z M278.29,393.22c0,3.42,0.69,6.42,2.13,9.15 c1.27,2.43,3.11,4.6,5.6,6.62c1.45,1.18,3.06,2.23,4.76,3.23c0.68,0.4,1.38,0.78,2.09,1.15c1.07,0.56,2.16,1.1,3.27,1.61 c1.48,0.69,2.99,1.36,4.51,2.01c0.76,0.32,1.51,0.65,2.27,0.97c5.68,2.42,11.56,4.92,15.92,8.31l0.03,0.02l0.01-0.04 c6-24.79,11.35-50.73,16.52-75.82v-0.01l-0.01-0.01c-2.64-3.57-5.27-7.19-7.9-10.83c-1.26-1.75-2.53-3.5-3.78-5.26 c-4.8-6.67-9.55-13.37-14.23-19.94c-9-12.67-18.23-25.65-27.65-38.4c-1.57-2.13-3.15-4.24-4.73-6.35 c-1.58-2.11-3.17-4.21-4.77-6.3l-0.05-0.06v0.08C272.96,302.85,274.92,345.33,278.29,393.22z M273.03,242.34 c1.49,3.2,3.12,6.44,4.91,9.76c0.71,1.32,1.45,2.66,2.21,4c1.52,2.69,3.14,5.43,4.87,8.22c2.16,3.49,4.48,7.07,6.97,10.75 c7.12,10.5,14.94,20.85,22.51,30.86c7.26,9.6,14.76,19.52,21.58,29.5l0.05,0.07v-0.09c1.47-87.08,3-177.13,'));
        string memory result = string(abi.encodePacked(image1,image2));
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library RabbitDeadHelper2 {
    using Strings for uint256;
    function RabbitString(string memory attack, string memory defense, uint256 kills, bool revived, string memory tokenId, uint256 mintTimestamp) public view returns (string memory) {
        string memory _level = calculatePlayerLevel(mintTimestamp, kills).toString();
        string memory _revived = revivedToString(revived);
        string memory image0 = string(abi.encodePacked('3.75-265.74v-0.04 l-0.04,0.02c-3.18,1.83-6.41,3.68-9.54,5.46c-15.95,9.1-32.44,18.51-47.52,29.82l-0.01,0.01v0.01c-2.82,24.17-5.3,46-7.13,68.41 C273.55,199.16,272.69,221.72,273.03,242.34L273.03,242.34z M306.84,1310.57c6.18-1.24,21.27-4.35,28.43-6.72 c-5.29,5.29-15.72,15.72-20.94,20.94l-0.04,0.04l0.06,0.01c5.25,0.25,10.59,0.67,15.75,1.08c8.19,0.65,16.61,1.32,24.97,1.32 c2.19,0,4.38-0.05,6.56-0.15h0.01c12.01-5.85,27.39-13.96,39.79-24.96c6.15-5.46,11.24-11.35,15.11-17.48 c4.31-6.84,7.31-14.28,8.92-22.13l0.01-0.05l-0.05,0.02c-16.76,7.36-31.53,14.26-45.14,21.11 c-15.59,7.84-29.78,15.66-43.39,23.9c0.8-3.26,1.07-6.16,0.79-8.63c-0.26-2.32-1.02-4.34-2.25-6c-1.81-2.45-4.66-4.21-8.7-5.36 c-3.16-0.91-7.11-1.46-12.41-1.74h-0.02l-0.01,0.02c-2.29,6.1-6.07,19.03-7.51,24.77l-0.01,0.04L306.84,1310.57z M378.02,470.47 l0.14,0.11l0.01-0.04c3.38-9.2,7.64-18.48,11.75-27.45c6.19-13.48,12.58-27.42,16.26-41.6c1.99-7.64,3.04-14.73,3.22-21.67 c0.21-7.79-0.68-15.2-2.71-22.64l-0.01-0.04l-0.03,0.03c-3.38,3-6.73,6.05-10.05,9.13c-5.79,5.35-11.5,10.8-17.14,16.3 c-4.09,3.96-8.13,7.95-12.14,11.94c-2.11,2.1-4.22,4.2-6.32,6.3c-1.05,1.05-2.1,2.09-3.15,3.15c-1.05,1.05-2.09,2.09-3.14,3.14 c-8.29,8.29-16.87,16.87-25.38,25.13l-0.02,0.02l0.02,0.02C345.07,445,361.82,457.95,378.02,470.47z M342.14,404.5 c26.51-23.9,52.09-48.19,76.53-72.63c1.36-1.35,2.71-2.71,4.06-4.07c0-0.01,0-0.01,0.01-0.01c2.7-2.72,5.38-5.43,8.05-8.15 c0.01-0.01,0.01-0.01,0.01-0.01c3.77-3.84,7.51-7.67,11.21-11.52c10.77-11.15,21.27-22.31,31.51-33.48l0.09-0.1l-0.12,0.05 c-14.24,6.53-29.22,14.74-45.79,25.1c-13.54,8.46-27.01,17.64-40.1,26.62c-1.22,0.83-2.43,1.66-3.64,2.49 c-1.45,0.99-2.92,2-4.4,3.02c-2.46,1.69-4.95,3.39-7.42,5.07l-0.01,0.01c-5.61,7.29-10.57,16-15.17,26.64 c-4.09,9.46-7.5,19.49-10.8,29.18c-0.16,0.49-0.33,0.97-0.5,1.46c-0.3,0.9-0.62,1.81-0.93,2.72c-0.86,2.52-1.75,5.07-2.63,7.56 l-0.04,0.1L342.14,404.5z M375.24,875.74c6.44,26.87,13.09,54.66,19.4,81.99v0.02h0.02c39.74,3.75,80.9,6.8,120.7,9.75 l0.19,0.01v-0.03L493.03,821.1c0-10.39-9.53-14.04-17.94-17.27c-1.35-0.52-2.62-1-3.84-1.52c-5.14-2.05-10.33-4.14-15.52-6.22 c-1.9-0.77-3.8-1.53-5.7-2.3c-4.24-1.71-8.47-3.41-12.64-5.09c-14.93-6.02-30.11-12.14-45.31-18.18 c-3.79-1.51-7.59-3.01-11.38-4.51c-0.01,0-0.01-0.01-0.02-0.01c-2.97-1.18-5.94-2.34-8.9-3.5c-8.42-3.3-16.81-6.56-25.14-9.74 l-0.04-0.02l0.01,0.05C355.6,793.78,365.58,835.45,375.24,875.74z M347.35,309.26l0.05-0.11c7.64-18.35,14.62-36.72,20.74-54.61 c6.39-18.69,12.04-37.44,16.8-55.74l0.01-0.01l-0.01-0.01c-2.78-12.63-6.59-26.19-11.66-41.43c-4.52-13.6-9.6-27.27-14.52-40.48 c-3.28-8.81-6.66-17.93-9.85-26.93l-0.05-0.14v0.15c0,27.28-0.65,55.14-1.27,82.08c-1.04,45.03-2.11,91.59-0.24,137.13 L347.35,309.26z M347.37,741.55c42.21,8.18,84.82,16.27,126.85,24.19c6.28,1.18,12.56,2.36,18.81,3.54 c11.42,2.15,22.79,4.29,34.08,6.41c14.99,2.82,30.11,5.66,45.31,8.53c6.28,1.18,12.58,2.37,18.88,3.56 c1.83,0.35,3.66,0.69,5.49,1.04c5.22,0.99,10.46,1.97,15.69,2.97c8.89,1.68,17.79,3.37,26.69,5.07 c10.58,2.01,21.16,4.03,31.74,6.06c12.02,2.31,24.04,4.62,36.01,6.94l0.05,0.01l-0.02-0.05c-5.63-12.33-11.07-25.17-16.33-37.6 c-5.36-12.66-10.82-25.56-16.64-38.29c-4.52-9.91-9.26-19.7-14.33-29.21l-0.01-0.01l-0.03-0.02c-0.01-0.01-0.02-0.01-0.03-0.02 c-8.23-4.38-16.5-8.79-24.83-13.2c-37.93-20.12-76.72-40.37-115.5-58.84h-0.01c-34.53,1.5-68.88,5.32-102.09,9.01h-0.01 l-0.02,0.04c-22.87,32.46-46.53,66.04-69.79,99.81l-0.02,0.03L347.37,741.55z M363.9,1281.29c22.52-9.76,44.65-21.2,66.05-32.27 l0.03-0.01v-0.02c2.03-23.68,5.49-47.6,8.83-70.73c4.07-28.16,8.29-57.29,9.94-86.16v-0.01l-0.01-0.01 c-20.67-44.05-37.85-79.35-54.05-111.11l-0.04-0.07l-0.01,0.09c-8.09,63.31-14.16,127.94-20.04,190.44 c-3.39,36.03-6.89,73.3-10.74,109.83v0.04L363.9,1281.29z M573.25,834.29c3.07,1.22,6.13,2.44,9.18,3.66 c0.4,0.16,0.79,0.31,1.18,0.47c6.72,2.67,13.49,5.37,20.28,8.08c12.31,4.9,24.72,9.87,37.14,14.87 c14.99,6.04,30,12.16,44.87,18.31h0.01l0.02,0.01v-0.01l0.01-0.02c3.75-10.13,7.76-20.24,11.63-30.02 c3.88-9.78,7.89-19.9,11.64-30.03l0.01-0.03l-0.03-0.01c-35.53-6.44-71.57-13.42-106.86-20.32c-6.89-1.35-13.76-2.7-20.58-4.04 c-6.91-1.35-13.85-2.72-20.81-4.07c-1.24-0.24-2.48-0.48-3.72-0.73c-6.97-1.36-13.96-2.72-20.98-4.09 c-45.81-8.89-92.39-17.67-138.57-25.31l-0.2-0.03l0.18,0.08C455.36,787.18,515.13,811.15,573.25,834.29z M438.22,1049.38 c2.31,4.71,4.63,9.41,6.96,14.08c2.91,5.84,5.83,11.64,8.76,17.39l0.02,0.04l0.02-0.04c1.06-1.71,2.12-3.42,3.17-5.14 c0.59-0.96,1.18-1.92,1.76-2.89c0.62-1.01,1.24-2.03,1.85-3.04c0.65-1.07,1.29-2.14,1.93-3.22c0.97-1.63,1.95-3.26,2.92-4.9 c0-0.01,0-0.01,0-0.01c2.41-4.09,4.8-8.19,7.17-12.31c0.32-0.57,0.65-1.13,0.97-1.7c1.05-1.83,2.09-3.66,3.13-5.49 c0,0,0.01-0.01,0.01-0.01c1.23-2.17,2.46-4.35,3.68-6.53c0-0.01,0.01-0.01,0.01-0.01c1.22-2.17,2.42-4.35,3.63-6.52 c9.71-17.54,19.11-35.2,28.34-52.56l0.02-0.04h-0.04c-25.65-2.56-51.84-4.47-77.17-6.31c-3.26-0.24-6.55-0.48-9.86-0.72 c-4.09-0.3-8.2-0.6-12.32-0.91c-0.23-0.02-0.46-0.04-0.68-0.05c-2.8-0.21-5.61-0.43-8.42-0.65c-1.63-0.12-3.27-0.25-4.9-0.38 h-0.05l0.03,0.05C411.88,994.57,424.93,1022.28,438.22,1049.38z M416.04,368.45c0.92,5.9,1.88,12.01,2.62,18.01l0.01,0.04 l0.03-0.02c13.39-5.82,26.23-12,38.16-18.38c12.8-6.84,25-14.13,36.26-21.69c11.97-8.02,23.26-16.6,33.58-25.49 c10.88-9.38,21.02-19.4,30.13-29.78l0.07-0.08l-0.09,0.04c-30.75,10.88-61.14,24.08-90.52,36.84 c-9.71,4.22-19.6,8.51-29.57,12.75c-5.54,2.35-11.08,4.69-16.64,6.98c-2.22,0.92-4.45,1.83-6.66,2.73l-0.02,0.01v0.01v0.02 C414.16,356.44,415.11,362.54,416.04,368.45z M439.71,326.43c16.79-5.17,34.88-11.72,55.31-20.04 c18.22-7.42,36.58-15.52,54.34-23.35c2.7-1.19,5.42-2.39,8.16-3.6c4.1-1.81,8.25-3.63,12.39-5.44c4.15-1.81,8.3-3.61,12.44-5.38 l0.01-0.01l0.01-0.01c13.51-20.55,18.31-45.39,22.96-69.39c1.27-6.6,2.59-13.41,4.06-19.94l0.02-0.07l-0.06,0.04 c-11.66,9.34-24.56,17.44-37.03,25.28c-9.83,6.18-19.99,12.56-29.49,19.52c-10.66,7.79-19.35,15.49-26.56,23.52 c-8.5,8.76-17.49,17.41-26.19,25.77c-17.39,16.73-35.37,34.04-50.38,53.05l-0.05,0.07L439.71,326.43z M459.2,1091.36 c9.54,9.12,19.12,18.35,28.6,27.53c4.21,4.07,8.41,8.14,12.58,12.19c3.13,3.03,6.25,6.06,9.34,9.06 c4.13,4.01,8.28,8.04,12.45,12.08c0,0,0,0,0.01,0.01c8.33,8.07,16.73,16.2,25.19,24.33c21.14,20.33,42.6,40.7,64.22,60.44 l0.05,0.05l-0.01-0.07c-2.82-21.33-7.22-42.6-11.48-63.16c-3.69-17.82-7.5-36.24-10.29-54.69c-2.08-18.72-3.95-37.62-5.77-55.9 c-2.76-27.85-5.61-56.66-9.24-85.23l-0.01-0.02h-0.02c-1.07,0.09-2.16,0.16-3.25,0.19c-3.98,0.15-8.08-0.02-12.14-0.25 c-1-0.05-2-0.12-3-0.18c-5.85-0.35-11.89-0.71-17.66-0.3c-6.47,0.46-11.87,1.86-16.51,4.29h-0.01l-0.01,0.01 c-14.18,21.49-26.65,44.27-38.71,66.3c-7.78,14.22-15.83,28.93-24.35,43.3l-0.01,0.02L459.2,1091.36z M498.99,1312.82 c5.82,3.6,11.22,8.2,16.45,12.65c2.23,1.91,4.51,3.85,6.84,5.73c0.58,0.47,1.17,0.94,1.76,1.4c1.77,1.38,3.57,2.72,5.41,3.97 c4.13,2.81,8.12,4.94,12.11,6.46c1.32,0.51,2.65,0.95,3.98,1.32c9.43,0.54,18.88,1.02,28.36,1.46c2.95,0.13,5.9,0.27,8.85,0.4 c12.44,0.55,24.88,1.03,37.31,1.46c24.86,0.86,49.62,1.54,73.97,2.2c29.04,0.79,59.06,1.61,88.73,2.73l0.03,0.01v-30.08 l-0.02-0.01c-17.52-3.5-35.33-7.15-52.55-10.68c-34.44-7.05-70.06-14.35-105.08-20.85c-36.04-3-73.06-3-108.85-3h-0.02 l-0.01,0.01c-0.75,1.03-1.49,2.07-2.23,3.11c-0.73,1.04-1.46,2.08-2.17,3.11c-1.44,2.08-2.85,4.14-4.23,6.17 c-1.73,2.53-3.5,5.12-5.31,7.72c-0.72,1.04-1.46,2.08-2.2,3.11c-0.37,0.52-0.74,1.03-1.12,1.55l-0.02,0.02L498.99,1312.82z M505.78,846.7c0.7,4.73,1.41,9.47,2.12,14.22c0.12,0.8,0.24,1.61,0.37,2.42c0.95,6.36,1.92,12.72,2.89,19.1 c1.47,9.58,2.96,19.16,4.49,28.74c0.85,5.33,1.71,10.66,2.58,15.98c0.32,1.95,0.64,3.9,0.96,5.85c1.34,8.08,2.7,16.14,4.1,24.16 c0.65,3.7,1.3,7.4,1.96,11.09v0.02h0.02c5.16,0,10.41,0.13,15.47,0.25c5.01,0.12,10.09,0.24,15.17,0.24 c7.63,0,15.26-0.27,22.65-1.24l0.02-0.01c23.28-17.21,45.98-35.8,67.92-53.78c10.64-8.72,21.66-17.74,32.67-26.54l0.04-0.03 l-0.04-0.01c-3.71-1.55-7.42-3.09-11.13-4.63c-7.43-3.08-14.86-6.14-22.31-9.18c-7.45-3.04-14.91-6.08-22.37-9.1 c-7.43-3-14.86-5.99-22.28-8.96c-33.54-13.43-66.97-26.54-99.78-39.42l-0.08-0.04l0.01,0.09 C502.75,826.1,504.26,836.38,505.78,846.7z M593.49,1063.74c2.41,19.14,4.91,38.93,6.08,58.39l0.01,0.02v0.01l0.02-0.01 c94.36-21.04,189.92-43.74,282.33-65.7c9.98-2.37,19.96-4.74,29.96-7.11l0.05-0.01l-0.04-0.03 c-86.35-61.93-157.67-112.02-224.45-157.64l-0.02-0.01l-0.02,0.01c-18.14,15.66-37.01,30.65-55.27,45.14 c-7.48,5.94-15.08,11.98-22.68,18.1c-1.3,1.05-2.61,2.1-3.91,3.16c-2.49,2.02-4.98,4.04-7.46,6.08 c-3.78,3.1-7.54,6.21-11.27,9.34v0.01l-0.01,0.01v0.01c-0.41,13.49,0.1,28.25,1.57,45.12 C589.69,1033.65,591.62,1048.95,593.49,1063.74z M615.21,1202.73c5.37,26.14,10.92,53.16,14.39,80.05v0.02h0.01h0.02 c23.65,4.13,47.51,9.09,70.57,13.89c23.06,4.8,46.91,9.76,70.56,13.88l0.08,0.02l-0.06-0.06c-1.63-1.67-3.26-3.34-4.89-5.02 c-8.22-8.44-16.55-16.97-24.96-25.56c-1.63-1.66-3.25-3.32-4.88-4.98c-8.4-8.57-16.89-17.19-25.47-25.85 c-12.01-12.13-24.18-24.33-36.5-36.56c-3.52-3.5-7.05-6.99-10.59-10.48c-1.77-1.75-3.54-3.5-5.32-5.24 c-3.55-3.5-7.11-6.98-10.69-10.48c-3.57-3.49-7.16-6.98-10.75-10.47c-3.59-3.49-7.2-6.97-10.81-10.45 c-7.23-6.96-14.49-13.9-21.79-20.81l-0.05-0.05l0.01,0.08C607.25,1163.99,611.29,1183.68,615.21,1202.73z M749.74,1275.07 c12.05,11.87,24.5,24.14,36.76,36.25l0.02,0.03l0.02-0.04c9.2-18.4,18.59-36.92,27.98-55.34c1.97-3.86,3.94-7.72,5.91-11.56 c7.43-14.52,14.85-28.95,22.16-43.19c4.46-8.68,8.95-17.41,13.45-26.19c3-5.85,6-11.7,9.01-17.59 c16.55-32.34,33.15-65.11,49.11-97.61l0.02-0.05l-0.05,0.01c-16.08,3.4-32.2,6.89-48.33,10.44c-12.9,2.84-25.83,5.72-38.74,8.64 c-0.01,0.01-0.01,0.01-0.02,0.01c-9.69,2.19-19.38,4.39-29.07,6.62c-46.03,10.57-92,21.48-137.46,32.4 c-4.85,1.16-9.69,2.33-14.54,3.49c-1.53,0.37-3.06,0.74-4.59,1.1c-4.84,1.16-9.66,2.33-14.48,3.48 c-7.11,1.71-14.21,3.42-21.29,5.13l-0.05,0.01l0.04,0.04C652.94,1179.7,702.15,1228.18,749.74,1275.07z M699.73,772.36 c0.76,1.77,1.52,3.53,2.3,5.28c0.51,1.16,1.02,2.3,1.53,3.45c1.44,3.24,2.91,6.47,4.41,9.68c0.81,1.74,1.63,3.47,2.47,5.2 c0.83,1.73,1.67,3.45,2.52,5.17c1.7,3.43,3.43,6.84,5.22,10.22l0.01,0.01l0.01,0.01c24.47,14.43,50.87,25.87,76.4,36.93 c4.99,2.16,10.15,4.4,15.19,6.61l0.12,0.05l-0.09-0.09c-19.57-21.37-40.69-43.32-62.77-65.21 c-20.67-20.49-42.74-41.49-65.59-62.4l-0.09-0.08l0.04,0.11C687.28,742.18,693.27,757.36,699.73,772.36z M694.16,884.17 l0.01,0.01c4.86,3.34,9.72,6.71,14.57,10.1c3.23,2.25,6.47,4.52,9.7,6.79c1.61,1.14,3.23,2.27,4.84,3.41 c3.23,2.28,6.44,4.56,9.66,6.83c12.86,9.13,25.63,18.28,38.17,27.27c5.58,4.01,11.2,8.03,16.83,12.06 c14.08,10.08,28.31,20.21,42.68,30.25c4.9,3.42,9.82,6.84,14.75,10.24c0.86,0.59,1.72,1.18,2.58,1.77 c2.03,1.4,4.07,2.8,6.11,4.18c2.31,1.58,4.63,3.16,6.95,4.73c4.37,2.97,8.76,5.91,13.15,8.83c2.6,1.73,5.2,3.45,7.81,5.16 c9.16,6.03,18.37,11.95,27.64,17.76l0.07,0.04l-0.04-0.07c-10.56-24.08-22.28-48.34-33.6-71.8 c-8.81-18.24-17.92-37.1-26.45-55.81c-1.44-2.7-2.73-5.62-3.97-8.45c-1.99-4.5-4.04-9.15-6.77-13.1 c-3.07-4.43-6.68-7.45-11.04-9.25c-6.78-3.32-13.6-6.66-20.46-10.01c-3.82-1.86-7.66-3.73-11.51-5.6 c-14.54-7.06-29.23-14.11-44-21c-4.66-2.17-9.34-4.33-14.02-6.47c-0.01,0-0.01,0-0.01-0.01c-4.68-2.14-9.37-4.26-14.06-6.35 c-2.34-1.05-4.69-2.08-7.04-3.12l-0.02-0.01l-0.01,0.04c-7.38,19.92-15.01,40.52-22.51,61.54v0.01L694.16,884.17L694.16,884.17z M875.86,1158.18c24.17-6.66,46.4-13.48,66.06-20.27l0.02-0.01l-0.01-0.02c-1.2-4.8-2.41-9.63-3.63-14.49 c-0.56-2.23-1.13-4.47-1.69-6.71c-0.19-0.76-0.38-1.52-0.58-2.28c-1.04-4.12-2.09-8.26-3.16-12.4 c-3.11-12.06-6.33-24.18-9.71-36.19l-0.02-0.06l-0.03,0.05c-17.19,29.89-33.09,60.95-47.29,92.33l-0.02,0.05L875.86,1158.18z M941.13,1099.61c2.77,10.33,5.63,21.02,8.26,31.53l0.01,0.05l0.04-0.04c4.55-5.38,9.01-10.86,13.42-16.37 c5.86-7.35,11.6-14.76,17.24-22.09c1.41-1.83,2.81-3.65,4.21-5.47c4.06-5.28,8.25-10.74,12.43-16.12l0.01-0.01l-0.01-0.01 c-7.67-13.26-14.97-26.87-22.02-40.03c-8.07-15.08-16.43-30.68-25.27-45.54l-0.03-0.05l-0.02,0.06c-1.97,6.9-4.56,13.74-7.29,21 c-7.53,19.94-15.32,40.55-9.23,61.59C935.5,1078.59,938.37,1089.28,941.13,1099.61z M985.69,1032.87 c5.63,10.25,11.44,20.84,17,31.47l0.02,0.04l0.02-0.03c6-7.88,12.3-15.89,18.39-23.65c6.09-7.75,12.39-15.77,18.39-23.65 l0.01-0.01l-0.01-0.01c-18.68-47.82-38.38-96.31-58.55-144.13l-0.03-0.07l-0.02,0.07c-3.31,13.21-7.39,26.4-11.35,39.16 c-5.94,19.13-12.07,38.92-15.67,59.19v0.01v0.01C963.35,992.16,974.71,1012.86,985.69,1032.87z"/> </g> </g> </g> </g>'));
        string memory image1 = string(abi.encodePacked('<text x="-440" y="1650" class="small">Attack: ',attack,' &#9876;</text> <text x="-440" y="1730" class="small">Defense: ',defense,' &#128737;</text> <text x="-440" y="-70" class="small">Dead &#128123;</text> <text x="-440" y="6" class="small">Level: ',_level,' &#127894;</text>'));
        string memory image2 = string(abi.encodePacked(' <text x="405" y="-95" class="small"># ',tokenId,'</text> <text x="1065" y="-70" class="small">Revived: ',_revived,'</text> <text x="295" y="1730" class="small">Kills Count: ',kills.toString(),' &#128128;</text> <text x="1060" y="1730" class="small">Team Rabbit &#129365;</text> </svg>'));
        string memory result = string(abi.encodePacked(image0, image1,image2));
        return result;
    }

    function calculateDaysAlive(uint256 timestamp) internal view returns(uint256) {
        return (((block.timestamp - timestamp) / 86400)+1);
    }

    function calculatePlayerLevel(uint256 timestamp, uint256 kills) internal view returns(uint256) {
        return calculateDaysAlive(timestamp)/10 + kills/2;
    }

    function revivedToString(bool revived) internal pure returns(string memory) {
        if (revived) {
            return "Yes &#128519;";
        } else {
            return "No &#128512;";
        }
    }
}