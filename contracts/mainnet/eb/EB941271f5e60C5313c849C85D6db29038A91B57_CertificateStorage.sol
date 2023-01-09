/**
 *Submitted for verification at polygonscan.com on 2023-01-09
*/

pragma solidity ^0.8.17;

contract CertificateStorage  {
    struct Certificate {
        uint8 certificateType;
        string certificateContentJSON;
        uint256 creationdDate;
        bool active;
        bool showContent;
        uint32 course;
    }
    struct Signature {
        address walletSigner;
        uint256 dateSignature;
    }

    uint256[] certificatesIssuedList;
    mapping (string => uint256)  certificateIDbyReference;
    mapping (uint256 => string)  certificateReferencebyId;
    mapping (uint256 => Certificate)  certificateContentbyId;
    mapping (uint256 => uint256)  certificateStudy;
    mapping (uint256 => Signature[]) certificateSigners;
    mapping(uint256 => mapping(address=>bool)) signControl;
    uint32[] courses;
    mapping(uint32=> string) courseInformation;
    address public academicInstitutionIdentity;
    string baseURL;

    /* BCQ control */
    string  moduleName = "Certificate Storage Module";
    uint8   SCVersion = 4;
    address academicInstitutionPreviousIdentity;
    address BQManager;
    address BQAdminModuleSC;


    modifier restrictedToIssuer {
        require(msg.sender == academicInstitutionIdentity, "unauthorized");
        _;
    }
    modifier adminOperation {
        require(msg.sender == academicInstitutionIdentity || BQAdminModuleSC == msg.sender|| msg.sender == BQManager, "Unauthorized");
         _;
    }

    constructor() {
        BQManager = tx.origin;
    }
    function initCertificateStorage(address _BQAdminModule) public  returns(bool) {
        require(academicInstitutionIdentity == address(0), "Already activated");
        academicInstitutionIdentity = msg.sender;
        BQAdminModuleSC = _BQAdminModule;
        return true;
    }

    function createCertificate(uint8 certType, uint256 certificateID, string memory certificateReference, string memory  certificateDetailsJSON, uint32 courseId) public  restrictedToIssuer returns(bool)
    {
        require(certificateContentbyId[certificateID].creationdDate == 0, "Certificate already created");  //Certificate already exists and cannot be changed or issued
        certificateIDbyReference[certificateReference] = certificateID;
        certificateReferencebyId[certificateID] = certificateReference;
        certificateContentbyId[certificateID] = Certificate({certificateType:certType,certificateContentJSON: certificateDetailsJSON,creationdDate:block.timestamp,active:true,showContent:true, course:courseId});

        certificatesIssuedList.push(certificateID);
        return true;
    }

    //Delete certificate
    function deleteCertificate( uint certificateId) public  restrictedToIssuer returns(bool) {
        require(certificateContentbyId[certificateId].active, "Certificate already deleted");
        certificateContentbyId[certificateId].active = false;
        delete certificateContentbyId[certificateId].certificateContentJSON;
        return true;
    }

    //Sign certificate
    function signCertificate( uint certificateId, address signer) public   restrictedToIssuer returns(bool) {
        require(certificateContentbyId[certificateId].active, "certificate does not exist or deleted");
        require(signControl[certificateId][signer]==false,"certificate already signed by user");
        certificateSigners[certificateId].push(Signature(signer,block.timestamp));
        signControl[certificateId][signer] = true;
        return true;
    }

    function setCertificateVisibility( uint certificateId, bool showCertificateContent) public  restrictedToIssuer returns(bool){
        require(certificateContentbyId[certificateId].active, "certificate does not exist or deleted");
        require(certificateContentbyId[certificateId].showContent != showCertificateContent, "Certificate visibility already updated");
        certificateContentbyId[certificateId].showContent = showCertificateContent;
        return true;
    }
    function setBaseURL(string memory _baseURL) public adminOperation returns(bool) {
        baseURL = _baseURL;
        return true;
    }
    function setCourse(uint32 courseId, string memory courseInfo) public restrictedToIssuer returns(bool) {
        if(bytes(courseInformation[courseId]).length == 0) {
            courses.push(courseId);
        }
        courseInformation[courseId] = courseInfo;
        return true;
    }

    //======== Public information and validation =============== //

    function getCertificatesIssued() public view returns(uint256 count, uint[] memory certificatesIdList) {
        return (getCertificateIssuedCount(),certificatesIssuedList);
    }
    function getCertificateIssuedByIndex(uint index) public view returns(uint certificateId) {
        return certificatesIssuedList[index];
    }
    function getCertificateIssuedCount() public view returns(uint count) {
        return certificatesIssuedList.length;
    }

    function isCertificateIssuedByInstitution(uint certificateId) public view returns(bool) {
        return certificateContentbyId[certificateId].creationdDate > 0;
    }

    function getCertificateIDbyReference(string memory certificateReference) public view returns(uint certificateId) {
         return certificateIDbyReference[certificateReference];
    }

    function getCertificateReferenceById(uint certificateId) public view returns(string memory certificateReference) {
        return certificateReferencebyId[certificateId];
    }
    /// @notice Function to retrieve the information required to retrieve for the public certificate viewer
    function getCertificateDetail(uint certificateId) public view returns( uint256 certId, bool isactive, string memory certificateDetailJson,uint256 creationDate, uint256 totalSignatures,uint8 docType,uint32 courseId,address academicInstitutionIdentitySC, string memory academicInstitutionName)
    {
        if(isCertificateIssuedByInstitution(certificateId)) {

            certificateDetailJson = getCertificateContentById(certificateId);
            totalSignatures = certificateSigners[certificateId].length;
            Certificate memory cert = certificateContentbyId[certificateId];

            (bool success, bytes memory returnData) = academicInstitutionIdentity.staticcall(abi.encodeWithSignature("academicInstitutionName()"));
            if(success) {
                (academicInstitutionName) = abi.decode(returnData,( string ));
            }

            return ( certificateId,cert.active,certificateDetailJson,cert.creationdDate,totalSignatures,cert.certificateType,cert.course,academicInstitutionIdentity,academicInstitutionName);
        }
    }

    function getCertificateContentById(uint certificateId) public view returns(string memory certificateDetail) {
        Certificate memory cert = certificateContentbyId[certificateId];
        if(cert.showContent) certificateDetail = cert.certificateContentJSON;
        else if(cert.active) certificateDetail = "{visibility:private}";
    }

    function getCertificateContentByReference(string memory certificateReference) public view returns(uint certificateId, string memory certificateDetail) {
        certificateId = certificateIDbyReference[certificateReference];
        certificateDetail = getCertificateContentById(certificateId);
    }


    /// @notice returns the number of signatures
    function getSignaturesCount(uint certificateId) public view returns (uint256)
    {
        return certificateSigners[certificateId].length;
    }
    /// @notice returns the number of signatures
    function getSignatures(uint certificateId) public view returns (uint count, address[] memory signerwalletList,uint256[] memory dateSignatureList,string[] memory signerNameList, string[] memory signerInfoList)
    {
        uint signatures = getSignaturesCount(certificateId);
        signerwalletList = new address[](signatures);
        dateSignatureList = new uint256[](signatures);
        signerNameList=new string[](signatures);
        signerInfoList=new string[](signatures);

        for(uint i = 0 ; i< signatures;i++) {
            (signerwalletList[i],dateSignatureList[i],signerNameList[i],signerInfoList[i]) = getSignatureByIndex(certificateId,i);
        }
        return (signatures,signerwalletList,dateSignatureList,signerNameList,signerInfoList);
    }

     /// @notice Function get a Signature detail from the certificate and from the Institutions issuer
    function getSignatureByIndex(uint256 certificateId, uint256 index) public view returns (address signerwallet,uint256 dateSignature,string memory signerName, string memory signerInfo)
    {
        signerwallet = certificateSigners[certificateId][index].walletSigner;
        dateSignature = certificateSigners[certificateId][index].dateSignature;

        (bool success, bytes memory returnData) = academicInstitutionIdentity.staticcall(abi.encodeWithSignature("getWalletInfo(address)",signerwallet));
        if(success) {
                (signerName, signerInfo) = abi.decode(returnData,(string,string));
        }
        return (signerwallet, dateSignature,signerName, signerInfo);
    }

    function getCertificateURL(uint certificateId) public view returns(string memory) {
        return(string(abi.encodePacked(baseURL,certificateReferencebyId[certificateId])));
    }

    function getCourseInfo(uint32 courseId) public view returns(string memory courseInfo) {
        return courseInformation[courseId];
    }
    function getCertificateCourseInfo(uint certificateId) public view returns(string memory courseInfo) {
        return courseInformation[certificateContentbyId[certificateId].course];
    }
    function getCourses() public view returns(string[] memory allCourses) {
        allCourses = new string[](courses.length);
        for(uint i = 0; i< courses.length;i ++) {
            allCourses[i] = courseInformation[courses[i]];
        }
        return allCourses;
    }

    function getModuleConfiguration() public view returns(string memory name, uint8 SCversion, address academicInstitutionSC, address academicInstitutionPreviousSC, address BQAdministrationModuleSC, address BQAdminManager){
        return (moduleName,SCVersion,academicInstitutionIdentity,academicInstitutionPreviousIdentity,BQAdminModuleSC,BQManager);
    }

   //=========  Module migration functions  =================//
    function migration_setNewAdministrationManagerModuleSC(address _newAdministrationManagerModuleSC) public adminOperation returns(bool){
        require(_newAdministrationManagerModuleSC != address(0));
        BQAdminModuleSC = _newAdministrationManagerModuleSC;
        return true;
    }

    function migration_updateToNewAcademySC() public adminOperation returns(bool) {
        address newAcademicInstitutionIdentitySC;
        (bool success, bytes memory returnData) = academicInstitutionIdentity.staticcall(abi.encodeWithSignature("academicInstitutionIdentity()"));
        if(success) {
                (newAcademicInstitutionIdentitySC) = abi.decode(returnData,(address));
                if(newAcademicInstitutionIdentitySC != address(0) && newAcademicInstitutionIdentitySC !=academicInstitutionIdentity) { //Academic institution upgraded - migrate to new SC address
                    academicInstitutionPreviousIdentity = academicInstitutionIdentity;
                    academicInstitutionIdentity = newAcademicInstitutionIdentitySC;
                    return true;
                }
        }
        return false;
    }


}



