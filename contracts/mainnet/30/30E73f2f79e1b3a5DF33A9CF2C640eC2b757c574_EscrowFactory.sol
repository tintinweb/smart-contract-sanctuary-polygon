// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./_CloneFactory.sol";
import "./Escrow.sol";
import "./ReentrancyGuard.sol";

// test
import "./IERC20.sol";
//import "./IERC1363.sol";

contract EscrowFactory is ReentrancyGuard {

    address public admin;
    address public implementation;
    mapping (uint256 => address) clonedContracts;
    uint256 public clonedContractsIndex = 0;

    // Agreement Creation
    event OfferCreatedBuyer(uint256 indexed clonedContractsIndex, address indexed _buyer, uint256 indexed _price, address[] _personalizedOffer, address[] _arbiters);
    event OfferCreatedSeller(uint256 indexed clonedContractsIndex, address indexed _seller, uint256 indexed _price, address[] _personalizedOffer, address[] _arbiters);
    // Agreement Acceptance
    event OfferAcceptedBuyer(uint256 indexed clonedContractsIndex, address indexed _buyer);
    event OfferAcceptedSeller(uint256 indexed clonedContractsIndex, address indexed _seller);
    // Buyer
    event DisputeStarted(uint256 indexed clonedContractsIndex, address indexed _buyer);
    event DeliveryConfirmed(uint256 indexed clonedContractsIndex, address indexed _buyer);  
    event ContractFunded(uint256 indexed clonedContractsIndex, address indexed _buyer);  
    // Seller
    event FundsClaimed(uint256 indexed clonedContractsIndex, address indexed _seller);
    event PaymentReturned(uint256 indexed clonedContractsIndex, address indexed _seller);
    // dispute handling
    event DisputeVoted(uint256 indexed clonedContractsIndex, address indexed _arbiter, bool indexed _returnFundsToBuyer);
    event DisputeClosed(uint256 indexed clonedContractsIndex, bool indexed _FundsReturnedToBuyer);
    // Contract Canceled
    event ContractCanceled(uint256 indexed clonedContractsIndex, address indexed _contractOwner);



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


    function CreateEscrowSeller (
        address[] calldata arbiters,
        uint256 price,
        address tokenContractAddress,
        uint256 timeToDeliver,
        string memory hashOfDescription,
        uint256 offerValidUntil,
        address[] calldata personalizedOffer
        
        // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 - USDC
        // 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174 - USDC on Polygon
        // 0x07865c6E87B9F70255377e024ace6630C1Eaa37F - USDC on Goerli
        // 0x0000000000000000000000000000000000000000 - ETH

        // ["0xdD870fA1b7C4700F2BD7f44238821C26f7392148", "0x583031D1113aD414F02576BD6afaBfb302140225", "0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB"], 100000000000000000, "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", 1, a23e5fdcd7b276bdd81aa1a0b7b963101863dd3f61ff57935f8c5ba462681ea6, 1784214826, []

    ) external {
        address clone = Clones.clone(implementation);

        Escrow(clone).InitializeSeller(
            payable(address(this)),         // the Factory contract
            payable(msg.sender),            // seller,
            arbiters,
            price,
            tokenContractAddress,
            timeToDeliver,
            hashOfDescription,
            offerValidUntil,
            personalizedOffer
        );

        clonedContracts[clonedContractsIndex] = clone;
        clonedContractsIndex++;

        emit OfferCreatedSeller(clonedContractsIndex, msg.sender, price, personalizedOffer, arbiters);
    }



    function CreateEscrowBuyer (  
        address[] calldata arbiters,
        uint256 price,
        address tokenContractAddress,
        uint256 timeToDeliver,
        string memory hashOfDescription,
        uint256 offerValidUntil,
        address[] calldata personalizedOffer
        
        // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 - USDC
        // 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174 - USDC on Polygon
        // 0x07865c6E87B9F70255377e024ace6630C1Eaa37F - USDC on Goerli
        // 0x0000000000000000000000000000000000000000 - ETH

        // ["0xdD870fA1b7C4700F2BD7f44238821C26f7392148", "0x583031D1113aD414F02576BD6afaBfb302140225", "0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB"], 100000000000000000, "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", 1, a23e5fdcd7b276bdd81aa1a0b7b963101863dd3f61ff57935f8c5ba462681ea6, 1784214826, []
        // 100000000000000000

    ) external payable{
        address clone = Clones.clone(implementation);

        Escrow(clone).InitializeBuyer{value: msg.value}(
            payable(address(this)),         // the Factory contract
            payable(msg.sender),            // buyer,
            arbiters,
            price,
            tokenContractAddress,
            timeToDeliver,
            hashOfDescription,
            offerValidUntil,
            personalizedOffer
        );

        clonedContracts[clonedContractsIndex] = clone;


        // transfer ERC20 (ETH is transfered at the contract instance level)
        if(tokenContractAddress != address(0)){
          // payment in tokenContractAddress currency
          IERC20 tokenContract = IERC20(tokenContractAddress);
          bool transferred = tokenContract.transferFrom(msg.sender, GetAddress(clonedContractsIndex), price);   // transfer to the contract instance    +  make sure user gives UNLIMITED approval to the main EscrowFactory before hand
          require(transferred, "ERC20 tokens failed to transfer to contract wallet");
        }


        

        // 1st prefered option is to do the payment transfer inside the InitializeBuyer, on the Escrow level
        // coded - need to test it now

        // 1st option seems to be working, need to consider 2 options:   price in ETH (working)   and   price in ERC20 (so need to handle both cases - might need 2 initializations on Escrow level)
        // problem:  for ERC20 transfer, you need a seperate approval Tx......
        // ERC667 implementation would be the only option

        // 2nd option is to pay just after creation of the instance
        // Escrow(clonedContracts[clonedContractsIndex]).getArbiters();

        clonedContractsIndex++;

        emit OfferCreatedBuyer(clonedContractsIndex, msg.sender, price, personalizedOffer, arbiters);
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

    function GetTokenContractAddress(uint256 index) view external returns(address) {
        return Escrow(clonedContracts[index]).tokenContractAddress();
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




    // WRITE FUNCTIONS

    // new buyer accepts the agreement
    function AcceptOfferBuyer(uint256 index) external payable{

      address tokenContractAddress = Escrow(clonedContracts[index]).tokenContractAddress();
      uint256 price = Escrow(clonedContracts[index]).price();


      if(tokenContractAddress != address(0)){
        // payment in tokenContractAddress currency
        IERC20 tokenContract = IERC20(tokenContractAddress);
        bool transferred = tokenContract.transferFrom(msg.sender, GetAddress(index), price);   // transfer to the contract instance    +  make sure user gives UNLIMITED approval to the main EscrowFactory before hand
        require(transferred, "ERC20 tokens failed to transfer to contract wallet");
      }


      // call the instance and finish the accept offer
      Escrow(clonedContracts[index]).acceptOfferBuyer{value: msg.value}(payable(msg.sender));
      emit OfferAcceptedBuyer(clonedContractsIndex, msg.sender);
    }

    function AcceptOfferSeller(uint256 index) external {
        Escrow(clonedContracts[index]).acceptOfferSeller(payable(msg.sender));
        emit OfferAcceptedSeller(clonedContractsIndex, msg.sender);
    } 

    // not sure if needed
    function AcceptOfferBuyer_ERC20(uint256 index) external {                                              // RENAME!!!!       AcceptOffer_ERC20   ->   AcceptOfferBuyer_ERC20
        Escrow(clonedContracts[index]).acceptOfferBuyer_ERC20(payable(msg.sender));
        emit OfferAcceptedBuyer(clonedContractsIndex, msg.sender);
    } 



    // NOTE:
    // test if we can use `erc20TokenAddress` as the actual argument for `recipient`, so that we can transfer any token
    // best if we can rename the argument, if not -> we will just use supply the ERC20TokenAddress for the recipient argument (it will look weird, but it should do the job)

    // 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
    function transfer_ERC20(address recipient, uint256 amount) public returns (bool) {

        IERC20 tokenContract = IERC20(recipient);          // USDC on polygon
        bool transferred = tokenContract.transferFrom(msg.sender, address(this), amount);
        // bool transferred = tokenContract.transfer(address(this), amount);                // same behaviour as 'transferFrom'
        require(transferred, "ERC20 tokens failed to transfer to contract wallet");

        return transferred;
    }


    /*
        function transfer_ERC1363(address erc20contractAddress, uint256 amount) public returns (bool) {

            IERC1363 tokenContract = IERC1363(erc20contractAddress);          // USDC on polygon

            tokenContract.approveAndCall(address(this), amount);
            tokenContract.onApprovalReceived(msg.sender, amount, "function");      

            bool transferred = tokenContract.transferFrom(msg.sender, address(this), amount);
            // bool transferred = tokenContract.transfer(address(this), amount);                // same behaviour as 'transferFrom'
            require(transferred, "ERC20 tokens failed to transfer to contract wallet");

            return transferred;
        }
    */


    /*
        function approveAndCall(address erc20contractAddress, uint256 value, bytes memory data) public override returns (bool) {
            approve(msg.sender, value);
            require(_checkAndCallApprove(msg.sender, value, data), "ERC1363: _checkAndCallApprove reverts");
            return true;
        }

        function _checkAndCallApprove(address spender, uint256 value, bytes memory data) internal returns (bool) {
            if (!spender.isContract()) {
                return false;
            }
            bytes4 retval = IERC1363Spender(spender).onApprovalReceived(
                _msgSender(), value, data
            );
            return (retval == _ERC1363_APPROVED);
        }
    */



    //-------------------------------------------------------------------------------------------------------------------------------------


    // ONLY SELLER
    function ReturnPayment(uint256 index) external payable {
        Escrow(clonedContracts[index]).returnPayment(msg.sender);
        emit PaymentReturned(clonedContractsIndex, msg.sender);
    } 

    function ClaimFunds(uint256 index) external payable {
        Escrow(clonedContracts[index]).claimFunds(msg.sender);
        emit FundsClaimed(clonedContractsIndex, msg.sender);
    } 

    function CancelSellerContract(uint256 index) external {
        Escrow(clonedContracts[index]).cancelSellerContract(msg.sender);
        emit ContractCanceled(clonedContractsIndex, msg.sender);
    } 


    // ONLY SELLER - DELEGATES
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

    // ONLY SELLER - PERSONALIZED OFFER
    function AddSellerPersonalizedOffer(uint256 index, address[] calldata personalizedOffer) external {
        Escrow(clonedContracts[index]).addSellerPersonalizedOffer(msg.sender, personalizedOffer);
    }
    function RemoveSellerPersonalizedOffer(uint256 index, address[] calldata personalizedOffer) external {
        Escrow(clonedContracts[index]).removeSellerPersonalizedOffer(msg.sender, personalizedOffer);
    }
    function UpdateSellerPersonalizedOffer(uint256 index, address[] calldata personalizedOfferToAdd, address[] calldata personalizedOfferToRemove) external {
        Escrow(clonedContracts[index]).removeSellerPersonalizedOffer(msg.sender, personalizedOfferToRemove);
        Escrow(clonedContracts[index]).addSellerPersonalizedOffer(msg.sender, personalizedOfferToAdd);        
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

    function CancelBuyerContract(uint256 index) external {
        Escrow(clonedContracts[index]).cancelBuyerContract(msg.sender);
        emit ContractCanceled(clonedContractsIndex, msg.sender);
    } 

    // ONLY BUYER - DELEGATES
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

    // ONLY BUYER - PERSONALIZED OFFER
    function AddBuyerPersonalizedOffer(uint256 index, address[] calldata personalizedOffer) external {
        Escrow(clonedContracts[index]).addBuyerPersonalizedOffer(msg.sender, personalizedOffer);
    }
    function RemoveBuyerPersonalizedOffer(uint256 index, address[] calldata personalizedOffer) external {
        Escrow(clonedContracts[index]).removeBuyerPersonalizedOffer(msg.sender, personalizedOffer);
    }
    function UpdateBuyerPersonalizedOffer(uint256 index, address[] calldata personalizedOfferToAdd, address[] calldata personalizedOfferToRemove) external {
        Escrow(clonedContracts[index]).removeBuyerPersonalizedOffer(msg.sender, personalizedOfferToRemove);
        Escrow(clonedContracts[index]).addBuyerPersonalizedOffer(msg.sender, personalizedOfferToAdd);        
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