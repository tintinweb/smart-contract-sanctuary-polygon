/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

// SPDX-License-Identifier: MITs

pragma solidity ^0.8.0;

contract landregistry {
    address payable contractOwner;



    receive() external payable {}

    constructor() {
        contractOwner = payable(msg.sender);
    }

    struct LandInspector {
        uint id;
        address addr;
        bytes32 name;
        bytes32 dob;
        uint cnic;
        bytes32 city;
        bytes32 district;
        bytes32 designation;
        bytes32 email;
        uint phone;
    }

    struct User {
        address id;
        bytes32 name;
        bytes32 dob;
        bytes32 city;
        bytes32 district;
        uint cnic;
        string document;
        string profilepic;
        bytes32 email;
        bytes32 phone;
        bool isUserVerified;
        bool death;
        uint registerdate;
    }

    struct Land {
        uint id;
        uint propertyPID;
        uint area;
        uint landPrice;
        string landAddress;
        bytes32 district;
        string allLatitudeLongitude;
        string document;
        string landpic;
        bool isforSell;
        bool isLandVerified;
        address payable ownerAddress;
        address payable proxyownerAddress;
        uint registerdate;
    }
    struct LandInfo {
        address verfiedby;
        uint verfydate;


    }

    struct LandPriceInfo{
        uint id;
        uint basePrice;
        uint landPrice;

    }
    struct UserInfo {
        address verfiedby;
          uint  verifydate;
    }

    struct LandHistory {
        uint parentId;
        uint childCount;
        uint childId;
        uint area;
        address parentAddress;
        uint timestamp;
    }

    struct LandRequest {
        uint reqId;
        address payable sellerId;
        address payable buyerId;
        uint landId;
        reqStatus requestStatus;
        uint bidPrice;
        bool isPaymentDone;
    }

    enum reqStatus {
        requested,
        accepted,
        rejected,
        paymentdone,
        commpleted
    }

    uint public inspectorsCount;
    uint public userCount;
    uint public landsCount;
    uint public documentId;
    uint requestCount;

    mapping(address => User) public UserMapping;

    mapping(address => LandInspector) public InspectorMapping;
    mapping(uint => address[]) allLandInspectorList;
    mapping(address => bool) public RegisteredInspectorMapping;
    mapping(uint => address[]) allUsersList;
    mapping(address => bool) public RegisteredUserMapping;
    mapping(address => uint[]) MyLands;
    mapping(uint => Land) public lands;
    mapping(uint => LandRequest) public LandRequestMapping;
    mapping(address => uint[]) MyReceivedLandRequest;
    mapping(address => uint[]) MySentLandRequest;
    mapping(uint => uint[]) allLandList;
    mapping(uint => uint[]) paymentDoneList;
    mapping(uint => LandHistory[]) landHistory;
    mapping(uint => LandHistory) public landHis;

    mapping(uint => LandInfo) public landinfo;
    mapping(address => UserInfo) public userinfo;
    mapping (uint =>LandPriceInfo) public landPriceInfo;

    function AndandRemoveProxyOwner(
        uint landId,
        address payable proxyOwner,
        bool x
    ) public {
        if (
            lands[landId].ownerAddress == msg.sender &&
            lands[landId].isLandVerified
        ) {
            if (x) {
                lands[landId].proxyownerAddress = proxyOwner;
            }

            if (!x && lands[landId].proxyownerAddress == proxyOwner) {
                lands[landId].proxyownerAddress = contractOwner;
            }
        } else {
            revert();
        }
    }

    function isContractOwner(address _addr) public view returns (bool) {
        if (_addr == contractOwner) return true;
        else return false;
    }

    function changeContractOwner(address _addr) public {
        if (msg.sender == contractOwner) {
            contractOwner = payable(_addr);
        }
    }

    //-----------------------------------------------LandInspector-----------------------------------------------

    function addLandInspector(
        address _addr,
        bytes32 _name,
        bytes32 _dob,
        uint _cinc,
        bytes32 _designation,
        bytes32 _city,
        bytes32 _district,
        bytes32 _email,
        uint _phone
    ) public returns (bool) {
        // Check if the caller is the contract owner and the inspector is not already registered
        if (
            msg.sender == contractOwner &&
            RegisteredInspectorMapping[_addr] == false
        ) {
            // Check if the CNIC already exists in the inspectors mapping
            for (uint i = 0; i < inspectorsCount; i++) {
                if (
                    InspectorMapping[allLandInspectorList[1][i]].cnic == _cinc
                ) {
                    revert();
                }
            }
            // Update the inspectors mapping and lists
            RegisteredInspectorMapping[_addr] = true;
            inspectorsCount++;
            allLandInspectorList[1].push(_addr);
            InspectorMapping[_addr] = LandInspector(
                inspectorsCount,
                _addr,
                _name,
                _dob,
                _cinc,
                _city,
                _district,
                _designation,
                _email,
                _phone
            );
            return true;
        } else {
            revert();
        }
    }

    function removeLandInspector(address _addr) public {
        if (msg.sender == contractOwner && RegisteredInspectorMapping[_addr]) {
            RegisteredInspectorMapping[_addr] = false;

            uint len = allLandInspectorList[1].length;
            for (uint i = 0; i < len; i++) {
                if (allLandInspectorList[1][i] == _addr) {
                    allLandInspectorList[1][i] = allLandInspectorList[1][
                        len - 1
                    ];
                    allLandInspectorList[1].pop();
                    break;
                }
            }
        } else {
            revert();
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

    function registerUser(
        bytes32 _name,
        bytes32 _dob,
        bytes32 _city,
        bytes32 _district,
        uint _cinc,
        string memory _document,
        string memory _profilepic,
        bytes32 _email,
        bytes32 _phone
    ) public {
        if (RegisteredUserMapping[msg.sender] == true) {
            // The user is already registered.
            revert("Allreadey registerd");
        } else {
            // require(!RegisteredUserMapping[msg.sender]);

            RegisteredUserMapping[msg.sender] = true;
            userCount++;
            allUsersList[1].push(msg.sender);
            UserMapping[msg.sender] = User(
                msg.sender,
                _name,
                _dob,
                _city,
                _district,
                _cinc,
                _document,
                _profilepic,
                _email,
                _phone,
                false,
                false,
                block.timestamp
            );
            //emit Registration(msg.sender);
        }
    }

    function verifyUser(address _userId) public {
        if (
            isLandInspector(msg.sender) &&
            _userId != msg.sender &&
            UserMapping[_userId].district ==
            InspectorMapping[msg.sender].district
        ) {
            UserMapping[_userId].isUserVerified = true;
            userinfo[_userId] = UserInfo(msg.sender, block.timestamp);
        } else {
            revert();
        }
    }

    function isUserVerified(address id) public view returns (bool) {
        return UserMapping[id].isUserVerified;
    }

    function ReturnAllUserList() public view returns (address[] memory) {
        return allUsersList[1];
    }

    function addLand(
        uint _area,
        string memory _landAddress,
        bytes32 _district,
        uint _landPrice,
        string memory _allLatiLongi,
        uint _propertyPID,
        string memory _document,
        string memory _landpic
    ) public {
        if (
            UserMapping[msg.sender].isUserVerified &&
            !CheckDuplicatePid(_propertyPID) &&
            _area > 0 &&
            !UserMapping[msg.sender].death
        ) {
            landsCount++;

            lands[landsCount] = Land(
                landsCount,
                _propertyPID,
                _area,
                _landPrice*10**18,
                _landAddress,
                _district,
                _allLatiLongi,
                _document,
                _landpic,
                false,
                false,
                payable(msg.sender),
                contractOwner,
                block.timestamp
            );
            MyLands[msg.sender].push(landsCount);
            allLandList[1].push(landsCount);
            landHistory[landsCount].push(
                LandHistory(
                    landsCount,
                    0,
                    0,
                    _area,
                    payable(msg.sender),
                    block.timestamp
                )
        //         
            );
        } else {
            revert();
        }
    }

    function subplot(uint id, uint newarea, uint numplots) public {
        if (
            UserMapping[msg.sender].isUserVerified &&
            lands[id].isLandVerified &&
            lands[id].ownerAddress == msg.sender &&
            numplots > 0 &&
            newarea < lands[id].area &&
            !lands[id].isforSell &&
            !UserMapping[msg.sender].death
        ) {
            uint parentPID = lands[id].propertyPID;

            for (uint i = 1; i <= numplots && lands[id].area >= newarea; i++) {
                lands[id].area -= newarea;
                landsCount++;

                // Generate a unique propertyPID for the new subplot
                uint subplotPID = uint(
                    keccak256(
                        abi.encodePacked(block.timestamp, landsCount, parentPID)
                    )
                );

                // Add the new subplot to the mapping with its unique propertyPID
                lands[landsCount] = Land(
                    landsCount,
                    subplotPID,
                    newarea,
                    lands[id].landPrice,
                    lands[id].landAddress,
                    lands[id].district,
                    lands[id].allLatitudeLongitude,
                    lands[id].document,
                    lands[id].landpic,
                    false,
                    false,
                    payable(msg.sender),
                    contractOwner,
                    block.timestamp
                );
                MyLands[msg.sender].push(landsCount);
                allLandList[1].push(landsCount);
// uint parentId;
        // uint childCount;
        // uint childId;
        // uint area;
        // address parentAddress;
        // uint timestamp;

                landHistory[landsCount].push(
                    LandHistory(id, 0, 0, newarea,payable(msg.sender), block.timestamp)
                );

                // update history for the parent land
                landHistory[id].push(
                    LandHistory(
                        id,
                        numplots,
                        landsCount,
                        newarea,
                        payable(msg.sender),
                        lands[id].registerdate
                    )
                );
            }
        } else {
            revert();
        }
    }

    function CheckDuplicatePid(uint _propertyPID) public view returns (bool) {
        for (uint i = 0; i <= landsCount; i++) {
            if (lands[i].propertyPID == _propertyPID) {
                return true;
            }
        }
        return false;
    }

    function getLandHistoryId(
        uint landId
    ) public view returns (LandHistory[] memory) {
        return landHistory[landId];
    }



    function ReturnAllLandList() public view returns (uint[] memory) {
        return allLandList[1];
    }

    function verifyLand(uint _id) public {
        if (
            isLandInspector(msg.sender) &&
            lands[_id].ownerAddress != msg.sender &&
            UserMapping[lands[_id].ownerAddress].isUserVerified &&
            InspectorMapping[msg.sender].district == lands[_id].district
        ) {
            lands[_id].isLandVerified = true;
            landinfo[_id] = LandInfo(msg.sender, block.timestamp);
        } else {
            revert();
        }
    }

    function myAllLands(address id) public view returns (uint[] memory) {
        return MyLands[id];
    }

    function ReturnAllLandIncpectorList()
        public
        view
        returns (address[] memory)
    {
        return allLandInspectorList[1];
    }

    function changeDetails(
        uint _landId,
        bool s,
        bool p,
        bool i,
        bool c,
        bool sell,
        uint _newPrice,
        string memory _newPic,
        string memory _allLatiLongi
    ) public {
        if (
            lands[_landId].ownerAddress == msg.sender &&
            lands[_landId].isLandVerified
        ) {
            if (s) {
                lands[_landId].isforSell = sell;
            }
            if (p) {
                lands[_landId].landPrice = _newPrice*10**18;
            }
            if (i) {
                lands[_landId].landpic = _newPic;
            }

            if (c) {
                lands[_landId].allLatitudeLongitude = _allLatiLongi;
            }
        } else {
            revert();
        }
    }

    function myReceivedLandRequests() public view returns (uint[] memory) {
        return MyReceivedLandRequest[msg.sender];
    }

    function mySentLandRequests() public view returns (uint[] memory) {
        return MySentLandRequest[msg.sender];
    }

    function acceptRequest(uint _requestId, bool acceptreject) public {
        require(LandRequestMapping[_requestId].sellerId == msg.sender);

        if (acceptreject && !LandRequestMapping[_requestId].isPaymentDone) {
            if (LandRequestMapping[_requestId].bidPrice > 0) {
                // Update the land price with the bid price
                 LandPriceInfo(_requestId,lands[LandRequestMapping[_requestId].landId]
                    .landPrice,LandRequestMapping[_requestId].bidPrice);

                lands[LandRequestMapping[_requestId].landId]
                    .landPrice = LandRequestMapping[_requestId].bidPrice;
            }

            LandRequestMapping[_requestId].requestStatus = reqStatus.accepted;
        } else if (
            !acceptreject && !LandRequestMapping[_requestId].isPaymentDone
        ) {
            LandRequestMapping[_requestId].requestStatus = reqStatus.rejected;
        }
    }

    function requestforBuyWithBid(uint _landId, uint _bidPrice) public {
        if (
            UserMapping[msg.sender].isUserVerified &&
            lands[_landId].isLandVerified &&
            msg.sender != lands[_landId].ownerAddress
        ) {
            requestCount++;
            LandRequestMapping[requestCount] = LandRequest(
                requestCount,
                lands[_landId].ownerAddress,
                payable(msg.sender),
                _landId,
                reqStatus.requested,
                _bidPrice*10**18,
                false
            );
            MyReceivedLandRequest[lands[_landId].ownerAddress].push(
                requestCount
            );
            MySentLandRequest[msg.sender].push(requestCount);
        } else {
            revert();
        }
    }

    // function getLandPrice(uint id) public view returns(uint) {
    //     return lands[id].landPrice;
    // }

    function makePayment(
        address payable _receiver,
        uint _requestId
    ) public payable {
        if (
            LandRequestMapping[_requestId].buyerId == msg.sender &&
            LandRequestMapping[_requestId].requestStatus ==
            reqStatus.accepted &&
            LandRequestMapping[_requestId].sellerId == _receiver &&
            msg.value == lands[LandRequestMapping[_requestId].landId].landPrice
        ) {
            LandRequestMapping[_requestId].requestStatus = reqStatus
                .paymentdone;
            LandRequestMapping[_requestId].isPaymentDone = true;
            paymentDoneList[1].push(_requestId);
            _receiver.transfer(msg.value);
        } else {
            revert();
        }
    }

    function returnPaymentDoneList() public view returns (uint[] memory) {
        return paymentDoneList[1];
    }

    function transferDeceasedOwnership(
        address deceased
    ) public {
        require(isLandInspector(msg.sender));
        UserMapping[deceased].death = true;
        uint[] memory landIds = MyLands[deceased];
        for (uint i = 0; i < landIds.length; i++) {
            uint landId = landIds[i];
            Land storage land = lands[landId];
            if (
                land.ownerAddress == deceased &&
                InspectorMapping[msg.sender].district == land.district
            ) {
                documentId++;
                land.isforSell = false;
                land.ownerAddress = land.proxyownerAddress;
                MyLands[land.proxyownerAddress].push(landId);
                uint[] storage deceasedLands = MyLands[deceased];

                for (uint j = 0; j < deceasedLands.length; j++) {
                    if (deceasedLands[j] == landId) {
                        deceasedLands[j] = deceasedLands[
                            deceasedLands.length - 1
                        ];
                        deceasedLands.pop();
                        break;
                    }
                }

                land.proxyownerAddress = contractOwner;
            }
        }
    }

    function transferOwnership(
        uint _requestId,
        string memory documentUrl
    ) public {
        require(isLandInspector(msg.sender));
        if (
            LandRequestMapping[_requestId].isPaymentDone == false &&
            InspectorMapping[msg.sender].district ==
            lands[LandRequestMapping[_requestId].landId].district
        ) revert();
        documentId++;

        LandRequestMapping[_requestId].requestStatus = reqStatus.commpleted;
        MyLands[LandRequestMapping[_requestId].buyerId].push(
            LandRequestMapping[_requestId].landId
        );

        uint len = MyLands[LandRequestMapping[_requestId].sellerId].length;
        for (uint i = 0; i < len; i++) {
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
    }
}