pragma solidity ^0.8.4;

import './token/IERC1155.sol';
import './security/Pausable.sol';
import './token/IERC1155TokenReceiver.sol';

contract NFTCoreAuction is Pausable, IERC1155TokenReceiver {
    bytes4 constant MAGIC_ON_ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 constant MAGIC_ON_ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public constant ownerCut = 9475;

    struct Auction {
        // Index of auction
        uint128 id;
        // Contract address
        address nftAddress;
        // Token id
        uint256 tokenId;
        // Current owner of NFT
        address owner;
        // Price (in wei) at beginning of auction
        uint128 price;
        // sell order or buy order : true means sell , false means buy
        bool isSell;
    }
    // All auctions
    Auction[] auctions;
    // Order id
    uint256 orderId = 1;

    // Order id to auctions index
    mapping(uint256 => uint256) idToIndex;
    // Sell auction is exist
    mapping(uint256 => bool) sellIdExist;
    // Buy auction is exist
    mapping(uint256 => bool) buyIdExist;

    // Is NFT contract permitted
    mapping(address => bool) public permission;

    modifier isPermitted(address addr) {
        require(permission[addr], "Contract hasn't permitted");
        _;
    }

    event AuctionCreated(
        uint256 indexed _index,
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        address _owner,
        uint256 _price,
        bool _isSell
    );

    event AuctionCancelled(
        uint256 indexed _index,
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        address _owner,
        bool isSell
    );
    event AuctionSuccessful(
        uint256 indexed _index,
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _totalPrice,
        address _bidder,
        bool isSell
    );

    function setPermission(address addr, bool permitted) external onlySuperAdmin {
        permission[addr] = permitted;
    }

    ///@dev get all exit auctions
    function getAllExistAuctions() external view returns (Auction[] memory) {
        return auctions;
    }

    ///@dev get auction details
    ///@param _orderId order id

    function getAuction(uint256 _orderId) public view returns (Auction memory) {
        require(sellIdExist[_orderId] || buyIdExist[_orderId], 'Not On Auction');
        uint256 _index = idToIndex[_orderId];
        return auctions[_index];
    }

    ///@dev create auction , notice that one just one nft can be placed on auction, even seller have more than one
    ///@param _nftAddress nft contract address
    ///@param _tokenId token id
    ///@param _price the price seller want to sell
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    ) external whenNotPaused isPermitted(_nftAddress) {
        address _seller = msg.sender;
        require(_owns(_nftAddress, msg.sender, _tokenId), 'Not Own The Token');

        Auction memory _auction = Auction(
            uint128(orderId),
            _nftAddress,
            _tokenId,
            _seller,
            uint128(_price),
            true
        );

        _addAuction(_auction, orderId);
        _escrow(_nftAddress, _tokenId, _seller);
        emit AuctionCreated(_auction.id, _auction.nftAddress, _auction.tokenId, _auction.owner, _auction.price, true);
    }

    function bidAuction(uint256 _orderId) external payable whenNotPaused {
        require(sellIdExist[_orderId], 'Order ID Not Exist or Not Sell Order');
        uint256 _index = idToIndex[_orderId];
        Auction memory _auction = auctions[_index];
        require(msg.sender != _auction.owner, 'Bidder and seller should not be the same');

        _bid(_auction, msg.value);
        _transfer(_auction.nftAddress, _auction.tokenId, address(this), msg.sender);
    }

    ///@dev create buy auction, notice that user should send the Matic when call this function
    ///@param _nftAddress nft contract address
    ///@param _tokenId token id
    ///@param _price the price buyer want to buy
    function createBuyAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    ) external payable whenNotPaused isPermitted(_nftAddress) {
        require(_price > 0, 'Price Should Not Be 0 ');
        require(msg.value >= _price, 'Not Enough Money');
        Auction memory _auction = Auction(
            uint128(orderId),
            _nftAddress,
            _tokenId,
            msg.sender,
            uint128(_price),
            false
        );

        _addAuction(_auction, orderId);
        emit AuctionCreated(_auction.id, _auction.nftAddress, _auction.tokenId, _auction.owner, _auction.price, false);
    }

    function bidBuyAuction(uint256 _orderId) external whenNotPaused {
        require(buyIdExist[_orderId], 'Order ID Not Exist or Not Buy Order');

        uint256 _index = idToIndex[_orderId];
        Auction memory _auction = auctions[_index];

        require(_owns(_auction.nftAddress, msg.sender, _auction.tokenId), 'Not Own The Token');
        require(msg.sender != _auction.owner, 'Token seller and buyer should not be the same');

        _bidBuy(_auction);
        _transfer(_auction.nftAddress, _auction.tokenId, msg.sender, _auction.owner);
    }

    function cancelAuction(uint256 _orderId) external whenNotPaused {
        require(sellIdExist[_orderId], 'Order ID Not Exist or Not Sell Order ');
        uint256 _index = idToIndex[_orderId];
        Auction memory _auction = auctions[_index];

        require(msg.sender == _auction.owner);
        _cancelAuction(_auction);
    }

    function cancelBuyAuction(uint256 _orderId) external whenNotPaused {
        require(buyIdExist[_orderId], 'Order ID Not Exist or Not Buy Order ');
        uint256 _index = idToIndex[_orderId];
        Auction memory _auction = auctions[_index];

        require(msg.sender == _auction.owner);
        _cancelBuyAuction(_auction);
    }

    function _owns(
        address _nftAddress,
        address _claimant,
        uint256 _tokenId
    ) private view returns (bool) {
        IERC1155 _nftContract = IERC1155(_nftAddress);
        return (_nftContract.balanceOf(_claimant, _tokenId) >= 1);
    }

    function _addAuction(Auction memory _auction, uint256 _orderId) internal {
        if (_auction.isSell) {
            sellIdExist[_orderId] = true;
        } else {
            buyIdExist[_orderId] = true;
        }
        uint256 indexToAuctions = auctions.length;
        idToIndex[_orderId] = indexToAuctions;

        auctions.push(_auction);
        orderId++;
    }

    function _escrow(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) private {
        IERC1155 _nftContract = IERC1155(_nftAddress);
        _nftContract.safeTransferFrom(_owner, address(this), _tokenId, 1, '0x');
    }

    function _cancelAuction(Auction memory _auction) internal {
        _removeAuction(_auction);
        _transfer(_auction.nftAddress, _auction.tokenId, address(this), _auction.owner);
        emit AuctionCancelled(_auction.id, _auction.nftAddress, _auction.tokenId, _auction.owner, true);
    }

    function _cancelBuyAuction(Auction memory _auction) internal {
        _removeAuction(_auction);
        payable(_auction.owner).transfer(_auction.price);
        emit AuctionCancelled(_auction.id, _auction.nftAddress, _auction.tokenId, _auction.owner, false);
    }

    function _transfer(
        address _nftAddress,
        uint256 _tokenId,
        address _from,
        address _to
    ) internal {
        IERC1155 _nftContract = IERC1155(_nftAddress);
        _nftContract.safeTransferFrom(_from, _to, _tokenId, 1, '0x');
    }

    function _bid(Auction memory _auction, uint256 _bidAmount) internal {
        uint256 _price = _auction.price;
        require(_bidAmount >= _price, 'Bid is lower than the price');

        address payable _seller = payable(_auction.owner);
        _removeAuction(_auction);
        if (_price > 0) {
            uint256 _sellerProceeds = _computeCut(_price);
            _seller.transfer(_sellerProceeds);
        }
        if (_bidAmount > _price) {
            uint256 _bidExcess = _bidAmount - _price;
            payable(msg.sender).transfer(_bidExcess);
        }
        emit AuctionSuccessful(_auction.id, _auction.nftAddress, _auction.tokenId, _price, msg.sender, true);
    }

    function _bidBuy(Auction memory _auction) internal {
        uint256 _price = _auction.price;

        address payable _seller = payable(msg.sender);
        _removeAuction(_auction);
        if (_price > 0) {
            uint256 _sellerProceeds = _computeCut(_price);
            _seller.transfer(_sellerProceeds);
        }

        emit AuctionSuccessful(_auction.id, _auction.nftAddress, _auction.tokenId, _price, msg.sender, false);
    }

    function _computeCut(uint256 _price) internal pure returns (uint256) {
        return (_price * ownerCut) / 10000;
    }

    function _removeAuction(Auction memory _auction) internal {
        if (_auction.isSell) {
            delete sellIdExist[_auction.id];
        } else {
            delete buyIdExist[_auction.id];
        }

        uint256 lastIndex = auctions.length - 1;
        uint256 targetIndex = idToIndex[_auction.id];
        Auction memory lastAuction = auctions[lastIndex];
        // delete in auctions
        auctions[targetIndex] = lastAuction;
        auctions.pop();
        //change idToIndex
        uint256 lastAuctionId = lastAuction.id;
        idToIndex[lastAuctionId] = targetIndex;
        delete idToIndex[_auction.id];
    }

    function cancelAllAuctions(uint256 _number) external onlySuperAdmin whenPaused {
        require(auctions.length >= _number, 'Not Enough Auctions To Cancel');
        for (uint256 i = 0; i < _number; i++) {
            Auction memory _auction = auctions[0];
            if (_auction.isSell) {
                _cancelAuction(_auction);
            } else {
                _cancelBuyAuction(_auction);
            }
        }
    }

    ///@dev if not have this function, contract can't receive ERC1155 token
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override returns (bytes4) {
        return MAGIC_ON_ERC1155_RECEIVED;
    }

    ///@dev if not have this function, contract can't receive ERC1155 token
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override returns (bytes4) {
        return MAGIC_ON_ERC1155_BATCH_RECEIVED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)
import '../utils/IERC165.sol';

pragma solidity ^0.8.0;

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

pragma solidity >=0.8.0 <0.9.0;

import './AccessControl.sol';

contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}

pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}

pragma solidity >=0.8.0 <0.9.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}