// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title A custom struct library
/// @author faf
library YelloBotLib {
  struct Bot {
    uint256 tokenId;
    uint256 lastHeal;
    uint256 lastFight;
    uint16 attack;
    uint16 defense;
    uint16 life;
    uint16 experience;
    uint32 nbDamage;
    uint16 nbKnock;
    uint8 nbFight;
    uint8 nbWin;
    uint8 nbLose;
  }

  struct Battle {
    uint256 attackerTokenId;
    uint256 defenderTokenId;
    uint256 winner;
    uint16[] moves;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./YelloBotLib.sol";

/// @title An Oracle example
/// @author faf
/// @dev use the VRF Chainlink Oracle for MainNet
contract YelloBotOracle {
  uint public random;
  address admin;

  event BotGenerated(string message, YelloBotLib.Bot bot);

  /// @param _random Init the random number
  constructor(uint _random) {
    admin = msg.sender;
    random = _random;
  }

  /// @param _random Give a new random number
  function setRandomness(uint _random) external {
    require(msg.sender == admin, "Not authorized");
    random = _random;
  }

  /// @notice You can adapt the attack and defense value
  /// @dev Please note that a modification will eventually change the size of the "moveArray" in the YelloBotBattle contract
  /// @param tokenId The YelloBotBattle tokenId
  /// @return A representation of a YelloBotLib.Bot
  function generateBot(uint256 tokenId) external returns (YelloBotLib.Bot memory) {
    uint256 lastHeal = block.timestamp;
    uint256 lastFight = block.timestamp;
    uint16 attack = uint16(generateRandomBetween(16, 20));
    uint16 defense = uint16(generateRandomBetween(10, 15));
    uint16 life = 255;
    uint16 experience = 1;
    uint32 nbDamage = 0;
    uint16 nbKnock = 0;
    uint8 nbFight = 0;
    uint8 nbWin = 0;
    uint8 nbLose = 0;

    YelloBotLib.Bot memory bot = YelloBotLib.Bot(
      tokenId,
      lastHeal,
      lastFight,
      attack,
      defense,
      life,
      experience,
      nbDamage,
      nbKnock,
      nbFight,
      nbWin,
      nbLose
    );
    emit BotGenerated("Bot generated", bot);
    return bot;
  }

  /// @dev Replace the keccak by a VRF Chainlink method
  /// @param min Minimun value
  /// @param max Maximun value
  /// @return value A generate number between min and max
  function generateRandomBetween(uint min, uint max) public view returns (uint value) {
    value = uint(keccak256(abi.encodePacked(random, block.timestamp, block.prevrandao, msg.sender))) % (max-min);
    return value + min;
  }
}