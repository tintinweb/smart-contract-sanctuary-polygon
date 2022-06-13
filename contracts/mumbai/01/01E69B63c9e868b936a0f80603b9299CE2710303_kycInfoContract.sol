/**
 *Submitted for verification at polygonscan.com on 2022-06-12
*/

pragma solidity ^0.8.4;

contract kycInfoContract {

    struct kycInfo {

        uint kycId;
        string userName;  
        address userAddress;
        string kycTimestamp; 
        bytes kycDetails;
    }

    mapping(uint => kycInfo ) public kycInformation;

    function saveKycInformation(uint _kycId, string memory _userName, address _userAddress, string memory _kycTimestamp , bytes memory _kycDetails) public {
            kycInfo memory kycDetails;
            kycDetails.kycId = _kycId;
            kycDetails.userName = _userName;
            kycDetails.userAddress = _userAddress;
            kycDetails.kycTimestamp = _kycTimestamp;
            kycDetails.kycDetails = _kycDetails;

            kycInformation[_kycId] =  kycDetails;
    }

    function getKycDetailbynumber(uint _kycId) public view returns ( kycInfo memory){
        return kycInformation[_kycId];
    }

}