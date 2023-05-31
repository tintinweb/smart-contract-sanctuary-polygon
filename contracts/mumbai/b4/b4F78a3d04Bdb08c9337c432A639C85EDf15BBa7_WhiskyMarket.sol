// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";


// File contracts/roles/WhiskyTreasuryNode.sol
/**
 * @notice A mixin that stores a reference to the Whisky treasury contract.
 */
abstract contract WhiskyTreasuryNode is Initializable {
    using AddressUpgradeable for address payable;

    address payable private treasury;

    /**
     * @dev Called once after the initial deployment to set the Whisky treasury address.
     */
    function _initializeWhiskyTreasuryNode(address payable _treasury)
        internal
        initializer
    {
        require(
            _treasury.isContract(),
            "WhiskyTreasuryNode: Address is not a contract"
        );
        treasury = _treasury;
    }

    /**
     * @notice Returns the address of the Whisky treasury.
     */
    function getWhiskyTreasury() public view returns (address payable) {
        return treasury;
    }

    // `______gap` is added to each mixin to allow adding new data slots or additional mixins in an upgrade-safe way.
    uint256[2000] private __gap;
}

// File contracts/interfaces/IAdminRole.sol
/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAdminRole {
    function isAdmin(address account) external view returns (bool);
}

// File contracts/roles/WhiskyAdminRole.sol
/**
 * @notice Allows a contract to leverage the admin role defined by the Whisky treasury.
 */
abstract contract WhiskyAdminRole is WhiskyTreasuryNode {
    // This file uses 0 data slots (other than what's included via WhiskyTreasuryNode)

    modifier onlyWhiskyAdmin() {
        require(
            _isWhiskyAdmin(),
            "WhiskyAdminRole: caller does not have the Admin role"
        );
        _;
    }

    function _isWhiskyAdmin() internal view returns (bool) {
        return IAdminRole(getWhiskyTreasury()).isAdmin(msg.sender);
    }
}

// File contracts/interfaces/IOperatorRole.sol
/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IOperatorRole {
    function isOperator(address account) external view returns (bool);
}

// File contracts/roles/WhiskyOperatorRole.sol
/**
 * @notice Allows a contract to leverage the operator role defined by the Whisky treasury.
 */
abstract contract WhiskyOperatorRole is WhiskyTreasuryNode {
    // This file uses 0 data slots (other than what's included via WhiskyTreasuryNode)

    function _isWhiskyOperator() internal view returns (bool) {
        return IOperatorRole(getWhiskyTreasury()).isOperator(msg.sender);
    }
}

// File contracts/mixins/NFTMarketCore.sol
/**
 * @notice A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTMarketCore {
    /**
     * @dev If the auction did not have an escrowed seller to return, this falls back to return the current owner.
     * This allows functions to calculate the correct fees before the NFT has been listed in auction.
     */
    function _getSellerFor(address nftContract, uint256 tokenId)
        internal
        view
        virtual
        returns (address payable)
    {
        return payable(IERC721Upgradeable(nftContract).ownerOf(tokenId));
    }

    // 50 slots were consumed by adding ReentrancyGuardUpgradeable
    uint256[950] private ______gap;
}

