// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./verifyProfileSignature.sol";
contract HoneyBiteMembership is Ownable,verifyProfileSignature{
    
    mapping(address => uint8[]) userMembershipStatus;
    mapping(bytes =>bool) public signatureStatus;

    /*
		to buy membership for Honey-Bite investment
        @param _user is the address of the user
        @param _membershipType is the type of membership for which payment is made 1 for IDO, 2 for Venture
		@param _timeStamp is the time when off-chain signature is created
		@param _amount is the amount required to buy this membership
        @param _signature is the message which is signed off-chain by the _signer
	*/
    function buyMembership(address _user, uint8 _membershipType, uint256 _timeStamp,uint _amount, bytes calldata _signature) public payable{
        bool _status = verify(owner(), _user,_timeStamp,_amount, _signature);
        require(_status,"signature doesnot  match");               
        require(!signatureStatus[_signature],"already used signature");        
        payable(owner()).transfer(_amount);
        signatureStatus[_signature] = true;
        userMembershipStatus[_user].push(_membershipType);
    }

    /*
		to view all purchased membership for Honey-Bite investment of a user
        @param _user is the address of the user
        returns an array of uint8 with all the purchased membership where 1 indicate IDO membership, 2 indicate Venture membership
	*/

    function membershipStatus(address _user) public view returns(uint8[] memory){
        return userMembershipStatus[_user];
    }
}