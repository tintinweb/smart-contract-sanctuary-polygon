// SPDX-License-Identifier: Unlicensed
import "./interfaces/IRandomizer.sol";

pragma solidity ^0.8.0;

contract BasicRandomizer is IRandomizer {
    function value() public view override returns (bytes32) {
        uint256 time = block.timestamp;
        uint256 extra = (time % 200) + 1;

        return
            keccak256(
                abi.encodePacked(
                    block.number,
                    blockhash(block.number - 2),
                    time,
                    extra
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRandomizer {
  function value() external view returns (bytes32);
}