// File contracts/mixins/SendValueWithFallbackWithdraw.sol
/**
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address payable;
    using SafeMathUpgradeable for uint256;

    mapping(address => uint256) private pendingWithdrawals;

    event WithdrawPending(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    /**
     * @notice Returns how much funds are available for manual withdraw due to failed transfers.
     */
    function getPendingWithdrawal(address user) public view returns (uint256) {
        return pendingWithdrawals[user];
    }

    /**
     * @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
     */
    function withdraw() public {
        withdrawFor(payable(msg.sender));
    }

    /**
     * @notice Allows anyone to manually trigger a withdrawal of funds which originally failed to transfer for a user.
     */
    function withdrawFor(address payable user) public nonReentrant {
        uint256 amount = pendingWithdrawals[user];
        require(amount > 0, "No funds are pending withdrawal");
        pendingWithdrawals[user] = 0;
        user.sendValue(amount);
        emit Withdrawal(user, amount);
    }

    /**
     * @dev Attempt to send a user ETH with a reasonably low gas limit of 20k,
     * which is enough to send to contracts as well.
     */
    function _sendValueWithFallbackWithdrawWithLowGasLimit(
        address mode,
        address payable user,
        uint256 amount
    ) internal {
        _sendValueWithFallbackWithdraw(mode, user, amount, 20000);
    }

    /**
     * @dev Attempt to send a user or contract ETH with a moderate gas limit of 90k,
     * which is enough for a 5-way split.
     */
    function _sendValueWithFallbackWithdrawWithMediumGasLimit(
        address paymentMode,
        address payable user,
        uint256 amount
    ) internal {
        _sendValueWithFallbackWithdraw(paymentMode, user, amount, 210000);
    }

    /**
     * @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later withdrawal.
     */
    function _sendValueWithFallbackWithdraw(
        address mode,
        address payable user,
        uint256 amount,
        uint256 gasLimit
    ) private {
        if (amount == 0) {
            return;
        }
        if (mode == address(0)) {
            // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = user.call{value: amount, gas: gasLimit}("");
            if (!success) {
                // Record failed sends for a withdrawal later
                // Transfers could fail if sent to a multisig with non-trivial receiver logic
                // solhint-disable-next-line reentrancy
                pendingWithdrawals[user] = pendingWithdrawals[user].add(amount);
                emit WithdrawPending(user, amount);
            }
        } else {
            require(IERC20(mode).transfer(user, amount));
        }
    }

    uint256[499] private ______gap;
}

// File contracts/interfaces/IFNDNFT721.sol
// solhint-disable
interface IFNDNFT721 {
    function tokenCreator(uint256 tokenId)
        external
        view
        returns (address payable);

    function getTokenCreatorPaymentAddress(uint256 tokenId)
        external
        view
        returns (address payable);

    function getTokenRoyalty(uint256 tokenId)
        external
        view
        returns (uint256);
}

// File contracts/mixins/NFTMarketCreators.sol
/**
 * @notice A mixin for associating creators to NFTs.
 * @dev In the future this may store creators directly in order to support NFTs created on a different platform.
 */
abstract contract NFTMarketCreators is
    ReentrancyGuardUpgradeable // Adding this unused mixin to help with linearization
{
    /**
     * @dev If the creator is not available then 0x0 is returned. Downstream this indicates that the creator
     * fee should be sent to the current seller instead.
     * This may apply when selling NFTs that were not minted on Whisky.
     */
    function _getCreator(address nftContract, uint256 tokenId)
        internal
        view
        returns (address payable)
    {
        try IFNDNFT721(nftContract).tokenCreator(tokenId) returns (
            address payable creator
        ) {
            return creator;
        } catch {
            return payable(address(0));
        }
    }

    /**
     * @dev Returns the creator and a destination address for any payments to the creator,
     * returns address(0) if the creator is unknown.
     */
    function _getCreatorAndPaymentAddress(address nftContract, uint256 tokenId)
        internal
        view
        returns (address payable, address payable)
    {
        address payable creator = _getCreator(nftContract, tokenId);
        try
            IFNDNFT721(nftContract).getTokenCreatorPaymentAddress(tokenId)
        returns (address payable tokenCreatorPaymentAddress) {
            if (tokenCreatorPaymentAddress != address(0)) {
                return (creator, tokenCreatorPaymentAddress);
            }
        } catch // solhint-disable-next-line no-empty-blocks
        {
            // Fall through to return (creator, creator) below
        }
        return (creator, creator);
    }

    // 500 slots were added via the new SendValueWithFallbackWithdraw mixin
    uint256[500] private ______gap;
}

// File contracts/mixins/Constants.sol
/**
 * @dev Constant values shared across mixins.
 */
abstract contract Constants {
    uint256 internal constant BASIS_POINTS = 10000;
}

