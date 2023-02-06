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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

    enum cardType {Gold, Silver, Bronze}
    enum typeSet {AllSet, GoldSet, SilverSet, BronzeSet, taskUserSet, allGoldUserSet, allSilverUserSet, allBronzeUserSet, fatherAddressSet, GoldLastIndexSet, userGetRewardIndexSet}
interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function mintForMiner(address _to) external returns (bool, uint256);

    function setType(uint256 _tokenId, cardType _type) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface swapRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract nftcx is Ownable {
    struct configItem {
        uint256 startBlock;
        uint256 endBlock;
        IERC20 erc20Token;
        IERC721 nftToken;
        uint256 price;
        uint256 bronzeRate;
        uint256 shareRate;
        uint256 allRate;
        address teamAddress;
    }

    struct swapConfigItem {
        bool useAutoSwap;
        swapRouter routerAddress;
        IERC20 swapInToken;
        IERC20 swapOutToken;
        uint256 swapInAmount;
        uint256 slippage; //滑点
    }

    struct userInfoItem {
        configItem config; //项目配置
        bool isGold; //是不是金卡
        bool isSilver; //是不是银卡
        bool isBronze; //是不是铜卡
        bool canInvite; //是否可邀请用户
        address referer; //直接推荐人
        address node; //节点
        uint256 taskAmount; //完成铜卡任务数
        uint256 tokenId; //卡牌编号
        uint256 sonAmount; //所有用户数量
        uint256 allReward; //所有奖励
        address[] taskAddressList; //铜卡任务的直推地址列表
        address[] allGoldUserSet;
        address[] allSilverUserSet;
        address[] allBronzeUserSet;
        address[] fatherAddressSet;
    }
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    //所有用户集
    EnumerableSet.AddressSet private AllSet;
    //金卡用户集
    EnumerableSet.AddressSet private GoldSet;
    //银卡用户集
    EnumerableSet.AddressSet private SilverSet;
    //铜卡用户集
    EnumerableSet.AddressSet private BronzeSet;
    //动态分红索引集,如何第一张NFT销售时,有2个金卡用户,记录为2,索引为0,1的金卡用户可分红
    uint256[] public GoldLastIndexList;
    uint256 public maxInt = 1000;
    //项目参数
    configItem public config;
    swapConfigItem public swapConfig;
    //用户是否已购买NFT列表
    mapping(address => bool) public hasMintedList;
    //用户的直接推荐人列表
    mapping(address => address) public refererList;
    //用户的领导人列表,金卡为address(1),银卡为address(2),铜卡为金卡用户
    mapping(address => address) public nodeList;
    //每个用户的累计佣金列表
    mapping(address => uint256) public allRewardList;
    //铜卡用户完成任务的数量
    mapping(address => uint256) public taskAmountList;
    //铜卡用户推荐的用户集,最多两个
    mapping(address => EnumerableSet.AddressSet) private taskUserSet;
    //金卡用户下面所有的金卡
    mapping(address => EnumerableSet.AddressSet) private allGoldUserSet;
    //金卡用户下面所有的银卡
    mapping(address => EnumerableSet.AddressSet) private allSilverUserSet;
    //金卡用户下面所有的铜卡
    mapping(address => EnumerableSet.AddressSet) private allBronzeUserSet;
    uint256 public NodeNum = 0;
    mapping(address => uint256) public userNodeIndexList;
    //用户mint的tokenID列表
    mapping(address => uint256) public tokenIdList;
    //用户体系下所有的用户数量列表
    mapping(address => uint256) public sonAmountList;
    //用户的推荐人集
    mapping(address => EnumerableSet.AddressSet) private fatherAddressSet;
    //金卡已领取平台奖励的索引集
    mapping(address => EnumerableSet.UintSet) private userGetRewardIndexSet;

    event BindReferer(uint256 _blockNumber, uint256 _time, address _user, address _referer, address _node);
    event upgradeToGoldE(uint256 _swapOutAmount, uint256 _amountIn, uint256 _amountOutMin, address[] _swapPath, address _to, uint256 _time);
    event getReward(uint256 _blockNumber, uint256 _time, address _childAddress, address _parentAddress, uint256 _rewardAmount, string _type);

    function setConfig(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _price,
        uint256 _bronzeRate,
        uint256 _shareRate,
        uint256 _allRate,
        IERC20 _erc20Token,
        IERC721 _nftToken,
        address _teamAddress
    ) external onlyOwner {
        setTimeLine(_startBlock, _endBlock);
        setPrice(_price, _bronzeRate, _shareRate, _allRate);
        setTokenList(_erc20Token, _nftToken);
        setTeamAddress(_teamAddress);
    }

    function setMaxInt(uint256 _maxInt) external onlyOwner {
        maxInt = _maxInt;
    }

    function setSwapConfig(
        bool _useAutoSwap,
        swapRouter _routerAddress,
        IERC20 _swapInToken,
        IERC20 _swapOutToken,
        uint256 _swapInAmount,
        uint256 _slippage,
        uint256 _approveAmount
    ) external onlyOwner {
        swapConfig.useAutoSwap = _useAutoSwap;
        swapConfig.routerAddress = _routerAddress;
        swapConfig.swapInToken = _swapInToken;
        swapConfig.swapOutToken = _swapOutToken;
        swapConfig.swapInAmount = _swapInAmount;
        swapConfig.slippage = _slippage;
        _swapInToken.approve(address(_routerAddress), _approveAmount);
        _swapOutToken.approve(address(_routerAddress), _approveAmount);
    }

    function setTimeLine(uint256 _startBlock, uint256 _endBlock) public onlyOwner {
        config.startBlock = _startBlock;
        config.endBlock = _endBlock;
    }

    function setPrice(uint256 _price, uint256 _bronzeRate, uint256 _shareRate, uint256 _allRate) public onlyOwner {
        config.price = _price;
        config.bronzeRate = _bronzeRate;
        config.shareRate = _shareRate;
        config.allRate = _allRate;
    }

    function setTokenList(IERC20 _erc20Token, IERC721 _nftToken) public onlyOwner {
        config.erc20Token = _erc20Token;
        config.nftToken = _nftToken;
    }

    function setTeamAddress(address _teamAddress) public onlyOwner {
        config.teamAddress = _teamAddress;
    }

    function addNodeList(address[] memory _nodeList) external onlyOwner {
        for (uint256 i = 0; i < _nodeList.length; i++) {
            address _node = _nodeList[i];
            if (!AllSet.contains(_node)) {
                AllSet.add(_node);
                GoldSet.add(_node);
                nodeList[_node] = address(1);
                (bool _status, uint256 _tokenId) = config.nftToken.mintForMiner(_node);
                require(_status, "t001");
                config.nftToken.setType(_tokenId, cardType.Gold);
                tokenIdList[_node] = _tokenId;
                hasMintedList[_node] = true;
                userNodeIndexList[_node] = NodeNum;
                NodeNum = NodeNum.add(1);
                emit BindReferer(block.number, block.timestamp, _node, address(0), address(1));
            }
        }
    }

    function buyNFT(address _referer) external {
        address _user = msg.sender;
        require(block.timestamp >= config.startBlock && block.timestamp <= config.endBlock, "e001");
        require(config.erc20Token.balanceOf(_user) >= config.price, "e002");
        require(!AllSet.contains(_user), "e003");
        //用户不能已存在
        require(AllSet.contains(_referer), "e004");
        //推荐人必须存在
        require(nodeList[_referer] != address(2), "e005");
        //不能是银卡
        AllSet.add(_user);
        refererList[_user] = _referer;
        GoldLastIndexList.push(GoldSet.length());
        BronzeSet.add(_user);
        (bool _status, uint256 _tokenId) = config.nftToken.mintForMiner(_user);
        require(_status, "e006");
        //设置卡的类型
        config.nftToken.setType(_tokenId, cardType.Bronze);
        tokenIdList[_user] = _tokenId;
        uint256 rewardForShare = config.price.mul(config.shareRate).div(100);
        config.erc20Token.transferFrom(_user, address(this), rewardForShare);
        if (nodeList[_referer] == address(1)) {
            address _node = _referer;
            //推荐人是金卡
            uint256 rewardForGold = config.price.mul(config.allRate).div(100);
            uint256 rewardLeft = config.price.sub(rewardForGold).sub(rewardForShare);
            config.erc20Token.transferFrom(_user, _node, rewardForGold);
            config.erc20Token.transferFrom(_user, config.teamAddress, rewardLeft);
            allRewardList[_referer] = allRewardList[_referer].add(rewardForGold);
            nodeList[_user] = _referer;
            allBronzeUserSet[_referer].add(_user);
            emit BindReferer(block.number, block.timestamp, _user, _referer, _node);
            emit getReward(block.number, block.timestamp, _user, _referer, rewardForGold, "Team");
        } else {
            //推荐人是铜卡
            address _node = nodeList[_referer];
            uint256 rewardForBronze = config.price.mul(config.bronzeRate).div(100);
            uint256 rewardForGold = config.price.mul(config.allRate).div(100).sub(rewardForBronze);
            uint256 rewardLeft = config.price.sub(rewardForGold).sub(rewardForBronze).sub(rewardForShare);
            config.erc20Token.transferFrom(_user, _node, rewardForGold);
            config.erc20Token.transferFrom(_user, _referer, rewardForBronze);
            config.erc20Token.transferFrom(_user, config.teamAddress, rewardLeft);
            allRewardList[_referer] = allRewardList[_referer].add(rewardForBronze);
            allRewardList[_node] = allRewardList[_node].add(rewardForGold);
            taskAmountList[_referer] = taskAmountList[_referer].add(1);
            taskUserSet[_referer].add(_user);
            nodeList[_user] = _node;
            allBronzeUserSet[_node].add(_user);
            emit BindReferer(block.number, block.timestamp, _user, _referer, _node);
            emit getReward(block.number, block.timestamp, _user, _node, rewardForGold, "Team");
            emit getReward(block.number, block.timestamp, _user, _referer, rewardForBronze, "Team");
            if (taskAmountList[_referer] == 2) {
                //推荐人铜卡升银卡
                nodeList[_referer] = address(2);
                BronzeSet.remove(_referer);
                SilverSet.add(_referer);
                allBronzeUserSet[_node].remove(_referer);
                allSilverUserSet[_node].add(_referer);
                if (config.nftToken.ownerOf(tokenIdList[_referer]) == _referer) {
                    config.nftToken.setType(tokenIdList[_referer], cardType.Silver);
                }
                emit BindReferer(block.number, block.timestamp, _referer, refererList[_referer], address(2));
            }
        }
        address _sonAddress = _user;
        for (uint256 k = 0; k < maxInt; k++) {
            address _fatherAddress = refererList[_sonAddress];
            if (_fatherAddress == address(0)) {
                break;
            }
            sonAmountList[_fatherAddress] = sonAmountList[_fatherAddress].add(1);
            //fatherAddressSet[_user].add(_fatherAddress);
            _sonAddress = _fatherAddress;
        }
    }

    function upgradeToGold(uint256 _swapOutAmount) external {
        address _user = msg.sender;
        address _node = nodeList[msg.sender];
        //必须是银卡用户
        require(SilverSet.contains(_user), "f001");
        require(taskAmountList[_user] == 2, "f002");
        if (swapConfig.useAutoSwap) {
            swapConfig.swapInToken.transferFrom(msg.sender, address(this), swapConfig.swapInAmount);
            address[] memory _swapPath = new address[](2);
            _swapPath[0] = address(swapConfig.swapInToken);
            _swapPath[1] = address(swapConfig.swapOutToken);
            uint256 _swapOutMin = _swapOutAmount.sub(_swapOutAmount.mul(swapConfig.slippage).div(100));
            swapConfig.routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapConfig.swapInAmount, _swapOutMin, _swapPath, _user, block.timestamp);
            emit upgradeToGoldE(_swapOutAmount, swapConfig.swapInAmount, _swapOutMin, _swapPath, _user, block.timestamp);
        }
        SilverSet.remove(_user);
        GoldSet.add(_user);
        allSilverUserSet[_node].remove(_user);
        allGoldUserSet[_node].add(_user);
        nodeList[_user] = address(1);
        userNodeIndexList[_user] = NodeNum;
        NodeNum = NodeNum.add(1);
        if (config.nftToken.ownerOf(tokenIdList[_user]) == _user) {
            config.nftToken.setType(tokenIdList[_user], cardType.Gold);
        }
        emit BindReferer(block.number, block.timestamp, _user, refererList[_user], address(1));
    }

    function getSet(uint256 _setType, address _user) external view returns (address[] memory _addressList, uint256[] memory _uint256List, uint256 _num, string  memory _typeName) {
        if (_setType == 0) {
            _typeName = "AllSet";
            _addressList = AllSet.values();
            _num = AllSet.length();
        }
        if (_setType == 1) {
            _typeName = "GoldSet";
            _addressList = GoldSet.values();
            _num = GoldSet.length();
        }
        if (_setType == 2) {
            _typeName = "SilverSet";
            _addressList = SilverSet.values();
            _num = SilverSet.length();
        }
        if (_setType == 3) {
            _typeName = "BronzeSet";
            _addressList = BronzeSet.values();
            _num = BronzeSet.length();
        }
        if (_setType == 4) {
            _typeName = "taskUserSet";
            _addressList = taskUserSet[_user].values();
            _num = taskUserSet[_user].length();
        }
        if (_setType == 5) {
            _typeName = "allGoldUserSet";
            _addressList = allGoldUserSet[_user].values();
            _num = allGoldUserSet[_user].length();
        }
        if (_setType == 6) {
            _typeName = "allSilverUserSet";
            _addressList = allSilverUserSet[_user].values();
            _num = allSilverUserSet[_user].length();
        }
        if (_setType == 7) {
            _typeName = "allBronzeUserSet";
            _addressList = allBronzeUserSet[_user].values();
            _num = allBronzeUserSet[_user].length();
        }
        if (_setType == 8) {
            _typeName = "fatherAddressSet";
            _addressList = fatherAddressSet[_user].values();
            _num = fatherAddressSet[_user].length();
        }
        if (_setType == 9) {
            _typeName = "GoldLastIndexList";
            _uint256List = GoldLastIndexList;
            _num = GoldLastIndexList.length;
        }
        if (_setType == 10) {
            _typeName = "userGetRewardIndexSet";
            _uint256List = userGetRewardIndexSet[_user].values();
            _num = userGetRewardIndexSet[_user].length();
        }
    }

    function getSetByIndexList(uint256 _setType, address _user, uint256[] memory _indexList) external view returns (address[] memory _addressList, uint256[] memory _uint256List, uint256 _num, string  memory _typeName) {
        _num = _indexList.length;
        if (_setType == 9 || _setType == 10) {
            _addressList = new address[](0);
            _uint256List = new uint256[](_num);
        } else {
            _addressList = new address[](_num);
            _uint256List = new uint256[](0);
        }
        if (_setType == 0) {
            _typeName = "AllSet";
            for (uint256 i = 0; i < _num; i++) {
                _addressList[i] = AllSet.at(_indexList[i]);
            }
        }
        if (_setType == 1) {
            _typeName = "GoldSet";
            for (uint256 i = 0; i < _num; i++) {
                _addressList[i] = GoldSet.at(_indexList[i]);
            }
        }
        if (_setType == 2) {
            _typeName = "SilverSet";
            for (uint256 i = 0; i < _num; i++) {
                _addressList[i] = SilverSet.at(_indexList[i]);
            }
        }
        if (_setType == 3) {
            _typeName = "BronzeSet";
            for (uint256 i = 0; i < _num; i++) {
                _addressList[i] = BronzeSet.at(_indexList[i]);
            }

        }
        if (_setType == 4) {
            _typeName = "taskUserSet";
            for (uint256 i = 0; i < _num; i++) {
                _addressList[i] = taskUserSet[_user].at(_indexList[i]);
            }
        }
        if (_setType == 5) {
            _typeName = "allGoldUserSet";
            for (uint256 i = 0; i < _num; i++) {
                _addressList[i] = allGoldUserSet[_user].at(_indexList[i]);
            }
        }
        if (_setType == 6) {
            _typeName = "allSilverUserSet";
            for (uint256 i = 0; i < _num; i++) {
                _addressList[i] = allSilverUserSet[_user].at(_indexList[i]);
            }
        }
        if (_setType == 7) {
            _typeName = "allBronzeUserSet";
            for (uint256 i = 0; i < _num; i++) {
                _addressList[i] = allBronzeUserSet[_user].at(_indexList[i]);
            }
        }
        if (_setType == 8) {
            _typeName = "fatherAddressSet";
            for (uint256 i = 0; i < _num; i++) {
                _addressList[i] = fatherAddressSet[_user].at(_indexList[i]);
            }
        }
        if (_setType == 9) {
            _typeName = "GoldLastIndexList";
            for (uint256 i = 0; i < _num; i++) {
                _uint256List[i] = GoldLastIndexList[_indexList[i]];
            }
        }
        if (_setType == 10) {
            _typeName = "userGetRewardIndexSet";
            for (uint256 i = 0; i < _num; i++) {
                _uint256List[i] = userGetRewardIndexSet[_user].at(_indexList[i]);
            }
        }
    }

    function getUserInfo(address _user, bool _returnList) external view returns (userInfoItem memory _userInfo) {
        _userInfo.config = config;
        _userInfo.isGold = GoldSet.contains(_user);
        _userInfo.isSilver = SilverSet.contains(_user);
        _userInfo.isBronze = BronzeSet.contains(_user);
        _userInfo.canInvite = !SilverSet.contains(_user);
        _userInfo.referer = refererList[_user];
        _userInfo.node = nodeList[_user];
        _userInfo.taskAmount = taskAmountList[_user];
        _userInfo.tokenId = tokenIdList[_user];
        _userInfo.sonAmount = sonAmountList[_user];
        _userInfo.allReward = allRewardList[_user];
        _userInfo.taskAddressList = taskUserSet[_user].values();
        if (_returnList) {
            _userInfo.allGoldUserSet = allGoldUserSet[_user].values();
            _userInfo.allSilverUserSet = allSilverUserSet[_user].values();
            _userInfo.allBronzeUserSet = allBronzeUserSet[_user].values();
            _userInfo.fatherAddressSet = fatherAddressSet[_user].values();
        }
    }

    function getPlatformRewardAmount(address _goldAddress, uint256[] memory _indexList) external view returns (uint256) {
        if (GoldSet.contains(_goldAddress)) {
            uint256 _myIndex = userNodeIndexList[_goldAddress];
            uint256 _rewardAmount;
            for (uint256 i = 0; i < _indexList.length; i++) {
                uint256 _goldNum = GoldLastIndexList[_indexList[i]];
                if (_myIndex < _goldNum && !userGetRewardIndexSet[_goldAddress].contains(_indexList[i])) {
                    _rewardAmount = _rewardAmount.add(config.price.mul(config.shareRate).div(100).div(_goldNum));
                }
            }
            return _rewardAmount;
        } else {
            return 0;
        }
    }

    function takePlatformReward(uint256[] memory _indexList) external {
        address _goldAddress = msg.sender;
        require(GoldSet.contains(_goldAddress), "e001");
        uint256 _myIndex = userNodeIndexList[_goldAddress];
        uint256 _rewardAmount;
        for (uint256 i = 0; i < _indexList.length; i++) {
            uint256 _goldNum = GoldLastIndexList[_indexList[i]];
            if (_myIndex < _goldNum && !userGetRewardIndexSet[_goldAddress].contains(_indexList[i])) {
                _rewardAmount = _rewardAmount.add(config.price.mul(config.shareRate).div(100).div(_goldNum));
                userGetRewardIndexSet[_goldAddress].add(_indexList[i]);
            }
        }
        config.erc20Token.transfer(_goldAddress, _rewardAmount);
        emit getReward(block.number, block.timestamp, address(3), _goldAddress, _rewardAmount, "Platform");
    }
}