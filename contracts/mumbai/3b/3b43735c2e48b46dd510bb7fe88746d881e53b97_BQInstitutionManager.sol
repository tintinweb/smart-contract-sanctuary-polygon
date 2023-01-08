//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CertificateStorage.sol";
import "./TokenManager.sol";

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

/* Academic Institution detail*/
string public academicInstitutionName;
string  academicInstitutionInformation;
uint256 creationDate;
address institutionManagerWallet;
bool    active;
address  migration_AcademicInstitution_NewSC;
address  migration_AcademicInstitution_PreviousSC;

/* Users information module */
mapping (address => UsersInformation) usersList;

/* BCQ control */
string   moduleName = "Academic Institution Management Module";
uint8    SCVersion = 4;
address  BQAdminModuleSC;
address  certStorageSC;
address  certTokenManagerSC;
address  docRepositorySC;

/*Events*/
event CertificateCreated(string indexed _certificateReference, uint256 indexed _certificateID);
event CertificateDeleted(uint256 indexed _certificateID);
event CertificateUpdated(uint8 indexed _operationType, uint256 indexed _certificateID);
/*operationType: 1-sign certificate  / 2-set additional information SC  / 3- set owner / 4-unset owner */
event AcademicInstitutionUpgrade(uint8 indexed _operation);


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
        require(usersList[msg.sender].isAdmin );
    }
    _;
}
modifier requireInstitutionManagerPermission {
    require(msg.sender == institutionManagerWallet);
    _;
}
modifier requireSignCertPermission {
    require(usersList[msg.sender].canSignCertififcates);
    _;
}
modifier  requireCreateCertPermission {
    require(usersList[msg.sender].canCreateCertificates);
    _;
}
modifier  requireDeleteCertPermission {
    require(usersList[msg.sender].canDeleteCertificates);
    _;
}

/// @notice Creates the institution. An institution can be created only once
function createInstitution (address _BCQAdminModuleSC, address _institutionManagerWallet, string memory  _InstitutionName, address  certificateStorageFactory, address certTokenManagerFactorySC) public  returns(bool){
        require(BQAdminModuleSC == address(0)); //Institution already created

        BQAdminModuleSC = _BCQAdminModuleSC;
        academicInstitutionName = _InstitutionName;
        institutionManagerWallet = _institutionManagerWallet;
        _updateUser(_institutionManagerWallet,"","",false,false,false,false,true,1);
        creationDate = block.timestamp;
        active = true;

        //Create and assign Certificate Storage
        certStorageSC = CertificateStorageFactory(certificateStorageFactory).createCertificateStorage();
        assert(CertificateStorage(certStorageSC).initCertificateStorage(_BCQAdminModuleSC));

        //Create and assign Token Manager
        certTokenManagerSC = CertificateTokenManagerFactory(certTokenManagerFactorySC).createCertificateTokenManager();
        assert(CertificateTokenManager(certTokenManagerSC).initCertificateTokenManager(_BCQAdminModuleSC,_InstitutionName));

        return true;
}



//======== Certificate Operation functions ======/
/// @notice Creates a Certificate which is stored in the Certificate Storage Module. The content of the issued certificate cannot be modified once created.
function createCertificate(uint8 certificateType, uint256 certificateID,  string memory certificateReference, string memory  certificateInfo, uint32 courseId) public onlyIfActive requireCreateCertPermission {
     assert(CertificateStorage(certStorageSC).createCertificate(certificateType,certificateID,certificateReference, certificateInfo,courseId));

     emit CertificateCreated( certificateReference,certificateID);
}

/// @notice Creates a Certificate and if we have a student wallet we assign it.
function createCertificate(uint8 certificateType, uint256 certificateID, string memory certificateReference, string memory  certificateInfo, uint32 courseId, address _to) public   {
      createCertificate(certificateType,certificateID,certificateReference,certificateInfo,courseId);
      if(_to != address(0)){
            setCertificateOwner(certificateID, _to);
      }
}

/// @notice Assigns the certificate to student wallet
function setCertificateOwner ( uint256 certificateID, address _studentWallet)   public  requireCreateCertPermission  {
    assert(CertificateTokenManager(certTokenManagerSC).setOwner(_studentWallet,certificateID));
    emit CertificateUpdated(3,certificateID);
}


