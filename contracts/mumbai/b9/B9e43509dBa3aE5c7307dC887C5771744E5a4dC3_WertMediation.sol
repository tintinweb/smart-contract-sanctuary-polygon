// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../includes/access/Ownable.sol";
import "../includes/interfaces/IERC721Receiver.sol";

enum PaymentMethod { BNB, BEP20 }
enum SaleType { DIRECT, OFFER, BOTH }
enum SaleState { OPEN, CLOSED }

interface INft {
    function totalSupply() external view returns (uint);
    function ownerOf(uint _tokenId)external view returns (address);
    function balanceOf(address _owner) external view returns(uint);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface IMintingService {
    function listings(uint _id) external view returns (address, address);
    function mintBnb(uint256 _id) external payable;
    function mintMultiBnb(uint256 _id, uint256 _quantity) external payable;
    function getListing(uint _id) external view returns (MintListing memory);
}

interface IMarket {
    function listings(uint _id) external view returns (address, address, address, uint, uint, uint);
    function directBuyBnb(uint _listing, address[] memory _discountAddresses) external payable;
}

struct MintListing {
    address owner;
    address nft;     
    address paymentToken;
    uint256 price;
    uint256 sales;
    uint256 maxSales;
    uint256 endDate;
    uint256 maxQuantity;
    uint256 discount;
    bool selectable;
    bool whitelisted;
    bool ended;
    bool usesReviveRug;
    address[] treasuryAddresses;
    uint256[] treasuryAllocations;
}

struct MarketListing {
    address owner;
    address paymentToken;
    address nft;
    uint targetPrice;
    uint minimumPrice;
    uint tokenId;
    uint saleEnd;
    uint graceEnd;
    uint createBlock;
    uint closedBlock;
    PaymentMethod paymentMethod;
    SaleType saleType;
    SaleState saleState;
}

contract WertMediation is Ownable, IERC721Receiver {
    IMintingService public mintingService;
    IMarket public market;

    constructor(address _mintingService, address _market) {
        mintingService = IMintingService(_mintingService);
        market = IMarket(_market);
    }

    function onERC721Received(address, address, uint256, bytes calldata) public override pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setMintingService(address _mintingService) public onlyOwner() {
        mintingService = IMintingService(_mintingService);
    }

    function setMarket(address _market) public onlyOwner() {
        market = IMarket(_market);
    }

    function mintBnb(address _recipient, uint _listingId) public payable {
        address nft;
        (,nft) = mintingService.listings(_listingId);     
        mintingService.mintBnb{ value: msg.value }(_listingId);        
        _transferMintedNfts(_recipient, nft);
    }

    function mintMultiBnb(address _recipient, uint _listingId, uint _quantity) public payable {
        address nft;
        (,nft) = mintingService.listings(_listingId);    
        mintingService.mintMultiBnb{ value: msg.value }(_listingId, _quantity);
        _transferMintedNfts(_recipient, nft);
    }

    function directBuyBnb(address _recipient, uint _listingId, address[] memory _discountAddresses) public payable {
        address nftAddress;
        uint tokenId;
        (,,nftAddress,,,tokenId) = market.listings(_listingId);
        market.directBuyBnb{ value: msg.value }(_listingId, _discountAddresses);
        INft nft = INft(nftAddress);
        nft.transferFrom(address(this), _recipient, tokenId);
    }

    function _transferMintedNfts(address _recipient, address _contract) private {
        uint[] memory ids = _checkOwnership(_contract);
        INft nft = INft(_contract);

        for (uint index = 0; index < ids.length; index++) 
            nft.transferFrom(address(this), _recipient, ids[index]);
    }

    function _checkOwnership(address _contractAddress) private view returns (uint[] memory){
        INft nft = INft(_contractAddress);
        uint balance = nft.balanceOf(address(this));        
        uint[] memory ids = new uint[](balance);
        uint idIndex = nft.totalSupply();
        uint insertIndex = 0;

        while (insertIndex < balance) {
            if (nft.ownerOf(idIndex) == address(this)) {
                ids[insertIndex] = idIndex;
                insertIndex++;
            }

            idIndex--;
        }
        
        return ids;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
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

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}