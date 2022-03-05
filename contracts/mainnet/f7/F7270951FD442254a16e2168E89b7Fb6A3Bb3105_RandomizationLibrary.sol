/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

pragma solidity 0.8.11;


contract RandomizationLibrary {
  /** This library assumes a completely random seed to work properly. 
    * Seeds should never be re-used.*/

  uint256 public constant BASE_DENOMINATOR = 10_000;

  function generateSeedAndSimulateBinomial() external returns (uint256 value) {
    uint256 seed = block.timestamp;
    return simulateBinomial(
      seed,
      30,
      4,
      13,
      60_000_000,
      73_000_000,
      14_000
    );
  }

  function simulateBinomial(
    uint256 seed, 
    uint256 n, 
    uint256 divisor,
    uint256 rightTailCutoff,
    uint256 floor,
    uint256 base,
    uint256 multiplier
  ) public view returns (uint256 value) {
    uint256 rolls = countRolls(seed, n, divisor);
    if(rolls > n - rightTailCutoff) rolls = n - rightTailCutoff;
    value = base * getMultiplierResult(rolls, multiplier)/(n*BASE_DENOMINATOR) + floor;
  }

  function getMultiplierResult(
    uint256 rolls,
    uint256 multiplier // scaled by BASE_DENOMINATOR
  ) internal view returns (uint256 result) {
    // Start at multiplier^0 = 1
    result = BASE_DENOMINATOR;
    // For each roll, multiply
    for(uint i = 0; i < rolls; i++) {
      result = result * multiplier / BASE_DENOMINATOR;
    }
    result -= BASE_DENOMINATOR;
  }


  function countRolls(
    uint256 seed, 
    uint256 n, 
    uint256 divisor
  ) internal pure returns (uint256 rolls) {
    uint256 workingSeed = seed; // We keep the old seed around to generate a new seed.
    for(uint256 i = 0; i < n; i++) {
      if(workingSeed % divisor == 0) rolls++;
      // If there is not enough value left for the next roll, we make a new seed.
      if((workingSeed /= divisor) < divisor ** 4) {
        workingSeed = uint256(keccak256(abi.encode(seed, i)));
      }
    }
  }
  

  function getRandomNumber(uint256 seed) external pure returns (uint256 value) {
    value = uint256(keccak256(abi.encode(seed, "RANDOM_ASS_STRING")));
  }
}