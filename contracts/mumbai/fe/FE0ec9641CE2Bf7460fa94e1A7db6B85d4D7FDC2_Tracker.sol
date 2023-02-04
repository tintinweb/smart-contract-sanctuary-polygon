/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Tracker {
    event Track(address from, address indexed to, address indexed nftContractAddr, uint256 indexed tokenId, uint256 time);

    function callTracker(
        address _nftContractAddr,
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        emit Track(
            _from,
            _to,
            _nftContractAddr,
            _tokenId,
            block.timestamp
        );
    }
}