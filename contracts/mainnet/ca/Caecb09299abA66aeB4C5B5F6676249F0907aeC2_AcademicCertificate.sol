/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @title Academic Certificate
/// @author Blockchain Qualifications
/// @notice Academic certificate emitted by an authorized Academic Institution. Once issued its content cannot be modified. The academicInstitutionIdentity is the Institution SC address who created it.
contract AcademicCertificate {

/* University info   */
  address public academicInstitutionIdentity;

/* Certificate info */
    uint256 internal certificateID;
    string internal certificateDetailJSON;
    string public certificateURI;    
    address public studentWallet;
    uint256 internal dateCreationCertificate;
    address public additionalInformationSC;
    bool internal showCertificate = true;
    bool internal activeCertificate = true;

    /* Sign info */
  address[] internal walletSignerList;
  mapping (address => uint256) internal dateSignatureWallet;

    /* Modifiers */
    modifier onlyAcademicInstitution() {
         require(msg.sender == academicInstitutionIdentity,"E401");
        _;
    }

    modifier onlyActiveCertificate() {
        require (activeCertificate, "E405");
        _;
    }
    /* Events */
    event CertificateCreated( address _certificateAddress, address creatorWallet);
    event CertificateSigned( address indexed _signer);
    event CertificateDeleted( uint256  _dateDelete);
    event CertificateAssignedOwnership (address indexed _studentWallet);

    /// @notice Creation of the Academic certificate by the Academic institution (universitySCAddress) only by authorized personnel(wallets) of the institution.
    function createCertificate (uint256 _certificateID, string memory  _certificateInfo)   public  returns(bool){
        require(certificateID == 0, "Certificate already created");

        academicInstitutionIdentity = msg.sender;
        certificateID =  _certificateID;
        certificateDetailJSON= _certificateInfo;
        dateCreationCertificate = block.timestamp;

        emit CertificateCreated(address(this),tx.origin);
        return true;
    }

    /// @notice Assigns the certificate to the student owner wallet
    function setCertificateOwnerAndUri (address _studentWallet, string memory _uri) public  onlyAcademicInstitution  returns(bool){
        studentWallet = _studentWallet;
        certificateURI = _uri;

        emit CertificateAssignedOwnership(studentWallet);
        return true;
    }

    /// @notice The certificate owner can modify the public visibility of the certificate content
    function setCertificateVisibility(bool showCertificateContent) public  returns(bool) {
        require(msg.sender == studentWallet || msg.sender == academicInstitutionIdentity, "certificate visibility managed by owner" );
        showCertificate = showCertificateContent;
        return true;
    }

    /// @notice Deletion of the Academic certificate by the Academic institution (universitySCAddress) only by authorized personnel(wallets) of the institution.
    function deleteCertificate  () public  onlyAcademicInstitution  returns(bool){
        activeCertificate=false;
        certificateDetailJSON = "";
        delete walletSignerList;
        delete studentWallet;
        emit CertificateDeleted(block.timestamp);
        return true;
    }

   /// @notice Signature of the certificate by the academic institution authorized personnel
   function signCertificate() public  onlyAcademicInstitution  returns (bool)
   {
       address signer = tx.origin;
       require (dateSignatureWallet[signer] == 0, "already signed"); //it can be signed by a signer only once

        walletSignerList.push(signer);
        dateSignatureWallet[signer] = block.timestamp;
        emit CertificateSigned(signer);
        return true;
   }
    /// @notice Function to set the SC where additional academic information of the certiticate is registered
   function setAdditionalInformationSC(address _additionalInformationSC) public  onlyAcademicInstitution  returns(bool)
   {
         additionalInformationSC = _additionalInformationSC;
         return true;
    }

    /// @notice returns the number of signatures
    function signatures() public view returns (uint256)
    {
        return walletSignerList.length;
    }

     /// @notice Function get a Signature detail from the certificate and from the Institutions issuer
    function signerDetail(uint256 walletSignerIndex, address walletSigner) public view returns (address signerwallet,uint256 dateSignature,string memory signerName, string memory signerInfo)
    {
        if(walletSignerIndex > 0) 
            signerwallet = walletSignerList[walletSignerIndex-1];
        else 
            signerwallet = walletSigner;

        (bool success, bytes memory returnData) = academicInstitutionIdentity.staticcall(abi.encodeWithSignature("getWalletInfo(address)",signerwallet));
        if(success) {
                (signerName, signerInfo) = abi.decode(returnData,(string,string));                
        }
        return (signerwallet, dateSignatureWallet[signerwallet],signerName, signerInfo);        
    }

    /// @notice Function to retrieve the information required to retrieve for the public certificate viewer
    function getCertificateDetail() public view returns( uint256 IDcertificate, bool active, string memory certificateDetail,uint256 creationDate, uint256 totalSignatures, bool hasAdditionalInformation,uint8 SCVersion,address academicInstitutionIdentitySC, string memory academicInstitutionName)
    {
        SCVersion = 3;
        if(showCertificate) certificateDetail = certificateDetailJSON;
        else if(activeCertificate) certificateDetail = "{visibility:private}";
        
        if(additionalInformationSC!= address(0)) hasAdditionalInformation = true;

        (bool success, bytes memory returnData) = academicInstitutionIdentity.staticcall(abi.encodeWithSignature("academicInstitutionName()"));
        if(success) {
             (academicInstitutionName) = abi.decode(returnData,( string ));
        }

        return ( certificateID,activeCertificate,certificateDetail,dateCreationCertificate,walletSignerList.length,hasAdditionalInformation,SCVersion,academicInstitutionIdentity,academicInstitutionName);
    }

    /// @notice Migration SC Version process: Function to migrate AcademicInstitutionIdentity for upgrade migration process. Only current AcademicInstitution manager can migrate.
    function migrateAcademicInstitutionIdentity(address newAcademicInstitutionIdentity) public onlyAcademicInstitution returns(bool) {
        academicInstitutionIdentity = newAcademicInstitutionIdentity;
        return true;
    }
}