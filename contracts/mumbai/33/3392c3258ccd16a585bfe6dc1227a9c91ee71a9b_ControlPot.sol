/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }
            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }
    struct Bytes32Set {
        Set _inner;
    }
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;
        assembly {
            result := store
        }
        return result;
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;
        assembly {
            result := store
        }

        return result;
    }
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;
        assembly {
            result := store
        }

        return result;
    }
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library myLibrary {
    struct bidPrice {
        uint256 bidOption;
        uint256 variable1;
        uint256 variable2;
    }
    struct expiryTimeInfo {
        uint256 expiryOption;
        uint256 startTime;
        uint256 decreaseBy;
        uint256 minimumTime;
    }
    struct createPotValue {
        address ERC721Address;
        address topOwner;
        address ownerOfTournament;
        bool isNative;
        uint256 tokenID;
        address bidToken;
        address potControlAddress;
        bidPrice bid;
        address[] toAddress;
        uint256[] toPercent;
        expiryTimeInfo expiryTime;
        bool priorityPool;
        uint256 toPreviousFee;
        uint256 ownerOfTournamentFee;
        uint256 hardExpiry;
        uint256 createNumber;
    }
}

contract Pot {

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet _listedLicenseSet;

    uint256 public tokenID;
    address public bidToken;
    uint256 public bidAmount;
    bool public priorityPool;
    bool public isClaim;
    uint256 public createdDate;
    uint256 public timeUntilExpiry;   
    address public ownerOfTournament;
    uint256 public ownerOfTournamentFee;
    address public lastBidWinner;
    uint256 public lengthOfBidDistribution = 0;

    uint256 public toOwnerFee = 3;
    uint256 public percent = 100;
    address public toPreviousBidder;
    uint256 public toPreviousBidderFee;

    uint256 private winnerClaimAllowTime = 600; // 2851200000; // 33 days
    uint256 private createClaimAllowTime = 720; // 5702400000; // 66 days
    address public topOwner;

    uint256 public bidOption;
    uint256 public bidVariable1;
    uint256 public bidVariable2;
    uint256 public hardExpiry;
    bool public isNative;
    uint256 public claimedDate;

    address public potControlAddress;

    uint256 public expirationTime;
    uint256 public expExpiryOption;
    uint256 public expDecreaseBy;
    uint256 public expMinimumTime;
    address public CERC721AddRess;
    uint256 createNumber;

    IERC20 _token;    
    IERC721 erc721Token;

    struct bidDistributionInfo {
        address toAddress;
        uint256 percentage;
    }
    mapping(uint256 => bidDistributionInfo) public bidInfo;

    struct bidderInfo {
        uint256 total_bid;
    }
    mapping(address => bidderInfo) public bidders;    
    address[] public bidAddressList;

    modifier onlyOwner() {
        require(msg.sender == ownerOfTournament, "Not onwer");
        _;
    }

    constructor() {
    }

    function setTopOwner(address newTopOwner) public {
        require(topOwner == msg.sender, "Error: you can not change Top Owner address!");
        topOwner = newTopOwner;
    }

    function calcBidAmount(uint256 _bidOption, uint256 _variable1, uint256 _variable2) internal {
        if(_bidOption == 1) {
            bidAmount = _variable1;
        } else if (_bidOption == 2) {
            bidAmount = bidAmount + bidAmount.mul(_variable2).div(percent);
        }
    }

    function initialize(myLibrary.createPotValue memory sValue) external {
        if (lengthOfBidDistribution > 0) {
            require(topOwner == msg.sender, "Error: you can not change initial variable");
        }
        bidToken = sValue.bidToken;
        isNative = sValue.isNative;        
        _token = IERC20(address(bidToken));
        lengthOfBidDistribution = sValue.toAddress.length;
        for(uint256 i = 0; i < sValue.toAddress.length; i++) {
            bidInfo[i].toAddress = sValue.toAddress[i];
            bidInfo[i].percentage = sValue.toPercent[i];
        }        
        erc721Token = IERC721(address(sValue.ERC721Address));
        priorityPool = sValue.priorityPool;
        CERC721AddRess = address(sValue.ERC721Address);
        createNumber = sValue.createNumber;
        _listedLicenseSet.add(sValue.ownerOfTournament);
        createdDate = block.timestamp;
        potControlAddress = sValue.potControlAddress;
        timeUntilExpiry = createdDate + sValue.expiryTime.startTime;  
        expExpiryOption = sValue.expiryTime.expiryOption;      
        expirationTime = sValue.expiryTime.startTime;
        expDecreaseBy = sValue.expiryTime.decreaseBy;
        expMinimumTime = sValue.expiryTime.minimumTime;

        tokenID = sValue.tokenID;
        lastBidWinner = sValue.ownerOfTournament;
        toPreviousBidderFee = sValue.toPreviousFee;
        ownerOfTournamentFee = sValue.ownerOfTournamentFee;
        ownerOfTournament = sValue.ownerOfTournament;

        topOwner = sValue.topOwner;    
        
        bidOption = sValue.bid.bidOption;  
        bidVariable1 = sValue.bid.variable1;  
        bidVariable2 = sValue.bid.variable2; 
        isClaim = false;

        if(bidOption == 1) {
            bidAmount = bidVariable1;
        } else if (bidOption == 2) {
            bidAmount = bidVariable1;
        }
    }
               
    function bid() public payable returns (uint256) {
        require(timeUntilExpiry > block.timestamp, "You cannot bid! Because this pot is closed biding!");
        require(msg.value > 0, "Insufficinet value");
        require(msg.value == bidAmount, "Your bid amount will not exact!");   

        toPreviousBidder = lastBidWinner;
        bidders[msg.sender].total_bid += bidAmount;

        uint256 value = msg.value;
        lastBidWinner = msg.sender;
        
        bool exist = false;
        for(uint256 cnt = 0; cnt < bidAddressList.length; cnt++) {
            if(bidAddressList[cnt] == msg.sender) {
                exist = true;
            }
        }
        if(exist == false) {
            bidAddressList.push(msg.sender);
        }
        _listedLicenseSet.add(lastBidWinner);

        if(expExpiryOption == 2 && expirationTime > expMinimumTime) {
            expirationTime -= expDecreaseBy;
        }

        uint256 onwerFee = bidAmount.mul(toOwnerFee).div(percent);        
        payable(address(topOwner)).transfer(onwerFee);    
        value = value - onwerFee;

        uint256 previousBidderFee = bidAmount.mul(toPreviousBidderFee).div(percent);        
        payable(address(toPreviousBidder)).transfer(previousBidderFee);    
        value = value - previousBidderFee;

        uint256 vOwnerOfTournamentFee = bidAmount.mul(ownerOfTournamentFee).div(percent);        
        payable(address(ownerOfTournament)).transfer(vOwnerOfTournamentFee);    
        value = value - vOwnerOfTournamentFee;

        for (uint i = 0; i < lengthOfBidDistribution; i++) {
            uint256 bidFee = bidAmount.mul(bidInfo[i].percentage).div(percent);
            payable(address(bidInfo[i].toAddress)).transfer(bidFee);
            value = value - bidFee;
        }

        uint256 createdBid = block.timestamp;
        timeUntilExpiry = createdBid + expirationTime;
             
        // potAmount = address(this).balance;
        calcBidAmount(bidOption, bidVariable1, bidVariable2);
        return bidAmount;
    }

    function bidERC20() public returns (uint256) {
        if(hardExpiry != 0) {
            require(hardExpiry > block.timestamp, "Hard Expiry is working now");
        }
        require(timeUntilExpiry > block.timestamp, "You cannot bid! Because this pot is closed biding!");

        toPreviousBidder = lastBidWinner;
        bidders[msg.sender].total_bid += bidAmount;

        uint256 value = bidAmount;
        lastBidWinner = msg.sender;
        _listedLicenseSet.add(lastBidWinner);
        bool exist = false;
        for(uint256 cnt = 0; cnt < bidAddressList.length; cnt++) {
            if(bidAddressList[cnt] == msg.sender) {
                exist = true;
            }
        }
        if(exist == false) {
            bidAddressList.push(msg.sender);
        }

        if(expExpiryOption == 2 && expirationTime > expMinimumTime) {
            expirationTime -= expDecreaseBy;
        }
        uint256 onwerFee = bidAmount.mul(toOwnerFee).div(percent);        
        _token.transferFrom(msg.sender, topOwner, onwerFee);
        value = value - onwerFee;

        uint256 previousBidderFee = bidAmount.mul(toPreviousBidderFee).div(percent);  
        _token.transferFrom(msg.sender, toPreviousBidder, previousBidderFee);   
        value = value - previousBidderFee;

        uint256 vOwnerOfTournamentFee = bidAmount.mul(ownerOfTournamentFee).div(percent);  
        _token.transferFrom(msg.sender, ownerOfTournament, vOwnerOfTournamentFee);   
        value = value - vOwnerOfTournamentFee;

        for (uint i = 0; i < lengthOfBidDistribution; i++) {
            uint256 bidFee = bidAmount.mul(bidInfo[i].percentage).div(percent);        
            _token.transferFrom(msg.sender, bidInfo[i].toAddress, bidFee);   
            value = value - bidFee;
        }
        _token.transferFrom(msg.sender, address(this), value); 
        uint256 createdBid = block.timestamp;
        timeUntilExpiry = createdBid + expirationTime;
             
        // potAmount = _token.balanceOf(address(this));
        calcBidAmount(bidOption, bidVariable1, bidVariable2);
        return bidAmount;
    }

    
    function getTotalBid(address to) public view returns(uint256) {
        bidderInfo storage bidder = bidders[to];
        return bidder.total_bid;
    }

    function getLifeTime() public view returns (uint256) {
        if(timeUntilExpiry > block.timestamp){
            uint256 lifeTime = timeUntilExpiry - block.timestamp;
            return lifeTime;  
        } else {
            return 0;
        }
    }
    function getBiddersInfo() public view returns(address[] memory ){
        return bidAddressList;
    }

    function claim() public returns (uint256) {
        address claimAvailableAddress;
        address topBidder = _listedLicenseSet.at(0);
        uint256 lengthOf = _listedLicenseSet.length();

        for(uint256 cnt = 0; cnt < lengthOf; cnt++) {
            address temp = _listedLicenseSet.at(cnt);
            if(bidders[topBidder].total_bid < bidders[temp].total_bid) {
                topBidder = temp;
            }
        }

        if(hardExpiry == 0) {
            if(block.timestamp < timeUntilExpiry) {
                claimAvailableAddress = 0x0000000000000000000000000000000000000000;
            } else if (timeUntilExpiry < block.timestamp && block.timestamp < timeUntilExpiry + winnerClaimAllowTime) {
                claimAvailableAddress = topBidder;
            } else if (timeUntilExpiry + winnerClaimAllowTime < block.timestamp && block.timestamp < timeUntilExpiry + createClaimAllowTime) {
                claimAvailableAddress = ownerOfTournament;
            } else {
                claimAvailableAddress = topOwner;
            }
        } else {
            if(block.timestamp < hardExpiry) {
                claimAvailableAddress = 0x0000000000000000000000000000000000000000;
            } else if (hardExpiry < block.timestamp && block.timestamp < hardExpiry + winnerClaimAllowTime) {
                claimAvailableAddress = topBidder;
            } else if (hardExpiry + winnerClaimAllowTime < block.timestamp && block.timestamp < hardExpiry + createClaimAllowTime) {
                claimAvailableAddress = ownerOfTournament;
            } else {
                claimAvailableAddress = topOwner;
            }
        }

        require(msg.sender == claimAvailableAddress, "You cannot claim!");
        erc721Token.transferFrom(address(this), msg.sender, tokenID);
        isClaim = true;
        claimedDate = block.timestamp;
        return address(this).balance;
    }

    modifier checkAllowance(uint256 amount) {
        require(_token.allowance(msg.sender, address(this)) >= amount, "Allowance Error");
        _;
    }
    function depositNFTNative() external {
        address owner = erc721Token.ownerOf(tokenID);
        require(owner == msg.sender, "you are not token owner!");
        erc721Token.transferFrom(owner, address(this), tokenID);
    }
}

