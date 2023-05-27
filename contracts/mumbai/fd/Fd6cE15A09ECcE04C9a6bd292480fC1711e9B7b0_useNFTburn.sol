/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

struct TokenDetail {
    address owner;
    uint256 tokenId;
    uint256 ILOCount;
    uint256 category;
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
        nftContract = INFTContract(0x7c5Cdf24Bc41520beeCa4E5384015C9dd8067A18);
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

    function getTokensOfOwnersON(address[] calldata _owners) external view returns (
        address[][] memory,
        uint256[][] memory, 
        uint256[][] memory) 
    {
        uint256[][] memory ownerTokens = new uint256[][](_owners.length);
        uint256[][] memory ownerTokenILOs = new uint256[][](_owners.length);
        address[][] memory ownerAddresses = new address[][](_owners.length);

        for (uint256 i = 0; i < _owners.length; i++) {
            uint256[] memory tokens = nftContract.tokensOfOwner(_owners[i]);
            uint256[] memory ILOs = new uint256[](tokens.length);
            address[] memory owners = new address[](tokens.length);

            for (uint256 j = 0; j < tokens.length; j++) {
                (ILOs[j], , , ) = nftContract.tokenDetails(_owners[i], tokens[j]);
                owners[j] = _owners[i];
            }

            ownerTokens[i] = tokens;
            ownerTokenILOs[i] = ILOs;
            ownerAddresses[i] = owners;
        }

        return (ownerAddresses, ownerTokens, ownerTokenILOs);
    }


    function getTokensOfOwnersInfo(address[] calldata _owners) external view returns (TokenDetail[][] memory) {
        TokenDetail[][] memory ownerTokenDetails = new TokenDetail[][](_owners.length);

        for (uint256 i = 0; i < _owners.length; i++) {
            uint256[] memory tokens = nftContract.tokensOfOwner(_owners[i]);
            TokenDetail[] memory tokenDetails = new TokenDetail[](tokens.length);

            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 ILOs;
                uint256 _category;
                (ILOs, , , ) = nftContract.tokenDetails(_owners[i], tokens[j]);
                (, , _category, ) = nftContract.tokenDetails(_owners[i], tokens[j]);
                tokenDetails[j] = TokenDetail({
                    owner: _owners[i],
                    tokenId: tokens[j],
                    ILOCount: ILOs,
                    category: _category
                });
            }

            ownerTokenDetails[i] = tokenDetails;
        }

        return ownerTokenDetails;
    }

    // Function to get tokens of a specific ILO count
    function getTokensWithSpecificILOs(address[] calldata _owners, uint256 _ILOs) external view returns (TokenDetail[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < _owners.length; i++) {
            uint256[] memory tokens = nftContract.tokensOfOwner(_owners[i]);
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 ILOs;
                (ILOs, , , ) = nftContract.tokenDetails(_owners[i], tokens[j]);
                if(ILOs == _ILOs) {
                    count += 1;
                }
            }
        }

        TokenDetail[] memory tokensWithSpecificILOs = new TokenDetail[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < _owners.length; i++) {
            uint256[] memory tokens = nftContract.tokensOfOwner(_owners[i]);
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 ILOs;
                uint256 _category;
                (ILOs, , , ) = nftContract.tokenDetails(_owners[i], tokens[j]);
                (, , _category, ) = nftContract.tokenDetails(_owners[i], tokens[j]);
                if(ILOs == _ILOs) {
                    tokensWithSpecificILOs[index] = TokenDetail({
                        owner: _owners[i],
                        tokenId: tokens[j],
                        ILOCount: ILOs,
                        category: _category
                    });
                    index += 1;
                }
            }
        }

        return tokensWithSpecificILOs;
    }

}