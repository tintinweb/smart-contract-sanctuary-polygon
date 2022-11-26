/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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


// File contracts/AssetNFT/IAssetNFT.sol

pragma solidity =0.8.17;

/**
 * @title An interface for the asset NFT
 * @author Polytrade.Finance
 * @dev This interface will hold the main functions, events and data types for the new asset NFT contract
 */
interface IAssetNFT is IERC721 {
    /**
     * @title A new struct to define the metadata structure
     * @dev Defining a new type of struct called Metadata to store the asset metadata
     * @param factoringFee, is a uint24 will have 2 decimals
     * @param discountFee, is a uint24 will have 2 decimals
     * @param lateFee, is a uint24 will have 2 decimals
     * @param bankChargesFee, is a uint24 will have 2 decimals
     * @param additionalFee, is a uint24 will have 2 decimals
     * @param gracePeriod, is a uint16 will have 2 decimals
     * @param advanceRatio, is a uint16 will have 2 decimals
     * @param dueDate, is a uint48 will have 2 decimals
     * @param invoiceDate, is a uint48 will have 2 decimals
     * @param fundsAdvancedDate, is a uint48 will have 2 decimals
     * @param invoiceAmount, is a uint will have 2 decimals
     * @param invoiceLimit, is a uint will have 2 decimals
     */
    struct InitialMetadata {
        uint24 factoringFee;
        uint24 discountFee;
        uint24 lateFee;
        uint24 bankChargesFee;
        uint24 additionalFee;
        uint16 gracePeriod;
        uint16 advanceRatio;
        uint48 dueDate;
        uint48 invoiceDate;
        uint48 fundsAdvancedDate;
        uint invoiceAmount;
        uint invoiceLimit;
    }

    /**
     * @title A new struct to define the metadata structure
     * @dev Defining a new type of struct called Metadata to store the asset metadata
     * @param paymentReceiptDate, is a uint48 will have 2 decimals
     * @param paymentReserveDate, is a uint48 will have 2 decimals
     * @param buyerAmountReceived, is a uint will have 2 decimals
     * @param supplierAmountReceived, is a uint will have 2 decimals
     * @param reservePaidToSupplier, is a uint will have 2 decimals
     * @param reservePaymentTransactionId, is a uint will have 2 decimals
     * @param amountSentToLender, is a uint will have 2 decimals
     * @param initialMetadata, is a InitialMetadata will hold all mandatory needed metadata to mint the AssetNFT
     */
    struct Metadata {
        uint48 paymentReceiptDate;
        uint48 paymentReserveDate;
        uint buyerAmountReceived;
        uint supplierAmountReceived;
        uint reservePaidToSupplier;
        uint reservePaymentTransactionId;
        uint amountSentToLender;
        InitialMetadata initialMetadata;
    }

    /**
     * @dev Emitted when `assetNumber` token with `metadata` is minted from the `creator` to the `receiver`
     * @param creator, Address of the contract that minted this token
     * @param receiver, Address of the receiver of this token
     * @param assetNumber, Uint id of the newly minted token
     */
    event AssetCreate(
        address indexed creator,
        address indexed receiver,
        uint assetNumber
    );

    /**
     * @dev Emitted when `newFormulas` contract address is set to the AssetNFT instead of `oldFormulas`
     * @param oldFormulas, Address of the old formulas smart contract
     * @param newFormulas, Address of the new formulas smart contract
     */
    event FormulasSet(address oldFormulas, address newFormulas);

    /**
     * @dev Emitted when `paymentReceiptDate`, `buyerAmountReceived` & `supplierAmountReceived`
     * metadata are updated on a specific AssetNFT `assetNumber`
     * @param assetNumber, Uint of the asset NFT
     * @param buyerAmountReceived, Uint represent the amount received from the buyer
     * @param supplierAmountReceived, Uint represent the amount received from the supplier
     * @param paymentReceiptDate, Uint represent the date
     */
    event AdditionalMetadataSet(
        uint assetNumber,
        uint buyerAmountReceived,
        uint supplierAmountReceived,
        uint paymentReceiptDate
    );

