// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;


// Interface to interact with the ERC721 NFTs
interface IERC721 {

    // function to transfer the NFT from owner to the given address. In order for this function to work, the owner needs to approve the transfer request first
    // it accepts the address of the NFT owner, the destination address and the token ID
    function transferFrom(address _from, address _to, uint256 _id) external;
}

contract Escrow{

    enum inspectionStatusOptions{pending, done, fail} // Different stages of the escrow

    //Defining the structure of estate(property)
    struct estate{
        uint256 nftID;
        address payable buyer;
        address payable seller;
        address payable inspector;
        address lender;
        uint256 purchaseAmount;
        uint256 processedAmount;
        inspectionStatusOptions inspectionStatus;
        bool transactionStatus;
    }
    
    //Defing the approvals struct in order to record approval for each estate
    struct approvals{
        bool sellerApproval;
        bool buyerApproval;
        bool lenderApproval;
    }

    mapping(uint256 => estate) properties; // mapping the estates with the nftId which is basically the tokenId from the Realestate NFT
    mapping(uint256 => approvals) public approval; // mapping to store the approvals

    address payable owner;// address of the owner to transfer him the brokerage fees
    address nftAddress;// Address of the RealContract smart contract in order to communicate to it regarding the nft ownership and token Ids

    // Constructor of the smart contract
    // Initializes the owner address and the realestate smart contract address
    constructor(address _nftAddress){
        owner = payable(msg.sender);
        nftAddress = _nftAddress;
    }

    // This modifier checks if the transaction is being conducted by the buyer of that particular 
    modifier onlyBuyer(uint256 _nftID){
        require(properties[_nftID].buyer == msg.sender);
        _;
    }

    // This modifier checks if the transaction is being conducted by the seller of that particular 
    modifier onlySeller(uint256 _nftID){
        require(properties[_nftID].seller == msg.sender);
        _;
    }

    // This modifier checks if the transaction is being conducted by the inspector of that particular 
    modifier onlyInspector(uint256 _nftID){
        require(properties[_nftID].inspector == msg.sender);
        _;
    }

    // This modifier checks if the transaction is being conducted by the lender of that particular 
    modifier onlyLender(uint256 _nftID){
        require(properties[_nftID].lender == msg.sender);
        _;
    }

    // Using this function different parties can give approval for the estate from their side
    function approve(uint256 _nftID) public {
        if(properties[_nftID].seller == msg.sender){
            approval[_nftID].sellerApproval = true;
        }else if(properties[_nftID].buyer == msg.sender){
            approval[_nftID].buyerApproval = true;
        }else if(properties[_nftID].lender == msg.sender){
            approval[_nftID].lenderApproval = true;
        }
    }


    // Creating a new estate records in the smart contracts
    function new_estate(uint256 _nftID, address payable _buyer, address payable _inspector, address _lender, uint256 _purchaseAmount) public {
        properties[_nftID] = estate( _nftID, _buyer,payable(msg.sender),_inspector,_lender,_purchaseAmount, 0,inspectionStatusOptions.pending, false);
        approval[_nftID] = approvals(false, false, false);
    }

    //This particular is called by the estate inspector in order to change the inpectionstatus of the estate. 
    // Before the inspector can update it, the buyer need to pay the inspection fees
    function inspection_update(uint256 _nftID,inspectionStatusOptions _inspectionStatus) public onlyInspector(_nftID) {
        require(properties[_nftID].processedAmount > 0, "Let the buyer pay the inspection fees");
        properties[_nftID].inspectionStatus = _inspectionStatus;
    }

    //This function is used by the buyer to lock the base fees or 20% of the total amount to start the escrow process
    function pay_escrow(uint256 _nftID) public payable onlyBuyer(_nftID){
        require(msg.value >= properties[_nftID].purchaseAmount*22/100, "You need to pay atleast 22% of the total amount.");
        properties[_nftID].processedAmount += msg.value;
    }

    //This function is used by the lender or banks in normal context to lock the remaining amount to the smart contract to complete the process
    // In order to pay the remaining amount, the inspection should be over
    function pay_lender(uint256 _nftID) public payable onlyLender(_nftID){
        require(properties[_nftID].inspectionStatus == inspectionStatusOptions.done, "Inspection need to be done in order to proceed");
        require(msg.value >= properties[_nftID].purchaseAmount*80/100, "You need to pay atleast the remaining amount");
        properties[_nftID].processedAmount += msg.value;
    }

    // This function is used to complete the transaction and transfer the property to the owner as well as transfered the amount to the seller
    //There are a lot of the checks needs to be done before transacting the property mentioned below: -
    // The inspections needs to be successful
    // Every party needs to submit their approval to the smart contract
    function transact_property(uint256 _nftID) public {
        require(properties[_nftID].inspectionStatus == inspectionStatusOptions.done, "The property need to be insepcted by the inspector");
        require(approval[_nftID].sellerApproval, "Seller approval is needed for the transaction");
        require(approval[_nftID].buyerApproval, "Buyer approval is needed for the transaction");
        require(approval[_nftID].lenderApproval, "Lender approval is needed for the transaction");
        require(properties[_nftID].processedAmount >= properties[_nftID].purchaseAmount);
        (bool sellersuccess, ) = payable(properties[_nftID].seller).call{value: properties[_nftID].purchaseAmount}(""); // Transfering the amount to the seller account
        require(sellersuccess, "Payment failed");
        (bool inspectorsuccess, ) = payable(properties[_nftID].inspector).call{value: properties[_nftID].processedAmount * 1/100}(""); // Transfering the inspection fees of 1% to the inspector
        require(inspectorsuccess, "Payment failed");
        (bool ownersuccess, ) = payable(owner).call{value: properties[_nftID].processedAmount * 1/100}("");// Transfering the commision to the owner of the smart contract
        require(ownersuccess, "Payment failed");
        IERC721(nftAddress).transferFrom(properties[_nftID].seller, properties[_nftID].buyer, properties[_nftID].nftID);
        properties[_nftID].transactionStatus = true;
        properties[_nftID].processedAmount = 0;
    }

    //This function is used to cancel the transaction if the inspection fails
    function cancelSale(uint256 _nftID) public {
        require(properties[_nftID].inspectionStatus == inspectionStatusOptions.fail, "The inspection was found to be true");
        (bool success, ) = payable(properties[_nftID].buyer).call{value: properties[_nftID].processedAmount}(""); //Transferring the processed amount to the buyer's account
        require(success);
    }

    //fallback function to recieve funds into the smart contract
    receive() external payable {}


    // This function is used to get the processed amount for a particular nft token
    function getBalance(uint256 _nftID) public view returns(uint256){
        return properties[_nftID].processedAmount;
    }
}