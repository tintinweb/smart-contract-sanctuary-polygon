// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Gigble {
    uint public value;
    address payable public publisher;
    address payable public gigCreator;
    address payable public platformAddress;
    enum State {
        Created,
        Locked,
        Release,
        Inactive
    }
    // The state variable has a default value of the first member, `State.created`
    State public state;
    modifier condition(bool condition_) {
        require(condition_);
        _;
    }
    /// Only the gigCreator can call this function.
    error OnlyGigCreator();
    /// Only the publisher can call this function.
    error OnlyPublisher();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The provided value has to be even.
    error ValueNotEven();
    modifier onlyGigCreator() {
        if (msg.sender != gigCreator) revert OnlyGigCreator();
        _;
    }
    modifier onlyPublisher() {
        if (msg.sender != publisher) revert OnlyPublisher();
        _;
    }
    modifier inState(State state_) {
        if (state != state_) revert InvalidState();
        _;
    }
    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();

    // Ensure that `msg.value` is an even number.
    // Division will truncate if it is an odd number.
    // Check via multiplication that it wasn't an odd number.
    constructor(address payable _platformAddress) payable {
        publisher = payable(msg.sender);
        platformAddress = _platformAddress;

        value = msg.value;
        if ((value) != msg.value) revert ValueNotEven();
    }

    // Struct for storing gig information
    struct Gig {
        uint256 id;
        string title;
        string description;
        uint256 price;
        uint256 deliveryDate;
        address payable publisher;
        address payable gigCreator;
    }

    // Mapping to store gig data
    mapping(uint256 => Gig) gigs;

    // Mapping to store escrow payments for each gig and gigCreator
    mapping(uint256 => mapping(address => uint256)) escrows;

    // Variables to track the number of gigs
    uint256 public gigCount = 0;

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

        state = State.Created;

        gigCount++;
    }

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the publisher before
    /// the contract is locked.
    function abort() external onlyPublisher inState(State.Created) {
        emit Aborted();
        state = State.Inactive;
        // We use transfer here directly. It is
        // reentrancy-safe, because it is the
        // last call in this function and we
        // already channged the state.
        publisher.transfer(address(this).balance);
        gigCount - 1;
    }

    /// Confirm the purchase as gigCreator.
    /// Transaction has to include `2 * value` ether.
    /// The ether will be locked until confirmReceived
    /// is called.
    function confirmPurchase()
        external
        payable
        inState(State.Created)
        condition(msg.value == (value))
    {
        emit PurchaseConfirmed();
        gigCreator = payable(msg.sender);
        state = State.Locked;
    }

    /// Confirm that you (the gigCreator) received the item.
    /// This will release the locked ether.
    function acceptGig() external onlyGigCreator inState(State.Locked) {
        emit ItemReceived();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Release;

        uint256 fee = value / 10;

        gigCreator.transfer(value - fee);
        // Transfer the fee to the platform's address
        payable(platformAddress).transfer(fee);
    }

    /// This function refunds the publisher, i.e.
    /// pays back the locked funds of the publisher.
    function refund() external onlyPublisher inState(State.Created) {
        emit SellerRefunded();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Inactive;
        publisher.transfer(value);
        gigCount - 1;
    }
}