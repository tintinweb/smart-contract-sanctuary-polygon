//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// https://medium.com/linum-labs/a-technical-primer-on-using-encoded-function-calls-50e2b9939223

// import "hardhat/console.sol";

// TODO:
// Two kind of proxy mint
// 1. For integrating with NFT contracts that allows specifying which address to mint the NFT
// 2. For integrating with NFT contracts that mints the NFT from the caller (this contract - check if need to use delegatecall)
// Once the third-party mint sends the NFT to this contract, send the minted NFT to recipient address

contract ERC721FunctionEncodedProxy {
    event ProxyMinted(
        address indexed nftAssetContract,
        address proxyMinter,
        address recipient,
        uint256 tokenId
    );

    event Test(uint256, uint256, address, address);

    function proxyMint(
        address nftAssetContract,
        // bytes4 _functionSignature,
        string memory _functionSignature,
        bytes calldata encodedData
    ) external payable {
        (
            uint256 uintParamA,
            uint256 uintParamB,
            address addressParamA,
            address addressParamB
        ) = abi.decode(encodedData, (uint256, uint256, address, address));

        emit Test(uintParamA, uintParamB, addressParamA, addressParamB);

        bytes4 functionSignature = bytes4(keccak256("mint(uint256)"));

        (bool success, ) = address(nftAssetContract).call{value: msg.value}(
            abi.encodePacked(functionSignature, uintParamA)
        );

        // (bool success, ) = address(nftAssetContract).call{value: msg.value}(
        //     abi.encodePacked(bytes4(keccak256(encodedData)), uintParamA)
        // );

        require(success, "Execution failed");
    }
}