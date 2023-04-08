/**
 *Submitted for verification at polygonscan.com on 2023-04-08
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


pragma solidity ^0.8.17;


interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    // don't need to define other functions, only using `transfer()` in this case
}




contract GenioAI{ 


    event InvestorCreated(address donor);
    event Upgrade(address indexed beneficiary, string indexed actionType,uint created);
    event Mode(string indexed actionType,uint created);
    event Registration(address indexed donor,string  actionType, uint _referral, uint256 created);
    event Adam(address indexed donor,string  actionType, uint _referral, uint256 created);
    event TransferReceived(address sender, uint value);

    address payable public owner;
    uint256 public balance;
    constructor(){
        owner = payable(msg.sender);
    }
    
    
    struct  Donor {
        bool is_exists; // Flag is investor exists
        string role; //System Funds
        uint referral;
        address upline; // Address of investor who invited this investor
        uint level; // Current level of this investor (can be 1-6 regarding rewards table)
        uint recycle; // No of recycles
        address left_leg; // left left of your Invitees
        address right_leg; // right left of your Invitees
        string left; // Flag is Left Donor exists
        string right; // Flag is Right Donor exists
        address myaddress;
        address pivotAddress;
    }



    struct Earnings {
        uint myEarning; uint myReward; uint regTime;
    }
    
    uint256 public totalEarnings;
    uint public lastUserId = 0;
     uint public numberOfCycles= 0;
    uint public apiCall = 1;
    
   
    Donor[] investors;

    // Investors
    mapping (address => Donor) public donors;
    mapping (address => Earnings) public earnings;

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

 
    

    modifier superGenio() {
        require(msg.sender == owner, "Transaction not coming from Genio!");
        _;
    }

    
    // Function to receive Ether
    receive() payable external {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    } 

    function isUserExists(address user) public view returns (bool) {
        if(donors[user].referral != 0){
            return true;
        }else{
            return false;
        }
    }

   
   function Cycles() public view returns (uint) {
        return numberOfCycles;
    }


    function numberOfAccount() public view returns (uint) {
        return lastUserId;
    }


    function createDonor(address _upline, address _donor, uint _referral) superGenio external{
        require(_donor != _upline, "You can not be under yourself");
        require(donors[_donor].is_exists == false, "You have a running contract");

         

        if(lastUserId == 0){
            
            donors[_donor].left = "empty";
            donors[_donor].right = "empty";
            donors[_donor].is_exists = true;
            donors[_donor].referral =  numberOfAccount() + 1;
            donors[_donor].level = 1;
            donors[_donor].recycle = 0;
            donors[_donor].role = "genio";
            donors[_donor].myaddress = _donor;
            donors[_donor].upline = owner;
            lastUserId++;
            earnings[_donor].myEarning = 0;
            earnings[_donor].regTime = block.timestamp;
            emit Adam(_donor,"Adam",lastUserId + 1, block.timestamp);
            
        }else{


        require(_donor != owner, "Genio is not allowed to particpate in the Donations");
        // require(_upline != owner, "Genio is not allowed to particpate in the Donations");
            

            if (keccak256(abi.encodePacked("empty")) == keccak256(abi.encodePacked(donors[_upline].left))) {
                
                donors[_donor].is_exists = true;
                donors[_donor].referral =  numberOfAccount() + 1;
                donors[_donor].level = 1;
                donors[_donor].left = "empty";
                donors[_donor].right = "empty";
                donors[_donor].role = "user";
                donors[_donor].myaddress = _donor;
                donors[_donor].upline = _upline;
                if(donors[_donor].level == 1){
                    donors[_upline].left = "closed";
                    donors[_upline].left_leg = _donor;
                }
                lastUserId++;
                earnings[_donor].myEarning = 0;
                earnings[_donor].regTime = block.timestamp;

            }else{

                if (keccak256(abi.encodePacked("empty")) == keccak256(abi.encodePacked(donors[_upline].right))) {
                    
                    donors[_donor].is_exists = true;
                    donors[_donor].referral =  numberOfAccount() + 1;
                    donors[_donor].level = 1;
                    donors[_donor].left = "empty";
                    donors[_donor].right = "empty";
                    donors[_donor].role = "user";
                    donors[_donor].myaddress = _donor;
                    donors[_donor].upline = _upline;
                    if(donors[_donor].level == 1){
                        donors[_upline].right = "closed";
                        donors[_upline].right_leg = _donor;
                    }
                    lastUserId++;
                    earnings[_donor].myEarning = 0;
                    earnings[_donor].regTime = block.timestamp;

                }
       
       
            }

            if (keccak256(abi.encodePacked("closed")) == keccak256(abi.encodePacked(donors[_upline].left))) {

                if (keccak256(abi.encodePacked("closed")) == keccak256(abi.encodePacked(donors[_upline].right))) {
                  
                    donors[_donor].pivotAddress = _upline;
                    upgrade(_upline,_donor);
                    emit Registration(_donor,"New Registration",_referral, block.timestamp);
                }

            }

        }

        
    }


    


    function upgrade(address _upline, address _donor) superGenio internal {
        apiCall++;
        if (keccak256(abi.encodePacked("closed")) == keccak256(abi.encodePacked(donors[_upline].left))) {
            
            if (keccak256(abi.encodePacked("closed")) == keccak256(abi.encodePacked(donors[_upline].right))) {


                    if(donors[_donor].pivotAddress  == owner){
                        // terminate!!!
                        donors[_donor].pivotAddress = address(0);
                        
                        emit Upgrade(_upline,"End of a row call", block.timestamp);
                        
                    }else{
                        
                            // compute here
                        if(donors[_upline].level == 1){
                            
                                
                            donors[_upline].level = 2;
                            donors[_donor].pivotAddress = donors[_upline].upline;
                            upgrade(donors[_donor].pivotAddress,_donor);
                            earnings[_upline].myEarning = earnings[_upline].myEarning + 0;
                            earnings[_upline].myReward = earnings[_upline].myReward + reward_1;
                            emit Upgrade(_upline,"New Level 2", block.timestamp);

                            

                        }else if(donors[_upline].level == 2){

                            address left = donors[_upline].left_leg;
                            address right = donors[_upline].right_leg;

                            if((donors[left].level == 2) && (donors[right].level == 2)){

                                donors[_upline].level = 3;
                                sendGNT(_upline,reward_2);
                                sendDai(_upline,pay_2);
                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);
                                totalEarnings = totalEarnings + 5;
                                earnings[_upline].myEarning = earnings[_upline].myEarning + 5;
                                earnings[_upline].myReward = earnings[_upline].myReward + reward_2;
                                emit Upgrade(_upline,"New Level 3", block.timestamp);

                            }else{

                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);

                            }

                            
                            
                            

                            
                        }else if(donors[_upline].level == 3){


                            address upline  = donors[_upline].upline;
                            address upright = donors[upline].right_leg;
                            address uplinex = donors[upline].upline;


                            address L1      = donors[upright].left_leg;
                            address R2      = donors[upright].right_leg;

                            if((L1 == address(0))  && (R2 == address(0))){



                                    displaceX3 (_upline);

                                    address left = donors[_upline].left_leg;
                                    address right = donors[_upline].right_leg;

                                    if((donors[left].level == 3) && (donors[right].level == 3)){

                                        donors[_upline].level = 4;
                                        sendGNT(_upline,reward_3);
                                        sendDai(_upline,pay_3);
                                        donors[_donor].pivotAddress = uplinex;
                                        upgrade(donors[_donor].pivotAddress,_donor);
                                        earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
                                        earnings[_upline].myReward = earnings[_upline].myReward + reward_3;
                                        totalEarnings = totalEarnings + 10;
                                        emit Upgrade(_upline,"New Level 4", block.timestamp);


                                    }else{

                                        donors[_donor].pivotAddress = uplinex;
                                        upgrade(donors[_donor].pivotAddress,_donor);

                                    }



                            }else{

                                    address left = donors[_upline].left_leg;
                                    address right = donors[_upline].right_leg;

                                    if((donors[left].level == 3) && (donors[right].level == 3)){

                                        donors[_upline].level = 4;
                                        sendGNT(_upline,reward_3);
                                        sendDai(_upline,pay_3);
                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        upgrade(donors[_donor].pivotAddress,_donor);
                                        earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
                                        earnings[_upline].myReward = earnings[_upline].myReward + reward_3;
                                        totalEarnings = totalEarnings + 10;
                                        emit Upgrade(_upline,"New Level 4", block.timestamp);


                                    }else{

                                        donors[_donor].pivotAddress = donors[_upline].upline;
                                        upgrade(donors[_donor].pivotAddress,_donor);

                                    }



                            }

                            
                        }else if(donors[_upline].level == 4){

                            address left = donors[_upline].left_leg;
                            address right = donors[_upline].right_leg;

                            if((donors[left].level == 4) && (donors[right].level == 4)){

                                donors[_upline].level = 5;
                                sendGNT(_upline,reward_4);
                                sendDai(_upline,pay_4);
                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);
                                earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
                                earnings[_upline].myReward = earnings[_upline].myReward + reward_4;
                                totalEarnings = totalEarnings + 10;
                                emit Upgrade(_upline,"New Level 5", block.timestamp);


                            }else{

                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);

                            }

                            
                        }else if(donors[_upline].level == 5){

                            address left = donors[_upline].left_leg;
                            address right = donors[_upline].right_leg;

                            if((donors[left].level == 5) && (donors[right].level == 5)){

                                donors[_upline].level = 6;
                                sendGNT(_upline,reward_5);
                                sendDai(_upline,pay_5);
                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);
                                earnings[_upline].myEarning = earnings[_upline].myEarning + 10;
                                earnings[_upline].myReward = earnings[_upline].myReward + reward_5;
                                totalEarnings = totalEarnings + 10;
                                emit Upgrade(_upline,"New Level 6", block.timestamp);


                            }else{

                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);

                            }

                            
                        }else if(donors[_upline].level == 6){

                            address left = donors[_upline].left_leg;
                            address right = donors[_upline].right_leg;

                            if((donors[left].level == 6) && (donors[right].level == 6)){

                                donors[_upline].level = 7;
                                sendGNT(_upline,reward_6);
                                sendDai(_upline,pay_6);
                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);
                                totalEarnings = totalEarnings + 20;
                                earnings[_upline].myEarning = earnings[_upline].myEarning +  20;
                                earnings[_upline].myReward = earnings[_upline].myReward + reward_6;
                                emit Upgrade(_upline,"New Level 7", block.timestamp);


                            }else{

                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);

                            }

                            
                        }else if(donors[_upline].level == 7){

                            address left = donors[_upline].left_leg;
                            address right = donors[_upline].right_leg;

                            if((donors[left].level == 7) && (donors[right].level == 7)){

                                donors[_upline].level = 8;
                                sendGNT(_upline,reward_7);
                                sendDai(_upline,pay_7);
                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);
                                totalEarnings = totalEarnings + 40;
                                earnings[_upline].myEarning = earnings[_upline].myEarning + 40;
                                earnings[_upline].myReward = earnings[_upline].myReward + reward_7;
                                emit Upgrade(_upline,"New Level 8", block.timestamp);

                            }else{

                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);

                            }

                            
                        }else if(donors[_upline].level == 8){

                            address left = donors[_upline].left_leg;
                            address right = donors[_upline].right_leg;

                            if((donors[left].level == 8) && (donors[right].level == 8)){
                                numberOfCycles++;
                                donors[_upline].level = 1;
                                donors[_upline].recycle = donors[_upline].recycle + 1;
                                sendGNT(_upline,reward_8);
                                sendDai(_upline,pay_8);
                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);
                                totalEarnings = totalEarnings + 230;
                                earnings[_upline].myEarning = earnings[_upline].myEarning +  230;
                                earnings[_upline].myReward = earnings[_upline].myReward + reward_8;
                                emit Upgrade(_upline,"Recycled", block.timestamp);

                            }else{

                                donors[_donor].pivotAddress = donors[_upline].upline;
                                upgrade(donors[_donor].pivotAddress,_donor);

                            }

                            
                        }else{
                            
                            
                        }


                    }

            }else{

                address Up = donors[_upline].upline;
                address DnLeft = donors[_upline].left_leg;
                donors[Up].left_leg = DnLeft;
                donors[DnLeft].upline = Up;
                uint toggle = 0;
                address newHost   = shuffle(DnLeft,toggle);
                donors[_upline].upline = newHost;

                donors[_donor].pivotAddress = donors[_upline].upline;
                upgrade(donors[_donor].pivotAddress,_donor);
                

            }
            

        }else{


            if(donors[_donor].pivotAddress  == owner){
                // terminate!!!
                donors[_donor].pivotAddress = address(0);
                emit Upgrade(_upline,"End of a row call", block.timestamp);
                
            }else{

                donors[_donor].pivotAddress = donors[_upline].upline;
                upgrade(donors[_donor].pivotAddress,_donor);

            }

            


        }
        

    }

   

    function sendDai(address _to, uint256 _amount) superGenio private  {
         require(_to != address(0));
         require(_amount > 0);
         IERC20 dai = IERC20(address(0xf1391810048c261bDe4160AF2d98790DADEc3584));
         dai.transfer(_to, _amount);
         
    }

    function sendGNT(address _to, uint256 _amount) superGenio private  {
        require(_to != address(0));
        require(_amount > 0);
        IERC20 gnt = IERC20(address(0xf1391810048c261bDe4160AF2d98790DADEc3584));
        gnt.transfer(_to, _amount);
        
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



   function sanitizing(address _address) public view returns(bool){

        address left = donors[_address].left_leg;
        address right =  donors[_address].right_leg;

        address dnleft = donors[left].left_leg;
        address dnright =  donors[left].right_leg;

        if(right == address(0)){
            if((dnleft != address(0)) && (dnright != address(0))){
                return true;
            }else{
                return false;
            }
        }else{
            return false;
        }

    }


    // shuffle the left side
    function shuffle (address _user, uint toggle) public view returns (address){

        address left = donors[_user].left_leg;
        address right =  donors[_user].right_leg;


        if(left == address(0)){
            return _user;
        }else if(right == address(0)){
            return _user;
        }else{

            if(_user == owner){
                return _user;
            }else{
                
                if(toggle == 0){

                  return  shuffle(left, 1);

                }else{

                   return shuffle(right, 0);

                }
            }

            

        }
        
    }


    function displace(address user) private{

        address Right = donors[user].right_leg;
        if(Right == address(0)){

            address Up = donors[user].upline;
            address DnLeft = donors[user].left_leg;
            donors[Up].left_leg = DnLeft;
            donors[DnLeft].upline = Up;
            uint toggle = 0;
            address newHost   = shuffle(DnLeft,toggle);
            donors[user].upline = newHost;

        }

    }


    // TODO IS HERE JUST LOOK WELL
    function displaceX2 (address user) private{
        address upline = donors[user].upline;
        address Right = donors[upline].right_leg;

        if(Right == address(0)){
            // check well
            if(upline == owner){}else{
                address Uplinex = donors[upline].upline;
                if(Uplinex == owner){}else{

                    uint toggle = 0;
                    donors[user].upline = donors[Uplinex].left_leg;
                    donors[Uplinex].left_leg = donors[user].myaddress;
                    address newHost   = shuffle(donors[user].left_leg,toggle);
                    donors[upline].upline = newHost;
                    donors[upline].left_leg = address(0);
                    
                    if(donors[newHost].left_leg == address(0)){
                        // update
                        donors[newHost].left_leg  = upline;

                    }else{
                        // update
                        donors[newHost].right_leg  = upline;
                    }

                }

            }
            

        }
        
    }



    function displaceX3 (address user) private{


        address upline  = donors[user].upline;
        address upright = donors[upline].right_leg;


        address L1      = donors[upright].left_leg;
        address R2      = donors[upright].right_leg;

        if((L1 == address(0))  && (R2 == address(0))){

            if(donors[user].level == 3){

                if(upline == owner){}else{

                    address Uplinex = donors[upline].upline;
                    if(Uplinex == owner){}else{
                        uint toggle = 0;
                        donors[user].upline = donors[Uplinex].myaddress;
                        donors[Uplinex].left_leg = user;
                        address newHost   = shuffle(donors[user].left_leg,toggle);
                        donors[Uplinex].left_leg = donors[user].myaddress;

                        address newHostUpline = donors[newHost].upline;

                        if(donors[newHostUpline].left_leg == newHost){
                            donors[upline].upline = newHostUpline;
                            donors[newHostUpline].left_leg  = upline;
                            donors[upline].left_leg = newHost;
                        }else{
                            donors[upline].upline = newHostUpline;
                            donors[newHostUpline].right_leg  = upline;
                            donors[upline].left_leg = newHost;
                        }

                    
                    }


                }


            }
            
            

        }

        
    }



    
}