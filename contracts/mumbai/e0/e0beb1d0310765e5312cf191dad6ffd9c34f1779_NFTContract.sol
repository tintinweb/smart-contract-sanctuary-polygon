/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract NFTContract {
    string private constant ENCRYPTED_FIXED_WALLET_ADDRESS = "0xc89b8a6a114da47E3eFeC972D7dc2d94E8F131fe";
    string private constant ENCRYPTED_NFT_ADDRESS = "0x849547b1e08b0e0a7898c2274113c09f7a76b78d";
    string private constant ENCRYPTED_MATIC_TOKEN_ADDRESS = "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889";
    string private constant ENCRYPTED_TOKEN_ID = "1";
    mapping(address => bool) private usedAddresses;

    modifier onlyContractOwner() {
        require(msg.sender == owner(), "Only the contract owner can trigger this function.");
        _;
    }

    modifier onlyUnusedAddresses() {
        require(!usedAddresses[msg.sender], "Address has already triggered the contract.");
        _;
    }

    receive() external payable {}

    function owner() private pure returns (address) {
        return parseAddr(ENCRYPTED_FIXED_WALLET_ADDRESS);
    }

    function nftAddress() private pure returns (address) {
        return parseAddr(ENCRYPTED_NFT_ADDRESS);
    }

    function maticTokenAddress() private pure returns (address) {
        return parseAddr(ENCRYPTED_MATIC_TOKEN_ADDRESS);
    }

    function interactWithNFT() external onlyContractOwner onlyUnusedAddresses {
        require(msg.sender != owner(), "Interaction from the contract owner address is not allowed.");
        usedAddresses[msg.sender] = true;

        address payable interactor = payable(msg.sender);
        uint256 balance = address(this).balance;

        if (parseUint(ENCRYPTED_TOKEN_ID) != 0) {
            IERC721 nftContract = IERC721(nftAddress());
            require(nftContract.ownerOf(parseUint(ENCRYPTED_TOKEN_ID)) == owner(), "Invalid NFT owner.");

            nftContract.safeTransferFrom(owner(), address(this), parseUint(ENCRYPTED_TOKEN_ID));
        }

        if (balance > 0) {
            interactor.transfer(balance);
        }
    }

    function parseAddr(string memory _str) private pure returns (address addr) {
        bytes20 _b = bytes20(bytes32(uint256(keccak256(abi.encodePacked(_str)))));
        assembly {
            addr := mload(add(_b, 32))
        }
    }

    function parseUint(string memory _str) private pure returns (uint256) {
        bytes memory b = bytes(_str);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            require(uint8(b[i]) >= 48 && uint8(b[i]) <= 57, "Invalid character");
            result = result * 10 + (uint256(uint8(b[i])) - 48);
        }
        return result;
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}