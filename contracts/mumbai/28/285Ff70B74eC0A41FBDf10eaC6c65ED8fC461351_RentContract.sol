// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "k004");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface TuZiNFT {
     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setUser(uint256 tokenId, address user, uint256 expires) external;

}

contract RentContract is Ownable {
    using SafeMath for uint256;
    TuZiNFT public TuZiNFTAddress;
    uint256 public orderId = 0;
    mapping(address=>uint256) public userTelList;

    struct orderInfo {
        bool _status;
        uint256 _orderId;
        uint256 _tokenId;
        uint256 _startTime;
        uint256 _rentLength;
        uint256 _expires;
        address _token;
        uint256 _zujin;
        uint256 _yajin;
        uint256 _rentAmount;
        address _owner;
        address _user;
    }

    mapping(uint256=>orderInfo) public  orderList;

    function setTuZiNFTAddress(address _TuZiNFTAddress) external onlyOwner {
        TuZiNFTAddress = TuZiNFT(_TuZiNFTAddress);
    }

    function setuserTel(uint256 _tel) external {
        userTelList[msg.sender] = _tel;
    }

    function deposit(uint256 _tokenId,uint256 _rentLength,address _token, uint256 _zujin, uint256 _yajin) external {
        TuZiNFTAddress.safeTransferFrom(msg.sender,address(this),_tokenId);
        orderInfo memory x = (new orderInfo[](1))[0];
        x._orderId = orderId;
        x._status = true;
        x._tokenId = _tokenId;
        x._startTime = block.timestamp;
        x._rentLength = _rentLength;
        x._token = _token;
        x._zujin = _zujin;
        x._yajin = _yajin;
        x._owner = msg.sender;
        orderList[orderId] = x;
        orderId = orderId.add(1);
    }

    function rent(uint256 _orderId) external payable {
        orderInfo storage x = orderList[_orderId];
        require(x._status,"e001");
        TuZiNFTAddress.setUser(x._tokenId, msg.sender, block.timestamp.add(x._rentLength));
        uint256 total = x._zujin.add(x._yajin);
        if (x._token == address(0)) {
           require(msg.value == total,"e001");
        } else {
            IERC20(x._token).transferFrom(msg.sender,address(this),total);
        }
        x._status = false;
        x._user = msg.sender;
        x._expires = block.timestamp.add(x._rentLength);
    }

    function withDraw(uint256 _orderId) external {
       orderInfo storage x = orderList[_orderId];
       require(x._status,"e001");
       require(x._owner == msg.sender,"e001");
       TuZiNFTAddress.safeTransferFrom(address(this), x._owner, x._tokenId);
    }

    function stopRent(uint256 _orderId) external {
        orderInfo storage x = orderList[_orderId];
        require(!x._status,"e001");
        require(x._owner == msg.sender,"e002");
        require(block.timestamp >= x._expires,"e003");
        uint256 _addAmount = x._zujin.mul(block.timestamp.sub(x._expires)).div(x._expires.sub(x._startTime));
        uint256 _leftAmount = 0;
        uint256 _allAmount = x._zujin;
        if (_addAmount>x._yajin) {
               _addAmount = x._yajin;
               _allAmount = _allAmount.add(x._yajin);
               } else {
                   _leftAmount = x._yajin.sub(_addAmount);
                   _allAmount = _allAmount.add(_addAmount);
                   }
        if (x._token == address(0)) {
               payable(msg.sender).transfer(_leftAmount);
               payable(x._owner).transfer(_allAmount);
           } else {
               IERC20(x._token).transfer(msg.sender, _leftAmount);
               IERC20(x._token).transfer(x._owner, _allAmount);
           }
        x._user = address(0);
        x._status = true;
        x._startTime = 0;
        x._expires = 0;
        TuZiNFTAddress.setUser(x._tokenId, address(0), 0);
    }

    function rentBack(uint256 _orderId) external {
        orderInfo storage x = orderList[_orderId];
        require(!x._status,"e001");
        require(x._user == msg.sender,"e002");
        require(block.timestamp >= x._expires,"e003");
        uint256 _addAmount = x._zujin.mul(block.timestamp.sub(x._expires)).div(x._expires.sub(x._startTime));
        uint256 _leftAmount = 0;
        uint256 _allAmount = x._zujin;
        if (_addAmount>x._yajin) {
               _addAmount = x._yajin;
               _allAmount = _allAmount.add(x._yajin);
               } else {
                   _leftAmount = x._yajin.sub(_addAmount);
                   _allAmount = _allAmount.add(_addAmount);
                   }
        if (x._token == address(0)) {
               payable(msg.sender).transfer(_leftAmount);
               payable(x._owner).transfer(_allAmount);
           } else {
               IERC20(x._token).transfer(msg.sender, _leftAmount);
               IERC20(x._token).transfer(x._owner, _allAmount);
           }
        x._user = address(0);
        x._status = true;
        x._startTime = 0;
        x._expires = 0;
        TuZiNFTAddress.setUser(x._tokenId, address(0), 0);
    }
}