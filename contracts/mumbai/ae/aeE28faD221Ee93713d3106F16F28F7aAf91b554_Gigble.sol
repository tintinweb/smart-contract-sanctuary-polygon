// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Gigble {
    uint public value;
    address payable public seller;
    address payable public buyer;
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
    /// Only the buyer can call this function.
    error OnlyBuyer();
    /// Only the seller can call this function.
    error OnlySeller();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The provided value has to be even.
    error ValueNotEven();
    modifier onlyBuyer() {
        if (msg.sender != buyer) revert OnlyBuyer();
        _;
    }
    modifier onlySeller() {
        if (msg.sender != seller) revert OnlySeller();
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
        seller = payable(msg.sender);
        platformAddress = _platformAddress;

        value = msg.value / 2;
        if ((2 * value) != msg.value) revert ValueNotEven();
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
    }

    // Mapping to store gig data
    mapping(uint256 => Gig) gigs;

    // Mapping to store escrow payments for each gig and buyer
    mapping(uint256 => mapping(address => uint256)) escrows;

    // Variables to track the number of gigs
    uint256 public gigCount = 0;

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the seller before
    /// the contract is locked.
    function abort() external onlySeller inState(State.Created) {
        emit Aborted();
        state = State.Inactive;
        // We use transfer here directly. It is
        // reentrancy-safe, because it is the
        // last call in this function and we
        // already channged the state.
        seller.transfer(address(this).balance);
    }

    /// Confirm the purchase as buyer.
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
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    /// Confirm that you (the buyer) received the item.
    /// This will release the locked ether.
    function confirmReceived() external onlyBuyer inState(State.Locked) {
        emit ItemReceived();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Release;

        uint256 fee = value / 10;

        buyer.transfer(value - fee);
        // Transfer the fee to the platform's address
        payable(platformAddress).transfer(fee);
    }

    /// This function refunds the seller, i.e.
    /// pays back the locked funds of the seller.
    function refundSeller() external onlySeller inState(State.Release) {
        emit SellerRefunded();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Inactive;
        seller.transfer(value);
    }
}