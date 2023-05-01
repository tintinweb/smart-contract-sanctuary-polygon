/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Sample {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    mapping(uint256 => address) public ownerOf;

    // 0x731133e9
    function mint(
        address _address,
        uint256 _tokenId,
        uint256 _salt,
        bytes calldata _signature
    ) external {
        ownerOf[_tokenId] = _address;
        emit Transfer(address(0), _address, _tokenId);
    }

    // 0x42966c68
    function burn(uint256 _tokenId) external {
        address currentOwner = ownerOf[_tokenId];
        require(
            msg.sender == currentOwner,
            "CONTRACT OWNER OR CURRENT OWNER ONLY"
        );
        delete ownerOf[_tokenId];
        emit Transfer(currentOwner, address(0), _tokenId);
    }
}