//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NakshNFT.sol";
import "./Structs.sol";

contract NakshMarketplace is Ownable, ERC721Holder {
    address payable public Naksh_org;

    SaleData[] internal OnSaleNFTs;

    uint256 constant FLOAT_HANDLER_TEN_4 = 10000;

    mapping(address => mapping(uint256 => SaleData)) public saleData;

    event SalePriceSet(
        address _nft,
        uint256 _tokenId,
        uint256 _price,
        bool tokenFirstSale,
        saleType saletype
    );
    event Sold(
        address _nft,
        address _buyer,
        address _seller,
        uint256 _amount,
        uint256 _tokenId,
        uint256 timestamp
    );
    event StartedAuction(
        address _nft,
        uint256 startTime,
        uint256 endTime,
        uint256 tokenId,
        address owner,
        uint256 price
    );
    event EndedAuction(
        address _nft,
        uint256 _tokenId,
        address _buyer,
        uint256 highestBID,
        uint256 timestamp
    );
    event Bidding(
        address _nft,
        uint256 _tokenId,
        address _bidder,
        uint256 _amount,
        uint256 timestamp
    );

    /**
     * Modifier to allow only owners of a token to perform certain actions
     */
    modifier onlyOwnerOf(address _nftAddress, uint256 _tokenId) {
        require(IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
     * @dev Organisation address can be updated to another address in case of attack or compromise(`newOrg`)
     * Can be done only by the contract owner.
     */
    function changeOrgAddress(address _newOrg) public onlyOwner {
        require(
            _newOrg != address(0),
            "New organization cannot be zero address"
        );
        Naksh_org = payable(_newOrg);
    }

    // function MintAndSetSaleByAdmin(address _nft, address _creator, string memory _tokenURI, string memory title,
    // string memory description, string memory artistName, uint256 price) public {
    //     NakshNFT(_nft).mintByAdmin(_creator, _tokenURI, title, description, artistName);

    // }

    /**
     * This function is used to set an NFT on sale.
     * @dev The sale price set in this function will be used to perform the sale transaction
     * once the buyer wants to buy an NFT.
     */
    function setSale(
        address _nft,
        uint256 _tokenId,
        uint256 price
    ) public onlyOwnerOf(_nft, _tokenId) {
        require(
            saleData[_nft][_tokenId].isOnSale == false,
            "NFT is already on sale"
        );
        address tOwner = IERC721(_nft).ownerOf(_tokenId);
        require(tOwner != address(0), "setSale: nonexistent token");

        IERC721(_nft).safeTransferFrom(msg.sender, address(this), _tokenId);
        saleData[_nft][_tokenId].nft = NakshNFT(_nft).getNFTData(_tokenId);
        saleData[_nft][_tokenId].isOnSale = true;
        saleData[_nft][_tokenId].salePrice = price;
        saleData[_nft][_tokenId].saletype = saleType.DirectSale;
        OnSaleNFTs.push(saleData[_nft][_tokenId]);
        emit SalePriceSet(
            _nft,
            _tokenId,
            price,
            saleData[_nft][_tokenId].tokenFirstSale,
            saleData[_nft][_tokenId].saletype
        );
    }

    function getNFTonSale() public view returns (SaleData[] memory) {
        return OnSaleNFTs;
    }

    function updateSaleData(address _nftAddress, uint256 _tokenId) internal {
        uint256 leng = OnSaleNFTs.length;

        for (uint256 i = 0; i < leng; ) {
            if (
                OnSaleNFTs[i].nft.nftAddress == _nftAddress &&
                OnSaleNFTs[i].nft.tokenId == _tokenId
            ) {
                delete OnSaleNFTs[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function getSaleData(address _nft, uint256 _tokenId)
        external
        view
        returns (SaleData memory)
    {
        require(
            saleData[_nft][_tokenId].isOnSale == true,
            "NFT is not on sale"
        );
        return saleData[_nft][_tokenId];
    }

    function cancelSale(address _nft, uint256 _tokenId)
        public
        onlyOwnerOf(_nft, _tokenId)
    {
        require(
            saleData[_nft][_tokenId].isOnSale == true,
            "NFT is not on sale"
        );
        IERC721(_nft).safeTransferFrom(address(this), msg.sender, _tokenId);
        delete saleData[_nft][_tokenId];
        updateSaleData(_nft, _tokenId);
    }

    /**
     * This function is used to buy an NFT which is on sale.
     */
    function buyTokenOnSale(uint256 _tokenId, address _nftAddress)
        public
        payable
    {
        NakshNFT _nft = NakshNFT(_nftAddress);
        uint256 price = saleData[_nftAddress][_tokenId].salePrice;
        uint256 sellerFees = _nft.getSellerFee();
        uint16[] memory creatorRoyalty = _nft.getCreatorFees();
        uint256 totalCreatorFees = _nft.getTotalCreatorFees();
        uint256 platformFees = _nft.orgFee();

        require(price != 0, "buyToken: price equals 0");
        require(msg.value >= price, "buyToken: price doesn't equal salePrice");
        address tOwner = saleData[_nftAddress][_tokenId]
            .nft
            .artist
            .artistAddress;

        IERC721(_nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );

        if (saleData[_nftAddress][_tokenId].tokenFirstSale == false) {
            platformFees = _nft.orgFeeInitial();
            sellerFees = _nft.sellerFeeInitial();
            // No creator royalty/royalties when artist is minting for the first time
            totalCreatorFees = 0;

            saleData[_nftAddress][_tokenId].tokenFirstSale = true;
        }

        //Dividing by 100*100 as all values are multiplied by 100
        uint256 toSeller = (msg.value * sellerFees) / FLOAT_HANDLER_TEN_4;

        uint256 toPlatform = (msg.value * platformFees) / FLOAT_HANDLER_TEN_4;

        payable(tOwner).transfer(toSeller);

        if (totalCreatorFees != 0) {
            splitCreatorRoyalty(address(_nft), creatorRoyalty);
        }

        Naksh_org.transfer(toPlatform);

        delete saleData[_nftAddress][_tokenId];
        updateSaleData(_nftAddress, _tokenId);

        emit Sold(
            _nftAddress,
            msg.sender,
            tOwner,
            msg.value,
            _tokenId,
            block.timestamp
        );
    }

    function splitCreatorRoyalty(
        address _nftAddress,
        uint16[] memory creatorRoyalty
    ) internal {
        NakshNFT _nft = NakshNFT(_nftAddress);
        uint256 _TotalSplits = _nft.TotalSplits();
        uint256[] memory toCreators;
        for (uint8 i = 0; i < _TotalSplits; ) {
            toCreators[i] =
                (msg.value * creatorRoyalty[i]) /
                FLOAT_HANDLER_TEN_4;
            payable(_nft.creators(i)).transfer(toCreators[i]);
        }
    }

    /**
     * This is a getter function to get the current price of an NFT.
     */
    function getSalePrice(address _nft, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        require(
            saleData[_nft][_tokenId].isOnSale == true,
            "NFT is not on Sale"
        );
        return saleData[_nft][_tokenId].salePrice;
    }

    /**
     * This function is used to change the price of a token
     * @notice Only token owner is allowed to change the price of a token
     */
    function changePrice(
        address _nft,
        uint256 _tokenId,
        uint256 price
    ) public onlyOwnerOf(_nft, _tokenId) {
        require(
            saleData[_nft][_tokenId].isOnSale == true,
            "NFT is not on sale"
        );
        require(
            price > 0,
            "changePrice: Price cannot be changed to less than 0"
        );
        saleData[_nft][_tokenId].salePrice = price;
    }

    /**
     * This function is used to check if it is the first sale of a token
     * on the Naksh marketplace.
     */
    function isTokenFirstSale(address _nftAddress, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return saleData[_nftAddress][_tokenId].tokenFirstSale;
    }

    NFTAuction[] auctionedNFTs;

    bidHistory[] previousBids;

    mapping(address => mapping(uint256 => NFTAuction)) public auctionData;

    mapping(address => mapping(uint256 => bidHistory[])) public prevBidData;
    mapping(address => uint256) internal bids;

    function startAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _auctionTime
    ) external onlyOwnerOf(_nftAddress, _tokenId) returns (bool) {
        require(
            saleData[_nftAddress][_tokenId].isOnSale == false,
            "NFT is already on sale"
        );
        uint256 _startTime = block.timestamp;

        IERC721(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        uint256 _endTime = block.timestamp + _auctionTime;

        NFTAuction memory nftAuction = NFTAuction(
            _startTime,
            _endTime,
            _tokenId,
            msg.sender,
            _price,
            0,
            address(0)
        );
        auctionData[_nftAddress][_tokenId] = nftAuction;
        auctionedNFTs.push(nftAuction);

        saleData[_nftAddress][_tokenId].nft = NakshNFT(_nftAddress).getNFTData(
            _tokenId
        );
        saleData[_nftAddress][_tokenId].isOnSale = true;
        saleData[_nftAddress][_tokenId].salePrice = _price;
        saleData[_nftAddress][_tokenId].saletype = saleType.Auction;
        OnSaleNFTs.push(saleData[_nftAddress][_tokenId]);

        emit StartedAuction(
            _nftAddress,
            _startTime,
            _endTime,
            _tokenId,
            msg.sender,
            _price
        );

        return true;
    }

    function bid(address _nftAddress, uint256 _tokenId)
        external
        payable
        returns (bool)
    {
        NFTAuction storage nftAuction = auctionData[_nftAddress][_tokenId];

        require(nftAuction.endTime >= block.timestamp, "Auction has ended");
        require(nftAuction.price <= msg.value, "Pay more than base price");
        require(
            nftAuction.highestBid <= msg.value,
            "Pay more than highest bid"
        );

        if (nftAuction.highestBidder == address(0)) {
            nftAuction.highestBidder = msg.sender;
            nftAuction.highestBid = msg.value;
            bidHistory memory addBid = bidHistory(
                msg.sender,
                msg.value,
                block.timestamp
            );
            prevBidData[_nftAddress][_tokenId].push(addBid);
        } else {
            payable(nftAuction.highestBidder).transfer(nftAuction.highestBid);
            nftAuction.highestBid = msg.value;
            nftAuction.highestBidder = msg.sender;
            bidHistory memory addBid = bidHistory(
                msg.sender,
                msg.value,
                block.timestamp
            );
            prevBidData[_nftAddress][_tokenId].push(addBid);
        }

        emit Bidding(
            _nftAddress,
            _tokenId,
            msg.sender,
            msg.value,
            block.timestamp
        );
        return true;
    }

    function getBidHistory(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (bidHistory[] memory)
    {
        return prevBidData[_nftAddress][_tokenId];
    }

    function endAuction(address _nftAddress, uint256 _tokenId) external {
        NFTAuction storage nftAuction = auctionData[_nftAddress][_tokenId];

        require(
            nftAuction.owner == msg.sender ||
                nftAuction.highestBidder == msg.sender,
            "Only owner of nft can call this"
        );

        require(
            nftAuction.owner == msg.sender ||
                nftAuction.endTime <= block.timestamp,
            "Auction has not yet ended"
        );

        if (nftAuction.highestBidder != address(0)) {
            payable(msg.sender).transfer(nftAuction.highestBid);

            IERC721(_nftAddress).safeTransferFrom(
                address(this),
                nftAuction.highestBidder,
                _tokenId
            );
        } else {
            IERC721(_nftAddress).safeTransferFrom(
                address(this),
                msg.sender,
                _tokenId
            );
        }

        delete saleData[_nftAddress][_tokenId];
        updateSaleData(_nftAddress, _tokenId);

        emit EndedAuction(
            _nftAddress,
            _tokenId,
            nftAuction.highestBidder,
            nftAuction.highestBid,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.10;

/**
 * @title An NFT Marketplace contract for Naksh NFTs
 * @notice This is the Naksh Marketplace contract for Minting NFTs and Direct Sale + Auction.
 * @dev Most function calls are currently implemented with access control
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Structs.sol";

/*
 * This is the Naksh Marketplace contract for Minting NFTs and Direct Sale + Auction.
 */
contract NakshNFT is ERC721URIStorage {
    // using SafeMath for uint256;
    mapping(address => bool) public creatorWhitelist;
    mapping(uint256 => address) private tokenOwner;
    mapping(address => uint256[]) private creatorTokens;
    mapping(address => CollectionDetails) private collectionData;

    mapping(uint256 => NFTData) public nftData;
    mapping(address => artistDetails) artistData;

    event WhitelistCreator(address _creator);
    event DelistCreator(address _creator);
    event OwnershipGranted(address newOwner);
    event OwnershipTransferred(address oldOwner, address newOwner);
    event Mint(
        address creator,
        uint256 tokenId,
        string tokenURI,
        string title,
        string description
    );

    uint256 constant FLOAT_HANDLER_TEN_4 = 10000;

    address public owner;
    address _grantedOwner;
    address public admin;
    uint256 public sellerFee;
    uint256 public orgFee;
    uint16[] public creatorFees;
    uint256 public totalCreatorFees;
    address payable[] public creators;
    uint256 public TotalSplits = creators.length;
    uint256 public sellerFeeInitial;
    uint256 public orgFeeInitial;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    NFTData[] mintedNfts;

    /**
     * Modifier to allow only minters to mint
     */
    modifier onlyArtist() virtual {
        require(creatorWhitelist[msg.sender] == true);
        _;
    }

    modifier onlyArtistOrAdmin() virtual {
        require(creatorWhitelist[msg.sender] == true || msg.sender == admin);
        _;
    }

    /**
     * Modifier to allow only owner of the contract to perform certain actions
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * Modifier to allow only admin of the organization to perform certain actions
     */
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor(
        artistDetails memory artist,
        CollectionDetails memory collection,
        address _owner,
        address payable _admin,
        uint16[] memory _creatorFees,
        address payable[] memory _creators,
        uint256 _totalCreatorFees
    ) ERC721(collection.name, collection.symbol) {
        artistData[artist.artistAddress] = artist;
        creatorWhitelist[artist.artistAddress] = true;
        collectionData[address(this)] = collection;
        owner = _owner;
        admin = _admin;
        //Multiply all the three % variables by 100, to kepe it uniform
        orgFee = 500;
        creatorFees = _creatorFees;
        creators = _creators;
        totalCreatorFees = _totalCreatorFees;
        sellerFee = 10000 - orgFee - totalCreatorFees;
        // Fees for first sale only
        orgFeeInitial = 500;
        sellerFeeInitial = 10000 - orgFeeInitial;
    }

    /**
     * @dev Owner can transfer the ownership of the contract to a new account (`_grantedOwner`).
     * Can only be called by the current owner.
     */
    function grantContractOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit OwnershipGranted(newOwner);
        _grantedOwner = newOwner;
    }

    function getCollectionDetails()
        external
        view
        returns (CollectionDetails memory)
    {
        return collectionData[address(this)];
    }

    /**
     * @dev Claims granted ownership of the contract for a new account (`_grantedOwner`).
     * Can only be called by the currently granted owner.
     */
    function claimContractOwnership() public virtual {
        require(
            _grantedOwner == msg.sender,
            "Ownable: caller is not the granted owner"
        );
        emit OwnershipTransferred(owner, _grantedOwner);
        owner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /**
     *@dev Current admin can transfer admin rights to a new account.
     */
    function grantAdminRights(address newAdmin) public virtual onlyAdmin {
        require(newAdmin != address(0));
        admin = newAdmin;
    }

    function fetchArtist(address _artist)
        public
        view
        returns (artistDetails memory)
    {
        require(_artist != address(0));
        require(
            creatorWhitelist[_artist] == true,
            "Given address is not artist"
        );
        return artistData[_artist];
    }

    /** @dev Calculate the royalty distribution for organisation/platform and the
     * creator/artist.
     * Each of the organisation, creator royalty and the parent organsation fees
     * are set in this function.
     * The 'sellerFee' indicates the final amount to be sent to the seller.
     */
    // function setRoyaltyPercentage(uint256 _orgFee, uint16[] memory _creatorFees)
    //     public
    //     onlyOwner
    //     returns (bool)
    // {
    //     uint256 _totalCreatorFees;
    //     uint256 _length = _creatorFees.length;
    //     for (uint8 i; i < _length; ) {
    //         _totalCreatorFees += _creatorFees[i];
    //         unchecked {
    //             ++i;
    //         }
    //     }
    //     //Sum of org fee and creator fee should be 100%
    //     require(10000 > _orgFee + _totalCreatorFees, "Sum should be 100%");
    //     orgFee = _orgFee;
    //     creatorFees = _creatorFees;
    //     totalCreatorFees = _totalCreatorFees;
    //     sellerFee = 10000 - orgFee - totalCreatorFees;
    //     return true;
    // }

    /** @dev Calculate the royalty distribution for organisation/platform and the
     * creator/artist(who would be the seller) on the first sale.
     * The first iteration of whitepaper has the following stats:
     * orgFee = 5%
     * artist royalty/creator fee = 0%
     * The above numbers can be updated later by the DAO
     * @notice _creatorFeeInitial should be sellerFeeInitial - seller fees on first sale
     */
    function setRoyaltyPercentageFirstSale(
        uint256 _orgFeeInitial,
        uint256 _creatorFeeInitial
    ) public onlyOwner returns (bool) {
        orgFeeInitial = _orgFeeInitial;
        sellerFeeInitial = _creatorFeeInitial;
        return true;
    }

    /** @dev Return all the royalties including first sale and subsequent sale values
     * orgFee - % of fees that would go to the org from the total royalty
     * creatorRoyalty - % of fees that would go to the artist/creator
     * orgInitialRoyalty - % of fees that would go to the organisation on first sale
     * sellerFeeInitial - % of fees for seller on the first sale
     */
    function getRoyalties()
        public
        view
        returns (
            uint256 _orgFee,
            uint256 _creatorRoyalty,
            uint256 _orgInitialRoyalty,
            uint256 _sellerFeeInitial
        )
    {
        return (orgFee, totalCreatorFees, orgFeeInitial, sellerFeeInitial);
    }

    /**
     * @dev This function is used to get the seller percentage.
     * This refers to the amount of money that would be distributed to the seller
     * after the reduction of royalty and platform fees.
     * The values are multipleied by 100, in order to work easily
     * with floating point percentages.
     */
    function getSellerFee() public view returns (uint256) {
        //Returning % multiplied by 100 to keep it uniform across contract
        return sellerFee;
    }

    function getTotalCreatorFees() public view returns (uint256) {
        return totalCreatorFees;
    }

    function getCreatorFees() public view returns (uint16[] memory) {
        return creatorFees;
    }

    function getNFTData(uint256 _tokenId) public view returns (NFTData memory) {
        return nftData[_tokenId];
    }

    /**
     * This function is used to mint an NFT for the Naksh marketplace.
     * @dev The basic information related to the NFT needs to be passeed to this function,
     * in order to store it on chain to avoid disputes in future.
     */
    function mintByArtistOrAdmin(
        address _creator,
        string memory _tokenURI,
        string memory title,
        string memory description,
        string memory artistName
    ) public returns (uint256 _tokenId) {
        minter mintedBy;
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        tokenOwner[tokenId] = _creator;

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"title": "',
                        title,
                        '", "description": "',
                        description,
                        '", "image": "',
                        _tokenURI,
                        '", "artist name": "',
                        artistName,
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        _mint(_creator, tokenId);
        _setTokenURI(tokenId, finalTokenUri);

        if (msg.sender == admin) {
            mintedBy = minter.Admin;
        } else {
            mintedBy = minter.Artist;
        }

        NFTData memory nftNew = NFTData(
            address(this),
            tokenId,
            _tokenURI,
            title,
            description,
            artistData[_creator],
            mintedBy
        );
        nftData[tokenId] = nftNew;
        mintedNfts.push(nftNew);

        creatorTokens[_creator].push(tokenId);
        emit Mint(_creator, tokenId, _tokenURI, title, description);
        return tokenId;
    }

    /**
     * This returns the total number of NFTs minted on the platform
     */
    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }

    /**
     *This function is used to burn NFT, only Admin is allowed
     */
    function burn(uint256 tokenId) public onlyAdmin {
        _burn(tokenId);
    }

    /**
     *This function allows to bulk mint NFTs
     */
    function bulkMintByArtist(
        string[] memory _tokenURI,
        string[] memory title,
        string[] memory description,
        string memory artistName
    ) public onlyArtist returns (uint256[] memory _tokenId) {
        uint256[] memory tokenIds;

        uint256 length = title.length;

        for (uint256 i = 0; i < length; ) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            tokenOwner[tokenId] = msg.sender;

            string memory json = Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '{"title": "',
                            title[i],
                            '", "description": "',
                            description[i],
                            '", "image": "',
                            _tokenURI[i],
                            '", "artist name": "',
                            artistName,
                            '"}'
                        )
                    )
                )
            );

            string memory finalTokenUri = string(
                abi.encodePacked("data:application/json;base64,", json)
            );

            _mint(msg.sender, tokenId);
            _setTokenURI(tokenId, finalTokenUri);

            NFTData memory nftNew = NFTData(
                address(this),
                tokenId,
                _tokenURI[i],
                title[i],
                description[i],
                artistData[msg.sender],
                minter.Artist
            );
            nftData[tokenId] = nftNew;
            mintedNfts.push(nftNew);

            creatorTokens[msg.sender].push(tokenId);

            emit Mint(
                msg.sender,
                tokenId,
                _tokenURI[i],
                title[i],
                description[i]
            );

            unchecked {
                ++i;
            }
        }
        return tokenIds;
    }

    /**
     *This function allows to bulk mint NFTs
     */
    function bulkMintByAdmin(
        address _creator,
        string[] memory _tokenURI,
        string[] memory title,
        string[] memory description,
        string memory artistName
    ) public onlyAdmin returns (uint256[] memory _tokenId) {
        uint256[] memory tokenIds;

        uint256 length = title.length;

        for (uint256 i = 0; i < length; ) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            tokenOwner[tokenId] = _creator;

            tokenIds[i] = tokenId;

            string memory json = Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '{"title": "',
                            title[i],
                            '", "description": "',
                            description[i],
                            '", "image": "',
                            _tokenURI[i],
                            '", "artist name": "',
                            artistName,
                            '"}'
                        )
                    )
                )
            );

            string memory finalTokenUri = string(
                abi.encodePacked("data:application/json;base64,", json)
            );

            _mint(_creator, tokenId);
            _setTokenURI(tokenId, finalTokenUri);

            NFTData memory nftNew = NFTData(
                address(this),
                tokenId,
                _tokenURI[i],
                title[i],
                description[i],
                artistData[msg.sender],
                minter.Admin
            );
            nftData[tokenId] = nftNew;
            mintedNfts.push(nftNew);

            creatorTokens[_creator].push(tokenId);

            emit Mint(
                _creator,
                tokenId,
                _tokenURI[i],
                title[i],
                description[i]
            );

            unchecked {
                ++i;
            }
        }
        return tokenIds;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

    enum minter{
        Admin,
        Artist
    }

    struct SocialMediaData {
        string instagram;
        string facebook;
        string twitter;
        string website;
    }

    struct CoverImage {
        string uri;
        bool isGradient;
    }

    struct CollectionDetails {
        string name;
        string symbol;
        string about;
        string logo;
        CoverImage cover;
        SocialMediaData social;
    }

    struct NFTData {
        address nftAddress;
        uint tokenId;
        string tokenUri;
        string title;
        string description;
        artistDetails artist;
        minter mintedBy;
    }

     struct artistDetails {
        string name;
        address artistAddress;
        string imageUrl;
    }

    enum saleType {
        DirectSale,
        Auction
    }

    struct SaleData {
        NFTData nft;
        bool isOnSale;
        bool tokenFirstSale;
        uint salePrice;
        saleType saletype;
    }

    struct NFTAuction {
        uint startTime;
        uint endTime;
        uint tokenId;
        address owner;
        uint price;
        uint highestBid;
        address highestBidder;
    }

    struct bidHistory {
        address bidder;
        uint amount;
        uint timestamp;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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