contract CertificateStorageFactory {
    string public moduleName = "BlockchainQualifications Storage Factory module";
    uint8 public SCVersion = 4;
    address public BCQAdministrationManagerModuleSC;
    mapping(address=>bool) public authorizedInstitutions;

    modifier onlyBCQAdministrationManagerModule {
        require(BCQAdministrationManagerModuleSC == msg.sender);
         _;
    }
    constructor (address _BCQAdministrationManagerModuleSC)  {
       BCQAdministrationManagerModuleSC = _BCQAdministrationManagerModuleSC;
    }

    function createCertificateStorage() public returns (address)
    {
        return address(new CertificateStorage());
    }
    //===== Institution Authorization functions  =================//
    function setAuthorizedInstitution(address _institutionSC, bool _authorization) public onlyBCQAdministrationManagerModule returns(bool)
    {
        authorizedInstitutions[_institutionSC] = _authorization;
        return true;
    }
    //=========  Module migration functions  =================//
    function setNewBCQAdministrationManagerModuleSC(address _newBCQAdministrationManagerModuleSC) public onlyBCQAdministrationManagerModule returns(bool){
        require(_newBCQAdministrationManagerModuleSC != address(0));
        BCQAdministrationManagerModuleSC = _newBCQAdministrationManagerModuleSC;
        return true;
    }
}