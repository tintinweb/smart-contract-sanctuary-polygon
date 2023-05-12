// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC777.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";


contract Sirius_by_Humanity is ERC777, Ownable, ReentrancyGuard {

    mapping(address => bool) public userIsWhitelisted;

    mapping(address => uint) public userLastClaim;

    mapping(address => uint) public userStartClaimPeriod;

    mapping(address => uint) public userEndClaimPeriod;

    mapping(address => uint) public userTokensToClaim;

    mapping(address => uint) public userTokensLeftToClaim;

    constructor(
        address[] memory hps
    )
    ERC777("Sirius by Humanity", "SRS", hps)
    {
        _mint(msg.sender, 11009023*1e18, "","");
    }

    //This function returns the unixtime of the next day 12:00 am. Used when users are whitelisted.Their start claiming period will start there.
    function next_midnight() public view returns (uint256) {
        uint256 now_time=block.timestamp;
        uint256 days_since_1970=now_time/86400;
        uint256 last_midnight= days_since_1970*86400;
        uint256 rest=now_time-last_midnight;
        return now_time + (86400-rest);
    }

    // Function that whitelist users. The claiming period lasts 1000 days.
    function add_Users_Claiming_List(uint256[] memory listTokensToClaim, address[] memory listAdress) onlyOwner public returns (bool) {
        require(listTokensToClaim.length==listAdress.length);
        uint256 users_start_claim_period=next_midnight();
        for(uint i=0;i<listAdress.length;i++){
            address address_user=listAdress[i];
            uint256 tokens_user=listTokensToClaim[i];
            // only users who are not whitelisted yet can be added
            if(userIsWhitelisted[address_user]==false){
                userIsWhitelisted[address_user]=true;
                userStartClaimPeriod[address_user]=users_start_claim_period;
                userEndClaimPeriod[address_user]=userStartClaimPeriod[address_user] + 1000 days;
                userLastClaim[address_user]=userStartClaimPeriod[address_user];
                userTokensLeftToClaim[address_user]=tokens_user*1e18;
                userTokensToClaim[address_user]=userTokensLeftToClaim[address_user];
            }
        }
        return true;
    }

    // To correct the number of tokens assigned to a Wallet
    function change_Users_TokensToClaim(uint256[] memory listTokensToClaim, address[] memory listAdress) onlyOwner public returns (bool) {
        require(listTokensToClaim.length==listAdress.length);
        uint256 users_start_claim_period=next_midnight();
        for(uint i=0;i<listAdress.length;i++){
            address address_user=listAdress[i];
            uint256 new_tokens_user=listTokensToClaim[i]*1e18;
            if(userIsWhitelisted[address_user]==true){
                // The claim period restart for the user, with more tokens
                userStartClaimPeriod[address_user]=users_start_claim_period;
                userEndClaimPeriod[address_user]=userStartClaimPeriod[address_user] + 1000 days;
                userLastClaim[address_user]=userStartClaimPeriod[address_user];
                userTokensToClaim[address_user]=new_tokens_user;
                userTokensLeftToClaim[address_user]=userTokensToClaim[address_user];

                if(new_tokens_user==0){
                    userIsWhitelisted[address_user]=false;
                    userStartClaimPeriod[address_user]=0;
                    userEndClaimPeriod[address_user]=0;
                    userLastClaim[address_user]=0;
                }
            }
        }
        return true;
    }

    // To remove a Wallet from the whitelist
    function remove_from_List(address[] memory listAdress) onlyOwner public returns (bool) {
        for(uint i=0;i<listAdress.length;i++){
            address address_user=listAdress[i];
            userIsWhitelisted[address_user]=false;
            userStartClaimPeriod[address_user]=0;
            userEndClaimPeriod[address_user]=0;
            userLastClaim[address_user]=0;
            userTokensToClaim[address_user]=0;
            userTokensLeftToClaim[address_user]=0;
        }
        return true;
    }

    // Return the number of tokens that a user can claim now
    function TokenAvailableToClaim(address _user) public view returns (uint256){
        if(block.timestamp>userStartClaimPeriod[msg.sender]){
            if (userIsWhitelisted[_user]==false){
                return 0;
            }
            else {
                uint256 user_tokens_perDay=userTokensToClaim[_user]/1000;
                uint256 now_time=block.timestamp;
                if (now_time>userEndClaimPeriod[_user]) {
                    now_time=userEndClaimPeriod[_user];
                }
                //To compute the days past since the last update. 86400 seconds per day
                uint256 user_days_lastUpdate=(now_time-userLastClaim[_user])/86400;
                if (user_days_lastUpdate==0){
                    return 0;
                }
                else{
                    uint256 tokens_available=user_days_lastUpdate*user_tokens_perDay;
                    return tokens_available;
                }
            }
        }
        else{
            return 0;
        }
    }

    // Mint & claim function
    function claim() public nonReentrant returns (bool) {
        require(userIsWhitelisted[msg.sender]==true,"Not Whitelisted");
        require(block.timestamp>userStartClaimPeriod[msg.sender]);
        uint256 user_tokens_perDay=userTokensToClaim[msg.sender]/1000;
        uint256 now_time=block.timestamp;
        if (now_time>userEndClaimPeriod[msg.sender]) {
            now_time=userEndClaimPeriod[msg.sender];
        }
        //To compute the days past since the last update. 86400 seconds per day
        uint256 user_days_lastUpdate=(now_time-userLastClaim[msg.sender])/86400;
        require(user_days_lastUpdate>0,"Nothing to claim");
        uint256 tokens_available=user_days_lastUpdate*user_tokens_perDay;
        _mint(msg.sender, tokens_available, "","");
        userLastClaim[msg.sender]=userLastClaim[msg.sender]+(user_days_lastUpdate*86400);
        userTokensLeftToClaim[msg.sender]-=tokens_available;
        return true;
    }

    function return_To_Owner(uint256 _amount) external onlyOwner {
        this.transfer(msg.sender, _amount);
    }

}