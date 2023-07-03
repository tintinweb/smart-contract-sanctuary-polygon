// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Module that enables calling multiple methods of the system in a single transaction.
 */
interface IMulticallModule {
    /**
     * @notice Executes multiple transaction payloads in a single transaction.
     * @dev Each transaction is executed using `delegatecall`, and targets the system address.
     * @param data Array of calldata objects, one for each function that is to be called in the system.
     * @return results Array of each `delegatecall`'s response corresponding to the incoming calldata array.
     */
    function multicall(
        bytes[] calldata data
    ) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IMulticallModule} from "../interfaces/IMulticallModule.sol";

/**
 * @title Module that enables calling multiple methods of the system in a single transaction.
 * @dev See IMulticallModule.
 * @dev Implementation adapted from https://github.com/Synthetixio/synthetix-v3/blob/main/protocol/synthetix/contracts/modules/core/MulticallModule.sol
 */
contract MulticallModule is IMulticallModule {
    /// @inheritdoc IMulticallModule
    function multicall(
        bytes[] calldata data
    ) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );

            if (!success) {
                uint len = result.length;
                assembly {
                    revert(add(result, 0x20), len)
                }
            }

            results[i] = result;
        }
    }
}