pragma solidity >=0.7.0 <0.9.0;
contract ControlPot {
    event Deployed(address);
    event Received(address, uint256);
    address public topOwner;
    address[] public allTournaments;
    address[] public bidDistributionAddress;

    uint256 public toOwnerFee = 3;
    uint256 public percent = 100;

    address[] public tokenList;
      
    uint256 private bidPercent = 0;

    constructor() {
        topOwner = msg.sender;
    }

    struct bidPrice {
        uint256 bidOption;
        uint256 variable1;
        uint256 variable2;
    }
    struct expiryTimeInfoVal {
        uint256 expiryOption;
        uint256 startTime;
        uint256 decreaseBy;
        uint256 minimumTime;
    }
    modifier onlyOwner() {
        require(msg.sender == topOwner, "Not onwer");
        _;
    }
    function addToken(address _token) external onlyOwner{
        tokenList.push(_token);
    }
    function removeToken(uint256 _index) external onlyOwner{
        delete tokenList[_index];
    }
    function getTokenList() external view returns (address[] memory) {
        return tokenList;
    }
    function allTournamentsLength() external view returns (uint256) {
        return allTournaments.length;
    }
    function setTopOwner(address newTopOwner) public {
        require(topOwner == msg.sender, "Error: you can not change Top Owner address!");
        topOwner = newTopOwner;
    }
    function setToOwnerFee(uint256 newToOwnerFee) public {
        require(topOwner == msg.sender, "Error: you can not change Top Owner address!");
        toOwnerFee = newToOwnerFee;
    }
    function createPot(address _NFTERC721, uint256 _tokenID, uint256 _bidTokenIndex, bool _isNative, bidPrice memory _bid, address[] memory _toAddress, uint256[] memory _toPercent, expiryTimeInfoVal memory _expirationTime, uint256 _hardExpiry, bool _priorityPool, uint256[] memory _creatorAndPreviousFee) external payable returns (address pair) {
        require(_toAddress.length == _toPercent.length, "Length of address and percentage is not match"); 
        for (uint256 i = 0; i < _toPercent.length; i++) {
            bidPercent += _toPercent[i];
        }
        require(bidPercent == (percent - toOwnerFee - _creatorAndPreviousFee[0] - _creatorAndPreviousFee[1]), "Fee is not 100%!");
        bytes memory bytecode = type(Pot).creationCode;
        myLibrary.createPotValue memory cValue; 
        cValue.ERC721Address = _NFTERC721;
        cValue.topOwner = topOwner;
        cValue.tokenID = _tokenID;
        cValue.createNumber = _creatorAndPreviousFee[2];
        cValue.ownerOfTournament = msg.sender;
        cValue.bidToken = tokenList[_bidTokenIndex];
        cValue.bid.bidOption = _bid.bidOption;
        cValue.bid.variable1 = _bid.variable1;
        cValue.bid.variable2 = _bid.variable2;
        cValue.toAddress = _toAddress;
        cValue.isNative = _isNative;
        cValue.toPercent = _toPercent;
        cValue.hardExpiry = _hardExpiry;
        cValue.ownerOfTournamentFee = _creatorAndPreviousFee[1];
        cValue.expiryTime.expiryOption = _expirationTime.expiryOption;
        cValue.expiryTime.startTime = _expirationTime.startTime;
        cValue.expiryTime.decreaseBy = _expirationTime.decreaseBy;
        cValue.expiryTime.minimumTime = _expirationTime.minimumTime;
        cValue.priorityPool = _priorityPool;
        cValue.toPreviousFee = _creatorAndPreviousFee[0] ;
        cValue.potControlAddress = address(this);
        bytes32 salt = keccak256(abi.encodePacked(tokenList[_bidTokenIndex], _bid.variable1, _toAddress, _toPercent, cValue.expiryTime.startTime, cValue.expiryTime.decreaseBy, cValue.expiryTime.minimumTime, _priorityPool, _creatorAndPreviousFee[0]));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        allTournaments.push(pair);
        Pot(pair).initialize(cValue);
        emit Deployed(pair);
        bidPercent = 0;
        return pair;
    }
}