// File contracts/mixins/NFTMarketFees.sol
/**
 * @notice A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is
    Constants,
    Initializable,
    WhiskyTreasuryNode,
    NFTMarketCore,
    NFTMarketCreators,
    SendValueWithFallbackWithdraw
{
    using SafeMathUpgradeable for uint256;

    event MarketFeesUpdated(
        uint256 primaryWhiskyFeeBasisPoints,
        uint256 secondaryWhiskyFeeBasisPoints
    );

    uint256 private _primaryWhiskyFeeBasisPoints;
    uint256 private _secondaryWhiskyFeeBasisPoints;

    mapping(address => mapping(uint256 => bool))
        private nftContractToTokenIdToFirstSaleCompleted;

    /**
     * @notice Returns true if the given NFT has not been sold in this market previously and is being sold by the creator.
     */
    function getIsPrimary(address nftContract, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return
            _getIsPrimary(
                nftContract,
                tokenId,
                _getCreator(nftContract, tokenId),
                _getSellerFor(nftContract, tokenId)
            );
    }

    /**
     * @dev A helper that determines if this is a primary sale given the current seller.
     * This is a minor optimization to use the seller if already known instead of making a redundant lookup call.
     */
    function _getIsPrimary(
        address nftContract,
        uint256 tokenId,
        address creator,
        address seller
    ) private view returns (bool) {
        return
            !nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId] &&
            creator == seller;
    }

    /**
     * @notice Returns the current fee configuration in basis points.
     */
    function getFeeConfig(address nftContract, uint256 tokenId)
        public
        view
        returns (
            uint256 primaryWhiskyFeeBasisPoints,
            uint256 secondaryWhiskyFeeBasisPoints,
            uint256 secondaryCreatorFeeBasisPoints
        )
    {
        return (
            _primaryWhiskyFeeBasisPoints,
            _secondaryWhiskyFeeBasisPoints,
            IFNDNFT721(nftContract).getTokenRoyalty(tokenId)
        );
    }

    /**
     * @notice Returns the fees of foundation in basis points
     */

    function getWhiskyFees() public 
    view 
    returns(uint256 primaryWhiskyFeeBasisPoints, 
    uint256 secondaryWhiskyFeeBasisPoints
    )
    {
        return (
            _primaryWhiskyFeeBasisPoints,
            _secondaryWhiskyFeeBasisPoints
        );
    }

    /**
     * @notice Returns how funds will be distributed for a sale at the given price point.
     * @dev This could be used to present exact fee distributing on listing or before a bid is placed.
     */
    function getFees(
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
        public
        view
        returns (
            uint256 foundationFee,
            uint256 creatorSecondaryFee,
            uint256 ownerRev
        )
    {
        (foundationFee, , creatorSecondaryFee, , ownerRev) = _getFees(
            nftContract,
            tokenId,
            _getSellerFor(nftContract, tokenId),
            price
        );
    }

    /**
     * @dev Calculates how funds should be distributed for the given sale details.
     * If this is a primary sale, the creator revenue will appear as `ownerRev`.
     */
    function _getFees(
        address nftContract,
        uint256 tokenId,
        address payable seller,
        uint256 price
    )
        private
        view
        returns (
            uint256 foundationFee,
            address payable creatorSecondaryFeeTo,
            uint256 creatorSecondaryFee,
            address payable ownerRevTo,
            uint256 ownerRev
        )
    {
        // The tokenCreatorPaymentAddress replaces the creator as the fee recipient.
        (
            address payable creator,
            address payable tokenCreatorPaymentAddress
        ) = _getCreatorAndPaymentAddress(nftContract, tokenId);
        uint256 foundationFeeBasisPoints;
        if (_getIsPrimary(nftContract, tokenId, creator, seller)) {
            foundationFeeBasisPoints = _primaryWhiskyFeeBasisPoints;
            // On a primary sale, the creator is paid the remainder via `ownerRev`.
            ownerRevTo = tokenCreatorPaymentAddress;
        } else {
            uint256 secondaryCreatorFeeBasisPoints = IFNDNFT721(nftContract).getTokenRoyalty(tokenId);
            foundationFeeBasisPoints = _secondaryWhiskyFeeBasisPoints;

            // If there is no creator then funds go to the seller instead.
            if (tokenCreatorPaymentAddress != address(0)) {
                // SafeMath is not required when dividing by a constant value > 0.
                creatorSecondaryFee =
                    price.mul(secondaryCreatorFeeBasisPoints) /
                    BASIS_POINTS;
                creatorSecondaryFeeTo = tokenCreatorPaymentAddress;
            }

            if (seller == creator) {
                ownerRevTo = tokenCreatorPaymentAddress;
            } else {
                ownerRevTo = seller;
            }
        }
        // SafeMath is not required when dividing by a constant value > 0.
        foundationFee = price.mul(foundationFeeBasisPoints) / BASIS_POINTS;
        ownerRev = price.sub(foundationFee).sub(creatorSecondaryFee);
    }

    /**
     * @dev Distributes funds to foundation, creator, and NFT owner after a sale.
     */
    function _distributeFunds(
        address mode,
        address nftContract,
        uint256 tokenId,
        address payable seller,
        uint256 price
    )
        internal
        returns (
            uint256 foundationFee,
            uint256 creatorFee,
            uint256 ownerRev
        )
    {
        address payable creatorFeeTo;
        address payable ownerRevTo;
        (
            foundationFee,
            creatorFeeTo,
            creatorFee,
            ownerRevTo,
            ownerRev
        ) = _getFees(nftContract, tokenId, seller, price);

        // Anytime fees are distributed that indicates the first sale is complete,
        // which will not change state during a secondary sale.
        // This must come after the `_getFees` call above as this state is considered in the function.
        nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId] = true;

        _sendValueWithFallbackWithdrawWithLowGasLimit(
            mode,
            getWhiskyTreasury(),
            foundationFee
        );
        _sendValueWithFallbackWithdrawWithMediumGasLimit(
            mode,
            creatorFeeTo,
            creatorFee
        );
        _sendValueWithFallbackWithdrawWithMediumGasLimit(
            mode,
            ownerRevTo,
            ownerRev
        );
    }


    /**
     * @notice Allows Whisky to change the market fees.
     */
    function _updateMarketFees(
        uint256 primaryWhiskyFeeBasisPoints,
        uint256 secondaryWhiskyFeeBasisPoints
    ) internal {
        require(
            primaryWhiskyFeeBasisPoints < BASIS_POINTS,
            "NFTMarketFees: Fees >= 100%"
        );

        require(
            secondaryWhiskyFeeBasisPoints < BASIS_POINTS,
            "NFTMarketFees: Fees >= 100%"
        );

        _primaryWhiskyFeeBasisPoints = primaryWhiskyFeeBasisPoints;
        _secondaryWhiskyFeeBasisPoints = secondaryWhiskyFeeBasisPoints;

        emit MarketFeesUpdated(
            primaryWhiskyFeeBasisPoints,
            secondaryWhiskyFeeBasisPoints
        );
    }

    uint256[1000] private ______gap;
}

