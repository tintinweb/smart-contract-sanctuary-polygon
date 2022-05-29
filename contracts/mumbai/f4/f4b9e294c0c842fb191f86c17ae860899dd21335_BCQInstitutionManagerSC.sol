/**
 *Submitted for verification at polygonscan.com on 2022-05-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title LogicModule  interface
interface BCQCertificateLogicModule {
    function createCertificate()   external returns(address);
}

interface AcademicCertificate {
  function createCertificate (string memory  _certificateInfo )   external  returns(bool);
    function deleteCertificate  () external    returns(bool);
    function signCertificate() external  returns (bool);
    function setAdditionalInformationSC( address _additionalInformationSC) external   returns(bool);
}

contract BCQInstitutionManagerSC {

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

string public moduleName = "BlockChainQualifications Academic Institution Manager module";
uint8 public SCVersion = 2;

address public institutionManagerWallet;
address public BCQAdminModuleSC;
address public currentBCQCertLogicModuleSC;
address[] public BCQCertLogicModuleSCHistoric;

string public institutionName;
string public institutionInformation;
uint256 public creationDate;
bool public active;


//Certificates
mapping (address => address) public certificateLogicModuleAddress;
mapping (uint256 => address) public certificateAddressByID;
address[] public certificatesExpelledList;

/* Users information module */
mapping (address => UsersInformation) public usersList;

/*Events*/
event CertificateCreated( uint256 indexed _certificateID, address indexed _certificateAddress);
event CertificateSigned(address indexed _certificateAddress, address indexed _userWallet);
event CertificateDeleted(address indexed _certificateAddress);
event UserUpdated(address indexed _userWallet);
event CertificateUpdated(uint256 indexed _operationType, address indexed _certificateAddress);
/*1-updateCertificateAcademicInformation  / 2-setCertificateAcademicExpedientSC / 3-setCertificateDocumentManagerSC */

/*Permission Control modifieres*/
modifier onlyBlockChainQualificationsManager {
    require(msg.sender == BCQAdminModuleSC);
     _;
}

