/**
 *Submitted for verification at polygonscan.com on 2022-07-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title Academic Certificate
/// @author Blockchain Qualifications
/// @notice Academic certificate emitted by an authorized Academic Institution. Once issued its content cannot be modified.
contract AcademicCertificate {

/* University info   */
  address academicInstitutionSCAddress;
  address public academicInstitutionUserCreatorWallet;

/* Certificate info */
    uint256 public certificateID;
    string public certificateDetailJSON;
    address public studentWallet;
    uint256 public dateCreationCertificate;
    address public additionalInformationSC;
    bool public activeCertificate;
    uint256 public dateDeletionCertificate;

/* Sign info */
  address[] public walletSignerList;
  mapping (address => uint256) dateSignatureWallet;

/*  BQ control    */
    uint8 public SCVersion = 3;

/*modifiers*/
    modifier onlyAcademicInstitution() {
         require(msg.sender == academicInstitutionSCAddress,"only the academic institution who create it can operate");
        _;
    }

    modifier onlyActiveCertificate() {
        require (activeCertificate);
        _;
    }

    event CertificateCreated( address _certificateAddress);
    event CertificateSigned( address indexed _signer);
    event CertificateDeleted( uint256  _dateDelete);
    event CertificateAssignedOwnership (address indexed _studentWallet);

    struct SignDetail {
        address signer;
        uint256 signDate;
        string name;
        string info;
    }

    /// @notice Creation of the Academic certificate by the Academic institution (universitySCAddress) only by authorized personnel(wallets) of the institution.
    function createCertificate (uint256 _certificateID, string memory  _certificateInfo )   public  returns(bool){
        
        require(certificateID == 0, "Certificate already created");
        
        academicInstitutionSCAddress = msg.sender;
        academicInstitutionUserCreatorWallet = tx.origin;
        // Set Certificate info
        certificateID =  _certificateID;
        certificateDetailJSON= _certificateInfo;
        dateCreationCertificate= block.timestamp;
        activeCertificate=true;
        emit CertificateCreated(address(this));
        return true;
    }
    
    /// @notice Assigns the certificate to the student owner wallet
    function setCertificateOwner (address _studentWallet) public  onlyAcademicInstitution onlyActiveCertificate returns(bool){
        studentWallet = _studentWallet;
        emit CertificateAssignedOwnership(studentWallet);
        return true;
    }

    /// @notice Deletion of the Academic certificate by the Academic institution (universitySCAddress) only by authorized personnel(wallets) of the institution.
    function deleteCertificate  () public  onlyAcademicInstitution onlyActiveCertificate returns(bool){
        activeCertificate=false;
        certificateDetailJSON = "";
        dateDeletionCertificate=block.timestamp;
        emit CertificateDeleted(dateDeletionCertificate);
        return true;
    }

   /// @notice Signature of the certificate by the academic institution authorized personnel
   function signCertificate() public  onlyAcademicInstitution onlyActiveCertificate returns (bool)
   {
       address signer = tx.origin;
       require (dateSignatureWallet[signer] == 0, "already signed by wallet"); //it can be signed by a signer only once

        walletSignerList.push(signer);
        dateSignatureWallet[signer] = block.timestamp;
        emit CertificateSigned(signer);
        return true;
   }
    /// @notice Function to set the SC where additional academic information of the certiticate is registered */
   function setAdditionalInformationSC(address _additionalInformationSC) public  onlyAcademicInstitution onlyActiveCertificate returns(bool)
   {
         additionalInformationSC = _additionalInformationSC;
         return true;
    }

    //Signer info funcitons
    function signatures() public view returns (uint256 )
    {
        return walletSignerList.length;
    }

     /// @notice Function get a Signature detail from the certificate and from the Institutions issuer */
    function signerDetail(uint256 walletSignerIndex) public view returns (address,uint256,string memory, string memory )
    {
        if(walletSignerIndex <= walletSignerList.length) {
            (bool success, bytes memory returnData) = academicInstitutionSCAddress.staticcall(abi.encodeWithSignature("getWalletInfo(address)",walletSignerList[walletSignerIndex]));
            string memory name = "";
            string memory info = "";
            if(success) {
                (name, info) = abi.decode(returnData,(string,string));
            }
            return (walletSignerList[walletSignerIndex], dateSignatureWallet[walletSignerList[walletSignerIndex]],name,info);
        }
        return (address(0),0,"","");
    }

     /// @notice Function to get All the signatures details
    function getSignaturesDetails() public view returns (SignDetail[] memory) 
    {

        SignDetail[] memory signaturesList = new SignDetail[](walletSignerList.length);

        if(walletSignerList.length > 0) {

            for(uint i = 0; i<walletSignerList.length; i++) {
                SignDetail memory signature;
                (signature.signer,signature.signDate, signature.name, signature.info) = signerDetail(i);
                signaturesList[i] = signature;
            }
        }

        return signaturesList;

    }
    /// @notice Function to retrieve the information required to retrieve for the public certificate viewer
    function getCertificateDetail4Viewer() public view returns(uint8 version, address academicIdentity, bool active, uint256 creationDate, string memory certificateJson, uint256 totalSignatures) 
    {
        return (SCVersion, academicInstitutionSCAddress, activeCertificate,dateCreationCertificate,certificateDetailJSON, walletSignerList.length);
    }

    /// @notice Function to retrieve the academic institution blockchain identity (SC address)
    function academicInstitutionIdentity() public view returns(address) 
    {
        return academicInstitutionSCAddress;
    }
}