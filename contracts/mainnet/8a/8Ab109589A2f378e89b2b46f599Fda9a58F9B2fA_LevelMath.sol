// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ILevelMath {
  struct LevelEpoch {
    uint256 oresToken;
    uint256 coolDownTime;
    uint256 klayeToSkip;
    uint256 klayePerDay;
    uint256 maxRewardDuration;
  }

  function getLevelEpoch(uint256 level)
    external
    view
    returns (LevelEpoch memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "../interfaces/ILevelMath.sol";

contract LevelMath is ILevelMath {
  uint256 public immutable MAX_LEVEL;

  constructor(uint256 maxLevel) {
    MAX_LEVEL = maxLevel;
  }

  function getLevelEpoch(uint256 level)
    external
    view
    override
    returns (LevelEpoch memory)
  {
    require(level <= MAX_LEVEL, "!invalid level");
    uint256 oresToken = 1500e18 * level + 500e18;
    uint256 coolDownTime = (level + 1) * 1 hours;
    uint256 klayeToSkip = 15e16 * level + 2e17;
    uint256 klayePerDay = 25e16 * level + 1e18;
    uint256 maxRewardDuration;
    if (level < 11) {
      maxRewardDuration = 5 days;
    } else if (level < 31) {
      maxRewardDuration = 4 days;
    } else if (level < 45) {
      maxRewardDuration = 3 days;
    } else if (level < 69) {
      maxRewardDuration = 2 days;
    } else {
      maxRewardDuration = 9999 days;
    }

    return
      LevelEpoch(
        oresToken,
        coolDownTime,
        klayeToSkip,
        klayePerDay,
        maxRewardDuration
      );
  }
}