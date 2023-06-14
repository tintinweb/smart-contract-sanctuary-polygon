//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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
    * Events from ocean protocol
    * https://github.com/oceanprotocol/contracts/blob/main/contracts/ERC721Factory.sol#L62
     */

    // event Template721Added(address indexed _templateAddress, uint256 indexed nftTemplateCount);
    // event Template20Added(address indexed _templateAddress, uint256 indexed nftTemplateCount);
    event TokenCreated(
        address indexed newTokenAddress,
        address indexed templateAddress,
        string name,
        string symbol,
        uint256 cap,
        address creator
    );  
    // event NewPool(
    //     address poolAddress,
    //     address ssContract,
    //     address baseTokenAddress
    // );
    // event NewFixedRate(bytes32 exchangeId, address indexed owner, address exchangeContract, address indexed baseToken);
    // event NewDispenser(address dispenserContract);
    // event DispenserCreated(  // emited when a dispenser is created
    //     address indexed datatokenAddress,
    //     address indexed owner,
    //     uint256 maxTokens,
    //     uint256 maxBalance,
    //     address allowedSwapper
    // );
    // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
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

    // event MetadataCreated(
    //     address indexed createdBy,
    //     uint8 state,
    //     string decryptorUrl,
    //     bytes flags,
    //     bytes data,
    //     bytes32 metaDataHash,
    //     uint256 timestamp,
    //     uint256 blockNumber
    // );

    OPFactory oceanFactory;

    constructor(address oceanFactoryAddress) {
        oceanFactory = OPFactory(oceanFactoryAddress);
    }

    function createNftWithErc20WithFixedRate(OPFactory.NftCreateData calldata nftData, OPFactory.ErcCreateData calldata ercData, OPFactory.FixedData calldata fixedData) public {
        oceanFactory.createNftWithErc20WithFixedRate(nftData, ercData, fixedData);        
    }
}