/**
 * @notice Adds support for a private sale of an NFT directly between two parties.
 */
abstract contract NFTMarketPrivateSale is NFTMarketFees {
    /**
     * @dev This name is used in the EIP-712 domain.
     * If multiple classes use EIP-712 signatures in the future this can move to the shared constants file.
     */
    string private constant NAME = "WhiskyMarket";
    /**
     * @dev This is a hash of the method signature used in the EIP-712 signature for private sales.
     */
    bytes32 private constant BUY_FROM_PRIVATE_SALE_TYPEHASH =
        keccak256(
            "BuyFromPrivateSale(address nftContract,uint256 tokenId,address buyer,uint256 price,uint256 deadline)"
        );

    /**
     * @dev This is the domain used in EIP-712 signatures.
     * It is not a constant so that the chainId can be determined dynamically.
     * If multiple classes use EIP-712 signatures in the future this can move to a shared file.
     */
    bytes32 private DOMAIN_SEPARATOR;

    event PrivateSaleFinalized(
        address paymentMode,
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 creatorFee,
        uint256 ownerRev,
        uint256 deadline
    );

    /**
     * @dev This function must be called at least once before signatures will work as expected.
     * It's okay to call this function many times. Subsequent calls will have no impact.
     */
    function _reinitialize() internal {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(NAME)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @notice Allow two parties to execute a private sale.
     * @dev The seller signs a message approving the sale, and then the buyer calls this function
     * with the msg.value equal to the agreed upon price.
     * The sale is executed in this single on-chain call including the transfer of funds and the NFT.
     */
    function buyFromPrivateSale(
        IERC721Upgradeable nftContract,
        address paymentMode,
        uint256 amount,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        // The signed message from the seller is only valid for a limited time.
        require(deadline >= block.timestamp, "NFTMarketPrivateSale:EXPIRED");
        // The seller must have the NFT in their wallet when this function is called.
        address payable seller = payable(nftContract.ownerOf(tokenId));

        if (paymentMode == address(0)) amount = msg.value;

        // Scoping this block to avoid a stack too deep error
        {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    // DOMAIN_SEPARATOR, //Need to be added in future
                    keccak256(
                        abi.encode(
                            BUY_FROM_PRIVATE_SALE_TYPEHASH,
                            nftContract,
                            tokenId,
                            // msg.sender,
                            amount,
                            deadline
                        )
                    )
                )
            );

            digest = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
            );
    
            // Revert if the signature is invalid, the terms are not as expected, or if the seller transferred the NFT.
            require(
                ecrecover(digest, v, r, s) == seller,
                "NFTMarketPrivateSale:INVALID_SIGNATURE"
            );
        }

        // This will revert if the seller has not given the market contract approval.
        nftContract.transferFrom(seller, msg.sender, tokenId);
        // Pay the seller, creator, and Whisky as appropriate.
        (
             ,
            uint256 creatorFee,
            uint256 ownerRev
        ) = _distributeFunds(
                paymentMode,
                address(nftContract),
                tokenId,
                seller,
                amount
            );

        emit PrivateSaleFinalized(
            paymentMode,
            address(nftContract),
            tokenId,
            seller,
            msg.sender,
            creatorFee,
            ownerRev,
            deadline
        );
    }

    uint256[1000] private ______gap;
}

