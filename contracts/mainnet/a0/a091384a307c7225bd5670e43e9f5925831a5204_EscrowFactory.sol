// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./_CloneFactory.sol";
import "./Escrow.sol";
import "./ReentrancyGuard.sol";


contract EscrowFactory is ReentrancyGuard {

    address public admin;
    address public implementation;
    mapping (uint256 => address) clonedContracts;
    uint256 public clonedContractsIndex = 0;

    //Declaring Events
    event OfferCreated(uint256 indexed clonedContractsIndex, address indexed _seller, uint256 indexed _price, uint256 _timeToDeliver, uint _offerValidUntil, address[] _personalizedOffer, address[] _arbiters);
    // buyer
    event OfferAccepted(uint256 indexed clonedContractsIndex, address indexed _buyer);
    event DisputeStarted(uint256 indexed clonedContractsIndex, address indexed _buyer);
    event DeliveryConfirmed(uint256 indexed clonedContractsIndex, address indexed _buyer);
    // seller
    event FundsClaimed(uint256 indexed clonedContractsIndex, address indexed _seller);
    event PaymentReturned(uint256 indexed clonedContractsIndex, address indexed _seller);
    // dispute handling
    event DisputeVoted(uint256 indexed clonedContractsIndex, address indexed _arbiter, bool indexed _returnFundsToBuyer);
    event DisputeClosed(uint256 indexed clonedContractsIndex, bool indexed _FundsReturnedToBuyer);



    constructor (address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    function SetImplementation (address _implementation) onlyAdmin public {
        implementation = _implementation;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }


    function CreateEscrow (
        
        address[] calldata arbiters,

        uint256 price,
        uint256 timeToDeliver,
        string memory hashOfDescription,

        // ADDED
        uint256 offerValidUntil,
        address[] calldata personalizedOffer
        
        // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 
        // 100000000000000000, 1, a23e5fdcd7b276bdd81aa1a0b7b963101863dd3f61ff57935f8c5ba462681ea6, 1657634353, ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"], ["0xdD870fA1b7C4700F2BD7f44238821C26f7392148", "0x583031D1113aD414F02576BD6afaBfb302140225", "0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB"]

    ) external {
        address clone = Clones.clone(implementation);

        Escrow(clone).Initialize(
            payable(address(this)),         // the Factory contract
            payable(msg.sender),            // seller,
            
            arbiters,

            price,
            timeToDeliver,
            hashOfDescription,
            
            // ADDED
            offerValidUntil,
            personalizedOffer

        );

        clonedContracts[clonedContractsIndex] = clone;
        clonedContractsIndex++;

        //emit OfferCreated(clonedContractsIndex, msg.sender, price, timeToDeliver, offerValidUntil, personalizedOffer, arbiters);
    }



    // ---------------------------------------------------------------------------
    //                  API functions to the escrow contracts
    // ---------------------------------------------------------------------------

    // GENERAL - READ
    function GetAddress(uint256 index) view public returns(address) {
        return clonedContracts[index];
    }

    function GetBalance(uint256 index) view external returns(uint256){
        return address(GetAddress(index)).balance;
    }

    function GetTimeLeftToDeadline(uint256 index) view external returns(uint256){
        if(GetState(index) == Escrow.State.await_payment){   // before agreement is made 
            return 0;
        } else {
            return (GetDeadline(index) - block.timestamp);
        }
    }

    function GetArbiters(uint256 index) view external returns(address[] memory){
        return Escrow(clonedContracts[index]).getArbiters();
    }

    function GetArbitersVote(uint256 index) view external returns(uint256[3] memory){
        return Escrow(clonedContracts[index]).getArbitersVote();
    }

    function GetBuyer(uint256 index) view external returns(address){
        return Escrow(clonedContracts[index]).buyer();
    }

    function GetSeller(uint256 index) view external returns(address) {
        return Escrow(clonedContracts[index]).seller();
    }

    function GetState(uint256 index) view public returns(Escrow.State) {
        return Escrow(clonedContracts[index]).state();
    }

    function GetPrice(uint256 index) view external returns(uint256) {
        return Escrow(clonedContracts[index]).price();
    }

    function GetDeadline(uint256 index) view public returns(uint256) {
        return Escrow(clonedContracts[index]).deadline();
    }

    function GetHashOfDescription(uint256 index) view external returns(string memory) {
        return Escrow(clonedContracts[index]).hashOfDescription();
    }

    function GetGracePeriod(uint256 index) view external returns(uint256) {
        return Escrow(clonedContracts[index]).gracePeriod();
    }



    // IMPLEMENT
    function GetIsOfferStillValid(uint256 index) view public returns(bool){
        return Escrow(clonedContracts[index]).isOfferValid();
    }

    function GetIsWalletEligibleToAcceptOffer(uint256 index, address wallet) view public returns(bool) {
    return Escrow(clonedContracts[index]).isWalletEligibleToAcceptOffer(wallet);
    }

    function GetIsWalletABuyerDelegate(uint256 index, address wallet) view public returns(bool) {
        return Escrow(clonedContracts[index]).isWalletBuyerDelegate(wallet);
    }

    function GetIsWalletASellerDelegate(uint256 index, address wallet) view public returns(bool) {
        return Escrow(clonedContracts[index]).isWalletSellerDelegate(wallet);
    }

    function GetValidUntil(uint256 index) view public returns(uint256){
        return Escrow(clonedContracts[index]).offerValidUntil();
    }

    function GetCommision(uint256 index) view public returns(uint256){
        return Escrow(clonedContracts[index]).GetCommision();
    }




    // new buyer accepts the agreement
    function AcceptOffer(uint256 index) external payable {
        Escrow(clonedContracts[index]).acceptOffer{value: msg.value}(payable(msg.sender));        // forward the buyers address
        emit OfferAccepted(clonedContractsIndex, msg.sender);
    } 


    // ONLY SELLER
    function ReturnPayment(uint256 index) external payable {
        Escrow(clonedContracts[index]).returnPayment(msg.sender);
        emit PaymentReturned(clonedContractsIndex, msg.sender);
    } 

    function ClaimFunds(uint256 index) external payable {
        Escrow(clonedContracts[index]).claimFunds(msg.sender);
        emit FundsClaimed(clonedContractsIndex, msg.sender);
    } 

    // ADDED
    function AddSellerDelegates(uint256 index, address[] calldata delegates) external {
        Escrow(clonedContracts[index]).addSellerDelegates(msg.sender, delegates);
    }
    function RemoveSellerDelegates(uint256 index, address[] calldata delegates) external {
        Escrow(clonedContracts[index]).removeSellerDelegates(msg.sender, delegates);
    }
    function UpdateSellerDelegates(uint256 index, address[] calldata delegatesToAdd, address[] calldata delegatesToRemove) external {
        Escrow(clonedContracts[index]).removeSellerDelegates(msg.sender, delegatesToRemove);
        Escrow(clonedContracts[index]).addSellerDelegates(msg.sender, delegatesToAdd);        
    }




    // ONLY BUYER
    function StartDispute(uint256 index) external {
        Escrow(clonedContracts[index]).startDispute(msg.sender);
        emit DisputeStarted(clonedContractsIndex, msg.sender);
    } 

    function ConfirmDelivery(uint256 index) external payable {
        Escrow(clonedContracts[index]).confirmDelivery(msg.sender);
        emit DeliveryConfirmed(clonedContractsIndex, msg.sender);
    } 

    // ADDED
    function AddBuyerDelegates(uint256 index, address[] calldata delegates) external {
        Escrow(clonedContracts[index]).addBuyerDelegates(msg.sender, delegates);
    }
    function RemoveBuyerDelegates(uint256 index, address[] calldata delegates) external {
        Escrow(clonedContracts[index]).removeBuyerDelegates(msg.sender, delegates);
    }
    function UpdateBuyerDelegates(uint256 index, address[] calldata delegatesToAdd, address[] calldata delegatesToRemove) external {
        Escrow(clonedContracts[index]).removeBuyerDelegates(msg.sender, delegatesToRemove);
        Escrow(clonedContracts[index]).addBuyerDelegates(msg.sender, delegatesToAdd);
    }





    // ONLY ARBITER
    function HandleDispute(uint256 index, bool returnFundsToBuyer) external payable {

        bool caseClosed = Escrow(clonedContracts[index]).handleDispute(msg.sender, returnFundsToBuyer);
        emit DisputeVoted(clonedContractsIndex, msg.sender, returnFundsToBuyer);

        if(caseClosed){
            // emit event that case is closed and money was transferred
            emit DisputeClosed(clonedContractsIndex, returnFundsToBuyer);
        }
    }

}