// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum ListStatus {
    NOT_LISTED,
    FIXED_PRICE,
    AUCTION
}

interface IVCMarketManager {
    function setAdmin(address _admin) external; // onlyAdmin

    function setPool(address _pool) external; // onlyAdmin

    function setStarter(address _starter) external; // onlyAdmin

    function changeMarketManager(address _mktManager) external; // onlyAdmin

    function setMarketplaceFixedPriceERC721(address _marketplaceFixedPriceERC721) external; // onlyAdmin

    function setMarketplaceAuctionERC1155(address _marketplaceAuctionERC1155) external; // onlyAdmin

    function setMarketplaceFixedPriceERC1155(address _marketplaceFixedPriceERC1155) external; // onlyAdmin

    function setMarketplaceFixedPricePocNft(address _marketplaceFixedPricePocNft) external; // onlyAdmin

    function setMarketplaceAuctionPocNft(address _marketplaceAuctionPocNft) external; // onlyAdmin

    function getMarketplaces() external view returns (address[5] memory marketplaces);

    function setArtNftERC721(address _artNftERC721) external; // onlyAdmin

    function setArtNftERC1155(address _artNftERC721) external; // onlyAdmin

    function callContract(address _contract, bytes calldata _data) external; // onlyAdmin

    function setPoCNft(address _pocNft) external; // onlyAdmin

    function setCurrency(IERC20 _currency) external; // onlyAdmin

    function setMinPoolFeeBps(uint96 _minTotalFeeBps) external; // onlyAdmin

    function setMarketplaceFeeBps(uint256 _marketplaceFeeBps) external; // onlyAdmin

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external; // onlyAdmin

    function accrueRoyalty(address _receiver, uint256 _royaltyAmount) external; // onlyMarketplaces

    function claimRoyalties(address _to, uint256 _poolAmount) external;

    function setListStatusERC721(uint256 _tokenId, bool listed) external; // only ERC721 marketplaces

