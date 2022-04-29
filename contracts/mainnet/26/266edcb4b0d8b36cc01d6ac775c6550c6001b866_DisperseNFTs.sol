/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0 <0.9.0;


interface NFT {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external; // EIP-1155
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable; // EIP-721
}


contract DisperseNFTs {
    // EIP-1155
    function disperseNFTs_1155_1(
        NFT nft,
        address from,
        address[] calldata recipients,
        uint256 tokenId,
        uint256 amounts
    ) external returns (bool[] memory result) {
        require(msg.sender == from, "Invalid caller!!");
        result = new bool[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            try nft.safeTransferFrom(from, recipients[i], tokenId, amounts, "") {
                result[i] = true;
            } catch {}
        }

        return result;
    }

    // EIP-1155
    function disperseNFTs_1155_2(
        NFT nft,
        address from,
        address[] calldata recipients,
        uint256[] calldata tokenIds,
        uint256 amounts
    ) external returns (bool[] memory result) {
        require(msg.sender == from, "Invalid caller!!");
        require(recipients.length == tokenIds.length, "Token ID length and recipient list length mismatch");
        result = new bool[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            try nft.safeTransferFrom(from, recipients[i], tokenIds[i], amounts, "") {
                result[i] = true;
            } catch {}
        }

        return result;
    }

    // EIP-1155
    function disperseNFTs_1155_3(
        NFT nft,
        address from,
        address[] calldata recipients,
        uint256 tokenIds,
        uint256[] calldata amounts
    ) external returns (bool[] memory result) {
        require(msg.sender == from, "Invalid caller!!");
        require(recipients.length == amounts.length, "Amount length and recipient list length mismatch");
        result = new bool[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            try nft.safeTransferFrom(from, recipients[i], tokenIds, amounts[i], "") {
                result[i] = true;
            } catch {}
        }

        return result;
    }

    // EIP-1155
    function disperseNFTs_1155_4(
        NFT nft,
        address from,
        address[] calldata recipients,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external returns (bool[] memory result) {
        require(msg.sender == from, "Invalid caller!!");
        require(recipients.length == tokenIds.length, "Token ID length and recipient list length mismatch");
        require(recipients.length == amounts.length, "Amounts length and recipients list length mismatch");
        result = new bool[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            try nft.safeTransferFrom(from, recipients[i], tokenIds[i], amounts[i], "") {
                result[i] = true;
            } catch {}
        }

        return result;
    }

    // EIP-721
    function disperseNFTs_721_1(
        NFT nft,
        address from,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external returns (bool[] memory result) {
        require(msg.sender == from, "Invalid caller!!");
        require(recipients.length == tokenIds.length, "Token ID length and recipient list length mismatch");
        result = new bool[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            try nft.safeTransferFrom(from, recipients[i], tokenIds[i], "") {
                result[i] = true;
            } catch {}
        }

        return result;
    }

    // EIP-721
    function disperseNFTs_721_2(
        NFT nft,
        address from,
        address[] calldata recipients,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        bool isERC721
    ) external payable returns (bool[] memory result) {
        require(msg.sender == from, "Invalid caller!!");
        require(isERC721, "isERC721 has to be true.");
        require(recipients.length == tokenIds.length, "Token ID length and recipient list length mismatch");
        result = new bool[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            try nft.safeTransferFrom{value : values[i]}(from, recipients[i], tokenIds[i], "") {
                result[i] = true;
            } catch {}
        }

        return result;
    }
}