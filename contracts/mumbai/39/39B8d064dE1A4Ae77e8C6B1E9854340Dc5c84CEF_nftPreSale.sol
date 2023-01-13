// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

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

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}


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

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20 {
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

interface IERC721 {
    function balanceOf(address account) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mintForMiner(address _to) external returns (bool, uint256);

    function MinerList(address _address) external returns (bool);
}


library Item {
    struct idoConfig {
        uint256 startBlock; //开始时间
        uint256 endBlock; //结束时间
        uint256 totalAmount; //NFT总个数
        uint256 maxAmountPerUser; //NFT总个数
        uint256 idoAmount; //已卖出NFT数量
        uint256 price; //NFT的价格,以idoToken计价
        uint256 burnRate; //购买NFT时销毁idoToken的比例
        uint256 shareRate; //购买NFT时分享idoToken的比例
        IERC20 idoToken; //NFT的计价代币合约地址
        IERC721 nftToken; //NFT的合约地址
    }

    struct returnStruct {
        idoConfig _config;
        address _referer;
        uint256 _refererTime;
        uint256 _idoAmount;
        uint256 _refererIdoAmount;
    }
}

contract nftPreSale is Ownable {
    using Address for address;
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    address deadAddress = 0x000000000000000000000000000000000000dEaD;
    EnumerableSet.AddressSet private allRefererSet; //所有有直推客户的用户列表
    EnumerableSet.AddressSet private allShareRefererSet; //所有可分享销售金的用户列表
    mapping(address => address) public refererAddressList;
    mapping(address => uint256) public refererTimeList;
    mapping(address => EnumerableSet.AddressSet) private directReferralUsersList; //用户直推客户列表
    mapping(address => uint256) public userIdoAmountList; //客户购买NFT数量列表
    mapping(address => uint256) public directReferralUsersIdoTotalAmountList; //用户直推客户总销量
    Item.idoConfig public config;

    event buyNftEvent(address _user, uint256 _timestamp, uint256 _amount, uint256[] _tokenIDList);

    constructor () {
        refererAddressList[deadAddress] = msg.sender;
    }

    function setIdoConfig(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _totalAmount,
        uint256 _maxAmountPerUser,
        uint256 _price,
        uint256 _burnRate,
        uint256 _shareRate,
        IERC20 _idoToken,
        IERC721 _nftToken
    ) external onlyOwner {
        config.startBlock = _startBlock;
        config.endBlock = _endBlock;
        config.totalAmount = _totalAmount;
        config.maxAmountPerUser = _maxAmountPerUser;
        config.price = _price;
        config.burnRate = _burnRate;
        config.shareRate = _shareRate;
        config.idoToken = _idoToken;
        config.nftToken = _nftToken;
    }

    function setTimeLine(uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        config.startBlock = _startBlock;
        config.endBlock = _endBlock;
    }

    function setAmountList(uint256 _totalAmount, uint256 _maxAmountPerUser) external onlyOwner {
        config.totalAmount = _totalAmount;
        config.maxAmountPerUser = _maxAmountPerUser;
    }

    function setPrice(uint256 _price, uint256 _burnRate, uint256 _shareRate) external onlyOwner {
        config.price = _price;
        config.burnRate = _burnRate;
        config.shareRate = _shareRate;
    }

    function setTokenList(IERC20 _idoToken, IERC721 _nftToken) external onlyOwner {
        config.idoToken = _idoToken;
        config.nftToken = _nftToken;
    }

    //绑定推荐人
    function blindReferer(address _referer) external {
        require(!_referer.isContract(), "t001");
        require(_referer != address(0), "t002");
        require(refererAddressList[_referer] != address(0), "t003");
        require(refererAddressList[msg.sender] == address(0), "t004");
        refererAddressList[msg.sender] = _referer;
        refererTimeList[msg.sender] = block.timestamp;
        directReferralUsersList[_referer].add(msg.sender);
        if (!allRefererSet.contains(_referer) && _referer != deadAddress) {
            allRefererSet.add(_referer);
        }
    }

    function buyNft(uint256 _amount) external {
        require(config.nftToken.MinerList(address(this)), "t005");
        //不能超过总量
        require(config.idoAmount.add(_amount) <= config.totalAmount, "t006");
        //每个人不能超过10个
        require(userIdoAmountList[msg.sender].add(_amount) <= config.maxAmountPerUser, "t007");
        uint256 _allAmount = config.price.mul(_amount);
        require(config.idoToken.balanceOf(msg.sender) >= _allAmount, "t008");
        uint256 _burnAmount = _allAmount.mul(config.burnRate).div(100);
        uint256 _shareAmount = _allAmount.sub(_burnAmount);
        config.idoToken.transferFrom(msg.sender, deadAddress, _burnAmount);
        config.idoToken.transferFrom(msg.sender, address(this), _shareAmount);
        //更新用户购买NFT数量
        userIdoAmountList[msg.sender] = userIdoAmountList[msg.sender].add(_amount);
        //更新推荐人的销售业绩
        if (refererAddressList[msg.sender] != address(0) && refererAddressList[msg.sender] != deadAddress) {
            address _referer = refererAddressList[msg.sender];
            directReferralUsersIdoTotalAmountList[_referer] = directReferralUsersIdoTotalAmountList[_referer].add(_amount);
            if (directReferralUsersIdoTotalAmountList[_referer] >= 10 && !allShareRefererSet.contains(_referer)) {
                allShareRefererSet.add(_referer);
            }
        }
        uint256[]  memory _tokenIDList = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            (bool _status,uint256 _nftID) = config.nftToken.mintForMiner(msg.sender);
            require(_status, "t009");
            _tokenIDList[i] = _nftID;
        }
        emit buyNftEvent(msg.sender, block.timestamp, _amount, _tokenIDList);
    }


    function claimIdoToken() external onlyOwner {
        config.idoToken.transfer(msg.sender, config.idoToken.balanceOf(address(this)));
    }

    //获取所有有直推客户的用户数量和列表
    function getAllRefererSet() external view returns (uint256 _num, address[] memory _addressList) {
        _num = allRefererSet.length();
        _addressList = allRefererSet.values();
    }

    //根据索引获取所有有直推客户的用户数量和列表
    function getAllRefererSetByIndexList(uint256[] memory _indexList) external view returns (uint256 _num, address[] memory _addressList) {
        _num = _indexList.length;
        _addressList = new address[](_num);
        for (uint256 i = 0; i < _num; i++) {
            uint256 _index = _indexList[i];
            _addressList[i] = allRefererSet.at(_index);
        }
    }

    //获取所有拥有分享销售金的用户数量和列表
    function getAllShareRefererSet() external view returns (uint256 _num, address[] memory _addressList) {
        _num = allShareRefererSet.length();
        _addressList = allShareRefererSet.values();
    }

    //获取用户的直推客户的数量和列表
    function getDirectReferralUsersList(address _user) public view returns (uint256 _num, address[] memory _addressList) {
        _num = directReferralUsersList[_user].length();
        _addressList = directReferralUsersList[_user].values();
    }

    //获取用户的直推客户的数量和列表
    function getDirectReferralUsersListByIndexList(address _user, uint256[] memory _indexList) public view returns (uint256 _num, address[] memory _addressList) {
        _num = _indexList.length;
        _addressList = new address[](_num);
        for (uint256 i = 0; i < _num; i++) {
            uint256 _index = _indexList[i];
            _addressList[i] = directReferralUsersList[_user].at(_index);
        }
    }

    function getIdoAmountList(address[] memory _addressList) public view returns (uint256[] memory _idoAmountList) {
        uint256 _num = _addressList.length;
        _idoAmountList = new uint256[](_num);
        for (uint256 i = 0; i < _num; i++) {
            address _user = _addressList[i];
            _idoAmountList[i] = userIdoAmountList[_user];
        }
    }

    function getAllInfo(address _user) public view returns (Item.returnStruct memory _returnList) {
        //ido配置信息
        _returnList._config = config;
        //该用户的推荐人
        _returnList._referer = refererAddressList[_user];
        //绑定推荐人的时间
        _returnList._refererTime = refererTimeList[_user];
        //该用户购买NFT的数量
        _returnList._idoAmount = userIdoAmountList[_user];
        //该用户推荐产生的总销售
        _returnList._refererIdoAmount = directReferralUsersIdoTotalAmountList[_user];
    }

    function getAllInfoWithList(address _user) public view returns (Item.returnStruct memory _returnList, uint256 _num, address[] memory _addressList, uint256[] memory _idoAmountList) {
        _returnList = getAllInfo(_user);
        (_num, _addressList) = getDirectReferralUsersList(_user);
        _idoAmountList = getIdoAmountList(_addressList);
    }

    function getAllInfoWithListByIndexList(address _user, uint256[] memory _indexList) public view returns (Item.returnStruct memory _returnList, uint256 _num, address[] memory _addressList, uint256[] memory _idoAmountList) {
        _returnList = getAllInfo(_user);
        (_num, _addressList) = getDirectReferralUsersListByIndexList(_user, _indexList);
        _idoAmountList = getIdoAmountList(_addressList);
    }

}