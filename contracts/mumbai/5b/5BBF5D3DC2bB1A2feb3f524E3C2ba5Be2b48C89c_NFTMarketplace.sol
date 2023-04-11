// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";

/// @title Clock auction for non-fungible tokens.
contract NFTMarketplace {
    using SafeERC20 for IERC20;
    // Represents an auction on an NFT
    struct Listing {
        // Current owner of NFT
        address seller;
        // Price at beginning of listing
        uint128 startingPrice;
        address token;
        // Duration (in seconds) of listing
        uint64 duration;
        // Time when listing started
        // NOTE: 0 if this listing has been concluded
        uint64 startedAt;
        uint64 endAt;
        address highestBidder;
        uint256 highestPrice;
        bool isAuction;
    }

    // Cut owner takes on each listing, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;

    address public owner;

    // Map from token ID to their corresponding listing.
    mapping(address => mapping(uint256 => Listing)) public listings;

    event ListingCreated(
        address indexed _NFTAddress,
        uint256 indexed _tokenId,
        uint256 _startingPrice,
        address _token,
        uint256 _duration,
        address _seller,
        bool _isAuction
    );

    event BuySucceed(
        address indexed _NFTAddress,
        uint256 indexed _tokenId,
        uint256 _price
    );

    event ListingCancelled(
        address indexed _NFTAddress,
        uint256 indexed _tokenId
    );

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _ownerCut - percent cut the owner takes on each listing, must be
    ///  between 0-10,000.
    constructor(uint256 _ownerCut, address _owner) {
        require(_ownerCut <= 10000);
        ownerCut = _ownerCut;
        owner = _owner;
    }

    /// @dev DON'T give me your money.
    //   function () external {}

    // Modifiers to check that inputs can be safely stored with a certain
    // number of bits. We use constants and multiple modifiers to save gas.
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

    /// @dev Creates and begins a new listing.
    /// @param _NFTAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _tokenId - ID of token to listing, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of listing.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    function createListing(
        address _NFTAddress,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _duration,
        address _token,
        bool _isAuction,
        uint64 _startedAt,
        uint64 _endAt
    )
        external
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith64Bits(_duration)
    {
        address _seller = msg.sender;
        require(_owns(_NFTAddress, _seller, _tokenId), "Not own NFT");
        _checkApproved(_NFTAddress, _tokenId);
        Listing memory _listing = Listing(
            _seller,
            uint128(_startingPrice),
            _token,
            uint64(_duration),
            _startedAt,
            _endAt,
            address(0),
            _startingPrice,
            _isAuction
        );
        require(_listing.duration >= 1 minutes, "Too short!");

        listings[_NFTAddress][_tokenId] = _listing;

        emit ListingCreated(
            _NFTAddress,
            _tokenId,
            uint256(_listing.startingPrice),
            _token,
            uint256(_listing.duration),
            _seller,
            _isAuction
        );
    }

    /// @dev Bids on an open listing, completing the listing and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _NFTAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _tokenId - ID of token to bid on.
    function bid(
        address _NFTAddress,
        uint256 _tokenId,
        uint256 _price
    ) external payable {
        Listing storage _listing = listings[_NFTAddress][_tokenId];
        require(_listing.isAuction == true, "Not auction");
        require(_isOnListing(_listing), "Auction not on");
        require(_price > _listing.highestPrice, "Invalid price");
        require(_listing.seller != msg.sender, "Invalid bid");
        _listing.highestPrice = _price;
        _listing.highestBidder = msg.sender;
    }

    /// @dev Cancels an listing that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _NFTAddress - Address of the NFT.
    /// @param _tokenId - ID of token on listing
    function cancelListing(address _NFTAddress, uint256 _tokenId) external {
        Listing memory _listing = listings[_NFTAddress][_tokenId];
        // require(_isOnListing(_listing), "Auction not on");
        require(msg.sender == _listing.seller, "Not authorized");
        _cancelListing(_NFTAddress, _tokenId);
    }

    /// @dev Returns true if the NFT is on listing.
    /// @param _listing - listing to check.
    function _isOnListing(Listing memory _listing)
        internal
        view
        returns (bool)
    {
        return (block.timestamp > _listing.startedAt && block.timestamp < _listing.endAt);
    }

    /// @dev Gets the NFT object from an address, validating that implementsERC721 is true.
    /// @param _NFTAddress - Address of the NFT.
    function _getNFTContract(address _NFTAddress)
        internal
        pure
        returns (IERC721)
    {
        IERC721 candidateContract = IERC721(_NFTAddress);
        // require(candidateContract.implementsERC721());
        return candidateContract;
    }

    /// @dev Returns true if the owner owns the token.
    /// @param _NFTAddress - The address of the NFT.
    /// @param _owner - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(
        address _NFTAddress,
        address _owner,
        uint256 _tokenId
    ) internal view returns (bool) {
        IERC721 _NFTContract = _getNFTContract(_NFTAddress);
        return (_NFTContract.ownerOf(_tokenId) == _owner);
    }

    /// @dev Cancels an listing unconditionally.
    function _cancelListing(address _NFTAddress, uint256 _tokenId) internal {
        delete listings[_NFTAddress][_tokenId];
        emit ListingCancelled(_NFTAddress, _tokenId);
    }

    /// @dev Approve to transfer NFT when win listing
    /// @param _NFTAddress - The address of the NFT.
    /// @param _tokenId - ID of token whose approval to verify.
    function _checkApproved(address _NFTAddress, uint256 _tokenId)
        internal
        view
    {
        IERC721 _NFTContract = _getNFTContract(_NFTAddress);
        require(
            _NFTContract.getApproved(_tokenId) == address(this),
            "Marketplace not approved for this NFT"
        );
    }

    /// @dev For User who win listing can claim NFT
    /// @param _NFTAddress - The address of the NFT.
    /// @param _tokenId - ID of token to bid on.
    function purchaseNFT(address _NFTAddress, uint256 _tokenId) external {
        address _buyer = msg.sender;
        IERC721 _NFTContract = _getNFTContract(_NFTAddress);
        Listing memory _listing = listings[_NFTAddress][_tokenId];
        require(!_isOnListing(_listing) && _listing.highestPrice > 0, "listing is on");
        require(_listing.highestBidder == _buyer, "not winner");
        require(_listing.isAuction == true, "not auction");
        address _seller = _listing.seller;
        _NFTContract.transferFrom(_seller, _buyer, _tokenId);

        uint256 cut_amount = (_listing.startingPrice * ownerCut) / 10000;
        IERC20(_listing.token).safeTransferFrom(_buyer, owner, cut_amount);
        IERC20(_listing.token).safeTransferFrom(
            _buyer,
            _seller,
            _listing.highestPrice - cut_amount
        );

        _cancelListing(_NFTAddress, _tokenId);
        emit BuySucceed(_NFTAddress, _tokenId, _listing.highestPrice);
    }

    /// @dev Buy NFT on marketplace
    /// @param _NFTAddress - The address of the NFT.
    /// @param _tokenId - ID of token to bid on.
    function buyNFT(address _NFTAddress, uint256 _tokenId) external {
        Listing memory _listing = listings[_NFTAddress][_tokenId];
        require(_listing.isAuction == false, "is auction");
        address _buyer = msg.sender;
        IERC721 _NFTContract = _getNFTContract(_NFTAddress);
        _NFTContract.transferFrom(_listing.seller, _buyer, _tokenId);

        uint256 cut_amount = (_listing.startingPrice * ownerCut) / 10000;
        IERC20(_listing.token).safeTransferFrom(
            _buyer,
            _listing.seller,
            cut_amount
        );
        IERC20(_listing.token).safeTransferFrom(
            _buyer,
            _listing.seller,
            _listing.startingPrice - cut_amount
        );

        _cancelListing(_NFTAddress, _tokenId);
        emit BuySucceed(_NFTAddress, _tokenId, _listing.startingPrice);
    }

    /// @dev Buy NFT on marketplace
    /// @param _NFTAddress - The address of the NFT.
    /// @param _tokenId - ID of token to bid on.
    function setPrice(address _NFTAddress, uint256 _tokenId, uint128 _price) external {
        Listing storage _listing = listings[_NFTAddress][_tokenId];
        require(_listing.isAuction == false, "is auction");
        require(_listing.seller == msg.sender, "not authorized");
        _listing.startingPrice = _price;
    }
}