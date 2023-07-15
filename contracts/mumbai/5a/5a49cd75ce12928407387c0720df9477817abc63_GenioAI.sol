/**
 *Submitted for verification at polygonscan.com on 2023-07-15
*/

// SPDX-License-Identifier: GPL-3.0

/**
*
*   ,d888888b   8888888888  88\\     88    88  ,d888888b,                                             
*   88     88   88          88 \\    88    88  88      88                                     
*   88          88888888    88  \\   88    88  88      88                                      
*   88  d8888   88          88   \\  88    88  88      88  
*   88     88   88          88    \\ 88    88  88      88  
*.  'd88bd888   8888888888  88     \\88    88  `d88888Pb'      
*                                                     
*                                                     
*
* 
**/


pragma solidity ^0.8.18;


interface IERC20 {function transfer(address _to, uint256 _value) external returns (bool);}

contract GenioAI{ 

    event InvestorCreated(address donor);
    event Upgrade(address indexed beneficiary, string indexed actionType,uint created);
    event Mode(string indexed actionType,uint created);
    event Registration(address indexed donor,string  actionType, uint _referral, uint256 created);
    event RefundSystem(address indexed donor,string  actionType, uint _referral, uint256 created);
    event Adam(address indexed donor,string  actionType, uint _referral, uint256 created);
    event TransferReceived(address sender, uint value);

    address payable public owner;
    uint256 public balance;
    constructor(){owner = payable(msg.sender);}
    
    struct  Donor {
        bool is_exists; string role; uint referral; address upline; 
        uint level; uint recycle; address left_leg; address right_leg; 
        string left; string right; address myaddress; address pivotAddress;
    }

    struct  RecentState {
        uint dna; string role; uint referral; address upline;  uint level;  
        uint recycle; address left_leg;  address right_leg; string left;  
        string right;  address myaddress; address pivotAddress; uint uplineDNA;
    }


    struct Earnings {uint myEarning; uint myReward; uint regTime;}

    struct Teamup {address topUp; }

    struct RefTrack {uint ref;address user; }

    struct Refunds {address donor; uint regTime;}

    struct Trajectory {
        uint id; address upline; uint level; uint recycle; uint uplineDNA;
        address left_leg; address right_leg; address myaddress; uint referral;
        string status; address pivotAddress; uint leftDNA; uint rightDNA;
    }


    struct Irregularities {address user; address downlineL; address downlineR; uint left; uint right;}
    
    uint256 public totalEarnings;
    uint public lastUserId      = 0;
    uint public lastUserId_     = 0;
    uint public numberOfCycles  = 0;
    uint public apiCall         = 1;
    uint256 public dna          = 0;
    uint  public domain         = 2;
    bool  public toggle         = true;
    bool  public switchTransfer = false;
    uint256 public Earns;

    mapping (address => Donor) public donors;
    mapping (address => RecentState) public state;
    mapping (address => Earnings) public earnings;
    mapping (address => Teamup) public teamingup;
    mapping (address => Refunds) public refundMe;
    mapping (uint    => Trajectory[]) public traject;
    mapping (uint    => RefTrack[]) public track;

    mapping (address => Irregularities) public irregular;

    uint pay_1 = 0;
    uint pay_2 = 5e18;
    uint pay_3 = 10e18;
    uint pay_4 = 10e18;
    uint pay_5 = 10e18;
    uint pay_6 = 20e18;
    uint pay_7 = 40e18;
    uint pay_8 = 230e18;

    uint reward_1 = 1e17 ;
    uint reward_2 = 2e17 ;
    uint reward_3 = 3e17 ;
    uint reward_4 = 4e17 ; 
    uint reward_5 = 5e17 ;
    uint reward_6 = 6e17 ;
    uint reward_7 = 7e17 ;
    uint reward_8 = 8e17 ;

    modifier superGenio() {require(msg.sender == owner, "Transaction not coming from Genio!"); _;}
    receive() payable external {} 

    function isUserExists(address user) public view returns (bool) {if(donors[user].referral != 0){ return true;}else{return false; }}
   
    function Cycles() public view returns (uint) {return numberOfCycles;}

    function numberOfAccount() public view returns (uint) {
        return lastUserId;
    }

    function dnaCall() public superGenio view returns (uint) {
        return dna;
    }

    function getReward(address user) public view returns (uint){
        return earnings[user].myReward;
    }

    function createDonor(address _upline, address _donor, uint _referral) superGenio external {
        require(_donor != _upline, "You can not be under yourself");
        require(donors[_donor].is_exists == false, "You have a running contract");

        uint numberOfAccount_ = numberOfAccount() + 1;

        if(lastUserId_ == 0){
            
            donors[_donor].left = "empty";
            donors[_donor].right = "empty";
            donors[_donor].is_exists = true;
            donors[_donor].referral =  0;
            donors[_donor].level = 1;
            donors[_donor].recycle = 0;
            donors[_donor].role = "genio";
            donors[_donor].myaddress = _donor;
            donors[_donor].upline = owner;
            earnings[_donor].myEarning = 0;
            earnings[_donor].regTime = block.timestamp;
            
            state[_donor].left = "empty";
            state[_donor].right = "empty";
            state[_donor].referral =  0;
            trackRef (0, _donor);
            state[_donor].level = 1;
            state[_donor].recycle = 0;
            state[_donor].role = "genio";
            state[_donor].myaddress = _donor;
            state[_donor].upline = owner;
            state[_donor].uplineDNA = 0;
            state[_donor].dna = dnaCall()+1;
            lastUserId_++;
            Add2Tree(dnaCall()+1, owner,1, 0,0,address(0), address(0),_donor,0,"",address(0), 0, 0);
            dna ++;
            emit Adam(_donor,"First Bloodline line created",lastUserId_ + 1, block.timestamp);
            emit Adam(_donor,"Adam's state [Active]",lastUserId_ + 1, block.timestamp);

            
        }else{


        require(_donor != owner, "Genio is not allowed to particpate in the Donations");
            
            uint myDNA = dnaCall()+1;
            if (keccak256(abi.encodePacked("empty")) == keccak256(abi.encodePacked(donors[_upline].left))) {
                donors[_donor].is_exists = true;
                donors[_donor].referral =  numberOfAccount_;
                donors[_donor].level = 1;
                donors[_donor].left = "empty";
                donors[_donor].right = "empty";
                donors[_donor].role = "user";
                donors[_donor].myaddress = _donor;
                donors[_donor].upline = _upline;
                donors[_upline].left = "closed";
                donors[_upline].left_leg = _donor;
                trackRef (numberOfAccount_, _donor);
                lastUserId++;
                earnings[_donor].myEarning = 0;
                earnings[_donor].regTime = block.timestamp;
                
                uint upline_dna = state[_upline].dna;
                Add2Tree(myDNA, _upline,1, 0,upline_dna,address(0), address(0),_donor,numberOfAccount_,"",address(0),0,0);
                
                traject[upline_dna][0].left_leg = _donor;
                traject[upline_dna][0].leftDNA = myDNA;
                state[_donor].right = "empty";
                state[_donor].referral =  numberOfAccount_;
                state[_donor].level = 1;
                state[_donor].recycle = 0;
                state[_donor].role = "genio";
                state[_donor].myaddress = _donor;
                state[_donor].upline = _upline;
                state[_donor].dna = myDNA;
                state[_upline].left = "closed";
                state[_upline].left_leg = _donor;
                state[_donor].uplineDNA = upline_dna;
                dna ++;
                emit Registration(_donor,"New Born",lastUserId + 1, block.timestamp);

            }else{

                if (keccak256(abi.encodePacked("empty")) == keccak256(abi.encodePacked(donors[_upline].right))) {
                    donors[_donor].is_exists = true;
                    donors[_donor].referral =  numberOfAccount_;
                    donors[_donor].level = 1;
                    donors[_donor].role = "user";
                    donors[_donor].myaddress = _donor;
                    donors[_donor].left = "empty";
                    donors[_donor].right = "empty";
                    donors[_donor].upline = _upline;
                    donors[_upline].right = "closed";
                    donors[_upline].right_leg = _donor;
                    trackRef (numberOfAccount_, _donor);
                    lastUserId++;
                    earnings[_donor].myEarning = 0;
                    earnings[_donor].regTime = block.timestamp;
                    uint upline_dna = state[_upline].dna;
                    Add2Tree(myDNA, _upline,1, 0,upline_dna,address(0), address(0),_donor,numberOfAccount_,"",address(0),0,0);
                    
                    traject[upline_dna][0].right_leg = _donor;
                    traject[upline_dna][0].rightDNA = myDNA;
                    state[_donor].referral =  numberOfAccount_;
                    state[_donor].level = 1;
                    state[_donor].recycle = 0;
                    state[_donor].role = "genio";
                    state[_donor].myaddress = _donor;
                    state[_donor].upline = _upline;
                    state[_donor].dna = myDNA;
                    state[_upline].right = "closed";
                    state[_upline].right_leg = _donor;
                    state[_donor].uplineDNA = upline_dna;
                    dna ++;
                    emit Registration(_donor,"New Born",lastUserId + 1, block.timestamp);

                }
       
       
            }

            if (keccak256(abi.encodePacked("closed")) == keccak256(abi.encodePacked(donors[_upline].left))) {

                if (keccak256(abi.encodePacked("closed")) == keccak256(abi.encodePacked(donors[_upline].right))) {
                  
                    traject[myDNA][0].pivotAddress = _upline;
                    upgrade(_upline,_donor,myDNA,state[_upline].dna);
                    emit Registration(_donor,"New Registration",_referral, block.timestamp);
                }

            }


        }

        
    }

    function upgrade(address _upline, address _donor, uint myDNA, uint upline_dna) internal {
        apiCall++;
        if(traject[upline_dna][0].left_leg != address(0)){

            if(traject[upline_dna][0].right_leg != address(0)){

                    if(traject[upline_dna][0].upline  ==  owner){
                        traject[myDNA][0].pivotAddress = address(0);
                        donors[_donor].pivotAddress = address(0);
                        emit Upgrade(_upline,"End of a row call", block.timestamp);
                    }else{
                        if(traject[upline_dna][0].level == 1){
                            traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                            donors[_donor].pivotAddress = donors[_upline].upline;
                            earnings[_upline].myEarning = earnings[_upline].myEarning + 0;
                            earnings[_upline].myReward = earnings[_upline].myReward + reward_1;
                            traject[upline_dna][0].level = 2;
                            state[_upline].level = 2;
                            donors[_upline].level = 2;
                            Earns = Earns +  10;
                            emit Upgrade(_upline,"New Level 2", block.timestamp);
                            upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
   
                        }else if(traject[upline_dna][0].level == 2){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;
                            uint level = 2;

                            if((traject[left][0].level == level) && (traject[right][0].level == level)){
                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;
                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);
                            }else{

                                Irregular(_upline,_donor,myDNA,upline_dna);


                            }

                        }else if(traject[upline_dna][0].level == 3){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;
                            uint level = 3;

                            if((traject[left][0].level== level) && (traject[right][0].level == level)){

                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;

                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);

                            }else{

                                Irregular(_upline,_donor,myDNA,upline_dna);


                                // traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                // donors[_donor].pivotAddress = donors[_upline].upline;
                                // upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);

                            }



                        }else if(traject[upline_dna][0].level == 4){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;
                            uint level = 4;

                            if((traject[left][0].level == level) && (traject[right][0].level == level)){

                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;

                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);

                            }else{

                                Irregular(_upline,_donor,myDNA,upline_dna);

                            }



                        }else if(traject[upline_dna][0].level == 5){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;
                            uint level = 5;

                            if((traject[left][0].level == level) && (traject[right][0].level == level)){

                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;

                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);

                            }else{
                                 Irregular(_upline,_donor,myDNA,upline_dna);

                                // traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                // donors[_donor].pivotAddress = donors[_upline].upline;
                                // upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);

                            }




                        }else if(traject[upline_dna][0].level == 6){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;
                            uint level = 6;

                            if((traject[left][0].level == level) && (traject[right][0].level == level)){

                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;

                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);

                            }else{
                                
                                Irregular(_upline,_donor,myDNA,upline_dna);

                                

                            }




                        }else if(traject[upline_dna][0].level == 7){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;
                            uint level = 7;

                            if((traject[left][0].level == level) && (traject[right][0].level == level)){

                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;

                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);

                            }else{

                                 Irregular(_upline,_donor,myDNA,upline_dna);


                            }


                        }else if(traject[upline_dna][0].level == 8){

                            uint left       = traject[upline_dna][0].leftDNA;
                            uint right      = traject[upline_dna][0].rightDNA;
                            uint LEFTdna    = traject[left][0].level;
                            uint RIGHTdna   = traject[right][0].level;
                            if((LEFTdna == 8) && (RIGHTdna == 8)){
                                if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[right][0].status)) && keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[left][0].status))) {
                                    traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                    donors[_donor].pivotAddress = donors[_upline].upline;
                                    upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                                }else{

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {
                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                                    }else{
                                        traject[upline_dna][0].level      = 8;
                                        state[_upline].level              = 1;
                                        donors[_upline].level             = 1;
                                        state[_upline].recycle            = state[_upline].recycle + 1;
                                        traject[upline_dna][0].status     = "completed";
                                        totalEarnings                     = totalEarnings + 230;
                                        earnings[_upline].myEarning       = earnings[_upline].myEarning +  230;
                                        earnings[_upline].myReward        = earnings[_upline].myReward + reward_8;
                                        donors[_upline].recycle           = donors[_upline].recycle + 1;
                                        donors[_upline].left_leg          = address(0);
                                        donors[_upline].right_leg         = address(0);
                                        state[_upline].left_leg           = address(0);
                                        state[_upline].right_leg          = address(0);
                                        donors[_upline].left              = "empty";
                                        donors[_upline].right             = "empty";
                                        donors[_upline].pivotAddress      = address(0);
                                        Earns                             = Earns +  240;
                                        numberOfCycles                    = numberOfCycles + 1;
                                        irregular[_upline].right          = 0;
                                        irregular[_upline].left           = 0;
                                        if(switchTransfer == true){
                                            sendDai(_upline,pay_8); 
                                        }
                                        updateStates(_upline,_donor);
                                    }
                                }
                            }else{
                                traject[myDNA][0].pivotAddress  = traject[upline_dna][0].upline;
                                donors[_donor].pivotAddress     = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                            }

                        }else{
                            traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                            donors[_donor].pivotAddress = donors[_upline].upline;
                            upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                            
                        }
                    
                    } 

            }else{

                traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                donors[_donor].pivotAddress = donors[_upline].upline;
                uint Ups = traject[upline_dna][0].uplineDNA;
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);
            }
        
        }else{

            traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
            donors[_donor].pivotAddress = donors[_upline].upline;
            uint Ups = traject[upline_dna][0].uplineDNA;
            upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);
            
        }
         
         

    }

    function  withdrawGNT (address user, uint256 amount) superGenio public returns(bool){
        require(earnings[user].myReward > amount, "Insufficient Balance");
        if(earnings[user].myReward < amount){
            return false;
        }else{
            earnings[user].myReward = earnings[user].myReward - amount;
            return true;
        }
        
    }

    function sendDai(address _to, uint256 _amount) superGenio private  {
         require(_to != address(0));
         IERC20 dai = IERC20(address(0xf1391810048c261bDe4160AF2d98790DADEc3584));
         dai.transfer(_to, _amount);
    }


    function refundSystem(address _to, uint256 _amount) superGenio public {
        require(msg.sender == owner, "Opps something is wrong");
        if(keccak256(abi.encodePacked("user")) == keccak256(abi.encodePacked(donors[msg.sender].role))){

        }else{
            if(msg.sender == owner){
                sendDai(_to, _amount);
            }else{

            }
        }
    }
 

    function failedContract(address _to) superGenio external returns (bool){
        sendDai(_to, 5e18);
        return true;
    }

    function flex(address _to,uint256 amt ) superGenio external returns (bool){
        sendDai(_to, amt);
        return true;
    }

    function Add2Tree ( uint id,  address upline, uint level, uint recycle, uint uplineDNA, address left_leg, address right_leg, address myaddress, uint referral, string memory status, address pivotAddress, uint rightDNA, uint leftDNA) internal {
        traject[id].push(Trajectory(id, upline, level, recycle, uplineDNA,left_leg, right_leg, myaddress, referral, status, pivotAddress, leftDNA, rightDNA));
    }

    function trackRef ( uint id,  address user) internal {
        track[id].push(RefTrack(id, user));
    }

    function toggling() internal {
        if(toggle == true){
            toggle = false;
        }else{
            toggle = true;
        }
    }

    function getNewUpline(uint newUplineDNA) public superGenio view returns (uint){
        uint LEFT  = traject[newUplineDNA][0].leftDNA;
        uint RIGHT = traject[newUplineDNA][0].rightDNA;
        if(LEFT == 0){
            return newUplineDNA;
        }else if(RIGHT == 0){
            return newUplineDNA;
        }else{
            uint l_level =  traject[LEFT][0].level;
            uint r_level =  traject[RIGHT][0].level;
            if(l_level > r_level){
                return getNewUpline(RIGHT);
            }else if(l_level == r_level){
                if(toggle){
                    return getNewUpline(LEFT);
                }else{
                    return getNewUpline(RIGHT);
                }
            }else{
                return getNewUpline(LEFT);
            }
        }
    }
   
    function setDomain (uint _domain) public superGenio {
        address uplineAddress = traject[_domain][0].myaddress;
        domain = state[uplineAddress].dna;
    }

    function updateStates(address _upline, address _donor) internal superGenio{
       uint newDNA                   = dnaCall()+1;
       uint upline_new               = getNewUpline(domain);
       toggling();
       address uplineAddress         = traject[upline_new][0].myaddress;
       state[_upline].upline         = uplineAddress;
       state[_upline].dna            = newDNA;
       donors[_upline].upline        = uplineAddress;
       state[_upline].uplineDNA      = upline_new;
       dna ++;
       Add2Tree(newDNA, uplineAddress,1, donors[_upline].recycle,upline_new,address(0), address(0),_upline,donors[_upline].referral,"",address(0),0,0);
       traject[newDNA][0].upline = uplineAddress;
       if(traject[upline_new][0].leftDNA == 0){ 
           
           
           traject[upline_new][0].leftDNA  = newDNA;
           traject[upline_new][0].left_leg = _upline;
           state[uplineAddress].left_leg   = _upline;
           donors[uplineAddress].left_leg  = _upline;
           state[uplineAddress].left       = "closed";
           donors[uplineAddress].left      = "closed";

          

       }else if(traject[upline_new][0].rightDNA == 0){
           
           traject[upline_new][0].rightDNA   = newDNA;
           traject[upline_new][0].right_leg  = _upline;
           state[uplineAddress].right_leg    = _upline;
           donors[uplineAddress].right_leg   = _upline;
           state[uplineAddress].right        = "closed";
           donors[uplineAddress].right       = "closed";

          
       }

       traject[newDNA][0].pivotAddress   = traject[newDNA][0].upline;
       donors[_donor].pivotAddress       = donors[_upline].upline;
       upgrade(donors[_donor].pivotAddress,_donor,newDNA,upline_new);
       emit Upgrade(_upline,"New Level 1 is Recycled", block.timestamp);

    }


    function dischargeDuty(address _upline, address _donor, uint myDNA, uint upline_dna, uint level) internal superGenio {
        traject[upline_dna][0].level = level+1;
        state[_upline].level = level+1;
        donors[_upline].level = level+1;
        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
        donors[_donor].pivotAddress = donors[_upline].upline;

        // update downline levels
        if(level == 2){
            totalEarnings = totalEarnings +  5;
            Earns = Earns +  20;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 5;
            earnings[_upline].myReward = earnings[_upline].myReward + reward_2;
            if(switchTransfer == true){
                sendDai(_upline,pay_2);
            }
            emit Upgrade(_upline,"New Level 3", block.timestamp);
        }if(level == 3){
            totalEarnings = totalEarnings +  10;
            Earns = Earns +  30;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
            earnings[_upline].myReward = earnings[_upline].myReward + reward_3;
            if(switchTransfer == true){
                sendDai(_upline,pay_3);
            }
            emit Upgrade(_upline,"New Level 4", block.timestamp);
        }if(level == 4){
            totalEarnings = totalEarnings +  10;
            Earns = Earns +  40;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
            earnings[_upline].myReward = earnings[_upline].myReward + reward_4;
            if(switchTransfer == true){
                sendDai(_upline,pay_4);
            }
            emit Upgrade(_upline,"New Level 5", block.timestamp);
        }if(level == 5){
            totalEarnings = totalEarnings +  10;
            Earns = Earns +  60;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
            earnings[_upline].myReward = earnings[_upline].myReward + reward_5;
            if(switchTransfer == true){
                sendDai(_upline,pay_5);
            }
            emit Upgrade(_upline,"New Level 6", block.timestamp);
        }if(level == 6){
            totalEarnings = totalEarnings +  20;
            Earns = Earns +  100;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 20;
            earnings[_upline].myReward = earnings[_upline].myReward + reward_6;
            if(switchTransfer == true){
                sendDai(_upline,pay_6);
            }
            emit Upgrade(_upline,"New Level 7", block.timestamp);
        }if(level == 7){
            totalEarnings = totalEarnings +  40;
            Earns = Earns +  160;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 40;
            earnings[_upline].myReward = earnings[_upline].myReward + reward_7;
            if(switchTransfer == true){
               sendDai(_upline,pay_7);
            }
            emit Upgrade(_upline,"New Level 8", block.timestamp);
        }
        
        uint lftDNA = traject[upline_dna][0].level ;
        uint rgtDNA = traject[upline_dna][0].level;
        irregular[_upline].right  = rgtDNA;
        irregular[_upline].left  = lftDNA;


        uint Ups = traject[upline_dna][0].uplineDNA;
        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

    }



    function Irregular(address _upline, address _donor, uint myDNA, uint upline_dna) internal superGenio {
        
        uint left = traject[upline_dna][0].leftDNA;
        uint right = traject[upline_dna][0].rightDNA;
        // uint level = traject[upline_dna][0].level;
        
        if((traject[right][0].level) < (traject[left][0].level) ){
            uint rightLevel = irregular[_upline].right ;
            uint lvl = traject[right][0].level;

            if(rightLevel == lvl){
                dischargeDuty(_upline,_donor,myDNA,upline_dna,lvl);
            }else if(lvl > rightLevel){
                dischargeDuty(_upline,_donor,myDNA,upline_dna,lvl);
            }else{
                traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                donors[_donor].pivotAddress = donors[_upline].upline;
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                
            }

        }else if((traject[left][0].level) < (traject[right][0].level) ){

            uint leftLevel = irregular[_upline].left ;
            uint lvl = traject[left][0].level;

            if(leftLevel == lvl){
                

                dischargeDuty(_upline,_donor,myDNA,upline_dna,lvl);
                

            }else if(lvl > leftLevel){


                dischargeDuty(_upline,_donor,myDNA,upline_dna,lvl);

            }else{

                traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                donors[_donor].pivotAddress = donors[_upline].upline;
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                
            }
            

        }else{


                traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                donors[_donor].pivotAddress = donors[_upline].upline;
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);

        }



    }


    function switchTransfers () superGenio external returns (bool){
       if(switchTransfer == true){
           switchTransfer = false;
       }else{
            switchTransfer = true;
       }
       return true;
    }

    function updateUsersLevel(address user, uint level) superGenio external returns (bool){
        state[user].level = level;
        uint dna_ = state[user].dna;
        traject[dna_][0].level = level;
        donors[user].level = level;
        return true;
    }

    function recycleUserWithPay(address user) superGenio external returns (bool){
        uint upline_dna = state[user].dna;

        traject[upline_dna][0].level   = 8;
        state[user].level              = 1;
        donors[user].level             = 1;
        state[user].recycle            = state[user].recycle + 1;
        traject[upline_dna][0].status  = "completed";
        totalEarnings                  = totalEarnings + 230;
        earnings[user].myEarning       = earnings[user].myEarning +  230;
        earnings[user].myReward        = earnings[user].myReward + reward_8;
        donors[user].recycle           = donors[user].recycle + 1;
        donors[user].left_leg          = address(0);
        donors[user].right_leg         = address(0);
        state[user].left_leg           = address(0);
        state[user].right_leg          = address(0);
        donors[user].left              = "empty";
        donors[user].right             = "empty";
        donors[user].pivotAddress      = address(0);
        Earns                          = Earns +  240;
        numberOfCycles                 = numberOfCycles + 1;
        irregular[user].right          = 0;
        irregular[user].left           = 0;
        if(switchTransfer == true){
             sendDai(user,pay_8);
        }

        recycleUser(user);
        return true;
    }

    function recycleUserNoPay(address user) superGenio external returns (bool){
        uint upline_dna = state[user].dna;

        traject[upline_dna][0].level   = 8;
        state[user].level              = 1;
        donors[user].level             = 1;
        state[user].recycle            = state[user].recycle + 1;
        traject[upline_dna][0].status  = "completed";
        donors[user].recycle           = donors[user].recycle + 1;
        donors[user].left_leg          = address(0);
        donors[user].right_leg         = address(0);
        state[user].left_leg           = address(0);
        state[user].right_leg          = address(0);
        donors[user].left              = "empty";
        donors[user].right             = "empty";
        donors[user].pivotAddress      = address(0);
        Earns                          = Earns +  240;
        numberOfCycles                 = numberOfCycles + 1;
        irregular[user].right          = 0;
        irregular[user].left           = 0;

        recycleUser(user);


        return true;
    }

    function recycleUser(address user) superGenio internal returns (bool){
        uint newDNA                   = dnaCall()+1;
        uint upline_new               = getNewUpline(domain);
        toggling();
        address uplineAddress         = traject[upline_new][0].myaddress;
        state[user].upline         = uplineAddress;
        state[user].dna            = newDNA;
        donors[user].upline        = uplineAddress;
        state[user].uplineDNA      = upline_new;
        dna ++;
        uint ref = donors[user].referral;
        uint cycle =  donors[user].recycle;
        Add2Tree(newDNA, uplineAddress,1, cycle,upline_new,address(0), address(0),user,ref,"",address(0),0,0);
        traject[newDNA][0].upline = uplineAddress;
        return true;
    }


    function Bridge(address _upline, address _donor, uint _referral) superGenio external {
        require(_donor != _upline, "You can not be under yourself");
        require(donors[_donor].is_exists == false, "You have a running contract");

        uint numberOfAccount_ = numberOfAccount() + 1;

        if(lastUserId_ == 0){
            
            donors[_donor].left = "empty";
            donors[_donor].right = "empty";
            donors[_donor].is_exists = true;
            donors[_donor].referral =  0;
            donors[_donor].level = 1;
            donors[_donor].recycle = 0;
            donors[_donor].role = "genio";
            donors[_donor].myaddress = _donor;
            donors[_donor].upline = owner;
            earnings[_donor].myEarning = 0;
            earnings[_donor].regTime = block.timestamp;
            
            state[_donor].left = "empty";
            state[_donor].right = "empty";
            state[_donor].referral =  0;
            trackRef (0, _donor);
            state[_donor].level = 1;
            state[_donor].recycle = 0;
            state[_donor].role = "genio";
            state[_donor].myaddress = _donor;
            state[_donor].upline = owner;
            state[_donor].uplineDNA = 0;
            state[_donor].dna = dnaCall()+1;
            lastUserId_++;
            Add2Tree(dnaCall()+1, owner,1, 0,0,address(0), address(0),_donor,0,"",address(0), 0, 0);
            dna ++;
            emit Adam(_donor,"First Bloodline line created",lastUserId_ + 1, block.timestamp);
            emit Adam(_donor,"Adam's state [Active]",lastUserId_ + 1, block.timestamp);

            
        }else{


        require(_donor != owner, "Genio is not allowed to particpate in the Donations");
            
            uint myDNA = dnaCall()+1;
            if (keccak256(abi.encodePacked("empty")) == keccak256(abi.encodePacked(donors[_upline].left))) {
                donors[_donor].is_exists = true;
                donors[_donor].referral =  numberOfAccount_;
                donors[_donor].level = 1;
                donors[_donor].left = "empty";
                donors[_donor].right = "empty";
                donors[_donor].role = "user";
                donors[_donor].myaddress = _donor;
                donors[_donor].upline = _upline;
                donors[_upline].left = "closed";
                donors[_upline].left_leg = _donor;
                trackRef (numberOfAccount_, _donor);
                lastUserId++;
                earnings[_donor].myEarning = 0;
                earnings[_donor].regTime = block.timestamp;
                
                uint upline_dna = state[_upline].dna;
                Add2Tree(myDNA, _upline,1, 0,upline_dna,address(0), address(0),_donor,numberOfAccount_,"",address(0),0,0);
                
                traject[upline_dna][0].left_leg = _donor;
                traject[upline_dna][0].leftDNA = myDNA;
                state[_donor].right = "empty";
                state[_donor].referral =  numberOfAccount_;
                state[_donor].level = 1;
                state[_donor].recycle = 0;
                state[_donor].role = "genio";
                state[_donor].myaddress = _donor;
                state[_donor].upline = _upline;
                state[_donor].dna = myDNA;
                state[_upline].left = "closed";
                state[_upline].left_leg = _donor;
                state[_donor].uplineDNA = upline_dna;
                dna ++;
                emit Registration(_donor,"New Born",lastUserId + 1, block.timestamp);

            }else{

                if (keccak256(abi.encodePacked("empty")) == keccak256(abi.encodePacked(donors[_upline].right))) {
                    donors[_donor].is_exists = true;
                    donors[_donor].referral =  numberOfAccount_;
                    donors[_donor].level = 1;
                    donors[_donor].role = "user";
                    donors[_donor].myaddress = _donor;
                    donors[_donor].left = "empty";
                    donors[_donor].right = "empty";
                    donors[_donor].upline = _upline;
                    donors[_upline].right = "closed";
                    donors[_upline].right_leg = _donor;
                    trackRef (numberOfAccount_, _donor);
                    lastUserId++;
                    earnings[_donor].myEarning = 0;
                    earnings[_donor].regTime = block.timestamp;
                    uint upline_dna = state[_upline].dna;
                    Add2Tree(myDNA, _upline,1, 0,upline_dna,address(0), address(0),_donor,numberOfAccount_,"",address(0),0,0);
                    
                    traject[upline_dna][0].right_leg = _donor;
                    traject[upline_dna][0].rightDNA = myDNA;
                    state[_donor].referral =  numberOfAccount_;
                    state[_donor].level = 1;
                    state[_donor].recycle = 0;
                    state[_donor].role = "genio";
                    state[_donor].myaddress = _donor;
                    state[_donor].upline = _upline;
                    state[_donor].dna = myDNA;
                    state[_upline].right = "closed";
                    state[_upline].right_leg = _donor;
                    state[_donor].uplineDNA = upline_dna;
                    dna ++;
                    emit Registration(_donor,"New Born",lastUserId + 1, block.timestamp);

                }
       
       
            }

            if (keccak256(abi.encodePacked("closed")) == keccak256(abi.encodePacked(donors[_upline].left))) {

                if (keccak256(abi.encodePacked("closed")) == keccak256(abi.encodePacked(donors[_upline].right))) {
                  
                    traject[myDNA][0].pivotAddress = _upline;
                    upgrade(_upline,_donor,myDNA,state[_upline].dna);
                    emit Registration(_donor,"New Registration",_referral, block.timestamp);
                }

            }


        }

        
    }

    function updateUsersLegs(address user, address left, address replace) superGenio external returns (bool){
        
        // state[user].dna;
        // uint dna_ = state[user].dna;
        // traject[dna_][0].level = level;
        // donors[user].level = level;
        // return true;

    }







    
}