    /**
     * @dev Emitted when `reservePaidToSupplier`, `reservePaymentTransactionId`, `paymentReserveDate`
     * & `amountSentToLender` metadata are updated on a specific AssetNFT `assetNumber`
     * @param assetNumber, Uint of the asset NFT
     * @param reservePaidToSupplier, Uint value of the reserved amount sent to supplier
     * @param reservePaymentTransactionId, Uint value of the payment transaction ID
     * @param paymentReserveDate, Uint value of the reserve payment date
     * @param amountSentToLender, Uint value of the amount sent to the lender
     */
    event AssetSettledMetadataSet(
        uint assetNumber,
        uint reservePaidToSupplier,
        uint reservePaymentTransactionId,
        uint paymentReserveDate,
        uint amountSentToLender
    );

    /**
     * @dev Emitted when `newURI` is set to the AssetNFT instead of `oldURI` by `assetNumber`
     * @param oldAssetBaseURI, Old URI for the asset NFT
     * @param newAssetBaseURI, New URI for the asset NFT
     */
    event AssetBaseURISet(string oldAssetBaseURI, string newAssetBaseURI);

    /**
     * @dev Implementation of a mint function that uses the predefined _mint() function from ERC721 standard
     * @param receiver, Receiver address of the newly minted NFT
     * @param assetNumber, Unique uint Asset Number of the NFT
     * @param initialMetadata, Struct of asset initial metadata
     */
    function createAsset(
        address receiver,
        uint assetNumber,
        InitialMetadata calldata initialMetadata
    ) external;

    /**
     * @dev Implementation of a setter for the formulas contract
     * @param formulasAddress, Address of the formulas calculation contract
     */
    function setFormulas(address formulasAddress) external;

    /**
     * @dev Implementation of a setter for the asset base URI
     * @param newBaseURI, String of the asset base URI
     */
    function setBaseURI(string calldata newBaseURI) external;

    /**
     * @dev Implementation of a setter for
     * Payment receipt date & amount paid by buyer & amount paid by supplier
     * @param assetNumber, Unique uint Asset Number of the NFT
     * @param buyerAmountReceived, Uint value of the amount received from buyer
     * @param supplierAmountReceived, Uint value of the amount received from supplier
     * @param paymentReceiptDate, Uint value of the payment receipt date
     */
    function setAdditionalMetadata(
        uint assetNumber,
        uint buyerAmountReceived,
        uint supplierAmountReceived,
        uint paymentReceiptDate
    ) external;

    /**
     * @dev Implementation of a setter for
     * reserved payment date & amount sent to supplier & the payment transaction ID & amount sent to lender
     * @param assetNumber, Unique uint Asset Number of the NFT
     * @param reservePaidToSupplier, Uint value of the reserved amount sent to supplier
     * @param reservePaymentTransactionId, Uint value of the payment transaction ID
     * @param paymentReserveDate, Uint value of the reserve payment date
     * @param amountSentToLender, Uint value of the amount sent to the lender
     */
    function setAssetSettledMetadata(
        uint assetNumber,
        uint reservePaidToSupplier,
        uint reservePaymentTransactionId,
        uint paymentReserveDate,
        uint amountSentToLender
    ) external;

