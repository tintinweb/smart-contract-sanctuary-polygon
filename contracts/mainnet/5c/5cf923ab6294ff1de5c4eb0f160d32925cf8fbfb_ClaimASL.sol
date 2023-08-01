// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract ClaimASL is Ownable, ReentrancyGuard {
    // ============= VARIABLES ============

    // Contract address of the staked token
    IERC20 public immutable claimToken;
    // Timestamp of when the rewards start
    uint256 public StartLockDate;

    uint256 public LockDuration = 50 days;

    uint256 public ClaimDuration = 28 days;

    uint256 public laps_duration = 7 days;

    mapping(address => uint) public userLastClaim;

    mapping(address => bool) public userIsWhitelisted;

    mapping(address => uint) public userStartLockPeriod;

    mapping(address => uint) public userStartClaimPeriod;

    mapping(address => uint) public userEndClaimPeriod;

    mapping(address => uint) public userTokensToClaimPerDay;

    mapping(address => uint) public userTokensToClaim;

    mapping(address => uint) public userTokensClaimed;

    constructor(
        address _claimToken
    ) {
        claimToken = IERC20(_claimToken);
        StartLockDate=block.timestamp;
    }

    // ============= MODIFIERS ============

    modifier checkBeforeEndLockup {
      require ( block.timestamp < StartLockDate + LockDuration ) ;
      _ ;
    }

    modifier update_userData(address _account) {

        if (_account != address(0)) {
            if(userIsWhitelisted[_account]==true){
                userStartClaimPeriod[_account]=userStartLockPeriod[_account]+LockDuration;
                userTokensToClaim[_account]=userTokensToClaimPerDay[_account]*(LockDuration/86400);
                userEndClaimPeriod[_account]=userStartClaimPeriod[_account]+ClaimDuration;
                if(userLastClaim[_account]==0){
                    userLastClaim[_account]=userStartClaimPeriod[_account];
                }
            }
        }
        _;
    }

    event StartLockupEvent( address indexed _user);
    event Add_Users_List( uint256[] listTokensToClaimPerDay, address[] indexed listAddress);
    event Change_Tokens_Users_List( uint256[] listTokensToClaimPerDay, address[] indexed listAddress);
    event Remove_Users_List( address[] indexed listAddress);

    // ============= FUNCTIONS ============

     // Function that whitelist users. The claiming period lasts 1000 days.
    function add_Users_Claiming_List(uint256[] calldata listTokensToClaimPerDay, address[] calldata listAddress) onlyOwner public returns (bool) {
        require(listTokensToClaimPerDay.length==listAddress.length);
        for(uint i;i<listAddress.length;i++){
            address address_user=listAddress[i];
            uint256 tokensPerDay_user=listTokensToClaimPerDay[i];
            // only users who are not whitelisted yet can be added
            if(userIsWhitelisted[address_user]==false){
                userIsWhitelisted[address_user]=true;
                userTokensToClaimPerDay[address_user]=tokensPerDay_user;
            }
        }
        emit Add_Users_List(listTokensToClaimPerDay, listAddress);
        return true;
    }

    // To correct the number of tokens assigned to a Wallet
    function change_Users_TokensToClaimPerDay(uint256[] calldata listTokensToClaimPerDay, address[] calldata listAddress) onlyOwner public returns (bool) {
        require(listTokensToClaimPerDay.length==listAddress.length);
        for(uint i;i<listAddress.length;i++){
            address address_user=listAddress[i];
            uint256 new_tokens_user=listTokensToClaimPerDay[i];
            if(userIsWhitelisted[address_user]==true){
                userTokensToClaimPerDay[address_user]=new_tokens_user;
                if(new_tokens_user==0){
                    userIsWhitelisted[address_user]=false;
                    userLastClaim[address_user]=0;
                    userStartLockPeriod[address_user]=0;
                    userTokensToClaimPerDay[address_user]=0;
                    userTokensClaimed[address_user]=0;
                    userStartClaimPeriod[address_user]=0;
                    userEndClaimPeriod[address_user]=0;
                    userTokensToClaim[address_user]=0;
                }
            }
        }
        emit Change_Tokens_Users_List(listTokensToClaimPerDay, listAddress);
        return true;
    }

    // To remove a Wallet from the whitelist
    function remove_from_List(address[] calldata listAddress) onlyOwner public returns (bool) {
        for(uint i;i<listAddress.length;i++){
            address address_user=listAddress[i];
            userIsWhitelisted[address_user]=false;
            userLastClaim[address_user]=0;
            userStartLockPeriod[address_user]=0;
            userTokensToClaimPerDay[address_user]=0;
            userTokensClaimed[address_user]=0;
            userStartClaimPeriod[address_user]=0;
            userEndClaimPeriod[address_user]=0;
            userTokensToClaim[address_user]=0;
        }
        emit Remove_Users_List(listAddress);
        return true;
    }

    function startLockup() public returns (bool) {
        require(userIsWhitelisted[msg.sender]==true,"Not Whitelisted");
        require(userStartLockPeriod[msg.sender]==0,"Lockup Period already started");
        userStartLockPeriod[msg.sender]=block.timestamp;
        emit StartLockupEvent(msg.sender);
        return true;
    }

    function change_LockDuration(uint256 _LockDuration) checkBeforeEndLockup onlyOwner public returns ( bool ) {
        require(block.timestamp<StartLockDate+_LockDuration);
        LockDuration=_LockDuration;
        return true;
    }

    function change_ClaimDuration(uint256 _ClaimDuration) checkBeforeEndLockup onlyOwner public returns ( bool ) {
        ClaimDuration=_ClaimDuration;
        return true;
    }

    function change_laps_duration(uint256 _laps_duration) checkBeforeEndLockup onlyOwner public returns ( bool ) {
        laps_duration=_laps_duration;
        return true;
    }
    
    function Claim() external update_userData(msg.sender) nonReentrant returns (bool) {
        require(userIsWhitelisted[msg.sender]==true,"Not Whitelisted");
        //check on the date of the user
        require ( block.timestamp >= userStartClaimPeriod[msg.sender],"Claim period not started") ;
        //double security
        require(userTokensClaimed[msg.sender]<userTokensToClaim[msg.sender], "All tokens already claimed");
        uint256 now_time=block.timestamp;
        if (now_time>userEndClaimPeriod[msg.sender]) {
            now_time=userEndClaimPeriod[msg.sender];
        }
        //nomber of intervals of time (7 days) since the last claim
        uint256 user_laps_lastUpdate=(now_time-userLastClaim[msg.sender])/(laps_duration);
        require(user_laps_lastUpdate>0,"Nothing to claim");
        //by default, 4 intervals of 7 days ==> 28 days. So division by 4
        uint256 number_laps=ClaimDuration/laps_duration;
        uint256 user_tokens_perLaps=userTokensToClaim[msg.sender]/number_laps;
        //tokens that can be claimed
        uint256 tokens_available=user_laps_lastUpdate*user_tokens_perLaps;
        //save the date of last claim
        userLastClaim[msg.sender]=userLastClaim[msg.sender]+(user_laps_lastUpdate*laps_duration);
        userTokensClaimed[msg.sender]+=tokens_available;

        claimToken.transfer(msg.sender,tokens_available);
        return true;
    }

    function return_To_Owner(uint256 _amount)  external onlyOwner {
        claimToken.transfer(_owner, _amount);
    }

}