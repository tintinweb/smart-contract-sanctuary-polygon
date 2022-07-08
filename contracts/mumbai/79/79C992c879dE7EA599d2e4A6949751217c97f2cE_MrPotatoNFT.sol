/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;
/*
Training data for machine learning.
*/
interface IERC165 {
function supportsInterface(bytes4 interfaceId) external view returns (bool);}
pragma solidity ^0.8.14;
interface IERC721 is IERC165 {
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
function balanceOf(address owner) external view returns (uint256 balance);
function ownerOf(uint256 tokenId) external view returns (address owner);
function safeTransferFrom(address from, address to, uint256 tokenId) external;
function transferFrom(address from, address to, uint256 tokenId) external;
function approve(address to, uint256 tokenId) external;
function getApproved(uint256 tokenId) external view returns (address operator);
function setApprovalForAll(address operator, bool _approved) external;
function isApprovedForAll(address owner, address operator) external view returns (bool);
function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;}
pragma solidity ^0.8.14;
interface IERC721Receiver {
function onERC721Received(address from, uint256 tokenId, bytes calldata data) external returns (bytes4);}
interface PotatoReceiver {
function onPotatoReceived(address from, uint256[] memory tokenIds) external payable;}
pragma solidity ^0.8.14;
interface IERC721Metadata is IERC721 {function name() external view returns (string memory);
function symbol() external view returns (string memory);function tokenURI(uint256 tokenId) external view returns (string memory);}
pragma solidity ^0.8.14;
interface IERC721Enumerable is IERC721 {function totalSupply() external view returns (uint256);
function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
function tokenByIndex(uint256 index) external view returns (uint256);}
pragma solidity ^0.8.14;
library Address {
function isContract(address account) internal view returns (bool) { uint256 size; assembly { size := extcodesize(account) } return size > 0;}
function sendValue(address payable recipient, uint256 amount) internal { require(address(this).balance >= amount, "Address: insufficient balance"); (bool success, ) = recipient.call{ value: amount }(""); require(success, "Address: unable to send value, recipient may have reverted");}
function functionCall(address target, bytes memory data) internal returns (bytes memory) {return functionCall(target, data, "Address: low-level call failed");}
function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {return functionCallWithValue(target, data, 0, errorMessage);}
function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {return functionCallWithValue(target, data, value, "Address: low-level call with value failed");}
function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {require(address(this).balance >= value, "Address: insufficient balance for call");require(isContract(target), "Address: call to non-contract");(bool success, bytes memory returndata) = target.call{ value: value }(data);return _verifyCallResult(success, returndata, errorMessage);}
function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {return functionStaticCall(target, data, "Address: low-level static call failed");}
function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory){require(isContract(target), "Address: static call to non-contract");(bool success, bytes memory returndata) = target.staticcall(data);return _verifyCallResult(success, returndata, errorMessage);}
function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {return functionDelegateCall(target, data, "Address: low-level delegate call failed");}
function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {require(isContract(target), "Address: delegate call to non-contract");(bool success, bytes memory returndata) = target.delegatecall(data);return _verifyCallResult(success, returndata, errorMessage);}
function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {if (success) {return returndata;} else {if (returndata.length > 0) {assembly {let returndata_size := mload(returndata)revert(add(32, returndata), returndata_size)}} else {revert(errorMessage);}}}}
pragma solidity ^0.8.14;
abstract contract Context {
function _msgSender() internal view virtual returns (address) {return msg.sender;}
function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}}
pragma solidity ^0.8.14;
library Strings {bytes16 private constant alphabet = "0123456789abcdef";
function toString(uint256 value) internal pure returns (string memory) {if (value == 0) {return "0";} uint256 temp = value;uint256 digits;while (temp != 0) {digits++;temp /= 10;}bytes memory buffer = new bytes(digits);while (value != 0) {digits -= 1;buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));value /= 10;}return string(buffer);}
function toHexString(uint256 value) internal pure returns (string memory) {if (value == 0) {return "0x00";}uint256 temp = value;uint256 length = 0;while (temp != 0) {length++;temp >>= 8;}return toHexString(value, length);}
function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {bytes memory buffer = new bytes(2 * length + 2);buffer[0] = "0";buffer[1] = "x";for (uint256 i = 2 * length + 1; i > 1; --i) {buffer[i] = alphabet[value & 0xf];value >>= 4;}require(value == 0, "Strings: hex length insufficient");return string(buffer);}}
pragma solidity ^0.8.14;
abstract contract ERC165 is IERC165 {
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {return interfaceId == type(IERC165).interfaceId;}}


