/**
 *Submitted for verification at polygonscan.com on 2022-05-27
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
    function createCertificate (string memory  _certificateInfo )   public  returns(bool){
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



/// @title LogicModule  interface
interface BCQInstitutionManagerSC {
   function addCertificate2List(address certificateAddress, uint256 certificateID) external returns(bool);
}

contract BCQCertificateLogicModule {

    /*public atributes*/
    string public moduleName = "BlockChainQualifications Logic module";
    uint8 public SCVersion = 2;
    address public BCQAdministrationManagerModuleSC;
    mapping (address => bool) public AuthorizedUniversityList;
    mapping (address => uint256) public universityIDTokens;

    /*modifiers*/
    modifier onlyBCQAdministrationManagerModule {
        require(BCQAdministrationManagerModuleSC == msg.sender);
         _;
    }
    modifier onlyAuthorizedUniversity {
        require (AuthorizedUniversityList[msg.sender]);
        _;
    }

    constructor (address _BCQAdministrationManagerModuleSC)  {
       BCQAdministrationManagerModuleSC = _BCQAdministrationManagerModuleSC;
    }

    //=========  Module migration functions  =================//
    function setNewBCQAdministrationManagerModuleSC(address _newBCQAdministrationManagerModuleSC) public onlyBCQAdministrationManagerModule returns(bool){
        require(_newBCQAdministrationManagerModuleSC != address(0));
        require(BCQAdministrationManagerModuleSC != _newBCQAdministrationManagerModuleSC);
        BCQAdministrationManagerModuleSC = _newBCQAdministrationManagerModuleSC;
        return true;
    }

    //===== Institution Authorization functions  =================//
    function setAuthorizedUniversity(address _universitySC,uint256 _universityIDToken, bool _authorization) public onlyBCQAdministrationManagerModule returns(bool)
    {
        require(_universitySC != address(0));
        require (_universityIDToken != 0);
        universityIDTokens[_universitySC] = _universityIDToken;
        AuthorizedUniversityList[_universitySC] = _authorization;
        return true;
    }

    //===== Institution operation with certificate functions ===== //

    function createCertificate()   public onlyAuthorizedUniversity returns(address){
        require(universityIDTokens[msg.sender] != 0, "Unauthorized");
        //Certificate creation
        address certificateAddress = address(new AcademicCertificate());
        //validate the new certificate address is valid (not 0)
        assert(certificateAddress != address(0));

        return certificateAddress;
    }


}