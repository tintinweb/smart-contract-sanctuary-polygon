// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { IGelatoResolver } from "./interfaces/IGelatoResolver.sol";
import { IAavegotchiOperator } from "./interfaces/IAavegotchiOperator.sol";

contract AavegotchiOperatorResolver is IGelatoResolver {

    address public immutable _aavegotchiOperatorAddress;

    constructor(address aavegotchiOperatorAddress) {
        _aavegotchiOperatorAddress = aavegotchiOperatorAddress;
    }

    // @notice Gelato pools the checker function for every block to verify whether it should trigger a task
    // @return canExec Whether Gelato should execute the task
    // @return execPayload Data that executors should use for the execution.
    function checker() external view returns (bool canExec, bytes memory execPayload) {
        IAavegotchiOperator aavegotchiOperator = IAavegotchiOperator(_aavegotchiOperatorAddress);
        (uint256[] memory tokenIds, address[] memory revokedAddresses) = aavegotchiOperator.listAavegotchisToPetAndAddressesToRemove();
        if (tokenIds.length > 0) {
            canExec = true;
            execPayload = abi.encodeWithSelector(IAavegotchiOperator.petAavegotchisAndRemoveRevoked.selector, tokenIds, revokedAddresses);
        } else {
            canExec = false;
            execPayload = bytes("No tokenIds to pet");
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IGelatoResolver {

    function checker() external view returns (bool canExec, bytes memory execPayload);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IAavegotchiOperator {

    function listAavegotchisToPetAndAddressesToRemove() external view returns (uint256[] memory tokenIds_, address[] memory revokedAddresses_);

    function petAavegotchisAndRemoveRevoked(uint256[] calldata tokenIds, address[] calldata revokedAddresses) external;

    function enablePetOperator() external;

    function disablePetOperator() external;

}