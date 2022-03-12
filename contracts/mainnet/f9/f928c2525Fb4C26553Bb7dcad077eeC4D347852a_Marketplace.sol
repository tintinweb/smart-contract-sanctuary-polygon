//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IBookingNFT.sol";
import "./interfaces/IPropertyVerification.sol";
import "./interfaces/IEscrow.sol";

contract Marketplace is
    ERC721HolderUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // VARIABLES
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    address payable public treasuryWallet;

    IBookingNFT BnftContract;
    IEscrow EscrowContract;
    IPropertyVerification PropertyVerificationContract;

    uint256 public nextListingId; // Counter for the listing ids
    uint256 public nextRequestId; // Counter for the request Ids
    uint256 public feeBasisPoint;
    uint256 public resaleFeeBasisPoint;
    uint256 private highestCommissionBasisPoint;
    uint256 public paymentInterval;
    uint256 public nextBnftAuctionId;

    EnumerableSetUpgradeable.UintSet private listingIds;
    EnumerableSetUpgradeable.UintSet private bnftAuctionIds;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => ListingRequest) public listingRequests;
    mapping(uint256 => BnftAuction) public bnftAuctions;

    // STRUCTURES
    struct Listing {
        address payable seller;
        uint256 propertyId;
        uint256[] requestIds;
        bool active;
    }

    struct ListingRequest {
        address requester;
        uint256 listingId;
        uint256 checkInTime;
        uint256 checkOutTime;
        uint256 deposited;
        bool approved;
        bool canceled;
        IERC20Upgradeable currency;
        string imageCID;
    }

    struct BnftAuction {
        address payable seller;
        address currencyAddress;
        uint256 tokenId;
        uint256 startingPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 buyItNowPrice;
        Bid highestBid;
    }

    struct Bid {
        address payable bidder;
        uint256 amount;
    }

    struct EscrowData {
        uint256 escrowId;
        uint256 escrowReleaseTime;
        uint256 escrowAmount;
    }

    event listingRequested(
        address renter,
        uint256 listingId,
        uint256 price,
        uint256 checkInTime,
        uint256 checkOutTime,
        uint256 requestId,
        IERC20Upgradeable currency
    );
    event SaleMade(address buyer, uint256 listingId);

    // EVENTS
    event ListingCreated(address seller, uint256 listingId, uint256 propertyId);

    event ListingCancelled(uint256 listingId);

    event TokenCommissionBulkAdded(
        address tokenAddress,
        address payable[] propertyOwnerAddress,
        uint256[] tokenIds,
        uint256[] commissionBasisPoints
    );

    event newBookingCreated(
        address propertyOwner,
        address initialRenter,
        uint256 requestId,
        uint256 newBnftId,
        uint256 listingId,
        uint256 createdTimestamp,
        EscrowData escrowData,
        uint256 fees,
        uint256 ownerFee
    );

    event cancelBookingRequest(
        address cancelledBy,
        uint256 requestId,
        uint256 listingId
    );

    event BnftAuctionCreated(
        address seller,
        address currencyAddress,
        uint256 tokenId,
        uint256 auctionId,
        uint256 startingPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 buyItNowPrice
    );

    event BidPlaced(address bidder, uint256 auctionId, uint256 amount);
    event BnftAuctionClaimed(address winner, uint256 auctionId);

    // MODIFIERS

    modifier onlyAdmin() {
        require(hasRole(ROLE_ADMIN, msg.sender), "Sender is not admin");
        _;
    }
    modifier sellerOrAdmin(address seller) {
        require(
            msg.sender == seller || hasRole(ROLE_ADMIN, msg.sender),
            "Sender is not the seller or admin"
        );
        _;
    }
    modifier onlyPropertyVerification() {
        require(
            msg.sender == address(PropertyVerificationContract),
            "Only Property Verification contract may call"
        );
        _;
    }

    function initialize(
        address _admin,
        address payable _treasuryWallet,
        address _bookingNFTAddress
    ) public initializer {
        require(
            _treasuryWallet != address(0),
            "Treasury wallet cannot be 0 address"
        );
        // require(tripsAddress != address(0), 'Trips cannot be 0 address');
        require(_bookingNFTAddress != address(0), "BNFT cannot be 0 address");

        // _admin addrss is now admin
        _setupRole(ROLE_ADMIN, _admin);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);

        treasuryWallet = _treasuryWallet;

        BnftContract = IBookingNFT(_bookingNFTAddress);

        feeBasisPoint = 500; //4 decimals, applies to listings. Fees collected are held in contract
        resaleFeeBasisPoint = 100; //4 decimals, applies to listings. Fees collected are held in contract
        highestCommissionBasisPoint = 10000; // Used to determine what the maximum fee (100%)
        paymentInterval = 86400; // intervals in which the user must pay (default 1 day)
    }

    function setEscrowAddress(address newEscrowAddress) external onlyAdmin {
        EscrowContract = IEscrow(newEscrowAddress);
    }

    function setBnftAddress(address newBnftAddress) external onlyAdmin {
        BnftContract = IBookingNFT(newBnftAddress);
    }

    function setPropertyVerificationAddress(address newPropertyVerificationAddress)
        external
        onlyAdmin
    {
        PropertyVerificationContract = IPropertyVerification(
            newPropertyVerificationAddress
        );
    }

    /**
     * @dev Create a new listing for a given property
     *
     * @param propertyId: id of the property being listed (from the PropertyVerificationContract)
     */
    function createListing(uint256 propertyId, address propertyOwner)
        public
        onlyPropertyVerification
        returns (uint256)
    {
        // the address listing this property must be the owner of the property
        require(
            PropertyVerificationContract.isPropertyOwnedBy(
                propertyId,
                propertyOwner
            ),
            "User does not own the property"
        );

        // create a new listing and add it to the list
        uint256 listingId = generateListingId();

        // empty array to keep track of requests specific to this listing
        uint256[] memory requests;

        listings[listingId] = Listing(
            // seller
            payable(propertyOwner),
            // propertyId
            propertyId,
            // requests
            requests,
            // active
            true
        );

        bool addSuccess = listingIds.add(listingId);
        require(addSuccess, "failed to add the new listing to the list");

        emit ListingCreated(
            // seller
            propertyOwner,
            // listingId
            listingId,
            // propertyId
            propertyId
        );

        return listingId;
    }

    /**
     * @dev Send a request for a listing
     * @param listingId      id of the listing
     * @param price          Price that the renter offers. Renter must also deposit this amount
     * @param checkInTime    check in time in epoch time
     * @param checkOutTime   check in time in epoch time
     */
    function requestListing(
        uint256 listingId,
        uint256 price,
        uint256 checkInTime,
        uint256 checkOutTime,
        IERC20Upgradeable currency,
        string memory imageCID
    ) external payable {
        Listing storage listing = listings[listingId];
        // renter must offer more than 0
        require(price > 0, "Must offer more than 0");

        // Owner cannot request their own property
        require(
            listing.seller != msg.sender,
            "Property owner cannot request the listing"
        );

        // Check in time must in the future
        require(
            block.timestamp < checkInTime,
            "The check in time has already passed."
        );
        // checkout time must be passed checkInTime
        require(
            checkOutTime > checkInTime,
            "The check in time is after the check out time"
        );

        if (address(currency) == address(0)) {
            require(msg.value == price, "Did not send the correct amount");
        } else {
            // Renter deposits money to Marketplace contract until approved or cancelled
            currency.safeTransferFrom(msg.sender, address(this), price);
        }

        uint256 newRequestId = generateRequestId();

        // create the new listing
        listingRequests[newRequestId] = ListingRequest(
            msg.sender,
            listingId,
            checkInTime,
            checkOutTime,
            price,
            false,
            false,
            currency,
            imageCID
        );

        // keep track of the requests per id
        listing.requestIds.push(newRequestId);

        emit listingRequested(
            msg.sender,
            listingId,
            price,
            checkInTime,
            checkOutTime,
            newRequestId,
            currency
        );
    }

    function cancelRequest(uint256 requestId) public {
        uint256 listingId = listingRequests[requestId].listingId;
        address seller = listings[listingId].seller;
        require(
            listingRequests[requestId].requester == msg.sender ||
                seller == msg.sender ||
                address(PropertyVerificationContract) == msg.sender,
            "User is not permited to cancel the request"
        );
        require(
            !listingRequests[requestId].approved,
            "This request is already approved"
        );
        require(
            !listingRequests[requestId].canceled,
            "This request is already cancelled"
        );
        listingRequests[requestId].canceled = true;

        // native tokens
        if (address(listingRequests[requestId].currency) == address(0)) {
            (bool success, ) = listingRequests[requestId].requester.call{
                value: listingRequests[requestId].deposited
            }("");
            require(success, "Transfer to requester failed");
        } else {
            // return the funds to the requester
            listingRequests[requestId].currency.safeTransfer(
                listingRequests[requestId].requester,
                listingRequests[requestId].deposited
            );
        }

        // once money has been returned, the deposited amount should be 0
        listingRequests[requestId].deposited = 0;

        emit cancelBookingRequest(msg.sender, requestId, listingId);
    }

    /**
     * @dev Approve a requested booking
     * @param requestId id of the request
     * @param ownerFee The fee that the owner collects
     */
    function approveBooking(uint256 requestId, uint256 ownerFee)
        external
        payable
    {
        ListingRequest memory listingRequest = listingRequests[requestId];
        // Listing memory listing = listings[listingRequest.listingId];

        // Only the seller can approve
        require(
            msg.sender == listings[listingRequest.listingId].seller,
            "only the listing owner may approve the booking"
        );

        require(
            listingRequest.requester != address(0),
            "This is an invalid request."
        );
        require(!listingRequest.canceled, "This request has been cancelled");
        require(
            !listingRequest.approved,
            "This request has already been approved"
        );
        // owner fee cannot be greater than 100%
        require(
            ownerFee < highestCommissionBasisPoint,
            "Owner fee must be within 100%"
        );

        require(
            block.timestamp < listingRequest.checkInTime,
            "The check in time has already passed"
        );
        require(
            listingRequest.checkInTime < listingRequest.checkOutTime,
            "The check in time is after the check out time"
        );

        // once money has been returned, the deposited amount should be 0
        listingRequests[requestId].deposited = 0;
        listingRequests[requestId].approved = true;

        uint256 newBnftId = BnftContract.createBooking(
            msg.sender,
            listingRequest.requester,
            // currency that must be used in future auctions
            address(listingRequest.currency),
            listingRequest.checkInTime,
            listingRequest.checkOutTime,
            listings[listingRequest.listingId].propertyId,
            ownerFee,
            listingRequest.imageCID
        );

        // Collect the fees for trips trade
        uint256 fees = (listingRequest.deposited * feeBasisPoint) /
            highestCommissionBasisPoint;
        uint256 nativeEscrowAmount = 0;

        // send the appropriate fees to trips trade treasury wallet
        if (address(listingRequest.currency) == address(0)) {
            (bool success, ) = treasuryWallet.call{value: fees}("");
            require(success, "Transfer of tokens to seller wallet failed");
            nativeEscrowAmount = listingRequest.deposited - fees;
        } else {
            listingRequest.currency.safeTransfer(
                treasuryWallet,
                // Trips trade fees
                fees
            );

            // approve escrow from using
            listingRequest.currency.approve(
                address(EscrowContract),
                listingRequest.deposited
            );
        }

        uint256 escrowId = EscrowContract.createEscrow{
            value: nativeEscrowAmount
        }(
            // the escrow should be released once the dispute time is over
            listingRequest.checkInTime +
                PropertyVerificationContract.disputeTimeLimit(),
            // lock up all the rent fees
            listingRequest.deposited - fees,
            newBnftId,
            listings[listingRequest.listingId].propertyId,
            ownerFee,
            listingRequest.currency
        );

        EscrowData memory escrowData = EscrowData(
            // escrowId
            escrowId,
            // escrowReleaseTime
            listingRequest.checkInTime +
                PropertyVerificationContract.disputeTimeLimit(),
            // escrowAmount
            listingRequest.deposited - fees
        );

        emit newBookingCreated(
            // propertyOwner
            listings[listingRequest.listingId].seller,
            // initialRenter
            listingRequest.requester,
            // requestId
            requestId,
            // newBnftId
            newBnftId,
            // listingId
            listingRequest.listingId,
            // createdTimestamp
            block.timestamp,
            // escrow data
            escrowData,
            // fees
            fees,
            // ownerFee
            ownerFee
        );
    }

    /**
     * @dev Get number of listings
     *
     * @return the number of listings
     */
    function getNumListings() external view returns (uint256) {
        return listingIds.length();
    }

    /**
     * @dev get list Ids at given indices
     *
     * Params:
     * indices: array of indecies
     */
    function getListingIds(uint256[] memory indices)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory foundListingIds = new uint256[](indices.length);

        for (uint256 i = 0; i < indices.length; i++) {
            foundListingIds[i] = listingIds.at(indices[i]);
        }

        return foundListingIds;
    }

    /**
     * @dev get listing at the given indices
     *
     * @param indices array of indices to
     * @return array of Listing structs at the indicies passed in
     */
    function getListingsAtIndices(uint256[] memory indices)
        external
        view
        returns (Listing[] memory)
    {
        Listing[] memory output = new Listing[](indices.length);

        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = listings[listingIds.at(indices[i])];
        }

        return output;
    }

    /**
     * @dev Cancel a listing given the listing id
     *
     * @param listingId listing id
     */
    function cancelListing(uint256 listingId)
        external
        onlyPropertyVerification
        nonReentrant
    {
        // check if the listing exists
        require(listingIds.contains(listingId), "Listing does not exist");

        // get the listing data
        Listing storage listing = listings[listingId];
        // remove listing from the mapping
        listingIds.remove(listingId);
        listings[listingId].active = false;

        // cancel all requests for this listing
        for (uint256 i = 0; i < listing.requestIds.length; i++) {
            cancelRequest(listing.requestIds[i]);
        }

        emit ListingCancelled(listingId);
    }

    /**
     * @dev set a new fee basis point
     * @param _feeBasisPoint the new fee basis point
     */
    function setFee(uint256 _feeBasisPoint) external onlyAdmin {
        require(
            _feeBasisPoint <= highestCommissionBasisPoint,
            "Fee must be less than 100%"
        );
        feeBasisPoint = _feeBasisPoint;
    }

    function setResaleFee(uint256 _newFee) external onlyAdmin {
        require(
            _newFee <= highestCommissionBasisPoint,
            "Fee must be less than 100%"
        );
        resaleFeeBasisPoint = _newFee;
    }

    /**
     * @dev generate a new listing id (iterates by 1)
     * @return the generated listing id
     */
    function generateListingId() internal returns (uint256) {
        return nextListingId++;
    }

    function generateRequestId() internal returns (uint256) {
        return nextRequestId++;
    }

    function getNumAuctions() external view returns (uint256) {
        return bnftAuctionIds.length();
    }

    function getAuctionIds(uint256[] memory indices)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory output = new uint256[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = bnftAuctionIds.at(indices[i]);
        }
        return output;
    }

    function getBnftAuctionsAtIndices(uint256[] memory indices)
        external
        view
        returns (BnftAuction[] memory)
    {
        BnftAuction[] memory output = new BnftAuction[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = bnftAuctions[bnftAuctionIds.at(indices[i])];
        }

        return output;
    }

    /**
     * @dev create an auction
     * @param tokenId the id of the bnft
     * @param startingPrice the minimum price to bid on the auction
     * @param startTime the time when the auction will start
     * @param endTime the time when the auction will end
     * @param buyItNowPrice the price which, if reached, the auction will end and the bidder will buy the bnft automatically. If 0, there is no buy it price
     */
    function createBnftAuction(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 buyItNowPrice
    ) public nonReentrant {
        (, , address currencyAddress, uint256 checkInTime, , , ) = BnftContract
            .bookingDetails(tokenId);
        IERC721Upgradeable bnftToken = IERC721Upgradeable(
            address(BnftContract)
        );

        // require seller is token owner
        require(
            msg.sender == bnftToken.ownerOf(tokenId),
            "User is not the owner of this Bnft"
        );

        // End time is before the check in time
        require(
            checkInTime > endTime,
            "The auction ends after the check in time"
        );
        // end time must be after the start time
        require(startTime < endTime, "End time must be after the start time");

        // end time must be after current time
        require(
            block.timestamp < endTime,
            "auction end time has already passed"
        );

        // if the buyItNowPrice is 0, implies there is no "buy it now" price
        if (buyItNowPrice != 0) {
            require(
                buyItNowPrice > startingPrice,
                "starting price must be less than the 'buy it now' price"
            );
        }

        uint256 auctionId = generateBnftAuctionId();
        // store the bnft in this contract
        bnftToken.safeTransferFrom(msg.sender, address(this), tokenId);
        bnftAuctions[auctionId] = BnftAuction(
            payable(msg.sender),
            currencyAddress,
            tokenId,
            startingPrice,
            startTime,
            endTime,
            buyItNowPrice,
            Bid(payable(msg.sender), 0)
        );

        bnftAuctionIds.add(auctionId);

        emit BnftAuctionCreated(
            msg.sender,
            currencyAddress,
            tokenId,
            auctionId,
            startingPrice,
            startTime,
            endTime,
            buyItNowPrice
        );
    }

    function placeBid(uint256 auctionId, uint256 amount)
        external
        payable
        nonReentrant
    {
        require(
            bnftAuctionIds.contains(auctionId),
            "This auction does not exist. Failed to bid"
        );

        BnftAuction storage auction = bnftAuctions[auctionId];
        require(
            block.timestamp >= auction.startTime,
            "Auction has not yet started"
        );
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(
            amount > auction.highestBid.amount,
            "Bid is not higher than the previous bid"
        );
        require(
            amount >= auction.startingPrice,
            "Bid is lower than the minimum bid"
        );

        if (auction.currencyAddress == address(0)) {
            require(
                msg.value == amount,
                "Did not send the correct amount of funds for this bid"
            );

            // return the funds to the previous highest bidder
            (bool success, ) = auction.highestBid.bidder.call{
                value: auction.highestBid.amount
            }("");
            require(
                success,
                "Transfer of funds back to the previous highest bidder failed"
            );
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(
                auction.currencyAddress
            );

            // retrieve the bid amount from the bidder
            token.safeTransferFrom(msg.sender, address(this), amount);
            token.safeTransfer(
                auction.highestBid.bidder,
                auction.highestBid.amount
            );
        }

        // set the new highest bidder
        auction.highestBid = Bid(payable(msg.sender), amount);

        // if the highest bid has been met, claim auction
        if (amount >= auction.buyItNowPrice && auction.buyItNowPrice != 0) {
            claimAuction(auctionId);
        }

        emit BidPlaced(msg.sender, auctionId, amount);
    }

    function claimAuction(uint256 auctionId) public payable {
        require(
            bnftAuctionIds.contains(auctionId),
            "Auction does not exist. Failed to claim"
        );
        BnftAuction memory auction = bnftAuctions[auctionId];

        // if the end time has passed OR the buy it now price has been surpassed
        require(
            block.timestamp >= auction.endTime ||
                (auction.buyItNowPrice <= auction.highestBid.amount &&
                    auction.buyItNowPrice != 0),
            "Auction is ongoing"
        );

        uint256 fee = (auction.highestBid.amount * resaleFeeBasisPoint) / 10000;
        bnftAuctionIds.remove(auctionId);
        (
            address propertyOwnerAddress,
            ,
            ,
            ,
            ,
            ,
            uint256 ownerFee
        ) = BnftContract.bookingDetails(auction.tokenId);
        uint256 commission = (auction.highestBid.amount * ownerFee) / 10000;

        // MATIC
        if (auction.currencyAddress == address(0)) {
            // send the earnings to the seller (minus the fee and property owner commission)
            (bool success, ) = auction.seller.call{
                value: auction.highestBid.amount - fee - commission
            }("");
            require(success, "Transfer of tokens to seller wallet failed");
            // send the fees to the treasury wallet
            (bool treasurySuccess, ) = treasuryWallet.call{value: fee}("");
            require(
                treasurySuccess,
                "Transfer of tokens to treasury wallet failed"
            );
            // send the commission to the property owner
            (bool propertyOwnerSuccess, ) = propertyOwnerAddress.call{
                value: commission
            }("");
            require(
                propertyOwnerSuccess,
                "Transfer of tokens to property owner failed"
            );
            // OTHERS
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(
                auction.currencyAddress
            );
            token.safeTransfer(
                auction.seller,
                auction.highestBid.amount - fee - commission
            );
            token.safeTransfer(treasuryWallet, fee);
            token.safeTransfer(propertyOwnerAddress, commission);
        }

        // transfer the bnft to the buyer
        BnftContract.safeTransferFrom(
            address(this),
            auction.highestBid.bidder,
            auction.tokenId
        );

        emit BnftAuctionClaimed(auction.highestBid.bidder, auctionId);
    }

    function generateBnftAuctionId() internal returns (uint256) {
        return nextBnftAuctionId++;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IBookingNFT {
    function getPropertyOwner(uint256 tokenId) external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getCheckInTime(uint256 tokenId) external view returns (uint256);

    function createBooking(
        address propertyOwnerAddress,
        address renterAddress,
        address currencyAddress,
        uint256 checkInTime,
        uint256 checkOutTime,
        uint256 propertyId,
        uint256 ownerFee,
        string memory imageCID
    ) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function bookingDetails(uint256 tokenId)
        external
        view
        returns (
            address propertyOwner,
            address renter,
            address currencyAddress,
            uint256 checkInTime,
            uint256 checkOutTime,
            uint256 propertyId,
            uint256 ownerFee
        );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract IPropertyVerification {
    uint256 public disputeTimeLimit; // Time limit to dispute a property before it's too late

    function verify(address propertyOwnerAddress, uint256 propertyId)
        external
        virtual
        returns (uint256);

    function unlistProperty(uint256 propertyId) external virtual;

    function isPropertyOwnedBy(uint256 propertyId, address propertyOwner)
        external
        view
        virtual
        returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IEscrow {
    function createEscrow(
        uint256 releaseTime,
        uint256 amount,
        uint256 bnftId,
        uint256 propertyId,
        uint256 ownerFee,
        IERC20Upgradeable currency
    ) external payable returns (uint256);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}