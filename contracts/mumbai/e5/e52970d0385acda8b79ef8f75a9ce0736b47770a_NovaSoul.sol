/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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


library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


library Counters {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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


interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract NovaSoul is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    enum TokenState{NORMAL, SELL, CAST}
    struct TokenInfo {
        uint8 level;               //等级
        TokenState state;          //状态
        uint8 buildTimes;          //铸造次数
        uint256 lastBuildTime;     //最后一次铸造的时间
        uint256 maxEnergy;         //能量值
        uint256 earnRate;          //盈利率  
    }
    struct TokenConfig {
        uint8 level;               //等级
        uint256 blindBoxRate;      //盲盒生成占比
        uint256 minEnergy;         //最小能量
        uint256 maxEnergy;         //最大能量
        uint256 minEarnRate;       //最小盈利率
        uint256 maxEarnRate;       //最大盈利率
    }
    //最高等级
    uint8 constant MAX_TOKEN_LEVEL = 5;
    //最大铸造次数
    uint8 constant MAX_TOKEN_CAST_TIMES = 5;
    //铸造冷却时间
    uint256 constant TOKEN_COOL_CAST_TIME = 60 * 60 * 24 * 5;
    //起始索引
    uint256 constant TOKEN_START_ID = 1000000000;

    //记录索引ID
    Counters.Counter _tokenIdBuilder;
    //勋章外部数据查询地址
    string private _baseTokenURI;
    //升级、铸造需要使用的ERC20代币
    address private _payErc20;
    //铸造一次的价格
    uint256 private _castTokenPrice;
    //升级一次的价格
    uint256 private _upgradeTokenPrice;
    //剩余盲盒数量
    uint256 private _leftBlindBoxCount;
    //盲盒实际售价
    uint256 private _blindBoxPrice;
    //盲盒实际售出数量
    uint256 private _sellBlindBoxCount;
    //勋章的绑定扩展数据
    mapping(uint256 => TokenInfo) private _tokenInfos;
    //勋章配置数据
    mapping(uint8 => TokenConfig) private _tokenConfigs;

    //事件-更新盲盒信息
    event UpdateBlindBoxInfo(uint256 count, uint256 price);
    //事件-购买盲盒
    event BuyBlindBox(address buyer, uint256 tokenId, TokenInfo tokenInfo);
    //事件-铸造勋章
    event CastToken(address owner, uint256 tokenId1, uint256 tokenId2, uint256 tokenId3, uint256 newTokenId, TokenInfo tokenInfo);
    //事件-升级勋章
    event UpgradeToken(address owner, uint256 tokenId, TokenInfo tokenInfo);

    //构造函数
    constructor() ERC721("NovaSoul", "NovaSoul") {
        _tokenIdBuilder._value = TOKEN_START_ID;
        setBaseURI("https://www.google.cn?Id=");
        _payErc20 = 0xE5e28b5fb0623Ef99Ed327126aAb10864F9E7427;
        _castTokenPrice = uint256(10)*(uint256(10)**18);
        _upgradeTokenPrice = uint256(10)*(uint256(10)**18);
        _blindBoxPrice = uint256(10)*(uint256(10)**18);
        _leftBlindBoxCount = 10000;
        _sellBlindBoxCount = 0;
        _initTokenConfig();
    }

    //设置勋章扩展数据查询地址
    function setBaseURI(string memory newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    //获取勋章扩展数据基础地址(重载)
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //获取勋章扩展数据查询地址(重载)
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    //获取勋章的所有信息
    function getTokenInfo(uint256 tokenId) public view returns (TokenInfo memory){
         _requireMinted(tokenId);
        return _tokenInfos[tokenId];
    }

    //设置收款代币
    function setPayErc20(address payAddr) public onlyOwner returns (address) {
        _payErc20 = payAddr;
        return _payErc20;
    }

    //直接创建一个勋章(管理员)
    function buildToken() public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId();
        _safeMint(msg.sender, tokenId);
        _tokenInfos[tokenId] = _initNewTokenInfo();
        return tokenId;
    }

    //更新盲盒售出数量和价格(管理员)
    function updateBlindBoxInfo(uint256 count, uint256 price) public onlyOwner {
        _leftBlindBoxCount = count;
        _blindBoxPrice = price;
        emit UpdateBlindBoxInfo(count, price);
    }

    //购买盲盒
    function buyBlindBox() public returns (uint256) {
        require(_leftBlindBoxCount > 0, "BuyBlindBox: blindBox not enough");
        require(IERC20(_payErc20).allowance(msg.sender, address(this)) >= _blindBoxPrice, "BuyBlindBox: allowance not enough");
        bool success = IERC20(_payErc20).transferFrom(msg.sender, address(this), _blindBoxPrice);
        require(success, "Address: unable to send value, recipient may have reverted");
        uint256 tokenId = _nextTokenId();
        _safeMint(msg.sender, tokenId);
        _tokenInfos[tokenId] = _initNewTokenInfo();
        uint8 level = _getBlindBoxLevel();
        _tokenInfos[tokenId].level = level;
        _tokenInfos[tokenId].maxEnergy = _getEnergy(level);
        _tokenInfos[tokenId].earnRate = _getEarnRate(level);
        _leftBlindBoxCount --;
        _sellBlindBoxCount ++;
        emit BuyBlindBox(_msgSender(), tokenId, _tokenInfos[tokenId]);
        return tokenId;
    }

    //铸造一个新的勋章
    function castToken(uint256 tokenId1, uint256 tokenId2, uint256 tokenId3) public allowCast(tokenId1, tokenId2, tokenId3) returns (uint256) {
        require(IERC20(_payErc20).allowance(msg.sender, address(this)) >= _castTokenPrice, "Cast: allowance not enough");
        bool success = IERC20(_payErc20).transferFrom(msg.sender, address(this), _castTokenPrice);
        require(success, "Address: unable to send value, recipient may have reverted");
        uint256 tokenId = _nextTokenId();
        _safeMint(msg.sender, tokenId);
        _tokenInfos[tokenId] = _initNewTokenInfo();
        _tokenInfos[tokenId].earnRate = _tokenInfos[tokenId1].earnRate + _tokenInfos[tokenId2].earnRate + _tokenInfos[tokenId3].earnRate;
        _tokenInfos[tokenId1].buildTimes++;
        _tokenInfos[tokenId2].buildTimes++;
        _tokenInfos[tokenId3].buildTimes++;
        uint nowTime = block.timestamp;
        _tokenInfos[tokenId1].lastBuildTime = nowTime;
        _tokenInfos[tokenId2].lastBuildTime = nowTime;
        _tokenInfos[tokenId3].lastBuildTime = nowTime;
        emit CastToken(_msgSender(), tokenId1, tokenId2, tokenId3, tokenId, _tokenInfos[tokenId]);
        return tokenId;
    }

    //升级勋章
    function upgradeToken(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        require(_tokenInfos[tokenId].state == TokenState.NORMAL, "ERC721: state not allow upgrade");
        require(_tokenInfos[tokenId].level < MAX_TOKEN_LEVEL, "ERC721: level not allow  upgrade");
        require(IERC20(_payErc20).allowance(msg.sender, address(this)) >= _castTokenPrice, "Upgrade: allowance not enough");
        bool success = IERC20(_payErc20).transferFrom(msg.sender, address(this), _upgradeTokenPrice);
        require(success, "Address: unable to send value, recipient may have reverted");
        _tokenInfos[tokenId].level++;
        _tokenInfos[tokenId].maxEnergy = _getEnergy(_tokenInfos[tokenId].level);
        _tokenInfos[tokenId].earnRate = _getEarnRate(_tokenInfos[tokenId].level);
        emit UpgradeToken(_msgSender(), tokenId, _tokenInfos[tokenId]);
    }
    
    //初始化新勋章的扩展数据
    function _initNewTokenInfo() internal view returns (TokenInfo memory){
        TokenInfo memory tokenInfo;
        tokenInfo.level = 1;
        tokenInfo.buildTimes = 0;
        tokenInfo.lastBuildTime = 0;
        tokenInfo.state = TokenState.NORMAL;
        tokenInfo.maxEnergy = _getEnergy(tokenInfo.level);
        tokenInfo.earnRate = _getEarnRate(tokenInfo.level);
        return tokenInfo;
    }
 
    //获取下一个新勋章的唯一ID
    function _nextTokenId() internal returns (uint256){
        uint256 res = _tokenIdBuilder.current();
        _tokenIdBuilder.increment();
        return res;
    }

    //初始化勋章配置
    function _initTokenConfig() internal {
        TokenConfig memory item1;
        item1.level = 1;
        item1.blindBoxRate = 80;
        item1.minEnergy = 2;
        item1.maxEnergy = 4;
        item1.minEarnRate = 10;
        item1.maxEarnRate = 20;

        TokenConfig memory item2;
        item1.level = 2;
        item1.blindBoxRate = 60;
        item1.minEnergy = 4;
        item1.maxEnergy = 6;
        item1.minEarnRate = 20;
        item1.maxEarnRate = 30;

        TokenConfig memory item3;
        item1.level = 3;
        item1.blindBoxRate = 40;
        item1.minEnergy = 6;
        item1.maxEnergy = 8;
        item1.minEarnRate = 30;
        item1.maxEarnRate = 40;

        TokenConfig memory item4;
        item1.level = 4;
        item1.blindBoxRate = 20;
        item1.minEnergy = 8;
        item1.maxEnergy = 10;
        item1.minEarnRate = 40;
        item1.maxEarnRate = 50; 

        TokenConfig memory item5;
        item1.level = 5;
        item1.blindBoxRate = 10;
        item1.minEnergy = 10;
        item1.maxEnergy = 12;
        item1.minEarnRate = 50;
        item1.maxEarnRate = 60; 

        _tokenConfigs[1] = item1;
        _tokenConfigs[2] = item2;
        _tokenConfigs[3] = item3;
        _tokenConfigs[4] = item4;
        _tokenConfigs[5] = item5;
    }

    //获取指定范围内的随机数
    function randNumFormRange(uint256 startNum, uint256 endNum) public view returns (uint256) {
        require(startNum < endNum, "invalid range");
        uint256 randLen = endNum - startNum;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, _msgSender()))) % (randLen);
        return startNum + randomNumber;
    }

    //获取盲盒勋章的等级
    function _getBlindBoxLevel() internal view returns (uint8){
        uint256 minLv1 = 0;
        uint256 maxLv1 = minLv1 + _tokenConfigs[1].blindBoxRate;

        uint256 minLv2 = maxLv1;
        uint256 maxLv2 = maxLv1 + _tokenConfigs[2].blindBoxRate;

        uint256 minLv3 = maxLv2;
        uint256 maxLv3 = maxLv2 + _tokenConfigs[3].blindBoxRate;

        uint256 minLv4 = maxLv3;
        uint256 maxLv4 = maxLv3 + _tokenConfigs[4].blindBoxRate;

        uint256 minLv5 = maxLv4;
        uint256 maxLv5 = maxLv4 + _tokenConfigs[5].blindBoxRate;

        uint256 totalRate = 0;
        for(uint8 i = 1; i < 6; i++){
            totalRate = totalRate +  _tokenConfigs[i].blindBoxRate;
        }
        uint256 rate = randNumFormRange(0, totalRate);
        if (rate >= minLv5 && rate < maxLv5) {
            return 5;
        } else if (rate >= minLv4 && rate < maxLv4) {
            return 4;
        } else if (rate >= minLv3 && rate < maxLv3) {
            return 3;
        } else if (rate >= minLv2 && rate < maxLv2) {
            return 2;
        } else {
            return 1;
        }
    }

    //根据勋章等级获取能量值
    function _getEnergy(uint8 level) internal view returns (uint256){
        TokenConfig memory cfg = _tokenConfigs[level];
        uint256 res = uint256(randNumFormRange(cfg.minEnergy, cfg.maxEnergy));
        return res;
    }

    //根据勋章等级获取盈利率
    function _getEarnRate(uint8 level) internal view returns (uint256){
        TokenConfig memory cfg = _tokenConfigs[level];
        uint256 res = uint256(randNumFormRange(cfg.minEarnRate, cfg.maxEarnRate));
        return res;
    }

    //提前判定是否允许铸造
    modifier allowCast(uint256 tokenId1, uint256 tokenId2, uint256 tokenId3){
        require(_isApprovedOrOwner(_msgSender(), tokenId1), "ERC721: caller is not token owner nor approved 1");
        require(_isApprovedOrOwner(_msgSender(), tokenId2), "ERC721: caller is not token owner nor approved 2");
        require(_isApprovedOrOwner(_msgSender(), tokenId3), "ERC721: caller is not token owner nor approved 3");
        require(_tokenInfos[tokenId1].state == TokenState.NORMAL, "ERC721: state not allow cast 1");
        require(_tokenInfos[tokenId2].state == TokenState.NORMAL, "ERC721: state not allow cast 2");
        require(_tokenInfos[tokenId3].state == TokenState.NORMAL, "ERC721: state not allow cast 3");
        require(_tokenInfos[tokenId1].buildTimes < MAX_TOKEN_CAST_TIMES, "ERC721: buildTimes not allow cast 1");
        require(_tokenInfos[tokenId2].buildTimes < MAX_TOKEN_CAST_TIMES, "ERC721: buildTimes not allow cast 2");
        require(_tokenInfos[tokenId3].buildTimes < MAX_TOKEN_CAST_TIMES, "ERC721: buildTimes not allow cast 3");
        require(block.timestamp - _tokenInfos[tokenId1].lastBuildTime > TOKEN_COOL_CAST_TIME, "ERC721: lastBuildTime not allow cast 1");
        require(block.timestamp - _tokenInfos[tokenId2].lastBuildTime > TOKEN_COOL_CAST_TIME, "ERC721: lastBuildTime not allow cast 2");
        require(block.timestamp - _tokenInfos[tokenId3].lastBuildTime > TOKEN_COOL_CAST_TIME, "ERC721: lastBuildTime not allow cast 3");
        _;
    }
}