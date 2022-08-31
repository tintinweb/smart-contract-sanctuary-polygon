/**
 *Submitted for verification at polygonscan.com on 2022-08-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @title LogicModule  interface
interface BCQCertificateLogicModule {
    function createCertificate()   external returns(address);
}

interface AcademicCertificate {
    function createCertificate (uint256 _certificateID, string memory  _certificateInfo )   external  returns(bool);
    function deleteCertificate  () external    returns(bool);
    function signCertificate() external  returns (bool);
    function setCertificateOwnerAndUri (address _studentWallet, string memory uri) external returns(bool);
    function setAdditionalInformationSC( address _additionalInformationSC) external   returns(bool);
    function setCertificateVisibility(bool showCertificateContent) external returns(bool);
    function migrateAcademicInstitutionIdentity(address newAcademicInstitutionIdentity) external returns(bool);
}

interface CertificateTokenManager{
    function mint(address to,uint256 tokenId,address _certificateAddress)  external  returns (bool);
    function burn(uint256 tokenId) external;
    function setOwner(address to, uint256 tokenId )  external  returns(bool);
}

interface IERC721Metadata {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// @title Account-bound tokens
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
///  Note: the ERC-165 identifier for this interface is 0x5164cf47.
interface IERC4973 /* is ERC165, ERC721Metadata */ {
  /// @dev This emits when a new token is created and bound to an account by
  /// any mechanism.
  /// Note: For a reliable `from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Attest(address indexed to, uint256 indexed tokenId);
  /// @dev This emits when an existing ABT is revoked from an account and
  /// destroyed by any mechanism.
  /// Note: For a reliable `from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Revoke(address indexed to, uint256 indexed tokenId);
  /// @notice Count all ABTs assigned to an owner
  /// @dev ABTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param owner An address for whom to query the balance
  /// @return The number of ABTs owned by `owner`, possibly zero
  function balanceOf(address owner) external view returns (uint256);
  /// @notice Find the address bound to an ERC4973 account-bound token
  /// @dev ABTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param tokenId The identifier for an ABT
  /// @return The address of the owner bound to the ABT
  function ownerOf(uint256 tokenId) external view returns (address);
  /// @notice Destroys `tokenId`. At any time, an ABT receiver must be able to
  ///  disassociate themselves from an ABT publicly through calling this
  ///  function.
  /// @dev Must emit a `event Revoke` with the `address to` field pointing to
  ///  the zero address.
  /// @param tokenId The identifier for an ABT
  function burn(uint256 tokenId) external;
}

