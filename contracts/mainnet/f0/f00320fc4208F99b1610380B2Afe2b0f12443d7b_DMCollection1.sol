//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import './DMAddressable.sol';
import './DMLinkable.sol';
import './interfaces/IDMHelpers.sol';

interface IDMCollection {
    function onCompose(address from, address to, address collection, uint256 tokenId) external returns (bytes4);
    function ownerOf(uint256 tokenId) external returns (address);
    function compose(bytes32 tokenHash, address sourceCollection, uint256 sourceTokenId) external returns (bool);
}
// import "hardhat/console.sol";
//import "@openzeppelin/contracts/utils/Strings.sol"; 
//import "@openzeppelin/contracts/utils/Address.sol"; 
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import 'base64-sol/base64.sol';
//contract DMCollection is Context, ERC165, IERC721, IERC721Enumerable, DMAddressable, DMLinkable {
contract DMCollection1 is Context, ERC165, IERC721, DMAddressable, DMLinkable {
    using Address for address;
    using Counters for Counters.Counter;
    
    address payable public contractOwner;
    address payable public contractMinter;
    // Token name
    string public name;
    // Token symbol
    string public symbol;
    // Metadata location on swarm
    bytes32 public collectionMetadataLocation; 
    
    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;
    // Mapping owner address to token count
    mapping (address => uint256) private _balances;
    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    // Mapping from tokenId to swarm location 
    mapping (uint256 => bytes32) internal _tokenDataLocation;
    mapping (uint256 => bytes32) internal _metadataLocation; 
    mapping (uint256 => address) internal _tokenCreator;
    mapping (uint256 => uint256) internal _tokenAmount;
    mapping (uint256 => bytes32) internal _tokenName;

    uint256[] public _tokenTemplates; // once template exists collection can mint only copies of templates
    // Mapping from swarmLocation to tokenId, data hash to tokenId
    mapping (bytes32 => uint256) internal tokenDataToToken;  
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;  
    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;
    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _ownedTokensIndex;
    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;   

    Counters.Counter private _tokenIdTracker;  
    
    bool public nonTransferable = false;
    uint public finiteCount = 0; // if 0=no finite count, else this defines how many one address can mint 

    /* @dev only minter can set params of collection*/
    function setCollectionParams(bool isNotTransferable, uint isFiniteCount) public {
        require(msg.sender==contractMinter,"!o!m");
        nonTransferable = isNotTransferable;
        finiteCount = isFiniteCount;
    }
    
    /* @dev Initializes the contract by setting a `name` and a `symbol` to the token collection. */ 
    constructor (string memory name_, string memory symbol_, IDMHelpers _helpers) DMAddressable(_helpers) payable { // payable ? 
        name = name_;
        symbol = symbol_;
        contractOwner = payable(msg.sender);
        contractMinter = payable(address(0)); //payable(msg.sender);// payable(msg.sender);
        _tokenIdTracker.increment(); // we start at 1 
    } 
    /* @dev See {IERC721Metadata-name}. */
    /*function name() public view virtual override returns (string memory) {
        return _name; 
    }*/ 
    /* @dev See {IERC721Metadata-symbol}. */
    /*function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }*/ 
    /* @dev returns totalSupply of NFT tokens */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length; 
    }

    /*function getOwner() public view returns (address) {
        return contractOwner;
    }*/ 
    /*function getMinter() public view returns (address) {
        return contractMinter; 
    }*/
    /*function getMetadata() public view returns (bytes32)
    {
        return collectionMetadataLocation;
    }*/ 
    /* @dev Sets new owner and receiver of funds got from creating new tokens */
    function setOwner(address newOwner) public {
        require(msg.sender==contractOwner,"!o");
        contractOwner = payable(newOwner);
    }
    /* @dev who can mint new NFTS */
    function setMinter(address newMinter) public {
        if(contractMinter==address(0)) 
        {
           contractMinter = payable(newMinter); 
           return; 
        } 

        require(msg.sender==contractOwner && msg.sender==contractMinter,"!o!m");
        contractMinter = payable(newMinter);   
    }
    function setMetadata(bytes32 newCollectionMetadataSwarmLocation) public
    {
        require(msg.sender==contractOwner || msg.sender==contractMinter,"!o");
        collectionMetadataLocation = newCollectionMetadataSwarmLocation;
    } 
    
    /* @dev See {IERC165-supportsInterface}. */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId;
            //|| super.supportsInterface(interfaceId);
    }
    /* @dev See {IERC721-balanceOf}. */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "0");
        return _balances[owner];
    }
    /* @dev See {IERC721-ownerOf}. */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        require(_owners[tokenId] != address(0), "!e");
        return _owners[tokenId];
    } 
    function tokenOfData(bytes32 dataHash) public view virtual returns (uint256) {
        return tokenDataToToken[dataHash]; 
    }
    /* @dev get owner of token at index */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
      require(_index < balanceOf(_owner));
      return _ownedTokens[_owner][_index];
    }
    /* @dev See {IERC721Enumerable-tokenByIndex}.*/
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalSupply(), ">");
        return _allTokens[index];
    }    
    /* @dev who created token */
    function tokenCreator(uint256 tokenId) public view virtual returns (address) {
        require(_exists(tokenId), "!e");
        return _tokenCreator[tokenId]; 
    }
    /* @dev amount in token */
    function tokenAmount(uint256 tokenId) public view virtual returns (uint256) {
        require(_exists(tokenId), "!e");
        return _tokenAmount[tokenId];
    }
    /* @dev See {IERC721-approve}. */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "!2o");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),"c!o!a");

        _approve(to, tokenId);
    }
    /* @dev See {IERC721-getApproved}. */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "!e");

        return _tokenApprovals[tokenId];
    }
    /* @dev See {IERC721-setApprovalForAll}. */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "c!a"); // not approved

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    /* @dev See {IERC721-isApprovedForAll}. */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    /* @dev See {IERC721-transferFrom}. */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "c!o!a");
        _transfer(from, to, tokenId);
    }
    /* @dev See {IERC721-safeTransferFrom}. */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    /* @dev See {IERC721-safeTransferFrom}.*/
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "c!o!a");
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "2!R");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "!o");
        require(to != address(0), "0x?");
        require(nonTransferable==false,"!tx"); 
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId); // Clear approvals from the previous owner
       
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
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
        require(_exists(tokenId), "!e");
        address owner = ownerOf(tokenId);
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "2!R");
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
        require(to != address(0), "0x");
        require(!_exists(tokenId), "m"); // minted
        
        if(finiteCount>=1)
           require(_balances[to]<finiteCount, "2mch");  // limited how much address can have tokens from this collection
        
        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _tokenCreator[tokenId] = msg.sender;

        emit Transfer(address(0), to, tokenId);
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
        address owner = ownerOf(tokenId);
 
        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _balances[owner] -= 1;

        _tokenDataLocation[tokenId] = 0;
        _metadataLocation[tokenId] = 0;
        _tokenCreator[tokenId] = address(0);
        _tokenAmount[tokenId] = 0;   
        
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        //return true; // this is not 721
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("!ERC721");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    

    /*
function onERC721Received(address to, address collection, uint256 tokenId) private returns (bool)
    {
        // onCompose(from, to, address(this), tokenId);        
        if (to.isContract()) {
            try IDMCollection(to).onCompose(msg.sender, to, collection, tokenId) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("!DMCollection");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }    
    
     */

    

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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal  {

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    } 
    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */ 
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length; 
    }
    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }    
    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
     /** 
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     * 
     * - the caller must be contractOwner
     */
    /*function mint(address to) public virtual {
        require(to==contractMinter,"!f"); 
    }*/
    /**
     * @dev if funds received return back to sender  
    */
    receive () external payable  {  
       payable(msg.sender).transfer(msg.value);  // return funds back to sender 
    }


    /* @dev Base URI for computing {tokenURI}. Empty by default, can be overriden in child contracts.*/
    function metadata() internal view virtual returns (string memory) {
        return string(abi.encodePacked(helpers.bytes32string(collectionMetadataLocation)));
    }
    function _baseURI() internal view virtual returns (string memory) {
        return gateway;
    }
    string public gateway = "https://gateway.fairdatasociety.org/bzz/";
    function setGateway(string memory newGateway) public returns (string memory)  {
        require(msg.sender==contractOwner || msg.sender == contractMinter,"!o");
        gateway = newGateway;
        return gateway;
    }
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) 
    {
        require(_exists(tokenId), "!exist");
        return string(abi.encodePacked(_baseURI(), helpers.bytes32string(_tokenDataLocation[tokenId]),"/"));        
        //require(_exists(tokenId), "!e");

        // string memory baseURI = _baseURI();
        //return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, helpers.bytes32string(_tokenDataLocation[tokenId]),"/")) : "";

        //return string(abi.encodePacked('', baseURI, helpers.bytes32string(_tokenDataLocation[tokenId]),'/'));
        // return string(abi.encodePacked('', baseURI, _tokenDataLocation[tokenId],"/"));

        //require(_exists(tokenId), "!e");
        //return string(abi.encodePacked("swarm://", helpers.bytes32string(_tokenDataLocation[tokenId])));
    } 
    function setTokenName(uint256 tokenId, string memory name) public 
    {
        require(msg.sender==ownerOf(tokenId), "!o");
        _tokenName[tokenId] = helpers.stringToBytes32(name);
    } 
    /**
     * @dev adds addressable data to tokenId, with triples to,metadata,data
    */
    function addDataLocation(uint256 tokenId/*, address to/*, bytes32 metadataSwarmLocation*/, bytes32 tokenDataSwarmLocation) public {
        require(msg.sender==ownerOf(tokenId), "!o"); // not owner
        dataLocationAdd( tokenId/*,  to,  metadataSwarmLocation*/, tokenDataSwarmLocation); 
    }


    /* @dev See {IERC721Metadata-tokenURI}.*/
    function tokenData(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "!e");
        return string(abi.encodePacked('{ "m": "0x', helpers.bytes32string(_metadataLocation[tokenId]), // metadata
                                       '","d": "0x', helpers.bytes32string(_tokenDataLocation[tokenId]), // data
                                       '","n": "0x', helpers.bytes32string(_tokenName[tokenId]),  // name
                                       '","a": "',   helpers.uint2str(_tokenAmount[tokenId]),  // amount
                                       '","c": "0x', helpers.addressString(_tokenCreator[tokenId]),  // creator
                                       '","o": "0x', helpers.addressString(_owners[tokenId]), '"}'));  // owner
                                                     // return data pairs of all addresses for all tokenIds         
        // return string(
        //     abi.encodePacked(
        //         'data:application/json;base64,',
        //         Base64.encode(
        //             bytes(
        //                 abi.encodePacked(
        //                     '{"name":"', name, tokenName[tokenId], 
        //                     '", "description":"', description,
        //                     '","image_data":"data:image/svg+xml;base64,',
        //                     image,
        //                     '","image":"data:image/svg+xml;base64,', 
        //                     image,
        //                     attributes
        //                 )
        //             )
        //         )
        //     )
        // );
        // return json;
    }
    /* Get All addresses and their data tied to this to token*/
    /*function tokenAddressables(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked('{ "o":"', ownerOf(tokenId), 
                                       '","r": ', super.addressablesJSON(tokenId), '}'));
    }*/  

    function _baseMint(address to) internal returns (uint256)
    {
        require(msg.sender==contractMinter, "!m");
        uint256 tokenId = _tokenIdTracker.current(); 
        _mint(to,  tokenId);
        _tokenIdTracker.increment();
        return tokenId;
    }
  
    function templateAdd(address to, string memory tokenName, uint256 duplicationPrice) public returns (uint256)
    {
        require(msg.sender==contractMinter, "!m");
        uint256 tokenId = _baseMint(to);
        _tokenName[tokenId] = helpers.stringToBytes32(tokenName);
        _tokenAmount[tokenId] = duplicationPrice;
        _tokenTemplates.push(tokenId); // once template exists collection can mint only copies of templates
        return tokenId;
    } 

    function templateCreatable(address from, address to, string memory tokenName, uint256 duplicationPrice) public returns (uint256)
    {
        uint256 tokenId = templateAdd(to, tokenName, duplicationPrice);
        _tokenCreator[tokenId] = from;
    }

    function templateMint(address to, uint256 fromTokenId, uint256 paymentReceived) public
    {
        require(_tokenAmount[fromTokenId] >= paymentReceived, "!$");
        uint256 tokenId = _baseMint(to);
        _tokenName[tokenId] = _tokenName[fromTokenId];
        addLink(fromTokenId, tokenId, true);
        addLink(tokenId, fromTokenId, true);
    }
    
    function getTemplateIndices() public view returns (uint256[] memory)
    {
        return _tokenTemplates;
    }


    /* @dev contract can call and create new NFTs */
    function mintForUser(address creator, uint256 amount, address to, bytes32 metadataSwarmLocation, bytes32 tokenDataSwarmLocation) public
    {
        require(_tokenTemplates.length==0, "=t"); // this contract has templates, minting for user not allowed

        require(msg.sender==contractOwner || msg.sender==contractMinter, "!om");
        creteNewRefLocation(creator, amount, to, metadataSwarmLocation, tokenDataSwarmLocation);
    }

    /* token creator, 
       amount 
       metadata location
       data location
    */
    function creteNewRefLocation(address creator, uint256 amount, address to, bytes32 metadataSwarmLocation, bytes32 tokenDataSwarmLocation) internal {
        require(tokenDataToToken[tokenDataSwarmLocation]==0, "ex"); // should be never claimed before 
        // uint256 tokenId = uint256(keccak256(abi.encodePacked(msg.sender))); // maybe we want different Id
        uint256 tokenId = _tokenIdTracker.current(); 
        _mint(to, tokenId);
        _tokenIdTracker.increment();
        
        _tokenCreator[tokenId]  = creator; 
        _tokenAmount[tokenId]  = amount;
        _metadataLocation[tokenId]  = metadataSwarmLocation;
        _tokenDataLocation[tokenId] = tokenDataSwarmLocation;
    
        tokenDataToToken[tokenDataSwarmLocation] = tokenId;  // so same location can't be minted twice 
    }

    function getTokenHash(address nftCollection, uint256 tokenId) public pure returns (bytes32)
    {
        return  keccak256(abi.encodePacked(nftCollection,tokenId));
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    /// @title Composable DMCollection NFTs
    /// @author Tex
    /// @notice Composable interface for DMCollection, this is one way ticket, once composed, can't be decomposed 
    /// @dev Send sourceTokenId to another collection and bind it to whatTokenId 
    struct Composable { 
        address collection;  //
        uint256 tokenId;  //
    }
    mapping(bytes32 => Composable[]) public composed;

    function transferCompose(address from, uint256 sourceTokenId, address targetCollection, uint256 targetTokenId) external returns (bytes4) 
    {
      require(ownerOf(sourceTokenId) == msg.sender, "!o");
      //require(IDMCollection(toCollection).ownerOf(whatTokenId) == msg.sender, "2o");
      //require(toCollection.isContract(), "!c");

      _transfer(from, targetCollection, sourceTokenId);
      bytes32 tokenHash = getTokenHash(address(this),sourceTokenId); //getTokenHash(address(this),sourceTokenId);
      IDMCollection(targetCollection).compose(tokenHash, targetCollection, sourceTokenId); 
      //bytes32 tokenHash = getTokenHash(address(this),sourceTokenId); //getTokenHash(address(this),sourceTokenId);
      //composed[tokenHash].push(Composable(targetCollection, targetTokenId));
      return this.transferCompose.selector;
    }
    
    // TODO: needs checking to see that sourceCollection sourceTokenId is owned by msg.sender
    function compose(bytes32 tokenHash, address sourceCollection, uint256 sourceTokenId) external returns (bool) 
    {
      //require(IDMCollection(sourceCollection).ownerOf(sourceTokenId) == msg.sender, "2o");
      composed[tokenHash].push(Composable(sourceCollection, sourceTokenId));
      return true;
    }
    
    /*
    function onERC721Received(address operator, address to, uint256 tokenId, bytes memory _data) private returns (bool)
    {
        if (to.isContract()) {
            //try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("!ERC721Receiver");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }

       return onCompose(operator, to, to, tokenId);
    }*/ 
    /*    
    function _transferCompose(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        return onCompose(from, to, address(this), tokenId);
    }*/ 

    /*
    function decompose(address collection, uint256 tokenId, uint256 index) public {
      require(msg.sender == IERC721(collection).ownerOf(tokenId), "!owner");
      bytes32 tokenHash = getTokenHash(collection, tokenId);

       IERC721(composed[tokenHash][index].collection).transferFrom( // transfer from the collection
                 address(this), 
                 IERC721(collection).ownerOf(tokenId), // owner of
                 composed[tokenHash][index].tokenId);

      for (uint256 i = 0; i < composed[tokenHash].length; i++) {
             IERC721(composed[tokenHash][i].collection).transferFrom( // transfer from the collection
                 address(this), 
                 IERC721(collection).ownerOf(tokenId), // owner of
                 composed[tokenHash][i].tokenId);

      }
      delete composed[tokenHash];
    } */

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import './interfaces/IDMHelpers.sol';

contract DMAddressable {
    IDMHelpers helpers;
    // Mapping from address to location 
    //mapping (uint256 => address[]) internal _addressesWithData;
    //mapping (uint256 => mapping (address => bytes32)) internal _addressMetadata;
    //mapping (uint256 => mapping (address => bytes32)) internal _addressData;
    /* @dev See if address has access to data and get it's referenced data location */
    mapping (uint256 => bytes32[]) public dataLocations;

    constructor(IDMHelpers _helpers)
    {
       helpers = _helpers;
    }
    function dataLocationAdd(uint256 tokenId, bytes32 dataLocation) internal virtual {
        dataLocations[tokenId].push(dataLocation); //
    }
    function dataLocationCount(uint256 tokenId) public view returns (uint256) {
        return dataLocations[tokenId].length; //
    } 
    
    /*function addresables(uint256 tokenId) public view returns (bytes32[] memory) {
        return dataLocations[tokenId];
    }*/  
    /*
    function addressablesJSON(uint256 tokenId) internal virtual view returns (string memory) {
        string memory data = "";
        for(uint256 i=0;i<dataLocations[tokenId].length;i++)
           string(abi.encodePacked(data, '{ "d":"0x', helpers.bytes32string(dataLocations[tokenId][i]),  
                                         '"}',
                                         i<dataLocations[tokenId].length-1 ? ',' : ''
                                         )); // return data pairs of all addresses for all tokenIds 

        return string(abi.encodePacked('[',data,']')); // return json
    }*/

    /*
    function addresables(uint256 tokenId) public view returns (address[] memory) {
        return _addressesWithData[tokenId];
    }  
 
    // @dev creates a new reference with data for 'to' for metadata and data location 
    function addressablesAdd(uint256 tokenId, address to,  bytes32 tokenDataSwarmLocation) internal virtual {
        if(_addressData[tokenId][to]==0) // does not exist  
           _addressesWithData[tokenId].push(to); //

        // should minting be split between all addresses ? 
        _addressData[tokenId][to]  = tokenDataSwarmLocation;  
    }
    //* @dev returns array of data 
    function addressablesJSON(uint256 tokenId) internal virtual view returns (string memory) {
        string memory data = "";
        for(uint256 i=0;i<_addressesWithData[tokenId].length;i++)
           //string(abi.encodePacked(data, '{ "m":"0x', bytes32string(_addressMetadata[tokenId][_addressesWithData[tokenId][i]]), // metadata information
           string(abi.encodePacked(data, '{ "d":"0x', helpers.bytes32string(_addressData[tokenId][_addressesWithData[tokenId][i]]),  // data location 
                                         '" "a":"0x', helpers.addressString(_addressesWithData[tokenId][i]), // can be collection           
                                         '"}',
                                         i<_addressesWithData[tokenId].length-1 ? ',' : ''
                                         )); // return data pairs of all addresses for all tokenIds 

        return string(abi.encodePacked('[',data,']')); // return json
    }*/ 
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract DMLinkable {
    struct TokenLink {
        uint256  tokenId; // what id
        bool     approved; // is it approved
    }
  
    bool public collectionNeedApproval;
    //mapping (uint256 => bool) private _tokenNeedsOwnerApprovalToAddLinks;  // who
    //mapping (uint256 => TokenLink[]) private _tokenOrigin; // where do i come from 
    mapping (uint256 => TokenLink[]) private _tokenLinks;  // who
    /*
    function addOrigin(uint256 toTokenId, address fromCollection, uint256 tokenId, bool approved) internal
    {
        TokenLink memory rtl;
        rtl.collection = fromCollection;
        rtl.tokenId = tokenId;
        rtl.approved = approved;

        _tokenOrigin[toTokenId].push(rtl); // who is in your 
    }*/
    function addLink(uint256 toTokenId, uint256 tokenId, bool approved) internal
    {
        TokenLink memory rtl;
        //rtl.collection = fromCollection;
        rtl.tokenId = tokenId;
        rtl.approved = approved;

        _tokenLinks[toTokenId].push(rtl); // who is in your 
    }
    function getLinks(uint256 tokenId) public view returns (TokenLink[] memory)
    {
        return _tokenLinks[tokenId];
    }
}

pragma solidity >=0.8.0 <0.9.0;


interface IDMHelpers {
    function char(bytes1 b) external pure returns (bytes1 c);
    function stringToBytes32(string memory source) external pure returns (bytes32 result);
    function bytes32string(bytes32 b32) external pure returns (string memory out);
    function addressString(address x) external pure returns (string memory);
    function uint2str(uint _i) external pure returns (string memory _uintAsString);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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