// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2021, 2022 silenttiger - All rights reserved
pragma solidity ^0.8.0;

import "./BoringOwnableAndOperator.sol";

contract PermissionControl is BoringOwnableAndOperator {

    // KYCed investors
    mapping(address => bool) public whitelistedInvestors; 
 
    // EIP712 related variables and functions
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
    bytes32 private constant APPROVAL_SIGNATURE_HASH =
        keccak256("SetInvestorWhitelisting(address investor,bool approved,uint256 deadline)");

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    // solhint-disable-next-line var-name-mixedcase
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    event LogWhiteListInvestor(address indexed investor, address indexed operator, bool approved);

    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, keccak256("PermissionManager"), chainId, address(this)));
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    constructor(address to) {
        // Set default roles
        emit OwnershipTransferred(owner, to);
        owner = to;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
    }

    function whitelistInvestors(address[] calldata investors, bool[] calldata approved) public onlyOperator {
        for (uint256 i = 0; i < investors.length; i++) {
            _whitelistInvestor(investors[i], msg.sender, approved[i]);
        }
    }

    function whitelistInvestor(address investor, bool approved) public onlyOperator {
        _whitelistInvestor(investor, msg.sender, approved);
    }

    function _whitelistInvestor(address investor, address operator, bool approved) private {
        whitelistedInvestors[investor] = approved;
        emit LogWhiteListInvestor(investor, operator, approved);
    }

    /// @notice Approves or revokes whitelisting for investors
    /// @param operator The address of the operator that approves or revokes access.
    /// @param investor The address who gains or loses access.
    /// @param approved If True approves access. If False revokes access.
    /// @param deadline Time when signature expires to prohibit replays.
    /// @param v Part of the signature. (See EIP-191)
    /// @param r Part of the signature. (See EIP-191)
    /// @param s Part of the signature. (See EIP-191)
    function setInvestorWhitelisting(
        address operator,
        address investor,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(isOperator[operator], "PermissionMgr: not operator");
        // Checks
        require(investor != address(0), "PermissionMgr: Investor not set");

        // Also, ecrecover returns address(0) on failure. So we check this, even if the modifier should prevent this:
        require(operator != address(0), "PermissionMgr: Operator cannot be 0");

        require(deadline >= block.timestamp && deadline <= (block.timestamp + 1 weeks), 'PermissionMgr: EXPIRED');

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            APPROVAL_SIGNATURE_HASH,
                            investor,
                            approved,
                            deadline
                        )
                    )
                )
            );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == operator, "PermissionMgr: Invalid Signature");

        _whitelistInvestor(investor, operator, approved);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <=0.8.12;
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

// extends from BoringOwnable
contract BoringOwnableAndOperator is BoringOwnable {
    event LogSetOperator(address indexed operator, bool status);

    // operators
    mapping(address => bool) public isOperator;

    modifier onlyOperator {
        require(isOperator[msg.sender], "not operator");
        _;
    }

    function setOperator(address operator, bool status) public onlyOwner {
        isOperator[operator] = status;
        emit LogSetOperator(operator, status);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <=0.8.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
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