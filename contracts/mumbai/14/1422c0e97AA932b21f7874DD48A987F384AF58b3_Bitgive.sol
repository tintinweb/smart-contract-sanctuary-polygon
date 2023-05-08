// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Escrow {
    address payable ngo;
    uint amount;

    mapping(address => bool) donors;
    mapping(address => uint256) donations;
    
    enum TxnType {
        CREDIT,
        DEBIT
    }

    struct Txn {
        uint timestamp;
        address to;
        address from;
        uint amount;
        TxnType tx_type;
        string link;
    }

    Txn[] public txns;
    

    modifier isDonor() {
        require(donors[tx.origin], "N/D");
        _;
    }

    modifier isNgo() {
        require(tx.origin == ngo, "N/G");
        _;
    }

    constructor(address _ngo) {
        ngo = payable(_ngo);
        amount = 0;
    }

    function deposit() public payable {
        amount += msg.value;
        donors[tx.origin] = true;
        donations[tx.origin] = amount;
        Txn memory n_tx = Txn(block.timestamp, address(this), tx.origin, msg.value, TxnType.CREDIT, "");
        txns.push(n_tx);
    }

    function withdraw(uint w_amount, string memory link) isNgo public {
        require(w_amount <= amount, "IS/B");
        Txn memory n_tx = Txn(block.timestamp, ngo, address(this), w_amount, TxnType.DEBIT, link);
        ngo.transfer(w_amount);
        amount -= w_amount;
        donations[tx.origin] = 0;
        txns.push(n_tx);
    }

    function refund() isDonor public {
        uint256 minAmt = donations[tx.origin];
        if (address(this).balance < minAmt) {
            minAmt = address(this).balance;
        }
        payable(tx.origin).transfer(minAmt);
    }

    function getTxns() public view returns (Txn[] memory) {
        return txns;
    }

    function getBalanceSnapshot() public view returns (uint) {
        return address(this).balance;
    }
}

contract Bitgive {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string imgUrl;
        address[] donators;
        uint256[] donations;
        Escrow e;
    }

    mapping(uint256 => Campaign) public campaigns;

    mapping(address => bool) public ngo;

    uint256 public numCampaigns = 0;

    function checkNgo(address _addr) public view returns (bool) {
        return ngo[_addr];
    }

    function addToNgo(address _addr) public {
        ngo[_addr] = true;
    }

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _imgUrl) public returns (uint256) {
        Campaign storage campaign = campaigns[numCampaigns];

        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.imgUrl = _imgUrl;
        campaign.e = new Escrow(_owner);

        numCampaigns++;

        return numCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        campaign.amountCollected = campaign.amountCollected + amount;

        campaign.e.deposit{value: amount}();
    }

    function withdrawFromCampaign(uint256 _id, uint256 _amt, string memory link) public {
        Campaign storage campaign = campaigns[_id];
        campaign.e.withdraw(_amt, link);
    }

    function refundFromCampaign(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];
        campaign.e.refund(); 
    }

    function getAllTxns(uint256 _id) view public returns (Escrow.Txn[] memory) {
        return campaigns[_id].e.getTxns();
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numCampaigns);

        for(uint i = 0; i < numCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}