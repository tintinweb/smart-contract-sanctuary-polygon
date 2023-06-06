//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IProofOfReserveOracle {
    function lockedValue() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IProofOfReserveOracle.sol";

contract MockOracle is IProofOfReserveOracle {
    uint256 constant _lockedValue = 1000000 * 10 ** 18;

    function lockedValue() external pure override returns (uint256) {
        return _lockedValue;
    }
}