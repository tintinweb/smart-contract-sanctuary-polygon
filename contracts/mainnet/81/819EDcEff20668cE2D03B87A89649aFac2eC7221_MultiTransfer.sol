/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IMultiTransfer {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PermitDetail {
        address token;
        address spender;
        uint48 deadline;
        address[] addresses;
    }

    // error
    error MultiTransfer_LengthMismatch();
}

contract MultiTransfer is IMultiTransfer {
    uint256 constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function multiPermit(PermitDetail calldata details_, Signature[] calldata signatures_) external {
        if (details_.addresses.length != signatures_.length) revert MultiTransfer_LengthMismatch();

        uint256 length = details_.addresses.length;
        address account;
        Signature memory sign;
        for (uint i; i < length; ) {
            account = details_.addresses[i];
            sign = signatures_[i];
            IERC20Permit(details_.token).permit(
                account,
                details_.spender,
                MAX_INT,
                details_.deadline,
                sign.v,
                sign.r,
                sign.s
            );
            unchecked {
                ++i;
            }
        }
    }
}