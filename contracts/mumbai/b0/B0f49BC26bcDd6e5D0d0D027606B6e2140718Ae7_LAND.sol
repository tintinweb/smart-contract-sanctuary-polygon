// SPDX-License-Identifier:MIT
pragma solidity 0.8.15;

/* ERRORS  */
error LAND__onlyinspector();
error LAND__Address_not_Landinspector();
error LAND__User_Not_Verified();

contract LAND {
    /*  LAND REGISTRATION    */
    struct LandRegistration {
        uint256 Id;
        string area;
        string city;
        string state;
        uint256 landprice;
        uint256 propertyPID;
        uint256 PhysicalSurveyNumber;
        string ipfsHash;
        string document;
    }
    /*   SELLER   */
    struct Seller{
        address _address;
        string name;
        string document;
        uint256 age;
        uint256 addharcard;
        uint256 panNumber;
        uint256 Landowned;
    }
    /*   BUYER    */
    struct Buyer{
         address _address;
        string name;
        string document;
        uint256 age;
        uint256 addharcard;
        uint256 panNumber;
        string Email;
    }
    /*   LAND REQUEST   */
    struct LandRequest {
        uint256 reqId;
        address SellerId;
        address BuyerId;
        uint256 landId;
    }
    /*  LAND INSPECTOR  */
    struct LandInspector {
        uint256 Id;
        uint256 age;
        string name;
        string designation;
    }
    /*  MAPPINGS OF INSTANCES */
    mapping(address=>Seller) private seller_details;
    mapping(address=>Buyer) private buyer_details;
    mapping(uint256 => LandInspector) landInspector_details;
    mapping(uint256 => LandRequest) landRequest_details;
    mapping(uint256 => LandRegistration) landRegistration_details;
    /* Verification variables */
    mapping(address=>bool)RegisteredBuyerMapping;
    mapping(address => bool)RegisteredAddressMapping;
    mapping(address => bool)RegisteredSellerMapping;
    mapping(address=>bool) SellerVerificationStatus;
    mapping(address=>bool) BuyerVerificationStatus;
    mapping(address => bool) SellerRejectionStatus;
    mapping(address => bool) BuyerRejectionStatus;
    mapping(uint256 => bool) LandVerification;
    mapping(uint256 => bool) LandVerified;
    mapping(uint256 => address) LandOwner;
    mapping(uint256 => bool) RequestLandQuery;
    mapping(uint256 => bool ) landRequestedStatus;
    mapping(uint256 => bool) PaymentReceived;
     /* COUNTS */
    uint256 private landsCount;
    uint256 private sellerCount;
    uint256 private buyerCount;
    uint256 private inspectorCount;
    uint256 private landRequestCount;
    address[] sellers;
    address[] buyers;
    address private immutable Landinspector;

    /* EVENTS */
    event InspectorAdded(string indexed name,string indexed designation,uint256 indexed Id);
    event Sellerverified(address indexed SellerId);
    event BuyerVerified(address indexed buyerId);
    event SellerRejected(address indexed SellerId);
    event BuyerRejected(address indexed buyer_Id);
    event LandAdded(uint256 indexed land_num);
    event SellerRegistered(address indexed _seller);
    event buyerRegistered(address indexed _buyer);
    event LandRequested(address indexed requested_to,uint256 indexed Request_no);
    /* Constructor */
    constructor()  {
        Landinspector = msg.sender;
        addInspector("INSPECTOR1","manager",45);
    }
    /* MODIFIER */
    modifier onlyinspector(){
        if(msg.sender != Landinspector) revert LAND__onlyinspector();
        _;
    }
    modifier islandInspector(address _inspectionId) {
        if(Landinspector != _inspectionId) revert LAND__Address_not_Landinspector();
            _;
        
    }
    /* @functions */
    function addInspector(string memory _name,string memory _designation,uint256 _age) onlyinspector() public {
        inspectorCount++;
        landInspector_details[inspectorCount] = LandInspector(inspectorCount,_age,_name,_designation);
        emit InspectorAdded(_name,_designation,inspectorCount);

    }
    function verifySeller(address seller_id) external onlyinspector(){
        SellerVerificationStatus[seller_id] = true;
        emit Sellerverified(seller_id);
    }
    function rejectSeller(address seller_id) external onlyinspector() {
       SellerRejectionStatus[seller_id] = true;
       emit SellerRejected(seller_id);
    }
    function verifyBuyer(address _buyerid) external onlyinspector() {
        BuyerVerificationStatus[_buyerid] = true;
        emit BuyerVerified(_buyerid);
    }
    function rejectBuyer(address _buyerid) external onlyinspector() {
        BuyerRejectionStatus[_buyerid] = true;
        emit BuyerRejected(_buyerid);
    }
    function isLandVerified(uint256 _landId) external view onlyinspector() returns(bool){
        if(LandVerified[_landId])
        return true;
    }
    function verifyland(uint256 _landId) external onlyinspector() {
        LandVerified[_landId] = true;
    }
    function userVerified(address _addr) internal view returns(bool){
        if(SellerVerificationStatus[_addr] || BuyerVerificationStatus[_addr]) {
            return true;
        }
    }
    function userRejected(address _addr) external view returns(bool){
         if(SellerRejectionStatus[_addr] || BuyerRejectionStatus[_addr]) {
            return true;
        }
    }
     function isSeller(address _addr) private view returns (bool) {
        if(RegisteredSellerMapping[_addr]){
            return true;
        }
    }
     function isBuyer(address _addr) private  view returns (bool) {
        if(RegisteredBuyerMapping[_addr]){
            return true;
        }
    }
    function isRegistered(address _addr) private view returns (bool) {
        if(RegisteredAddressMapping[_addr]){
            return true;
        }
    }
    function addland(string memory  _area, string memory _city,string memory _state, uint landPrice, uint _propertyPID,uint _surveyNum,string memory _ipfsHash, string memory _document) external {
        if(!isSeller(msg.sender) || !isRegistered(msg.sender)) revert LAND__User_Not_Verified();
         landsCount++;
        landRegistration_details[landsCount] = LandRegistration(landsCount,_area,_city,_state,landPrice,_propertyPID,_surveyNum,_ipfsHash,_document);
        LandOwner[landsCount] = msg.sender;
        emit LandAdded(landsCount);
    }
    function registerSeller(string memory _name, uint _age, uint256 _aadharNumber, uint256 _panNumber, uint256 _landsOwned, string memory _document) external {
        if(RegisteredAddressMapping[msg.sender]) revert LAND__User_Not_Verified();
        RegisteredAddressMapping[msg.sender] = true;
        RegisteredSellerMapping[msg.sender] = true;
        sellerCount++;
        seller_details[msg.sender] = Seller(msg.sender,_name,_document,_age,_aadharNumber,_panNumber,_landsOwned);
        sellers.push(msg.sender);
        emit SellerRegistered(msg.sender);
    }
    function updateSeller(string memory _name, uint256 _age, uint256 _aadharNumber, uint256 _panNumber, uint256 _landsOwned) external {
        require(RegisteredSellerMapping[msg.sender] && (seller_details[msg.sender]._address == msg.sender));
        seller_details[msg.sender].name =_name;
        seller_details[msg.sender].age =_age;
        seller_details[msg.sender].panNumber =_panNumber;
        seller_details[msg.sender].addharcard =_aadharNumber;
        seller_details[msg.sender].Landowned =_landsOwned;
    }
    function getSellers() external view returns(address[] memory){
        return sellers;
    }
    function getSellerDetails(address _addr) external view returns(Seller memory){
        return seller_details[_addr];
    }
    function registerBuyer(string memory _name,string memory _document,uint256 _age,uint256 _addharcard,uint256 _panNumber, string memory _Email) external {
        if(RegisteredAddressMapping[msg.sender]) revert LAND__User_Not_Verified();

        RegisteredAddressMapping[msg.sender] = true;
        RegisteredBuyerMapping[msg.sender] = true;
        buyerCount++;
        buyer_details[msg.sender] = Buyer(msg.sender,_name,_document,_age,_addharcard,_panNumber,_Email);
        buyers.push(msg.sender);
        emit buyerRegistered(msg.sender);
    }
    function UpdateBuyer(string memory _name,uint256 _age,uint256 _aadharnumber,uint256 _panNumber,string memory _Email) external {
        require(RegisteredAddressMapping[msg.sender] && buyer_details[msg.sender]._address == msg.sender);
        buyer_details[msg.sender].name = _name;
        buyer_details[msg.sender].age = _age;
        buyer_details[msg.sender].addharcard = _aadharnumber;
        buyer_details[msg.sender].panNumber = _panNumber;
        buyer_details[msg.sender].Email = _Email;
    }
    function getBuyers() external view returns(address[] memory){
        return buyers;
    }
    function getBuyersDetails(address _addr) external view  returns(Buyer memory){
        return buyer_details[_addr];
    }
    function requestLand(address _sellerId,uint256 _LandId) external {
        require(isBuyer(msg.sender) && userVerified(msg.sender));
        landRequestCount++;
        landRequest_details[landRequestCount] = LandRequest(landRequestCount,_sellerId,msg.sender,_LandId);
        RequestLandQuery[landRequestCount] = false;
        landRequestedStatus[landRequestCount] = true;
        emit LandRequested(_sellerId,landRequestCount);
    }
    function getLandRequestDetails(uint256 _requestId) external returns(LandRequest memory, bool  status){
        return (landRequest_details[_requestId],landRequestedStatus[_requestId]);
    }
    function isRequested(uint256 _landId) external returns(bool){
        if(landRequestedStatus[_landId]){
            return true;
        }
    }
    function isApproved(uint256 _reqId) external view returns(bool){
        if(RequestLandQuery[_reqId]){
            return true;
        }
    }
    function approveRequest(uint256 _reqId) external {
        require(isSeller(msg.sender) && userVerified(msg.sender));
        RequestLandQuery[_reqId] = true;
    }
    function TransferOwnership(uint256 _reqId,address _newowner) external onlyinspector(){
        LandOwner[_reqId] = _newowner;
    }
    function payment(address payable _receiver,uint256 _landId) external payable {
        _receiver.transfer(msg.value);
        PaymentReceived[_landId] = true;
    }
    function isPaid(uint _landId) public  view   returns (bool) {
        if(PaymentReceived[_landId]){
            return true;
        }
    }
    function getlandCount() external view returns(uint256){
        return landsCount;
    }
    function getSellerCount() external view returns(uint256){
        return landsCount;
    }
    function getBuyerCount() external view returns(uint256){
        return landsCount;
    }
    function getRequestCount() external view returns(uint256){
        return landsCount;
    }
    function getlandOwner(uint256 _landnumber) external view returns(address){
        return LandOwner[_landnumber];
    }
    
}