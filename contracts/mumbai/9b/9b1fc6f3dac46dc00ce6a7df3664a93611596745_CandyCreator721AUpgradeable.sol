/***
 *    ░█████╗░░█████╗░███╗░░██╗██████╗░██╗░░░██╗  ░█████╗░██████╗░███████╗░█████╗░████████╗░█████╗░██████╗░
 *    ██╔══██╗██╔══██╗████╗░██║██╔══██╗╚██╗░██╔╝  ██╔══██╗██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗
 *    ██║░░╚═╝███████║██╔██╗██║██║░░██║░╚████╔╝░  ██║░░╚═╝██████╔╝█████╗░░███████║░░░██║░░░██║░░██║██████╔╝
 *    ██║░░██╗██╔══██║██║╚████║██║░░██║░░╚██╔╝░░  ██║░░██╗██╔══██╗██╔══╝░░██╔══██║░░░██║░░░██║░░██║██╔══██╗
 *    ╚█████╔╝██║░░██║██║░╚███║██████╔╝░░░██║░░░  ╚█████╔╝██║░░██║███████╗██║░░██║░░░██║░░░╚█████╔╝██║░░██║
 *    ░╚════╝░╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░░░░╚═╝░░░  ░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝
 *
 * Version: LFG
 *
 * Purpose: ERC-721 template for no-code users.
 *          Placeholder for pre-reveal information.
 *          Batch minting using ERC721A.
 *          Guaranteed mint royalties with CandyPaymentSplitter.
 *          EIP-2981 compliant secondary sale collection-wide royalties with CandyCollection2981Royalties.
 *          Merkle whitelist functionality utilizing getAux from ERC721A.
 *          Can be deployed using a Clone Factory (OpenZeppelin Upgradeable Style)
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ERC721A/ERC721AUpgradeable.sol";
import "../PaymentSplitter/CandyPaymentSplitterUpgradeable.sol";
import "../Royalties/CandyCollection2981RoyaltiesUpgradeable.sol";

error MintingNotActive();
error MintingActive();
error WouldExceedMintSize();
error ExceedsMaxTransactionMints();
error NonExistentToken();
error WhitelistNotRequired();
error WhitelistRequired();
error NotWhitelisted();
error NotEnoughWhitelistSlots();
error ExceedsMaxWhitelistMints();
error WrongPayment();
error InvalidMintSize();

/// @title An ERC721A-based token contract.
/// @author Candy Labs
contract CandyCreator721AUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ERC721AUpgradeable,
    CandyPaymentSplitterUpgradeable,
    CandyCollection2981RoyaltiesUpgradeable
{
    // State Variables
    string private base;
    // 32 bytes
    string private placeholderURI;
    // 32 bytes
    bytes32 private whitelistMerkleRoot;
    // 32 bytes 
    uint256 private maxPublicMints;
    // 32 bytes 
    uint256 private mintPrice;
    // 32 bytes 
    uint256 private mintSize;
    // 8 bytes 
    uint64 private maxWhitelistMints;
    // 1 byte 
    bool private whitelistActive;
    // 1 byte 
    bool private mintingActive;
    // 1 byte
    bool private lockedPayees;
    
    // Contract Events 
    event UpdatedMintPrice(uint256 _old, uint256 _new);
    event UpdatedMintSize(uint256 _old, uint256 _new);
    event UpdatedMaxWhitelistMints(uint256 _old, uint256 _new);
    event UpdatedMaxPublicMints(uint256 _old, uint256 _new);
    event UpdatedMintStatus(bool _old, bool _new);
    event UpdatedWhitelistStatus(bool _old, bool _new);
    event UpdatedPresaleEnd(uint256 _old, uint256 _new);
    event UpdatedWhitelist(bytes32 _old, bytes32 _new);
    event UpdatedRoyalties(address newRoyaltyAddress, uint256 newPercentage);
    event PayeesLocked(bool _status);


    /***
     *    ░██████╗███████╗████████╗██╗░░░██╗██████╗░
     *    ██╔════╝██╔════╝╚══██╔══╝██║░░░██║██╔══██╗
     *    ╚█████╗░█████╗░░░░░██║░░░██║░░░██║██████╔╝
     *    ░╚═══██╗██╔══╝░░░░░██║░░░██║░░░██║██╔═══╝░
     *    ██████╔╝███████╗░░░██║░░░╚██████╔╝██║░░░░░
     *    ╚═════╝░╚══════╝░░░╚═╝░░░░╚═════╝░╚═╝░░░░░
     *    This section pertains to contract initialization and setup.
     */

    function initialize(
        // 32 bytes
        string memory name,
        // 32 bytes
        string memory symbol,
        // 32 bytes
        string memory _placeholderURI,
        // 32 bytes
        uint256 _mintPrice,
        // 32 bytes 
        uint256 _mintSize,
        // 32 bytes per element
        address[] memory splitAddresses,
        // 32 bytes per element
        // Can use uint16 (max value 65535) since an element in splitBasisPoints cannot be greater than 9,500.
        uint256[] memory splitBasisPoints,
        // 32 bytes
        bytes32 _whitelistMerkleRoot,
        // 32 bytes 
        uint256 _maxPublicMints,
        // 8 bytes
        uint64 _maxWhitelistMints,
        // 20 bytes
        address candyWallet
    )   public initializer {
        __ERC721A_init(name, symbol);
        __Ownable_init();
        
        setupPaymentSplit(candyWallet, splitAddresses, splitBasisPoints);
        if (_whitelistMerkleRoot != 0) {
            whitelistMerkleRoot = _whitelistMerkleRoot;
            enableWhitelist();
        }
        placeholderURI = _placeholderURI;
        mintPrice = _mintPrice;
        mintSize = _mintSize;
        maxPublicMints = _maxPublicMints;
        maxWhitelistMints = _maxWhitelistMints;
    }

    /// @dev Called only within the logic of the initializer function to setup the payment splitting logic. 
    /// @param candyWallet The address used to receive the 5% (500 basis points) Candy Chain platform fee.
    /// @param splitAddresses An array containing the addresses that should receive payment.
    /// @param splitBasisPoints An array containing the basis points for each address in splitAddresses.
    function setupPaymentSplit(address candyWallet, address[] memory splitAddresses, uint256[] memory splitBasisPoints) private onlyInitializing {
        addPayee(candyWallet, 500);
        if (splitAddresses.length == 0) {
            addPayee(_msgSender(), 9500);
            lockPayees();
        } else {
            for (uint256 i = 0; i < splitAddresses.length; i++) {
                addPayee(splitAddresses[i], splitBasisPoints[i]);
            }
            lockPayees();
        }
    }

    /***
     *    ███╗   ███╗██╗███╗   ██╗████████╗
     *    ████╗ ████║██║████╗  ██║╚══██╔══╝
     *    ██╔████╔██║██║██╔██╗ ██║   ██║
     *    ██║╚██╔╝██║██║██║╚██╗██║   ██║
     *    ██║ ╚═╝ ██║██║██║ ╚████║   ██║
     *    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝
     *    This section pertains to minting functionality.
     */

    /// @notice Mint function for use with whitelist minting sales. Mint fees in native token,
    ///  requires amount * mintPrice to be sent by caller.
    /// @param merkleProof The merkleProof generated by an off-chain API.
    /// @param amount The number of tokens to be minted.
    function whitelistMint(bytes32[] calldata merkleProof, uint64 amount)
        external
        payable
    {
        if (!mintingActive) revert MintingNotActive();
        if (!whitelistActive) revert WhitelistNotRequired();
        if (_msgValue() != mintPrice * amount) revert WrongPayment();
        if (totalSupply() + amount > mintSize) revert WouldExceedMintSize();
        if (amount > maxWhitelistMints) revert ExceedsMaxWhitelistMints();
        if (
            !MerkleProofUpgradeable.verify(
                merkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            )
        ) revert NotWhitelisted();
        uint64 numWhitelistMinted = _getAux(_msgSender()) + amount;
        if (numWhitelistMinted > maxWhitelistMints)
            revert NotEnoughWhitelistSlots();
        _safeMint(_msgSender(), amount);
        _setAux(_msgSender(), numWhitelistMinted);
    }

    /// @notice Mint function for use with public minting sales. Mint Fees in native token,
    ///  requires amount * mintPrice to be sent by caller.
    /// @param amount The number of tokens to be minted.
    function publicMint(uint256 amount) external payable {
        if (whitelistActive) revert WhitelistRequired();
        if (!mintingActive) revert MintingNotActive();
        if (_msgValue() != mintPrice * amount) revert WrongPayment();
        if (totalSupply() + amount > mintSize) revert WouldExceedMintSize();
        if (amount > maxPublicMints) revert ExceedsMaxTransactionMints();
        _safeMint(_msgSender(), amount);
    }

    /***
     *    ██████╗░░█████╗░██╗░░░██╗███╗░░░███╗███████╗███╗░░██╗████████╗
     *    ██╔══██╗██╔══██╗╚██╗░██╔╝████╗░████║██╔════╝████╗░██║╚══██╔══╝
     *    ██████╔╝███████║░╚████╔╝░██╔████╔██║█████╗░░██╔██╗██║░░░██║░░░
     *    ██╔═══╝░██╔══██║░░╚██╔╝░░██║╚██╔╝██║██╔══╝░░██║╚████║░░░██║░░░
     *    ██║░░░░░██║░░██║░░░██║░░░██║░╚═╝░██║███████╗██║░╚███║░░░██║░░░
     *    ╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝╚══════╝╚═╝░░╚══╝░░░╚═╝░░░
     *    This section pertains to mint fees, royalties, and fund release.
     */

    // Function to receive ether, msg.data must be empty
    receive() external payable {
        // From PaymentSplitter.sol
        emit PaymentReceived(_msgSender(), _msgValue());
    }

    // Function to receive ether, msg.data is not empty
    fallback() external payable {
        // From PaymentSplitter.sol
        emit PaymentReceived(_msgSender(), _msgValue());
    }

    /// @notice Releases funds from the contract to the addresses owed payment.
    ///  Only the owner can call this function.
    /// @dev Defaults to the logic contained in CandyPaymentSplitterUpgradeable.
    function release() external onlyOwner {
        _release();
    }

    /// @notice Sets single address EIP-2981 royalty information for this collection.
    /// @dev Uses internal functions to set EIP-2981
    ///  found in IERC2981Upgradeable.sol and used by CandyCollection2981RoyaltiesUpgradeable.sol
    /// @param _royaltyAddress - Address for all royalties to go to.
    /// @param _basisPoints - Basis points (out of 10,000) to set as secondary sale royalty fee.
    ///  of secondary sales
    function setRoyaltyInfo(address _royaltyAddress, uint256 _basisPoints)
        public
        onlyOwner
    {
        _setRoyalties(_royaltyAddress, _basisPoints);
        emit UpdatedRoyalties(_royaltyAddress, _basisPoints);
    }

    /// @notice this will set the fees required to mint using
    ///  publicMint(), must enter in wei. So 1 ETH = 10**18.
    /// @param _newFee - fee you set, if ETH 10**18, if
    ///  an ERC20 use token's decimals in calculation
    function setMintPrice(uint256 _newFee) public onlyOwner {
        uint256 oldFee = mintPrice;
        mintPrice = _newFee;
        emit UpdatedMintPrice(oldFee, mintPrice);
    }

    /// @notice will add an address to PaymentSplitter by owner role
    /// @dev May be able to eliminate this function since it is only called in the constructor / initializer
    /// @param newAddress Address to receive payments.
    /// @param _basisPoints The basis points newAddress should receive of contract earnings.
    function addPayee(address newAddress, uint256 _basisPoints) private {
        require(!lockedPayees, "Can not set, payees locked");
        _addPayee(newAddress, _basisPoints);
    }

    /// @notice Locks the ability to add further payees on CandyPaymentSplitter.sol
    function lockPayees() private {
        require(!lockedPayees, "Can not set, payees locked");
        lockedPayees = true;
        emit PayeesLocked(lockedPayees);
    }

    /***
     *
     *    ░█████╗░██████╗░███╗░░░███╗██╗███╗░░██╗
     *    ██╔══██╗██╔══██╗████╗░████║██║████╗░██║
     *    ███████║██║░░██║██╔████╔██║██║██╔██╗██║
     *    ██╔══██║██║░░██║██║╚██╔╝██║██║██║╚████║
     *    ██║░░██║██████╔╝██║░╚═╝░██║██║██║░╚███║
     *    ╚═╝░░╚═╝╚═════╝░╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝
     *    This section pertains to to basic contract administration tasks.
     *    All functions are restricted with the onlyOwner modifier.
     */

    /// @notice Updates the placeholderURI.
    /// @dev Added so users can fix mistakes with expensive deployed contracts.
    function updatePlaceholder(string calldata _placeholderURI) external onlyOwner {
        placeholderURI = _placeholderURI;
    }

    /// @notice Enables minting. 
    function enableMinting() external onlyOwner {
        if (mintingActive) revert MintingActive();
        bool old = mintingActive;
        mintingActive = true;
        emit UpdatedMintStatus(old, mintingActive);
    }

    /// @notice Disables minting. 
    function disableMinting() external onlyOwner {
        if (!mintingActive) revert MintingNotActive();
        bool old = mintingActive;
        mintingActive = false;
        emit UpdatedMintStatus(old, mintingActive);
    }

    /// @notice Requires whitelist membership for minting. 
    /// @dev Public visibility required since the function is called internally.
    function enableWhitelist() public onlyOwner {
        if (whitelistActive) revert WhitelistRequired();
        bool old = whitelistActive;
        whitelistActive = true;
        emit UpdatedWhitelistStatus(old, whitelistActive);
    }

    /// @notice Removes the whitelist requirement for minting. 
    function disableWhitelist() external onlyOwner {
        if (!whitelistActive) revert WhitelistNotRequired();
        bool old = whitelistActive;
        whitelistActive = false;
        emit UpdatedWhitelistStatus(old, whitelistActive);
    }

    /// @notice Sets a new Merkle root used to verify whitelist membership
    ///  in combination with a proof submitted to the whitelistMint function.
    /// @param _merkleRoot The generated Merkle root hash for the whitelist.
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        bytes32 old = whitelistMerkleRoot;
        whitelistMerkleRoot = _merkleRoot;
        emit UpdatedWhitelist(old, whitelistMerkleRoot);
    }

    /// @notice Sets the maximum number of tokens a whitelisted user can mint.
    /// @param _amount The maximum amount of tokens a whitelisted user can mint.
    function setMaxWhitelistMints(uint64 _amount) public onlyOwner {
        uint256 oldAmount = maxWhitelistMints;
        maxWhitelistMints = _amount;
        emit UpdatedMaxWhitelistMints(oldAmount, maxWhitelistMints);
    }

    /// @notice Sets the maximum number of tokens a single address can mint AT A TIME
    ///  during the public mint period. Keep in mind that regardless of the number set, during public
    ///  minting any user will still be able to call the publicMint function an unlimited number of times
    /// @param  _amount The maximum amount of tokens that can be minted in a public transaction.
    function setMaxPublicMints(uint256 _amount) public onlyOwner {
        uint256 oldAmount = maxPublicMints;
        maxPublicMints = _amount;
        emit UpdatedMaxPublicMints(oldAmount, maxWhitelistMints);
    }

    /// @notice Updates the base URI for the token metadata
    ///  it does not emit an event so that it can be set invisibly to purchasers
    ///  and avoid token sniping.
    /// @param baseURI The new baseURI to generate tokenURIs from. 
    function setBaseURI(string memory baseURI) public onlyOwner {
        base = baseURI;
    }

    /// @notice Sets the mint size. Cannot be smaller than the totalSupply().
    /// @param _amount The mint size, or number of items in the collection.
    function setMintSize(uint256 _amount) public onlyOwner {
        if (_amount < totalSupply()) revert InvalidMintSize();
        uint256 old = mintSize;
        mintSize = _amount;
        emit UpdatedMintSize(old, mintSize);
    }

    /***
     *    ██████╗░██╗░░░██╗██████╗░██╗░░░░░██╗░█████╗░  ██╗░░░██╗██╗███████╗░██╗░░░░░░░██╗░██████╗
     *    ██╔══██╗██║░░░██║██╔══██╗██║░░░░░██║██╔══██╗  ██║░░░██║██║██╔════╝░██║░░██╗░░██║██╔════╝
     *    ██████╔╝██║░░░██║██████╦╝██║░░░░░██║██║░░╚═╝  ╚██╗░██╔╝██║█████╗░░░╚██╗████╗██╔╝╚█████╗░
     *    ██╔═══╝░██║░░░██║██╔══██╗██║░░░░░██║██║░░██╗  ░╚████╔╝░██║██╔══╝░░░░████╔═████║░░╚═══██╗
     *    ██║░░░░░╚██████╔╝██████╦╝███████╗██║╚█████╔╝  ░░╚██╔╝░░██║███████╗░░╚██╔╝░╚██╔╝░██████╔╝
     *    ╚═╝░░░░░░╚═════╝░╚═════╝░╚══════╝╚═╝░╚════╝░  ░░░╚═╝░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═════╝░
     *    Public view functions to retrieve information about the contract. 
     */

    /// @notice True/False value indicating whether minting is enabled.
    function mintStatus() external view returns (bool) {
        return mintingActive;
    }

    /// @notice True/False value indicating that the whitelist is currenly required for minting.
    function whitelistStatus() external view returns (bool) {
        return whitelistActive;
    }

    /// @notice The fee to mint each token in this collection. 
    function mintingFee() external view returns (uint256) {
        return mintPrice;
    }

    /// @notice The maximum tokens that are allowed to be minted 
    ///  by a whitelisted address.
    function whitelistMaxMints() external view returns (uint256) {
        return maxWhitelistMints;
    }

    /// @notice The maximum tokens that are allowed to be minted during
    ///  a single publicMint transaction.
    function publicMaxMints() external view returns (uint256) {
        return maxPublicMints;
    }

    /// @notice The current contract balance. 
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice The size of the collection.
    /// @dev Can be updated to sizes larger than or equal to the totalSupply()
    ///  through setMintSize().
    function collectionSize() external view returns (uint256) {
        return mintSize;
    }

    /***
     *    ░█████╗░██╗░░░██╗███████╗██████╗░██████╗░██╗██████╗░███████╗
     *    ██╔══██╗██║░░░██║██╔════╝██╔══██╗██╔══██╗██║██╔══██╗██╔════╝
     *    ██║░░██║╚██╗░██╔╝█████╗░░██████╔╝██████╔╝██║██║░░██║█████╗░░
     *    ██║░░██║░╚████╔╝░██╔══╝░░██╔══██╗██╔══██╗██║██║░░██║██╔══╝░░
     *    ╚█████╔╝░░╚██╔╝░░███████╗██║░░██║██║░░██║██║██████╔╝███████╗
     *    ░╚════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═════╝░╚══════╝
     */

    /// @notice Sets the baseURI which will be used to generate tokenURIs
    /// @dev Refer to tokenURI function for additional information.
    function _baseURI() internal view override returns (string memory) {
        return base;
    }

    /// @notice Sets the first tokenId that will be minted.
    /// @dev Override for ERC721A _startTokenId to change from default 0 -> 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Returns the metadata URI for a given token.
    /// @dev Override for ERC721A tokenURI.
    /// @param tokenId The id of the token in this collection to retrieve the URI for. Must exist.
    /// @return The baseURI suffixed with ./{tokenId}.json
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonExistentToken();
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        StringsUpgradeable.toString(tokenId),
                        ".json"
                    )
                )
                : placeholderURI;
    }

    /// @notice Required override for supportsInterface(bytes4).
    /// @param interfaceId bytes4 id per interface or contract
    ///  calculated by ERC165 standards automatically
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return (
            interfaceId == type(CandyCollection2981RoyaltiesUpgradeable).interfaceId ||
            interfaceId == type(OwnableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/***
 *    
 *    ██████╗░░█████╗░░█████╗░░░███╗░░  ██████╗░░█████╗░██╗░░░██╗░█████╗░██╗░░░░░████████╗██╗███████╗░██████╗
 *    ╚════██╗██╔══██╗██╔══██╗░████║░░  ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗██║░░░░░╚══██╔══╝██║██╔════╝██╔════╝
 *    ░░███╔═╝╚██████║╚█████╔╝██╔██║░░  ██████╔╝██║░░██║░╚████╔╝░███████║██║░░░░░░░░██║░░░██║█████╗░░╚█████╗░
 *    ██╔══╝░░░╚═══██║██╔══██╗╚═╝██║░░  ██╔══██╗██║░░██║░░╚██╔╝░░██╔══██║██║░░░░░░░░██║░░░██║██╔══╝░░░╚═══██╗
 *    ███████╗░█████╔╝╚█████╔╝███████╗  ██║░░██║╚█████╔╝░░░██║░░░██║░░██║███████╗░░░██║░░░██║███████╗██████╔╝
 *    ╚══════╝░╚════╝░░╚════╝░╚══════╝  ╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═╝╚══════╝╚═════╝░
 *
 * Designed to allow setting a global royalty address along with specified basis points. 
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

abstract contract CandyCollection2981RoyaltiesUpgradeable is Initializable, IERC2981Upgradeable {

  address private royaltyAddress;
  uint256 private royaltyBasisPoints;

  function _setRoyalties(address _receiver, uint256 _basisPoints) internal {
    royaltyAddress = _receiver;
    royaltyBasisPoints = _basisPoints;
  }

  // Override for royaltyInfo(uint256, uint256)
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view override(IERC2981Upgradeable) returns (
    address receiver,
    uint256 royaltyAmount
  ) {
    receiver = royaltyAddress;
    royaltyAmount = _salePrice * royaltyBasisPoints / 10000;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

/***
 *    ██████╗  █████╗ ██╗   ██╗███╗   ███╗███████╗███╗   ██╗████████╗
 *    ██╔══██╗██╔══██╗╚██╗ ██╔╝████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
 *    ██████╔╝███████║ ╚████╔╝ ██╔████╔██║█████╗  ██╔██╗ ██║   ██║
 *    ██╔═══╝ ██╔══██║  ╚██╔╝  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║
 *    ██║     ██║  ██║   ██║   ██║ ╚═╝ ██║███████╗██║ ╚████║   ██║
 *    ╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝
 *
 *    ███████╗██████╗ ██╗     ██╗████████╗████████╗███████╗██████╗
 *    ██╔════╝██╔══██╗██║     ██║╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗
 *    ███████╗██████╔╝██║     ██║   ██║      ██║   █████╗  ██████╔╝
 *    ╚════██║██╔═══╝ ██║     ██║   ██║      ██║   ██╔══╝  ██╔══██╗
 *    ███████║██║     ███████╗██║   ██║      ██║   ███████╗██║  ██║
 *    ╚══════╝╚═╝     ╚══════╝╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝
 * Re-write of @openzeppelin/contracts/finance/PaymentSplitter.sol
 *
 *
 * Edits the release functionality to force release to all addresses added
 * as payees.
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error ZeroBalance();
error AddressAlreadyAssigned();
error InvalidShares();
error SharesToZeroAddress();

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */

abstract contract CandyPaymentSplitterUpgradeable is Initializable, ContextUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _numPayees;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event RefundReleased(address to, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     *
     *  receive() external payable virtual {
     *    emit PaymentReceived(_msgSender(), msg.value);
     *  }
     *
     *  // Fallback function is called when msg.data is not empty
     *  // Added to PaymentSplitter.sol
     *  fallback() external payable {
     *    emit PaymentReceived(_msgSender(), msg.value);
     *  }
     *
     * receive() and fallback() to be handled at final contract
     */

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Releases contract balance to the addresses that are owed funds.
     */
    function _release() internal {
        if (address(this).balance == 0) revert ZeroBalance();
        for (uint256 i = 0; i < _numPayees.current(); i++) {
            address account = payee(i);
            uint256 totalReceived = address(this).balance + _totalReleased;
            uint256 payment = (totalReceived * _shares[account]) /
                _totalShares -
                _released[account];
            _released[account] = _released[account] + payment;
            _totalReleased = _totalReleased + payment;
            AddressUpgradeable.sendValue(payable(account), payment);
            emit PaymentReleased(account, payment);
        }
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares to assign the payee.
     */
    function _addPayee(address account, uint256 shares_) internal {
        if (account == address(0)) revert SharesToZeroAddress();
        if (shares_ <= 0) revert InvalidShares();
        if (_shares[account] != 0) revert AddressAlreadyAssigned();
        _numPayees.increment();
        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    // Release refund to account
    function _releaseRefund(address account, uint256 payment) internal {
        AddressUpgradeable.sendValue(payable(account), payment);
        emit RefundReleased(account, payment);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "./IERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AUpgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721AUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721AUpgradeable.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex != end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721AUpgradeable is IERC721Upgradeable, IERC721MetadataUpgradeable {
    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApproveToCaller();
    error ApprovalToCurrentOwner();
    error BalanceQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint) {
        return msg.value;
    }

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}