    /**
     * @dev Implementation of a getter for asset metadata
     * @return Metadata Metadata related to a specific asset
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function getAsset(uint assetNumber) external view returns (Metadata memory);

    /**
     * @dev Calculate the number of late days
     * @return uint Number of Late Days
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function calculateLateDays(uint assetNumber) external view returns (uint);

    /**
     * @dev Calculate the discount amount
     * @return uint Amount of the Discount
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function calculateDiscountAmount(uint assetNumber)
        external
        view
        returns (uint);

    /**
     * @dev Calculate the late amount
     * @return uint Late Amount
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function calculateLateAmount(uint assetNumber) external view returns (uint);

    /**
     * @dev Calculate the advanced amount
     * @return uint Advanced Amount
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function calculateAdvancedAmount(uint assetNumber)
        external
        view
        returns (uint);

    /**
     * @dev Calculate the factoring amount
     * @return uint Factoring Amount
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function calculateFactoringAmount(uint assetNumber)
        external
        view
        returns (uint);

    /**
     * @dev Calculate the invoice tenure
     * @return uint Invoice Tenure
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function calculateInvoiceTenure(uint assetNumber)
        external
        view
        returns (uint);

    /**
     * @dev Calculate the reserve amount
     * @return uint Reserve Amount
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function calculateReserveAmount(uint assetNumber)
        external
        view
        returns (uint);

    /**
     * @dev Calculate the finance tenure
     * @return uint Finance Tenure
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function calculateFinanceTenure(uint assetNumber)
        external
        view
        returns (uint);

    /**
     * @dev Calculate the total fees amount
     * @return uint Total Amount
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function calculateTotalFees(uint assetNumber) external view returns (uint);

    /**
     * @dev Calculate the net amount payable to the client
     * @return uint Net Amount Payable to the Client
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function calculateNetAmountPayableToClient(uint assetNumber)
        external
        view
        returns (int);

    /**
     * @dev Calculate the total amount received
     * @return uint Total Received Amount
     * @param assetNumber, Unique uint Asset Number of the NFT
     */
    function calculateTotalAmountReceived(uint assetNumber)
        external
        view
        returns (uint);
}


// File contracts/Marketplace/IMarketplace.sol

pragma solidity =0.8.17;

/**
 * @title The main interface to define the main marketplace
 * @author Polytrade.Finance
 * @dev Collection of all procedures related to the marketplace
 */
interface IMarketplace {
    /**
     * @dev Emitted when new `newAssetNFT` contract has been set instead of `oldAssetNFT`
     * @param oldAssetNFT, Old address of asset NFT contract token
     * @param newAssetNFT, New address of asset NFT contract token
     */
    event AssetNFTSet(address oldAssetNFT, address newAssetNFT);

    /**
     * @dev Emitted when new `stableToken` contract has been set
     * @param stableToken, Address of ERC20 contract token
     */
    event StableTokenSet(address stableToken);

    /**
     * @dev Implementation of a setter for the asset NFT contract
     * @param assetNFTAddress, Address of the asset NFT contract
     */
    function setAssetNFT(address assetNFTAddress) external;

    /**
     * @dev Implementation of a setter for the ERC20 token
     * @param stableTokenAddress, Address of the stableToken (ERC20) contract
     */
    function setStableToken(address stableTokenAddress) external;

    /**
     * @dev Implementation of the function used to buy Asset NFT
     * @param assetNumber, Uint unique number of the Asset NFT
     */
    function buy(uint assetNumber) external;

    /**
     * @dev Implementation of the function used to buy multiple Asset NFT at once
     * @param assetNumbers, Array of uint unique numbers of the Asset NFTs
     */
    function batchBuy(uint[] calldata assetNumbers) external;

    /**
     * @dev Implementation of the function used to disburse money
     * @param assetNumber, Uint unique number of the Asset NFT
     * @return int Required amount to be paid
     */
    function disburse(uint assetNumber) external returns (int);

    /**
     * @dev Implementation of a getter for the asset NFT contract
     * @return address Address of the asset NFT contract
     */
    function getAssetNFT() external view returns (address);

    /**
     * @dev Implementation of a getter for the stable coin contract
     * @return address Address of the stable coin contract
     */
    function getStableCoin() external view returns (address);
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/Token/Token.sol

pragma solidity =0.8.17;

/**
 * @title The token used to pay for getting AssetNFTs
 * @author Polytrade.Finance
 * @dev IERC20 used for test purposes
 */
contract Token is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        address receiver_,
        uint totalSupply_
    ) ERC20(name_, symbol_) {
        _mint(receiver_, totalSupply_ * 1 ether);
    }
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}


// File contracts/Marketplace/Marketplace.sol

pragma solidity =0.8.17;




/**
 * @title The common marketplace for the AssetNFTs
 * @author Polytrade.Finance
 * @dev Implementation of all AssetNFT trading operations
 * @custom:receiver Receiver contract able to receiver tokens
 */
