// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface INFT {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract AirdropTokens {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function airdrop(
        address contractAddress,
        uint256 startTokenID,
        address[] memory recipients
    ) public {
        require(
            owner == msg.sender,
            "Only the contract owner can airdrop tokens."
        );
        require(
            startTokenID >= 1,
            "startTokenID must be greater than or equal to 1"
        );
        require(recipients.length >= 1, "Please add at least one recipient");

        INFT nft = INFT(contractAddress);
        require(
            (startTokenID - 1) + recipients.length <= nft.totalSupply(),
            "Not enough tokens to airdrop."
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 tokenId = startTokenID++;
            nft.safeTransferFrom(nft.ownerOf(tokenId), recipients[i], tokenId);
        }
    }
}