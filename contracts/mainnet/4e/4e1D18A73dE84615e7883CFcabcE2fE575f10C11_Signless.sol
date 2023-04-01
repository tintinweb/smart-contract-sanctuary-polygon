// SPDX-License-Identifier: MIT
// The MIT License (MIT)

// Copyright (c) 2018 SmartContract ChainLink, Ltd.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
pragma solidity ^0.8.0;

abstract contract ITypeAndVersion {
    function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

/// @title Signless
/// @author kevincharm
/// @notice Delegated Child-Key Signer (DCKS) Registry
interface ISignless {
    struct Delegation {
        /// @notice The delegator i.e., the "owner"
        /// @dev 20B
        address delegatooor;
        /// @notice Nullifier of delegator
        /// @dev 6B
        uint48 nullifier;
        /// @notice Timestamp of when this delegate is no longer valid
        /// @dev 6B
        uint48 expiry;
    }

    event DelegateRegistered(
        address indexed delegator,
        address delegate,
        uint48 nullifier,
        uint48 expiry
    );
    event DelegateRevoked(address indexed delegator, address delegate);
    event InvalidateNullifier(address indexed delegator, uint48 nullifier);
    error AlreadyRegistered(address delegator, address delegate);
    error InvalidNullifier(address delegator, uint48 nullifier);
    error DelegationExpired(address delegator, address delegate, uint48 expiry);
    error NotDelegator(
        address delegator,
        address actualDelegator,
        address delegate
    );

    /// @notice Get nullifier for delegator
    /// @param delegator Delegatooor
    function getNullifier(address delegator) external view returns (uint48);

    /// @notice Get info about registered delegate
    /// @param delegate Registered delegate to get info of
    function getDelegateInfo(
        address delegate
    )
        external
        view
        returns (address delegatooor, uint48 nullifier, uint256 expiry);

    /// @notice Get the delegator for a delegate, if that delegate is valid
    /// @param delegate Registered delegate to get info of
    function getDelegator(
        address delegate
    ) external view returns (address delegatooor);

    /// @notice Returns true if the `delegatee` pubkey is registered as a
    ///     delegated signer for `delegator`
    /// @param delegator The delegatooooooooor
    /// @param delegate The delegate public key
    /// @return truth or dare
    function isDelegate(
        address delegator,
        address delegate
    ) external view returns (bool);

    /// @notice Register a delegate public key of which the delegator has
    ///     control. Also allows a delegator to renew a delegate key by
    ///     updating the expiry.
    /// @param delegate Truncated ECDSA public key that the delegator wishes
    ///     to delegate to.
    /// @param expiry When the delegation becomes invalid, as UNIX timestamp
    function registerDelegate(address delegate, uint48 expiry) external;

    /// @notice Revoke all delegates for the caller, by incrementing the
    ///     nullifier
    function revokeAllDelegates() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {ISignless} from "./ISignless.sol";
import {ITypeAndVersion} from "../interfaces/ITypeAndVersion.sol";
import {Sets} from "../utils/Sets.sol";

/// @title Signless
/// @author kevincharm
/// @notice Delegated Child-Key Signer (DCKS) Registry
contract Signless is ISignless, ITypeAndVersion {
    using Sets for Sets.Set;

    /// @notice Nullifier for each delegatooor
    ///     delegatooor => nullifier
    mapping(address => uint48) private nullifiers;

    /// @notice Delegate information
    ///     delegate => info
    mapping(address => Delegation) private delegates;

    /// @notice Set of delegates for each delegator
    ///     delegator => delegates
    mapping(address => Sets.Set) private delegateSet;

    constructor() {}

    function typeAndVersion() external pure override returns (string memory) {
        return "Signless 1.2.0";
    }

    /// @notice Get nullifier for delegator
    /// @param delegator Delegatooor
    function getNullifier(address delegator) external view returns (uint48) {
        return nullifiers[delegator];
    }

    /// @notice Get info about registered delegate
    /// @param delegate Registered delegate to get info of
    function getDelegateInfo(
        address delegate
    )
        external
        view
        returns (address delegatooor, uint48 nullifier, uint256 expiry)
    {
        Delegation memory delegation = delegates[delegate];
        return (
            delegation.delegatooor,
            delegation.nullifier,
            delegation.expiry
        );
    }

    /// @notice Get the delegator for a delegate, if that delegate is valid
    /// @param delegate Registered delegate to get info of
    function getDelegator(
        address delegate
    ) external view returns (address delegatooor) {
        Delegation memory delegation = delegates[delegate];
        if (
            nullifiers[delegation.delegatooor] != delegation.nullifier ||
            block.timestamp >= delegation.expiry
        ) {
            return address(0);
        }
        return delegation.delegatooor;
    }

    /// @notice Returns true if the `delegatee` pubkey is registered as a
    ///     delegated signer for `delegator`
    /// @param delegator The delegatooooooooor
    /// @param delegate The delegate public key
    /// @return truth or dare
    function isDelegate(
        address delegator,
        address delegate
    ) external view returns (bool) {
        Delegation memory delegation = delegates[delegate];
        return
            delegation.delegatooor == delegator &&
            delegation.nullifier == nullifiers[delegator] &&
            block.timestamp < delegation.expiry;
    }

    function getDelegatesCount(
        address delegator
    ) external view returns (uint256) {
        return delegateSet[delegator].size;
    }

    /// @notice Get the set of delegates for a delegator.
    /// @param delegator Delegator to get delegate set of
    /// @param startFrom Which delegate to start fetching from
    /// @param pageSize Maximum number of delegates to fetch in this call
    function getDelegatesPaginated(
        address delegator,
        address startFrom,
        uint256 pageSize
    )
        external
        view
        returns (address[] memory out, Delegation[] memory infos, address next)
    {
        out = new address[](pageSize);
        infos = new Delegation[](pageSize);

        address element = delegateSet[delegator].ll[startFrom];
        uint256 i;
        if (startFrom > address(0x1) && element != address(0)) {
            out[i] = startFrom;
            infos[i] = delegates[startFrom];
            unchecked {
                ++i;
            }
        }
        for (
            ;
            i < pageSize && element != address(0) && element != address(0x1);
            ++i
        ) {
            out[i] = element;
            infos[i] = delegates[element];
            element = delegateSet[delegator].prev(element);
        }
        assembly {
            // Change size of output arrays to number of fetched delegates
            mstore(out, i)
            mstore(infos, i)
        }
        return (out, infos, element);
    }

    /// @notice Register a delegate public key of which the delegator has
    ///     control. Also allows a delegator to renew a delegate key by
    ///     updating the expiry.
    /// @param delegate Truncated ECDSA public key that the delegator wishes
    ///     to delegate to.
    /// @param expiry When the delegation becomes invalid, as UNIX timestamp
    function registerDelegate(address delegate, uint48 expiry) external {
        address delegator = msg.sender;
        Delegation memory delegateSigner = delegates[delegate];
        if (delegateSigner.delegatooor != address(0)) {
            // Delegate already registered, and not by the caller
            revert AlreadyRegistered(delegateSigner.delegatooor, delegate);
        }

        uint48 nullifier = nullifiers[delegator];
        delegateSet[delegator].add(delegate);
        delegates[delegate] = Delegation({
            delegatooor: delegator,
            nullifier: nullifier,
            expiry: expiry
        });

        emit DelegateRegistered(delegator, delegate, nullifier, expiry);
    }

    /// @notice Revoke a delegate of which the delegator has control.
    /// @param prevDelegate Previous delegate in the list (needed for set lookup)
    /// @param delegate Delegate teo revoke
    function revokeDelegate(address prevDelegate, address delegate) external {
        address delegator = msg.sender;
        Delegation memory delegateSigner = delegates[delegate];
        if (delegateSigner.delegatooor != delegator) {
            revert NotDelegator(
                delegator,
                delegateSigner.delegatooor,
                delegate
            );
        }

        delegateSet[delegator].del(prevDelegate, delegate);
        delegates[delegate] = Delegation({
            delegatooor: address(0x1) /** brick this delegate pubkey */,
            nullifier: 0,
            expiry: 0
        });

        emit DelegateRevoked(delegator, delegate);
    }

    /// @notice Revoke all delegates for the caller, by incrementing the
    ///     nullifier
    function revokeAllDelegates() external {
        address delegator = msg.sender;
        uint48 nullifier = nullifiers[delegator];
        ++nullifiers[delegator];
        emit InvalidateNullifier(delegator, nullifier);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8 <0.9;

library Sets {
    struct Set {
        mapping(address => address) ll;
        uint256 size;
    }

    address public constant OUROBOROS = address(0x1);

    function init(Set storage set) internal {
        require(set.ll[OUROBOROS] == address(0));
        set.ll[OUROBOROS] = OUROBOROS;
    }

    function tail(Set storage set) internal view returns (address) {
        address t = set.ll[OUROBOROS];
        require(
            t != address(0) && t != OUROBOROS,
            "Uninitialised or empty set"
        );
        return t;
    }

    function prev(
        Set storage set,
        address element
    ) internal view returns (address) {
        require(element != address(0), "Element must be nonzero");
        return set.ll[element];
    }

    function add(Set storage set, address element) internal {
        require(
            element != address(0) &&
                element != OUROBOROS &&
                set.ll[element] == address(0)
        );
        set.ll[element] = set.ll[OUROBOROS];
        set.ll[OUROBOROS] = element;
        ++set.size;
    }

    function del(
        Set storage set,
        address prevElement,
        address element
    ) internal {
        require(
            element == set.ll[prevElement],
            "prevElement is not linked to element"
        );
        require(
            element != address(0) && element != OUROBOROS,
            "Invalid element"
        );
        set.ll[prevElement] = set.ll[element];
        set.ll[element] = address(0);
        --set.size;
    }

    function has(
        Set storage set,
        address element
    ) internal view returns (bool) {
        return set.ll[element] != address(0);
    }

    function toArray(Set storage set) internal view returns (address[] memory) {
        if (set.size == 0) {
            return new address[](0);
        }

        address[] memory array = new address[](set.size);
        address element = set.ll[OUROBOROS];
        for (uint256 i; i < array.length; ++i) {
            array[i] = element;
            element = set.ll[element];
        }
        return array;
    }
}