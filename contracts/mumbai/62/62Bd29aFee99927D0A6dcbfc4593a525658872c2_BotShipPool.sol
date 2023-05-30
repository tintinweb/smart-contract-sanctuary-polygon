// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../ITokenPaymentSplitter.sol";
import "../Managable.sol";
import "./LibLazyPoolRemove.sol";


contract BotShipPool is Managable, Pausable, ReentrancyGuard, ERC721Holder {

    using ECDSA for bytes32;

    event ItemAddedToPool(address indexed _nft, uint256 indexed _tokenId, address payToken, uint256 price);
    event ItemUpdated(address indexed _nft, uint256 indexed _tokenId, address payToken, uint256 price);
    event ItemRemovedFromPool(address indexed _nft, uint256 indexed _tokenId);
    event ItemSold(address indexed nft, address indexed buyer, uint256 tokenId, address payToken, uint256 price);
    event ChangedTreasuryAddress(address treasuryAddress);
    event BotAddressChanged(address _addr);
    event ShipAddressChanged(address _addr);
    event SignerAddressChanged(address _addr);
    event EmergencyWithdrawToken(address token, address to, uint quantity);
    event EmergencyWithdrawNFT(address nft, address to, uint tokenID);
    event TeamSold(address indexed _nft, address indexed _buyer, uint256[3] _tokenId);
    event AddedWhitelistedAddress(address _addr);
    event RemovedWhitelistedAddress(address _addr);

    struct Listing {
        address payToken;
        uint256 price;
        uint256 internalIndex;
    }

    struct ExtendedListing {
        uint256 tokenId;
        address payToken;
        uint256 price;
    }


    address public treasuryAddress;
    address public botAddress;
    address public shipAddress;
    address private signerAddress;
    bytes32 private domainSeparator;
    address public constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address public immutable BITS_ADDRESS;
    
    /// @notice tokenId -> Array of Listing items
    mapping(uint256 => Listing) pooledBots;
    mapping(uint256 => Listing) pooledShips;
    mapping(address => bool) public whitelistedBuyers;

    uint256[] pooledBotIds;
    uint256[] pooledShipIds;

    /// @notice Contract initializer
    constructor (
        address _treasuryAddress, 
        address _botAddress,
        address _shipAddress,
        address _signerAddress,
        address _bitAddress,
        string memory _appName,
        string memory _version              
    ) {
        domainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(_appName)),
            keccak256(bytes(_version)),
            block.chainid,
            address(this)
        ));    

        _setTreasuryAddress(_treasuryAddress);
        _setSignerAddress(_signerAddress);
        _setBotAddresss(_botAddress);
        _setShipAddress(_shipAddress);
        BITS_ADDRESS = _bitAddress;
        _addManager(msg.sender);
    }

    /// @notice Method for adding NFT to pool
    /// @param _nftAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    /// @param _payToken Paying token
    /// @param _price sale price
    function addItem(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price
    ) external whenNotPaused onlyManager {

        address _botAddress = botAddress;
        require(_nftAddress == _botAddress || _nftAddress == shipAddress, "nft not allowed");
        require(_payToken == BITS_ADDRESS || _payToken == ZERO_ADDRESS, "pay token not allowed");

        _addItem(_nftAddress, _tokenId, _payToken, _price);
        
    }

    /// @notice Method for mass adding NFTs to pool
    /// @param _nftAddress Address of NFT contract
    /// @param _payToken Paying token
    /// @param _tokenId[] Token IDs of NFT
    /// @param _price[] sale prices
    function addManyItems(
        address _nftAddress,
        address _payToken,
        uint256[] calldata _tokenId,
        uint256[] calldata _price
    ) external whenNotPaused onlyManager {

        address _botAddress = botAddress;
        require(_tokenId.length == _price.length, "incorrect item data");
        require(_nftAddress == _botAddress || _nftAddress == shipAddress, "nft not allowed");
        require(_payToken == BITS_ADDRESS || _payToken == ZERO_ADDRESS, "pay token not allowed");

        for (uint i = 0; i < _tokenId.length; i++){
            _addItem(_nftAddress, _tokenId[i], _payToken, _price[i]);
        }   
    }

    /// @notice Method for removing item from pool
    /// @param _nftAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    function removeItem(
        address _nftAddress, 
        uint256 _tokenId 
    ) external whenNotPaused onlyManager {
        
        _removeItem(_nftAddress, _tokenId);
        IERC721(_nftAddress).safeTransferFrom(address(this), _msgSender(), _tokenId);

        emit ItemRemovedFromPool(_nftAddress, _tokenId);
    }

    /// @notice Method for mass removing items from pool
    /// @param _nftAddress Address of NFT contract
    /// @param _tokenId[] Token IDs of NFT
    function removeManyItems(
        address _nftAddress,
        uint256[] calldata _tokenId
    ) external whenNotPaused onlyManager {

        for (uint i = 0; i < _tokenId.length; i++){
            _removeItem(_nftAddress, _tokenId[i]);
            IERC721(_nftAddress).safeTransferFrom(address(this), _msgSender(), _tokenId[i]);

            emit ItemRemovedFromPool(_nftAddress, _tokenId[i]);
        }
    }

    /// @notice Method for updating NFT in pool
    /// @param _nftAddress Address of NFT contract
    /// @param _newPayToken payment token
    /// @param _tokenId Token ID of NFT
    /// @param _newPrice New sale price for iteam
    function updateItem(
        address _nftAddress,
        uint256 _tokenId,
        address _newPayToken,
        uint256 _newPrice
    ) external whenNotPaused onlyManager {

        address _botAddress = botAddress;

        require(_nftAddress == _botAddress || _nftAddress == shipAddress, "nft not allowed");
        require(_newPayToken == BITS_ADDRESS || _newPayToken == ZERO_ADDRESS, "pay token not allowed");

        _updateItem(_nftAddress, _newPayToken, _tokenId, _newPrice);
    }

    /// @notice Method for mass updating NFTs in pool
    /// @param _nftAddress Address of NFT contract
    /// @param _newPayToken payment token
    /// @param _tokenId[] Token IDs of NFT
    /// @param _newPrice[] New sale prices for each iteam
    function updateManyItems(
        address _nftAddress,
        address _newPayToken,
        uint256[] calldata _tokenId,
        uint256[] calldata _newPrice
    ) external whenNotPaused onlyManager {

        address _botAddress = botAddress;

        require(_tokenId.length == _newPrice.length, "incorrect item data");
        require(_nftAddress == _botAddress || _nftAddress == shipAddress, "nft not allowed");
        require(_newPayToken == BITS_ADDRESS || _newPayToken == ZERO_ADDRESS, "pay token not allowed");

        for (uint i = 0; i < _tokenId.length; i++){
            _updateItem(_nftAddress, _newPayToken, _tokenId[i], _newPrice[i]);
        }
    }


    /// @notice Method for buying pooled NFT
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _payToken payment token
    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        LibLazyPoolRemove.Remove calldata _remove,
        bytes calldata _signature        
    ) external payable nonReentrant whenNotPaused {

        require(_remove.deadline >= block.timestamp, "expired");
        require(_remove.id == _tokenId, "invalid token Id");
        require(_remove.nft == _nftAddress, "invalid nft Address");
        if(whitelistedBuyers[msg.sender] != true){
            require(_remove.buyer == msg.sender, "invalid buyer");
        }    

        require(verifyTypedDataHash(domainSeparator, _remove, _signature, signerAddress), "bad sig");

        Listing memory _listing = _removeItem(_nftAddress, _tokenId);
        require(_listing.payToken == _payToken, "invalid pay token");

        _buyItem(_listing, _nftAddress, _tokenId, _remove.buyer);
    }

    /// @notice Method for buying pooled NFT
    /// @param _nftAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _payToken payment token
    function buyTeam(
        address _nftAddress,
        address[3] calldata _payToken,
        uint256[3] calldata _tokenId,
        LibLazyPoolRemove.BuyTeam calldata _buyTeam,
        bytes calldata _signature
    ) external payable nonReentrant whenNotPaused {

        require(_buyTeam.deadline >= block.timestamp, "expired");
        require(_buyTeam.nft == _nftAddress, "invalid nft Address");
        if(whitelistedBuyers[msg.sender] != true){
            require(_buyTeam.buyer == msg.sender, "invalid buyer");
        }
        require(_buyTeam.id[0] == _tokenId[0], "invalid token Id 1");
        require(_buyTeam.id[1] == _tokenId[1], "invalid token Id 2");
        require(_buyTeam.id[2] == _tokenId[2], "invalid token Id 3");

        require(verifyTypedDataHashTwo(domainSeparator, _buyTeam, _signature, signerAddress), "bad sig");

        uint[3] memory _price;
        for(uint i = 0; i < 3; i++){
            Listing memory _listing = _removeItem(_nftAddress, _tokenId[i]);
            require(_listing.payToken == _payToken[i], "invalid pay token");
            _price[i] = _listing.price;
            require(_price[i] > 0, "price is zero");
        }

        _buyTheTeam(_buyTeam.buyer, _nftAddress, _payToken, _price, _tokenId);

    }

    function getBotsInPool() public view returns(ExtendedListing[] memory) {

        ExtendedListing[] memory _allBots = new ExtendedListing[](pooledBotIds.length);

        for (uint i = 0; i < pooledBotIds.length; i++){
            ExtendedListing memory _listing;
            _listing.tokenId = pooledBotIds[i];
            _listing.payToken = pooledBots[pooledBotIds[i]].payToken;
            _listing.price = pooledBots[pooledBotIds[i]].price;
            _allBots[i] = _listing;
        }
        return _allBots;
    }

    function getShipsInPool() public view returns(ExtendedListing[] memory) {

        ExtendedListing[] memory _allShips = new ExtendedListing[](pooledShipIds.length);

        for (uint i = 0; i < pooledShipIds.length; i++){
            ExtendedListing memory _listing;
            _listing.tokenId = pooledShipIds[i];
            _listing.payToken = pooledShips[pooledShipIds[i]].payToken;
            _listing.price = pooledShips[pooledShipIds[i]].price;
            _allShips[i] = _listing;
        }
        return _allShips;
    }

    function getBotPrice(uint _tokenId) public view returns(uint _price) {
        _price = pooledBots[_tokenId].price;
    }

    function getShipPrice(uint _tokenId) public view returns(uint _price) {
        _price = pooledShips[_tokenId].price;
    }

    function setTreasuryAddress(address _addr) external onlyManager {
        _setTreasuryAddress(_addr);
    }   

    function setBotAddress(address _addr) external onlyManager {
        _setBotAddresss(_addr);
    }

    function setSignerAddress(address _addr) external onlyManager {
        _setSignerAddress(_addr);
    }

    function setShipAddress(address _addr) external onlyManager {
        _setShipAddress(_addr);
    }

    function addWhitelistedAddress(address _addr) external onlyManager {
        _addWhitelistedAddress(_addr);
    }

    function removeWhitelistedAddress(address _addr) external onlyManager {
        _removeWhitelistedAddress(_addr);
    }

    function emergencyTokenWithdraw (address payable _to, address _token) external onlyManager {
        if(_token != ZERO_ADDRESS) {
            uint balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(_to, balance);
            emit EmergencyWithdrawToken(_token, _to, balance);
        } else {
            uint _balance = address(this).balance;
            _to.transfer(_balance);            
            emit EmergencyWithdrawToken(_token, _to, _balance);
        }
    }

    function emergencyNFTWithdraw (address _to, address _nftAddress, uint _tokenID) external onlyManager {
        IERC721(_nftAddress).safeTransferFrom(address(this), _to, _tokenID);
        emit EmergencyWithdrawNFT(_nftAddress, _to, _tokenID);
    }

    function _addItem(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price
    ) private {

        address _botAddress = botAddress;

        require(_price > 0, "price is zero");

        Listing memory _listing = Listing({
            payToken: _payToken,
            price: _price,
            internalIndex: 0
        });

        if(_nftAddress == _botAddress){
            Listing memory _existingListing = pooledBots[_tokenId];
            require(_existingListing.price == 0, "already added");
            pooledBotIds.push(_tokenId);
            _listing.internalIndex = pooledBotIds.length-1;
            pooledBots[_tokenId] = _listing;
        } else {
            Listing memory _existingListing = pooledShips[_tokenId];
            require(_existingListing.price == 0, "already added");
            pooledShipIds.push(_tokenId);
            _listing.internalIndex = pooledShipIds.length-1;
            pooledShips[_tokenId] = _listing;
        }

        IERC721 nft = IERC721(_nftAddress);
        require(nft.ownerOf(_tokenId) == _msgSender(), "not owning item");
        nft.safeTransferFrom(_msgSender(), address(this), _tokenId);

        emit ItemAddedToPool(
            _nftAddress,
            _tokenId,
            _payToken,
            _price
        );
    }

    function _updateItem(
        address _nftAddress,
        address _newPayToken,
        uint256 _tokenId,
        uint256 _newPrice
    ) private {

        address _botAddress = botAddress;

        require(_newPrice > 0, "price is zero");

        Listing memory _existingListing;

        if(_nftAddress == _botAddress){
            _existingListing = pooledBots[_tokenId];
            require(_existingListing.price > 0, "not added");

            _existingListing.payToken = _newPayToken;
            _existingListing.price = _newPrice;

            pooledBots[_tokenId] = _existingListing;

        } else {
            _existingListing = pooledShips[_tokenId];
            require(_existingListing.price > 0, "not added");

            _existingListing.payToken = _newPayToken;
            _existingListing.price = _newPrice;

            pooledShips[_tokenId] = _existingListing;
        }

        emit ItemUpdated(
            _nftAddress,
            _tokenId,
            _newPayToken,
            _newPrice
        );
    }

    function _removeItem(
        address _nftAddress, 
        uint256 _tokenId 
    ) private returns (Listing memory) {

        Listing memory _existingListing;

        if(_nftAddress == botAddress){
            uint _idLength = pooledBotIds.length;

            _existingListing = pooledBots[_tokenId];
            require(_existingListing.price > 0, "not added");

            delete(pooledBots[_tokenId]);

            if(_existingListing.internalIndex != (_idLength - 1)){
                pooledBotIds[_existingListing.internalIndex] = pooledBotIds[_idLength - 1];
                pooledBotIds.pop();
                pooledBots[pooledBotIds[_existingListing.internalIndex]].internalIndex = _existingListing.internalIndex;
            } else {
                pooledBotIds.pop();
            }
        } else {
            uint _idLength = pooledShipIds.length;
 
            _existingListing = pooledShips[_tokenId];
            require(_existingListing.price > 0, "not added");

            delete(pooledShips[_tokenId]);

            if(_existingListing.internalIndex != (_idLength - 1)){
                pooledShipIds[_existingListing.internalIndex] = pooledShipIds[_idLength - 1];
                pooledShipIds.pop();
                pooledShips[pooledShipIds[_existingListing.internalIndex]].internalIndex = _existingListing.internalIndex;
            }  else {
                pooledShipIds.pop();
            }
        }
        return _existingListing;
    }

    function _buyItem(Listing memory _listing, address _nftAddress, uint _tokenId, address _buyer) private {
       
       if(_listing.payToken == BITS_ADDRESS){
            require(IERC20(BITS_ADDRESS).transferFrom(_msgSender(), address(this), _listing.price));
            IERC20(BITS_ADDRESS).approve(treasuryAddress, _listing.price);
            ITokenPaymentSplitter(treasuryAddress).split(BITS_ADDRESS, _buyer, _listing.price);
       } else {
            require(msg.value == _listing.price, "not enough native token");
            (bool success,) = treasuryAddress.call{value: msg.value}(
                abi.encodeWithSignature("split(address,address,uint256)", ZERO_ADDRESS, _buyer, _listing.price)
            );
            require(success, "Splitter call fail");
       }
        
        // Transfer NFT to buyer
        IERC721(_nftAddress).safeTransferFrom(
            address(this),
            _buyer,
            _tokenId
        );

        emit ItemSold(
            _nftAddress,
            _buyer,
            _tokenId,
            _listing.payToken,
            _listing.price
        );
    }

    function _buyTheTeam(address _buyer, address _nftAddress, address[3] memory _payToken, uint256[3] memory _price, uint[3] memory _tokenId) private {
       uint _bitsPrice;
       uint _maticPrice;

       for (uint i = 0; i < 3; i++){
            if(_payToken[i] == BITS_ADDRESS){
                _bitsPrice += _price[i];
            } else {
                _maticPrice += _price[i];
            }
       }

       require(_bitsPrice > 0 || _maticPrice > 0, "Price error");

       if(_bitsPrice > 0){
            require(IERC20(BITS_ADDRESS).transferFrom(_msgSender(), address(this), _bitsPrice));
            IERC20(BITS_ADDRESS).approve(treasuryAddress, _bitsPrice);
            ITokenPaymentSplitter(treasuryAddress).split(BITS_ADDRESS, _buyer, _bitsPrice);
       }
       
       if(_maticPrice > 0){
            require(msg.value == _maticPrice, "not enough native token");
            (bool success,) = treasuryAddress.call{value: msg.value}(
                abi.encodeWithSignature("split(address,address,uint256)", ZERO_ADDRESS, _buyer, _maticPrice)
            );
            require(success, "Splitter call fail");
       } 
        
        for (uint i = 0; i < 3; i++){
            // Transfer NFT to buyer
            IERC721(_nftAddress).safeTransferFrom(
                address(this),
                _buyer,
                _tokenId[i]
            );

            emit ItemSold(
                _nftAddress,
                _buyer,
                _tokenId[i],
                _payToken[i],
                _price[i]
            );
        }

        emit TeamSold(_nftAddress, _buyer, _tokenId);
    }

    function _addWhitelistedAddress(address _addr) internal {
        whitelistedBuyers[_addr] = true;
        emit AddedWhitelistedAddress(_addr);
    }   

    function _removeWhitelistedAddress(address _addr) internal {
        whitelistedBuyers[_addr] = false;
        emit RemovedWhitelistedAddress(_addr);
    }   

    function _setTreasuryAddress(address _addr) internal {
        treasuryAddress = _addr;
        emit ChangedTreasuryAddress(_addr);
    }   

    function _setBotAddresss(address _addr) internal {
        botAddress = _addr;
        emit BotAddressChanged(_addr);
    }

    function _setSignerAddress(address _addr) internal {
        signerAddress = _addr;
        emit SignerAddressChanged(_addr);
    }

    function _setShipAddress(address _addr) internal {
        shipAddress = _addr;
        emit ShipAddressChanged(_addr);
    }

    function verifyTypedDataHash(bytes32 _domainSeparator, LibLazyPoolRemove.Remove calldata _remove, bytes calldata _signature, address _owner) internal pure returns (bool) {
        bytes32 digest = ECDSA.toTypedDataHash(_domainSeparator, LibLazyPoolRemove.hash(_remove));
        address signer = ECDSA.recover(digest, _signature);

        return signer == _owner;
    }

    function verifyTypedDataHashTwo(bytes32 _domainSeparator, LibLazyPoolRemove.BuyTeam calldata _buyTeam, bytes calldata _signature, address _owner) internal pure returns (bool) {
        bytes32 digest = ECDSA.toTypedDataHash(_domainSeparator, LibLazyPoolRemove.hashBuyTeam(_buyTeam));
        address signer = ECDSA.recover(digest, _signature);

        return signer == _owner;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITokenPaymentSplitter {
    function split(address _token, address _sender, uint256 _amount) external payable ;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Managable {
    mapping(address => bool) private managers;
    address[] private managersAddresses;

    event AddedManager(address _address);
    event RemovedManager(address _address);

    modifier onlyManager() {
        require(managers[msg.sender], "caller is not manager");
        _;
    }

    function getManagers() public view returns (address[] memory) {
        return managersAddresses;
    }

    function transferManager(address _manager) external onlyManager {
        _removeManager(msg.sender);
        _addManager(_manager);
    }

    function addManager(address _manager) external onlyManager {
        _addManager(_manager);
    }

    function removeManager(address _manager) external onlyManager {
        uint index;
        for(uint i = 0; i < managersAddresses.length; i++) {
            if(managersAddresses[i] == _manager) {
                index = i;
                break;
            }
        }

        managersAddresses[index] = managersAddresses[managersAddresses.length - 1];
        managersAddresses.pop();

        _removeManager(_manager);
    }

    function _addManager(address _manager) internal {
        managers[_manager] = true;
        managersAddresses.push(_manager);
        emit AddedManager(_manager);
    }

    function _removeManager(address _manager) internal {
        managers[_manager] = false;
        emit RemovedManager(_manager);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibLazyPoolRemove {
    bytes32 public constant TYPE_HASH = keccak256("Remove(address nft,address buyer,uint256 id,uint256 deadline)");
    bytes32 public constant BUY_TEAM_HASH = keccak256("BuyTeam(address nft,address buyer,uint256 deadline,uint256[] id)");
 
    struct Remove {
        address nft;
        address buyer;
        uint256 id;
        uint256 deadline;
    }

    struct BuyTeam {
        address nft;
        address buyer;
        uint256 deadline;
        uint256[] id;
    }


    function hash(Remove memory _lazyRemove) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH,_lazyRemove.nft,_lazyRemove.buyer,_lazyRemove.id,_lazyRemove.deadline));
    }    

    function hashBuyTeam(BuyTeam memory _lazyBuyTeam) internal pure returns (bytes32) {
        return keccak256(abi.encode(BUY_TEAM_HASH,_lazyBuyTeam.nft,_lazyBuyTeam.buyer,_lazyBuyTeam.deadline,keccak256(abi.encodePacked(_lazyBuyTeam.id))));
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}