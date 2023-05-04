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

interface IERC721Enumerable {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address) external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256) external view returns (string memory);

    function mintForMiner(address) external returns (bool, uint256);

    function MinerList(address) external returns (bool);

    function tokenOfOwnerByIndex(address, uint256) external view returns (uint256);
}

contract Ifo20230503 is Ownable {
    uint256 public totalAmount = 50000;
    uint256 public mintedAmount;
    uint256 public maxAmountPerUser;
    address public devAddress;
    address public nftToken;
    mapping(address => userItem) public userInfoList;
    FreeItem public FreeConfig;
    IfoItem public IfoConfig;

    struct returnItem {
        uint256 totalAmount;
        uint256 mintedAmount;
        uint256 maxAmountPerUser;
        address devAddress;
        address nftToken;
        FreeItem FreeConfig;
        IfoItem IfoConfig;
        userItem userInfo;
        uint256[] idList;
    }

    struct userItem {
        uint256 freeAmount;
        uint256 ifoAmount;
        uint256 totalAmount;
    }

    struct FreeItem {
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmount;
        uint256 mintedAmount;
        uint256 maxAmountPerUser;
    }

    struct IfoItem {
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmount;
        uint256 mintedAmount;
        uint256 maxAmountPerUser;
    }

    function setNftToken(address _nftToken) external onlyOwner {
        nftToken = _nftToken;
    }

    function setConfig(uint256 _totalAmount, uint256 _maxAmountPerUser, address _devAddress) external onlyOwner {
        totalAmount = _totalAmount;
        maxAmountPerUser = _maxAmountPerUser;
        devAddress = _devAddress;
    }

    function setFreeConfig(
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _totalAmount,
        uint256 _maxAmountPerUser) external onlyOwner {
        FreeConfig.price = _price;
        FreeConfig.startTime = _startTime;
        FreeConfig.endTime = _endTime;
        FreeConfig.totalAmount = _totalAmount;
        FreeConfig.maxAmountPerUser = _maxAmountPerUser;
    }

    function setIfoConfig(
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _totalAmount,
        uint256 _maxAmountPerUser) external onlyOwner {
        IfoConfig.price = _price;
        IfoConfig.startTime = _startTime;
        IfoConfig.endTime = _endTime;
        IfoConfig.totalAmount = _totalAmount;
        IfoConfig.maxAmountPerUser = _maxAmountPerUser;
    }

    function freeMint(uint56 _amount) external {
        address _user = msg.sender;
        uint256 _timestamp = block.timestamp;
        require(_timestamp >= FreeConfig.startTime, "e001");
        require(_timestamp <= FreeConfig.endTime, "e002");
        FreeConfig.mintedAmount += _amount;
        mintedAmount += _amount;
        userInfoList[_user].freeAmount += _amount;
        userInfoList[_user].totalAmount += _amount;
        require(FreeConfig.mintedAmount <= FreeConfig.totalAmount, "e003");
        require(mintedAmount <= totalAmount, "e004");
        require(userInfoList[_user].freeAmount <= FreeConfig.maxAmountPerUser, "e005");
        require(userInfoList[_user].totalAmount <= maxAmountPerUser, "e006");
        for (uint256 i = 0; i < _amount; i++) {
            (bool _status, uint256 _tokenId) = IERC721Enumerable(nftToken).mintForMiner(_user);
            require(_status && _tokenId > 0, "e007");
        }
    }

    function ifoMint(uint56 _amount) external payable {
        address _user = msg.sender;
        uint256 _timestamp = block.timestamp;
        require(msg.value == _amount * IfoConfig.price, "e00");
        require(devAddress != address(0));
        require(nftToken != address(0));
        require(_timestamp >= IfoConfig.startTime, "e001");
        require(_timestamp <= IfoConfig.endTime, "e002");
        IfoConfig.mintedAmount += _amount;
        mintedAmount += _amount;
        userInfoList[_user].ifoAmount += _amount;
        userInfoList[_user].totalAmount += _amount;
        require(IfoConfig.mintedAmount <= IfoConfig.totalAmount, "e003");
        require(mintedAmount <= totalAmount, "e004");
        require(userInfoList[_user].ifoAmount <= IfoConfig.maxAmountPerUser, "e005");
        require(userInfoList[_user].totalAmount <= maxAmountPerUser, "e006");
        for (uint256 i = 0; i < _amount; i++) {
            (bool _status, uint256 _tokenId) = IERC721Enumerable(nftToken).mintForMiner(_user);
            require(_status && _tokenId > 0, "e007");
        }
        payable(devAddress).transfer(_amount * IfoConfig.price);
    }

    function getUserData(address _user) external view returns (returnItem memory returnItem_) {
        returnItem_.totalAmount = totalAmount;
        returnItem_.mintedAmount = mintedAmount;
        returnItem_.maxAmountPerUser = maxAmountPerUser;
        returnItem_.devAddress = devAddress;
        returnItem_.nftToken = nftToken;
        returnItem_.FreeConfig = FreeConfig;
        returnItem_.IfoConfig = IfoConfig;
        returnItem_.userInfo = userInfoList[_user];
        uint256 _num = IERC721Enumerable(nftToken).balanceOf(_user);
        uint256[] memory _idList = new uint256[](_num);
        for (uint256 i = 0; i < _num; i++) {
            _idList[i] = IERC721Enumerable(nftToken).tokenOfOwnerByIndex(_user, i);
        }
        returnItem_.idList = _idList;
    }

    receive() payable external {}
}