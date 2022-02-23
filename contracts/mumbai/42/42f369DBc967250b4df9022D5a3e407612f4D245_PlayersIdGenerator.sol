pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

///@dev The interface we couple Scouts contract to
interface IPlayersIdGenerator {
  function getPlayerId(uint256 _minterType, uint256 _minterId, uint256 _totalSupply) pure external returns (uint256);
}

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

import "./IPlayersIdGenerator.sol";

/**
 * @dev PlayersIdGenerator implementation
 *
 * This contract will allow us to adapt for different Player minters in the future.
 * For the moment, players will be only minted through scoutings and IDs will be incremental.
 */

enum MinterTypes { Scouting }

contract PlayersIdGenerator is IPlayersIdGenerator {
  ///This is just so the different types are visible in the ABI
  MinterTypes public constant SCOUTING = MinterTypes.Scouting;

  ///We use uint256 instead of the Types enum because MetaSoccerPlayers.sol is not upgradeable.
  function getPlayerId(uint256 _minterType, uint256 _minterId, uint256 _totalSupply) public pure returns (uint256) {
    require(_minterType == uint256(MinterTypes.Scouting), "Invalid minter");
    return _totalSupply;
  }

  ///This is just a helper function to help with transparency
  function typeBounds() public pure returns(uint256, uint256) {
    return(uint256(type(MinterTypes).min), uint8(type(MinterTypes).max));
  }

  ///This is just a helper function to help with transparency
  function typeName(uint256 _minterType) public pure returns(string memory) {
    if (_minterType == uint256(MinterTypes.Scouting)) {
      return "Scouting";
    }

    revert("Not existing");
  }
}