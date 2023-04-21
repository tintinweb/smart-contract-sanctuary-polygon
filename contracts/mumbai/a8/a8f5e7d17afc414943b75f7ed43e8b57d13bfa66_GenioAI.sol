/**
 *Submitted for verification at polygonscan.com on 2023-04-20
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

    struct Refunds {address donor; uint regTime;}

    struct Trajectory {
        uint id; address upline; uint level; uint recycle; uint uplineDNA;
        address left_leg; address right_leg; address myaddress;
        string status; address pivotAddress; uint leftDNA; uint rightDNA;
    }
    
    uint256 public totalEarnings;
    uint public lastUserId      = 0;
    uint public numberOfCycles  = 0;
    uint public apiCall         = 1;
    uint256 public dna          = 0;
    uint  public domain         = 1;
    bool  public toggle         = true;

    mapping (address => Donor) public donors;
    mapping (address => RecentState) public state;
    mapping (address => Earnings) public earnings;
    mapping (address => Teamup) public teamingup;
    mapping (address => Refunds) private refundMe;
    mapping (uint    => Trajectory[]) public traject;

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
    receive() payable external {balance += msg.value;emit TransferReceived(msg.sender, msg.value);} 

    function isUserExists(address user) public view returns (bool) {if(donors[user].referral != 0){ return true;}else{return false; }}
   
    function Cycles() public view returns (uint) {return numberOfCycles;}

    function numberOfAccount() internal superGenio view returns (uint) {
        return lastUserId;
    }

    function dnaCall() internal superGenio view returns (uint) {
        return dna;
    }

    function getReward(address user) public view returns (uint){
        return earnings[user].myReward;
    }

    function createDonor(address _upline, address _donor, uint _referral) superGenio external {
        require(_donor != _upline, "You can not be under yourself");
        require(donors[_donor].is_exists == false, "You have a running contract");

        uint numberOfAccount_ = numberOfAccount() + 1;

        if(lastUserId == 0){
            
            donors[_donor].left = "empty";
            donors[_donor].right = "empty";
            donors[_donor].is_exists = true;
            donors[_donor].referral =  numberOfAccount_;
            donors[_donor].level = 1;
            donors[_donor].recycle = 0;
            donors[_donor].role = "genio";
            donors[_donor].myaddress = _donor;
            donors[_donor].upline = owner;
            earnings[_donor].myEarning = 0;
            earnings[_donor].regTime = block.timestamp;
            
            Add2Tree(dnaCall()+1, owner,1, 0,0,address(0), address(0),_donor,"",address(0), 0, 0);
            
            state[_donor].left = "empty";
            state[_donor].right = "empty";
            state[_donor].referral =  numberOfAccount_;
            state[_donor].level = 1;
            state[_donor].recycle = 0;
            state[_donor].role = "genio";
            state[_donor].myaddress = _donor;
            state[_donor].upline = owner;
            state[_donor].uplineDNA = 0;
            state[_donor].dna = dnaCall()+1;
            lastUserId++;
            dna ++;

            emit Adam(_donor,"Adam",lastUserId + 1, block.timestamp);
            emit Adam(_donor,"First Bloodline line created",lastUserId + 1, block.timestamp);
            emit Adam(_donor,"Adam's state [Active]",lastUserId + 1, block.timestamp);

            
        }else{


        require(_donor != owner, "Genio is not allowed to particpate in the Donations");
            
            uint myDNA = dnaCall()+1;
            if (keccak256(abi.encodePacked("empty")) == keccak256(abi.encodePacked(donors[_upline].left))) {
                
                // setting up struct
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
                lastUserId++;
                earnings[_donor].myEarning = 0;
                earnings[_donor].regTime = block.timestamp;

                
                uint upline_dna = state[_upline].dna;
                Add2Tree(myDNA, _upline,1, 0,upline_dna,address(0), address(0),_donor,"",address(0),0,0);
                emit Adam(_donor,"New Born",lastUserId + 1, block.timestamp);

                traject[upline_dna][0].left_leg = _donor;
                traject[upline_dna][0].leftDNA = myDNA;
                
                // setting up state
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
                    lastUserId++;
                    earnings[_donor].myEarning = 0;
                    earnings[_donor].regTime = block.timestamp;

                    
                    uint upline_dna = state[_upline].dna;
                    Add2Tree(myDNA, _upline,1, 0,upline_dna,address(0), address(0),_donor,"",address(0),0,0);
                    
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
                        // terminate!!!
                        traject[myDNA][0].pivotAddress = address(0);
                        donors[_donor].pivotAddress = address(0);
                        
                        emit Upgrade(_upline,"End of a row call", block.timestamp);
                        
                    }else if(traject[upline_dna][0].upline  ==  address(0)){
                        // terminate!!!
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
                            emit Upgrade(_upline,"New Level 2", block.timestamp);
                            upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
   
                        }else if(traject[upline_dna][0].level == 2){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;

                            uint LEFTdna = traject[left][0].level;
                            uint RIGHTdna = traject[right][0].level;
                            uint level = 2;

                            if((LEFTdna == level) && (RIGHTdna == level)){

                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;
                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);

                            }else{

                                if(LEFTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{
                                        
                                        uint right_now = traject[right][0].rightDNA;
                                        dischargeRight(_upline,_donor,myDNA,upline_dna,level,right_now);
                                        

                                    }

                                }else if(RIGHTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{

                                        uint left_now = traject[left][0].rightDNA;
                                        dischargeLeft(_upline,_donor,myDNA,upline_dna,level,left_now);
                                        
                                    }


                                }

                            }

                        }else if(traject[upline_dna][0].level == 3){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;

                            uint LEFTdna = traject[left][0].level;
                            uint RIGHTdna = traject[right][0].level;
                            uint level = 3;

                            if((LEFTdna == level) && (RIGHTdna == level)){

                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;

                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);

                            }else{

                                if(LEFTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{
                                        
                                        uint right_now = traject[right][0].rightDNA;
                                        dischargeRight(_upline,_donor,myDNA,upline_dna,level,right_now);
                                        

                                    }

                                }else if(RIGHTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{

                                        uint left_now = traject[left][0].rightDNA;
                                        dischargeLeft(_upline,_donor,myDNA,upline_dna,level,left_now);
                                        
                                    }


                                }

                            }



                        }else if(traject[upline_dna][0].level == 4){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;

                            uint LEFTdna = traject[left][0].level;
                            uint RIGHTdna = traject[right][0].level;
                            uint level = 4;

                            if((LEFTdna == level) && (RIGHTdna == level)){

                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;

                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);

                            }else{

                                if(LEFTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{
                                        
                                        uint right_now = traject[right][0].rightDNA;
                                        dischargeRight(_upline,_donor,myDNA,upline_dna,level,right_now);
                                        

                                    }

                                }else if(RIGHTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{

                                        uint left_now = traject[left][0].rightDNA;
                                        dischargeLeft(_upline,_donor,myDNA,upline_dna,level,left_now);
                                        
                                    }


                                }
                            }



                        }else if(traject[upline_dna][0].level == 5){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;

                            uint LEFTdna = traject[left][0].level;
                            uint RIGHTdna = traject[right][0].level;
                            uint level = 5;

                            if((LEFTdna == level) && (RIGHTdna == level)){

                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;

                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);

                            }else{

                                if(LEFTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{
                                        
                                        uint right_now = traject[right][0].rightDNA;
                                        dischargeRight(_upline,_donor,myDNA,upline_dna,level,right_now);
                                        

                                    }

                                }else if(RIGHTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{

                                        uint left_now = traject[left][0].rightDNA;
                                        dischargeLeft(_upline,_donor,myDNA,upline_dna,level,left_now);
                                        
                                    }


                                }

                            }




                        }else if(traject[upline_dna][0].level == 6){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;

                            uint LEFTdna = traject[left][0].level;
                            uint RIGHTdna = traject[right][0].level;
                            uint level = 6;

                            if((LEFTdna == level) && (RIGHTdna == level)){

                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;

                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);

                            }else{

                                if(LEFTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{
                                        
                                        uint right_now = traject[right][0].rightDNA;
                                        dischargeRight(_upline,_donor,myDNA,upline_dna,level,right_now);
                                        

                                    }

                                }else if(RIGHTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{

                                        uint left_now = traject[left][0].rightDNA;
                                        dischargeLeft(_upline,_donor,myDNA,upline_dna,level,left_now);
                                        
                                    }


                                }

                            }




                        }else if(traject[upline_dna][0].level == 7){

                            uint left = traject[upline_dna][0].leftDNA;
                            uint right = traject[upline_dna][0].rightDNA;

                            uint LEFTdna = traject[left][0].level;
                            uint RIGHTdna = traject[right][0].level;
                            uint level = 7;

                            if((LEFTdna == level) && (RIGHTdna == level)){

                                traject[upline_dna][0].level = level+1;
                                state[_upline].level = level+1;
                                donors[_upline].level = level+1;

                                dischargeDuty(_upline,_donor,myDNA,upline_dna,level);

                            }else{

                                if(LEFTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{
                                        
                                        uint right_now = traject[right][0].rightDNA;
                                        dischargeRight(_upline,_donor,myDNA,upline_dna,level,right_now);
                                        

                                    }

                                }else if(RIGHTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{

                                        uint left_now = traject[left][0].rightDNA;
                                        dischargeLeft(_upline,_donor,myDNA,upline_dna,level,left_now);
                                        
                                    }


                                }

                            }




                        }else if(traject[upline_dna][0].level == 8){

                            uint left       = traject[upline_dna][0].leftDNA;
                            uint right      = traject[upline_dna][0].rightDNA;
                            uint LEFTdna    = traject[left][0].level;
                            uint RIGHTdna   = traject[right][0].level;
                            uint level      = 8;
                            if((LEFTdna == 8) && (RIGHTdna == 8)){
                                if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[right][0].status))) {

                                    traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                    donors[_donor].pivotAddress = donors[_upline].upline;
                                    uint Ups = traject[upline_dna][0].uplineDNA;
                                    upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);
                                    emit Upgrade(_upline,"New Level 1 is Recycled", block.timestamp);

                                }else{

                                    traject[upline_dna][0].level      = 8;
                                    state[_upline].level              = 1;
                                    donors[_upline].level             = 1;
                                    state[_upline].recycle            =  state[_upline].recycle + 1;
                                    traject[upline_dna][0].status     = "completed";
                                    totalEarnings                     = totalEarnings + 230;
                                    earnings[_upline].myEarning       = earnings[_upline].myEarning +  230;
                                    earnings[_upline].myReward        = earnings[_upline].myReward + reward_8;
                                    donors[_upline].recycle           = donors[_upline].recycle + 1;
                                    donors[_upline].left_leg          = address(0);
                                    donors[_upline].right_leg         = address(0);
                                    donors[_upline].left              = "empty";
                                    donors[_upline].right             = "empty";
                                    donors[_upline].pivotAddress      = address(0);
                                    sendDai(_upline,pay_8); 
                                    updateStates(_upline,_donor);
                                }

                            }else{

                                
                                if(LEFTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        uint Ups = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{
                                        
                                        uint right_now = traject[right][0].rightDNA;
                                        dischargeRight(_upline,_donor,myDNA,upline_dna,level,right_now);

                                    }

                                }else if(RIGHTdna == 8){

                                    if (keccak256(abi.encodePacked("completed")) == keccak256(abi.encodePacked(traject[upline_dna][0].status))) {

                                        traject[myDNA][0].pivotAddress  = traject[upline_dna][0].upline;
                                        donors[_donor].pivotAddress     = donors[_upline].upline;
                                        uint Ups                        = traject[upline_dna][0].uplineDNA;
                                        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

                                    }else{

                                        uint left_now = traject[left][0].rightDNA;
                                        dischargeLeft(_upline,_donor,myDNA,upline_dna,level,left_now);
                                        
                                    }


                                }



                            }

                        }else{
                            
                            // Not possible 
                            
                        }

                    
                    } 

            }else{

                traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
                donors[_donor].pivotAddress = donors[_upline].upline;
                uint Ups = traject[upline_dna][0].uplineDNA;
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);

            }
        
        }
         
         

    }

    function  withdrawGNT (address user, uint256 amount) superGenio public{
        require(amount > 0, "Not acceptable");
        require(earnings[user].myReward > amount, "Insufficient Balance");
        if(earnings[user].myReward < amount){

        }else{
            earnings[user].myReward = earnings[user].myReward - amount;
        }
        
    }

    function sendDai(address _to, uint256 _amount) superGenio private  {
         require(_to != address(0));
         require(_amount > 0);
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

    function Add2Tree ( uint id,  address upline, uint level, uint recycle, uint uplineDNA, address left_leg, address right_leg, address myaddress, string memory status, address pivotAddress, uint rightDNA, uint leftDNA) internal {
        traject[id].push(Trajectory(id, upline, level, recycle, uplineDNA,left_leg, right_leg, myaddress, status, pivotAddress, leftDNA, rightDNA));
    }

    function toggling() internal {
        if(toggle == true){
            toggle = false;
        }else{
            toggle = true;
        }
    }

    function getNewUpline(uint newUplineDNA) public superGenio returns (uint){
        
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
       domain = _domain;
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
       uint recycle                  = donors[_upline].recycle;
       dna ++;
       Add2Tree(newDNA, uplineAddress,1, recycle,upline_new,address(0), address(0),_upline,"",address(0),0,0);
       traject[newDNA][0].upline = uplineAddress;
       if(traject[upline_new][0].leftDNA == 0){ 
           traject[upline_new][0].leftDNA  = newDNA;
           traject[upline_new][0].left_leg = _upline;
       }
       else if(traject[upline_new][0].rightDNA == 0){
           traject[upline_new][0].rightDNA   = newDNA;
           traject[upline_new][0].right_leg  = _upline;
       }
       traject[newDNA][0].pivotAddress  = traject[newDNA][0].upline;
       donors[_donor].pivotAddress      = donors[_upline].upline;
       upgrade(donors[_donor].pivotAddress,_donor,newDNA,upline_new);
       emit Upgrade(_upline,"New Level 1 is Recycled", block.timestamp);
    }

    function dischargeDuty(address _upline, address _donor, uint myDNA, uint upline_dna, uint level) internal superGenio {
        traject[upline_dna][0].level = level+1;
        state[_upline].level = level+1;
        donors[_upline].level = level+1;
        traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
        donors[_donor].pivotAddress = donors[_upline].upline;
        if(level == 2){
            totalEarnings = totalEarnings +  5;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 5;
            sendDai(_upline,pay_2);
            emit Upgrade(_upline,"New Level 3", block.timestamp);
        }
        if(level == 3){
            totalEarnings = totalEarnings +  10;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
            sendDai(_upline,pay_3);
            emit Upgrade(_upline,"New Level 4", block.timestamp);
        }if(level == 4){
            totalEarnings = totalEarnings +  10;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
            sendDai(_upline,pay_4);
            emit Upgrade(_upline,"New Level 5", block.timestamp);
        }
        if(level == 5){
            totalEarnings = totalEarnings +  10;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
            sendDai(_upline,pay_5);
            emit Upgrade(_upline,"New Level 6", block.timestamp);
        }if(level == 6){
            totalEarnings = totalEarnings +  20;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 20;
            sendDai(_upline,pay_6);
            emit Upgrade(_upline,"New Level 7", block.timestamp);
        }if(level == 7){
            totalEarnings = totalEarnings +  40;
            earnings[_upline].myEarning = earnings[_upline].myEarning + 40;
            sendDai(_upline,pay_7);
            emit Upgrade(_upline,"New Level 8", block.timestamp);
        }
        earnings[_upline].myReward = earnings[_upline].myReward + reward_6;
        uint Ups = traject[upline_dna][0].uplineDNA;
        upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);
        emit Upgrade(_upline,"New Level", block.timestamp);
    }

    function dischargeRight(address _upline, address _donor, uint myDNA, uint upline_dna, uint level, uint right_now) internal superGenio {
        uint left_ = traject[right_now][0].leftDNA;
        uint right_ = traject[right_now][0].rightDNA;
        uint LEFTdna_ = traject[left_][0].level;
        uint RIGHTdna_ = traject[right_][0].level;
        if((LEFTdna_ == level) && (RIGHTdna_ == level)){
            traject[upline_dna][0].level = level + 1;
            state[_upline].level = level + 1;
            donors[_upline].level = level + 1;
            traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
            donors[_donor].pivotAddress = donors[_upline].upline;
            if(level == 2){
                totalEarnings = totalEarnings +  5;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 5;
                earnings[_upline].myReward = earnings[_upline].myReward + reward_2;
                sendDai(_upline,pay_2);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 3", block.timestamp);
            }
            if(level == 3){
                totalEarnings = totalEarnings +  10;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
                earnings[_upline].myReward = earnings[_upline].myReward + reward_3;
                sendDai(_upline,pay_3);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 4", block.timestamp);
            }if(level == 4){
                totalEarnings = totalEarnings +  10;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
                earnings[_upline].myReward = earnings[_upline].myReward + reward_4;
                sendDai(_upline,pay_4);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 5", block.timestamp);
            }
            if(level == 5){
                totalEarnings = totalEarnings +  10;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
                earnings[_upline].myReward = earnings[_upline].myReward + reward_5;
                sendDai(_upline,pay_5);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 5", block.timestamp);
            }if(level == 6){
                totalEarnings = totalEarnings +  20;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 20;
                earnings[_upline].myReward = earnings[_upline].myReward + reward_6;
                sendDai(_upline,pay_6);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 7", block.timestamp);
            }if(level == 7){
                totalEarnings = totalEarnings +  40;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 40;
                earnings[_upline].myReward = earnings[_upline].myReward + reward_7;
                sendDai(_upline,pay_7);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 8", block.timestamp);
            }
        }else{
            traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
            donors[_donor].pivotAddress = donors[_upline].upline;
            uint Ups = traject[upline_dna][0].uplineDNA;
            upgrade(donors[_donor].pivotAddress,_donor,myDNA,Ups);
        }
    }

    function dischargeLeft(address _upline, address _donor, uint myDNA, uint upline_dna, uint level, uint left_now) internal superGenio {
        uint left_     = traject[left_now][0].leftDNA;
        uint right_    = traject[left_now][0].rightDNA;
        uint LEFTdna_  = traject[left_][0].level;
        uint RIGHTdna_ = traject[right_][0].level;
        if((LEFTdna_ == level) && (RIGHTdna_ == level)){
            traject[upline_dna][0].level = level + 1;
            state[_upline].level         = level + 1;
            donors[_upline].level        = level + 1;
            traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
            donors[_donor].pivotAddress = donors[_upline].upline;
            if(level == 2){
                totalEarnings = totalEarnings +  5;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 5;
                earnings[_upline].myReward  = earnings[_upline].myReward + reward_2;
                sendDai(_upline,pay_2);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 3", block.timestamp);
            }
            if(level == 3){
                totalEarnings = totalEarnings +  10;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
                earnings[_upline].myReward  = earnings[_upline].myReward + reward_3;
                sendDai(_upline,pay_3);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 4", block.timestamp);
            }if(level == 4){
                totalEarnings = totalEarnings +  10;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
                earnings[_upline].myReward  = earnings[_upline].myReward + reward_4;
                sendDai(_upline,pay_4);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 5", block.timestamp);
            }
            if(level == 5){
                totalEarnings = totalEarnings +  10;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
                earnings[_upline].myReward  = earnings[_upline].myReward + reward_5;
                sendDai(_upline,pay_5);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 5", block.timestamp);
            }if(level == 6){
                totalEarnings = totalEarnings +  20;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 20;
                earnings[_upline].myReward  = earnings[_upline].myReward + reward_6;
                sendDai(_upline,pay_6);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 7", block.timestamp);
            }if(level == 7){
                totalEarnings = totalEarnings +  40;
                earnings[_upline].myEarning = earnings[_upline].myEarning + 40;
                earnings[_upline].myReward  = earnings[_upline].myReward + reward_7;
                sendDai(_upline,pay_7);
                upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
                emit Upgrade(_upline,"New Level 8", block.timestamp);
            }
        }else{
            traject[myDNA][0].pivotAddress = traject[upline_dna][0].upline;
            donors[_donor].pivotAddress = donors[_upline].upline;
            upgrade(donors[_donor].pivotAddress,_donor,myDNA,traject[upline_dna][0].uplineDNA);
        }
    }
    
}