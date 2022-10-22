/**
 *Submitted for verification at polygonscan.com on 2022-10-22
*/

// File: token/IERC721TokenReceiver.sol

pragma solidity >=0.8.0 <0.9.0;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}
// File: utils/ISetter.sol

pragma solidity >=0.8.0 <0.9.0;

interface ISetter {

    /// @dev Interface of function setTokenToUsable of ELFCore.
    function setTokenToUsable(uint256 tokenId, address addr) external;
}
// File: utils/IGetter.sol

pragma solidity >=0.8.0 <0.9.0;

interface IGetter {

    /// @dev Interface used by server to check who can use the _tokenId.
    function getUser(address _nftAddress,uint256 _tokenId) external view returns (address);
    
    /// @dev Interface used by server to check who can claim coin B earned by _tokenId.
    function getCoinB(address _nftAddress,uint256 _tokenId) external view returns (address);
}
// File: token/IERC721.sol

pragma solidity >=0.8.0 <0.9.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
// File: security/AccessControl.sol

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
// File: security/Pausable.sol

pragma solidity >=0.8.0 <0.9.0;


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
// File: DecreaseAuction.sol

pragma solidity ^0.8.4;






/// @title Clock auction for non-fungible tokens.
contract DecreaseAuction is Pausable, IGetter, IERC721TokenReceiver {
    /// @dev Value should be returned when we transfer NFT to a contract via safeTransferFrom.
    bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    // Represents an auction on an NFT
    struct Auction {
        // Seller of NFT
        address seller;
        // TokenId
        uint256 id;
        // Price (in wei) at beginning of auction
        uint256 startingPrice;
        // Price (in wei) at end of auction
        uint256 endingPrice;
        // Duration (in seconds) of auction
        uint256 duration;
        // Time when auction started. 0 if this auction has been concluded
        uint256 startedAt;
    }

    Auction[] Auctions;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public constant ownerCut = 9475;

    mapping(uint256 => uint256) idToIndex;
    mapping(uint256 => bool) idExist;

    address public immutable ELFCoreAddress;

    event AuctionCreated(
        address indexed _seller,
        uint256 indexed _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _startAt
    );

    event AuctionSuccessful(
        uint256 indexed _tokenId,
        uint256 _dealPrice,
        address _winner
    );

    event AuctionCanceled(uint256 indexed _tokenId, address canceller);

    modifier validId(uint256 id) {
        require(idExist[id], "token not on sale");
        _;
    }

    constructor(address addr) {
        ELFCoreAddress = addr;
    }

    /// @dev Interface used by server to check who can use the _tokenId.
    function getUser(address _nftAddress, uint256 _tokenId)
        external
        view
        override
        validId(_tokenId)
        returns (address)
    {
        return Auctions[idToIndex[_tokenId]].seller;
    }

    /// @dev Interface used by server to check who can claim coin B earned by _tokenId.
    function getCoinB(address _nftAddress, uint256 _tokenId)
        external
        view
        override
        validId(_tokenId)
        returns (address)
    {
        return Auctions[idToIndex[_tokenId]].seller;
    }

    function getAuctions() external view returns (Auction[] memory) {
        return Auctions;
    }

    /// @dev Returns auction info of an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getOneAuction(uint256 _tokenId)
        external
        view
        validId(_tokenId)
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Auction memory _auction = Auctions[idToIndex[_tokenId]];
        uint256 price = _getCurrentPrice(_auction);
        return (
            _auction.seller,
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            _auction.startedAt,
            price
        );
    }

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    ) external whenNotPaused {
        address _seller = msg.sender;
        require(_owns(_seller, _tokenId), NO_PERMISSION);
        require(_duration <= 2592000, "duration shuold less than 720 hours");
        Auction memory _auction = Auction(
            _seller,
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            block.timestamp
        );
        idToIndex[_tokenId] = Auctions.length;
        idExist[_tokenId] = true;
        Auctions.push(_auction);
        _escrow(_seller, _tokenId);
        emit AuctionCreated(
            _seller,
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            block.timestamp
        );
        ISetter sc = ISetter(ELFCoreAddress);
        sc.setTokenToUsable(_tokenId, msg.sender);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Matic is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
        validId(_tokenId)
    {
        // _bid will throw if the bid or funds transfer fails
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can't
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId)
        external
        validId(_tokenId)
        whenNotPaused
    {
        address seller = Auctions[idToIndex[_tokenId]].seller;
        require(msg.sender == seller, NO_PERMISSION);
        _cancelAuction(_tokenId, seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId)
        external
        whenPaused
        onlyAdmin
        validId(_tokenId)
    {
        _cancelAuction(_tokenId, Auctions[idToIndex[_tokenId]].seller);
    }

    /// @dev Gets the NFT contract instance from an address, validating that implementsERC721 is true.
    function _getNftContract()
        internal
        view
        returns (IERC721 candidateContract)
    {
        candidateContract = IERC721(ELFCoreAddress);
    }

    /// @dev Returns current price of an NFT on auction.
    function _getCurrentPrice(Auction memory _auction)
        internal
        view
        returns (uint256)
    {
        uint256 _secondsPassed = block.timestamp - _auction.startedAt;

        return
            _computeCurrentPrice(
                _auction.startingPrice,
                _auction.endingPrice,
                _auction.duration,
                _secondsPassed
            );
    }

    /// @dev Computes the current price of an auction.
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    ) internal pure returns (uint256) {
        if (_secondsPassed >= _duration || _duration == 0) {
            return _endingPrice;
        }
        uint256 hr_pass = _secondsPassed / 3600;
        uint256 _currentPrice;
        if (_startingPrice >= _endingPrice) {
            uint256 _totalPriceChange = _startingPrice - _endingPrice;
            uint256 _priceChange = (_totalPriceChange * 3600) / _duration;
            _currentPrice = _startingPrice - (hr_pass * _priceChange);
        } else {
            uint256 _totalPriceChange = _endingPrice - _startingPrice;
            uint256 _priceChange = (_totalPriceChange * 3600) / _duration;
            _currentPrice = _startingPrice + (hr_pass * _priceChange);
        }
        return _currentPrice;
    }

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId)
        private
        view
        returns (bool)
    {
        IERC721 _nftContract = _getNftContract();
        return (_nftContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete idExist[_tokenId];
        uint256 index = idToIndex[_tokenId];
        uint256 lastIndex = Auctions.length - 1;
        Auction memory _auction = Auctions[lastIndex];
        Auctions[index] = _auction;
        idToIndex[_auction.id] = index;
        delete idToIndex[_tokenId];
        Auctions.pop();
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCanceled(_tokenId, msg.sender);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId) private {
        IERC721 _nftContract = _getNftContract();
        _nftContract.transferFrom(_owner, address(this), _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        IERC721 _nftContract = _getNftContract();
        _nftContract.transferFrom(address(this), _receiver, _tokenId);
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal pure returns (uint256) {
        return (_price * ownerCut) / 10000;
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bid(uint256 _tokenId, uint256 _bidAmount) internal {
        Auction memory _auction = Auctions[idToIndex[_tokenId]];
        require(msg.sender != _auction.seller, NO_PERMISSION);
        uint256 _price = _getCurrentPrice(_auction);
        require(_bidAmount >= _price, "matic not enough");
        address payable _seller = payable(_auction.seller);
        _removeAuction(_tokenId);
        uint256 _sellerProceeds = _computeCut(_price);
        _seller.transfer(_sellerProceeds);
        if (_bidAmount > _price) {
            uint256 _bidExcess = _bidAmount - _price;
            payable(msg.sender).transfer(_bidExcess);
        }
        emit AuctionSuccessful(_tokenId, _price, msg.sender);
    }

    /// @dev Required for ERC721TokenReceiver compliance.
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external pure override returns (bytes4) {
        return MAGIC_ON_ERC721_RECEIVED;
    }
}