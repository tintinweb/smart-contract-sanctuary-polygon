// SPDX-License-Identifier: None

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

contract PermissionManager is BoringOwnable {
    struct PermissionInfo {
        uint index;
        bool isAllowed;
    }

    mapping(address => PermissionInfo) public info;
    address[] public allowedAccounts;

    function permit(address _account) public onlyOwner {
        if (info[_account].isAllowed) {
            revert("Account is already permitted");
        }
        info[_account] = PermissionInfo({index: allowedAccounts.length, isAllowed: true});
        allowedAccounts.push(_account);
    }

    function revoke(address _account) public onlyOwner {
        PermissionInfo memory accountInfo = info[_account];

        if (accountInfo.index != allowedAccounts.length-1) {
            address last = allowedAccounts[allowedAccounts.length-1];
            PermissionInfo storage infoLast = info[last];

            allowedAccounts[accountInfo.index] = last;
            infoLast.index = accountInfo.index;
        }

        delete info[_account];
        allowedAccounts.pop();
    }

    function getAllAccounts() public view returns (address[] memory) {
        return allowedAccounts;
    }

    modifier isAllowed() {
        require(info[msg.sender].isAllowed, "sender is not allowed");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}