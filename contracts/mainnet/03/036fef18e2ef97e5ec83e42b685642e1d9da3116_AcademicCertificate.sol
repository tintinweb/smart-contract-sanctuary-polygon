/**
 *Submitted for verification at polygonscan.com on 2022-05-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title Academic Certificate
/// @author Blockchain Qualifications
/// @notice Academic certificate emitted by an authorized Academic Institution. Once issued its content cannot be modified.
contract AcademicCertificate {

/* University info   */
  address public universitySCAddress;
  address public universityUserCreatorWallet;

/* Certificate info */
    string public certificateDetailJSON;
    uint256 public dateCreationBCCertificate;
    bool public activeCertificate;
    uint256 public dateDeletion;
    address public additionalInformationSC;

/*  BCQ addresses   */
    uint8 public SCVersion = 2;

/* Sign info */
  address[] public walletSignerList;
  mapping (address => uint256) public dateSignatureWallet;

/* Modifiers*/
   modifier onlyUniversityIssuer {
         require(msg.sender == universitySCAddress, "only Academic Institution who created it can operate");  //only the university who created it can operate
        _;
    }

    modifier onlyActiveCertificate() {
        require (activeCertificate, "certificate is inactive");
        _;
    }

    event CertificateCreated( address _certificateAddress);
    event CertificateSigned( address indexed _signer);
    event CertificateDeleted( uint256  _dateDelete);

    /// @notice Creation of the Academic certificate by the Academic institution (universitySCAddress) only by authorized personnel(wallets) of the institution.
    function createCertificate ( address _universitySC, string memory  _certificateInfo )   public  returns(bool){
        require(bytes(certificateDetailJSON).length == 0, "Certificate details cannot be modified");
        universitySCAddress = _universitySC;
        universityUserCreatorWallet = tx.origin;
        // Set Certificate info
        certificateDetailJSON= _certificateInfo;
        dateCreationBCCertificate= block.timestamp;
        activeCertificate=true;
        emit CertificateCreated(address(this));
        return true;
    }

    /// @notice Deletion of the Academic certificate by the Academic institution (universitySCAddress) only by authorized personnel(wallets) of the institution.
    function deleteCertificate  () public  onlyUniversityIssuer onlyActiveCertificate returns(bool){
        activeCertificate=false;
        certificateDetailJSON = "";
        dateDeletion=block.timestamp;
        emit CertificateDeleted(dateDeletion);
        return true;
  }

   /// @notice Signature of the certificate by the academic institution authorized personnel
   function signCertificate() public  onlyUniversityIssuer onlyActiveCertificate returns (bool)
   {
       address signer = tx.origin;
       require (dateSignatureWallet[signer] == 0, "already signed by wallet"); //it can be signed by a signer only once

        walletSignerList.push(signer);
        dateSignatureWallet[signer] = block.timestamp;
        emit CertificateSigned(signer);
        return true;
   }
    /// @notice Function to set the SC where additional academic information of the certiticate is registered */
   function setAdditionalInformationSC( address _additionalInformationSC) public  onlyUniversityIssuer onlyActiveCertificate returns(bool){
         additionalInformationSC = _additionalInformationSC;
         return true;
    }


    //Signer info funcitons
    function signatures() public view returns (uint256 )
    {
        return walletSignerList.length;
    }


    function signatureInfo(uint256 walletSignerIndex) public view returns (address,uint256 )
    {
        if(walletSignerIndex <= walletSignerList.length) {
            return (walletSignerList[walletSignerIndex], dateSignatureWallet[walletSignerList[walletSignerIndex]]);
        }
        return (address(0),0);
    }

    function academicInstitutionIdentity() public view returns(address) {
        return universitySCAddress;
    }
}