// File contracts/mixins/NFTMarketAuction.sol
/**
 * @notice An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 */
abstract contract NFTMarketAuction {
    /**
     * @dev A global id for auctions of any type.
     */
    uint256 private nextAuctionId;

    function _initializeNFTMarketAuction() internal {
        nextAuctionId = 1;
    }

    function _getNextAndIncrementAuctionId() internal returns (uint256) {
        return nextAuctionId++;
    }

    uint256[1000] private ______gap;
}

// File contracts/mixins/AccountMigration.sol
/**
 * @notice Checks for a valid signature authorizing the migration of an account to a new address.
 * @dev This is shared by both the FNDNFT721 and FNDNFTMarket, and the same signature authorizes both.
 */
abstract contract AccountMigration is WhiskyOperatorRole {
    using AddressUpgradeable for address;
    // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/cryptography
    function _isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) private view returns (bool) {
        if (signer.isContract()) {
            try IERC1271(signer).isValidSignature(hash, signature) returns (
                bytes4 magicValue
            ) {
                return magicValue == IERC1271(signer).isValidSignature.selector;
            } catch {
                return false;
            }
        } else {
            return ECDSA.recover(hash, signature) == signer;
        }
    }

    // From https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
    function _toAsciiString(address x) private pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i + 2] = _char(hi);
            s[2 * i + 3] = _char(lo);
        }
        return string(s);
    }

    function _char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/cryptography/ECDSA.sol
    // Modified to accept messages (instead of the message hash)
    function _toEthSignedMessage(bytes memory message)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(message.length),
                    message
                )
            );
    }

    /**
     * @dev Confirms the msg.sender is a Whisky operator and that the signature provided is valid.
     * @param signature Message `I authorize Whisky to migrate my account to ${newAccount.address.toLowerCase()}`
     * signed by the original account.
     */
    modifier onlyAuthorizedAccountMigration(
        address originalAddress,
        address newAddress,
        bytes memory signature
    ) {
        require(
            _isWhiskyOperator(),
            "AccountMigration: Caller is not an operator"
        );
        bytes32 hash = _toEthSignedMessage(
            abi.encodePacked(
                "I authorize Whisky to migrate my account to ",
                _toAsciiString(newAddress)
            )
        );
        require(
            _isValidSignatureNow(originalAddress, hash, signature),
            "AccountMigration: Signature must be from the original account"
        );
        _;
    }
}

// File contracts/mixins/NFTMarketReserveAuction.sol
/**
 * @notice Manages a reserve price auction for NFTs.
 */
