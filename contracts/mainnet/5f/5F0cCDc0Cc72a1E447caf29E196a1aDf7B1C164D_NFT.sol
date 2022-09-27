// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";

import "./ERC721.sol";

import "./console.sol";

import "./Ownable.sol";
import "./Strings.sol";


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


contract NFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;


    Counters.Counter private _tokenIds;
    address contractAddress;

    address public token0;
    address public token1;

    uint public gsum = 0;

    struct GroupInfo {
        uint price0;
        uint price1;
        uint start_time;
        uint end_time;
        uint open_time;
        uint goods;
        string uri;
        mapping(uint => string) goodsURIs;
        mapping(uint => uint) goodsStock;
        mapping(uint => uint) goodsNum;
    }

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;
    // token group
    mapping (uint256 => uint256) public _tokenGids;
    // token goods_id
    mapping (uint256 => uint256) public _tokenGoodsIds;

    mapping (uint256 => GroupInfo) public groupinfos;

    event GroupCreated (
        uint indexed groupId,
        uint price0,
        uint price1,
        uint start_time,
        uint end_time,
        uint open_time
    );

    event GroupUpdated (
        uint indexed groupId,
        uint price0,
        uint price1,
        uint start_time,
        uint end_time,
        uint open_time
    );

    constructor(address marketplaceAddress, address _token0, address _token1) ERC721("Cardinal", "Cardinal") {
        contractAddress = marketplaceAddress;
        token0 = _token0;
        token1 = _token1;
    }

    function claimFee(address token, address addr, uint amount) public onlyOwner {
        if(token != address(0)) {
            TransferHelper.safeTransfer(token, addr, amount);
        }else{
            TransferHelper.safeTransferETH(addr, amount);
        }
    }

    function createGroup(string memory _uri, uint _price0, uint _price1, uint _start_time, uint _end_time, uint _open_time) public onlyOwner returns(uint) {
        uint _gid = gsum;
        gsum = gsum + 1;
        GroupInfo storage gi = groupinfos[_gid];
        gi.price0 = _price0;
        gi.price1 = _price1;
        gi.start_time = _start_time;
        gi.end_time = _end_time;
        gi.open_time = _open_time;
        gi.uri = _uri;
        emit GroupCreated(_gid, _price0, _price1, _start_time, _end_time, _open_time);
        return _gid;
    }

    function updateGroup(uint _gid, string memory _uri, uint _price0, uint _price1, uint _start_time, uint _end_time, uint _open_time) public onlyOwner returns(uint) {
        require(_gid < gsum, 'gid error');
        GroupInfo storage gi = groupinfos[_gid];
        gi.price0 = _price0;
        gi.price1 = _price1;
        gi.start_time = _start_time;
        gi.end_time = _end_time;
        gi.open_time = _open_time;
        gi.uri = _uri;
        emit GroupUpdated(_gid, _price0, _price1, _start_time, _end_time, _open_time);
        return _gid;
    }

    function addGoods(uint _gid, string memory _uri, uint _num, uint _stock) public onlyOwner returns (uint) {
        require(_gid < gsum, 'gid error');
        GroupInfo storage gi = groupinfos[_gid];
        uint _id = gi.goods;
        gi.goods = _id + 1;
        gi.goodsURIs[_id] = _uri;
        gi.goodsNum[_id] = _num;
        gi.goodsStock[_id] = _stock;
        return _id;
    }
    
    function updateGoods(uint _gid, uint _id, string memory _uri, uint _num, uint _stock) public onlyOwner {
        require(_gid < gsum, 'gid error');
        GroupInfo storage gi = groupinfos[_gid];
        require(_id < gi.goods, 'goodsid error');
        gi.goodsURIs[_id] = _uri;
        gi.goodsNum[_id] = _num;
        gi.goodsStock[_id] = _stock;
    }

    function getGoodsInfo(uint _gid, uint _id) public view returns (string memory, uint, uint) {
        GroupInfo storage gi = groupinfos[_gid];
        return (gi.goodsURIs[_id], gi.goodsNum[_id], gi.goodsStock[_id]);
    }

    function getGroupStock(uint _gid) public view returns (uint) {
        uint _stock = 0;
        GroupInfo storage gi = groupinfos[_gid];
        for(uint i=0;i < gi.goods; i++) {
            _stock += gi.goodsStock[i];
        }
        return _stock;
    }

    function getGroupSum(uint _gid) public view returns (uint) {
        uint _sum = 0;
        GroupInfo storage gi = groupinfos[_gid];
        for(uint i=0;i < gi.goods; i++) {
            _sum += gi.goodsNum[i];
        }
        return _sum;
    }

    function isOpened(uint _tokenId) public view returns (bool) {
        uint _gid = _tokenGids[_tokenId];
        if(groupinfos[_gid].open_time == 0) {
            return false;
        }
        if(block.timestamp < groupinfos[_gid].open_time) {
            return false;
        }else{
            return true;
        }
    }

    function buyToken(uint _gid) public returns(uint) {
        require(_gid < gsum, 'gid error');
        GroupInfo storage gi = groupinfos[_gid];
        uint _group_stock = getGroupStock(_gid);
        require(_group_stock > 0, "stock empty");
        //时间判断
        require(gi.start_time < block.timestamp && gi.end_time > block.timestamp, 'time error');
        //获取token0
        TransferHelper.safeTransferFrom(token0, msg.sender, address(this), gi.price0);
        //获取token1
        TransferHelper.safeTransferFrom(token1, msg.sender, address(this), gi.price1);

        uint rand_num = getRandom(0, _group_stock);

        uint _goods_id = 0;
        for(uint i=0;i < gi.goods; i++) {
            if(rand_num < gi.goodsStock[i]) {
                _goods_id = i;
                break;
            }else{
                rand_num -= gi.goodsStock[i];
            }
        }
        //商品库存减一
        gi.goodsStock[_goods_id] -= 1;

        //创建nft
        string memory _tokenURI = gi.goodsURIs[_goods_id];


        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _tokenGids[newItemId] = _gid;
        _tokenGoodsIds[newItemId] = _goods_id;

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        setApprovalForAll(contractAddress, true);
        return newItemId;
    }


    function getRandom(uint seed, uint max) private view returns(uint256) {
        uint256 _v = 0;
        _v = psuedoRandomness(seed) % max;
        return _v;
    }

    function psuedoRandomness(uint seed) private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(_msgSender())))) / (block.timestamp)) +
            block.number + seed
        )));
    }


    // function createToken(string memory _tokenURI) public returns (uint) {
    //     _tokenIds.increment();
    //     uint256 newItemId = _tokenIds.current();

    //     _mint(msg.sender, newItemId);
    //     _setTokenURI(newItemId, _tokenURI);
    //     setApprovalForAll(contractAddress, true);
    //     return newItemId;
    // }

    // function createToken(address user, string memory _tokenURI) public returns (uint) {
    //     _tokenIds.increment();
    //     uint256 newItemId = _tokenIds.current();

    //     _mint(user, newItemId);
    //     _setTokenURI(newItemId, _tokenURI);
    //     setApprovalForAll(contractAddress, true);
    //     return newItemId;
    // }

    // function createTokens(address user, string memory _tokenURI, uint256 count) public {
    //     for(uint i=0; i < count; i++) {
    //         _tokenIds.increment();
    //         uint256 newItemId = _tokenIds.current();

    //         _mint(user, newItemId);
    //         _setTokenURI(newItemId, _tokenURI);
    //         setApprovalForAll(contractAddress, true);
    //     }
    // }

    

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        uint _gid = _tokenGids[tokenId];

        if(block.timestamp < groupinfos[_gid].open_time) {
            return groupinfos[_gid].uri;
        }

        uint _goods_id = _tokenGoodsIds[tokenId];

        string memory _tokenURI = groupinfos[_gid].goodsURIs[_goods_id];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}