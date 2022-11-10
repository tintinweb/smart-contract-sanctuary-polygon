//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CertificateStorage.sol";
import "./TokenManagerv4.sol";

interface DocumentRepository {
    function setConfig(uint certificateId, string memory URLDirectory, string memory BASEDocURL) external returns(bool);
    function addDocument(uint certificateId,uint docId, uint docType,  string memory docName, string memory docReference) external returns(bool);
    function hasDocuments(uint certificateId) external view returns(bool);
    function getDocumentById(uint certificateId, uint docId ) external view returns( uint docType,  string memory docName, string memory docReference);
    function getDocuments(uint certificateId ) external  view returns(uint count, uint[] memory docId, uint[] memory docType,  string[] memory docName, string[] memory docReference);
}

/// @title Academic Institution Manager module
/// @author Blockchain Qualifications
/// @notice Academic Institution that operates and issues blockchain academic certificates, badges and documents.
contract BQInstitutionManager  {

 struct UsersInformation
 {
    string name;
    string userinfo;
    bool isActive;
    bool canCreateCertificates;
    bool canDeleteCertificates;
    bool canSignCertififcates;
    bool isAdmin;
    uint8 role;
    uint256 lastUpdate;
 }

/* Academic Institution detail */
string public academicInstitutionName;
string  academicInstitutionInformation;
uint256 creationDate;
address institutionManagerWallet;
bool    active;
address  migration_AcademicInstitution_NewSC;
address  migration_AcademicInstitution_PreviousSC;

/* Users information module */
mapping (address => UsersInformation) public usersList;

/* BCQ control */
string   moduleName = "Academic Institution Management Module";
uint8    SCVersion = 4;
address  BQAdminModuleSC;
address  certStorageSC;
address  certTokenManagerSC;
address  docRepositorySC;

/*Events*/
event CertificateCreated( uint256 indexed _certificateID, string indexed _certificateReferencec);
event CertificateDeleted(uint256 indexed _certificateID);
event CertificateUpdated(uint8 indexed _operationType, uint256 indexed _certificateID);
/*operationType: 1-sign certificate  / 2-set additional information SC  / 3- set owner / 4-unset owner */

/*Permission Control modifieres*/
modifier onlyBlockChainQualificationsManager {
    require(msg.sender == BQAdminModuleSC);
     _;
}

modifier onlyIfActive {
    require (active);
     _;
}
modifier requireAdminPermission {
    if(msg.sender != institutionManagerWallet) {
        require(usersList[msg.sender].isActive);
        require(usersList[msg.sender].isAdmin );
    }
    _;
}
modifier requireInstitutionManagerPermission {
    require(msg.sender == institutionManagerWallet);
    _;
}
modifier requireSignCertPermission {
    require(usersList[msg.sender].isActive);
    require(usersList[msg.sender].canSignCertififcates);
    _;
}
modifier  requireCreateCertPermission {
    require(usersList[msg.sender].isActive);
    require(usersList[msg.sender].canCreateCertificates);
    _;
}
modifier  requireDeleteCertPermission {
    require(usersList[msg.sender].isActive);
    require(usersList[msg.sender].canDeleteCertificates);
    _;
}

function createInstitution (address _BCQAdminModuleSC, address _institutionManagerWallet, string memory  _InstitutionName, address  certificateStorageFactory, address certTokenManagerFactorySC) public  returns(bool){
        require(BQAdminModuleSC == address(0)); //Institution already created

        BQAdminModuleSC = _BCQAdminModuleSC;
        academicInstitutionName = _InstitutionName;
        institutionManagerWallet = _institutionManagerWallet;
        _updateUser(_institutionManagerWallet,"","",false,false,false,false,true,1);
        certStorageSC = CertificateStorageFactory(certificateStorageFactory).createCertificateStorage();
        assert(CertificateStorage(certStorageSC).initCertificateStorage(_BCQAdminModuleSC));

        certTokenManagerSC = CertificateTokenManagerFactory(certTokenManagerFactorySC).createCertificateTokenManager();
        assert(CertificateTokenManager(certTokenManagerSC).initCertificateTokenManager(_BCQAdminModuleSC,_InstitutionName));
        creationDate = block.timestamp;
        active = true;
        return true;
}



//======== Certificate Operation functions ======/
function createCertificate(uint8 certificateType, uint256 certificateID,  string memory certificateReference, string memory  certificateInfo) public onlyIfActive requireCreateCertPermission {
     assert(CertificateStorage(certStorageSC).createCertificate(certificateType,certificateID,certificateReference, certificateInfo));

     emit CertificateCreated( certificateID,  certificateReference);
}

//certificate creation function
function createCertificate(uint8 certificateType, uint256 certificateID, string memory certificateReference, string memory  certificateInfo, address _to) public   {
      createCertificate(certificateType,certificateID,certificateReference,certificateInfo);
      if(_to != address(0)){
            setCertificateOwner(certificateID, _to);
      }
}

//Asign certificate to student wallet
function setCertificateOwner ( uint256 certificateID, address _studentWallet)   public  requireCreateCertPermission  {
    assert(CertificateTokenManager(certTokenManagerSC).setOwner(_studentWallet,certificateID));
    emit CertificateUpdated(3,certificateID);
}


//Delete certificate
function deleteCertificate( uint certificateId) public  requireDeleteCertPermission  {
    assert(CertificateStorage(certStorageSC).deleteCertificate(certificateId));
    if(ownerOf(certificateId)!=address(0)) {
        CertificateTokenManager(certTokenManagerSC).burn(certificateId);
    }
    emit CertificateDeleted(certificateId);
}

//Sign certificate
function signCertificate( uint certificateId) internal  {
    assert(CertificateStorage(certStorageSC).signCertificate(certificateId, msg.sender));
    emit CertificateUpdated(1,certificateId);
}
function signCertificates( uint[] memory certificatesIds) public  onlyIfActive  requireSignCertPermission{
    for(uint i = 0; i < certificatesIds.length; i++) {
        signCertificate(certificatesIds[i]);
    }
}

function setCertificateVisibility(  uint certificateId, bool showCertificateContent) public  {
    require((usersList[msg.sender].isActive && usersList[msg.sender].canCreateCertificates )|| ownerOf(certificateId) == msg.sender, "Unauthorized");
    assert(CertificateStorage(certStorageSC).setCertificateVisibility(certificateId,showCertificateContent));
}

function setCertificateDocRepositoryConfig(uint certificateId,string memory URLDirectory, string memory BASEDocURL) public  returns(bool) {
    assert(DocumentRepository(docRepositorySC).setConfig(certificateId,URLDirectory,BASEDocURL));
    return true;
}
function setAddCertificateDocument(uint certificateId,uint docId, uint docType,  string memory docName, string memory docReference) public  returns(bool) {
     assert(DocumentRepository(docRepositorySC).addDocument(certificateId,docId,docType,docName,docReference));
    return true;
}



//======== Maintainance of users and permissions =============== //


/*Function to add or update a wallet as an authorized user of the academic institution*/
function updateUser ( address _walletUser, string memory _name, string memory _userinfo, bool _isActive, bool _canCreateCertificates, bool _canDeleteCertificates,bool _canSignCertififcates, bool _isAdmin, uint8 _role ) public requireAdminPermission{
    _updateUser ( _walletUser,  _name,  _userinfo,  _isActive,  _canCreateCertificates,  _canDeleteCertificates, _canSignCertififcates,  _isAdmin,  _role );
}

function _updateUser ( address _walletUser, string memory _name, string memory _userinfo, bool _isActive,  bool _canCreateCertificates, bool _canDeleteCertificates,bool _canSignCertififcates, bool _isAdmin, uint8 _role ) internal{
   usersList[_walletUser] = UsersInformation(  _name,  _userinfo,  _isActive, _canCreateCertificates,  _canDeleteCertificates, _canSignCertififcates, _isAdmin, _role , block.timestamp);
}


//======== Public information and validation =============== //

function getCertificatesIssued() public view returns(uint256 count, uint[] memory certificateList) {
    return CertificateStorage(certStorageSC).getCertificatesIssued();
}
function isCertificateIssuedByInstitution(uint certificateId) public view returns(bool) {
    return CertificateStorage(certStorageSC).isCertificateIssuedByInstitution(certificateId);
}

function getCertificateIDbyReference(string memory certificateReference) public view returns(uint certificateId) {
   return CertificateStorage(certStorageSC).getCertificateIDbyReference(certificateReference);
}


function certificatesOf(address owner) public view   returns (uint count, uint256[] memory certificateList) {
     return CertificateTokenManager(certTokenManagerSC).certificatesOf(owner);
}



function validateAndRetrieveCertificateData4Viewer(string memory certificateReference) public view returns(bool valid,uint8 docType,uint256 certificateID, bool activeCertificate, uint256 certificateCreationDate, string memory certificateDetail,address studentWallet, uint256 totalSignatures,bool hasAdditionalDocuments,string memory institutionNameAndDetail, address institutionIdentity) {
    uint certificateId =   CertificateStorage(certStorageSC).getCertificateIDbyReference(certificateReference);
    return validateAndRetrieveCertificateData4ViewerById(certificateId);
}
function validateAndRetrieveCertificateData4ViewerById(uint certificateId) internal view returns(bool valid,uint8 docType,uint256 certificateID, bool activeCertificate, uint256 certificateCreationDate, string memory certificateDetail,address studentWallet, uint256 totalSignatures,bool hasAdditionalDocuments,string memory institutionNameAndDetail, address institutionIdentity) {
    institutionNameAndDetail = string(abi.encodePacked('{"name":"',academicInstitutionName, '", "detail":',academicInstitutionInformation,'}'));
    certificateID = certificateId;
    if(isCertificateIssuedByInstitution(certificateId)) {

        ( , activeCertificate, certificateDetail,certificateCreationDate, totalSignatures,docType,,) = CertificateStorage(certStorageSC).getCertificateDetail(certificateId);

        studentWallet = ownerOf(certificateID);
        institutionIdentity= academicInstitutionIdentity();
        if(docRepositorySC !=address(0)) hasAdditionalDocuments = DocumentRepository(docRepositorySC).hasDocuments(certificateId);
        return (true,docType,certificateID,activeCertificate,certificateCreationDate,certificateDetail, studentWallet,totalSignatures,hasAdditionalDocuments,institutionNameAndDetail,institutionIdentity);
    }
    return (false,docType,0,false,0,"",address(0),0,false,institutionNameAndDetail,address(0));
}
function getCertificateSignatures(uint certificateId) public view returns(uint count, address[] memory signerwalletList,uint256[] memory dateSignatureList,string[] memory signerNameList, string[] memory signerInfoList) {
    return CertificateStorage(certStorageSC).getSignatures(certificateId);
}

function getCertificateContentByReference(string memory certificateReference) public view returns(uint certificateId, string memory certificateDetail) {

    return CertificateStorage(certStorageSC).getCertificateContentByReference(certificateReference);
}
function getCertificateContentById(uint certifiateId) public view returns(string memory certificateDetail) {
    return CertificateStorage(certStorageSC).getCertificateContentById(certifiateId);
}
function getCertificateURL(uint certificateId) public view returns(string memory) {
        return CertificateStorage(certStorageSC).getCertificateURL(certificateId);
}

function getAcademicInstitutionInformation() public view returns(string memory institutionName, string memory institutionDetail, bool isActive, uint256 dateCreatio, uint256 certificatesIssued, address docRepositoryAddress, uint8 scv ) {
    uint certificatesIssuedCount = CertificateStorage(certStorageSC).getCertificateIssuedCount();
    return (academicInstitutionName, academicInstitutionInformation, active,creationDate,certificatesIssuedCount,docRepositorySC,SCVersion);
}
function getModuleConfiguration() public view returns(string memory name, uint8 SCversion, address certificateStorageModuleSC, address tokenManagerModuleSC, address docRepository, address BQAdministrationModuleSC, address institutionAdminWallet){
    return (moduleName,SCVersion,certStorageSC,certTokenManagerSC,docRepositorySC,BQAdminModuleSC,institutionManagerWallet);

}

/*Function to get the information of a academic institution user wallet*/
function getWalletInfo (address _wallet) public view returns (string memory, string memory){
      return  (usersList[_wallet].name, usersList[_wallet].userinfo);
}

/*Function to get the permissions of a academic institution user wallet*/
function getWalletPermission (address _walletUser) public view returns ( bool, bool,bool, bool,bool, uint8, uint256 ){
      return  (
     usersList[_walletUser].isActive,
     usersList[_walletUser].canCreateCertificates,
     usersList[_walletUser].canDeleteCertificates,
     usersList[_walletUser].canSignCertififcates,
     usersList[_walletUser].isAdmin,
     usersList[_walletUser].role,
     usersList[_walletUser].lastUpdate );
}

function academicInstitutionIdentity() public view returns(address ){
   if(migration_AcademicInstitution_NewSC != address(0)) return migration_AcademicInstitution_NewSC;
   else return address(this);
}

//Certificate Token user Management

function ownerOf(uint256 tokenId) public view returns (address owner) {
    return  CertificateTokenManager(certTokenManagerSC).ownerOf(tokenId);
}

function tokenURI(uint256 tokenId) public view returns (string memory tokenUri) {
    return CertificateTokenManager(certTokenManagerSC).tokenURI(tokenId);
}

function getWalletCertificateCollectionAddress() public view returns(address) {
    return certTokenManagerSC;
}


//======== BCQ management and migrations functions =============== //

function updateInstitutionInformation (string memory _newInformationJSON) public onlyBlockChainQualificationsManager returns (bool) {
    academicInstitutionInformation = _newInformationJSON;
    return true;
}

function changeCertLogicModuleSC(address _newcertificateStorageSCAddress) public onlyBlockChainQualificationsManager returns (bool){
    certStorageSC = _newcertificateStorageSCAddress;
    return true;
}

function changeTokenManagerModuleSC(address _newBCQTokenManagerModuleSCAddress) public onlyBlockChainQualificationsManager returns (bool){
    certTokenManagerSC = _newBCQTokenManagerModuleSCAddress;
    return true;
}
function changeAdditionalDocumentModuleSC(address _newDocRepositorySC) public onlyBlockChainQualificationsManager returns (bool){
    docRepositorySC = _newDocRepositorySC;
    return true;
}


function setNewBCQAdministrationManagerModuleSC(address _newBCQAdministrationManagerModuleSC) public onlyBlockChainQualificationsManager returns(bool){
        BQAdminModuleSC = _newBCQAdministrationManagerModuleSC;
        return true;
}


function changeinstitutionManager(address _newinstitutionManagerWallet)  onlyBlockChainQualificationsManager public returns(bool){
    institutionManagerWallet = _newinstitutionManagerWallet;
    _updateUser(_newinstitutionManagerWallet,"","",true,false,false,false,true,1);
    return true;
}

function activate(bool _active) public onlyBlockChainQualificationsManager returns(bool){
    active = _active;
    return true;
}

function migrateToNewSCVersion(address _migration_AcademicInstitution_NewSC) public requireInstitutionManagerPermission{
    migration_AcademicInstitution_NewSC = _migration_AcademicInstitution_NewSC;
}

function migrationSetPreviousSCVersion(address _migration_AcademicInstitution_PreviousSC) public requireInstitutionManagerPermission{
    migration_AcademicInstitution_PreviousSC = _migration_AcademicInstitution_PreviousSC;
}


}



contract BCQInstitutionManagerFactory  {
   // string public moduleName = "BCQ Factory";
    uint8 public SCVersion = 4;
    address public BCQAdministrationManagerModuleSC;

    modifier onlyBCQAdministrationManagerModule {
        require(BCQAdministrationManagerModuleSC == msg.sender);
         _;
    }

    constructor (address _BCQAdministrationManagerModuleSC)  {
       BCQAdministrationManagerModuleSC = _BCQAdministrationManagerModuleSC;
    }


    function newBCQAcademicInstitution(address _institutionManagerWallet, string memory  _InstitutionName, address   _BCQCertLogicModuleFactory, address _BCQcertTokenManagerFactory) public onlyBCQAdministrationManagerModule returns(address){
        BQInstitutionManager newInstitution = new BQInstitutionManager();
        assert(newInstitution.createInstitution(msg.sender, _institutionManagerWallet,_InstitutionName,  _BCQCertLogicModuleFactory,_BCQcertTokenManagerFactory));
        return address(newInstitution);
    }

}