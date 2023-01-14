/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.9;

    contract SmartSteps {

    uint[3] sideDetails; /*0:default,1:left,2:right*/
    address payable ownerWallet;
    bool IsInitinalized;

    struct User {
        address referrer;
        address parentID;
        address leftID;
        address rightID;
        bool isRegisterd;
    }

    mapping(address => User) public users;
    mapping(address=>address[]) check;

    function initialize(address _owner) public {
        require(IsInitinalized == false,"already done");
        ownerWallet = payable(_owner);
        sideDetails = [0,1,2];
    }

    function register(address _referrer,uint _sideIndex) public {
        User storage user = users[msg.sender];
        require(user.isRegisterd == false,"already register");
        require(_sideIndex < sideDetails.length,"wrong deatils");
        require((users[_referrer].isRegisterd ==true && _referrer != msg.sender) || ownerWallet == msg.sender,  "No upline found");
     if (user.referrer == address(0) && ownerWallet != msg.sender) {
			        user.referrer = _referrer;
        }
     if( ownerWallet != msg.sender){
        if(sideDetails[_sideIndex]==0){
                check[msg.sender].push( user.referrer);
            for(uint j=0 ;j<check[msg.sender].length;j++){
                address leg = check[msg.sender][j];
                    if(users[leg].leftID==address(0)){
                        users[leg].leftID = msg.sender;
                        user.parentID = leg;
                        break;
                    }else{
                        check[msg.sender].push(users[leg].leftID);
                    }
                    if(users[leg].rightID == address(0)){
                            users[leg].rightID = msg.sender;
                            user.parentID = leg;
                            break;
                    }else{
                        check[msg.sender].push(users[leg].rightID);
                    }
                }
                
                }
                if(sideDetails[_sideIndex]==1){
                    address upline = user.referrer;
                    for(uint i = 0;i<15;i++){
                        if(upline != address(0)){
                            if(users[upline].leftID == address(0)){
                                users[upline].leftID = msg.sender;
                                user.parentID = upline;
                                break;
                            }
                    }
                    upline = users[upline].leftID;
            }
                
                }
            if(sideDetails[_sideIndex]==2){
                address upline = user.referrer;
                    for(uint i = 0;i<15;i++){
                        if(upline != address(0)){
                             if(users[upline].rightID == address(0)){
                                users[upline].rightID = msg.sender;
                                user.parentID = upline;
                                break;
                             }
                    }
                    upline = users[upline].rightID;
            }
                
                }
        }
        
           
        user.isRegisterd = true;
    }

   







}