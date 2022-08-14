pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

//import "hardhat/console.sol";
import "./INiftnityTicket.sol";
import "./SafeMath.sol";


contract NiftinityMarketplace {
    using SafeMath for uint;

    struct Listing {
        address seller;
        uint tokenId;
        uint amountListed;
        uint pricePerTicket;
        uint platformFee;
    }

    uint public nextListingId = 0;
    mapping(uint => Listing) public listings;
    mapping(uint => bool) public listingsActive;
    mapping(uint => mapping(address => uint)) public promoterFees;

    address public platformOwner;
    uint public defaultPlatformFee;
    INiftnityTicket public ticketContract;

    constructor (address _ticketContractAddress, uint _defaultPlatformFee) {

        require((0 <= _defaultPlatformFee) && (_defaultPlatformFee <= 100), "PLATFORM FEE MUST BE BETWEEN 0 AND 100");
        platformOwner = msg.sender;
        ticketContract = INiftnityTicket(_ticketContractAddress);
        defaultPlatformFee = _defaultPlatformFee;
    }

    function getListing(uint listingId) external view returns (Listing memory){
        return listings[listingId];
    }

    function createListing(
        address seller,
        uint tokenId,
        uint amountListed,
        uint pricePerTicket,
        uint platformFee)
    external
    {
        require(seller == tx.origin, "SELLER MUST BE EQUAL TO TX.ORIGIN");
        require(ticketContract.balanceOf(seller, tokenId) >= amountListed, "NOT ENOUGH TICKETS OWNED BY SELLER TO CREATE REQUESTED LISTING");
        require(ticketContract.isApprovedForAll(seller, address(this)), "SELLER DID NOT APPROVE NIFTINITY TO MANAGE TICKETS ON THEIR BEHALF");

        uint listingId = nextListingId;
        nextListingId = nextListingId + 1;

        Listing memory newListing = Listing(seller, tokenId, amountListed, pricePerTicket, platformFee);
        listings[listingId] = newListing;
        listingsActive[listingId] = true;

    }

    function mintAndListTickets(
        address creator,
        uint amount,
        string calldata publicMetadataURL,
        string calldata privateMetadataURL,
        uint pricePerTicket
    )
    external
    {
        uint newTokenId = ticketContract.mintTickets(creator, amount, publicMetadataURL, privateMetadataURL);
        this.createListing(creator, newTokenId, amount, pricePerTicket, defaultPlatformFee);
    }

    function buyTickets(address buyer, uint listingId, uint amount, address promoter) external payable {
        // Basic Security Checks
        {
            require(buyer == msg.sender, "BUYER MUST BE EQUAL TO MSG.SENDER");
            require(ticketContract.isApprovedForAll(buyer, address(this)), "BUYER DID NOT APPROVE NIFTINITY TO MANAGE TICKETS ON THEIR BEHALF");
            require(listingsActive[listingId], "SELECTED LISTING EITHER DOES NOT NOT EXIST OR IS NOT ACTIVE ANYMORE");
        }


        // Purchase feasibility Checks
        Listing storage listing = listings[listingId];
        uint totalPricePaidByBuyer = listing.pricePerTicket * amount;
        require(listing.amountListed >= amount, "NOT ENOUGH TICKETS LISTED TO FULFILL PURCHASE REQUEST");
        require(msg.value == totalPricePaidByBuyer, "PURCHASE PRICE DOES NOT MATCH MSG.VALUE EXACTLY");


        {
            uint totalPromoterFee = promoterFees[listingId][promoter].mul(totalPricePaidByBuyer).div(100);
            uint totalPlatformFee = listing.platformFee.mul(totalPricePaidByBuyer).div(100);
            require((totalPlatformFee + totalPromoterFee) < totalPricePaidByBuyer, "TRANSACTION FEES ARE HIGHER THAN TOTAL PRICE");
            uint totalSellerProfit = totalPricePaidByBuyer - (totalPlatformFee + totalPromoterFee);


            ticketContract.safeTransferFrom(listing.seller, buyer, listing.tokenId, amount, "");

//            console.log("Seller   = ", listing.seller, "Seller Profit = ", totalSellerProfit);
//            console.log("Buyer    = ", buyer, "Amount Paid   = ", listing.pricePerTicket);
//            console.log("Promoter = ", promoter, "Promoter Fee  = ", totalPromoterFee);
//            console.log("Platform = ", platformOwner, "Platform Fee  = ", totalPlatformFee);

            payable(listing.seller).transfer(totalSellerProfit);
            payable(platformOwner).transfer(totalPlatformFee);

            if ((promoter != 0x0000000000000000000000000000000000000000) && (totalPromoterFee > 0)) {
                payable(promoter).transfer(totalPromoterFee);
            }

            listing.amountListed = listing.amountListed - amount;
            if (listing.amountListed == 0) {
                listingsActive[listingId] = false;
            }

        }


        require(address(this).balance == 0, "MONEY LEFT ON CONTRACT AFTER AT THE END OF TRANSACTION");


    }

    function addPromoter(address promoter, uint listingId, uint promoterFee) external {
        Listing memory listing = listings[listingId];
        require((0 <= promoterFee) && (promoterFee <= 100 - defaultPlatformFee), "PLATFORM FEE MUST BE BETWEEN 0 AND (100 - PLATFORM FEE)");
        require(tx.origin == listing.seller, "ONLY LISTING OWNER CAN ASSIGN PROMOTERS");

        promoterFees[listingId][promoter] = promoterFee;
    }

    function numListings() external view virtual returns (uint256) {
        return nextListingId;
    }

}