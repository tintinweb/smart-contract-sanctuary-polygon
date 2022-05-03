// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./FxBaseChildTunnel.sol";


contract MyTokenContract is ERC20, Ownable, FxBaseChildTunnel {

    //Store user staking info, user tokens balance earned, last updated info
    mapping(address => uint256[]) userStakeInfo;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public lastUpdated;

    uint256 public constant dailyReward = 5 ether;

    //Testing purposes only (to be removed later)
    uint256 public time;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) ERC20("My Token Name", "MYTN"){
        _mint(address(this), 100 ether);
    }

    //Modifier to update the balance and last updated info
    modifier updateBalance(address _address, uint256 _timestamp) {
        //Store the user earned balance before reset with new time
        userBalance[_address] += earned(_address); 

        //update the new time
        lastUpdated[_address] = _timestamp; 
        _;       
    }

    //Modifier to ensure user is not another contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory data) internal override validateSender(sender){ 
        (address from, uint256[] memory tokenIds, uint256 timestamp, bool action) = abi.decode(data, (address,uint256[],uint256, bool));
        time = block.timestamp;

        action? processStake(from, tokenIds, timestamp): processUnstake(from, tokenIds, timestamp);

    }

    function processStake(address _address, uint256[] memory _tokenIds, uint256 _timestamp) private updateBalance(_address, _timestamp){
        userStakeInfo[_address] = _tokenIds;

    }

    function processUnstake(address _address, uint256[] memory _tokenIds, uint256 _timestamp) private updateBalance(_address, _timestamp) {
        userStakeInfo[_address] = _tokenIds;

        if(userStakeInfo[_address].length == 0) {
            //Automatically claim all tokens if user unstake everything
            claimTokenForUser(_address);
        }
    }


    function getUserStakedTokens(address _address) public view returns(uint256[] memory){
        return userStakeInfo[_address];
    }

    //Display total unclaimed tokens in contract
    function getUnclaimedBalance (address _address) public view returns(uint256) {
        return (userBalance[_address] + earned(_address));
    
    }
    
    //Display total balance claimed (in wallet) and unclaimed tokens in the contract
    function getTotalTokens(address _address) public view returns(uint256) {
        return balanceOf(_address) + userBalance[_address] + earned(_address);
    }


    //Calculate token generate per second only
    function tokenPerSecond() public view returns(uint256) {
        return dailyReward/86400;
    }

    //Calculate total user earned (with multiplier)
    function earned(address _address) public view returns(uint256){
        return tokenPerSecond() * (block.timestamp - lastUpdated[_address]) * userStakeInfo[_address].length;
    }

    //Allow user to update their unclaim balances manually
    function updateUnclaimBalance(address _address) public {
        userBalance[_address] += earned(_address);
        lastUpdated[_address] = block.timestamp;
    }

    //Purchase utility (try forward to GNS for gasless transaction)
    function purchaseUtility(address _address, uint256 value) public updateBalance(_address, block.timestamp){
        require(value * 10 ** 18 <= getTotalTokens(_address), "Insufficient tokens!");
        uint256 amount = value * 10 ** 18;

        //If unclaimed balance has sufficient tokens
        if(amount <= userBalance[_address]) {
            userBalance[_address] -= amount;
        }
        else {
            //Deduct from unclaim balance and transfer the remaining
            amount -= userBalance[_address];
            _transfer(_address, address(this), amount);
        }

    }

    //Claim all tokens (only for unstaking)
    function claimTokenForUser(address _address) private updateBalance(_address, block.timestamp){ 
        _transfer(address(this), _address, userBalance[_address]);
        userBalance[_address] = 0;
    }


    //Claim a specific amount of tokens
    function claimToken(uint256 _amount) public callerIsUser updateBalance(msg.sender, block.timestamp){ 
        require(_amount * 10 ** 18 <= getUnclaimedBalance(msg.sender), "Invalid amount to claim!");
        userBalance[msg.sender] -= _amount * 10 **18;
        _transfer(address(this), msg.sender, _amount * 10 **18);
    }


    //Owner functions
    function airdrop(address[] memory _addresses, uint256[] memory _amounts) public onlyOwner {
        require(_addresses.length == _amounts.length, "Number of addresses and token amounts is not equal");
        for (uint256 counter = 0; counter < _addresses.length; counter ++) {
            userBalance[_addresses[counter]] += _amounts[counter] * 10 ** 18;
        }
    }


    function withdrawTokens(address _to, uint256 _amount) public onlyOwner {
        _transfer(address(this), _to, _amount * 10 ** 18);
    }
    
    
}