/// @notice internal function to delete a certificate
function _deleteCertificate( uint certificateId) internal  {
    assert(CertificateStorage(certStorageSC).deleteCertificate(certificateId));
    if(wt_ownerOf(certificateId)!=address(0)) {
        CertificateTokenManager(certTokenManagerSC).burn(certificateId);
    }
    emit CertificateDeleted(certificateId);
}

/// @notice Deletes a list of Certificates
function deleteCertificate( uint[] memory certificatesIds) public  onlyIfActive  requireDeleteCertPermission{
    for(uint i = 0; i < certificatesIds.length; i++) {
        _deleteCertificate(certificatesIds[i]);
    }
}

/// @notice  internal function to sign a certifiate
function _signCertificate( uint certificateId) internal  {
    assert(CertificateStorage(certStorageSC).signCertificate(certificateId, msg.sender));
    emit CertificateUpdated(1,certificateId);
}

/// @notice Signs a list of Certificates
function signCertificates( uint[] memory certificatesIds) public  onlyIfActive requireSignCertPermission{
    for(uint i = 0; i < certificatesIds.length; i++) {
        _signCertificate(certificatesIds[i]);
    }
}

/// @notice A student and the academic institution can manage the content visibility of a certifiate
function setCertificateVisibility(  uint certificateId, bool showCertificateContent) public  {
    require(usersList[msg.sender].canCreateCertificates || wt_ownerOf(certificateId) == msg.sender, "Unauthorized");
    assert(CertificateStorage(certStorageSC).setCertificateVisibility(certificateId,showCertificateContent));
}

/// @notice Config the additional document repository of a certificate
function setCertificateDocRepositoryConfig(uint certificateId,string memory URLDirectory, string memory BASEDocURL) public  requireAdminPermission {
    assert(DocumentRepository(docRepositorySC).setConfig(certificateId,URLDirectory,BASEDocURL));
}

/// @notice Add an additional document to the certificate document repository
function setAddCertificateDocument(uint certificateId,uint docId, uint docType,  string memory docName, string memory docReference) public requireCreateCertPermission{
     assert(DocumentRepository(docRepositorySC).addDocument(certificateId,docId,docType,docName,docReference));
}

function setCourseInformation(uint32 courseId,string memory info) public requireAdminPermission  {
    assert(CertificateStorage(certStorageSC).setCourse(courseId,info));
}


//======== Maintainance of users and permissions =============== //


/// @notice Function to add or update a wallet as an authorized user of the academic institution
function updateUser ( address _walletUser, string memory _name, string memory _userinfo, bool _isActive, bool _canCreateCertificates, bool _canDeleteCertificates,bool _canSignCertififcates, bool _isAdmin, uint8 _role ) public requireAdminPermission{
    _updateUser ( _walletUser,  _name,  _userinfo,  _isActive,  _canCreateCertificates,  _canDeleteCertificates, _canSignCertififcates,  _isAdmin,  _role );
}

function _updateUser ( address _walletUser, string memory _name, string memory _userinfo, bool _isActive,  bool _canCreateCertificates, bool _canDeleteCertificates,bool _canSignCertififcates, bool _isAdmin, uint8 _role ) internal{
   usersList[_walletUser] = UsersInformation(  _name,  _userinfo,  _isActive, _canCreateCertificates,  _canDeleteCertificates, _canSignCertififcates, _isAdmin, _role , block.timestamp);
}


//======== Public information and validation =============== //

/// @notice Retrieve the list of Certificates issued (certificateIds)
function getCertificatesIssued() public view returns(uint256 count, uint[] memory certificateList) {
    return CertificateStorage(certStorageSC).getCertificatesIssued();
}

/// @notice Verify if a certificate is issued by the academic institution
function isCertificateIssuedByInstitution(uint certificateId) public view returns(bool) {
    return CertificateStorage(certStorageSC).isCertificateIssuedByInstitution(certificateId);
}

/// @notice Retrieve the certificate content (by certificate reference)
function getCertificateContentByReference(string memory certificateReference) public view returns(uint certificateId, string memory certificateDetail) {
    return CertificateStorage(certStorageSC).getCertificateContentByReference(certificateReference);
}

