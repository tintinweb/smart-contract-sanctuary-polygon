/**
 *Submitted for verification at polygonscan.com on 2022-05-09
*/

pragma solidity ^0.8.10;


contract AcademicCertificate {

/*   BCQ addresses   */
    address public BCQCertificateLogicAddress;
    uint8 public SCVersion = 2;

/* University info   */
  address public universitySCAddress;
  address public universityUserCreatorWallet;
  uint256 public universityIDToken;

/* certificate info */
    string public certificateDetailJSON;
    uint256 public dateCreationBCCertificate;
    bool public activeCertificate;
    uint256 public dateDeletion;
    address academicExpedientSC;
    address documentManagerSC;

/* Sign info */
  address[] public walletSignerList;
  mapping (address => uint256) public dateSignatureWallet;

/*modifiers*/
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

    constructor() {
    }

    function initCertificate (string memory  _certificateInfo )   public  returns(bool){
        require(bytes(certificateDetailJSON).length == 0, "Certificate details cannot be modified");
        universitySCAddress = msg.sender;
        universityUserCreatorWallet = tx.origin;
        // Set Certificate info
        certificateDetailJSON= _certificateInfo;
        dateCreationBCCertificate= block.timestamp;
        activeCertificate=true;
        emit CertificateCreated(address(this));
        return true;
    }

   /*Function to delete the certificate, only authorized wallets of the university are allowed to call it*/
    function deleteCertificate  (uint256 _universityIDToken) public  onlyUniversityIssuer onlyActiveCertificate returns(bool){
        activeCertificate=false;
        certificateDetailJSON = "";
        dateDeletion=block.timestamp;
        emit CertificateDeleted(dateDeletion);
        return true;
  }

   /*Function to sign the certificate, only authorized wallets of the university are allowed to call it*/
   function signCertificate(uint256 _universityIDToken, address signer ) public  onlyUniversityIssuer onlyActiveCertificate returns (bool)
   {
       require (dateSignatureWallet[signer] == 0, "already signed by wallet"); //it can be signed by a signer only once

        walletSignerList.push(signer);
        dateSignatureWallet[signer] = block.timestamp;
        emit CertificateSigned(signer);
        return true;
   }
    /*Function to set the SC of the academic expedient manager of the certificate */
   function setAcademicExpedientSC(uint256 _universityIDToken, address _academicExpedientSC) public  onlyUniversityIssuer() onlyActiveCertificate returns(bool){
         academicExpedientSC = _academicExpedientSC;
         return true;
    }

    /*Function to set the SC of  the document manager of the certificate with the index to the  attached documents*/
    function setdocumentManagerSC(uint256 _universityIDToken,address _documentManagerSC) public  onlyUniversityIssuer() onlyActiveCertificate returns(bool){
        documentManagerSC = _documentManagerSC;
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