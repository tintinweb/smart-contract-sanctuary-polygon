pragma solidity 0.8.7;

import "./ERC721_WhiteListMint.sol";

contract PunchableERC721 is ERC721WhiteListMint{

    struct PunchCard{
        address puncherAddress;
        uint8 maxPunches;
    }

    mapping(string => PunchCard) public punchBook;
    mapping(uint => mapping(string => uint8)) nftPunchBook;

    constructor(uint _reservedIDs, string memory name, string memory symbol) ERC721WhiteListMint(_reservedIDs, name, symbol){}

    function createPunchCard(string memory eventId, address puncherAddress,uint8 maxPunches) external onlyOwner {
        require(address(punchBook[eventId].puncherAddress) == address(0) &&  punchBook[eventId].maxPunches == 0,
                "201" );
        punchBook[eventId] = PunchCard(puncherAddress, maxPunches);
    }

    function updatePuncherAddress(string memory eventId, address puncherAddress) external onlyOwner {
        punchBook[eventId].puncherAddress = puncherAddress;
    }

    function updateMaxPunches(string memory eventId, uint8 maxPunches) external onlyOwner {
        punchBook[eventId].maxPunches = maxPunches;
    }

    function burnPunchCard(string memory eventId) external onlyOwner {
        punchBook[eventId] = PunchCard(address(0), 0);
    }

    function punchACard(string memory eventId, uint256 _tID, uint8 increment) external {
        require( _msgSender() == punchBook[eventId].puncherAddress, "202");
        require(nftPunchBook[_tID][eventId] + increment <= punchBook[eventId].maxPunches, "203");
        nftPunchBook[_tID][eventId] += increment;
    }

    function getNFTPunchesPerCard(string memory eventId, uint256 _tID) external view returns (uint){
        require(_exists(_tID), "001");
        return nftPunchBook[_tID][eventId];
    }


}

// SPDX-License-Identifier: MIT
//repo

pragma solidity 0.8.7;

import "./SDKERC_721.sol";

