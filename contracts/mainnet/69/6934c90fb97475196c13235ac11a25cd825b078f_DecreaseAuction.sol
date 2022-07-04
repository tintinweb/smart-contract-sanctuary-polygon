/**
 *Submitted for verification at polygonscan.com on 2022-07-04
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
contract DecreaseAuction is Pausable, IGetter, IERC721TokenReceiver{

    /// @dev Value should be returned when we transfer NFT to a contract via safeTransferFrom.
    bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started. 0 if this auction has been concluded
        uint64 startedAt;
    }

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public constant ownerCut=9475;

    // Map from token ID to their corresponding auction.
    mapping (address => mapping (uint256 => Auction)) public auctions;
    // Whether an NFT can be hired in this contract.
    mapping (address => bool) public permission;

    event AuctionCreated(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    );

    event AuctionSuccessful(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _totalPrice,
        address _winner
    );

    event AuctionCancelled(
        address indexed _nftAddress,
        uint256 indexed _tokenId
    );

    modifier isPermitted(address addr){
        require(permission[addr],NO_PERMISSION);
        _;
    }

    function setPermission(address addr,bool permitted) external onlySuperAdmin{
        permission[addr]=permitted;
    }

    /// @dev Interface used by server to check who can use the _tokenId.
    function getUser(address _nftAddress,uint256 _tokenId) external override view returns (address){
        return auctions[_nftAddress][_tokenId].seller;
    }

    /// @dev Interface used by server to check who can claim coin B earned by _tokenId.
    function getCoinB(address _nftAddress,uint256 _tokenId) external override view returns (address){
        return auctions[_nftAddress][_tokenId].seller;
    }

    /// @dev Returns auction info of an NFT on auction.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(
        address _nftAddress,
        uint256 _tokenId
    )
    external
    view
    returns (
        address,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        Auction memory _auction = auctions[_nftAddress][_tokenId];
        require(_isOnAuction(_auction));
        return (
            _auction.seller,
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            _auction.startedAt
        );
    }

    /// @dev Returns the current price of an auction.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(
        address _nftAddress,
        uint256 _tokenId
    )
    external
    view
    returns (uint256)
    {
        Auction memory _auction = auctions[_nftAddress][_tokenId];
        require(_isOnAuction(_auction));
        return _getCurrentPrice(_auction);
    }

    /// @dev Creates and begins a new auction.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )external
    whenNotPaused
    isPermitted(_nftAddress)
    {
        address _seller = msg.sender;
        require(_owns(_nftAddress, _seller, _tokenId));
        require(_duration <= 2592000 ,"duration shuold less than 720 hours");
        Auction memory _auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(block.timestamp)
        );
        _addAuction(_nftAddress, _tokenId, _auction, _seller);
        _escrow(_nftAddress, _seller, _tokenId);
        ISetter sc=ISetter(_nftAddress);
        sc.setTokenToUsable(_tokenId,msg.sender);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _tokenId - ID of token to bid on.
    function bid(
        address _nftAddress,
        uint256 _tokenId
    )
    external
    payable
    whenNotPaused
    isPermitted(_nftAddress)
    {
        Auction memory _auction = auctions[_nftAddress][_tokenId];
        require(msg.sender != _auction.seller);
        // _bid will throw if the bid or funds transfer fails
        _bid(_nftAddress, _tokenId, msg.value);
        _transfer(_nftAddress, msg.sender, _tokenId);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(address _nftAddress, uint256 _tokenId) external whenNotPaused isPermitted(_nftAddress){
        Auction memory _auction = auctions[_nftAddress][_tokenId];
        require(_isOnAuction(_auction));
        require(msg.sender == _auction.seller);
        _cancelAuction(_nftAddress, _tokenId, _auction.seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(
        address _nftAddress,
        uint256 _tokenId
    )
    external
    whenPaused
    onlyAdmin
    {
        Auction storage _auction = auctions[_nftAddress][_tokenId];
        require(_isOnAuction(_auction));
        _cancelAuction(_nftAddress, _tokenId, _auction.seller);
    }

    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _isOnAuction(Auction memory _auction) internal pure returns (bool) {
        return (_auction.startedAt > 0);
    }

    /// @dev Gets the NFT contract instance from an address, validating that implementsERC721 is true.
    /// @param _nftAddress - Address of the NFT contract.
    function _getNftContract(address _nftAddress) internal pure returns (IERC721 candidateContract) {
        candidateContract = IERC721(_nftAddress);
    }

    /// @dev Returns current price of an NFT on auction.
    function _getCurrentPrice(
        Auction memory _auction
    )
    internal
    view
    returns (uint256)
    {
        uint256 _secondsPassed = block.timestamp - _auction.startedAt;

        return _computeCurrentPrice(
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
    )
    internal
    pure
    returns (uint256)
    {
        if (_secondsPassed >= _duration || _duration == 0) {
            return _endingPrice;
        }  
        uint256 hr_pass =  _secondsPassed/3600;
        uint256 _currentPrice;
        if (_startingPrice >= _endingPrice){
            uint256 _totalPriceChange = _startingPrice - _endingPrice;
            uint256 _priceChange = _totalPriceChange*3600/_duration;
            _currentPrice = _startingPrice - (hr_pass * _priceChange);
        }
        else{
            uint256 _totalPriceChange =  _endingPrice-_startingPrice;
            uint256 _priceChange = _totalPriceChange*3600/_duration;
            _currentPrice = _startingPrice + (hr_pass * _priceChange);
        }
        return _currentPrice;
    }

    /// @dev Returns true if the claimant owns the token.
    /// @param _nftAddress - The address of the NFT.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _nftAddress, address _claimant, uint256 _tokenId) private view returns (bool) {
        IERC721 _nftContract = _getNftContract(_nftAddress);
        return (_nftContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(
        address _nftAddress,
        uint256 _tokenId,
        Auction memory _auction,
        address _seller
    ) internal {
        auctions[_nftAddress][_tokenId] = _auction;
        emit AuctionCreated(
            _nftAddress,
            _tokenId,
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration),
            _seller
        );
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(address _nftAddress, uint256 _tokenId) internal {
        delete auctions[_nftAddress][_tokenId];
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(address _nftAddress, uint256 _tokenId, address _seller) internal {
        _removeAuction(_nftAddress, _tokenId);
        _transfer(_nftAddress, _seller, _tokenId);
        emit AuctionCancelled(_nftAddress, _tokenId);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _nftAddress - The address of the NFT.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _nftAddress, address _owner, uint256 _tokenId) private {
        IERC721 _nftContract = _getNftContract(_nftAddress);
        _nftContract.transferFrom(_owner, address(this), _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _nftAddress - The address of the NFT.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _nftAddress, address _receiver, uint256 _tokenId) internal {
        IERC721 _nftContract = _getNftContract(_nftAddress);
        _nftContract.transferFrom(address(this), _receiver, _tokenId);
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal pure returns (uint256) {
        return _price * ownerCut / 10000;
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _bidAmount
    )
    internal
    returns (uint256)
    {
        Auction memory _auction = auctions[_nftAddress][_tokenId];
        require(_isOnAuction(_auction));
        uint256 _price = _getCurrentPrice(_auction);
        require(_bidAmount >= _price);
        address payable _seller = payable(_auction.seller);
        _removeAuction(_nftAddress, _tokenId);
        if (_price > 0) {
            uint256 _sellerProceeds = _computeCut(_price);
            _seller.transfer(_sellerProceeds);
        }
        if (_bidAmount > _price) {
            uint256 _bidExcess = _bidAmount - _price;
            payable(msg.sender).transfer(_bidExcess);
        }
        emit AuctionSuccessful(_nftAddress, _tokenId, _price, msg.sender);
        return _price;
    }
    /// @dev Required for ERC721TokenReceiver compliance.
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) override pure external returns(bytes4){
        return MAGIC_ON_ERC721_RECEIVED;
    }
}