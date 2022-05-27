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

/* certificate info */
    string public certificateDetailJSON;
    uint256 public dateCreationBCCertificate;
    address public additionalInformationSC;
    bool public activeCertificate;
    uint256 public dateDeletion;
    
/* Sign info */
  address[] public walletSignerList;
  mapping (address => uint256) public dateSignatureWallet;

/*   Manager addresses   */
    address public BCQCertificateLogicAddress;
    uint8 public SCVersion = 2;

/*modifiers*/
    modifier onlyUniversityIssuer(address _universitySCAddress) {
         require(msg.sender == BCQCertificateLogicAddress,"only the logicModule who create it can operate");
         require(universitySCAddress == _universitySCAddress,"only the academic institution who create it can operate");
        _;
    }

    modifier onlyActiveCertificate() {
        require (activeCertificate);
        _;
    }

    event CertificateCreated( address _certificateAddress);
    event CertificateSigned( address indexed _signer);
    event CertificateDeleted( uint256  _dateDelete);

    constructor ()  {
        //Set Blockchain Qualifications logic Module who operates it
        BCQCertificateLogicAddress = msg.sender;
    }

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
    function deleteCertificate  (address _universitySCAddress) public  onlyUniversityIssuer(_universitySCAddress) onlyActiveCertificate returns(bool){
        activeCertificate=false;
        certificateDetailJSON = "";
        dateDeletion=block.timestamp;
        emit CertificateDeleted(dateDeletion);
        return true;
  }

   /// @notice Signature of the certificate by the academic institution authorized personnel
   function signCertificate(address _universitySCAddress) public  onlyUniversityIssuer(_universitySCAddress) onlyActiveCertificate returns (bool)
   {
       address signer = tx.origin;
       require (dateSignatureWallet[signer] == 0, "already signed by wallet"); //it can be signed by a signer only once

        walletSignerList.push(signer);
        dateSignatureWallet[signer] = block.timestamp;
        emit CertificateSigned(signer);
        return true;
   }
    /// @notice Function to set the SC where additional academic information of the certiticate is registered */
   function setAdditionalInformationSC(address _universitySCAddress, address _additionalInformationSC) public  onlyUniversityIssuer(_universitySCAddress) onlyActiveCertificate returns(bool){
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

    function createCertificate(uint256 certificateID,  string memory  _certificateInfo, address /*creatorWallet*/)   public onlyAuthorizedUniversity returns(bool){
        require(universityIDTokens[msg.sender] != 0, "Unauthorized");
        //Certificate creation
        AcademicCertificate newCertificate = new AcademicCertificate();
        //validate the new certificate address is valid (not 0)
        assert(address(newCertificate) != address(0));
        assert(newCertificate.createCertificate(msg.sender,_certificateInfo));
        //validate the new certificate addess is add to the list of in the university certificates expelled
        assert(BCQInstitutionManagerSC(msg.sender).addCertificate2List(address(newCertificate), certificateID));
        return true;
    }

    function deleteCertificate(address _certificateAddress)  public onlyAuthorizedUniversity returns(bool){
        assert(AcademicCertificate(_certificateAddress).deleteCertificate(msg.sender));
        return true;
    }

    function signCertificate(address _certificateAddress, address /*signer*/) public onlyAuthorizedUniversity returns (bool) {
        assert(AcademicCertificate(_certificateAddress).signCertificate(msg.sender));
        return true;
     }

    function updateCertificateAcademicInformation( address _certificateAddress, address   _additionalInformationSC)   public onlyAuthorizedUniversity returns(bool){
        assert(AcademicCertificate(_certificateAddress).setAdditionalInformationSC(msg.sender, _additionalInformationSC));
        return true;
    }


}