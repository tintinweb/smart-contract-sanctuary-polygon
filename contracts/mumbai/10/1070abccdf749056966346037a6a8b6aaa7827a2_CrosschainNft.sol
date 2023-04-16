pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Strings.sol";
import "./NonblockingReceiver.sol";
import "./Ownable.sol";

//Polygon contract

contract CrosschainNft is Ownable, ERC721, NonblockingReceiver {

    address public _owner;
    string private baseURI;
    uint256 nextTokenId = 0;
    uint256 MAX_MINT_POLYGON = 10000;

    uint gasForDestinationLzReceive = 350000;

    constructor(string memory baseURI_, address _layerZeroEndpoint) ERC721("CrosschainNft", "test") { 
        _owner = msg.sender;
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        baseURI = baseURI_;
    }

    // mint function
    function mint(uint8 count) external payable {
        require(nextTokenId + count <= MAX_MINT_POLYGON, "Mint out");
        _safeMint(msg.sender, ++nextTokenId);
    }

    // This function transfers the nft from your address on the 
    // source chain to the same address on the destination chain
    function crossChains(uint16 _chainId, uint tokenId) public payable {
        require(msg.sender == ownerOf(tokenId), "You must own the token to cross");
        require(trustedRemoteLookup[_chainId].length > 0, "Sorry, This chain is currently unavailable for cross");

        // burn NFT, eliminating it from circulation on src chain
        _burn(tokenId);

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint messageFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);
        
        require(msg.value >= messageFee, "msg.value not enough to cover messageFee. Send gas for message fees");

        endpoint.send{value: msg.value}(
            _chainId,                           // destination chainId
            trustedRemoteLookup[_chainId],      // destination address of nft contract
            payload,                            // abi.encoded()'ed bytes
            payable(msg.sender),                // refund address
            address(0x0),                       // 'zroPaymentAddress' unused for this
            adapterParams                       // txParameters 
        );
    }  

    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

/*
    // just in case this fixed variable limits us from future integrations
    function setGasForDestinationLzReceive(uint newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }
*/
    // ------------------
    // Internal Functions
    // ------------------

    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) override internal {
        // decode
        (address toAddr, uint tokenId) = abi.decode(_payload, (address, uint));

        // mint the tokens back into existence on destination chain
        _safeMint(toAddr, tokenId);
    }  

    function _baseURI() override internal view returns (string memory) {
        return baseURI;
    }
}