/// @notice Function used by the public certificate viewer used to retrive all the certificate details. (by certificate reference)
function validateAndRetrieveCertificateData(string memory certificateReference) public view returns(bool valid,uint8 docType,uint256 certificateID, bool activeCertificate, uint256 certificateCreationDate, string memory certificateDetail,address studentWallet, uint256 totalSignatures,bool hasAdditionalDocuments, string memory courseInfo,string memory institutionNameAndDetail, address institutionIdentity) {
    uint certificateId =   CertificateStorage(certStorageSC).getCertificateIDbyReference(certificateReference);
    return validateAndRetrieveCertificateDataById(certificateId);
}
/// @notice Function used by the public certificate viewer used to retrive all the certificate details. (by certificate CertificateId)
function validateAndRetrieveCertificateDataById(uint certificateId) internal view returns(bool valid,uint8 docType,uint256 certificateID, bool activeCertificate, uint256 certificateCreationDate, string memory certificateDetail,address studentWallet, uint256 totalSignatures,bool hasAdditionalDocuments,string memory courseInfo, string memory institutionNameAndDetail, address institutionIdentity) {

    certificateID = certificateId;
    institutionNameAndDetail = string(abi.encodePacked('{"name":"',academicInstitutionName, '", "detail":',academicInstitutionInformation,'}'));
    if(isCertificateIssuedByInstitution(certificateId)) {
        ( , activeCertificate, certificateDetail,certificateCreationDate, totalSignatures,docType,,,) = CertificateStorage(certStorageSC).getCertificateDetail(certificateId);
        ( courseInfo) = CertificateStorage(certStorageSC).getCertificateCourseInfo(certificateId);
        studentWallet = wt_ownerOf(certificateID);
        institutionIdentity= academicInstitutionIdentity();
        if(docRepositorySC !=address(0)) hasAdditionalDocuments = DocumentRepository(docRepositorySC).hasDocuments(certificateId);
        return (true,docType,certificateID,activeCertificate,certificateCreationDate,certificateDetail, studentWallet,totalSignatures,hasAdditionalDocuments,courseInfo,institutionNameAndDetail,institutionIdentity);
    }
    return (false,docType,0,false,0,"",address(0),0,false,"",institutionNameAndDetail,address(0));
}
/// @notice Retrieve the signature detail of a certificate
function getCertificateSignatures(uint certificateId) public view returns(uint count, address[] memory signerwalletList,uint256[] memory dateSignatureList,string[] memory signerNameList, string[] memory signerInfoList) {
    return CertificateStorage(certStorageSC).getSignatures(certificateId);
}

/// @notice Retrieve the Academic institution public details
function getAcademicInstitutionInformation() public view returns(string memory institutionName, string memory institutionDetail, bool isActive, uint256 dateCreatio, uint256 certificatesIssued, address docRepositoryAddress, uint8 scv ) {
    uint certificatesIssuedCount = CertificateStorage(certStorageSC).getCertificateIssuedCount();
    return (academicInstitutionName, academicInstitutionInformation, active,creationDate,certificatesIssuedCount,docRepositorySC,SCVersion);
}

/// @notice Retrieve the academic institution module configuration
function getModuleConfiguration() public view returns(string memory name, uint8 SCversion, address certificateStorageModuleSC, address tokenManagerModuleSC, address docRepository, address BQAdministrationModuleSC, address institutionAdminWallet){
    return (moduleName,SCVersion,certStorageSC,certTokenManagerSC,docRepositorySC,BQAdminModuleSC,institutionManagerWallet);

}

/// @notice Retrieve the information of an academic institution member wallet
function getWalletInfo (address _wallet) public view returns (string memory, string memory){
      return  (usersList[_wallet].name, usersList[_wallet].userinfo);
}

/// @notice Retrieve the operation permissions of an academic institution user wallet
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

/// @notice Retrieve the academic institution identity (this smart contract address if not migrated or the new Smart Contract if upgraded to new version)
function academicInstitutionIdentity() public view returns(address ){
   if(migration_AcademicInstitution_NewSC != address(0)) return migration_AcademicInstitution_NewSC;
   else return address(this);
}



//======== Certificate Token functions =============== //

/// @notice Retrieve the certificate collection manager address
function wt_collectionAddress() public view returns(address) {
    return certTokenManagerSC;
}

//Certificate Token user Management
/// @notice Retrieve the student wallet owner of a certificate
function wt_ownerOf(uint256 tokenId) public view returns (address owner) {
    return  CertificateTokenManager(certTokenManagerSC).ownerOf(tokenId);
}

