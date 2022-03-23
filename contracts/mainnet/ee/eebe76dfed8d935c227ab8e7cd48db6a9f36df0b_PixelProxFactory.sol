pragma solidity 0.5.0;

import "./ERC721Full.sol";

contract PixelProxFactory is ERC721Full {

    constructor() ERC721Full("Pixel Prox DAO", "DPXP") public {
    }

    // contrato de venta que genera los tokens 
    address ownerCanCreateMakeNFTs = address(0);

    /**
    * Estructura de la pixel de las plantas 
    * digitales en su version 1
    */
    struct pixel {
        address creator;
        string ipfs;
    }
    // asignar pixels (nfts)
    pixel[] public pixels;

    // Crear NFT
    function _createNFT(address _beneficiary, string memory ipfs) private {
        // obtener y asignar el id del nft
        uint256 idNft = pixels.push(pixel(_beneficiary, ipfs));
        // crear el token
        _mint(_beneficiary, idNft);
        _setTokenURI(idNft, ipfs);
    }

    // Crear nuevo codigo pixel
    function createNewNFT(address _beneficiary, string memory ipfs) public {
        require(msg.sender == ownerCanCreateMakeNFTs, "Genetic only can be created by owner Fabric contract");
        _createNFT(_beneficiary, ipfs);
    }

    // Configuracion inicial del contrato. Solo puede crear tokens el contrato que se asigne al inicio
    function setup(address newOwnerAddress) public {
        //require(newOwnerAddress != '', "Address format incorrect");
        require(ownerCanCreateMakeNFTs == address(0), "Error! Contract initialized");
        ownerCanCreateMakeNFTs = newOwnerAddress;
    }

    /**
    * Obtener los NFT que tiene un owner
    */
    function tokensOfOwner(address owner) public view returns (uint256[] memory){
        return _tokensOfOwner(owner);
    }

    // cambiar de owner (versionamiento de contratos)
    function changeOwnerContract(address newOwnerContract) public {
        // solo el owner puede cambiar la direccion de contrato
        require(ownerCanCreateMakeNFTs == msg.sender, "You dont have access to this tool");
        ownerCanCreateMakeNFTs = newOwnerContract;
    }
}