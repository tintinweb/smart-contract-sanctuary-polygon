//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _id) external;
}

contract Escrow {

    address public nftAddress;
    uint256 public nftID;
    uint256 public purchasePrice;
    uint256 public escrowAmount;
    address payable public seller;
    address payable public buyer;
    address public inspector;
    address public lender;
    address public appraiser;

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this method");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this method");
        _;
    }

    modifier onlyInspector() {
        require(msg.sender == inspector, "Only inspector can call this method");
        _;
    }

    modifier onlyAppraiser() {
        require(msg.sender == appraiser, "Only appraiser can call this method");
        _;
    }

    bool public inspectionPassed = false;
    mapping(address => bool) public inspectionApproval;    

    bool public appraisalPassed = false;
    mapping(address => bool) public appraisalApproval;

    constructor(
        address _nftAddress, 
        uint256 _nftID, 
        uint256 _purchasePrice, 
        uint256 _escrowAmount, 
        address payable _seller, 
        address payable _buyer,  
        address _inspector, 
        address _lender, 
        address _appraiser ) 
    {
        nftAddress = _nftAddress;
        nftID = _nftID;
        purchasePrice = _purchasePrice;
        escrowAmount = _escrowAmount;
        seller = _seller;
        buyer = _buyer;
        inspector = _inspector;
        lender = _lender;
        appraiser = _appraiser;
    }

    // Put Under Contract (only buyer - payable escrow)
    function depositEarnest() public payable onlyBuyer {
        require(msg.value >= escrowAmount);
    }

    // Update Inspection Status (only inspector)
    function updateInspectionStatus(bool _passed) public onlyInspector {
        inspectionPassed = _passed;
    }

    // Update Appraisal Status (only appraiser)
    function updateAppraisalStatus(bool _passed) public onlyAppraiser {
        appraisalPassed = _passed;
    }


    // Approve Sale
    function approveSale() public {
        inspectionApproval[msg.sender] = true;
        appraisalApproval[msg.sender] = true;
    }

    // Finalize Sale
    // -> Require inspection status
    // -> Require appraisal status
    // -> Require sale to be authorized
    // -> Require funds to be correct amount
    // -> Transfer NFT to buyer
    // -> Transfer Funds to Seller
    function finalizeSale() public {
        require(inspectionPassed);
        require(appraisalPassed);
        require(inspectionApproval[buyer]);
        require(inspectionApproval[seller]);
        require(inspectionApproval[lender]);
        require(appraisalApproval[buyer]);
        require(appraisalApproval[seller]);
        require(appraisalApproval[lender]);
        require(address(this).balance >= purchasePrice);

        (bool success, ) = payable(seller).call{value: address(this).balance}("");
        require(success);

        IERC721(nftAddress).transferFrom(address(this), buyer, nftID);
    }

    // Cancel Sale (handle earnest deposit)
    // -> if inspection or appraisal status is not approved, then refund, otherwise send to seller
    function cancelSale() public {
        if(inspectionPassed == false || appraisalPassed == false) {
            payable(buyer).transfer(address(this).balance);
        } else {
            payable(seller).transfer(address(this).balance);
        }        
    }

    receive() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Homework for students:
    // Add more robust 'cancel transaction'
    // Add more items like appraisal, ensure appraisal price is at least purchase price
    // Deploy to test network
    // Create a user interface
}