abstract contract NFTMarketReserveAuction is
    Constants,
    WhiskyAdminRole,
    AccountMigration,
    NFTMarketCore,
    ReentrancyGuardUpgradeable,
    SendValueWithFallbackWithdraw,
    NFTMarketFees,
    NFTMarketAuction
{
    using SafeMathUpgradeable for uint256;

    struct ReserveAuction {
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 startTime;
        uint256 endTime;
        address payable bidder;
        uint256 amount;
        address paymentMode;
    }

    mapping(address => mapping(uint256 => uint256))
        private nftContractToTokenIdToAuctionId;
    mapping(uint256 => ReserveAuction) private auctionIdToAuction;

    mapping(address => bool) public tokens;

    uint256 private _minPercentIncrementInBasisPoints;

    // This variable was used in an older version of the contract, left here as a gap to ensure upgrade compatibility
    uint256 private ______gap_was_maxBidIncrementRequirement;

    // These variables were used in an older version of the contract, left here as gaps to ensure upgrade compatibility
    uint256 private ______gap_was_goLiveDate;

    uint256 private EXTENSION_DURATION;

    event ReserveAuctionConfigUpdated(
        uint256 minPercentIncrementInBasisPoints,
        uint256 maxBidIncrementRequirement,
        uint256 duration,
        uint256 extensionDuration,
        uint256 goLiveDate
    );

    event ReserveAuctionCreated(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 reservePrice,
        uint256 auctionId,
        address paymentMode
    );
    event ReserveAuctionUpdated(
        uint256 indexed auctionId,
        uint256 reservePrice
    );
    event ReserveAuctionCanceled(uint256 indexed auctionId);
    
    event ReserveAuctionBidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        uint256 endTime
    );
    event ReserveAuctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 f8nFee,
        uint256 creatorFee,
        uint256 ownerRev
    );
    event ReserveAuctionCanceledByAdmin(
        uint256 indexed auctionId,
        string reason
    );
    event ReserveAuctionSellerMigrated(
        uint256 indexed auctionId,
        address indexed originalSellerAddress,
        address indexed newSellerAddress
    );
    event TokenUpdated(
        address indexed tokenAddress,
        bool indexed status
    );

    modifier onlyValidAuctionConfig(uint256 reservePrice) {
        require(
            reservePrice > 0,
            "NFTMarketReserveAuction: Reserve price must be at least 1 wei"
        );
        _;
    }

    /**
     * @notice Returns auction details for a given auctionId.
     */
    function getReserveAuction(uint256 auctionId)
        public
        view
        returns (ReserveAuction memory)
    {
        return auctionIdToAuction[auctionId];
    }

    /**
     * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
     * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
     */
    function getReserveAuctionIdFor(address nftContract, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return nftContractToTokenIdToAuctionId[nftContract][tokenId];
    }

    /**
     * @dev Returns the seller that put a given NFT into escrow,
     * or bubbles the call up to check the current owner if the NFT is not currently in escrow.
     */
    function _getSellerFor(address nftContract, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (address payable)
    {
        address payable seller = auctionIdToAuction[
            nftContractToTokenIdToAuctionId[nftContract][tokenId]
        ].seller;
        if (seller == address(0)) {
            return super._getSellerFor(nftContract, tokenId);
        }
        return seller;
    }

    /**
     * @notice Returns the current configuration for reserve auctions.
     */
    function getReserveAuctionConfig()
        public
        view
        returns (uint256 minPercentIncrementInBasisPoints, uint256 duration)
    {
        minPercentIncrementInBasisPoints = _minPercentIncrementInBasisPoints;
        duration = EXTENSION_DURATION;
    }

    function _updateReserveAuctionConfig(
        uint256 minPercentIncrementInBasisPoints,
        uint256 duration
    ) internal {
        require(
            minPercentIncrementInBasisPoints <= BASIS_POINTS,
            "NFTMarketReserveAuction: Min increment must be <= 100%"
        );

        _minPercentIncrementInBasisPoints = minPercentIncrementInBasisPoints;
        EXTENSION_DURATION = duration;

        // We continue to emit unused configuration variables to simplify the subgraph integration.
        emit ReserveAuctionConfigUpdated(
            minPercentIncrementInBasisPoints,
            0,
            duration,
            EXTENSION_DURATION,
            0
        );
    }

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     */
    function createReserveAuction(
        address nftContract,
        uint256 tokenId,
        uint256 reservePrice,
        uint256 startDate,
        uint256 endDate,
        address paymentMode
    ) public onlyValidAuctionConfig(reservePrice) nonReentrant {
        require(tokens[paymentMode], "NFTMarketReserveAuction:TOKEN_NOT_SUPPORTED");
        // If an auction is already in progress then the NFT would be in escrow and the modifier would have failed
        uint256 extraTimeForExecution = 10 minutes;
        require(
            startDate + extraTimeForExecution > block.timestamp &&
                endDate > startDate + EXTENSION_DURATION,
            "NFTMarketReserveAuction:INVALID_ENDDATE"
        );
        uint256 auctionId = _getNextAndIncrementAuctionId();
        nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
        auctionIdToAuction[auctionId] = ReserveAuction(
            nftContract,
            tokenId,
            payable(msg.sender),
            startDate,
            endDate, // endTime is only known once the reserve price is met
            payable(address(0)), // bidder is only known once a bid has been placed
            reservePrice,
            paymentMode
        );

        IERC721Upgradeable(nftContract).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit ReserveAuctionCreated(
                msg.sender,
                nftContract,
                tokenId,
                reservePrice,
                auctionId,
                paymentMode
            );
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the configuration
     * such as the reservePrice may be changed by the seller.
     */
    function updateReserveAuction(uint256 auctionId, uint256 reservePrice)
        public
        onlyValidAuctionConfig(reservePrice)
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "NFTMarketReserveAuction:NOT_YOUR_AUCTION"
        );
        require(
            auction.startTime > block.timestamp,
            "NFTMarketReserveAuction:AUCTION_IN_PROGRESS"
        );

        auction.amount = reservePrice;

        emit ReserveAuctionUpdated(auctionId, reservePrice);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * The NFT is returned to the seller from escrow.
     */
    function cancelReserveAuction(uint256 auctionId) public nonReentrant {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "NFTMarketReserveAuction:CANCEL_NOT_ALLOWED_DIFFERENT_OWNER"
        );
        require(
            auction.bidder == address(0),
            "NFTMarketReserveAuction:AUCTION_IN_PROGRESS"
        );

        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        IERC721Upgradeable(auction.nftContract).transferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        emit ReserveAuctionCanceled(auctionId);
    }

    /**
     * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the auction, the countdown may be extended.
     */
    function placeBid(uint256 amount, uint256 auctionId)
        public
        payable
        nonReentrant
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        require(
            auction.amount != 0,
            "NFTMarketReserveAuction:AUCTION_NOT_FOUND"
        );
        require(
            auction.startTime <= block.timestamp &&
                auction.endTime >= block.timestamp,
            "NFTMarketReserveAuction:AUCTION_NOT_LIVE"
        );

        uint256 minAmount = _getMinBidAmountForReserveAuction(auction.amount);
        if (auction.paymentMode == address(0)) {
            amount = msg.value;
        }
        require(
            amount >= minAmount,
            "NFTMarketReserveAuction:BID_AMOUNT_TOO_LOW"
        );

        // Cache and update bidder state before a possible reentrancy (via the value transfer)
        uint256 originalAmount = auction.amount;
        address payable originalBidder = auction.bidder;
        if (auction.paymentMode != address(0)) {
            IERC20(auction.paymentMode).transferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
        auction.amount = amount;
        auction.bidder = payable(msg.sender);

        if (originalBidder != address(0)) {
            // Refund the previous bidders
            _sendValueWithFallbackWithdrawWithLowGasLimit(
                auction.paymentMode,
                originalBidder,
                originalAmount
            );
        }

        emit ReserveAuctionBidPlaced(
            auctionId,
            msg.sender,
            amount,
            block.timestamp
        );
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute funds.
     */
    function finalizeReserveAuction(uint256 auctionId) public nonReentrant {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.endTime > 0,
            "NFTMarketReserveAuction:AUCTION_ALREADY_SETTLED"
        );
        require(
            auction.endTime < block.timestamp,
            "NFTMarketReserveAuction:AUCTION_IN_PROGRESS"
        );

        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        IERC721Upgradeable(auction.nftContract).transferFrom(
            address(this),
            auction.bidder,
            auction.tokenId
        );

        (
            uint256 f8nFee,
            uint256 creatorFee,
            uint256 ownerRev
        ) = _distributeFunds(
                auction.paymentMode,
                auction.nftContract,
                auction.tokenId,
                auction.seller,
                auction.amount
            );

        emit ReserveAuctionFinalized(
            auctionId,
            auction.seller,
            auction.bidder,
            f8nFee,
            creatorFee,
            ownerRev
        );
    }

    /**
     * @notice Returns the minimum amount a bidder must spend to participate in an auction.
     */
    function getMinBidAmount(uint256 auctionId) public view returns (uint256) {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.endTime < block.timestamp) {
            return auction.amount;
        }
        return _getMinBidAmountForReserveAuction(auction.amount);
    }

    /**
     * @dev Determines the minimum bid amount when outbidding another user.
     */
    function _getMinBidAmountForReserveAuction(uint256 currentBidAmount)
        private
        view
        returns (uint256)
    {
        uint256 minIncrement = currentBidAmount.mul(
            _minPercentIncrementInBasisPoints
        ) / BASIS_POINTS;
        if (minIncrement == 0) {
            // The next bid must be at least 1 wei greater than the current.
            return currentBidAmount.add(1);
        }
        return minIncrement.add(currentBidAmount);
    }

    /**
     * @notice Allows Whisky to add token address.
     */
    function adminUpdateToken(address tokenAddress, bool status)
        public
        onlyWhiskyAdmin
    {
        tokens[tokenAddress] = status;
        if (tokenAddress == address(0)) {
            emit TokenUpdated(tokenAddress, status);
        } else {
            emit TokenUpdated(
                tokenAddress,
                status
            );
        }
    }

    /**
     * @notice Allows Whisky to cancel an auction, refunding the bidder and returning the NFT to the seller.
     * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
     */
    function adminCancelReserveAuction(uint256 auctionId, string memory reason)
        public
        onlyWhiskyAdmin
    {
        require(
            bytes(reason).length > 0,
            "NFTMarketReserveAuction:INCLUDE_A_REASON_FOR_THIS_CANCELLATION"
        );
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.amount > 0,
            "NFTMarketReserveAuction:AUCTION_NOT_FOUND"
        );

        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        IERC721Upgradeable(auction.nftContract).transferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );
        if (auction.bidder != address(0)) {
            _sendValueWithFallbackWithdrawWithMediumGasLimit(
                auction.paymentMode,
                auction.bidder,
                auction.amount
            );
        }

        emit ReserveAuctionCanceledByAdmin(auctionId, reason);
    }

    /**
     * @notice Allows an NFT owner and Whisky to work together in order to update the seller
     * for auctions they have listed to a new account.
     * @param signature Message `I authorize Whisky to migrate my account to ${newAccount.address.toLowerCase()}`
     * signed by the original account.
     * @dev This will gracefully skip any auctions that have already been finalized.
     */
    function adminAccountMigration(
        uint256[] calldata listedAuctionIds,
        address originalAddress,
        address payable newAddress,
        bytes calldata signature
    )
        public
        onlyAuthorizedAccountMigration(originalAddress, newAddress, signature)
    {
        for (uint256 i = 0; i < listedAuctionIds.length; i++) {
            uint256 auctionId = listedAuctionIds[i];
            ReserveAuction storage auction = auctionIdToAuction[auctionId];
            // The seller would be 0 if it was finalized before this call
            if (auction.seller != address(0)) {
                require(
                    auction.seller == originalAddress,
                    "NFTMarketReserveAuction:AUCTION_NOT_CREATED_BY_THAT_ADDRESS"
                );
                auction.seller = newAddress;
                emit ReserveAuctionSellerMigrated(
                    auctionId,
                    originalAddress,
                    newAddress
                );
            }
        }
    }

    uint256[1000] private ______gap;
}

