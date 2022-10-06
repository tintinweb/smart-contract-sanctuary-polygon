pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT
import "./Ownable.sol";


contract Whitelisting {

    //1 is for dontVerify
    //2 is for verify
    //3 is for verifyWithSmartContract
    //will denote the method for whitelisting in smart contract

    Ownable ownable;
    
    uint256 public identifier = 0;  // initially set to 0
    bool canBeAdded = false;
    

    mapping (address => bool) public VerifyAddressForWhitelisting;  //for identifier 1
    mapping (address => bool) verifyAddress;  // for identifier 2

    bytes32[] rootHashesForVerifyUsingConract; //for verifying with identifier 3

    modifier moduleAccess(uint256 idType){
        require(identifier == idType, "Invalid identifier" );
        _;
    }


    modifier onlyOwner() {
        require(ownable.verifyOwner(msg.sender) == true);
        _;
    }

    function setOwnable(address ownable_Address) public {
        ownable = Ownable(ownable_Address);
    }   


    //onlyOwner
    function setWhitelistType(uint256 identifierType) external onlyOwner{
        require (identifierType > 0 && identifierType <= 3, "wrong parameter passed");
        identifier = identifierType;
    }
    
    // Don't verify module start  - identifier 1
    function registerUser(address addr, uint256 id) external moduleAccess(id){
        require(canBeAdded == true, "Can't add");
        VerifyAddressForWhitelisting[addr] = true;
    }
    
    function setUserWhitelistingVariable() external onlyOwner{
        canBeAdded = !canBeAdded;
    }
    // Don't verify module end 

    

    //Verify module start   - identifier 2
    function addAddresses(bytes memory addresses, uint256 id) external moduleAccess(id) onlyOwner {
        address[] memory walletAddressesList = abi.decode(addresses, (address[]));
        for(uint i = 0; i < walletAddressesList.length; i++){
        verifyAddress[walletAddressesList[i]] = true;
        }
    }

    function statusOfAddress(address addr) external view returns(bool){
        return verifyAddress[addr];
    }
    //Verify module end


    //VerifyWithSmartContract module start - identifier 3

    function addRootHashForVerifyUsingConract(bytes32 newRootHash, uint256 id) external moduleAccess(id) onlyOwner {
        rootHashesForVerifyUsingConract.push(newRootHash);
    }

    function getRootHashesForVerifyUsingConract() external view returns(bytes32[] memory){
        return rootHashesForVerifyUsingConract;
    }

  
    

}