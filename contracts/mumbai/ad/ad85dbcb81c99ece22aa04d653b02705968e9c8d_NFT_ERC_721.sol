/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0 <0.9.0;

library AddressUtils {
    function isContract(address _address) internal view returns (bool addressCheck){
        bytes32 codeHash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {codeHash := extcodehash(_address)}
        // solhint-disable-line
        addressCheck = (codeHash != 0x0 && codeHash != accountHash);
    }
}

library StringTools {
    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) {return "0";}

        uint temp = value;
        uint digits;

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

    function toString(bool value) internal pure returns (string memory) {
        if (value) {
            return "True";
        } else {
            return "False";
        }
    }

    function toString(address addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(addr);
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint i = 0; i < 20; i++) {
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

            stringBytes[2 * i + 3] = rightChar;
            stringBytes[2 * i + 2] = leftChar;
        }

        return string(stringBytes);
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface ERC165 {
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface ERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function approve(address _approved, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}


contract SupportsInterface is ERC165 {
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true;
    }

    function supportsInterface(bytes4 _interfaceID) external override view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }
}

abstract contract NFTokenMetadata is ERC721Metadata {
    string internal nftName;
    string internal nftSymbol;

    function name() external override view returns (string memory _name) {
        _name = nftName;
    }

    function symbol() external override view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }
}