    function getListStatusERC721(uint256 _tokenId) external view returns (ListStatus);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../utils/FeeManager.sol";
import "../interfaces/IVCMarketManager.sol";
import "../starter/IVCStarter.sol";
import "../utils/CanWithdrawERC20.sol";

struct TokenFeesData {
    uint256 poolFeeBps;
    uint256 starterFeeBps;
    address[] projects;
    uint256[] projectFeesBps;
}

error MktFeesDataError();
error MktRemoveProjectFailed();
error MktTotalFeeError();
error MktUnexpectedAddress();
error MktOnlyAdminAllowed();
error MktPoolTransferFailed();

contract FeeBeneficiary is FeeManager, CanWithdrawERC20 {
    /// @notice The Marketplace currency
    IERC20 public currency;

    /// @notice The admin of this contract is the VCMarketManager contract
    address public admin;

    /// @notice The VC Pool contract address
    address public pool;

    /// @notice The VC Starter contract address
    address public starter;

    /// @notice The minimum fee in basis points to distribute amongst VC Pool and VC Starter Projects
    uint256 public minPoolFeeBps;

    /// @notice The VC Marketplace fee in basis points
    uint256 public marketplaceFeeBps;

    /// @notice The maximum amount of projects a token seller can support
    uint96 public maxBeneficiaryProjects;

    event CurrencySet(address indexed oldCurrency, address indexed newCurrency);
    event MktPoolFunded(address indexed user, IERC20 indexed currency, uint256 amount);
    event MktProjectFunded(address indexed project, address indexed user, IERC20 indexed currency, uint256 amount);

    /**
     * @dev Maps a token and seller to its TokenFeesData struct.
     */
    mapping(uint256 => mapping(address => TokenFeesData)) _tokenFeesData;

    /**
     * @dev Constructor
     */
    constructor(
        address _admin,
        uint256 _minPoolFeeBps,
        uint256 _marketplaceFeeBps,
        uint96 _maxBeneficiaryProjects
    ) {
        _setAdmin(_admin);
        _setMinPoolFeeBps(_minPoolFeeBps);
        _setMarketplaceFeeBps(_marketplaceFeeBps);
        _setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
    }

    function setAdmin(address _admin) external {
        _onlyAdmin();
        _setAdmin(_admin);
    }

    function _setAdmin(address _admin) internal {
        _checkAddress(_admin);
        admin = _admin;
    }

    function setPool(address _pool) external {
        _onlyAdmin();
        _checkAddress(_pool);

        _setTo(_pool);
        pool = _pool;
    }

    function setStarter(address _starter) external {
        _onlyAdmin();
        _checkAddress(_starter);

        starter = _starter;
    }

    function setMinPoolFeeBps(uint96 _minPoolFeeBps) external {
        _onlyAdmin();

        _setMinPoolFeeBps(_minPoolFeeBps);
    }

    function setMarketplaceFeeBps(uint256 _marketplaceFee) external {
        _onlyAdmin();

        _setMarketplaceFeeBps(_marketplaceFee);
    }

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) public {
        _onlyAdmin();

        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev Returns the struct TokenFeesData corresponding to the _token and _tokenId
     *
     * @param _tokenId: Non-fungible token identifier
     */
    function getFeesData(uint256 _tokenId, address _seller) public view returns (TokenFeesData memory result) {
        return _tokenFeesData[_tokenId][_seller];
    }

    /**
     * @dev Constructs a `TokenFeesData` struct which stores the total fees in
     * bips that will be transferred to both the pool and the starter smart
     * contracts.
     *
     * @param _tokenId NFT token ID
     * @param _projects Array of Project addresses to support
     * @param _projectFeesBps Array of fees to support each project ID
     */
    function _setFees(
        uint256 _tokenId,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) internal returns (uint256) {
        if (_projects.length != _projectFeesBps.length || _projects.length > maxBeneficiaryProjects) {
            revert MktFeesDataError();
        }

        uint256 starterFeeBps;
        for (uint256 i = 0; i < _projectFeesBps.length; i++) {
            starterFeeBps += _projectFeesBps[i];
        }

        uint256 totalFeeBps = _poolFeeBps + starterFeeBps;

        if (_poolFeeBps < minPoolFeeBps || totalFeeBps > FEE_DENOMINATOR) {
            revert MktTotalFeeError();
        }

        _tokenFeesData[_tokenId][msg.sender] = TokenFeesData(_poolFeeBps, starterFeeBps, _projects, _projectFeesBps);

        return totalFeeBps;
    }

    /**
     * @dev Computes and transfers fees to both the Pool and the Starter smart contracts when the token is bought.
     *
     * @param _tokenId Non-fungible token identifier
     * @param _price Token price
     *
     * NOTE: Transfer fee from contract (Marketplace) itself.
     */
    function _transferFee(
        uint256 _tokenId,
        address _seller,
        address _buyer,
        uint256 _price,
        uint256 _starterFee,
        uint256 _poolFee,
        uint256 _mktFee
    ) internal returns (uint256 extraToPool) {
        if (_starterFee > 0) {
            TokenFeesData storage feesData = _tokenFeesData[_tokenId][_seller];
            extraToPool = _fundProjects(_seller, feesData, _price);
            _poolFee += extraToPool;
        }

        if (!currency.transfer(pool, _mktFee + _poolFee)) {
            revert MktPoolTransferFailed();
        }
        emit MktPoolFunded(_buyer, currency, _mktFee);
        if (_poolFee > 0) {
            emit MktPoolFunded(_seller, currency, _poolFee);
        }
    }

    /**
     * @dev Computes individual fees for each beneficiary project and performs
     * the pertinent accounting at the Starter smart contract.
     */
    function _fundProjects(
        address _seller,
        TokenFeesData storage _feesData,
        uint256 _listPrice
    ) internal returns (uint256 toPool) {
        bool[] memory activeProjects = IVCStarter(starter).areActiveProjects(_feesData.projects);

        for (uint256 i = 0; i < activeProjects.length; i++) {
            uint256 amount = _toFee(_listPrice, _feesData.projectFeesBps[i]);
            if (amount > 0) {
                if (activeProjects[i] == true) {
                    currency.approve(starter, amount);
                    IVCStarter(starter).fundProjectOnBehalf(_seller, _feesData.projects[i], amount);
                } else {
                    toPool += amount;
                }
            }
        }
    }

    function _checkAddress(address _address) internal view {
        if (_address == address(this) || _address == address(0)) {
            revert MktUnexpectedAddress();
        }
    }

    /**
     * @dev Sets the Marketplace currency.
     */
    function setCurrency(IERC20 _currency) external {
        _onlyAdmin();

        currency = _currency;
        emit CurrencySet(address(currency), address(_currency));
    }

    function _setMinPoolFeeBps(uint256 _minPoolFeeBps) private {
        minPoolFeeBps = _minPoolFeeBps;
    }

    function _setMarketplaceFeeBps(uint256 _marketplaceFeeBps) private {
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    function _setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) private {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev Splits an amount into fees for both Pool and Starter smart
     * contracts and a resulting amount to be transferred to the token
     * owner (i.e. the token seller).
     */
    function _splitListPrice(TokenFeesData memory _feesData, uint256 _listPrice)
        internal
        pure
        returns (
            uint256 starterFee,
            uint256 poolFee,
            uint256 resultingAmount
        )
    {
        starterFee = _toFee(_listPrice, _feesData.starterFeeBps);
        poolFee = _toFee(_listPrice, _feesData.poolFeeBps);
        resultingAmount = _listPrice - starterFee - poolFee;
    }

    function _onlyAdmin() internal view {
        if (msg.sender != admin) {
            revert MktOnlyAdminAllowed();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./VCMarketplaceBasePoCNft.sol";

contract VCMarketplaceAuctionPoCNft is VCMarketplaceBasePoCNft, ERC721Holder {
    error MktAlreadyListed();
    error MktExistingBid();
    error MktBidderNotAllowed();
    error MktBidTooLate();
    error MktBidTooLow();
    error MktSettleTooEarly();

    struct AuctionListing {
        address seller;
        uint256 initialPrice;
        uint256 maturity;
        address highestBidder;
        uint256 highestBid;
        uint256 marketplaceFeeBps;
        uint256 marketFee;
        uint256 starterFee;
        uint256 poolFee;
    }

    event ListedAuction(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 maturity,
        uint256 initialPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee
    );
    event UnlistedAuction(address indexed seller, address indexed token, uint256 indexed tokenId);
    event Bid(
        address indexed bidder,
        address indexed seller,
        uint256 indexed tokenId,
        address token,
        uint256 amount,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee
    );
    event Settled(
        address indexed buyer,
        address indexed seller,
        address indexed token,
        uint256 tokenId,
        uint256 endPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee
    );

    mapping(uint256 => AuctionListing) public auctionListings;

    constructor(
        address _admin,
        uint256 _minPoolFeeBps,
        uint256 _marketplaceFee,
        uint96 _maxBeneficiaryProjects
    ) FeeBeneficiary(_admin, _minPoolFeeBps, _marketplaceFee, _maxBeneficiaryProjects) {}

    /**
     * @dev Allows a token owner, i.e. msg.sender, to auction an ERC721 artNft with a given initial price and duration.
     *
     * @param _tokenId the token identifier
     * @param _initialPrice minimum price set by the seller
     * @param _biddingDuration duration of the auction in seconds
     * @param _projectIds Array of projects identifiers to support on purchases
     * @param _projectFeesBps Array of project fees in basis points on purchases
     */
    function listAuction(
        uint256 _tokenId,
        uint256 _initialPrice,
        uint256 _biddingDuration,
        uint256 _poolFeeBps,
        address[] calldata _projectIds,
        uint256[] calldata _projectFeesBps
    ) public whenNotPaused {
        // creator or collector cannot re-list
        if (auctionListings[_tokenId].seller != address(0)) {
            revert MktAlreadyListed();
        }

        _setFees(_tokenId, _poolFeeBps, _projectIds, _projectFeesBps);

        uint256 maturity = block.timestamp + _biddingDuration;

        _newList(_tokenId, _initialPrice, maturity);
    }

    /**
     * @dev Cancels the token auction from the Marketplace and sends back the
     * asset to the seller.
     *
     * Requirements:
     *
     * - The token must not have a bid placed, if there is a bid the transaction will fail
     *
     * @param _tokenId the token identifier
     */
    function unlistAuction(uint256 _tokenId) public {
        AuctionListing memory listing = auctionListings[_tokenId];

        if (listing.seller != msg.sender) {
            revert MktCallerNotSeller();
        }

        if (listing.highestBid != 0) {
            revert MktExistingBid();
        }

        delete auctionListings[_tokenId];

        IPoCNft(address(pocNft)).transferFrom(address(this), listing.seller, _tokenId);

        emit UnlistedAuction(msg.sender, address(pocNft), _tokenId);
    }

    /**
     * @dev Places a bid for a token listed in the Marketplace. If the bid is valid,
     * previous bid amount and its market fee gets returned back to previous bidder,
     * while current bid amount and market fee is charged to current bidder.
     *
     * @param _tokenId the token identifier
     * @param _amount the bid amount
     */
    function bid(uint256 _tokenId, uint256 _amount) public whenNotPaused {
        AuctionListing memory listing = auctionListings[_tokenId];

        _checkBeforeBid(listing, _amount);

        if (listing.highestBid != 0) {
            uint256 amountBack = listing.highestBid + listing.marketFee;
            currency.transfer(listing.highestBidder, amountBack);
            _balanceNotWithdrawable[currency] -= amountBack;
        }

        // pass listing.marketplaceFeeBps as argument to _getFees
        (uint256 marketFee, uint256 starterFee, uint256 poolFee) = _getFees(_tokenId, listing.seller, _amount);

        uint256 amountCharged = _amount + marketFee;
        currency.transferFrom(msg.sender, address(this), amountCharged);
        _balanceNotWithdrawable[currency] += amountCharged;

        listing.highestBidder = msg.sender;
        listing.highestBid = _amount;
        listing.marketFee = marketFee;
        listing.starterFee = starterFee;
        listing.poolFee = poolFee;
        auctionListings[_tokenId] = listing;

        emit Bid(msg.sender, listing.seller, _tokenId, address(pocNft), _amount, marketFee, starterFee, poolFee);
    }

    /**
     * @dev Allows anyone to settle the auction. If there are no bids, the seller
     * receives back the NFT
     *
     * @param _tokenId the token identifier
     */
    function settle(uint256 _tokenId) public whenNotPaused {
        AuctionListing memory listing = auctionListings[_tokenId];

        _checkBeforeSettle(listing);

        delete auctionListings[_tokenId];

        if (listing.highestBid != 0) {
            uint256 extraToPool = _settle(
                _tokenId,
                listing.seller,
                listing.highestBidder,
                listing.highestBid,
                listing.marketFee,
                listing.starterFee,
                listing.poolFee
            );

            listing.poolFee += extraToPool;
            listing.starterFee -= extraToPool;

            _minting(
                _tokenId,
                listing.highestBidder,
                listing.marketFee,
                listing.seller,
                listing.starterFee,
                listing.poolFee
            );
        } else {
            IPoCNft(address(pocNft)).transferFrom(address(this), listing.seller, _tokenId);
        }

        emit Settled(
            listing.highestBidder,
            listing.seller,
            address(pocNft),
            _tokenId,
            listing.highestBid,
            listing.marketFee,
            listing.starterFee,
            listing.poolFee
        );
    }

    function _newList(
        uint256 _tokenId,
        uint256 _initialPrice,
        uint256 _maturity
    ) internal {
        IPoCNft(address(pocNft)).transferFrom(msg.sender, address(this), _tokenId);

        (uint256 marketFee, uint256 starterFee, uint256 poolFee) = _getFees(_tokenId, msg.sender, _initialPrice);

        auctionListings[_tokenId] = AuctionListing(
            msg.sender,
            _initialPrice,
            _maturity,
            address(0),
            0,
            marketplaceFeeBps,
            marketFee,
            starterFee,
            poolFee
        );

        emit ListedAuction(
            address(pocNft),
            _tokenId,
            msg.sender,
            _maturity,
            _initialPrice,
            marketFee,
            starterFee,
            poolFee
        );
    }

    struct AuctionListing2 {
        address seller;
        uint256 initialPrice;
        uint256 maturity;
        address highestBidder;
        uint256 highestBid;
        uint256 marketplaceFeeBps;
        uint256 marketFee;
        uint256 starterFee;
        uint256 poolFee;
    }

    function _checkBeforeBid(AuctionListing memory listing, uint256 _amount) internal view {
        _checkAddressZero(listing.seller);
        if (listing.seller == msg.sender) {
            revert MktBidderNotAllowed();
        }
        if (block.timestamp > listing.maturity) {
            revert MktBidTooLate();
        }
        if (_amount <= listing.highestBid || _amount < listing.initialPrice) {
            revert MktBidTooLow();
        }
    }

    function _checkBeforeSettle(AuctionListing memory listing) internal view {
        _checkAddressZero(listing.seller);
        if (!(block.timestamp > listing.maturity)) {
            revert MktSettleTooEarly();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./FeeBeneficiary.sol";
import "../tokens/IPoCNft.sol";

abstract contract VCMarketplaceBasePoCNft is FeeBeneficiary, Pausable {
    error MktCallerNotSeller();
    error MktTokenNotListed();
    error MktSettleFailed();
    error MktPurchaseFailed();

    event PoCNftSet(address indexed oldPoCNft, address indexed newPoCNft);

    /// @notice The Viral(Cure) Proof of Collaboration Non-Fungible Token
    IPoCNft public pocNft;

    constructor() {}

    function pause(bool _paused) public {
        _onlyAdmin();

        if (_paused) _pause();
        else _unpause();
    }

    function setPoCNft(address _pocNft) external {
        _onlyAdmin();

        pocNft = IPoCNft(_pocNft);
        emit PoCNftSet(address(pocNft), _pocNft);
    }

    function _getFees(
        uint256 _tokenId,
        address _seller,
        uint256 _listPrice
    )
        internal
        view
        returns (
            uint256 marketFee,
            uint256 starterFee,
            uint256 poolFee
        )
    {
        marketFee = _toFee(_listPrice, marketplaceFeeBps);
        TokenFeesData memory feesData = _tokenFeesData[_tokenId][_seller];

        (starterFee, poolFee, ) = _splitListPrice(feesData, _listPrice);
    }

    function _settle(
        uint256 _tokenId,
        address _seller,
        address _highestBidder,
        uint256 _highestBid,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee
    ) internal returns (uint256 extraToPool) {
        extraToPool = _transferFee(_tokenId, _seller, _highestBidder, _highestBid, _starterFee, _poolFee, _marketFee);
        uint256 amountToSeller = _highestBid - _starterFee - _poolFee;

        if (!currency.transfer(_seller, amountToSeller)) {
            revert MktSettleFailed();
        }
    }

    function _purchase(
        uint256 _tokenId,
        address _seller,
        uint256 _listPrice,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee
    ) internal returns (uint256 extraToPool) {
        if (!currency.transferFrom(msg.sender, address(this), _listPrice + _marketFee)) {
            revert MktPurchaseFailed();
        }
        extraToPool = _transferFee(_tokenId, _seller, msg.sender, _listPrice, _starterFee, _poolFee, _marketFee);
        uint256 amountToSeller = _listPrice - _starterFee - _poolFee;

        if (!currency.transfer(_seller, amountToSeller)) {
            revert MktPurchaseFailed();
        }
    }

    function _minting(
        uint256 _tokenId,
        address _buyer,
        uint256 _marketFee,
        address _seller,
        uint256 _starterFee,
        uint256 _poolFee
    ) internal {
        IPoCNft(address(pocNft)).transfer(_buyer, _tokenId);

        pocNft.mint(_buyer, _marketFee, true);
        pocNft.mint(_seller, _poolFee, true);

        if (_starterFee > 0) {
            pocNft.mint(_seller, _starterFee, false);
        }
    }

    function _checkAddressZero(address _address) internal pure {
        if (_address == address(0)) {
            revert MktTokenNotListed();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCProject {
    error ProjOnlyStarterError();
    error ProjBalanceIsZeroError();
    error ProjCampaignNotActiveError();
    error ProjERC20TransferError();
    error ProjZeroAmountToWithdrawError();
    error ProjCannotTransferUnclaimedFundsError();
    error ProjCampaignNotNotFundedError();
    error ProjCampaignNotFundedError();
    error ProjUserCannotMintError();
    error ProjResultsCannotBePublishedError();
    error ProjCampaignCannotStartError();
    error ProjBackerBalanceIsZeroError();
    error ProjAlreadyClosedError();
    error ProjBalanceIsNotZeroError();
    error ProjLastCampaignNotClosedError();

    struct CampaignData {
        uint256 target;
        uint256 softTarget;
        uint256 startTime;
        uint256 endTime;
        uint256 backersDeadline;
        uint256 raisedAmount;
        bool resultsPublished;
    }

    enum CampaignStatus {
        NOTCREATED,
        ACTIVE,
        NOTFUNDED,
        FUNDED,
        SUCCEEDED,
        DEFEATED
    }

    function init(
        address starter,
        address pool,
        address lab,
        uint256 poolFeeBps,
        IERC20 currency
    ) external;

    function fundProject(uint256 _amount) external;

    function closeProject() external;

    function startCampaign(
        uint256 _target,
        uint256 _softTarget,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _backersDeadline
    ) external returns (uint256);

    function publishCampaignResults() external;

    function fundCampaign(address _user, uint256 _amount) external;

    function validateMint(uint256 _campaignId, address _user) external returns (uint256,uint256);

    function backerWithdrawDefeated(address _user)
        external
        returns (
            uint256,
            uint256,
            bool
        );

    function labCampaignWithdraw()
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function labProjectWithdraw() external returns (uint256);

    function withdrawToPool(IERC20 currency) external returns (uint256);

    function transferUnclaimedFunds() external returns (uint256, uint256);

    function getNumberOfCampaigns() external view returns (uint256);

    function getCampaignStatus(uint256 _campaignId) external view returns (CampaignStatus currentStatus);

    function getFundingAmounts(uint256 _amount)
        external
        view
        returns (
            uint256 currentCampaignId,
            uint256 amountToCampaign,
            uint256 amountToPool,
            bool isFunded
        );

    function projectStatus() external view returns (bool);

    function lastCampaignBalance() external view returns (uint256);

    function outsideCampaignsBalance() external view returns (uint256);

    function campaignRaisedAmount(uint256 _campaignId) external view returns (uint256);

    function campaignResultsPublished(uint256 _campaignId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IVCProject.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCStarter {
    error SttrNotAdminError();
    error SttrNotWhitelistedLabError();
    error SttrNotLabOwnerError();
    error SttrNotCoreTeamError();
    error SttrLabAlreadyWhitelistedError();
    error SttrLabAlreadyBlacklistedError();
    error SttrFundingAmountIsZeroError();
    error SttrMinCampaignDurationError();
    error SttrMaxCampaignDurationError();
    error SttrMinCampaignTargetError();
    error SttrMaxCampaignTargetError();
    error SttrSoftTargetBpsError();
    error SttrLabCannotFundOwnProjectError();
    error SttrBlacklistedLabError();
    error SttrCampaignTargetError();
    error SttrCampaignDurationError();
    error SttrERC20TransferError();
    error SttrExistingProjectRequestError();
    error SttrNonExistingProjectRequestError();
    error SttrInvalidSignatureError();
    error SttrProjectIsNotActiveError();
    error SttrResultsCannotBePublishedError();

    event SttrWhitelistedLab(address indexed lab);
    event SttrBlacklistedLab(address indexed lab);
    event SttrSetMinCampaignDuration(uint256 minCampaignDuration);
    event SttrSetMaxCampaignDuration(uint256 maxCampaignDuration);
    event SttrSetMinCampaignTarget(uint256 minCampaignTarget);
    event SttrSetMaxCampaignTarget(uint256 maxCampaignTarget);
    event SttrSetSoftTargetBps(uint256 softTargetBps);
    event SttrPoCNftSet(address indexed poCNft);
    event SttrCampaignStarted(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        uint256 startTime,
        uint256 endTime,
        uint256 backersDeadline,
        uint256 target,
        uint256 softTarget
    );
    event SttrCampaignFunding(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        address user,
        uint256 amount,
        bool campaignFunded
    );
    event SttrLabCampaignWithdrawal(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        uint256 amount
    );
    event SttrLabWithdrawal(address indexed lab, address indexed project, uint256 amount);
    event SttrWithdrawToPool(address indexed project, IERC20 indexed currency, uint256 amount);
    event SttrBackerMintPoCNft(address indexed lab, address indexed project, uint256 indexed campaign, uint256 amount);
    event SttrBackerWithdrawal(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        uint256 amount,
        bool campaignDefeated
    );
    event SttrUnclaimedFundsTransferredToPool(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        uint256 amount
    );
    event SttrProjectFunded(address indexed lab, address indexed project, address indexed backer, uint256 amount);
    event SttrProjectClosed(address indexed lab, address indexed project);
    event SttrProjectRequest(address indexed lab);
    event SttrCreateProject(address indexed lab, address indexed project, bool accepted);
    event SttrCampaignResultsPublished(address indexed lab, address indexed project, uint256 campaignId);
    event SttrPoolFunded(address indexed user, uint256 amount);

    function setAdmin(address admin) external; // onlyAdmin

    function setPool(address pool) external; // onlyAdmin

    function setProjectTemplate(address _newProjectTemplate) external;

    function setCoreTeam(address _newCoreTeam) external;

    function setTxValidator(address _newTxValidator) external;

    function setCurrency(IERC20 currency) external;

    function setPoolFeeBps(uint256 _newPoolFeeBps) external;

    function whitelistLab(address lab) external;

    function blacklistLab(address lab) external;

    function addNoFeeAccounts(address[] memory _accounts) external;

    function setMinCampaignDuration(uint256 minCampaignDuration) external;

    function setMaxCampaignDuration(uint256 maxCampaignDuration) external;

    function setMinCampaignTarget(uint256 minCampaignTarget) external;

    function setMaxCampaignTarget(uint256 maxCampaignTarget) external;

    function setSoftTargetBps(uint256 softTargetBps) external;

    function setPoCNft(address _pocNft) external;

    function createProject(address _lab, bool _accepted) external returns (address newProject);

    function createProjectRequest() external;

    function fundProject(address _project, uint256 _amount) external;

    function fundProjectOnBehalf(
        address _user,
        address _project,
        uint256 _amount
    ) external;

    function closeProject(address _project, bytes memory _sig) external;

    function startCampaign(
        address _project,
        uint256 _target,
        uint256 _duration,
        bytes memory _sig
    ) external returns (uint256 campaignId);

    function publishCampaignResults(address _project, bytes memory _sig) external;

    function fundCampaign(address _project, uint256 _amount) external;

    function backerMintPoCNft(address _project, uint256 _campaignId) external;

    function backerWithdrawDefeated(address _project) external;

    function labCampaignWithdraw(address _project) external;

    function labProjectWithdraw(address _project) external;

    function transferUnclaimedFunds(address _project) external;

    function withdrawToPool(address project, IERC20 currency) external;

    function getAdmin() external view returns (address);

    function getCurrency() external view returns (address);

    function getCampaignStatus(address _project, uint256 _campaignId)
        external
        view
        returns (IVCProject.CampaignStatus currentStatus);

    function isValidProject(address _lab, address _project) external view returns (bool);

    function isWhitelistedLab(address _lab) external view returns (bool);

    function areActiveProjects(address[] memory _projects) external view returns (bool[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPoCNft is IERC721 {
    struct Contribution {
        uint256 amount;
        uint256 timestamp;
    }

    struct Range {
        uint240 maxDonation;
        uint16 maxBps;
    }

    event PoCNFTMinted(address indexed user, uint256 amount, uint256 tokenId, bool isPool);
    event PoCBoostRangesChanged(Range[]);

    error PoCUnexpectedAdminAddress();
    error PoCOnlyAdminAllowed();
    error PoCUnexpectedBoostDuration();
    error PoCInvalidBoostRangeParameters();

    function setAdmin(address newAdmin) external; // onlyAdmin

    function grantMinterRole(address _address) external; // onlyAdmin

    function revokeMinterRole(address _address) external; // onlyAdmin

    function grantApproverRole(address _approver) external; // onlyAdmin

    function revokeApproverRole(address _approver) external; // onlyAdmin

    function setPool(address pool) external; // onlyAdmin

    function changeBoostDuration(uint256 newBoostDuration) external; // onlyAdmin

    function changeBoostRanges(Range[] calldata newBoostRanges) external; // onlyAdmin

    function setApprovalForAllCustom(
        address caller,
        address operator,
        bool approved
    ) external; // only(APPROVER_ROLE)

    //function supportsInterface(bytes4 interfaceId) external view override returns (bool);

    function exists(uint256 tokenId) external returns (bool);

    function votingPowerBoost(address _user) external view returns (uint256);

    function denominator() external pure returns (uint256);

    function getContribution(uint256 tokenId) external view returns (Contribution memory);

    function mint(
        address _user,
        uint256 _amount,
        bool isPool
    ) external; // only(MINTER_ROLE)

    function transfer(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract CanWithdrawERC20 {
    error ERC20WithdrawalFailed();
    event ERC20Withdrawal(address indexed to, IERC20 indexed token, uint256 amount);

    address _to = 0x000000000000000000000000000000000000dEaD;
    mapping(IERC20 => uint256) _balanceNotWithdrawable;

    constructor() {}

    function withdraw(IERC20 _token) external {
        uint256 balanceWithdrawable = _token.balanceOf(address(this)) - _balanceNotWithdrawable[_token];

        if (balanceWithdrawable == 0 || !_token.transfer(_to, balanceWithdrawable)) {
            revert ERC20WithdrawalFailed();
        }
        emit ERC20Withdrawal(_to, _token, balanceWithdrawable);
    }

    function _setTo(address to) internal {
        _to = to;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FeeManager {
    /// @notice Used to translate from basis points to amounts
    uint96 public constant FEE_DENOMINATOR = 10_000;

    /**
     * @dev Translates a fee in basis points to a fee amount.
     */
    function _toFee(uint256 _amount, uint256 _feeBps) internal pure returns (uint256) {
        return (_amount * _feeBps) / FEE_DENOMINATOR;
    }
}