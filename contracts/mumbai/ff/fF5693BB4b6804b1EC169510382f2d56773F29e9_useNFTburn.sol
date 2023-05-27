/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

struct TokenDetail {
    uint256 tokenId;
    uint256 ILOCount;
}

// Extended the interface of the contract to include tokensOfOwner function
interface INFTContract {
    function useNFT(address _holder, uint256 _tokenId) external;
    function tokensOfOwner(address _owner) external view returns (uint256[] memory);
    function tokenDetails(address _holder, uint256 _tokenId) external view returns (
        uint256 ILOs,
        string memory _type,
        uint256 _cat,
        string memory _image
    );
}

contract useNFTburn {
    INFTContract nftContract;

    address public owner;

    /* @dev: Check if contract owner */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner!");
        _;
    }

    // Initialize the address of the NFT contract in the constructor
    constructor() {
        owner = msg.sender;
        nftContract = INFTContract(0xB9D2b934AB7AA9EFF18E7B1Cfed547f7396a840d);
    }

    function setNFTContract(address _nftContractAddress) external onlyOwner{
        nftContract = INFTContract(_nftContractAddress);
    }

    // Function to call useNFT function twice for each address and token ID
    function useNFTsTwice(address[] calldata _holders, uint256[] calldata _tokenIds) external onlyOwner{
        require(_holders.length == _tokenIds.length, "Arrays length mismatch");

        for (uint256 i = 0; i < _holders.length; i++) {
            nftContract.useNFT(_holders[i], _tokenIds[i]);
            nftContract.useNFT(_holders[i], _tokenIds[i]);
        }
    }

    function useNFTsMultipleTimes(address[] calldata _holders, uint256[] calldata _tokenIds, uint256 _times) external onlyOwner{
    require(_holders.length == _tokenIds.length, "Arrays length mismatch");

    for (uint256 i = 0; i < _holders.length; i++) {
        for (uint256 j = 0; j < _times; j++) {
            nftContract.useNFT(_holders[i], _tokenIds[i]);
        }
    }
}

    // This function takes an array of addresses and for each address
    // it retrieves the list of tokenIds owned by that address.
    // It returns an array of arrays of tokenIds.
    function getTokensOfOwners(address[] calldata _owners) external view returns (uint256[][] memory) {
        uint256[][] memory ownerTokens = new uint256[][](_owners.length);
        for (uint256 i = 0; i < _owners.length; i++) {
            ownerTokens[i] = nftContract.tokensOfOwner(_owners[i]);
        }
        return ownerTokens;
    }

    function getTokensOfOwnersON(address[] calldata _owners) external view returns (uint256[][] memory, uint256[][] memory) {
        uint256[][] memory ownerTokens = new uint256[][](_owners.length);
        uint256[][] memory ownerTokenILOs = new uint256[][](_owners.length);

        for (uint256 i = 0; i < _owners.length; i++) {
            uint256[] memory tokens = nftContract.tokensOfOwner(_owners[i]);
            uint256[] memory ILOs = new uint256[](tokens.length);

            for (uint256 j = 0; j < tokens.length; j++) {
                (ILOs[j], , , ) = nftContract.tokenDetails(_owners[i], tokens[j]);
            }

            ownerTokens[i] = tokens;
            ownerTokenILOs[i] = ILOs;
        }

        return (ownerTokens, ownerTokenILOs);
    }


    function getTokensOfOwnersInfo(address[] calldata _owners) external view returns (TokenDetail[][] memory) {
        TokenDetail[][] memory ownerTokenDetails = new TokenDetail[][](_owners.length);

        for (uint256 i = 0; i < _owners.length; i++) {
            uint256[] memory tokens = nftContract.tokensOfOwner(_owners[i]);
            TokenDetail[] memory tokenDetails = new TokenDetail[](tokens.length);

            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 ILOs;
                (ILOs, , , ) = nftContract.tokenDetails(_owners[i], tokens[j]);
                tokenDetails[j] = TokenDetail({
                    tokenId: tokens[j],
                    ILOCount: ILOs
                });
            }

            ownerTokenDetails[i] = tokenDetails;
        }

        return ownerTokenDetails;
    }

}