/**
 *Submitted for verification at polygonscan.com on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _id) external;
    function mintToken(address _to, uint256 _id, string memory _tokenURI) external;
}

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function mintToken(address to, uint256 _id, uint256 _amount, string memory _tokenURI)  external;
}

contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "you are not the owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract Limited {
	struct LimitedShelves {address token; uint256 nftType; address nftAddress; address seller; uint256 id; uint256 num; uint256 value;}
	mapping(uint256 => LimitedShelves) public lss;
	
	event OnLimitedNft(address indexed _token, address indexed _nftAddress, address indexed _seller, uint256 _nftType, uint256 _id, uint256 _num, uint256 _value);
    event OffLimitedNft(uint256 indexed _id);
    event BuyLimitedNft(uint256 indexed _id);

    function onLimitedNft(address _token, uint256 _nftType, address _nftAddress, uint256 _id, uint256 _num, uint256 _value) external {
        _onLimitedNft(_token, _nftType, _nftAddress, _id, _num, _value);
    }
    function offLimitedNft(uint256 _id) external {
        _offLimitedNft(_id);
    }
    function buyLimitedNft(uint256 _id, uint256 _num) external {
        _buyLimitedNft(_id,_num);
    }
	
	function _onLimitedNft(address _token, uint256 _nftType, address _nftAddress, uint256 _id, uint256 _num, uint256 _value) internal virtual {
        LimitedShelves memory item = lss[_id];
        require(item.num == 0, "_id is exist");
		if (_nftType == 1) {
            IERC721(_nftAddress).transferFrom(msg.sender, address(this), _id);
        } else {
            IERC1155(_nftAddress).safeTransferFrom(msg.sender, address(this), _id , _num, "");
        }
        
        lss[_id] = LimitedShelves(_token, _nftType, _nftAddress, msg.sender, _id, _num, _value);
        emit OnLimitedNft(_token, _nftAddress, msg.sender, _nftType, _id, _num, _value);
    }
    function _offLimitedNft(uint256 _id) internal virtual {
		LimitedShelves memory item = lss[_id];
        if (item.nftType == 1) {
            IERC721(item.nftAddress).transferFrom(address(this), item.seller, _id);
        } else {
            IERC1155(item.nftAddress).safeTransferFrom(address(this), item.seller, _id , item.num, "");
        }
        
		delete lss[_id];
        emit OffLimitedNft(_id);
    }
    function _buyLimitedNft(uint256 _id, uint256 _num) internal virtual {
        LimitedShelves memory item = lss[_id]; 
		require(item.num >= _num, "NFT insufficient quantity");
		uint256 totalPrice = item.value * _num;
        IERC20(item.token).transferFrom(msg.sender, address(this), totalPrice);
        IERC20(item.token).transfer(item.seller, totalPrice);
        if (item.nftType == 1) {
            IERC721(item.nftAddress).transferFrom(address(this), msg.sender, _id);
        } else {
            IERC1155(item.nftAddress).safeTransferFrom(address(this), msg.sender, _id , _num, "");
        }
		lss[_id].num = item.num - _num;
		if (lss[_id].num == 0) {
			delete lss[_id];
        }
        emit BuyLimitedNft(_id);
    }
}

contract Auction {
	struct AuctionShelves {address token; uint256 nftType; address nftAddress; address seller; uint256 id; uint256 num; uint256 value; uint256 endTime;}
    struct Bid {uint256 id; address bidder; uint256 value;}

	mapping(uint256 => AuctionShelves) public ass;
    mapping(uint256 => Bid) public bs;
	
	event OnAuctionNft(address indexed _token, address indexed _nftAddress, address indexed _seller, uint256 _nftType, uint256 _id, uint256 _num, uint256 _value, uint256 _endTime);
    event BuyAuctionNft(uint256 indexed _id, uint256 indexed _amount);
    event Settlement(address indexed _operator, uint256 indexed _id);

    function onAuctionNft(address _token, uint256 _nftType, address _nftAddress, uint256 _id, uint256 _num, uint256 _value, uint256 _endTime) external {
        _onAuctionNft(_token, _nftType, _nftAddress, _id, _num, _value, _endTime);
    }
    function buyAuctionNft(uint256 _id, uint256 amount) external {
        _buyAuctionNft(_id, amount);
    }
    function settlement(uint256 _id) external {
        _settlement(_id);
    }
	
	function _onAuctionNft(address _token, uint256 _nftType, address _nftAddress, uint256 _id, uint256 _num, uint256 _value, uint256 _endTime) internal virtual {
        AuctionShelves memory item = ass[_id];
        require(item.num == 0, "_id is exist");
		if (_nftType == 1) {
            IERC721(_nftAddress).transferFrom(msg.sender, address(this), _id);
        } else {
            IERC1155(_nftAddress).safeTransferFrom(msg.sender, address(this), _id , _num, "");
        }
        
        ass[_id] = AuctionShelves(_token, _nftType, _nftAddress, msg.sender, _id, _num, _value, _endTime);
        emit OnAuctionNft(_token, _nftAddress, msg.sender, _nftType, _id, _num, _value, _endTime);
    }    

    function _buyAuctionNft(uint256 _id, uint256 amount) internal virtual {
        AuctionShelves memory item = ass[_id];
        Bid memory bsItem = bs[_id];
        require(block.timestamp < item.endTime, "The auction is over");
        require(amount > item.value, "This quotation is less than the current quotation");
        IERC20(item.token).transferFrom(msg.sender, address(this), amount);
        if (bsItem.value == 0) {
            bs[_id] = Bid(_id, msg.sender, amount);
        } else {
            bs[_id] = Bid(_id, msg.sender, amount);
            IERC20(item.token).transfer(bsItem.bidder, bsItem.value);
        }
        emit BuyAuctionNft(_id, amount);
    }
    function _settlement(uint256 _id) internal virtual {
        AuctionShelves memory item = ass[_id];
        Bid memory bsItem = bs[_id];
        require(item.endTime < block.timestamp, "The auction is not over yet");
        if (bsItem.value == 0) {
            if (item.nftType == 1) {
                IERC721(item.nftAddress).transferFrom(address(this), item.seller, _id);
            } else {
                IERC1155(item.nftAddress).safeTransferFrom(address(this), item.seller, _id , item.num, "");
            }
        } else {
            if (item.nftType == 1) {
                IERC721(item.nftAddress).transferFrom(address(this), bsItem.bidder, _id);
            } else {
                IERC1155(item.nftAddress).safeTransferFrom(address(this), bsItem.bidder, _id , item.num, "");
            }
            IERC20(item.token).transfer(item.seller, bsItem.value);
        }   
        delete ass[_id];
        delete bs[_id];
        emit Settlement(msg.sender, _id);
    }
}

contract NftRouter is Limited, Auction, Owned, ERC1155Holder {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external auth { wards[guy] = 1; }
    function deny(address guy) external auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

    uint256 public currentTokenId = 1;
    mapping(uint256 => address) public nftAddress;
    mapping(uint256 => uint256) public nftType;

    event Mint721Token(address indexed token, address indexed _to, uint256 indexed id);
    event Mint1155Token(address indexed token, address indexed _to, uint256 indexed id, uint256 num);

    constructor() {
        wards[msg.sender] = 1;
    }

    function setCurrentTokenId(uint256 _id) external auth {
        currentTokenId = _id;   
    }
    
    function new721Nft(address token, address _to, string memory _tokenURI) external {
        _new721Nft(token, _to, _tokenURI);        
    }    

    function new1155Nft(address token, address _to, uint256 _num, string memory _tokenURI) external {
        _new1155Nft(token, _to, _num, _tokenURI);
    }

    function _new721Nft(address token, address _to, string memory _tokenURI) internal virtual {
        require(token != address(0), "New721Nft: 721 contract  to the zero address");
        currentTokenId = currentTokenId + 1;
        uint256 newTokenId = currentTokenId;        
        IERC721(token).mintToken(_to, newTokenId, _tokenURI);

        nftType[newTokenId] = 1;
        nftAddress[newTokenId] = token;
        emit Mint721Token(token, _to, newTokenId);
    }
    function _new1155Nft(address token, address _to, uint256 _num, string memory _tokenURI) internal virtual {
        require(token != address(0), "New1155Nft: 1155 contract  to the zero address");
        currentTokenId = currentTokenId + 1;
        uint256 newTokenId = currentTokenId;        
        IERC1155(token).mintToken(_to, newTokenId, _num, _tokenURI);

        nftType[newTokenId] = 0;
        nftAddress[newTokenId] = token;
        emit Mint1155Token(token, _to, newTokenId, _num);
    }       
}