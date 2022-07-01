//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./Ownable.sol";

/// @title Mix Pix Art
/// @author VdSR

contract MixpixContract is IERC721, Ownable {

    uint256 public constant CREATION_LIMIT_GEN0 = 10;
    string public constant override name = "Pix";
    string public constant override symbol = "PIX";

    event Create(
        address owner, 
        uint256 pixId, 
        uint256 mumId, 
        uint256 dadId, 
        uint256 genes
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

    uint256 public gen0Counter;

    function getPix(uint256 _id)external view returns(
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

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;

        pixIndexToOwner [_tokenId] = _to;

        if (_from != address(0)){
            ownershipTokenCount[_from]--;
        }

        // Emit the transfer event.
        emit Transfer(_from, _to, _tokenId);
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return pixIndexToOwner[_tokenId] == _claimant;
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