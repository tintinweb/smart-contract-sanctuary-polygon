//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract Gigble {
    address payable public platformAddress;

    constructor(address payable _platformAddress) {
        platformAddress = _platformAddress;
    }

    // Struct for storing gig information
    struct Gig {
        uint256 id;
        string title;
        string description;
        uint256 price;
        uint256 deliveryDate;
        address payable seller;
        address payable buyer;
        bool isAccepted;
    }

    // Mapping to store gig data
    mapping(uint256 => Gig) gigs;

    // Mapping to store escrow payments for each gig and buyer
    mapping(uint256 => mapping(address => uint256)) escrows;

    // Variables to track the number of gigs
    uint256 public gigCount = 0;

    // Events to emit when a gig is created, purchased, accepted or completed
    event GigCreated(
        uint256 id,
        string title,
        string description,
        uint256 price,
        uint256 deliveryDate,
        address seller
    );

    event GigAccepted(uint256 id);

    event Escrowed(uint256 indexed gigId, address indexed buyer, uint256 value);
    event PaymentReleased(
        uint256 indexed gigId,
        address indexed buyer,
        address indexed seller,
        uint256 value,
        address platformAddress
    );

    // Function to create a new gig
    function createGig(
        string memory _title,
        string memory _description,
        uint256 _price,
        uint256 _deliveryDate
    ) public {
        require(
            bytes(_title).length > 0 &&
                bytes(_description).length > 0 &&
                _price > 0 &&
                _deliveryDate < block.timestamp,
            "Invalid gig details"
        );

        gigCount++;
        gigs[gigCount] = Gig(
            gigCount,
            _title,
            _description,
            _price,
            _deliveryDate,
            payable(msg.sender),
            payable(address(0)),
            false
        );

        emit GigCreated(
            gigCount,
            _title,
            _description,
            _price,
            _deliveryDate,
            msg.sender
        );
    }

    function releasePayment(uint256 _gigId) public {
        Gig storage gig = gigs[_gigId];
        address payable seller = gig.seller;
        uint256 payment = escrows[_gigId][msg.sender];
        uint256 fee = payment / 10; // Set a 10% fee for the platform
        require(gig.isAccepted == true, "Gig is not Accepted");
        // Transfer the payment to the seller's address
        seller.transfer(payment - fee);

        // Transfer the fee to the platform's address
        payable(platformAddress).transfer(fee);

        // Reset the escrow payment for the buyer
        escrows[_gigId][msg.sender] = 0;

        // Emit an event to log the payment release
        emit PaymentReleased(
            _gigId,
            msg.sender,
            seller,
            payment,
            platformAddress
        );
    }
}