// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";

/// @title MixPixArt (teste version)
/// @author VdSR

contract MyContract is IERC721, Ownable {

    uint256 public constant CREATION_LIMIT_GEN0 = 100;
    string public constant override name = "MyToken";
    string public constant override symbol = "TOKEN";

    bytes4 internal constant MAGIC_ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;


    event Create(
        address owner, 
        uint256 pixId, 
        uint256 indexed mumId, 
        uint256 indexed dadId, 
        uint256 indexed genes
    );

    struct Pix{
        uint256 genes;
        uint64 createTime;
        uint32 mumId;
        uint32 dadId;
        uint16 generation;
    }

    Pix [] pixies;

    mapping (uint256 => address) public pixIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;

    mapping(uint256 => address) public pixIndexToApproved;
    mapping (address => mapping (address =>bool)) private _operatorApprovals;

    uint256 public gen0Counter;

    function getPix(uint256 _id)public view returns(
        uint256 genes,
        uint256 createTime,
        uint256 mumId,
        uint256 dadId,
        uint256 generation
    )
    
    {
    Pix storage pix = pixies[_id];
    createTime = uint256(pix.createTime);
    mumId = uint256(pix.mumId);
    dadId = uint256(pix.dadId);
    generation = uint256(pix.generation);
    genes = pix.genes;
    }


    function createPixGen0(uint256 _genes) public onlyOwner returns (uint256){
        require(gen0Counter < CREATION_LIMIT_GEN0);

        gen0Counter++;

        //Gen0 have no owners they are own by the contract
        return _createPix(0, 0, 0, _genes, msg.sender);                
    }

    function mixPix(uint256 _dadId, uint256 _mumId) public returns (uint256){
        require(_owns(msg.sender, _dadId), "The user doesnt own the token");
        require(_owns(msg.sender, _mumId), "The user doesnt own the token");

        (uint256 dadDna,,,, uint256 DadGeneration) = getPix(_dadId);
        (uint256 mumDna,,,, uint256 MumGeneration) = getPix(_mumId);

        uint256 newDna = _mixDna(dadDna, mumDna);
        
        uint256 kidGen = 0;
        if(DadGeneration < MumGeneration){
            kidGen = MumGeneration +1;
            kidGen /= 2;
        }else if (DadGeneration > MumGeneration){
            kidGen = DadGeneration +1;
            kidGen /= 2;
        }else{
            kidGen = MumGeneration +1;
        }
        _createPix(_mumId, _dadId, kidGen, newDna, msg.sender);
    }

    function _createPix(
        uint256 _mumId,
        uint256 _dadId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    ) private returns (uint256){
        Pix memory _pix = Pix({
            genes: _genes,
            createTime: uint64(block.timestamp),
            mumId: uint32(_mumId),
            dadId: uint32(_dadId),
            generation: uint16(_generation)
        });
        
        pixies.push(_pix);
        uint256 newPixId = pixies.length -1;


        emit Create(_owner, newPixId, _mumId, _dadId, _genes);

        _transfer(address(0), _owner, newPixId);

        return newPixId;
    }


//standard functions of a ERC721 contract
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool){
        return ( _interfaceId == _INTERFACE_ID_ERC721 || _interfaceId == _INTERFACE_ID_ERC165);
    }

    function balanceOf(address owner) external view override returns (uint256 balance){
        return ownershipTokenCount[owner];
    }

    function totalSupply() public view override returns (uint){
        return pixies.length;
    }

    function ownerOf(uint256 _tokenId) external view override returns (address)
    {
        return pixIndexToOwner[_tokenId];
    }

    function transfer(address _to, uint256 _tokenId) external override
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from, _to, _tokenId);
    }

    function _safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) internal{
        _transfer(_from, _to, _tokenId);
        require(_checkERC721Support(_from, _to, _tokenId, _data));
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;

        pixIndexToOwner [_tokenId] = _to;

        if (_from != address(0)){
            ownershipTokenCount[_from]--;
            delete pixIndexToApproved[_tokenId];
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        _isApprovedOrOwner(msg.sender, _from, _to, _tokenId);
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public override{
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);
        emit Approval(msg.sender, _to, _tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override{
        require(operator != msg.sender);

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public override view returns (address){
        require(tokenId < pixies.length);

        return pixIndexToApproved[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool){
        return _operatorApprovals[owner][operator];
    }

    
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return pixIndexToOwner[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal{
        pixIndexToApproved[_tokenId] = _approved;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns(bool){
        return pixIndexToApproved[_tokenId] == _claimant;
    }

    function _checkERC721Support(
        address _from, 
        address _to, 
        uint256 _tokenId, 
        bytes memory _data) internal returns (bool){
            if(!_isContract(_to)){
            return true;
            }

            bytes4 returnData = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            return returnData == MAGIC_ERC721_RECEIVED;
        }

    function _isContract(address _to) view internal returns (bool){
            uint32 size;
            assembly{
                size := extcodesize(_to)
            }
            return size < 0;
    }
    
    function _isApprovedOrOwner(address _spender, address _from, address _to, uint256 _tokenId) internal view returns (bool) {
        require(_tokenId < pixies.length);
        require(_to != address(0));
        require(_owns(_from, _tokenId));

        return(_spender == _from) || _approvedFor(_spender, _tokenId) || isApprovedForAll(_from, _spender);
    }

    function _mixDna(uint256 _dadDna, uint256 _mumDna) public pure returns (uint256){
        //dadDna: 1111121213121312121
        //mumDna: 1199887766554433221
        
        //10 + 20 = 1020
        //10 * 100 = 1000
        //1000+20 = 1020 

        uint256 firstHalf = _dadDna / 1000000000; //result 11 11 12 12 13
        uint256 secondHalf= _mumDna % 100000000;  //result 554433221

        uint256 newDna = firstHalf * 1000000000; // reult 11 11 12 12 13
        newDna = newDna + secondHalf; //result 11 11 12 12 13 55 44 33 22 1
        return newDna;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
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

    /*
     * @dev Returns the total number of tokens in circulation.
     */
    function totalSupply() external view returns (uint256 total);

    /*
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory tokenName);

    /*
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory tokenSymbol);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);


     /* @dev Transfers `tokenId` token from `msg.sender` to `to`.
     *
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `to` can not be the contract address.
     * - `tokenId` token must be owned by `msg.sender`.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.7;

import "./Context.sol";

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

pragma solidity ^0.8.7;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.7;

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