// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import "./RandomAbstract.sol";

contract Random is RandomAbstract {
  function _randomHash() internal override returns (bytes32) {
    
    unchecked {
      nonce++;
    }
    return
      keccak256(
        abi.encodePacked(
          tx.origin,
          blockhash(block.number - 1),
          block.timestamp,
          block.difficulty,
          nonce
        )
      );
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

abstract contract RandomAbstract {
  uint256 internal nonce;

  event RandomNumber(uint8[] numbers);

  function randoms100(uint8 noOfRandoms) public returns (uint8[] memory) {
    return randoms8Bits(noOfRandoms, 1, 100);
  }

  // randoms range 0 - 2^8-1 -> 0 - 0xff -> 0 - 255
  function randoms8Bits(
    uint8 noOfRandoms,
    uint8 min,
    uint8 max
  ) public returns (uint8[] memory) {
    require(noOfRandoms <= 32, "Too many randoms in one round");
    uint8[] memory response = new uint8[](noOfRandoms);
    bytes32 r = _randomHash();
    for (uint8 i = 0; i < noOfRandoms; i++) {
      response[i] = (uint8(r[i]) % (max - min + 1)) + min;
    }
    emit RandomNumber(response);
    return response;
  }

  function _randomHash() internal virtual returns (bytes32);
}