contract ERC721WhiteListMint is SDKERC721{

  // State info for the next TID to mint. No NFTs can be minted above this number
  uint256 nextTID;
 //NFT Minting info
  address mintingAddress;

  modifier allowedMinter (){
    require( owner() == _msgSender() || mintingAddress == _msgSender(), "101");
    _;
  }

 /*****************************************************************************************
     constructor: Function to create a reserved set of ids to mint as well as a "nextTID" variable
     @param _reservedIDs: The id's that below are reserved
 *****************************************************************************************/

  constructor(uint _reservedIDs, string memory name, string memory symbol) SDKERC721(_reservedIDs, name, symbol){
      nextTID = _reservedIDs;
  }

/*****************************************************************************************
     mint: Function to mint a particular token with a specific _eID, no metadata provided initially with this function
      The NFT ID Must be less than nextTID (essentially reservedIDs or any burnt NFT)
     @param _to: Recipeint of the NFT
     @param _tID: the Token ID of the NFT
     @param _eID: the Token's expereince ID of the NFT
 *****************************************************************************************/
 function mint(address _to, uint256 _tID, uint256 _eID) external override allowedMinter {
   require(_tID <= nextTID, "102");
   super._mint(_to, _tID);
   EID[_tID] = _eID;
   supply++;
 }

 /*****************************************************************************************
     mint: Function to mint a particular token with a specific _eID, and specific _Uri for metadata
     The NFT ID Must be less than nextTID (essentially reservedIDs or any burnt NFT)
     @param _to: Recipeint of the NFT
     @param _tID: the Token ID of the NFT
     @param _eID: the Token's expereince ID of the NFT
     @param _Uri: the Token's URI
 *****************************************************************************************/
 function mint(address _to, uint256 _tID, uint256 _eID, string memory _Uri) external override allowedMinter {
   require(_tID <= nextTID, "102");
   super._mint(_to, _tID);
   EID[_tID] = _eID;
   nftTokenUri[_tID] = _Uri;
   supply++;
 }

 /*****************************************************************************************
     mint: Function to mint a particular token with a specific _eID, no metadata provided initially with this function
     The NFT ID Must be less than nextTID (essentially reservedIDs or any burnt NFT)
     @param _to: Recipeint of the NFT
     @param _eID: the Token's expereince ID of the NFT
 *****************************************************************************************/
 function mint(address _to, uint256 _eID) external  allowedMinter {
   nextTID += 1;
   super._mint(_to, nextTID);
   EID[nextTID] = _eID;
   supply++;
 }

 /*****************************************************************************************
     mint: Function to mint a particular token with a specific _eID, and specific _Uri for metadata
     The NFT ID Must be less than nextTID (essentially reservedIDs or any burnt NFT)
     @param _to: Recipeint of the NFT
     @param _eID: the Token's expereince ID of the NFT
     @param _Uri: the Token's URI
 *****************************************************************************************/
 function mint(address _to, uint256 _eID, string memory _Uri) external allowedMinter {
   nextTID += 1;
   super._mint(_to, nextTID);
   EID[nextTID] = _eID;
   nftTokenUri[nextTID] = _Uri;
   supply++;
 }

 /*****************************************************************************************
     @dev Sets the minter address
     @param _minterAddress Address of who can mint the NFT
   *****************************************************************************************/
  function setMinter(address _minterAddress ) external onlyOwner {
      //changes the minter address
      mintingAddress = _minterAddress;
  }

 /*****************************************************************************************
     minter: Returns address of who can mint
     @return address: the address of who can mint
 *****************************************************************************************/
 function minter() public view returns (address) {
   return mintingAddress;
 }

 /*****************************************************************************************
     @dev Burns an NFT.

     @notice that this burn implementation allows the minter to re-mint a burned NFT.

     @param _tokenId ID of the NFT to be burned.
   *****************************************************************************************/
  function burn(uint256 _tokenId ) external {
    require( owner() == _msgSender() || mintingAddress == _msgSender(), "101");
      //clearing the uri
      nftTokenUri[_tokenId] = "";
      //clearing the experience
      EID[_tokenId] = 0;
      //burning the token for good
      super._burn(_tokenId);
      supply--;
  }

  /*****************************************************************************************
     setTokenEID: Function to set the experience ID of a given NFT

     @param _tID: the Token ID of the NFT

     @param _eID: the experience ID of the NFT

 *****************************************************************************************/
 function setTokenEID(uint256 _tID, uint256 _eID) external  {
   require( owner() == _msgSender() || mintingAddress == _msgSender(), "101");
   require(_exists(_tID), "001");
   EID[_tID] = _eID;
 }

}

