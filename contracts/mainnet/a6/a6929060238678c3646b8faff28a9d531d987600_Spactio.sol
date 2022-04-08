// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


import "./IERC20.sol";
import "./ERC721.sol";
import "./ERC1155.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";


contract Spactio is Ownable, ERC1155Holder {
    uint256 public totalFees = 0;
    mapping(address=>uint256) public collectionFees;

    event NewAuction(address indexed seller, address indexed smartContract, uint256 indexed tokenId, uint256 minimumPrice, uint256 id);
    event NewRentOffer(address indexed landlord, address indexed smartContract, uint256 indexed tokenId, uint256 price, uint256 collateral, uint256 totalDays, uint256 id);

    struct Auction {
        bool valid;
        bool is721;
        uint256 createdOn;
        uint256 auctionEndsOn;
        address smartContract;
        uint256 tokenId;
        address seller;
        address highestBidder;
        uint256 minimumPrice;
        uint256 currentPrice;
        bool closed;
    }

    struct RentOffer {
        bool valid;
        bool is721;
        uint256 createdOn;
        uint256 offerEndsOn;
        address smartContract;
        uint256 tokenId;
        address landlord;
        address tenant;
        uint256 price;
        uint256 collateral;
        uint256 totalDays;
        uint256 rentStartedOn;
        uint256 rentEndsOn;
        bool closed;
    }
    
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => RentOffer) public rentOffers;

    function createAuction(address _smartContract, uint256 _tokenId, uint256 _minimumPrice, uint256 _totalDays, bool _is721) public {
        uint256 id = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, _smartContract, _tokenId)));
        require(!auctions[id].valid, "The auction already exists");
        require(_minimumPrice > 0, "Invalid price");
        require(_smartContract != address(0), "Invalid smart contract");
        require(_totalDays > 0, "Invalid days");

        if (_is721) {
            ERC721(_smartContract).transferFrom(msg.sender, address(this), _tokenId);
        } else {
            ERC1155(_smartContract).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "0x0");
        }
        
        Auction memory o;
        o.valid = true;
        o.seller = msg.sender;
        o.smartContract = _smartContract;
        o.is721 = _is721;
        o.tokenId = _tokenId;
        o.minimumPrice = _minimumPrice;
        o.createdOn = block.timestamp;
        o.auctionEndsOn = block.timestamp + _totalDays * 1 days;
        
        auctions[id] = o;
        
        emit NewAuction(msg.sender, _smartContract, _tokenId, _minimumPrice, id);
    }

    function createRentOffer(address _smartContract, uint256 _tokenId, uint256 _price, uint256 _collateral, uint256 _totalDays, bool _is721) public {
        uint256 id = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, _smartContract, _tokenId)));
        require(!auctions[id].valid, "The offer already exists");
        require(_price > 0, "Invalid price");
        require(_collateral > 0, "Invalid collateral");
        require(_smartContract != address(0), "Invalid smart contract");
        require(_totalDays > 0, "Invalid days");

        if (_is721) {
            ERC721(_smartContract).transferFrom(msg.sender, address(this), _tokenId);
        } else {
            ERC1155(_smartContract).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "0x0");
        }
        
        RentOffer memory o;
        o.valid = true;
        o.landlord = msg.sender;
        o.smartContract = _smartContract;
        o.is721 = _is721;
        o.tokenId = _tokenId;
        o.price = _price;
        o.collateral = _collateral;
        o.createdOn = block.timestamp;
        o.offerEndsOn = block.timestamp + 30 days;
        o.totalDays = _totalDays;
        
        rentOffers[id] = o;
        
        emit NewRentOffer(msg.sender, _smartContract, _tokenId, _price, _collateral, _totalDays, id);
    }

    function claimAuction(uint256 _id) public {
        require(auctions[_id].valid, "Invalid auction");
        require(auctions[_id].auctionEndsOn < block.timestamp, "Still not finished");
        require(!auctions[_id].closed, "Already closed");
        require(auctions[_id].highestBidder == msg.sender, "Not the highest bidder");

        Auction storage auction = auctions[_id];
        auction.closed = true;
        uint256 percentage = 100 - getFees(auction.smartContract);
        uint256 totalAmount = auction.currentPrice * percentage / 100;
        payable(auction.seller).transfer(totalAmount);
        totalFees += auction.currentPrice - totalAmount; 

        if (auction.is721) {
            ERC721(auction.smartContract).transferFrom(address(this), msg.sender, auction.tokenId);
        } else {
            ERC1155(auction.smartContract).safeTransferFrom(address(this), msg.sender, auction.tokenId, 1, "0x0");
        }
    }

    function bid(uint256 _id) public payable {
        require(auctions[_id].valid, "Invalid auction");
        require(!auctions[_id].closed, "Already closed");
        require(auctions[_id].auctionEndsOn > block.timestamp, "Already finished");
        require(msg.value > auctions[_id].currentPrice, "Invalid bid");

        Auction storage auction = auctions[_id];

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.currentPrice);
        }

        auction.highestBidder = msg.sender;
        auction.currentPrice = msg.value;
    }

    function cancelAuction(uint256 _id) public {
        require(auctions[_id].valid, "Invalid auction");
        require(!auctions[_id].closed, "Already closed");
        require(auctions[_id].highestBidder == address(0), "Already a bid");
        require(auctions[_id].seller == msg.sender, "Not the seller");

        Auction storage auction = auctions[_id];
        auction.valid = false;

        if (auction.is721) {
            ERC721(auction.smartContract).transferFrom(address(this), msg.sender, auction.tokenId);
        } else {
            ERC1155(auction.smartContract).safeTransferFrom(address(this), msg.sender, auction.tokenId, 1, "0x0");
        }
    }
    
    function claimRentOffer(uint256 _id) public {
        require(rentOffers[_id].valid, "Invalid rent offer");
        require(!rentOffers[_id].closed, "Already closed");
        require(rentOffers[_id].tenant != address(0), "Not rented");
        require(rentOffers[_id].rentEndsOn > block.timestamp, "Still not finished");

        RentOffer storage rentOffer = rentOffers[_id];
        rentOffer.closed = true;
        payable(rentOffer.landlord).transfer(rentOffer.collateral);
    }

    function getFees(address _collection) internal view returns (uint256) {
        if (collectionFees[_collection] == 0) {
            return 10;
        }
        return collectionFees[_collection];
    }

    function rent(uint256 _id) public payable {
        require(rentOffers[_id].valid, "Invalid rent offer");
        require(rentOffers[_id].tenant == address(0), "Already rented");
        require(!rentOffers[_id].closed, "Already closed");
        require(block.timestamp < rentOffers[_id].offerEndsOn, "Offer not valid anymore");
        require(msg.value >= rentOffers[_id].price + rentOffers[_id].collateral, "Invalid value");

        RentOffer storage rentOffer = rentOffers[_id];
        rentOffer.tenant = msg.sender;
        rentOffer.rentStartedOn = block.timestamp;
        rentOffer.rentEndsOn = block.timestamp + rentOffer.totalDays * 1 days;
        uint256 percentage = 100 - getFees(rentOffer.smartContract);
        uint256 totalAmount = rentOffer.price * percentage / 100;
        payable(rentOffer.landlord).transfer(totalAmount);
        totalFees += rentOffer.price - totalAmount; 

        if (rentOffer.is721) {
            ERC721(rentOffer.smartContract).transferFrom(address(this), msg.sender, rentOffer.tokenId);
        } else {
            ERC1155(rentOffer.smartContract).safeTransferFrom(address(this), msg.sender, rentOffer.tokenId, 1, "0x0");
        }
    }

    function repayRentOffer(uint256 _id) public {
        require(rentOffers[_id].valid, "Invalid rent offer");
        require(!rentOffers[_id].closed, "Already closed");
        require(rentOffers[_id].tenant != address(0), "There is no tenant");

        RentOffer storage rentOffer = rentOffers[_id];
        rentOffer.closed = true;

        if (rentOffer.is721) {
            ERC721(rentOffer.smartContract).transferFrom(msg.sender, rentOffer.landlord, rentOffer.tokenId);
        } else {
            ERC1155(rentOffer.smartContract).safeTransferFrom(msg.sender, rentOffer.landlord, rentOffer.tokenId, 1, "0x0");
        }

        payable(msg.sender).transfer(rentOffer.collateral);
    }

    function cancelRentOffer(uint256 _id) public {
        require(rentOffers[_id].valid, "Invalid rent offer");
        require(!rentOffers[_id].closed, "Already closed");
        require(rentOffers[_id].tenant == address(0), "Already a tenant");
        require(rentOffers[_id].landlord == msg.sender, "Not the landlord");

        RentOffer storage rentOffer = rentOffers[_id];
        rentOffer.valid = false;

        if (rentOffer.is721) {
            ERC721(rentOffer.smartContract).transferFrom(address(this), msg.sender, rentOffer.tokenId);
        } else {
            ERC1155(rentOffer.smartContract).safeTransferFrom(address(this), msg.sender, rentOffer.tokenId, 1, "0x0");
        }
    }

    function _recoverNFT(address smartContract, uint256 tokenId, bool is721) public onlyOwner {
        if (is721) {
            ERC721(smartContract).transferFrom(address(this), msg.sender, tokenId);
        } else {
            ERC1155(smartContract).safeTransferFrom(address(this), msg.sender, tokenId, 1, "0x0");
        }
    }

    function _setCollectionFees(address _collection, uint256 _fees) public onlyOwner {
        require(_fees < 100, "Invalid number");

        collectionFees[_collection] = _fees;
    }

    function _withdrawFees() public onlyOwner {
        uint256 total = totalFees;
        totalFees = 0;
        payable(msg.sender).transfer(total);
    }
}