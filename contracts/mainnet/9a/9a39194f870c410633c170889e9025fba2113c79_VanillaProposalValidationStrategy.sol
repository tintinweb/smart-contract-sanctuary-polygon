// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";

/// @title Vanilla Proposal Validation Strategy
contract VanillaProposalValidationStrategy is IProposalValidationStrategy {
    function validate(
        address, // author,
        bytes calldata, // params,
        bytes calldata // userParams
    ) external override returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IProposalValidationStrategy {
    function validate(address author, bytes calldata params, bytes calldata userParams) external returns (bool);
}