// File contracts/FNDNFTMarket.sol
pragma abicoder v2; // solhint-disable-line

/**
 * @title A market for NFTs on Whisky.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract WhiskyMarket is
    WhiskyTreasuryNode,
    WhiskyAdminRole,
    WhiskyOperatorRole,
    AccountMigration,
    NFTMarketCore,
    ReentrancyGuardUpgradeable,
    NFTMarketCreators,
    SendValueWithFallbackWithdraw,
    NFTMarketFees,
    NFTMarketAuction,
    NFTMarketReserveAuction,
    NFTMarketPrivateSale
{
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(address payable treasury) public initializer {
        WhiskyTreasuryNode._initializeWhiskyTreasuryNode(treasury);
        NFTMarketAuction._initializeNFTMarketAuction();
    }

    /**
     * @notice Allows Whisky to update the market configuration.
     */
    function adminUpdateConfig(
        uint256 minPercentIncrementInBasisPoints,
        uint256 duration,
        uint256 primaryF8nFeeBasisPoints,
        uint256 secondaryF8nFeeBasisPoints
    ) public onlyWhiskyAdmin {
        _reinitialize();
        _updateReserveAuctionConfig(minPercentIncrementInBasisPoints, duration);
        _updateMarketFees(
            primaryF8nFeeBasisPoints,
            secondaryF8nFeeBasisPoints
        );
    }

    /**
     * @dev Checks who the seller for an NFT is, this will check escrow or return the current owner if not in escrow.
     * This is a no-op function required to avoid compile errors.
     */
    function _getSellerFor(address nftContract, uint256 tokenId)
        internal
        view
        virtual
        override(NFTMarketCore, NFTMarketReserveAuction)
        returns (address payable)
    {
        return super._getSellerFor(nftContract, tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}