// SPDX-License-Identifier: MIT
//repo

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract SDKERC721 is ERC721, Ownable{

   //Global metadata
  string private globalMetadata;

 //Metadata per _experienceID
 mapping (uint256 => string) internal tokenUri;
 //EID
 mapping (uint256 => uint256) internal EID;

 //Metadata per _nftID
 mapping (uint256 => string) internal nftTokenUri;

 string private _contractURI;

 //royalty info
  address royaltyRecipient;

  uint16 royaltyValue;

  //For Rarible royalty standard
  bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

  uint immutable public reservedIDs;

  uint internal supply;

  event RoyaltiesSet(uint256 tokenId, Part royalties);


 constructor(uint _reservedIDs, string memory name, string memory symbol) ERC721(name, symbol) {
      reservedIDs = _reservedIDs;
 }


 /*****************************************************************************************
     makeMetadata: Function for updating metadata per specific NFT. Overrides default
                   "experience" metadata

     @param _tID: Token ID to have metadata modified for

     @param _Uri: The URI that has a JSON packet of metadata
 *****************************************************************************************/
 function makeMetadata(uint256 _tID, string memory _Uri) external onlyOwner {
   require(_exists(_tID),"001");
   nftTokenUri[_tID] = _Uri;
 }

 /*****************************************************************************************
     makeExperience: Function for updating or creating a set of metadata for all NFTs in
                   a given experience.

     @param _eID: Token experience ID to have metadata modified for

     @param _Uri: The URI that has a JSON packet of metadata
 *****************************************************************************************/
 function makeExperience(uint256 _eID, string memory _Uri) external onlyOwner {
   tokenUri[_eID] = _Uri;
 }

  /*****************************************************************************************
     setTokenEID: Function to set the experience ID of a given NFT

     @param _tID: the Token ID of the NFT

     @param _eID: the experience ID of the NFT

 *****************************************************************************************/
//  function setTokenEID(uint256 _tID, uint256 _eID) external virtual onlyOwner {
//    require(_exists(_tID), "Nonexistent token");
//    EID[_tID] = _eID;
//  }

 /*****************************************************************************************
     contractURI: Function for updating or creating the metadata of the contract. Used by opensea

     @param _Uri: The URI that has a JSON packet of metadata

     EX: {
       "name": "OpenSea Creatures",
       "description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
       "image": "https://openseacreatures.io/image.png",
       "external_link": "https://openseacreatures.io",
       "seller_fee_basis_points": 100, # Indicates a 1% seller fee.
       "fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
     }
 *****************************************************************************************/
 function setContractURI(string memory _Uri) external onlyOwner {
     _contractURI = _Uri;
 }

 /*****************************************************************************************
     mint: Function to mint a particular token with a specific _eID, no metadata provided initially with this function

     @param _to: Recipeint of the NFT

     @param _tID: the Token ID of the NFT

     @param _eID: the Token's expereince ID of the NFT

 *****************************************************************************************/
 function mint(address _to, uint256 _tID, uint256 _eID) external virtual onlyOwner {
   super._mint(_to, _tID);
   EID[_tID] = _eID;
   supply++;
 }

 /*****************************************************************************************
     mint: Function to mint a particular token with a specific _eID, and specific _Uri for metadata

     @param _to: Recipeint of the NFT

     @param _tID: the Token ID of the NFT

     @param _eID: the Token's expereince ID of the NFT

     @param _Uri: the Token's URI

 *****************************************************************************************/
 function mint(address _to, uint256 _tID, uint256 _eID, string memory _Uri) external virtual onlyOwner {
   super._mint(_to, _tID);
   EID[_tID] = _eID;
   nftTokenUri[_tID] = _Uri;
   supply++;
 }

 /*****************************************************************************************
     mint: Function to mint a particular token with a specific _eID, no metadata provided initially with this function

     @param _to: Recipeint of the NFT

     @param _tID: the Token ID of the NFT

     @param _eID: the Token's expereince ID of the NFT

//  *****************************************************************************************/
//  function mint(address _to, uint256 _eID) external virtual onlyOwner {
//    uint newId = getMaxId() + 1;
//    super._mint(_to, newId);
//    EID[newId] = _eID;
//  }

//  /*****************************************************************************************
//      mint: Function to mint a particular token with a specific _eID, and specific _Uri for metadata

//      @param _to: Recipeint of the NFT

//      @param _tID: the Token ID of the NFT

//      @param _eID: the Token's expereince ID of the NFT

//      @param _Uri: the Token's URI

//  *****************************************************************************************/
//  function mint(address _to, uint256 _eID, string memory _Uri) external virtual onlyOwner {
//    uint newId = getMaxId() + 1;
//    super._mint(_to, newId);
//    EID[newId] = _eID;
//    nftTokenUri[newId] = _Uri;

//  }

  /*****************************************************************************************
     @dev Burns an NFT.

     @notice that this burn implementation allows the minter to re-mint a burned NFT.

     @param _tokenId ID of the NFT to be burned.
   *****************************************************************************************/
  // function burn(uint256 _tokenId ) external virtual onlyOwner {
  //     //clearing the uri
  //     nftTokenUri[_tokenId] = "";
  //     //clearing the experience
  //     EID[_tokenId] = 0;
  //     //burning the token for good
  //     super._burn(_tokenId);
  // }

 /*****************************************************************************************
      @dev Sets the metadata for all the NFTs. If it's not empty (""), all NFTs will
      have this metadata showing.
      @param _uri the URI of the metadata.
  *****************************************************************************************/
  function setGlobalMetadata(string memory _uri) external onlyOwner {
      globalMetadata = _uri;
  }

 /*****************************************************************************************
     contractURI: Function to return the URI json metadata of a smart contract

     @return string: the URI of the contract

 *****************************************************************************************/
 function contractURI() public view returns (string memory) {
     return _contractURI;
 }


 /*****************************************************************************************
     tokenEID: Function to return the experience ID of a given NFT

     @param _tID: the Token ID of the NFT

     @return uint256: the expereicen ID of a particular NFT

 *****************************************************************************************/
 function tokenEID(uint256 _tID) public view returns (uint256) {
   require(_exists(_tID), "001");
   return EID[_tID];
 }

 /*****************************************************************************************
     _experienceEmpty: Helper function to determine if Token URI is empty of not for given NFT

     @param _tID: the Token ID of the NFT

     @return bool: If the tokenURI is empty and needs to be overriden

 *****************************************************************************************/
 function _experienceEmpty(uint256 _tID) internal view returns (bool) {
   require(_exists(_tID), "001");
   string memory empty = "";
   return keccak256(bytes(tokenUri[EID[_tID]])) == keccak256(bytes(empty));
 }

 /*****************************************************************************************
     @dev: Helper function to determine if Token URI is empty of not for given NFT
     @param _tID: the Token ID of the NFT
     @return bool: If the tokenURI is empty and needs to be overriden

 *****************************************************************************************/
 function _globalUriEmpty() internal view returns (bool) {
   string memory empty = "";
   return keccak256(bytes(globalMetadata)) == keccak256(bytes(empty));
 }

 /*****************************************************************************************
     supportsInterface: Overrides the default interface of ERC721 to allow for support of royalties

     @param interfaceId: the interface ID to see if it is accepted

     @return bool: True for any ERC721 interface as well as royalties

 *****************************************************************************************/
 bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
 bytes4 private constant _INTERFACE_ID_RARIBLE_ROYALTIES = 0xcad96cca;
 function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {

     return
         interfaceId == _INTERFACE_ID_ERC2981 ||
         interfaceId == _INTERFACE_ID_RARIBLE_ROYALTIES ||
         super.supportsInterface(interfaceId);
 }


 /*****************************************************************************************
     @dev Sets the royalties for the NFTs
     @notice that since all the NFTs will have the same percentage and address for royalties,
     it's not required to set individual values for each NFT. Instead, A global address and
     percentage is set for all of them.
     @param _royaltiesReceipientAddress: the address receiving the royalties
     @param _percentage: percentage of the tx to pay for royalties. Must be
      amplified 100 times.
     @notice that _percentageBasisPoints is amplified 100 Xs in order to be able to have
     0.01% accuracy.
  *****************************************************************************************/
     function setRoyalties(address _royaltiesReceipientAddress, uint16 _percentage) public onlyOwner {
       require(_percentage < 10000, '002');
       royaltyRecipient = _royaltiesReceipientAddress;
       royaltyValue = _percentage;
       emit RoyaltiesSet(0, Part(payable(royaltyRecipient), royaltyValue));
   }

  /*****************************************************************************************
      @dev Called with the sale price to determine how much royalty is owed and to whom.
      @notice this is the only method specified to comply with the ERC2981 standard
      @param _tokenId - the NFT asset queried for royalty information. @notice this
      parameter is not really used in this implementation since all NFTs have the same
      percentage and recipient address. It is only part of the method to comply with
      the standard.
      @param _salePrice - the sale price of the NFT asset specified by _tokenId
      @return receiver - address of who should be sent the royalty payment
      @return royaltyAmount - the royalty payment amount for value sale price
  *****************************************************************************************/
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view

        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyRecipient, (_salePrice * royaltyValue) / 10000);
    }

    /*****************************************************************************************
      @dev
     *****************************************************************************************/
     function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }

    /*****************************************************************************************
      @dev
    *****************************************************************************************/
    function getRaribleV2Royalties(uint256 id) external view returns (Part memory){
      Part memory raribleRoyalty = Part(payable(royaltyRecipient), royaltyValue);
      return raribleRoyalty;
    }

 /*****************************************************************************************
     @dev Returns the metadata URI of the token.
     @param _tID: the Token ID of the NFT
     @return string: The URI with the URL to the JSON metadata packet.
     @notice Return varies depending if the global metadata is set or not, or if the
     experience has metadata set or not since these act as masks for the NFT URI.
 *****************************************************************************************/
 function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
   require(_exists(tokenId), "001");
   if (!_globalUriEmpty()){
     return globalMetadata;

   }else if(!_experienceEmpty(tokenId)){
       return tokenUri[EID[tokenId]];
   }
   else{
       return nftTokenUri[tokenId];
   }
 }


 /*****************************************************************************************
     appendUintToString: Returns a string composed of a string and a number passed into said string

     @param inStr: the input string

     @param v: the number to append to the string

     @return string: the inputted string with the number as a string inputted.

 *****************************************************************************************/
   function appendUintToString(string memory inStr, uint v) internal pure returns (string memory) {
     uint maxlength = 100;
     bytes memory reversed = new bytes(maxlength);
     uint i = 0;
     while (v != 0) {
         uint remainder = v % 10;
         v = v / 10;
         reversed[i++] = bytes1(uint8(48 + remainder));
     }
     bytes memory inStrb = bytes(inStr);
     bytes memory s = new bytes(inStrb.length + i);
     uint j;
     for (j = 0; j < inStrb.length; j++) {
         s[j] = inStrb[j];
     }
     for (j = 0; j < i; j++) {
         s[j + inStrb.length] = reversed[i - 1 - j];
     }
     return string(s);
 }


 /*****************************************************************************************
     owns: Returns a string composed of a particular wallet's NFTs

     @param owner: the address of the person being checked


     @return string: a sting in a json list of all the NFTs that are owned

 *****************************************************************************************/

 function owns(address owner) public view returns (string memory) {
   uint256 _j = 1;
   uint maxGap = reservedIDs + 100;
   uint gap=0;

   string memory message = "[";
   string memory empty = "[";

   while(gap < maxGap){
     if (_exists(_j)){
        gap=0;
        if(ownerOf(_j) == owner){

            if(keccak256(bytes(message)) != keccak256(bytes(empty))){
              message = string(abi.encodePacked(message, ", "));
            }
            else{
              message = string(abi.encodePacked(message, " "));
            }
            message = appendUintToString( message, _j);

        }
     }else{
          gap++;
      }
     _j++;
   }
   message = string(abi.encodePacked(message, " ]"));
   return message;
 }


 /*****************************************************************************************
     experiences: Returns a string composed of a particular wallet's NFTs and their corresponding experiences

     @param owner: the address of the person being checked


     @return string: a string in a key value pair for NFT IDs and their experiences

 *****************************************************************************************/

 function experiences(address owner) public view returns (string memory) {
   uint256 _j = 1;
   uint maxGap = reservedIDs + 100;
   uint gap=0;

   string memory message = "{";
   string memory empty = "{";

    while(gap < maxGap){
      if (_exists(_j)){
        gap=0;
        if(ownerOf(_j) == owner){

          if(keccak256(bytes(message)) != keccak256(bytes(empty))){
            message = string(abi.encodePacked(message, ", "));
          }
          else{
            message = string(abi.encodePacked(message, " "));
          }

         message = appendUintToString( message, _j);
         message = string(abi.encodePacked(message, ":"));
         message = appendUintToString( message, tokenEID(_j));

        }
      }else{
          gap++;
      }
     _j++;
   }
   message = string(abi.encodePacked(message, " }"));
   return message;
 }

 function tokenExperience(uint tokenId) external view returns (uint) {
    return EID[tokenId];
 }


 /*****************************************************************************************
     totalSupply: Returns the total supply of NFTs on the contract

     @return uint256: the number of NFTs in the contract

 *****************************************************************************************/
 function totalSupply() public view returns (uint256) {
   return supply;
 }

 /*****************************************************************************************
     totalExperiences: Returns the total number of NFT experiences on the contract
     @return uint256: the number of experiences
 *****************************************************************************************/
 function totalExperiences() public view returns (uint256) {
   uint maxGap = reservedIDs + 100;
   uint gap=0;
   uint i = 1;
   uint total = 0;
   while(gap < maxGap){
      if (bytes(tokenUri[i]).length!=0){
          total++;
          gap=0;
      }else{
          gap++;
        }
      i++;
   }
   return total;
 }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}