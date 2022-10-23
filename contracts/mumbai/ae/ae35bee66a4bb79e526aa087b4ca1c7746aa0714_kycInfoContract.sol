/**
 *Submitted for verification at polygonscan.com on 2022-10-22
*/

pragma solidity ^0.8.4;

contract kycInfoContract {

    struct kycInfo {

        uint kycId;
        string userName;  
        address userAddress;
        string kycTimestamp; 
        string status;
        string details; 
    }

    mapping(uint => kycInfo ) public kycInformation;

    function saveKycInformation(uint _kycId, string memory _userName, address _userAddress, string memory _kycTimestamp , string memory _status, string memory _details) public {
            kycInfo memory kycDetails;
            kycDetails.kycId = _kycId;
            kycDetails.userName = _userName;
            kycDetails.userAddress = _userAddress;
            kycDetails.kycTimestamp = _kycTimestamp;
            kycDetails.status = _status;
            kycDetails.details = _details;

            kycInformation[_kycId] =  kycDetails;
    }

    function getKycDetailbynumber(uint _kycId) public view returns ( kycInfo memory){
        return kycInformation[_kycId];
    }

}