/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
pragma solidity ^0.8.14;
contract MrPotatoNFT is Context, ERC165, IERC721, IERC721Metadata {

    address THIS = address(this);
    address contractOwner;
    mapping(address => bool) worker; 
    address mintingAddress;
    uint MAX_POTATO_COUNT = 8888888;

    constructor(){
        _name = "Mr Potato NFT";
        _symbol = "Potato NFT";
        contractOwner = msg.sender;
        setWorker(msg.sender);
    }
    
    uint public pieces;
    mapping(uint => string) public images;
    mapping(uint => string) public names;
    mapping(uint => uint) public metapoints;

    function totalSupply() public view returns(uint){
        return potatoes;   
    }

    uint public potatoes;
    mapping( uint => Potato ) potato;
    struct Potato {
        uint background;
        uint leftArm;
        uint rightArm;
        uint hat;
        uint ears;
        uint eyes;
        uint nose;
        uint mouth;
        uint shoes;
    }

    function newPiece(string memory image, string memory desc, uint meta) public{
        require(worker[msg.sender]);
        images[pieces] = image;
        names[pieces] = desc;
        metapoints[pieces] = meta;
        pieces += 1;
    }

    function newPieces(string[] memory image, string[] memory desc, uint[] memory meta) public {
        require(worker[msg.sender]);
        uint L = image.length;
        for(uint i; i<L; i+=1){
            images[pieces] = image[i];
            names[pieces] = desc[i];
            metapoints[pieces] = meta[i];
            pieces += 1;   
        }
    }

    function changeContractOwner(address newContractOwner) public{
        require( msg.sender == contractOwner );
        contractOwner = newContractOwner;
    }

    function setWorker(address workerAddress) public{
        require( msg.sender == contractOwner );
        worker[workerAddress] = true;
    }

    function fireWorker(address workerAddress) public{
        require( msg.sender == contractOwner );
        worker[workerAddress] = false;
    }
    
    event MintPotatoHead(address buyer, uint potatoID);
    function mintPotatoHead(
        address buyer,
        uint256 background,
        uint256 leftArm,
        uint256 rightArm,
        uint256 hat,
        uint256 ears,
        uint256 eyes,
        uint256 nose,
        uint256 mouth,
        uint256 shoes
    ) public{
        require(worker[msg.sender] && potatoes<MAX_POTATO_COUNT);
        Potato storage _potato = potato[potatoes];
        _potato.background = background;
        _potato.leftArm = leftArm;
        _potato.rightArm = rightArm;
        _potato.hat = hat;
        _potato.ears = ears;
        _potato.eyes = eyes;
        _potato.nose = nose;
        _potato.mouth = mouth;
        _potato.shoes = shoes;
        _mint(buyer,potatoes);
        emit MintPotatoHead(buyer,potatoes);
        potatoes +=1;
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
    event Mint(address to, uint tokenID);
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0));
        require(!_exists(tokenId));
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Mint(to, tokenId);
    }


    function getPotatoData(uint tokenId) public view returns(
        address owner,
        uint background,
        uint leftArm,
        uint rightArm,
        uint hat,
        uint ears,
        uint eyes,
        uint nose,
        uint mouth,
        uint shoes){
        owner = _owners[tokenId];
        Potato storage P = potato[tokenId];
        background = P.background;
        leftArm = P.leftArm;
        rightArm = P.rightArm;
        hat = P.hat;
        ears = P.ears;
        eyes = P.eyes;
        nose = P.nose;
        mouth = P.mouth;
        shoes = P.shoes;
    }
    
    function tokenURI(uint256 ID) public view virtual override returns (string memory) {
        require(_exists(ID), "ERC721Metadata: URI query for nonexistent token");

        return string( abi.encodePacked('data:text/json,{"name":"', constructName(ID) ,'","attributes":[', constructAttributes(ID) ,'],"description":"', constructDescription(ID) ,'","image":"data:image/svg+xml;base64,',constructSVG(ID),'"}' ) );
    }

    function constructName(uint ID) public view returns (string memory URI){
        return "Mr. Potato Head";
    }

    function constructDescription(uint ID) public view returns (string memory URI){
        return "Equipped with all different kinds of parts.";
    }

    function constructAttributes(uint ID) public view returns (string memory JSON){
        Potato storage P = potato[ID];
        string memory _2 = string( abi.encodePacked('"},{"trait_type":"Nose","value":"',names[P.nose],'"},{"trait_type":"Mouth","value":"',names[P.mouth],'"},{"trait_type":"Left Arm","value":"',names[P.leftArm],'"},{"trait_type":"Right Arm","value":"',names[P.rightArm]));
        string memory _1 = string( abi.encodePacked('{"trait_type":"Background","value":"',names[P.background],'"},{"trait_type":"Head","value":"',names[P.hat],'"},{"trait_type":"Ears","value":"',names[P.ears],'"},{"trait_type":"Eyes","value":"',names[P.eyes],_2));
        return string( abi.encodePacked(_1,'"},{"trait_type":"Shoes","value":"',names[P.shoes],'"},{"trait_type":"Nose","value":"',names[P.nose],'"}' ));
    }

    function constructSVG(uint ID) public view returns (string memory SVG){
        Potato storage P = potato[ID];
        string memory _2 = string( abi.encodePacked(images[P.leftArm],'" width="1080" height="1080"/><image href="',images[P.rightArm],'" width="1080" height="1080"/><image href="',images[P.shoes],'" width="1080" height="1080"/></svg>'));
        string memory _1 = string( abi.encodePacked('" width="1080" height="1080"/><image href="',images[P.eyes],'" width="1080" height="1080"/><image href="',images[P.nose],'" width="1080" height="1080"/><image href="',images[P.mouth],'" width="1080" height="1080"/><image href="',_2));
        return string( abi.encodePacked('<svg width="1080" height="1080" ><image href="',images[P.background],'" width="1080" height="1080"/><image href="https://ipfs.io/ipfs/QmZ563JsZTZf3jpASfBydjyinVXCfc2jMgd9RBRDVW6U8Z?filename=NSovUSok.png" width="1080" height="1080"/><image href="',images[P.hat],'" width="1080" height="1080"/><image href="',images[P.ears], _1 ));
    }

    // This is for the Potato Machine
    event PotatoTransfer(address from, address to, uint amount, uint[] potatoes);

    function potatoTransfer(address from, address to, uint256[] memory tokenIds) public payable {
        require( to.isContract() );

        uint L = tokenIds.length;
        for (uint i; i<L; i+=1){
            require(_isApprovedOrOwner(_msgSender(), tokenIds[i]), "ERC721: transfer caller is not owner nor approved");
            _transfer(from, to, tokenIds[i]);
        }        
        PotatoReceiver(to).onPotatoReceived{value: msg.value}(from, tokenIds);
        
        emit PotatoTransfer(from, to, L, tokenIds);
    }

    function transferFrom(address from, address to, uint256[] memory tokenIds) public {
        uint L = tokenIds.length;
        for (uint i;i<L;i+=1){
            require(_isApprovedOrOwner(_msgSender(), tokenIds[i]), "ERC721: transfer caller is not owner nor approved");
            _transfer(from, to, tokenIds[i]);
        }
        emit PotatoTransfer(from, to, L, tokenIds);
    }
    
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/

    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/

    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/

    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
        uint[] memory tokenIds = new uint[](1);
        tokenIds[0] = tokenId;
        emit PotatoTransfer(from, to, 1, tokenIds);
    }
    

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

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
        emit Approval(ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            IERC721Receiver(to).onERC721Received(from, tokenId, _data);
        }
        return true;
    }
}