/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface INftCollection {

    /**
     * @dev Mint NFTs from the NFT contract.
     */
    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) external;
}


pragma solidity ^0.8.0;

/** @title NftMintingStation.
 */
contract NftMintingStation {

    INftCollection public nftCollection;


    constructor(INftCollection _nftCollection) {
        nftCollection = _nftCollection;
    }


    function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) internal {
        nftCollection.mint(_to, _id, _amount, _data);
    }
}

pragma solidity ^0.8.0;

/**
 * @title MetaPopit Minter
 * @notice MetaPopit Minting Station
 */
contract VispXMinter is NftMintingStation {

    constructor(INftCollection _collection) NftMintingStation(_collection) {}


    /**
     * @dev mint a `_quantity` NFT (quantity max for a wallet is limited by `MAX_MINT_PER_WALLET`)
     * _wl: whitelist level
     * _signature: backend signature for the transaction
     */
    function mint(
        uint256 _id, 
        uint256 _amount,
        bytes memory _data //0x1000000000000000000000000000000000000000000000000000000000000000
    ) external {
        _mint(msg.sender, _id, _amount, _data);
    }
}