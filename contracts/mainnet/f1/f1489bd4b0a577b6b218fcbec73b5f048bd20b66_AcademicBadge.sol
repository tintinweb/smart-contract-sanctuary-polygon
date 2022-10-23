/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @title Academic Badge
/// @author Blockchain Qualifications
/// @notice Academic badge emitted by an authorized Academic Institution. Once issued its content cannot be modified. The academicInstitutionIdentity is the Institution SC address who created it.
contract AcademicBadge {

/* University info   */
  address public academicInstitutionIdentity;

/* Certificate info */
    uint256 internal badgeID;
    string internal badgeDetailJSON;
    string public badgeURI;
    address public studentWallet;
    uint256 internal dateCreationBadge;
    address public additionalInformationSC;
    bool internal showBadge = true;
    bool internal activeBadge = true;
    uint8 internal documentType = 2;   //SCVersion3

    /* Modifiers */
    modifier onlyAcademicInstitution() {
         require(msg.sender == academicInstitutionIdentity,"E401");
        _;
    }

    modifier onlyActiveCertificate() {
        require (activeBadge, "E405");
        _;
    }
    /* Events */
    event BadgeCreated( address _certificateAddress, address creatorWallet);
    event BadgeDeleted( uint256  _dateDelete);
    event BadgeAssignedOwnership (address indexed _studentWallet);

    /// @notice Creation of the Academic certificate by the Academic institution (universitySCAddress) only by authorized personnel(wallets) of the institution.
    function createCertificate (uint256 _badgeID, string memory  _badgeInfo)   public  returns(bool){
        require(badgeID == 0, "Certificate already created");

        academicInstitutionIdentity = msg.sender;
        badgeID =  _badgeID;
        badgeDetailJSON= _badgeInfo;
        dateCreationBadge = block.timestamp;

        emit BadgeCreated(address(this),tx.origin);
        return true;
    }

    /// @notice Assigns the certificate to the student owner wallet
    function setCertificateOwnerAndUri (address _studentWallet, string memory _uri) public  onlyAcademicInstitution  returns(bool){
        studentWallet = _studentWallet;
        badgeURI = _uri;

        emit BadgeAssignedOwnership(studentWallet);
        return true;
    }

    /// @notice The certificate owner can modify the public visibility of the certificate content
    function setCertificateVisibility(bool showBadgeContent) public  returns(bool) {
        require(msg.sender == studentWallet || msg.sender == academicInstitutionIdentity, "certificate visibility managed by owner" );
        showBadge = showBadgeContent;
        return true;
    }

    /// @notice Deletion of the Academic certificate by the Academic institution (universitySCAddress) only by authorized personnel(wallets) of the institution.
    function deleteCertificate  () public  onlyAcademicInstitution  returns(bool){
        activeBadge=false;
        badgeDetailJSON = "";
        delete studentWallet;
        emit BadgeDeleted(block.timestamp);
        return true;
    }


    /// @notice Function to set the SC where additional academic information of the certiticate is registered
   function setAdditionalInformationSC(address _additionalInformationSC) public  onlyAcademicInstitution  returns(bool)
   {
         additionalInformationSC = _additionalInformationSC;
         return true;
    }


    /// @notice Function to retrieve the information required to retrieve for the public certificate viewer
    function getCertificateDetail() public view returns( uint256 IDcertificate, bool active, string memory certificateDetail,uint256 creationDate, uint256 totalSignatures, bool hasAdditionalInformation,uint8 docType,address academicInstitutionIdentitySC, string memory academicInstitutionName)
    {
        if(showBadge) certificateDetail = badgeDetailJSON;
        else if(activeBadge) certificateDetail = "{visibility:private}";

        if(additionalInformationSC!= address(0)) hasAdditionalInformation = true;

        (bool success, bytes memory returnData) = academicInstitutionIdentity.staticcall(abi.encodeWithSignature("academicInstitutionName()"));
        if(success) {
             (academicInstitutionName) = abi.decode(returnData,( string ));
        }

        return ( badgeID,activeBadge,certificateDetail,dateCreationBadge,0,hasAdditionalInformation,documentType,academicInstitutionIdentity,academicInstitutionName);
    }

    /// @notice Migration SC Version process: Function to migrate AcademicInstitutionIdentity for upgrade migration process. Only current AcademicInstitution manager can migrate.
    function migrateAcademicInstitutionIdentity(address newAcademicInstitutionIdentity) public onlyAcademicInstitution returns(bool) {
        academicInstitutionIdentity = newAcademicInstitutionIdentity;
        return true;
    }
}