abstract contract NFToken is ERC721, NFTokenMetadata, SupportsInterface {
    using AddressUtils for address;

    string constant ZERO_ADDRESS = "003001";
    string constant NOT_VALID_NFT = "003002";
    string constant NOT_OWNER_OR_OPERATOR = "003003";
    string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
    string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
    string constant NFT_ALREADY_EXISTS = "003006";
    string constant NOT_OWNER = "003007";
    string constant IS_OWNER = "003008";

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    mapping(uint256 => address) internal idToOwner;
    mapping(uint256 => address) internal idToApproval;
    mapping(address => uint256) private ownerToNFTokenCount;
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
            NOT_OWNER_OR_OPERATOR
        );
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender],
            NOT_OWNER_APPROVED_OR_OPERATOR
        );
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
        _;
    }

    constructor() {
        supportedInterfaces[0x80ac58cd] = true;
    }

    function approve(address _approved, uint256 _tokenId) external override canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner, IS_OWNER);

        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address _owner) external override view returns (uint256) {
        require(_owner != address(0), ZERO_ADDRESS);
        return _getOwnerNFTCount(_owner);
    }

    function ownerOf(uint256 _tokenId) external override view returns (address _owner){
        _owner = idToOwner[_tokenId];
        require(_owner != address(0), NOT_VALID_NFT);
    }

    function getApproved(uint256 _tokenId) external override view validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, NOT_OWNER);
        require(_to != address(0), ZERO_ADDRESS);

        _transferFrom(tokenOwner, _to, _tokenId);
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) private {
        transferFrom(_from, _to, _tokenId);

        if (_to.isContract()) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
        }
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal virtual {
        _clearApproval(_tokenId);

        _removeNFToken(_from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0), ZERO_ADDRESS);
        require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

        _addNFToken(_to, _tokenId);

        emit Transfer(address(0), _to, _tokenId);
    }

    function _burn(uint256 _tokenId) internal virtual validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        _clearApproval(_tokenId);
        _removeNFToken(tokenOwner, _tokenId);
        emit Transfer(tokenOwner, address(0), _tokenId);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal virtual {
        require(idToOwner[_tokenId] == _from, NOT_OWNER);
        ownerToNFTokenCount[_from] -= 1;
        delete idToOwner[_tokenId];
    }

    function _addNFToken(address _to, uint256 _tokenId) internal virtual {
        require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to] += 1;
    }

    function _getOwnerNFTCount(address _owner) internal virtual view returns (uint256){
        return ownerToNFTokenCount[_owner];
    }

    function _clearApproval(uint256 _tokenId) private {
        delete idToApproval[_tokenId];
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract NFT_ERC_721 is NFToken, Ownable {
    using StringTools for *;

    uint256 nextTokenId = 1;
    address public minter;
    string public imageUrl;

    struct PoolIdentifier {
        IERC20 stakeToken;
        IERC20 rewardToken;
        uint256 poolIndex;
    }

    mapping(address => uint256[]) allTokenIdsOfUser;
    mapping(uint256 => uint256) public tokenIdToIndex;
    mapping(uint256 => uint256) public tokenIdToAllIndex;
    mapping(uint256 => PoolIdentifier) public tokenIdToPoolIdentifier;
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => mapping(address => uint256[])))) public poolTypeAndOwnerToTokenId;

    constructor(string memory name, string memory symbol, address _minter, string memory _imageUrl) {
        supportedInterfaces[0x5b5e139f] = true;
        nftName = name;
        nftSymbol = symbol;
        minter = _minter;
        imageUrl = _imageUrl;
    }

    modifier onlyMinter() {
        require(_msgSender() == minter, "Operation can only be performed by the minter.");
        _;
    }

    function addIdToAllIdList(address to, uint256 _tokenId) internal {
        tokenIdToAllIndex[_tokenId] = allTokenIdsOfUser[to].length;
        allTokenIdsOfUser[to].push(_tokenId);
    }

    function delIdFromAllIdList(address from, uint256 _tokenId) internal {
        uint256 length = allTokenIdsOfUser[from].length;
        require(length > 0, "Invalid Length");

        uint256 lastId = allTokenIdsOfUser[from][length - 1];
        uint256 currentIndex = tokenIdToAllIndex[_tokenId];

        allTokenIdsOfUser[from][currentIndex] = allTokenIdsOfUser[from][length - 1];
        tokenIdToAllIndex[lastId] = currentIndex;
        allTokenIdsOfUser[from].pop();

        delete tokenIdToAllIndex[_tokenId];
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal override {
        super._transferFrom(_from, _to, _tokenId);

        PoolIdentifier storage poolIdentifier = tokenIdToPoolIdentifier[_tokenId];
        IERC20 stakeToken = poolIdentifier.stakeToken;
        IERC20 rewardToken = poolIdentifier.rewardToken;
        uint256 poolIndex = poolIdentifier.poolIndex;

        uint256 tokenIndex = tokenIdToIndex[_tokenId];

        uint256 length = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from].length;
        uint256 endingToken = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from][length - 1];

        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from][tokenIndex] = endingToken;
        tokenIdToIndex[endingToken] = tokenIndex;
        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from].pop();

        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_to].push(_tokenId);
        tokenIdToIndex[_tokenId] = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_to].length - 1;

        delIdFromAllIdList(_from, _tokenId);
        addIdToAllIdList(_to, nextTokenId);
    }

    function mint(
        address _to,
        IERC20 stakeToken,
        IERC20 rewardToken,
        uint256 poolIndex
    ) external onlyMinter() returns (uint256 tokenId) {
        _mint(_to, nextTokenId);

        PoolIdentifier storage poolIdentifier = tokenIdToPoolIdentifier[nextTokenId];
        poolIdentifier.stakeToken = stakeToken;
        poolIdentifier.rewardToken = rewardToken;
        poolIdentifier.poolIndex = poolIndex;

        tokenIdToIndex[nextTokenId] = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_to].length;
        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_to].push(nextTokenId);
        addIdToAllIdList(_to, nextTokenId);

        tokenId = nextTokenId;
        nextTokenId += 1;
    }

    function burn(address _from, uint256 _tokenId) external onlyMinter() {
        require(_from == idToOwner[_tokenId], "Invalid _from specified.");
        _burn(_tokenId);

        PoolIdentifier storage poolIdentifier = tokenIdToPoolIdentifier[_tokenId];
        IERC20 stakeToken = poolIdentifier.stakeToken;
        IERC20 rewardToken = poolIdentifier.rewardToken;
        uint256 poolIndex = poolIdentifier.poolIndex;

        uint256 tokenIndex = tokenIdToIndex[_tokenId];
        uint256 length = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from].length;
        uint256 endingToken = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from][length - 1];

        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from][tokenIndex] = endingToken;
        tokenIdToIndex[endingToken] = tokenIndex;
        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from].pop();

        delIdFromAllIdList(_from, _tokenId);
    }

    function setTokenName(string calldata name) external onlyOwner() {
        nftName = name;
    }

    function setTokenSymbol(string calldata symbol) external onlyOwner() {
        nftSymbol = symbol;
    }

    function setImageUrl(string memory _uri) external onlyOwner() {
        imageUrl = _uri;
    }

    function getDetailsOfToken(uint256 _tokenId) internal view returns (string memory, string memory, string memory) {
        PoolIdentifier storage poolIdentifier = tokenIdToPoolIdentifier[_tokenId];

        return (
        address(poolIdentifier.stakeToken).toString(),
        address(poolIdentifier.rewardToken).toString(),
        poolIdentifier.poolIndex.toString()
        );
    }

    function getTokenParameters(uint256 _tokenId) external view validNFToken(_tokenId) returns(IERC20, IERC20, uint256) {
        PoolIdentifier storage poolIdentifier = tokenIdToPoolIdentifier[_tokenId];
        return (poolIdentifier.stakeToken, poolIdentifier.rewardToken, poolIdentifier.poolIndex);
    }

    function tokenURI(uint256 _tokenId) external override view validNFToken(_tokenId) returns (string memory) {
        (string memory a, string memory b, string memory c) = getDetailsOfToken(_tokenId);

        string memory uri = string(abi.encodePacked(
            "{"
                "\"image\": \"", imageUrl, "\", "
                "\"attributes\": ["
                    "{"
                        "\"trait_type\": \"Stake Token\","
                        "\"value\": \"", a, "\""
                    "},"
                    "{"
                        "\"trait_type\": \"Reward Token\","
                        "\"value\": \"", b, "\""
                    "},"
                    "{"
                        "\"trait_type\": \"Pool Index\","
                        "\"value\": \"", c, "\""
                    "}"
                "]"
            "}"
        ));

        return uri;
    }

    function getTokenIdsOfOwner(IERC20 stakeToken, IERC20 rewardToken, uint256 poolIndex, address _owner) external view returns (uint256[] memory) {
        return poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_owner];
    }

    function getAllTokenIdsOfOwner(address _owner) external view returns(uint256[] memory) {
        return allTokenIdsOfUser[_owner];
    }
}