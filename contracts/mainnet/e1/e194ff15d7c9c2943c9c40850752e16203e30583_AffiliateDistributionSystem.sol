/**
 *Submitted for verification at polygonscan.com on 2022-09-06
*/

// File: contracts/referral.sol



pragma solidity 0.8.10;

contract AffiliateDistributionSystem {
    address public owner;
    uint public _price = 0 * 10 * 18; //this is 1 Ether/Matic
    uint public _affiliationfee = 0 * 10 * 18; //this is 1 Ether/Matic
    uint public _share = 10; //this is 10% Affiliate Share for each coupon used

    //map coupons to affiliate addresses
    mapping(string => address) public affiliates;
    //map users to user addresses
    mapping(string => address) public users;
    mapping(address => string) public coupons;
    mapping(string => uint256) public used;
    mapping(address => string) public couponused;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function price(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function affiliationfees(uint256 newFee) public onlyOwner {
        _affiliationfee = newFee;
    }

    function share(uint256 newShare) public onlyOwner {
        _share = newShare;
    }

    function registerAffiliate(string calldata coupon) public payable {
        //avoid double affiliate codes
        require(affiliates[coupon] == address(0));
        require(msg.value >= _affiliationfee, "Not enough Matic paid");
        //link affiliate code to wallet
        affiliates[coupon] = msg.sender;
        //get affiliate code thru address
        coupons[msg.sender] = coupon;
    }

    //Registration Zone, Users will input coupon
    function registerUser(address payable _affiliate, string memory coupon, string calldata user)
        public
        payable
    {
        //avoid double username
        require(users[user] == address(0));
        //check if coupon exist
        require(affiliates[coupon] != address(0));
        require(affiliates[coupon] == _affiliate);
        //verify if coupon owned by the correct affiliate
        require(msg.value >= _price, "Not enough Matic paid");
        //+1 affiliate invites
        _affiliate.transfer(msg.value/_share);
        //count coupon usage
        used[coupon]++;
        //register user
        users[user] = msg.sender;
        //add coupon used by user
        couponused[msg.sender] = coupon;
    }

    function getAffiliate(string calldata coupon)
        public
        view
        returns (address)
    {
        return affiliates[coupon];
    }

    function getCouponUsed(string calldata coupon) public view returns (uint256) {
        return used[coupon];
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed.");
    }

}