contract Marketplace is IERC721Receiver, Ownable, IMarketplace {
    IAssetNFT private _assetNFT;
    Token private _stableToken;

    /**
     * @dev Constructor for the main Marketplace
     * @param assetNFTAddress, Address of the Asset NFT used in the marketplace
     * @param stableTokenAddress, Address of the stableToken (ERC20) contract
     */
    constructor(address assetNFTAddress, address stableTokenAddress) {
        _setAssetNFT(assetNFTAddress);
        _setStableToken(stableTokenAddress);
    }

    /**
     * @dev Implementation of a setter for the asset NFT contract
     * @param assetNFTAddress, Address of the asset NFT contract
     */
    function setAssetNFT(address assetNFTAddress) external onlyOwner {
        _setAssetNFT(assetNFTAddress);
    }

    /**
     * @dev Implementation of a setter for the ERC20 token
     * @param stableTokenAddress, Address of the stableToken (ERC20) contract
     */
    function setStableToken(address stableTokenAddress) external onlyOwner {
        _setStableToken(stableTokenAddress);
    }

    /**
     * @dev Implementation of the function used to buy Asset NFT
     * @param assetNumber, Uint unique number of the Asset NFT
     */
    function buy(uint assetNumber) external {
        address assetOwner = _assetNFT.ownerOf(assetNumber);
        uint amount = _assetNFT.calculateAdvancedAmount(assetNumber);
        _assetNFT.safeTransferFrom(assetOwner, msg.sender, assetNumber);
        require(
            _stableToken.transferFrom(msg.sender, assetOwner, amount),
            "Transfer failed"
        );
    }

    /**
     * @dev Implementation of the function used to buy multiple Asset NFT at once
     * @param assetNumbers, Array of uint unique numbers of the Asset NFTs
     */
    function batchBuy(uint[] calldata assetNumbers) external {
        uint amount;
        address assetOwner;
        for (uint counter = 0; counter < assetNumbers.length; ) {
            amount = _assetNFT.calculateReserveAmount(assetNumbers[counter]);
            assetOwner = _assetNFT.ownerOf(assetNumbers[counter]);
            _assetNFT.safeTransferFrom(
                assetOwner,
                msg.sender,
                assetNumbers[counter]
            );
            require(
                _stableToken.transferFrom(msg.sender, assetOwner, amount),
                "Transfer failed"
            );
            unchecked {
                counter++;
            }
        }
    }

    /**
     * @dev Implementation of the function used to disburse money
     * @param assetNumber, Uint unique number of the Asset NFT
     * @return int Required amount to be paid
     */
    function disburse(uint assetNumber) external view returns (int) {
        int amount = _assetNFT.calculateNetAmountPayableToClient(assetNumber);

        return amount;
    }

    /**
     * @dev Implementation of a getter for the asset NFT contract
     * @return address Address of the asset NFT contract
     */
    function getAssetNFT() external view returns (address) {
        return address(_assetNFT);
    }

    /**
     * @dev Implementation of a getter for the stable coin contract
     * @return address Address of the stable coin contract
     */
    function getStableCoin() external view returns (address) {
        return address(_stableToken);
    }

    /**
     * @dev Whenever an {IERC721} `assetNumber` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient,
     * the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev Implementation of a setter for the asset NFT contract
     * @param newAssetNFTAddress, Address of the asset NFT contract
     */
    function _setAssetNFT(address newAssetNFTAddress) private {
        address oldAssetNFTAddress = address(_assetNFT);
        _assetNFT = IAssetNFT(newAssetNFTAddress);
        emit AssetNFTSet(oldAssetNFTAddress, newAssetNFTAddress);
    }

    /**
     * @dev Implementation of a setter for the ERC20 token
     * @param stableTokenAddress, Address of the stableToken (ERC20) contract
     */
    function _setStableToken(address stableTokenAddress) private {
        _stableToken = Token(stableTokenAddress);
        emit StableTokenSet(stableTokenAddress);
    }
}