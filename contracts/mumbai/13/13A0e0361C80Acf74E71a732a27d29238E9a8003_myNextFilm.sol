/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: MIT 

pragma solidity 0.8.7;
contract myNextFilm {
    struct script{
	string email;
	string scriptName;
	string encryptedURL;
    }
 
    address Owner;    
    mapping(bytes32 =>mapping(string=>string)) public preview;       //preview[email][_previewName] = uri
    mapping(bytes32 => bytes32) loginId;
    script[] public scriptDetails;

    constructor(){
        Owner = msg.sender;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == Owner,"Only Mnf can call this function");
        require(newOwner != address(0), "Ownable: new owner is the zero address");        
        Owner = newOwner;
    }
   
    function createPreView(bytes32 _encryptEmail,string memory _previewName, string memory _url) public{
        require(msg.sender == Owner,"Only Mnf can call this function");
        preview[_encryptEmail][_previewName] = _url;
    }

    function createUserProfile(bytes32 _encryptEmail,bytes32 _password) public{
        require(loginId[_encryptEmail] == "","Email already exist... Please login using another Email Id");
        loginId[_encryptEmail] = _password;        
    }
    
    function login(bytes32 _encryptEmail,bytes32 _password) public view returns(bool) {
        require(msg.sender == Owner,"Only Mnf can call this function");
        if(loginId[_encryptEmail] == _password){
            return true;
        }   
        else{
            return false;
        }
    }

    function deleteUserProfile(bytes32 _encryptEmail,bytes32 _password) public{
        require(msg.sender == Owner,"Only Mnf can call this function");
        require(loginId[_encryptEmail] == _password,"Wrong Password");
        delete loginId[_encryptEmail];        
    }
    
    function registerScript(string memory _email,string memory _scriptName,string memory _encryptedURL) public {
	    require(msg.sender == Owner,"Only MNF can add script of user");
	    scriptDetails.push(script(_email,_scriptName,_encryptedURL));
    }

    function NoOfScript() public view returns(uint){
	    return scriptDetails.length;
    }

    function viewScriptDetails() public view returns(script[] memory){
	    return scriptDetails;
    }
 
}