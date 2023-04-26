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

    function minAddPoolAmount() external view returns (uint256);
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

interface IERC721 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

    struct configItem {
        uint256 startBlock;
        uint256 endBlock;
        IERC20 erc20Token;
        IERC20 shareToken;
        IERC721 nftToken;
        uint256 price;
        uint256 bronzeRate;
        uint256 shareRate;
        uint256 allRate;
        address teamAddress;
        bool useShareMode;
    }

    struct userInfoItem {
        configItem config;
        bool isGold;
        bool isSilver;
        bool isBronze;
        bool canInvite;
        address referer;
        address node;
        uint256 taskAmount;
        uint256 tokenId;
        uint256 sonAmount;
        uint256 allReward;
        uint256 allPlatformReward;
        uint256 allGoldNum;
        uint256 allSilverNum;
        uint256 allBronzeNum;
        uint256 idoAmount;
        uint256 shareId;
        address[] taskAddressList;
        address[] allGoldUserSet;
        address[] allSilverUserSet;
        address[] allBronzeUserSet;
        address[] fatherAddressSet;
    }

    struct ShareItem {
        uint256 _nftTotalNumber;
        uint256 _timestamp;
        uint256 _shareAmount; //瓜分的代币
        uint256 _nftPerShare; //每张铜卡可分得的代币
        uint256 _nftTotalPerShare; //每张铜卡累积可分得的代币
    }

interface NFTMarketing {
    function config() external view returns (configItem memory);

    function getSet(uint256, address) external view returns (address[] memory, uint256[] memory, uint256, string memory);

    function getUserInfo(address, bool) external view returns (userInfoItem memory);

    function hasMintedList(address) external view returns (bool); //如果不是买的金卡返回的是true

    function toSilverTimeList(address) external view returns (uint256);
}

contract nftShare20230426 is Ownable, ReentrancyGuard {
    NFTMarketing public NFTMarketingAddress;
    IERC721 public NFT;
    using SafeMath for uint256;
    uint256 public shareId;
    uint256 public minShareAmount;
    uint256 public nftTotalPerShare; //NFT累积瓜分额度
    uint256 public claimedAmount; //已领金额
    uint256 public sharedAmount; //已分金额
    address public shareToken; //瓜分的代币合约
    bool public useShareMode = true;
    mapping(address => bool) public setShareUsersList;
    mapping(uint256 => ShareItem) public shareList;
    mapping(uint256 => uint256) public nftTotalPerShareList;
    mapping(address => uint256) public userClaimedAmount;
    mapping(address => uint256) public lastClaimIndex;
    mapping(address => bool) public outList;

    event ShareEvent(uint256 _shareId, uint256 _nftTotalNumber, uint256 _timestamp, uint256 _shareAmount, uint256 _nftPerShare, uint256 _nftTotalPerShare);

    constructor (bool _useShareMode, uint256 _minShareAmount, NFTMarketing _NFTMarketingAddress, IERC721 _NFT, address _shareToken) {
        useShareMode = _useShareMode;
        minShareAmount = _minShareAmount;
        NFTMarketingAddress = _NFTMarketingAddress;
        NFT = _NFT;
        shareToken = _shareToken;
        setShareUsersList[_shareToken] = true;
        setShareUsersList[msg.sender] = true;
    }

    function setConfig(NFTMarketing _NFTMarketingAddress, IERC721 _NFT, address _shareToken) public onlyOwner {
        NFTMarketingAddress = _NFTMarketingAddress;
        NFT = _NFT;
        shareToken = _shareToken;
    }

    function setUseShareMode(bool _useShareMode, uint256 _minShareAmount) public onlyOwner {
        useShareMode = _useShareMode;
        minShareAmount = _minShareAmount;
    }

    function setSetShareUsersList(address[] memory _usersList, bool _status) public onlyOwner {
        for (uint256 i = 0; i < _usersList.length; i++) {
            setShareUsersList[_usersList[i]] = _status;
        }
    }

    function setShare() public {
        require(setShareUsersList[msg.sender] || msg.sender == owner(), "sk001");
        uint256 _shareAmount = shareId == 0 ? 0 : _getLeftToken();
        uint256 _nftTotalNumber = NFT.totalSupply();
        if (useShareMode && _shareAmount >= minShareAmount) {
            uint256 _nftPerShare = _shareAmount / _nftTotalNumber;
            nftTotalPerShare += _nftPerShare;
            nftTotalPerShareList[shareId] = nftTotalPerShare;
            shareList[shareId] = ShareItem({
            _nftTotalNumber : _nftTotalNumber,
            _timestamp : block.timestamp,
            _shareAmount : _shareAmount,
            _nftPerShare : _nftPerShare,
            _nftTotalPerShare : nftTotalPerShare
            });
            sharedAmount += _shareAmount;
            emit ShareEvent(shareId, _nftTotalNumber, block.timestamp, _shareAmount, _nftPerShare, nftTotalPerShare);
            shareId += 1;
        }
    }

    function claimReward() public nonReentrant {
        address _user = msg.sender;
        require(shareId > 0, "e001");
        require(NFT.balanceOf(_user) > 0, "e002");
        uint256 _rewardAmount = _pendingReward(_user);
        require(_rewardAmount > 0, "e003");
        IERC20(shareToken).transfer(_user, _rewardAmount);
        claimedAmount += _rewardAmount;
        userClaimedAmount[_user] += _rewardAmount;
        lastClaimIndex[_user] = shareId - 1;
    }

    function pendingReward(address _user) public view returns (uint256 _rewardAmount) {
        _rewardAmount = _pendingReward(_user);
    }

    function _pendingReward(address _user) private view returns (uint256) {
        uint256 _rewardAmount;
        if (shareId == 0) {
            return 0;
        }
        userInfoItem memory x = NFTMarketingAddress.getUserInfo(_user, false);
        uint256 isGold = x.isGold ? 1 : 0;
        uint256 isSilver = x.isSilver ? 1 : 0;
        uint256 isBronze = x.isBronze ? 1 : 0;
        bool canClaim = (isGold + isSilver + isBronze) > 0 ? true : false;
        if (!canClaim) {
            return 0;
        }
        uint256 _tokenId = x.tokenId;
        if (_tokenId == 0) {
            return 0;
        }
        uint256 _minShareId = getMinIndex(_user, _tokenId);
        uint256 _maxShareId = shareId - 1;

        _rewardAmount = nftTotalPerShareList[_maxShareId] - nftTotalPerShareList[_minShareId];
        return _rewardAmount;
    }

    function getMinIndex(address _user, uint256 tokenId) private view returns (uint256) {
        uint256 _minShareId;
        if (lastClaimIndex[_user] > 0) {
            return lastClaimIndex[_user];
        }
        for (uint256 i = 0; i < shareId; i++) {
            ShareItem memory x = shareList[i];
            if (x._nftTotalNumber >= tokenId) {
                _minShareId = i == 0 ? 0 : i - 1;
                break;
            }
        }
        return _minShareId;
    }

    function _getLeftToken() private view returns (uint256) {
        if (IERC20(shareToken).balanceOf(address(this)).add(claimedAmount) > sharedAmount) {
            return IERC20(shareToken).balanceOf(address(this)).add(claimedAmount).sub(sharedAmount);
        } else {
            return 0;
        }
    }

    function getLeftToken() private view returns (uint256) {
        return _getLeftToken();
    }
}