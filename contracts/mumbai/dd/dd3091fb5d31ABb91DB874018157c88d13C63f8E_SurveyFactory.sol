/**
 *Submitted for verification at polygonscan.com on 2023-06-27
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

interface OPFactory {
    struct NftCreateData {
        string name;
        string symbol;
        uint256 templateIndex;
        string tokenURI;
        bool transferable;
        address owner;
    }

    struct ErcCreateData {
        uint256 templateIndex;
        string[] strings;
        address[] addresses;
        uint256[] uints;
        bytes[] bytess;
    }

    struct FixedData {
        address fixedPriceAddress;
        address[] addresses;
        uint256[] uints;
    }

    function createNftWithErc20WithFixedRate(
        NftCreateData calldata _NftCreateData, 
        ErcCreateData calldata _ErcCreateData, 
        FixedData calldata _FixedData
    ) external returns (address erc721Address, address erc20Address, bytes32 exchangeId);

}


contract SurveyFactory {

    /**
    * Events from Ocean Protocol
    * https://github.com/oceanprotocol/contracts/blob/main/contracts/ERC721Factory.sol#L62
    */

    event TokenCreated(
        address indexed newTokenAddress,
        address indexed templateAddress,
        string name,
        string symbol,
        uint256 cap,
        address creator
    );  
    
    event NFTCreated(
        address newTokenAddress,
        address indexed templateAddress,
        string tokenName,
        address indexed admin,
        string symbol,
        string tokenURI,
        bool transferable,
        address indexed creator
    );

    /// Ocean Protocol contract
    OPFactory oceanFactory;

    /// @notice Constructor to initialize the 
    /// @param oceanFactoryAddress Ocean Factory's address
    constructor(address oceanFactoryAddress) {
        oceanFactory = OPFactory(oceanFactoryAddress);
    }

    /// @notice Creates an nft and data token with a fixed price.
    /// @dev After calling the function, get events NFTCreated and TokenCreated in the client.
    /// @param nftData Data related to the NFT to create.
    /// @param ercData Data related to the token to create.
    /// @param fixedData Data related to the price.
    function createNftWithErc20WithFixedRate(OPFactory.NftCreateData calldata nftData, OPFactory.ErcCreateData calldata ercData, OPFactory.FixedData calldata fixedData) public {
        oceanFactory.createNftWithErc20WithFixedRate(nftData, ercData, fixedData);        
    }
}