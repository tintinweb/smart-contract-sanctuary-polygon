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

    OPFactory public oceanFactory;

    address public publisher;

    constructor(address oceanFactoryAddress) {
        oceanFactory = OPFactory(oceanFactoryAddress);
        publisher = msg.sender;
    }

    function createNftWithErc20WithFixedRate(OPFactory.NftCreateData calldata nftData, OPFactory.ErcCreateData calldata ercData, OPFactory.FixedData calldata fixedData) public {
        oceanFactory.createNftWithErc20WithFixedRate(nftData, ercData, fixedData);        
    }

}