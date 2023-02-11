// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
                set._indexes[lastValue] = valueIndex;
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
        return _values(set._inner);
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

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e003");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e004");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e005");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e006");
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function approve(address spender, uint value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);
}

contract shareTokenCx is Ownable {
    struct shareItem {
        uint256 _shareId;  //索引编号
        uint256 _createTime; //创建时间
        uint256 _canClaimTime; //可领取时间
        IERC20 _token; //代币合约
        uint256 _totalAmount; //总金额
        uint256 _shareNumber; //总人数
        uint256 _claimAmountPerShare; //每人可领取份额
    }

    struct erc20TokenItem {
        //代币合约
        IERC20 token;
        //已分配数量
        uint256 sharedAmount;
        //已领取数量
        uint256 claimedAmount;

    }

    struct userInfoItem {
        uint256 _claimTime;
        uint256 _time;
        uint256 _claimAmount;
        bool _inWhiteList;
        bool _canClaim;
        bool _hasClaimed;
    }
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    //每次分配的地址列表
    mapping(uint256 => EnumerableSet.AddressSet) private whiteListForPerShareList;
    //每次分配用户是否已领取
    mapping(address => mapping(uint256 => bool)) public claimStatusList;
    //已经分配的次数
    uint256 public shareId;
    uint256[] public shareIdList;
    mapping(uint256 => shareItem) public shareList;
    mapping(IERC20 => erc20TokenItem) public tokenList;

    event setShareEvent(uint256 _blockNumber, uint256 _createtime, uint256 _claimTime, uint256 _shareId, uint256 _shareAmount);

    function setShare(IERC20 _token, uint256 _claimTime, uint256 _shareNumber) external onlyOwner {
        uint256 _shareAmount = _token.balanceOf(address(this)).add(tokenList[_token].claimedAmount).sub(tokenList[_token].sharedAmount);
        require(_shareAmount > 0, "e001");
        shareItem memory x = new shareItem[](1)[0];
        x._shareId = shareId;
        x._createTime = block.timestamp;
        x._canClaimTime = _claimTime;
        x._token = _token;
        x._totalAmount = _shareAmount;
        x._shareNumber = _shareNumber;
        x._claimAmountPerShare = _shareAmount.div(_shareNumber);
        shareList[shareId] = x;
        shareIdList.push(shareId);
        emit setShareEvent(block.number, block.timestamp, _claimTime, shareId, _shareAmount);
        shareId = shareId.add(1);
        tokenList[_token].token = _token;
        tokenList[_token].sharedAmount = tokenList[_token].sharedAmount.add(_shareAmount);
    }

    function AddWhiteList(uint256 _shareId, address[] memory _addressList) external onlyOwner {
        //在没有达到领取时间之前可以修改白名单
        require(_shareId < shareId, "e002");
        require(block.timestamp < shareList[_shareId]._canClaimTime, "e003");
        for (uint256 i = 0; i < _addressList.length; i++) {
            if (!whiteListForPerShareList[_shareId].contains(_addressList[i])) {
                whiteListForPerShareList[_shareId].add(_addressList[i]);
            }
        }
        require(whiteListForPerShareList[_shareId].length() <= shareList[_shareId]._shareNumber, "e004");
    }

    function removeWhiteList(uint256 _shareId, address[] memory _addressList) external onlyOwner {
        require(_shareId < shareId, "e005");
        require(block.timestamp < shareList[_shareId]._canClaimTime, "e006");
        for (uint256 i = 0; i < _addressList.length; i++) {
            if (whiteListForPerShareList[_shareId].contains(_addressList[i])) {
                whiteListForPerShareList[_shareId].remove(_addressList[i]);
            }
        }
        require(whiteListForPerShareList[_shareId].length() <= shareList[_shareId]._shareNumber, "e007");
    }

    function claimById(uint256 _shareId) public {
        uint256 _claimAmount = shareList[_shareId]._claimAmountPerShare;
        if (whiteListForPerShareList[_shareId].contains(msg.sender) && !claimStatusList[msg.sender][_shareId] && block.timestamp >= shareList[_shareId]._canClaimTime) {
            shareList[_shareId]._token.transfer(msg.sender, _claimAmount);
            claimStatusList[msg.sender][_shareId] = true;
            tokenList[shareList[_shareId]._token].claimedAmount = tokenList[shareList[_shareId]._token].claimedAmount.add(_claimAmount);
        }
    }

    function claimByShareIdList(uint256[] memory _shareIdList) public {
        for (uint256 i = 0; i < _shareIdList.length; i++) {
            uint256 _shareId = _shareIdList[i];
            claimById(_shareId);
        }
    }

    function getUserInfo(address _user, uint256 _shareId) public view returns (userInfoItem memory _userInfo) {
        _userInfo._claimTime = shareList[_shareId]._canClaimTime;
        _userInfo._time = block.timestamp;
        _userInfo._canClaim = block.timestamp >= shareList[_shareId]._canClaimTime;
        _userInfo._claimAmount = shareList[_shareId]._claimAmountPerShare;
        _userInfo._inWhiteList = whiteListForPerShareList[_shareId].contains(_user);
        _userInfo._hasClaimed = claimStatusList[_user][_shareId];
    }

    function massGetAllUserInfo(address _user) public view returns (userInfoItem[] memory _userInfoList) {
        uint256 _num = shareIdList.length;
        _userInfoList = new userInfoItem[](_num);
        for (uint256 i = 0; i < _num; i++) {
            _userInfoList[i] = getUserInfo(_user, shareIdList[i]);
        }
    }

    function massGetUserInfo(address _user, uint256[] memory _shareIdList) public view returns (userInfoItem[] memory _userInfoList) {
        uint256 _num = _shareIdList.length;
        _userInfoList = new userInfoItem[](_num);
        for (uint256 i = 0; i < _num; i++) {
            _userInfoList[i] = getUserInfo(_user, _shareIdList[i]);
        }
    }
}