pragma solidity ^0.8.0;
// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0

import "./Redeemers.sol";

interface IScoutsIdGenerator {
  function getScoutId(Redeemers.Types _redeemerName, uint256 _tokenId) pure external returns (uint256);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)

library Redeemers {
    enum Types { Tickets, PA }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./IScoutsIdGenerator.sol";
import "./Redeemers.sol";

contract ScoutsIdGenerator is IScoutsIdGenerator {
  using Redeemers for ScoutsIdGenerator;
  function getScoutId(Redeemers.Types _redeemerName, uint256 _tokenId) public pure returns (uint256) {
    //TODO: Check out of boudns
    if (_redeemerName == Redeemers.Types.Tickets) {
      // First 4699 scouts reserved for Pioneers
      require(_tokenId < 4700, "Only 4700 Pioneers should be available");
      return(_tokenId);
    } else {
      return 1337;
    }
  }
}