/// @notice Retrieve the certificate URI
function wt_tokenURI(uint256 tokenId) public view returns (string memory tokenUri) {
    return CertificateTokenManager(certTokenManagerSC).tokenURI(tokenId);
}

/// @notice Retrieve the list of certificates assigned to a student (student wallet)
function wt_gertificatesOf(address owner) public view   returns (uint count, uint256[] memory certificateList) {
     return CertificateTokenManager(certTokenManagerSC).certificatesOf(owner);
}

/// @notice Retrieve the CertificateId by the Certificate Reference
function wt_getIDbyReference(string memory certificateReference) public view returns(uint certificateId) {
   return CertificateStorage(certStorageSC).getCertificateIDbyReference(certificateReference);
}
/// @notice Retrieve the CertificateId by the Certificate Reference
function wt_getCertificateReferenceById(uint certificateId) public view returns(string memory certificateReference) {
   return CertificateStorage(certStorageSC).getCertificateReferenceById(certificateId);
}

/// @notice Retrieve the certificate viewer URL
function wt_getCertificateURL(uint certificateId) public view returns(string memory) {
        return CertificateStorage(certStorageSC).getCertificateURL(certificateId);
}


//======== BQ management and migrations functions =============== //
/// @notice Update the institution public information
function updateInstitutionInformation (string memory _newInformationJSON) public onlyBlockChainQualificationsManager returns (bool) {
    academicInstitutionInformation = _newInformationJSON;
    emit AcademicInstitutionUpgrade(1);
    return true;
}

/// @notice Upgrade the Certificate Storage Manager module
function changeCertLogicModuleSC(address _newcertificateStorageSCAddress) public onlyBlockChainQualificationsManager returns (bool){
    certStorageSC = _newcertificateStorageSCAddress;
    emit AcademicInstitutionUpgrade(2);
    return true;
}

/// @notice Upgrade the Token Manager module
function changeTokenManagerModuleSC(address _newBCQTokenManagerModuleSCAddress) public onlyBlockChainQualificationsManager returns (bool){
    certTokenManagerSC = _newBCQTokenManagerModuleSCAddress;
    emit AcademicInstitutionUpgrade(3);
    return true;
}

/// @notice Upgrade the Additional document Manager module
function changeAdditionalDocumentModuleSC(address _newDocRepositorySC) public onlyBlockChainQualificationsManager returns (bool){
    docRepositorySC = _newDocRepositorySC;
    emit AcademicInstitutionUpgrade(4);
    return true;
}

/// @notice Upgrade to new BQ Admin module
function setNewBCQAdministrationManagerModuleSC(address _newBCQAdministrationManagerModuleSC) public onlyBlockChainQualificationsManager returns(bool){
        require(_newBCQAdministrationManagerModuleSC != address(0));
        BQAdminModuleSC = _newBCQAdministrationManagerModuleSC;
        emit AcademicInstitutionUpgrade(5);
        return true;
}

/// @notice Update institution manager
function changeinstitutionManager(address _newinstitutionManagerWallet)  onlyBlockChainQualificationsManager public returns(bool){
    institutionManagerWallet = _newinstitutionManagerWallet;
    _updateUser(_newinstitutionManagerWallet,"","",true,false,false,false,true,1);
    emit AcademicInstitutionUpgrade(6);
    return true;
}

/// @notice Activate the academic institution
function activate(bool _active) public onlyBlockChainQualificationsManager returns(bool){
    active = _active;
    emit AcademicInstitutionUpgrade(7);
    return true;
}

/// @notice Migration process: Set New academic institution Smart Contract address
function migrateToNewSCVersion(address _migration_AcademicInstitution_NewSC) public requireInstitutionManagerPermission{
    migration_AcademicInstitution_NewSC = _migration_AcademicInstitution_NewSC;
    emit AcademicInstitutionUpgrade(8);
}

/// @notice Migration process: Set Previous academic institution Smart Contract address
function migrationSetPreviousSCVersion(address _migration_AcademicInstitution_PreviousSC) public requireInstitutionManagerPermission{
    migration_AcademicInstitution_PreviousSC = _migration_AcademicInstitution_PreviousSC;
    emit AcademicInstitutionUpgrade(9);
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