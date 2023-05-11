/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

interface TestToken {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function transfer(address recipient, uint256 amount) external returns(bool);

}

contract TestController{
    event TokenPurchased(address indexed _owner, uint256 _amount, uint256 _bnb);
    event ClaimedToken(address indexed _owner, uint256 _stakeId, uint256 _date);

    TestToken Token;

    bool public is_preselling;
    address payable owner;
    address payable tokenSource = payable(0xD22111277586166f0aA3Cfb8507bFfA3A6F1a42D); 
    address payable fundreceiver;
    uint256 soldTokens;
    uint256 receivedFunds;
    uint256 priceInETH=1;


    struct tokenVesting{
        uint256 amount;        
        uint256 date_added;     
        uint256 redeem_date;    
        uint256 redeem_count;
    }
    
    uint256 redemptionCount = 7; //4 times to redeem
    uint256 lockDays = 30; //1 month duration every redemption (total of 120 days or 4 months)
    uint256 rewardRate = 0; //20% reward for vesting the tokens

    uint256 public RecordId;
    mapping(uint256 => tokenVesting) idVesting; 
    mapping(uint256 => address) recordIdOwner;   

    constructor(TestToken _tokenAddress)  {
        Token = _tokenAddress;
        owner = payable(msg.sender);
        fundreceiver = owner;
        is_preselling = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "invalid owner");
        _;
    }
    
    //buy tokens
    function tokensale(uint256 _amount ) public payable returns(uint256)  {
        require(is_preselling, "pre selling is over.");
        require(msg.value >= priceInETH * _amount, "Insufficient funds!");

        uint256 _rewardAmount = (_amount * rewardRate) / 100; //get total reward for vesting
        uint256 _totalTokens = _amount + _rewardAmount; //total totens (principal + reward)

        RecordId += 1; //auto increment for every record

        //save new vesting record
        tokenVesting storage _vesting = idVesting[RecordId];
        _vesting.amount = _totalTokens;
        _vesting.date_added = block.timestamp;
        _vesting.redeem_date = block.timestamp ; //set 1st redemption date (+30 days)

        //track down the owner of the record id
        recordIdOwner[RecordId] = msg.sender;

        //transfer tokens to contract address
        Token.transferFrom(tokenSource, address(this), _totalTokens);

        //transfer bnb or network native coin
        fundreceiver.transfer(msg.value);
        
        soldTokens += _amount;
        receivedFunds += msg.value;

        emit TokenPurchased(msg.sender, _amount, msg.value);
        return RecordId;
    }

    function Redeem(uint256 _id) public returns(bool)  {
        
        //verify the owner of the stake record
        address _recordOwner = recordIdOwner[_id];
        require(_recordOwner == msg.sender, "invalid owner");

        tokenVesting storage _vesting = idVesting[_id];

        //validate if total redemption is not greater than 4 or (redemption count)
        require(_vesting.redeem_count < redemptionCount, "already redeemed");
        
        //validate if redemption date is ready
        uint256 _redeemDate = _vesting.redeem_date;  
        require(block.timestamp >= _redeemDate, "not yet ready to redeem");

        uint256 _redeemAmount = _vesting.amount / redemptionCount; //amount every redemption (divided by number of redemption or 4)

        _vesting.redeem_count += 1; //update count of redemption max of 4
        _vesting.redeem_date = block.timestamp + (lockDays * 1 days); // update date for next redemption +30 days 

        //tokens will be transferred to user's wallet address
        Token.transfer(msg.sender, _redeemAmount);

        emit ClaimedToken(msg.sender, _id, block.timestamp);
        return true;
    }
    
    function getTokenSupply() public view returns(uint256){
        return Token.totalSupply();
    }
    
    function getTokenbalance(address _address) public view returns(uint256){
        return Token.balanceOf(_address);
    }
    
    function totalSoldTokens() public view returns(uint256){
        return soldTokens;
    }
    function totalReceivedFunds() public view returns(uint256){
        return receivedFunds;
    }

    function calc(uint256 _tokensToBuy) public view returns(uint256){
        return priceInETH*_tokensToBuy;
    }
    
    function getbalance()  public onlyOwner {
        owner.transfer(address(this).balance);
    }

    
    function SetReceiver(address payable _fund) public onlyOwner {
        fundreceiver = _fund;
    }


    function SetPreSellingStatus() public onlyOwner {
        is_preselling = !is_preselling;
    }

    function updatePrice(uint256 _priceInETH) public onlyOwner {
        priceInETH=_priceInETH;
    }

}