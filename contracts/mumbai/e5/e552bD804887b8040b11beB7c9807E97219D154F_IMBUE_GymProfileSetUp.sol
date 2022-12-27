/**
 *Submitted for verification at polygonscan.com on 2022-12-26
*/

/**
 *Submitted for verification at polygonscan.com on 2022-10-29
 */

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.7;

contract IMBUE_GymProfileSetUp {
     uint public amountCut;

    constructor() public {
        amountCut = 0.01 * 1e18;
        Owner = msg.sender;
    }

    // uint256 OwnerFee = 0.2 ether;

    struct GymDetailsStruct {
        address GymOwner;
        string GymImageURLs;
        string GymName;
        string Genre;
        string Description;
        string Addresses;
        string SocialMediaLinks;
        uint256 MemberShipPrice;
        uint128 MobileNumber;
    }
    mapping(address => GymDetailsStruct) viewDescription;
    GymDetailsStruct[] private GymArr;
    mapping(address => bool) public IsMember;
    mapping(address => uint256) private MemberShipEnd;
    string[] private AddArr;
    address public Owner;

    function SetGymDetails(
        string memory _GymImageURLs,
        string memory _GymName,
        string memory _Genre,
        string memory _Description,
        string memory _Addresses,
        string memory _SocialMediaLinks,
        uint256 _MemberShipPrice,
        uint128 _MobileNumber
    ) public {
        if (
            viewDescription[msg.sender].GymOwner ==
            0x0000000000000000000000000000000000000000
        ) {
            viewDescription[msg.sender] = GymDetailsStruct(
                msg.sender,
                _GymImageURLs,
                _GymName,
                _Genre,
                _Description,
                _Addresses,
                _SocialMediaLinks,
                _MemberShipPrice,
                _MobileNumber
            );
            GymArr.push(viewDescription[msg.sender]);
            AddArr.push(_Addresses);
        } else {
            for (uint256 i = 0; i < GymArr.length; i++) {
                viewDescription[msg.sender] = GymDetailsStruct(
                    msg.sender,
                    _GymImageURLs,
                    _GymName,
                    _Genre,
                    _Description,
                    _Addresses,
                    _SocialMediaLinks,
                    _MemberShipPrice,
                    _MobileNumber
                );
                if (GymArr[i].GymOwner == msg.sender) {
                    GymArr[i] = viewDescription[msg.sender];
                }
            }
        }
    }

    function ViewDescription(address _user)
        public
        view
        returns (GymDetailsStruct memory)
    {
        return viewDescription[_user];
    }

    function GetGymLocations(address _user)
        public
        view
        returns (string memory)
    {
        return viewDescription[_user].Addresses;
    }

    function viewLocations(address _user, uint256 _Id)
        public
        view
        returns (string memory)
    {
        if (IsCreated[_user][_Id] == true) {
            return _ClassDetails[_Id][_user].Location;
        } else {
            return viewDescription[_user].Addresses;
        }
    }

    function RegisteredGyms() public view returns (GymDetailsStruct[] memory) {
        return GymArr;
    }

    function GetAddress() public view returns (string[] memory) {
        return AddArr;
    }
    function balance() public returns (uint256){
    return payable(address(this)).balance;
  } 
  function balanceNew(address owner) public view returns(uint accountBalance)
{
   accountBalance = owner.balance;
}

function getBalanceNew(address ContractAddress) public view returns(uint){
    return ContractAddress.balance;
}

    // User MembershipClass
    function purchaseMemberShip() public payable {
      
        require(
            MemberShipEnd[msg.sender] < block.timestamp,
            "You are already a member"
        );
        // payable(msg.sender).transfer(amountCut);
        (bool isSuccess, ) = payable(msg.sender).call{value: amountCut}("");
        require(isSuccess, "0.01 daalo");
        IsMember[msg.sender] = true;
        MemberShipEnd[msg.sender] = block.timestamp + 1669188668;

        //    require(msg.value == 1 ether, "Need to send 1 ETH");
    }
    

    struct ClassStruct {
    
        address studioWalletAddress;
        string ImageUrl;
        string ClassName;
        string Category;
        string SubCategory;
        string ClassLevel;
        string Description;
        string Location;
        string[] classModeAndEventKey;
        string DateAndTime;
        string Duration;
        string ClassType; // class is one time or repeating
        address WhoBooked;
        uint256 ClassId;
        bool IsBooked;
    }
    uint256 ClassID = 1;
    uint256 ClassCount;
    mapping(address => ClassStruct) ClassDetails;
    mapping(address => uint256) private Count;
    mapping(address => uint256) private BookedClassCount;
    mapping(uint256 => mapping(address => ClassStruct)) private _ClassDetails;
    mapping(address => mapping(uint256 => bool)) private IsCreated;
    mapping(uint256 => mapping(address => ClassStruct)) private BookedClasses;
    mapping(address => mapping(uint256 => bool)) private IsBooked;
    ClassStruct[] arr2;
    ClassStruct[] arr;

    function CreateAndScheduleClasses(
        string memory _ImageUrl,
        string memory _ClassName,
        string[] memory _Categories,
        string memory _ClassLevel,
        string memory _Description,
        string memory _Location,
        string[] memory _classModeAndEventKey,
        string memory _DateAndTime,
        string memory _Duration,
        string memory _ClassType
    ) public {
        ClassDetails[msg.sender] = ClassStruct(
            msg.sender,
            _ImageUrl,
            _ClassName,
            _Categories[0],
            _Categories[1],
            _ClassLevel,
            _Description,
            _Location,
            _classModeAndEventKey,
            _DateAndTime,
            _Duration,
            _ClassType,
            0x0000000000000000000000000000000000000000,
            ClassID,
            false
        );
        arr.push(ClassDetails[msg.sender]);
        _ClassDetails[ClassID][msg.sender] = ClassDetails[msg.sender];
        ClassID += 1;
        Count[msg.sender] += 1;
        IsCreated[msg.sender][ClassID] = true;
    }

    function editClass(
        address _user,
        uint256 _ClassID,
        string memory _ImageUrl,
        string[] memory _ClassNameAnd_Categories,
        string memory _ClassLevel,
        string memory _Description,
        string memory _Location,
        string[] memory _classModeAndEventKey,
        string memory _DateAndTime,
        string memory _Duration,
        string memory _ClassType
    ) public {
        _ClassDetails[_ClassID][_user] = ClassStruct(
            _user,
            _ImageUrl,
            _ClassNameAnd_Categories[0],
            _ClassNameAnd_Categories[1],
            _ClassNameAnd_Categories[2],
            _ClassLevel,
            _Description,
            _Location,
            _classModeAndEventKey,
            _DateAndTime,
            _Duration,
            _ClassType,
            0x0000000000000000000000000000000000000000,
            _ClassID,
            false
        );
        ClassDetails[_user] = _ClassDetails[_ClassID][_user];
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].ClassId == _ClassID) {
                arr[i] = ClassDetails[_user];
            }
        }
    }

    function getClasses(address _user)
        public
        view
        returns (ClassStruct[] memory)
    {
        uint8 _index = 0;
        uint256 count = Count[_user];
        ClassStruct[] memory arr1 = new ClassStruct[](count);
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].studioWalletAddress == _user) {
                arr1[_index] = arr[i];
                _index += 1;
            }
        }
        return arr1;
    }

    // User Book Class Function
    function BookClass(address _Owner, uint256 _ClassId) public {
        require(
            MemberShipEnd[msg.sender] >= block.timestamp,
            "Purchase subscription"
        );
        require(
            IsBooked[msg.sender][_ClassId] == false,
            "You already booked this class"
        );
        _ClassDetails[_ClassId][_Owner].WhoBooked = msg.sender;
        arr2.push(_ClassDetails[_ClassId][_Owner]);
        IsBooked[msg.sender][_ClassId] = true;
        BookedClassCount[msg.sender] += 1;
    }

    // User Book Class Function

    function getBookedClasses(address _user)
        public
        view
        returns (ClassStruct[] memory)
    {
        uint256 _Count = BookedClassCount[_user];
        uint256 _index = 0;
        ClassStruct[] memory arR = new ClassStruct[](_Count);
        for (uint256 i = 0; i < arr2.length; i++) {
            if (_user == arr2[i].WhoBooked) {
                arR[_index] = arr2[i];
                _index += 1;
            }
        }
        return arR;
    }
}