/// @title Academic Institution Manager module
/// @author Blockchain Qualifications
/// @notice Academic Institution that operates and issues blockchain academic certificates
contract BCQInstitutionManager is IERC4973,IERC721Metadata {

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
address public institutionManagerWallet;
bool  active;
address public migration_AcademicInstitution_NewSC;
address public migration_AcademicInstitution_OldSC;

/* Certificates */
mapping (uint256 => address) public certificateAddressByID;
mapping (address => uint256) public certificateIDByAddress;
mapping (address => uint256[]) internal certificatesOfOwner;
mapping (uint256 => bool) certificateTokenManaged;
mapping (address => bool) public certificateDeleted;
address[] public certificatesExpelledList;

/* Users information module */
mapping (address => UsersInformation) public usersList;

/* BCQ control */
uint8 public SCVersion = 3;
address public BCQAdminModuleSC;
address public certLogicModuleSC;
address public certTokenManagerSC;

/*Events*/
event CertificateCreated( uint256 indexed _certificateID, address indexed _certificateAddress);
event CertificateDeleted(address indexed _certificateAddress);
event CertificateMigrated(address indexed _certificateAddress);
event CertificateUpdated(uint256 indexed _operationType, address indexed _certificateAddress);
/*operationType: 1-sign certificate  / 2-set additional information SC */

/*Permission Control modifieres*/
modifier onlyBlockChainQualificationsManager {
    require(msg.sender == BCQAdminModuleSC);
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

function createInstitution (address _BCQAdminModuleSC, address _institutionManagerWallet, string memory  _InstitutionName, address   _BCQCertLogicModuleSCAddress, address _BCQcertTokenManagerSC) public  returns(bool){
        require(BCQAdminModuleSC == address(0)); //Institution already created

        BCQAdminModuleSC = _BCQAdminModuleSC;
        academicInstitutionName = _InstitutionName;
        institutionManagerWallet = _institutionManagerWallet;
        _updateUser(_institutionManagerWallet,"","",true,false,false,false,true,1);
        certLogicModuleSC = _BCQCertLogicModuleSCAddress;
        certTokenManagerSC = _BCQcertTokenManagerSC;
        creationDate = block.timestamp;
        active = true;
        return true;
}



//======== Certificate Operation functions ======/
function createCertificate( uint256 certificateID, string memory  _certificateInfo) public onlyIfActive requireCreateCertPermission {
      require(certificateAddressByID[certificateID] == address(0));  //Certificate already exists and cannot be changed or issued
      //Certificate creation with the current version of blockchain qualifications logic module
      address newCertificate = BCQCertificateLogicModule(certLogicModuleSC).createCertificate();
      assert(AcademicCertificate(newCertificate).createCertificate(certificateID, _certificateInfo));

      certificatesExpelledList.push(newCertificate);
      certificateAddressByID[certificateID] = newCertificate;
      certificateIDByAddress[newCertificate] = certificateID;

      emit CertificateCreated(  certificateID,  newCertificate);
}

//certificate creation function
function createCertificate( uint256 certificateID, string memory  _certificateInfo, address _to, string memory uri) public   {
      createCertificate(certificateID,_certificateInfo);

      if(_to != address(0)){
            setCertificateOwner(certificateID, _to, uri);
      }
}

//Asign certificate to student wallet
function setCertificateOwner ( uint256 certificateID, address _studentWallet, string memory uri)   public  requireCreateCertPermission  {
    require(certificateAddressByID[certificateID] != address(0));  //Verify exists
    require(certTokenManagerSC != address(0)); //"Certificate Token Manager not defined"
    if(!certificateTokenManaged[certificateID]) { //certificate token not created yet
        assert(CertificateTokenManager(certTokenManagerSC).mint(_studentWallet,certificateID,certificateAddressByID[certificateID]));
        certificateTokenManaged[certificateID] = true;
    }
    assert(CertificateTokenManager(certTokenManagerSC).setOwner(_studentWallet,certificateID));
    certificatesOfOwner[_studentWallet].push(certificateID);
    assert(AcademicCertificate(certificateAddressByID[certificateID]).setCertificateOwnerAndUri(_studentWallet,uri));
    emit Attest(_studentWallet,certificateID);
}


//Delete certificate
function deleteCertificate( address _certificateAddress) public  requireDeleteCertPermission  {
    assert(AcademicCertificate(_certificateAddress).deleteCertificate());
    if(certificateTokenManaged[certificateIDByAddress[_certificateAddress]]) {
        CertificateTokenManager(certTokenManagerSC).burn(certificateIDByAddress[_certificateAddress]);
    }
    certificateDeleted[_certificateAddress] = true;
    emit CertificateDeleted(_certificateAddress);
}

//Sign certificate
function signCertificate( address _certificateAddress) public onlyIfActive  requireSignCertPermission  {
    assert(AcademicCertificate(_certificateAddress).signCertificate());
    emit CertificateUpdated(1,_certificateAddress);
}

function setCertificateVisibility( address _certificateAddress, bool showCertificateContent) public  requireCreateCertPermission {
    assert(AcademicCertificate(_certificateAddress).setCertificateVisibility(showCertificateContent));
}


function setCertificateAdditionalInformationSC( address _certificateAddress, address _additionalInformationSC) public onlyIfActive requireCreateCertPermission {
    assert(AcademicCertificate(_certificateAddress).setAdditionalInformationSC(_additionalInformationSC));
    emit CertificateUpdated(2,  _certificateAddress);
}



//======== Maintainance of users and permissions =============== //


/*Function to add or update a wallet as an authorized user of the academic institution*/
function updateUser ( address _walletUser, string memory _name, string memory _userinfo, bool _isActive, bool _canCreateCertificates, bool _canDeleteCertificates,bool _canSignCertififcates, bool _isAdmin, uint8 _role ) public requireAdminPermission
{
    _updateUser ( _walletUser,  _name,  _userinfo,  _isActive,  _canCreateCertificates,  _canDeleteCertificates, _canSignCertififcates,  _isAdmin,  _role );
}

function _updateUser ( address _walletUser, string memory _name, string memory _userinfo, bool _isActive,  bool _canCreateCertificates, bool _canDeleteCertificates,bool _canSignCertififcates, bool _isAdmin, uint8 _role ) internal
{
   usersList[_walletUser] = UsersInformation(  _name,  _userinfo,  _isActive, _canCreateCertificates,  _canDeleteCertificates, _canSignCertififcates, _isAdmin, _role , block.timestamp);
}


//======== Public information and validation =============== //

function certificatesExpelledCount() public view returns (uint256 )
{
    return certificatesExpelledList.length;
}


function certificatesExpelled() public view returns(address[] memory) {
    return certificatesExpelledList;
}

function isCertificateExpelledbyinstitution(address _certificateAddress) public view returns(bool) {
    return certificateIDByAddress[_certificateAddress] > 0;
 }

function certificatesOf(address owner) public view   returns (uint count, uint256[] memory certificateList) {
    uint256[] memory certificatesId = new uint256[](certificatesOfOwner[owner].length);
    bool success;
    bytes memory returnData;
    address certificateowner;
    count = 0;
    for(uint i =0; i < certificatesOfOwner[owner].length; i++) {
         (success,returnData) = certTokenManagerSC.staticcall(abi.encodeWithSignature("ownerOf(uint256)",certificatesOfOwner[owner][i]));
         if(success) {
                (certificateowner) = abi.decode(returnData,(address));
                if(certificateowner == owner){
                    certificatesId[count] = certificatesOfOwner[owner][i];
                    count++;
                }
          }
     }
    return (count,certificatesId);
  }



function validateAndRetrieveCertificateData4Viewer(address _certificateAddress) public view returns(bool valid,uint256 certificateID, bool activeCertificate, uint256 certificateCreationDate, string memory certificateDetail,address studentWallet, uint256 totalSignatures,bool hasAdditionalInformation,string memory institutionNameAndDetail) {
    institutionNameAndDetail = string(abi.encodePacked('{"name":"',academicInstitutionName, '", "detail":',academicInstitutionInformation,'}'));

    if(isCertificateExpelledbyinstitution(_certificateAddress)) {

        (bool success, bytes memory returnData) = _certificateAddress.staticcall(abi.encodeWithSignature("getCertificateDetail()"));

        if(success) {
                (certificateID,activeCertificate, certificateDetail, certificateCreationDate, totalSignatures,hasAdditionalInformation, , , ) = abi.decode(returnData,(uint256,bool,string,uint256,uint256,bool,uint8,address,string));
        }

        return (true,certificateID,activeCertificate,certificateCreationDate,certificateDetail, ownerOf(certificateID),totalSignatures,hasAdditionalInformation,institutionNameAndDetail);
    }
    return (false,certificateIDByAddress[_certificateAddress],false,0,"",address(0),0,false,institutionNameAndDetail);
}

function getAcademicInstitutionInformation() public view returns(string memory institutionName, string memory institutionDetail, bool isActive, uint256 dateCreatio, uint256 certificatesIssued, uint8 scv ) {
    return (academicInstitutionName, academicInstitutionInformation, active,creationDate,certificatesExpelledList.length,SCVersion);
}


/*Function to get the information of a academic institution user wallet*/
function getWalletInfo (address _wallet) public view returns (string memory, string memory)
{
      return  (usersList[_wallet].name, usersList[_wallet].userinfo);
}

/*Function to get the permissions of a academic institution user wallet*/
function getWalletPermission (address _walletUser) public view returns ( bool, bool,bool, bool,bool, uint8, uint256 )
{
      return  (
     usersList[_walletUser].isActive,
     usersList[_walletUser].canCreateCertificates,
     usersList[_walletUser].canDeleteCertificates,
     usersList[_walletUser].canSignCertififcates,
     usersList[_walletUser].isAdmin,
     usersList[_walletUser].role,
     usersList[_walletUser].lastUpdate );
}

function academicInstitutionIdentity() public view returns(address )
{
   if(migration_AcademicInstitution_NewSC != address(0)) return migration_AcademicInstitution_NewSC;
   else return address(this);
}

//======== EIP4973 functions =============== //
function name() public view  returns (string memory) {
    return string(abi.encodePacked(academicInstitutionName, " Certificate"));
}

function symbol() public pure returns (string memory) {
    return "";
}

function tokenURI(uint256 tokenId) public view returns (string memory tokenUri) {
        (bool success, bytes memory returnData) = certTokenManagerSC.staticcall(abi.encodeWithSignature("tokenURI(uint256)",tokenId));
        if(success) {
          (tokenUri) = abi.decode(returnData,(string));
        }
}

function supportsInterface(bytes4 interfaceId) public view  returns (bool suported) {
    (bool success, bytes memory returnData) = certTokenManagerSC.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)",interfaceId));
    if(success) {
          (suported) = abi.decode(returnData,(bool));
    }
  }


function balanceOf(address owner) public view   returns (uint256 balance) {
    (bool success, bytes memory returnData) = certTokenManagerSC.staticcall(abi.encodeWithSignature("balanceOf(address)",owner));
    if(success) {
          (balance) = abi.decode(returnData,(uint256));
    }
 }

  function ownerOf(uint256 tokenId) public view returns (address owner) {
    (bool success, bytes memory returnData) = certTokenManagerSC.staticcall(abi.encodeWithSignature("ownerOf(uint256)",tokenId));
    if(success) {
          (owner) = abi.decode(returnData,(address));
    }
  }

  function burn(uint256 tokenId) public {
      require(msg.sender == ownerOf(tokenId));
      assert(AcademicCertificate(certificateAddressByID[tokenId]).setCertificateVisibility(false));
      CertificateTokenManager(certTokenManagerSC).burn(tokenId);
      certificateTokenManaged[tokenId]= false;
      emit Revoke (msg.sender, tokenId);
  }


//======== BCQ management and migrations functions =============== //

function updateInstitutionInformation (string memory _newInformationJSON) public onlyBlockChainQualificationsManager returns (bool) {
    academicInstitutionInformation = _newInformationJSON;
    return true;
}

function changeCertLogicModuleSC(address _newBCQCertLogicModuleSCAddress) public onlyBlockChainQualificationsManager returns (bool){
    certLogicModuleSC = _newBCQCertLogicModuleSCAddress;
    return true;
}

function changeTokenManagerModuleSC(address _newBCQTokenManagerModuleSCAddress) public onlyBlockChainQualificationsManager returns (bool){
    certTokenManagerSC = _newBCQTokenManagerModuleSCAddress;
    return true;
}

function setNewBCQAdministrationManagerModuleSC(address _newBCQAdministrationManagerModuleSC) public onlyBlockChainQualificationsManager returns(bool){
        BCQAdminModuleSC = _newBCQAdministrationManagerModuleSC;
        return true;
}


function changeinstitutionManager(address _newinstitutionManagerWallet)  onlyBlockChainQualificationsManager public returns(bool)
{
    institutionManagerWallet = _newinstitutionManagerWallet;
    _updateUser(_newinstitutionManagerWallet,"","",true,false,false,false,true,1);
    return true;
}

function activate(bool _active) public onlyBlockChainQualificationsManager returns(bool)
{
    active = _active;
    return true;
}

function migrateToNewSCVersion(address _migration_AcademicInstitution_NewSC) public requireInstitutionManagerPermission
{
    migration_AcademicInstitution_NewSC = _migration_AcademicInstitution_NewSC;
}

function migrationSetPreviousSCVersion(address _migration_AcademicInstitution_OldSC) public requireInstitutionManagerPermission
{
    migration_AcademicInstitution_OldSC = _migration_AcademicInstitution_OldSC;
}


function migrateCertificateToNewSC(uint certificateIndex, uint256 iterations) public requireAdminPermission  {
      require(migration_AcademicInstitution_NewSC != address(0));  //Institution not migrated
      require(certificatesExpelledList.length >= certificateIndex+iterations);
      address certificateAddressIt;

     for(uint256 i = 0; i < iterations; i++ ) {
         certificateAddressIt = certificatesExpelledList[certificateIndex+i];
         if(!certificateDeleted[certificateAddressIt]) { //deleted certificates are not migrated
            assert(AcademicCertificate(certificateAddressIt).migrateAcademicInstitutionIdentity(migration_AcademicInstitution_NewSC));
            uint certificateID = certificateIDByAddress[certificateAddressIt];
            assert(BCQInstitutionManager(migration_AcademicInstitution_NewSC).addMigratedCertificate(certificateAddressIt,certificateID,ownerOf(certificateID)));
            emit CertificateMigrated(certificateAddressIt);
         }
    }
}

function addMigratedCertificate(address certificateAddress, uint256 certificateID, address owner) public returns(bool) {
    require(msg.sender == migration_AcademicInstitution_OldSC ); //"only previous institution sc can add certificates in migration process"
    if( certificateIDByAddress[certificateAddress] == 0) { //not migrated yet
        certificatesExpelledList.push(certificateAddress);
        certificateAddressByID[certificateID] = certificateAddress;
        certificateIDByAddress[certificateAddress] = certificateID;
        if(owner != address(0)) {
            certificateTokenManaged[certificateID] = true;
            certificatesOfOwner[owner].push(certificateID);
        }
    }
    return true;
}


}