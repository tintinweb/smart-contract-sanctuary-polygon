//SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

/**
* @author Team-SALD - Polygon Internship 22
* @title An Election Dapp
*/
/**
 *@notice TruElect token interface 
 */


contract User{
    constructor(){
        admin[msg.sender]=true;
    }
    /**@dev user structure*/

    struct UserStruct {
        address addr;
        string cid;
    }
    /**@dev valid for cases (registered user, verified for partaking in any electoral process)*/ 
    mapping(address=>mapping(string=>bool)) isValid; 

    /**@dev registered users map*/
    mapping(address=>UserStruct) public registeredUsers;

    /**@dev Authorized Election bodies addresses*/ 
    mapping (address=>mapping(string=>bool)) public electionBodies;

    /**@dev only admin map*/ 
    mapping (address=>bool) private admin;

    /********************* EVENTS **************************/

    /**@dev register event*/ 
    event Register (address user,string msg);

    /**@dev verify event*/ 
    event Verify (address caller,address user, string msg);

    /** @dev ElectionBodyAdded event*/ 
    event ElectionBodyAdded(address electionBody,string electionBodyName);

    /************************* MODIIERS **********************/ 

    /**@dev only Election body */ 
    modifier onlyElectionBody(string memory electionBodyName) {
        require(electionBodies[msg.sender][electionBodyName],'Not authorized');
        _;
    }

    /**@dev only admin */ 
    modifier onlyAdmin() {
        require(admin[msg.sender],'Not authorized');
        _;
    }

    /************************* FUNCTIONS **********************/ 

    /** @notice function to register user */ 

    function  register(string memory cid) public {
        require(isValid[msg.sender]['registered'] == false,'Already Registered');
        registeredUsers[msg.sender] = UserStruct({addr:msg.sender,cid:cid});
        /**@dev update is valid map*/ 
        isValid[msg.sender]['registered'] = true;
        emit Register(msg.sender,'Registered');
    }

    /**@dev function to verify user from an authorized body*/
    function verify(address user,string memory electionBody) onlyElectionBody(electionBody) public{
        require(isValid[msg.sender]['registered'] == true,'Not Registered');
        isValid[user][electionBody] = true;
        emit Verify(msg.sender,user,'Verified');
    }

     /** @dev Read User profile*/
    function getUserProfile () public view returns (UserStruct memory){
        return registeredUsers[msg.sender];
    } 

    /**@dev register a registration body only owner call*/ 
      function addElectionBody (address electionBody,string memory electionBodyName) public onlyAdmin {
        electionBodies[electionBody][electionBodyName] =true;
        emit ElectionBodyAdded(electionBody,electionBodyName);
    }

    /**@dev Get user status for all valid electorial platform*/ 
      function getUserStatus (address userAddr,string memory status) public view returns (bool ){
        return isValid[userAddr][status];
    } 

    
}