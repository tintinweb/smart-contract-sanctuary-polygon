// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Land {
    address contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    struct Landreg {
        uint256 id;
        uint256 area;
        string landAddress;
        uint256 landPrice;
        string allLatitudeLongitude;
        //string allLongitude;
        uint256 propertyPID;
        string physicalSurveyNumber;
        string document;
        bool isforSell;
        address payable ownerAddress;
        bool isLandVerified;
    }

    struct User {
        address id;
        string name;
        uint256 age;
        string city;
        string aadharNumber;
        string panNumber;
        string document;
        string email;
        bool isUserVerified;
    }

    struct LandInspector {
        uint256 id;
        address _addr;
        string name;
        uint256 age;
        string designation;
        string city;
    }

    struct LandRequest {
        uint256 reqId;
        address payable sellerId;
        address payable buyerId;
        uint256 landId;
        reqStatus requestStatus;
        bool isPaymentDone;
    }
    enum reqStatus {
        requested,
        accepted,
        rejected,
        paymentdone,
        commpleted
    }

    uint256 inspectorsCount;
    uint256 public userCount;
    uint256 public landsCount;
    uint256 public documentId;
    uint256 requestCount;

    mapping(address => LandInspector) public InspectorMapping;
    mapping(uint256 => address[]) allLandInspectorList;
    mapping(address => bool) RegisteredInspectorMapping;
    mapping(address => User) public UserMapping;
    mapping(uint256 => address) AllUsers;
    mapping(uint256 => address[]) allUsersList;
    mapping(address => bool) RegisteredUserMapping;
    mapping(address => uint256[]) MyLands;
    mapping(uint256 => Landreg) public lands;
    mapping(uint256 => LandRequest) public LandRequestMapping;
    mapping(address => uint256[]) MyReceivedLandRequest;
    mapping(address => uint256[]) MySentLandRequest;
    mapping(uint256 => uint256[]) allLandList;
    mapping(uint256 => uint256[]) paymentDoneList;

    function isContractOwner(address _addr) public view returns (bool) {
        if (_addr == contractOwner) return true;
        else return false;
    }

    function changeContractOwner(address _addr) public {
        require(msg.sender == contractOwner, "you are not contractOwner");

        contractOwner = _addr;
    }

    //-----------------------------------------------LandInspector-----------------------------------------------

    function addLandInspector(
        address _addr,
        string memory _name,
        uint256 _age,
        string memory _designation,
        string memory _city
    ) public returns (bool) {
        if (contractOwner != msg.sender) return false;
        require(contractOwner == msg.sender);
        RegisteredInspectorMapping[_addr] = true;
        allLandInspectorList[1].push(_addr);
        InspectorMapping[_addr] = LandInspector(
            inspectorsCount,
            _addr,
            _name,
            _age,
            _designation,
            _city
        );
        return true;
    }

    function ReturnAllLandIncpectorList()
        public
        view
        returns (address[] memory)
    {
        return allLandInspectorList[1];
    }

    function removeLandInspector(address _addr) public {
        require(msg.sender == contractOwner, "You are not contractOwner");
        require(RegisteredInspectorMapping[_addr], "Land Inspector not found");
        RegisteredInspectorMapping[_addr] = false;

        uint256 len = allLandInspectorList[1].length;
        for (uint256 i = 0; i < len; i++) {
            if (allLandInspectorList[1][i] == _addr) {
                allLandInspectorList[1][i] = allLandInspectorList[1][len - 1];
                allLandInspectorList[1].pop();
                break;
            }
        }
    }

    function isLandInspector(address _id) public view returns (bool) {
        if (RegisteredInspectorMapping[_id]) {
            return true;
        } else {
            return false;
        }
    }

    //-----------------------------------------------User-----------------------------------------------

    function isUserRegistered(address _addr) public view returns (bool) {
        if (RegisteredUserMapping[_addr]) {
            return true;
        } else {
            return false;
        }
    }

    function registerUser(
        string memory _name,
        uint256 _age,
        string memory _city,
        string memory _aadharNumber,
        string memory _panNumber,
        string memory _document,
        string memory _email
    ) public {
        require(!RegisteredUserMapping[msg.sender]);

        RegisteredUserMapping[msg.sender] = true;
        userCount++;
        allUsersList[1].push(msg.sender);
        AllUsers[userCount] = msg.sender;
        UserMapping[msg.sender] = User(
            msg.sender,
            _name,
            _age,
            _city,
            _aadharNumber,
            _panNumber,
            _document,
            _email,
            false
        );
        //emit Registration(msg.sender);
    }

    function verifyUser(address _userId) public {
        require(isLandInspector(msg.sender));
        UserMapping[_userId].isUserVerified = true;
    }

    function isUserVerified(address id) public view returns (bool) {
        return UserMapping[id].isUserVerified;
    }

    function ReturnAllUserList() public view returns (address[] memory) {
        return allUsersList[1];
    }

    //-----------------------------------------------Land-----------------------------------------------
    function addLand(
        uint256 _area,
        string memory _address,
        uint256 _landPrice,
        string memory _allLatiLongi,
        uint256 _propertyPID,
        string memory _surveyNum,
        string memory _document
    ) public {
        require(isUserVerified(msg.sender));
        landsCount++;
        lands[landsCount] = Landreg(
            landsCount,
            _area,
            _address,
            _landPrice,
            _allLatiLongi,
            _propertyPID,
            _surveyNum,
            _document,
            false,
            payable(msg.sender),
            false
        );
        MyLands[msg.sender].push(landsCount);
        allLandList[1].push(landsCount);
        // emit AddingLand(landsCount);
    }

    function ReturnAllLandList() public view returns (uint256[] memory) {
        return allLandList[1];
    }

    function verifyLand(uint256 _id) public {
        require(isLandInspector(msg.sender));
        lands[_id].isLandVerified = true;
    }

    function isLandVerified(uint256 id) public view returns (bool) {
        return lands[id].isLandVerified;
    }

    function myAllLands(address id) public view returns (uint256[] memory) {
        return MyLands[id];
    }

    function makeItforSell(uint256 id) public {
        require(lands[id].ownerAddress == msg.sender);
        lands[id].isforSell = true;
    }

    function requestforBuy(uint256 _landId) public {
        require(isUserVerified(msg.sender) && isLandVerified(_landId));
        requestCount++;
        LandRequestMapping[requestCount] = LandRequest(
            requestCount,
            lands[_landId].ownerAddress,
            payable(msg.sender),
            _landId,
            reqStatus.requested,
            false
        );
        MyReceivedLandRequest[lands[_landId].ownerAddress].push(requestCount);
        MySentLandRequest[msg.sender].push(requestCount);
    }

    function myReceivedLandRequests() public view returns (uint256[] memory) {
        return MyReceivedLandRequest[msg.sender];
    }

    function mySentLandRequests() public view returns (uint256[] memory) {
        return MySentLandRequest[msg.sender];
    }

    function acceptRequest(uint256 _requestId) public {
        require(LandRequestMapping[_requestId].sellerId == msg.sender);
        LandRequestMapping[_requestId].requestStatus = reqStatus.accepted;
    }

    function rejectRequest(uint256 _requestId) public {
        require(LandRequestMapping[_requestId].sellerId == msg.sender);
        LandRequestMapping[_requestId].requestStatus = reqStatus.rejected;
    }

    function requesteStatus(uint256 id) public view returns (bool) {
        return LandRequestMapping[id].isPaymentDone;
    }

    function landPrice(uint256 id) public view returns (uint256) {
        return lands[id].landPrice;
    }

    function makePayment(uint256 _requestId) public payable {
        require(
            LandRequestMapping[_requestId].buyerId == msg.sender &&
                LandRequestMapping[_requestId].requestStatus ==
                reqStatus.accepted
        );

        LandRequestMapping[_requestId].requestStatus = reqStatus.paymentdone;
        //LandRequestMapping[_requestId].sellerId.transfer(lands[LandRequestMapping[_requestId].landId].landPrice);
        //lands[LandRequestMapping[_requestId].landId].ownerAddress.transfer(lands[LandRequestMapping[_requestId].landId].landPrice);
        lands[LandRequestMapping[_requestId].landId].ownerAddress.transfer(
            msg.value
        );
        LandRequestMapping[_requestId].isPaymentDone = true;
        paymentDoneList[1].push(_requestId);
    }

    function returnPaymentDoneList() public view returns (uint256[] memory) {
        return paymentDoneList[1];
    }

    function transferOwnership(uint256 _requestId, string memory documentUrl)
        public
        returns (bool)
    {
        require(isLandInspector(msg.sender));
        if (LandRequestMapping[_requestId].isPaymentDone == false) return false;
        documentId++;
        LandRequestMapping[_requestId].requestStatus = reqStatus.commpleted;
        MyLands[LandRequestMapping[_requestId].buyerId].push(
            LandRequestMapping[_requestId].landId
        );

        uint256 len = MyLands[LandRequestMapping[_requestId].sellerId].length;
        for (uint256 i = 0; i < len; i++) {
            if (
                MyLands[LandRequestMapping[_requestId].sellerId][i] ==
                LandRequestMapping[_requestId].landId
            ) {
                MyLands[LandRequestMapping[_requestId].sellerId][i] = MyLands[
                    LandRequestMapping[_requestId].sellerId
                ][len - 1];
                //MyLands[LandRequestMapping[_requestId].sellerId].length--;
                MyLands[LandRequestMapping[_requestId].sellerId].pop();
                break;
            }
        }
        lands[LandRequestMapping[_requestId].landId].document = documentUrl;
        lands[LandRequestMapping[_requestId].landId].isforSell = false;
        lands[LandRequestMapping[_requestId].landId]
            .ownerAddress = LandRequestMapping[_requestId].buyerId;
        return true;
    }

    function makePaymentTestFun(address payable _reveiver) public payable {
        _reveiver.transfer(msg.value);
    }
}