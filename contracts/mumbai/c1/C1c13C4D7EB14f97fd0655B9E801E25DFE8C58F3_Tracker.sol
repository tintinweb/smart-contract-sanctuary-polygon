/**
 *Submitted for verification at polygonscan.com on 2023-02-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMarketPlaceProxy {
    function isValid(address _target) external view returns(bool);
}

contract Tracker {

    IMarketPlaceProxy public proxy;

    address public owner = msg.sender;

    event Track(address from, address indexed to, address indexed nftContractAddr, uint256 indexed tokenId, uint256 time);

    function callTracker(
        address _nftContractAddr,
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        require(proxy.isValid(msg.sender) == true, "Invalid caller.");

        if (_from != address(proxy)) {
            emit Track(
                _from,
                _to,
                _nftContractAddr,
                _tokenId,
                block.timestamp
            );
        }
    }

    function setProxy(IMarketPlaceProxy _proxy) external {
        require(msg.sender == owner, "Only owner");

        proxy = _proxy;
    }
}