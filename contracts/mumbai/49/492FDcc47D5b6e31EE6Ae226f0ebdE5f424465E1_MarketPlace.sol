// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../Blacklist.sol";
import "../TokenReceiptHandler.sol";

contract MarketPlace is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721Receiver
{
    using AddressUpgradeable for address;

    struct AuctionListing {
        address seller;
        address purchaseTokenAddress;
        uint256 startPrice;
        uint256 endPrice;
        uint256 listTime; // in timestamp
        uint256 duration; // in day
    }

    // State Variables
    // mapping of NFT contract addresses to token IDs that themselves point to Listing data structs
    mapping(address => mapping(uint256 => AuctionListing))
        private _auctionListings;

    TokenReceiptHandler internal tokenReceiptHandler;
    Blacklist internal blacklist;

    uint256 public platformFeePercent; // % * 100, e.g. 4.5% = 450
    uint256 public constant percentMaxValue = 10000;
    address public payoutWalletAddress;
    mapping(address => bool) public approvedPurchaseTokenAddresses;

    // event
    event PlatformFeePercentUpdated(uint256 platformFeePercent);
    event PlatformFeePayoutWalletAddressUpdated(address payoutWalletAddress);
    event ApprovedPurchaseTokenAddressesUpdated(address tokenAddress);

    /// @notice this event is emitted when a listing is created
    event ItemListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        address tokenAddress,
        uint256 startPrice,
        uint256 endPrice,
        uint256 duration
    );

    /// @notice this event is emitted when the listing was sold
    event ItemUnlisted(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller
    );

    /// @notice this event is emitted when a listing is cancelled by seller
    event ItemCanceled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller
    );

    /// @notice this event is emitted when item was bought
    event ItemBought(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed buyer,
        address tokenAddress,
        uint256 price
    );

    /// @dev Determine if purchase token address is in approved list
    /// @param _purchaseTokenAddress purchase token address
    modifier isApprovedPurchaseToken(address _purchaseTokenAddress) {
        require(
            approvedPurchaseTokenAddresses[_purchaseTokenAddress] == true,
            "Token is not approved"
        );
        _;
    }

    /// @dev Determine if NFT is listed auction on the market
    /// @param _nftAddress Nft address
    /// @param _nftId token ID
    modifier isAuctionListed(address _nftAddress, uint256 _nftId) {
        require(
            _auctionListings[_nftAddress][_nftId].startPrice > 0,
            "Not Listed"
        );
        _;
    }

    /// @dev Determine if NFT is own by lister
    /// @param _nftAddress Nft address
    /// @param _nftId token ID
    /// @param _lister lister address
    modifier isOwner(
        address _nftAddress,
        uint256 _nftId,
        address _lister
    ) {
        require(_lister == IERC721(_nftAddress).ownerOf(_nftId), "Not Owner");
        _;
    }

    /// @dev Determine if listed auction NFT seller is canceller
    /// @param _nftAddress Nft address
    /// @param _nftId token ID
    /// @param _canceller canceller address
    modifier isAuctionListSeller(
        address _nftAddress,
        uint256 _nftId,
        address _canceller
    ) {
        require(
            _canceller == _auctionListings[_nftAddress][_nftId].seller,
            "Not Auction List Seller"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev Initialize the contract
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @dev Required by IERC721Receiver
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice Setup TokenReceipt contracts
    /// @param _tokenReceipt TokenReceiptHandler contract address
    function setupTokenReceiptContracts(address _tokenReceipt)
        external
        onlyOwner
    {
        require(_tokenReceipt.isContract(), "addresses must be contract");

        tokenReceiptHandler = TokenReceiptHandler(_tokenReceipt);
    }

    /// @notice Setup Blacklist contracts
    /// @param _blacklist Blacklist contract address
    function setupBlacklistContracts(address _blacklist) external onlyOwner {
        require(_blacklist.isContract(), "addresses must be contract");

        blacklist = Blacklist(_blacklist);
    }

    /// @notice Set up Platform Fee Percent
    /// @param _platformFeePercent % * 100, e.g. 4.5% = 450
    function setPlatformFeePercent(uint256 _platformFeePercent)
        external
        onlyOwner
    {
        platformFeePercent = _platformFeePercent;
        emit PlatformFeePercentUpdated(platformFeePercent);
    }

    /// @notice Set up Platform Fee Payout wallet
    /// @param _payoutWalletAddress payout wallet address
    function setPlatformFeePayoutWalletAddress(address _payoutWalletAddress)
        external
        onlyOwner
    {
        payoutWalletAddress = _payoutWalletAddress;
        emit PlatformFeePayoutWalletAddressUpdated(payoutWalletAddress);
    }

    /// @notice Set up Approve purchase token
    /// @param _token token address
    /// @param _isApproved token isApprove
    function setApprovedPurchaseTokenAddresses(address _token, bool _isApproved)
        external
        onlyOwner
    {
        // check token address is erc20 or not
        require(_token.isContract(), "addresses must be contract");
        IERC20 token = IERC20(_token);
        token.allowance(msg.sender, address(this));

        approvedPurchaseTokenAddresses[_token] = _isApproved;
        emit ApprovedPurchaseTokenAddressesUpdated(_token);
    }

    /// @notice list nft as auction price, if this is fixed price, _startPrice = _endPrice & _duration = 0
    /// @param _nftAddress nft address
    /// @param _nftId nft ID
    /// @param _tokenAddress token address
    /// @param _startPrice start price
    /// @param _endPrice end price
    /// @param _duration end time duration
    function listAuctionItem(
        address _nftAddress,
        uint256 _nftId,
        address _tokenAddress,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _duration // in day
    )
        external
        isApprovedPurchaseToken(_tokenAddress)
        isOwner(_nftAddress, _nftId, msg.sender)
    {
        require(_startPrice > 0 && _endPrice > 0, "Price must be above Zero");
        require(
            IERC721(_nftAddress).isApprovedForAll(msg.sender, address(this)),
            "Not approved for Marketplace"
        );
        require(
            !blacklist.blacklistedNFT(msg.sender, address(_nftAddress), _nftId),
            "Nft is blacklisted"
        );

        // set listing data
        _auctionListings[_nftAddress][_nftId] = AuctionListing(
            msg.sender,
            _tokenAddress,
            _startPrice,
            _endPrice,
            block.timestamp,
            _duration
        );

        // transfer nft to this contract (staking)
        IERC721(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _nftId
        );

        // give seller stake token
        tokenReceiptHandler.createReceipts(
            msg.sender,
            _nftAddress,
            _asDefaultValueArray(_nftId, 1),
            _asDefaultValueArray(1, 1)
        );

        // emit event
        emit ItemListed(
            _nftAddress,
            _nftId,
            msg.sender,
            _tokenAddress,
            _startPrice,
            _endPrice,
            _duration
        );
    }

    /// @notice cancel listing auction price nft
    /// @param _nftAddress nft address
    /// @param _nftId nft ID
    function cancelAuctionListing(address _nftAddress, uint256 _nftId)
        external
        isAuctionListed(_nftAddress, _nftId)
        isAuctionListSeller(_nftAddress, _nftId, msg.sender)
    {
        delete (_auctionListings[_nftAddress][_nftId]);

        // transfer nft back to seller
        IERC721(_nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _nftId
        );

        // burn seller stake token
        tokenReceiptHandler.burnReceipts(
            msg.sender,
            _nftAddress,
            _asDefaultValueArray(_nftId, 1),
            _asDefaultValueArray(1, 1)
        );

        emit ItemCanceled(_nftAddress, _nftId, msg.sender);
    }

    /// @notice get listing auction nft price in current time
    /// @param _nftAddress nft address
    /// @param _nftId nft ID
    function getAuctionItemPrice(address _nftAddress, uint256 _nftId)
        public
        view
        isAuctionListed(_nftAddress, _nftId)
        returns (uint256)
    {
        AuctionListing memory listedItem = _auctionListings[_nftAddress][
            _nftId
        ];
        // return endPrice if the time is passed duration
        if (
            block.timestamp >
            (listedItem.listTime + listedItem.duration * 3600 * 24)
        ) {
            return listedItem.endPrice;
        }

        uint256 targetPrice;
        uint256 durationPrice = ((Math.max(
            listedItem.startPrice,
            listedItem.endPrice
        ) - Math.min(listedItem.startPrice, listedItem.endPrice)) *
            (block.timestamp - listedItem.listTime)) /
            (listedItem.duration * 3600 * 24);

        if (listedItem.startPrice > listedItem.endPrice) {
            targetPrice = listedItem.startPrice - durationPrice;
        } else {
            targetPrice = listedItem.startPrice + durationPrice;
        }
        return targetPrice;
    }

    /// @notice buy listed auction price nft
    /// @param _nftAddress nft address
    /// @param _nftId nft ID
    function buyAuctionItem(address _nftAddress, uint256 _nftId)
        external
        isAuctionListed(_nftAddress, _nftId)
        nonReentrant
    {
        AuctionListing memory listedItem = _auctionListings[_nftAddress][
            _nftId
        ];

        // send token to seller and payout wallet
        uint256 targetPrice = getAuctionItemPrice(_nftAddress, _nftId);
        uint256 sellerReceive = (targetPrice *
            (percentMaxValue - platformFeePercent)) / percentMaxValue;
        uint256 payoutWalletReceive = targetPrice - sellerReceive;
        IERC20 token = IERC20(listedItem.purchaseTokenAddress);
        token.transferFrom(msg.sender, listedItem.seller, sellerReceive);
        token.transferFrom(
            msg.sender,
            payoutWalletAddress,
            payoutWalletReceive
        );

        // send nft from contract to buyer
        delete (_auctionListings[_nftAddress][_nftId]);
        IERC721(_nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _nftId
        );

        // emit Item unlisted event
        emit ItemUnlisted(_nftAddress, _nftId, listedItem.seller);

        // burn seller stake token
        tokenReceiptHandler.burnReceipts(
            listedItem.seller,
            _nftAddress,
            _asDefaultValueArray(_nftId, 1),
            _asDefaultValueArray(1, 1)
        );

        // emit bought event
        emit ItemBought(
            _nftAddress,
            _nftId,
            msg.sender,
            listedItem.purchaseTokenAddress,
            targetPrice
        );
    }

    /// @notice get auction fix price nft info
    /// @param _nftAddress nft address
    /// @param _nftId nft ID
    function getAuctionListing(address _nftAddress, uint256 _nftId)
        external
        view
        returns (AuctionListing memory)
    {
        return _auctionListings[_nftAddress][_nftId];
    }

    function _asDefaultValueArray(uint256 element, uint256 length)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            array[i] = element;
        }

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
interface IERC721Receiver {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./utils/AccessProtectedUpgradable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Blacklist contract
/// @notice blacklist any owner or NFT token id, which can be read from any contract
contract Blacklist is
    Initializable,
    UUPSUpgradeable,
    AccessProtectedUpgradable
{
    using AddressUpgradeable for address;

    mapping(bytes32 => bool) internal blacklist;

    /// @notice flag to disable all blacklist
    bool public disabled;

    /// @notice nft type to blacklist
    /// @dev 0: ALL, 1: ERC721, 2: ERC1155
    enum NFT_TYPE {
        ALL,
        ERC721,
        ERC1155
    }

    /// @notice used to limit the max number of blacklist in each batch
    uint256 public constant MAX_INPUT_LENGTH = 32;
    struct Input {
        address _owner;
        NFT_TYPE _type;
        address _token;
        uint256 _id;
        bool _enable;
    }

    uint256 public constant ANY_TOKEN_ID =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice emit event when the contract was changed the disabled status
    event ContractDisabled(bool indexed _status);

    /// @notice emit event when the address was added to blacklist
    event NFTBlacklisted(
        address indexed _owner,
        address indexed _token,
        uint256 indexed _tokenId,
        bool _enable
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev Initialize the contract
    function initialize() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice blacklist the multiple owners or NFT token ids
    /// @dev the input list was limited as MAX_INPUT_LENGTH
    /// @param _inputs the list of inputs to blacklist
    function blacklistNFTs(Input[] memory _inputs) external onlyAdmin {
        require(
            _inputs.length > 0 && _inputs.length <= MAX_INPUT_LENGTH,
            "Invalid input length"
        );

        for (uint256 i = 0; i < _inputs.length; i++) {
            //check if the input is valid
            require(
                canBlacklistNFT(
                    _inputs[i]._owner,
                    _inputs[i]._type,
                    _inputs[i]._token,
                    _inputs[i]._id
                ),
                string(
                    abi.encodePacked(
                        "NFT(",
                        Strings.toString(i),
                        ") can't be blacklisted"
                    )
                )
            );

            _doBlacklistNFT(
                _inputs[i]._owner,
                _inputs[i]._type,
                _inputs[i]._token,
                _inputs[i]._id,
                _inputs[i]._enable
            );
        }
    }

    /// @notice determine if the NFT can be blacklisted
    /// @param _owner the owner of the NFT
    /// @param _type the type of the NFT
    /// @param _token the token contract address of the NFT
    /// @param _id the token id of the NFT
    /// @return whether the NFT can be blacklisted
    function canBlacklistNFT(
        address _owner,
        NFT_TYPE _type,
        address _token,
        uint256 _id
    ) public view returns (bool) {
        if (
            //make sure the owner is valid
            _owner == address(0) ||
            //can't blacklist this contract and any admin
            _owner == address(this) ||
            isAdmin(_owner)
        ) {
            return false;
        }

        //don't check anything else if type is ALL
        if (_type == NFT_TYPE.ALL) {
            return true;
        }

        //check if the token is valid contract address
        if (_token == address(0) || !_token.isContract()) {
            return false;
        }
        //ignore the checking for ANY_TOKEN_ID
        else if (_id == ANY_TOKEN_ID) {
            return true;
        }
        //case for ERC721
        else if (_type == NFT_TYPE.ERC721) {
            //verify that token is owned by that owner
            try IERC721(_token).ownerOf(_id) returns (address _tokenOwner) {
                return _owner == _tokenOwner;
            } catch {
                return false;
            }
        }
        //case for ERC1155
        /*if (_type == NFT_TYPE.ERC1155)*/
        else {
            //verify that token is owned by that owner
            try IERC1155(_token).balanceOf(_owner, _id) returns (
                uint256 _balanceOf
            ) {
                return _balanceOf > 0;
            } catch {
                return false;
            }
        }
    }

    /// @notice do the blacklist procedure
    /// @param _owner the owner of the NFT
    /// @param _type the type of the NFT
    /// @param _token the token contract address of the NFT
    /// @param _id the token id of the NFT
    /// @param _enable whether to enable or disable the blacklist
    function _doBlacklistNFT(
        address _owner,
        NFT_TYPE _type,
        address _token,
        uint256 _id,
        bool _enable
    ) internal {
        if (_type == NFT_TYPE.ALL) {
            // use token address as 0 and token id as 0 to blacklist all NFTs of that owner
            blacklist[
                getBlacklistKey(_owner, address(0), ANY_TOKEN_ID)
            ] = _enable;

            emit NFTBlacklisted(_owner, address(0), ANY_TOKEN_ID, _enable);
        } else {
            blacklist[getBlacklistKey(_owner, _token, _id)] = _enable;

            emit NFTBlacklisted(_owner, _token, _id, _enable);
        }
    }

    /// @notice disable the blacklist contract
    /// @param _status assign the disabled status to this value
    function setDisabled(bool _status) external onlyAdmin {
        disabled = _status;

        emit ContractDisabled(_status);
    }

    /// @notice get the blacklist record of the NFT
    /// @param _owner the owner of the NFT
    /// @param _token the token contract address of the NFT
    /// @param _id the token id of the NFT
    /// @return whether the NFT is blacklisted
    function blacklistedNFT(
        address _owner,
        address _token,
        uint256 _id
    ) external view returns (bool) {
        // return false if the contract is disabled
        if (disabled) {
            return false;
        }

        return
            //determine that owner was blacklisted or not
            blacklist[getBlacklistKey(_owner, address(0), ANY_TOKEN_ID)] ||
            //determine that all ids of token was blacklisted or not
            blacklist[getBlacklistKey(_owner, _token, ANY_TOKEN_ID)] ||
            //determine that specified token id was blacklisted or not
            blacklist[getBlacklistKey(_owner, _token, _id)];
    }

    /// @notice get the hash key of the blacklist record
    /// @param _owner the owner of the NFT
    /// @param _token the token contract address of the NFT
    /// @param _id the token id of the NFT
    /// @return the hash key of the blacklist record
    function getBlacklistKey(
        address _owner,
        address _token,
        uint256 _id
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_owner, _token, _id));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./utils/AccessProtectedUpgradable.sol";

import "./interfaces/ITokenReceiptable.sol";

/// @title Contract for Token Receipt Handler
/// @notice This contract is used to handle token receipts for mint or burn.
contract TokenReceiptHandler is
    Initializable,
    UUPSUpgradeable,
    AccessProtectedUpgradable
{
    using AddressUpgradeable for address;

    /// @notice The mapping of token to receipt contract
    mapping(address => ITokenReceiptable) internal tokenReceiptables;

    /// @notice This event will be emitted when token receipt was setup
    /// @param originalToken Address of the original token
    /// @param receiptToken Address of the token receipt
    event SetupTokenReceipt(address originalToken, address receiptToken);

    /// @notice This event will be emitted when receipt is created.
    /// @param user The user who own the receipt.
    /// @param originalToken The original token address
    /// @param receiptToken The receipt token address
    /// @param tokenId The token id of the receipt.
    /// @param amount The amount of the receipt.
    event CreateReceipt(
        address indexed user,
        address originalToken,
        address receiptToken,
        uint256 tokenId,
        uint256 amount
    );

    /// @notice This event will be emitted when receipt is burnt.
    /// @param user The user who own the receipt.
    /// @param originalToken The original token address
    /// @param receiptToken The receipt token address
    /// @param tokenId The token id of the receipt.
    /// @param amount The amount of the receipt.
    event BurnReceipt(
        address indexed user,
        address originalToken,
        address receiptToken,
        uint256 tokenId,
        uint256 amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev Initialize the contract
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice Setup token receipt
    /// @param _originalToken Address of the original token
    /// @param _receiptToken Address of the token receipt
    function setupTokenReceipt(address _originalToken, address _receiptToken)
        external
        onlyAdmin
    {
        require(
            _originalToken.isContract() && _receiptToken.isContract(),
            "Token must be a contract"
        );

        ITokenReceiptable tokenReceiptable = ITokenReceiptable(_receiptToken);
        require(
            tokenReceiptable.originalToken() == _originalToken,
            "ITokenReceiptable should be came from same original token"
        );

        tokenReceiptables[_originalToken] = tokenReceiptable;

        emit SetupTokenReceipt(_originalToken, _receiptToken);
    }

    /// @notice Create receipts as a proof for assets when stakeholder want to stake some assets
    /// @param _stakeholder The user who stake the asset
    /// @param _assetAddress The address of the asset
    /// @param _tokenIds The token id of the asset
    /// @param _amounts The amount of the asset
    function createReceipts(
        address _stakeholder,
        address _assetAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(
            address(tokenReceiptables[_assetAddress]) != address(0),
            "Token receipt is not setup"
        );

        require(
            _tokenIds.length == _amounts.length && _tokenIds.length > 0,
            "tokenIds and amounts should be same length and greater than 0"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            emit CreateReceipt(
                _stakeholder,
                _assetAddress,
                address(tokenReceiptables[_assetAddress]),
                _tokenIds[i],
                _amounts[i]
            );

            tokenReceiptables[_assetAddress].mintForReceipt(
                _stakeholder,
                _tokenIds[i],
                _amounts[i]
            );
        }
    }

    /// @notice Burn receipts as a proof for assets when stakeholder want to unstake some assets
    /// @param _stakeholder The user who stake the asset
    /// @param _assetAddress The address of the asset
    /// @param _tokenIds The token id of the asset
    /// @param _amounts The amount of the asset
    function burnReceipts(
        address _stakeholder,
        address _assetAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(
            address(tokenReceiptables[_assetAddress]) != address(0),
            "Token receipt is not setup"
        );

        require(
            _tokenIds.length == _amounts.length && _tokenIds.length > 0,
            "tokenIds and amounts should be same length and greater than 0"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            emit BurnReceipt(
                _stakeholder,
                _assetAddress,
                address(tokenReceiptables[_assetAddress]),
                _tokenIds[i],
                _amounts[i]
            );

            tokenReceiptables[_assetAddress].burnForReceipt(
                _stakeholder,
                _tokenIds[i],
                _amounts[i]
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtectedUpgradable is OwnableUpgradeable {
    mapping(address => bool) internal _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Admin
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether user has admin access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "Caller does not have Admin Access"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
pragma solidity ^0.8.4;

/// @title Interface for Receipt Token
/// @notice This interface is used to extend for Receipt Token
interface ITokenReceiptable {
    /// @dev The address of the original token
    /// @return The address of the original token
    function originalToken() external view returns (address);

    /// @dev Mint function for TokenReceiptHandler
    /// @param receiptTo Create receipt for this address
    /// @param tokenId The token id for receipt
    /// @param amount The amount of tokens for receipt
    function mintForReceipt(
        address receiptTo,
        uint256 tokenId,
        uint256 amount
    ) external;

    /// @dev Burn function for TokenReceiptHandler
    /// @param receiptFrom Burn receipt for this address
    /// @param tokenId The token id for receipt
    /// @param amount The amount of tokens for receipt
    function burnForReceipt(
        address receiptFrom,
        uint256 tokenId,
        uint256 amount
    ) external;
}