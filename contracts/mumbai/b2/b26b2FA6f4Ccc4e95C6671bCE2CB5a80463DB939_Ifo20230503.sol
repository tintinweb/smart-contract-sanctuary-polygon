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

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintForMiner(address _to) external returns (bool, uint256);

    function MinerList(address _address) external returns (bool);
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

    receive() payable external {}
}