modifier onlyIfActive {
    require (active);
     _;
}
modifier requireIsAdminPermission {
    if(msg.sender != institutionManagerWallet) {
        require(usersList[msg.sender].isActive);
        require(usersList[msg.sender].isAdmin );
    }
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

function createInstitution (address _BCQAdminModuleSC, address _institutionManagerWallet, string memory  _InstitutionName, address   _BCQCertLogicModuleSCAddress) public  returns(bool){
        require(BCQAdminModuleSC == address(0), "Institution already activated");

        BCQAdminModuleSC = _BCQAdminModuleSC;
        institutionName = _InstitutionName;
        institutionManagerWallet  = _institutionManagerWallet;

        BCQCertLogicModuleSCHistoric.push(_BCQCertLogicModuleSCAddress);
        currentBCQCertLogicModuleSC = _BCQCertLogicModuleSCAddress;

        usersList[institutionManagerWallet] = UsersInformation(  "Institution Manager",  "Institution Manager",  true,
        false,  false, false, true, 1 , block.timestamp);

        creationDate = block.timestamp;
        active =true;
        return true;
}

function updateInstitutionInformation (string memory _newInformationJSON) public onlyIfActive onlyBlockChainQualificationsManager returns (bool) {
    institutionInformation = _newInformationJSON;
    return true;
}

function updateInstitutionName (string memory _newinstitutionName) public onlyIfActive onlyBlockChainQualificationsManager returns (bool) {
    institutionName = _newinstitutionName;
    return true;
}

function changeCertLogicModuleSC(address _newBCQCertLogicModuleSCAddress) public onlyIfActive onlyBlockChainQualificationsManager returns (bool){
    require(currentBCQCertLogicModuleSC != _newBCQCertLogicModuleSCAddress);
    BCQCertLogicModuleSCHistoric.push(_newBCQCertLogicModuleSCAddress);
    currentBCQCertLogicModuleSC = _newBCQCertLogicModuleSCAddress;
    return true;
}

function setNewBCQAdministrationManagerModuleSC(address _newBCQAdministrationManagerModuleSC) public onlyBlockChainQualificationsManager returns(bool){
        require(_newBCQAdministrationManagerModuleSC != address(0));
        require(_newBCQAdministrationManagerModuleSC != BCQAdminModuleSC);
        BCQAdminModuleSC = _newBCQAdministrationManagerModuleSC;
        return true;
}


//Admin Functions
function changeinstitutionManager(address _newinstitutionManagerWallet)  onlyBlockChainQualificationsManager public returns(bool)
{
    require( institutionManagerWallet != _newinstitutionManagerWallet);
    institutionManagerWallet = _newinstitutionManagerWallet;

    if(usersList[_newinstitutionManagerWallet].isActive != true) {
        usersList[_newinstitutionManagerWallet] = UsersInformation("Institution Manager",  "Institution Manager",  true,false,  false, false, true, 1 , block.timestamp);
    } else {
        usersList[_newinstitutionManagerWallet].isAdmin = true;
        usersList[_newinstitutionManagerWallet].role = 1;
        usersList[_newinstitutionManagerWallet].lastUpdate = block.timestamp;
    }

    return true;
}

function activate(bool _active) public onlyBlockChainQualificationsManager returns(bool)
{
    require (active != _active);
    active = _active;

    return true;
}

//======== Certificate Operation functions ======/

//certificate creation function
function createCertificate( uint256 certificateID, string memory  _certificateInfo) onlyIfActive requireCreateCertPermission public returns(bool){
      require(certificateAddressByID[certificateID] == address(0));
      //Certificate creation with the current version of blockchain qualifications logic module
       address newCertificate = BCQCertificateLogicModule(currentBCQCertLogicModuleSC).createCertificate();
       assert(newCertificate != address(0));
       assert(AcademicCertificate(newCertificate).createCertificate(_certificateInfo));

       certificatesExpelledList.push(newCertificate);
       certificateAddressByID[certificateID] = newCertificate;
       certificateLogicModuleAddress[newCertificate] = currentBCQCertLogicModuleSC;
       emit CertificateCreated(  certificateID,  newCertificate);
       return true;
}


//detele certificate function. we use the logic manager of the creation of the certificate
function deleteCertificate( address _certificateAddress) public onlyIfActive requireDeleteCertPermission returns (bool) {
    assert(AcademicCertificate(_certificateAddress).deleteCertificate());
    emit CertificateDeleted(_certificateAddress);
    return true;
}


function signCertificate( address _certificateAddress) public onlyIfActive  requireSignCertPermission returns (bool) {
    assert(AcademicCertificate(_certificateAddress).signCertificate());
    emit CertificateSigned(_certificateAddress, msg.sender);
    return true;
}


function setCertificateAdditionalInformationSC( address _certificateAddress, address _additionalInformationSC) public onlyIfActive requireCreateCertPermission returns(bool){
    assert(AcademicCertificate(_certificateAddress).setAdditionalInformationSC(_additionalInformationSC));
    emit CertificateUpdated(2,  _certificateAddress);
    return true;
}



//======== Maintainance of users and permissions =============== //


/*Function to add or update a wallet as an authorized user of the university*/
function updateUser ( address _walletUser, string memory _name, string memory _userinfo, bool _isActive,
  bool _canCreateCertificates, bool _canDeleteCertificates,bool _canSignCertififcates, bool _isAdmin, uint8 _role ) public requireIsAdminPermission returns(bool) //to-do only university manager
{
   usersList[_walletUser] = UsersInformation(  _name,  _userinfo,  _isActive,
  _canCreateCertificates,  _canDeleteCertificates, _canSignCertififcates, _isAdmin, _role , block.timestamp);

  emit UserUpdated(_walletUser);
  return true;
}


//======== Public information and validation =============== //

function certificatesExpelled() public view returns (uint256 )
{
    return certificatesExpelledList.length;
}


function isCertificateExpelledbyinstitution(address _certificateAddress) public view returns(bool) {
    if(certificateLogicModuleAddress[_certificateAddress] != address(0))
        return true;

    return false;

 }

/*Function to get the information of a university user wallet*/
function getWalletInfo (address _wallet) public view returns (string memory, string memory)
{
      return  (usersList[_wallet].name, usersList[_wallet].userinfo);
}

/*Function to get the permissions of a university user wallet*/
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

}