// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";

contract ReferralAccountsManager is Ownable {

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////                                                                                    ////////////////
    ////////////////     .88b  d88.   d888888b   d8b   db   d88888b   d8888b.   d888888b    .d88b.      ////////////////
    ////////////////     88'YbdP`88     `88'     888o  88   88'       88  `8D     `88'     .8P  Y8.     ////////////////
    ////////////////     88  88  88      88      88V8o 88   88ooooo   88oobY'      88      88    88     ////////////////
    ////////////////     88  88  88      88      88 V8o88   88~~~~~   88`8b        88      88    88     ////////////////
    ////////////////     88  88  88     .88.     88  V888   88.       88 `88.     .88.     `8b  d8'     ////////////////
    ////////////////     YP  YP  YP   Y888888P   VP   V8P   Y88888P   88   YD   Y888888P    `Y88P'      ////////////////
    ////////////////                                                                                    ////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     VARIABLES      /////////////////////
    ////////////////////////////////////////////////////////////////////

    //list of all referrents 
    address[] referrents;

    //this boolean ignores the referrent list and returns true for everyone
    bool ignoreReferrentList; 

    address[] referrentListModifiers;

    constructor(){
        ignoreReferrentList = false;
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     MODIFIERS      /////////////////////
    ////////////////////////////////////////////////////////////////////
    
    modifier isListModifier(){
        require(msg.sender==owner() || isReferrentListModifier(msg.sender), "You are not allowed to modify the referrent List.");
        _;
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////////////\     SETTERS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    function safeAddReferrent(address _referrent)public isListModifier{
        if(!isReferrent(_referrent)){
            referrents.push(_referrent);
        }
    }

    function safeRemoveReferrent(address _referrent)public isListModifier{
        for(uint i = 0; i < referrents.length; i++){
            if(referrents[i] == _referrent){
                referrents[i] = referrents[referrents.length-1];
                referrents.pop();
                break;
            }
        }
    }

    function safeSetIgnoreReferrentList(bool _ignoreReferrentList)public onlyOwner{
        ignoreReferrentList = _ignoreReferrentList;
    }

    function safeAddReferrentListModifier(address _referrentListModifier)public onlyOwner{
        require(!isReferrentListModifier(_referrentListModifier), "This address is already a referrentListModifier.");
        referrentListModifiers.push(_referrentListModifier);
    }

    function safeRemoveReferrentListModifier(address _referrentListModifier)public onlyOwner{
        for(uint i = 0; i < referrentListModifiers.length; i++){
            if(referrentListModifiers[i] == _referrentListModifier){
                referrentListModifiers[i] = referrentListModifiers[referrentListModifiers.length-1];
                referrentListModifiers.pop();
                break;
            }
        }
    }
    

    ////////////////////////////////////////////////////////////////////
    ///////////////////////////\     GETTERS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    function getAllReferrents() public view returns (address[] memory){
        return referrents;
    }


    function getIgnoreReferrentList() public view returns (bool){
        return ignoreReferrentList;
    }

    function isReferrent(address _referrent) public view returns (bool){
        if(ignoreReferrentList){
            return true;
        }
        for(uint i = 0; i < referrents.length; i++){
            if(referrents[i] == _referrent){
                return true;
            }
        }
        return false;
    }

    
    function isReferrentListModifier(address _referrentListModifier) public view returns (bool){
        for(uint i = 0; i < referrentListModifiers.length; i++){
            if(referrentListModifiers[i] == _referrentListModifier){
                return true;
            }
        }
        return false;
    }

    function getReferrentListModifiers() public view returns (address[] memory){
        return referrentListModifiers;
    }
}