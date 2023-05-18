// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IHistory} from "./IHistory.sol";

/// @title Simple History
///
/// @notice This contract stores claims for each DApp individually.
/// This means that, for each DApp, the contract stores an array of
/// `Claim` entries, where each `Claim` is composed of:
///
/// * An epoch hash (`bytes32`)
/// * A closed interval of input indices (`uint128`, `uint128`)
///
/// The contract guarantees that the first interval starts at index 0,
/// and that the following intervals don't have gaps or overlaps.
///
/// Furthermore, claims can only be submitted by the contract owner
/// through `submitClaim`, but can be retrieved by anyone with `getClaim`.
///
/// @dev This contract inherits OpenZeppelin's `Ownable` contract.
///      For more information on `Ownable`, please consult OpenZeppelin's official documentation.
contract History is IHistory, Ownable {
    struct Claim {
        bytes32 epochHash;
        uint128 firstIndex;
        uint128 lastIndex;
    }

    /// @notice Mapping from DApp address to array of claims.
    /// @dev See the `getClaim` and `submitClaim` functions.
    mapping(address => Claim[]) internal claims;

    /// @notice A new claim regarding a specific DApp was submitted.
    /// @param dapp The address of the DApp
    /// @param claim The newly-submitted claim
    /// @dev MUST be triggered on a successful call to `submitClaim`.
    event NewClaimToHistory(address indexed dapp, Claim claim);

    /// @notice Creates a `History` contract.
    /// @param _owner The initial owner
    constructor(address _owner) {
        // constructor in Ownable already called `transferOwnership(msg.sender)`, so
        // we only need to call `transferOwnership(_owner)` if _owner != msg.sender
        if (_owner != msg.sender) {
            transferOwnership(_owner);
        }
    }

    /// @notice Submit a claim regarding a DApp.
    /// There are several requirements for this function to be called successfully.
    ///
    /// * `_claimData` MUST be well-encoded. In Solidity, it can be constructed
    ///   as `abi.encode(dapp, claim)`, where `dapp` is the DApp address (type `address`)
    ///   and `claim` is the claim structure (type `Claim`).
    ///
    /// * `firstIndex` MUST be less than or equal to `lastIndex`.
    ///   As a result, every claim MUST encompass AT LEAST one input.
    ///
    /// * If this is the DApp's first claim, then `firstIndex` MUST be `0`.
    ///   Otherwise, `firstIndex` MUST be the `lastClaim.lastIndex + 1`.
    ///   In other words, claims MUST NOT skip inputs.
    ///
    /// @inheritdoc IHistory
    /// @dev Emits a `NewClaimToHistory` event. Should have access control.
    function submitClaim(
        bytes calldata _claimData
    ) external override onlyOwner {
        (address dapp, Claim memory claim) = abi.decode(
            _claimData,
            (address, Claim)
        );

        require(claim.firstIndex <= claim.lastIndex, "History: FI > LI");

        Claim[] storage dappClaims = claims[dapp];
        uint256 numDAppClaims = dappClaims.length;

        require(
            claim.firstIndex ==
                (
                    (numDAppClaims == 0)
                        ? 0
                        : (dappClaims[numDAppClaims - 1].lastIndex + 1)
                ),
            "History: unclaimed inputs"
        );

        dappClaims.push(claim);

        emit NewClaimToHistory(dapp, claim);
    }

    /// @notice Get a specific claim regarding a specific DApp.
    /// There are several requirements for this function to be called successfully.
    ///
    /// * `_proofContext` MUST be well-encoded. In Solidity, it can be constructed
    ///   as `abi.encode(claimIndex)`, where `claimIndex` is the claim index (type `uint256`).
    ///
    /// * `claimIndex` MUST be inside the interval `[0, n)` where `n` is the number of claims
    ///   that have been submitted to `_dapp` already.
    ///
    /// @inheritdoc IHistory
    function getClaim(
        address _dapp,
        bytes calldata _proofContext
    ) external view override returns (bytes32, uint256, uint256) {
        uint256 claimIndex = abi.decode(_proofContext, (uint256));

        Claim memory claim = claims[_dapp][claimIndex];

        return (claim.epochHash, claim.firstIndex, claim.lastIndex);
    }

    /// @inheritdoc IHistory
    /// @dev Emits an `OwnershipTransferred` event. Should have access control.
    function migrateToConsensus(
        address _consensus
    ) external override onlyOwner {
        transferOwnership(_consensus);
    }
}

// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

/// @title History interface
interface IHistory {
    // Permissioned functions

    /// @notice Submit a claim.
    ///         The encoding of `_claimData` might vary
    ///         depending on the history implementation.
    /// @param _claimData Data for submitting a claim
    /// @dev Should have access control.
    function submitClaim(bytes calldata _claimData) external;

    /// @notice Transfer ownership to another consensus.
    /// @param _consensus The new consensus
    /// @dev Should have access control.
    function migrateToConsensus(address _consensus) external;

    // Permissionless functions

    /// @notice Get a specific claim regarding a specific DApp.
    ///         The encoding of `_proofContext` might vary
    ///         depending on the history implementation.
    /// @param _dapp The DApp address
    /// @param _proofContext Data for retrieving the desired claim
    /// @return epochHash_ The claimed epoch hash
    /// @return firstInputIndex_ The index of the first input of the epoch in the input box
    /// @return lastInputIndex_ The index of the last input of the epoch in the input box
    function getClaim(
        address _dapp,
        bytes calldata _proofContext
    )
        external
        view
        returns (
            bytes32 epochHash_,
            uint256 firstInputIndex_,
            uint256 lastInputIndex_
        );
}