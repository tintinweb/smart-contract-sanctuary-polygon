// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract NftSwapper {
    mapping(address => address) public userNfts;
    mapping(address => uint256) public userNftTokens;

    function wantToSwap(address nftSCAddress, uint256 nftTokenId) public {
        bool contractExists = isContract(nftSCAddress);
        require(
            contractExists == true,
            "Your NFT Smart Contract Address is incorect"
        );

        (bool success, bytes memory result) = nftSCAddress.delegatecall(
            abi.encodeWithSignature(
                "approve(address, uint256)",
                address(this),
                nftTokenId
            )
        );

        require(success == true, "Approving your token not works");

        userNfts[msg.sender] = nftSCAddress;
        userNftTokens[nftSCAddress] = nftTokenId;
    }

    /*     function wantToSwapFor(
        address myNftSCAddress,
        uint256 myNftTokenId,
        address forNftSCAddress,
        uint256 forNftTokenId
    ) public {}

    function executeSwap(
        address myNftSCAddress,
        uint256 myNftTokenId,
        address forNftSCAddress,
        uint256 forNftTokenId
    ) public {} */

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}