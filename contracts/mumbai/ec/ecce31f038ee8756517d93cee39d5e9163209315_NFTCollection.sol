/**
 *Submitted for verification at polygonscan.com on 2023-02-10
*/

/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns(uint256 balance);
    function ownerOf(uint256 tokenId) external view returns(address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns(address operator);
    function isApprovedForAll(address owner, address operator) external view returns(bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function tokenURI(uint tokenId) external view returns(string memory);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns(bytes4);
}

interface ITracker {
    function callTracker(
        address _nftContractAddr,
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

contract ERC721 is IERC721Metadata, IERC721Receiver, IERC165 {
    error UnsafeTransfer();

    ITracker public immutable tracker;

    address internal owner;
    uint private tokenCount = 1;
    uint private collectionTotalNFT;

    string private collectionName;
    string private collectionSymbol;
    string private collectionDescription;

    // from token_id to token_URI
    mapping(uint => string) private _tokenMetadata;
    // from token_id to token owner
    mapping(uint => address) private _ownerOf;
    // from owner to his/her owned tokens amount
    mapping(address => uint) private _balances;
    // from token_id to approveed operator for it
    mapping(uint => address) private _tokenApprovals;
    // from owner address to approved operator
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _collectionDescription,
        address _owner,
        ITracker _tracker
    ) {
        owner = _owner;
        collectionName = _collectionName;
        collectionSymbol = _collectionSymbol;
        collectionDescription = _collectionDescription;
        tracker = _tracker;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function getOwner() external view returns(address) {
        return owner;
    }

    function getTokenCount() external view returns(uint) {
        return tokenCount;
    }

    function getCollectionTotalNFT() external view returns(uint) {
        return collectionTotalNFT;
    }

    function name() external view returns(string memory) {
        return collectionName;
    }

    function symbol() external view returns(string memory) {
        return collectionSymbol;
    }

    function tokenURI(uint _tokenId) external view returns(string memory) {
        return _tokenMetadata[_tokenId];
    }

    function ownerOf(uint _tokenId) external view returns(address) {
        return _ownerOf[_tokenId];
    }

    function balanceOf(address _target) external view returns(uint) {
        return _balances[_target];
    }

    function description() external view returns(string memory) {
        return collectionDescription;
    }

    function getApproved(uint _tokenId) external view returns(address operator) {
        operator = _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns(bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function supportsInterface(bytes4 interfaceId) external pure returns(bool) {
        return interfaceId == type(IERC721).interfaceId || 
               interfaceId == type(IERC721Metadata).interfaceId;
    }

    function _exists(uint _tokenId) internal view returns(bool) {
        return _ownerOf[_tokenId] != address(0);
    }

    function mint(string calldata _tokenURI) external onlyOwner returns(bool) {
        require(bytes(_tokenURI).length > 0, "Invalid token URI");
        address msgSender = msg.sender;

        collectionTotalNFT += 1;

        _tokenMetadata[tokenCount] = _tokenURI;
        _ownerOf[tokenCount] = msgSender;
        _balances[msgSender] += 1;

        emit Transfer({
            from: address(0),
            to: msgSender,
            tokenId: tokenCount
        });

        tokenCount += 1;

        return true;
    }

    function burn(uint _tokenId) external returns(bool) {
        require(_exists(_tokenId) == true, "Token does not exist");
        address msgSender = msg.sender;
        require(_ownerOf[_tokenId] == msgSender, "You are not the owner");

        collectionTotalNFT -= 1;

        _ownerOf[_tokenId] = address(0);
        _balances[msgSender] -= 1;
        delete _tokenApprovals[_tokenId];
        
        emit Transfer({
            from: msgSender,
            to: address(0),
            tokenId: _tokenId
        });

        return true;
    }

    function transferFrom(address _from, address _to, uint _tokenId) public {
        require(_exists(_tokenId) == true, "Token doesn't exist!");
        address tokenOwner = _ownerOf[_tokenId];
        address msgSender = msg.sender;
        require(
            tokenOwner == msgSender ||
            _tokenApprovals[_tokenId] == msgSender ||
            _operatorApprovals[tokenOwner][msgSender] == true,
            "You cannot access"
        );

        _ownerOf[_tokenId] = _to;

        _balances[tokenOwner] -= 1;
        _balances[_to] += 1;

        delete _tokenApprovals[_tokenId];

        emit Transfer({
            from: _from,
            to: _to,
            tokenId: _tokenId
        });

        tracker.callTracker(address(this), _from, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) external {
        require(_exists(_tokenId) == true, "Token doesn't exist!");
        address tokenOwner = _ownerOf[_tokenId];
        address msgSender = msg.sender;
        require(
            tokenOwner == msgSender ||
            _operatorApprovals[tokenOwner][msgSender] == true,
            "Invalid access"
        );
        require(_to != address(0), "Invalid target address");
        require(_to != tokenOwner, "Cannot approve to current owner");

        _tokenApprovals[_tokenId] = _to;

        emit Approval({
            owner: msgSender,
            approved: _to,
            tokenId: _tokenId
        });
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != address(0), "Invalid operator");
        address msgSender = msg.sender;
        require(msgSender != _operator, "Cannot approveForAll to current owner");

        _operatorApprovals[msgSender][_operator] = _approved;

        emit ApprovalForAll({
            owner: msgSender,
            operator: _operator,
            approved: _approved
        });
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external {
        transferFrom(_from, _to, _tokenId);

        _checkSafity(_from, _to, _tokenId, _data);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        transferFrom(_from, _to, _tokenId);

        _checkSafity(_from, _to, _tokenId, "");
    }

    function _checkSafity(
        address _from,
        address _to,
        uint _tokenId,
        bytes memory _data
    ) private {
        if (_to.code.length > 0) {
            if (
                IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) != 
                IERC721Receiver.onERC721Received.selector
            ) {
                revert UnsafeTransfer();
            }
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract NFTCollection is ERC721 {
    constructor(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _collectionDescription,
        address _owner,
        ITracker _tracker
    ) ERC721(_collectionName, _collectionSymbol, _collectionDescription, _owner, _tracker) {
        //
    }
}

contract Factory {
    event Deployed(address indexed contractAddr, address indexed caller, uint256 indexed time);

    ITracker public tracker;  

    address public immutable owner = msg.sender;

    function deploy(
        string calldata _collectionName,
        string calldata _collectionSymbol,
        string calldata _collectionDescription
    ) external returns(address) {
        NFTCollection nft = new NFTCollection(
            _collectionName,
            _collectionSymbol,
            _collectionDescription,
            tx.origin,
            tracker
        );
        require(address(nft) != address(0), "Somthing went wrong.");

        emit Deployed(address(nft), tx.origin, block.timestamp);

        return address(nft);
    }

    function setTracker(ITracker _tracker) external {
        require(msg.sender == owner, "Only owner");

        tracker = _tracker;
    }
}