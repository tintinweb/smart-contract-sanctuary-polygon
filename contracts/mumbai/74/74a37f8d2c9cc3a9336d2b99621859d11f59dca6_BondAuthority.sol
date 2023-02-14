// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IBondAuthority, Authority} from "./interfaces/IBondAuthority.sol";

/// @title Bond Authority
/// @notice Bond Authority Contract
/// @dev The Bond Authority contract manages permissions for function
///      calls in the Carbon Capture contracts. It allows the designated
///      owner to grant authority to specific addresses and verifies if
///      a user is authorized to make a function call on a target contract.
///      The contract also tracks updates to the owner and emits an event
///      for ownership changes.
///
/// @author GET Protocol
contract BondAuthority is IBondAuthority {
    /* ========== ERRORS ========== */

    error Authority_onlyOwner();
    error Authority_invalidParams();

    /* ========== EVENTS ========== */

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /* ========== STATE VARIABLES ========== */

    /// @notice Designated contract owner with permission to grant authority
    address public owner;

    /// @notice Authorized addresses
    mapping(address => bool) internal _isAuthorized;

    constructor(address _owner) {
        if (_owner == address(0)) revert Authority_invalidParams();
        owner = _owner;
    }

    /// @inheritdoc IBondAuthority
    function setAuthority(address _user, bool _status) public override {
        if (msg.sender != owner) revert Authority_onlyOwner();
        _isAuthorized[_user] = _status;
    }

    /// @inheritdoc IBondAuthority
    function setOwner(address _newOwner) public override {
        if (_newOwner == address(0)) revert Authority_invalidParams();
        if (msg.sender != owner) revert Authority_onlyOwner();

        owner = _newOwner;

        emit OwnerUpdated(msg.sender, _newOwner);
    }

    /// @inheritdoc Authority
    function canCall(
        address _user,
        address _target,
        bytes4 _funcSig
    ) external view override returns (bool) {
        return _isAuthorized[_user];
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {Authority} from "solmate/auth/Auth.sol";

interface IBondAuthority is Authority {
    /// @notice        Grant or revoke authority to call certain functions
    /// @param _user   Address to grant/revoke authority to
    /// @param _status True to grant authority, false to revoke authority
    function setAuthority(address _user, bool _status) external;

    /// @notice          Update the contract owner with permission to grant authority
    /// @dev Only        the current owner can perform this action
    /// @param _newOwner The address to be set as the new owner
    function setOwner(address _newOwner) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}