// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IOracle {

    /**
     * @notice Return amount of tokens that are required to receive that much eth.
     * @param ethOutput eth value want to receive.
     * @return tokenInput token value required.
     */
    function getTokenValueOfEth(uint256 ethOutput) external view returns (uint256 tokenInput);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "../paymaster/IOracle.sol";

contract LargeTxTest {
    string public data;

    function setData(string memory newData) public {
        data = newData;
    }
}