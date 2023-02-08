// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;


interface IExtLicense {
    function getAgreementPage(uint16 page) external view returns (string memory);
    function renderSignaturePage(uint256 tokenId) external view returns (string memory);
    function agreementPageCount() external view returns(uint16); 
}

struct TokenMetadata {
    uint16 tokenId;
    string name;
    string description;
    string image;
    string animation_url;
    string image_hash;
    string anim_hash; 
}
struct Keypair {
    string key;
    string value;
}

/**
 * BKExternalConnector is intended for use cases where a license agreement is required for a ERC721 contract which 
 * is not BKopy compatible, such as Mojito's NFT contract.
 * In this case the BKExternal contract supply the data from the native ERC721 (e.g. the Mojito license).
 * When the ERC721 is resident on a blockchain other than Polygon, the token metadata must be loaded 
 * by from a client DApp which can call the 721's tokenURI function, and then supply it to this BKExternal contract.
 * When the ERC721 is on the same blockchain as this contract (i.e. Polygon), the tokenURI function can be
 * called directly.  
 * 
 * This BKExternal generates a license agreement based on values contained accessible from standard ERC721 functions 
 * on the native license.
 */

contract BKExternalConnector {
    mapping(uint256 => TokenMetadata) public tokenMetadata;  //token-based metadata like artwork title and url, etc.
    string public BKContractName = "BKExternalConnector";
    string public BKVersion = "0.1.0";
    string public nativeChain; //the chain which holds the native contract
    string public NFTName;
    address public publisherAddress; //the address of signatory of the license agreement.
    address public BKExtLicenseAddress;
    address public nativeAddress; //the address of the ERC-721 to which this contract refers
    bool public hasTokens; //If there is no token 0, this is false.
    uint public minTokenId = 0;  
    uint public maxTokenId = 0;  //this is the actual highest live tokenId on the NFT.  (If hasTokens is true);
    uint public maxRecordedId = 0; //this is the highest tokenId for which tokenMetaData has been acquired. (if Has tokens is true)
    uint public tokenMetaCount; //The number of tokens for which tokenMetadata has been recorded
    address public owner;
    address public license;
    string[] private attribNames;  //names of constant attribs (all values are string (names are tagrefs;
    mapping(string=>string) attribsMap; //mapping of key (the tag ref) to values for contract attribs (constant for all tokens.)

    constructor(string memory nativeChain_, address nativeAddress_, string memory name_, address publisherAddress_, uint16 maxId) {
        nativeChain = nativeChain_;
        nativeAddress = nativeAddress_;
        publisherAddress = publisherAddress_;  //the party who signs the agreement
        NFTName = name_;
        owner = msg.sender;  //the deployer of the this contract and license (ownership may be transferred to publisher)
        maxTokenId = maxId;
    }

    /* deployed: '0x7e7145F035fd736c53450cACad6cB7a8520DF484 BKExternal connector
    rancho Ethereum 0xdb5409f9dB2C5F80B238C7dc8EddeB18dfA17aB6 Tomokazu Matsuyama: Harmless Charm 0x68574fFa1CE758aCD941B7b8d590Fd7aC6e53787 4 */
    /*
    ourceNFTChain: 'Ethereum',
  SourceNFTAddress: '0xdb5409f9dB2C5F80B238C7dc8EddeB18dfA17aB6',
  PublisherAddress: '0x68574fFa1CE758aCD941B7b8d590Fd7aC6e53787',
  MaxTokenId: 485,
  BindingCollectionAddress: '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9',
  BKExternalConnectorAddress: '0x70e0bA845a1A0F2DA3359C97E0285013525FFC49',
  BKExternalLicenseAddress: '0x4826533B4897376654Bb4d4AD88B7faFD0C98528',
  DeploymentChain: 'Localhost',
  TokensProcessCount: 4,
  TokenLimit: 4
    {
  SourceNFTChain: 'Ethereum',
  SourceNFTAddress: '0xdb5409f9dB2C5F80B238C7dc8EddeB18dfA17aB6',
  PublisherAddress: '0x68574fFa1CE758aCD941B7b8d590Fd7aC6e53787',
  MaxTokenId: 485,
  BindingCollectionAddress: '0x9502E0e65903752A20C9dE2e2D630Daf4c89e13A',
  BKExternalConnectorAddress: '0xC02EAe599D97b5372eBEE4e3F378D7372211Ee04',
  BKExternalLicenseAddress: '0x2588681D3F4f23D53D48Ba081893B75e59641F56',
  DeploymentChain: 'Localhost',
  TokensProcessCount: 4,
  TokenLimit: 4
}
ourceNFTChain: 'Ethereum',
  SourceNFTAddress: '0xdb5409f9dB2C5F80B238C7dc8EddeB18dfA17aB6',
  PublisherAddress: '0x68574fFa1CE758aCD941B7b8d590Fd7aC6e53787',
  MaxTokenId: 485,
  BindingCollectionAddress: '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9',
  BKExternalConnectorAddress: '0x70e0bA845a1A0F2DA3359C97E0285013525FFC49',
  BKExternalLicenseAddress: '0x4826533B4897376654Bb4d4AD88B7faFD0C98528',
  DeploymentChain: 'Localhost',
  TokensProcessCount: 4,
  TokenLimit: 4
    */


    function attachLicense(address bkExtLicenseAddress, uint maxId) public {
        require(msg.sender == owner, "{CK3X3X only protocol owner}");
        require(BKExtLicenseAddress == address(0), "{SJX933} Write once");
        license  = bkExtLicenseAddress;
        maxTokenId = maxId;
    }

    function getPage(uint16 page) public view returns(string memory) {
        IExtLicense elicense = IExtLicense(license);
        require(page > 0 && page <= elicense.agreementPageCount(), "Page out of range");
        return (elicense.getAgreementPage(page));
    }
    function getPageCount() public view returns(uint16) {
         IExtLicense elicense = IExtLicense(license);
         return elicense.agreementPageCount();
    }
    function getSchedule(uint tokenId) public view returns(string memory) {
        require(tokenId <= maxTokenId, "invalidTokenId {C39X3X}");
         IExtLicense elicense = IExtLicense(license);
         return elicense.renderSignaturePage(tokenId);

    }
    
// function getAgreementPage(uint16 page) external view returns (string memory);
//     function renderSignaturePage(uint256 tokenId) external view returns (string memory);
//     function agreementPageCount() external view returns(uint16); 

    function transferOwnership(address newOwner) public {
        require(msg.sender==owner, "{JF9X9D onlyowner can change owner.");
        owner=newOwner;
    }

    

    function saveTokenMeta(TokenMetadata memory meta) public {
        require(msg.sender == owner, "{3939D} only owner");
        require(tokenMetadata[meta.tokenId].tokenId==0, "{X93X3} Write once");
        require(meta.tokenId<=maxTokenId && hasTokens, "{V93FFA} Max tokenId must be updated before saving token Meta");
        tokenMetadata[meta.tokenId] = meta;
        tokenMetaCount++;
        if (meta.tokenId > maxRecordedId) { maxRecordedId = meta.tokenId ;}
    }

    function getImageUrl(uint tokenId) public view returns(string memory) {return tokenMetadata[tokenId].image;}
    function getDescription(uint tokenId) public view returns(string memory) {return tokenMetadata[tokenId].description;}
    function getArtworkTitle(uint tokenId) public view returns(string memory) {return tokenMetadata[tokenId].name;}
    function getAnimUrl(uint tokenId) public view returns(string memory) {return tokenMetadata[tokenId].animation_url;}
    function getImageHash(uint tokenId) public view returns(string memory) {return tokenMetadata[tokenId].image_hash;}
    function getAnimHash(uint tokenId) public view returns(string memory ) {return tokenMetadata[tokenId].anim_hash;}

/*
uint16 tokenId;
    string name;
    string description;
    string image;
    string animation_url;
    bytes32 image_hash;
    bytes32 anim_hash; 
*/



    /**
     * This function sets the image hasha nd anim hash independntly of the tokenmetadata set in
     * save TokenMetadata.  It should be run after saveToken Meta or the data will be overwritten.
     * @param tokenId  -tokens id
     * @param image_hash - hash of image asset 
     * @param anim_hash  - hash of mp4 asset.
     */
    function saveImageHashes(uint tokenId, string memory image_hash, string memory  anim_hash) public {
        require(msg.sender == owner, "{D9X93X} only owner");
        tokenMetadata[tokenId].image_hash = image_hash;
        tokenMetadata[tokenId].anim_hash = anim_hash;
    }

    function hasTokenMetadata(uint tokenId) public view returns(bool) {
        if (tokenMetadata[tokenId].tokenId != tokenId) return false;
        return true;
    }

    function setMaxId(uint16 maxTokenId_) public {
        require(msg.sender == owner);
        maxTokenId = maxTokenId_;
        hasTokens=true;
    }


    // function saveContractAttribs(Keypair[] memory keypairs) public {
    //     require(attribNames.length==0, "ContractAttibs are write once");
    //     require(msg.sender == owner);
    //     for (uint i=0; i<keypairs.length; i++) {
    //         attribNames.push(keypairs[i].key);
    //         attribsMap[keypairs[i].key]=keypairs[i].value;
    //     }
        
    // }
    // function getContractAttribValue(string memory key) public view returns(string memory) {
    //     return attribsMap[key];
    // }

    // function getContractAttribNames() public view returns(string[] memory) {
    //     return attribNames;
    // }
}