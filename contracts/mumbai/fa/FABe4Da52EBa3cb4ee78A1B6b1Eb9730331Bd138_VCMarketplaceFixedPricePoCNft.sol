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

import "./IFeeBeneficiary.sol";

/**
 * @title FeeBeneficiary
 * @dev Base contract that contains the logic to manage and split user, project and market fees
 */
contract FeeBeneficiary is IFeeBeneficiary, FeeManager, CanWithdrawERC20 {
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

    /**
     * @dev Maps a token and seller to its TokenFeesData struct.
     */
    mapping(uint256 => mapping(address => TokenFeesData)) _tokenFeesData;

    /**
     * @dev Constructor
     * @param _admin Admin wallet for this contract
     * @param _minPoolFeeBps Minimum basis points fee that is required for pool
     * @param _marketplaceFeeBps VC Marketplace fee in basis points
     * @param _maxBeneficiaryProjects The maximum amount of projects a token seller can support
     */
    constructor(address _admin, uint256 _minPoolFeeBps, uint256 _marketplaceFeeBps, uint96 _maxBeneficiaryProjects) {
        _setAdmin(_admin);
        _setMinPoolFeeBps(_minPoolFeeBps);
        _setMarketplaceFeeBps(_marketplaceFeeBps);
        _setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
    }

    /**
     * @dev See {IFeeBeneficiary-setAdmin}.
     */
    function setAdmin(address _admin) external {
        _onlyAdmin();
        _setAdmin(_admin);
    }

    /**
     * @dev See {IFeeBeneficiary-setPool}.
     */
    function setPool(address _pool) external {
        _onlyAdmin();
        _checkAddress(_pool);

        _setTo(_pool);
        pool = _pool;
    }

    /**
     * @dev See {IFeeBeneficiary-setStarter}.
     */
    function setStarter(address _starter) external {
        _onlyAdmin();
        _checkAddress(_starter);

        starter = _starter;
    }

    /**
     * @notice Allow admin to set the minimum valid basis points fee for VC Pool
     * @param _minPoolFeeBps the new minimum fee
     */
    function setMinPoolFeeBps(uint96 _minPoolFeeBps) external {
        _onlyAdmin();

        _setMinPoolFeeBps(_minPoolFeeBps);
    }

    /**
     * @notice Allow admin to set the marketplace fee in basis points
     * @param _marketplaceFee the new marketplace fee
     */
    function setMarketplaceFeeBps(uint256 _marketplaceFee) external {
        _onlyAdmin();

        _setMarketplaceFeeBps(_marketplaceFee);
    }

    /**
     * @notice Allow admin to set the max amount of beneficiary projects
     * @param _maxBeneficiaryProjects the new max amount
     */
    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) public {
        _onlyAdmin();

        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev See {IFeeBeneficiary-setCurrency}.
     */
    function setCurrency(IERC20 _currency) external {
        _onlyAdmin();

        currency = _currency;
        emit MktCurrencySet(address(currency), address(_currency));
    }

    /**
     * @dev See {IFeeBeneficiary-getFeesData}.
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
     * @param _poolFeeBps Basis points fee that will be transferred to the pool on each purchase
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
     * @dev Computes and transfers fees to the Pool and projects.
     *
     * @param _tokenId Non-fungible token identifier
     * @param _seller The seller of the token used to get fees data from the storage
     * @param _buyer The address that bought the token
     * @param _price Token price
     * @param _starterFee The starter fee set on token listing
     * @param  _poolFee The pool fee set on token listing
     * @param _mktFee The market fee set on token listing
     *
     * NOTE: Transfer fee from contract (Marketplace) itself.
     * FIXME: The use of _starterFee here is just to validate if something will be transferred to projects
     * Maybe we could replace that with just a bool since we are already iterating over all the projects here
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
            revert MktPoolTransferFailedError();
        }
        emit MktPoolFunded(_buyer, currency, _mktFee);
        emit MktPoolFunded(_seller, currency, _poolFee);
    }

    /**
     * @dev Computes individual fees for each beneficiary project and performs
     * the pertinent accounting at the Starter smart contract.
     * @param _seller The seller of the listed token
     * @param _feesData The fee data structure
     * @param _listPrice The listed price
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

    /**
     * @dev Check that the address is a valid one
     * @param _address Address to check
     */
    function _checkAddress(address _address) internal view {
        if (_address == address(this) || _address == address(0)) {
            revert MktUnexpectedAddressError();
        }
    }

    /**
     * @dev internal function to set min pool fee in basis points
     */
    function _setMinPoolFeeBps(uint256 _minPoolFeeBps) private {
        minPoolFeeBps = _minPoolFeeBps;
    }

    /**
     * @dev internal function to set the marketplace fee in basis points
     */
    function _setMarketplaceFeeBps(uint256 _marketplaceFeeBps) private {
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    /**
     * @dev internal function to set the max allowed amount of beneficiary projects
     */
    function _setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) private {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev internal function to set the admin of this contract
     */
    function _setAdmin(address _admin) internal {
        _checkAddress(_admin);
        admin = _admin;
    }

    /**
     * @dev Splits an amount into fees for both Pool and Starter smart
     * contracts and a resulting amount to be transferred to the token
     * owner (i.e. the token seller).
     * @param _feesData the fee data structure
     * @param _listPrice the listing price for the token
     */
    function _splitListPrice(
        TokenFeesData memory _feesData,
        uint256 _listPrice
    ) internal pure returns (uint256 starterFee, uint256 poolFee, uint256 resultingAmount) {
        starterFee = _toFee(_listPrice, _feesData.starterFeeBps);
        poolFee = _toFee(_listPrice, _feesData.poolFeeBps);
        resultingAmount = _listPrice - starterFee - poolFee;
    }

    /**
     * @dev internal function to validate that the sender of the tx is the admin
     */
    function _onlyAdmin() internal view {
        if (msg.sender != admin) {
            revert MktOnlyAdminAllowedError();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../utils/FeeManager.sol";
import "../utils/CanWithdrawERC20.sol";
import "../starter/IVCStarter.sol";

interface IFeeBeneficiary {
    error MktFeesDataError();
    error MktTotalFeeError();
    error MktUnexpectedAddressError();
    error MktOnlyAdminAllowedError();
    error MktPoolTransferFailedError();

    struct TokenFeesData {
        uint256 poolFeeBps;
        uint256 starterFeeBps;
        address[] projects;
        uint256[] projectFeesBps;
    }

    struct ListingFeeData {
        uint256 marketFee;
        uint256 starterFee;
        uint256 poolFee;
        address[] projects;
        uint256[] projectFeesBps;
    }

    struct ListingData {
        uint256 tokenId;
        uint256 price;
        address[] projects;
        uint256[] projectFeesBps;
    }

    event MktCurrencySet(address indexed oldCurrency, address indexed newCurrency);
    event MktPoolFunded(address indexed user, IERC20 indexed currency, uint256 amount);
    event MktProjectFunded(address indexed project, address indexed user, IERC20 indexed currency, uint256 amount);

    /**
     * @dev Sets the Marketplace admin.
     *
     * @notice Allow admin to transfer admin access to another wallet
     *
     * @param _admin: The admin address
     */
    function setAdmin(address _admin) external;

    /**
     * @dev Sets the Marketplace VCPool.
     *
     * @notice Allow admin to set or update the VC Pool contract address
     *
     * @param _pool: The VCPool address
     */
    function setPool(address _pool) external;

    /**
     * @dev Sets the Marketplace VCStarter.
     *
     * @notice Allow admin to set the address for VC Starter Contract
     *
     * @param _starter: The VCStarter address
     */
    function setStarter(address _starter) external;

    function setMinPoolFeeBps(uint96 _minPoolFeeBps) external;

    function setMarketplaceFeeBps(uint256 _marketplaceFee) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    /**
     * @dev Sets the Marketplace currency.
     *
     * @param _currency: The new currency address to set.
     */
    function setCurrency(IERC20 _currency) external;

    /**
     * @dev Returns the struct TokenFeesData corresponding to the _token and _tokenId
     *
     * @notice Fees data for a specified user and tokenId
     *
     * @param _tokenId Non-fungible token identifier
     * @param _seller The fees corresponding to the seller for the specified token
     */
    function getFeesData(uint256 _tokenId, address _seller) external view returns (TokenFeesData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./FeeBeneficiary.sol";
import "../tokens/IVCPoCNft.sol";

interface IVCMarketplaceBasePoCNft {
    error MktCallerNotSellerError();
    error MktTokenNotListedError();
    error MktSettleFailedError();
    error MktPurchaseFailedError();

    event MktPoCNftSet(address indexed oldPoCNft, address indexed newPoCNft);

    /**
     * @dev Pauses or unpauses the Marketplace
     */
    function pause(bool _paused) external;

    /**
     * @dev Sets the Proof of Collaboration Non-Fungible Token.
     *
     * @param _pocNft new PoCNft address
     */
    function setPoCNft(address _pocNft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./VCMarketplaceBasePoCNft.sol";

interface IVCMarketplaceFixedPricePoCNft {
    struct FixedPriceListing {
        address seller;
        uint256 price;
        uint256 marketFee;
        uint256 starterFee;
        uint256 poolFee;
    }

    event MktListedFixedPrice(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 listPrice,
        IFeeBeneficiary.ListingFeeData fees
    );
    event MktUpdatedFixedPrice(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 listPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee
    );
    event MktUnlistedFixedPrice(address indexed token, uint256 indexed tokenId, address indexed seller);
    event MktPurchased(
        address indexed buyer,
        address indexed token,
        uint256 indexed tokenId,
        address seller,
        uint256 listPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee
    );

    /**
     * @dev Allows a token owner, i.e. msg.sender, to list an ERC721 artNft with a given fixed price to the Marketplace.
     * It can also be used to update a listing, such as its price, fees and/or royalty data.
     *
     * @param _tokenId the token identifier
     * @param _listPrice the listing price
     * @param _poolFeeBps the fee transferred to the VC Pool on purchases
     * @param _projectIds Array of projects identifiers to support on purchases
     * @param _projectFeesBps Array of project fees in basis points on purchases
     */
    function listFixedPrice(
        uint256 _tokenId,
        uint256 _listPrice,
        uint256 _poolFeeBps,
        address[] calldata _projectIds,
        uint256[] calldata _projectFeesBps
    ) external;

    /**
     * @dev Allows the seller, i.e. msg.sender, to remove a token from being listed at the Marketplace.
     *
     * @param _tokenId the token identifier
     */
    function unlistFixedPrice(uint256 _tokenId) external;

    /**
     * @dev Allows a buyer, i.e. msg.sender, to purchase a token at a fixed price in the Marketplace. Tokens must be
     * purchased for the price set by the seller plus the market fee.
     *
     * @param _tokenId the token identifier
     */
    function purchase(uint256 _tokenId) external;

    function listed(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IVCMarketplaceBasePoCNft.sol";

abstract contract VCMarketplaceBasePoCNft is IVCMarketplaceBasePoCNft, Pausable, FeeBeneficiary {
    /// @notice The Viral(Cure) Proof of Collaboration Non-Fungible Token
    IVCPoCNft public pocNft;

    constructor() {}

    /**
     * @dev See {IVCMarketplaceBasePoCNft-pause}.
     */
    function pause(bool _paused) public {
        _onlyAdmin();

        if (_paused) _pause();
        else _unpause();
    }

    /**
     * @dev See {IVCMarketplaceBasePoCNft-setPoCNft}.
     */
    function setPoCNft(address _pocNft) external {
        _onlyAdmin();

        pocNft = IVCPoCNft(_pocNft);
        emit MktPoCNftSet(address(pocNft), _pocNft);
    }

    /**
     * @dev Get fees for token id for sale
     * @param _tokenId token id
     * @param _seller seller of the token
     * @param _listPrice listing price
     * @return marketFee market fee
     * @return starterFee starter fee
     * @return poolFee pool fee
     */
    function _getFees(
        uint256 _tokenId,
        address _seller,
        uint256 _listPrice
    ) internal view returns (uint256 marketFee, uint256 starterFee, uint256 poolFee) {
        marketFee = _toFee(_listPrice, marketplaceFeeBps);
        TokenFeesData memory feesData = _tokenFeesData[_tokenId][_seller];

        (starterFee, poolFee, ) = _splitListPrice(feesData, _listPrice);
    }

    /**
     * @dev settles an auction listing
     * @param _tokenId token id
     * @param _seller token's seller
     * @param _highestBidder bidder of the highest bid
     * @param _highestBid highest bid amount
     * @param _marketFee marker fee
     * @param _starterFee starter fee
     * @param _poolFee pool fee
     */
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
            revert MktSettleFailedError();
        }
    }

    /**
     * @dev process the purchase of a listed token
     * @param _tokenId token id
     * @param _seller seller of the token
     * @param _listPrice listed price
     * @param _marketFee market fee
     * @param _starterFee starter fee
     * @param _poolFee pool fee
     */
    function _purchase(
        uint256 _tokenId,
        address _seller,
        uint256 _listPrice,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee
    ) internal returns (uint256 extraToPool) {
        if (!currency.transferFrom(msg.sender, address(this), _listPrice + _marketFee)) {
            revert MktPurchaseFailedError();
        }
        extraToPool = _transferFee(_tokenId, _seller, msg.sender, _listPrice, _starterFee, _poolFee, _marketFee);
        uint256 amountToSeller = _listPrice - _starterFee - _poolFee;

        if (!currency.transfer(_seller, amountToSeller)) {
            revert MktPurchaseFailedError();
        }
    }

    /**
     * @dev transfer listed poc and mint pocs to buyer and seller
     * @param _tokenId token id
     * @param _buyer buyer of the listed token
     * @param _marketFee market fee
     * @param _seller seller address
     * @param _starterFee starter fee
     * @param _poolFee pool fee
     */
    function _minting(
        uint256 _tokenId,
        address _buyer,
        uint256 _marketFee,
        address _seller,
        uint256 _starterFee,
        uint256 _poolFee
    ) internal {
        IVCPoCNft(address(pocNft)).transfer(_buyer, _tokenId);

        pocNft.mint(_buyer, _marketFee, true);
        pocNft.mint(_seller, _poolFee, true);

        if (_starterFee > 0) {
            pocNft.mint(_seller, _starterFee, false);
        }
    }

    /**
     * @dev check if address is the null address
     * @param _address address to check
     */
    function _checkAddressZero(address _address) internal pure {
        if (_address == address(0)) {
            revert MktTokenNotListedError();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IVCMarketplaceFixedPricePoCNft.sol";

contract VCMarketplaceFixedPricePoCNft is IVCMarketplaceFixedPricePoCNft, VCMarketplaceBasePoCNft, ERC721Holder {
    /// @notice Maps a token Id to its listing
    mapping(uint256 => FixedPriceListing) public fixedPriceListings;

    constructor(
        address _admin,
        uint256 _minPoolFeeBps,
        uint256 _marketplaceFee,
        uint96 _maxBeneficiaryProjects
    ) FeeBeneficiary(_admin, _minPoolFeeBps, _marketplaceFee, _maxBeneficiaryProjects) {}

    /**
     * @dev See {IVCMarketplaceFixedPricePoCNft-listFixedPrice}.
     */
    function listFixedPrice(
        uint256 _tokenId,
        uint256 _listPrice,
        uint256 _poolFeeBps,
        address[] calldata _projectIds,
        uint256[] calldata _projectFeesBps
    ) external whenNotPaused {
        _setFees(_tokenId, _poolFeeBps, _projectIds, _projectFeesBps);
        if (!listed(_tokenId)) {
            _newList(ListingData(_tokenId, _listPrice, _projectIds, _projectFeesBps));
        } else {
            _updateList(_tokenId, _listPrice);
        }
    }

    /**
     * @dev See {IVCMarketplaceFixedPricePoCNft-unlistFixedPrice}.
     */
    function unlistFixedPrice(uint256 _tokenId) external {
        FixedPriceListing memory listing = fixedPriceListings[_tokenId];

        if (listing.seller != msg.sender) {
            revert MktCallerNotSellerError();
        }

        delete fixedPriceListings[_tokenId];

        IVCPoCNft(address(pocNft)).transferFrom(address(this), listing.seller, _tokenId);

        emit MktUnlistedFixedPrice(address(pocNft), _tokenId, msg.sender);
    }

    /**
     * @dev See {IVCMarketplaceFixedPricePoCNft-purchase}.
     */
    function purchase(uint256 _tokenId) external whenNotPaused {
        FixedPriceListing memory listing = fixedPriceListings[_tokenId];

        _checkAddressZero(listing.seller);
        delete fixedPriceListings[_tokenId];

        uint256 extraToPool = _purchase(
            _tokenId,
            listing.seller,
            listing.price,
            listing.marketFee,
            listing.starterFee,
            listing.poolFee
        );

        listing.poolFee += extraToPool;
        listing.starterFee -= extraToPool;

        _minting(_tokenId, msg.sender, listing.marketFee, listing.seller, listing.starterFee, listing.poolFee);

        emit MktPurchased(
            msg.sender,
            address(pocNft),
            _tokenId,
            listing.seller,
            listing.price,
            listing.marketFee,
            listing.starterFee,
            listing.poolFee
        );
    }

    function listed(uint256 _tokenId) public view returns (bool) {
        return fixedPriceListings[_tokenId].seller != address(0);
    }

    function _newList(ListingData memory data) internal {
        IVCPoCNft(address(pocNft)).transferFrom(msg.sender, address(this), data.tokenId);

        (uint256 marketFee, uint256 starterFee, uint256 poolFee) = _getFees(data.tokenId, msg.sender, data.price);

        fixedPriceListings[data.tokenId] = FixedPriceListing(msg.sender, data.price, marketFee, starterFee, poolFee);

        emit MktListedFixedPrice(
            address(pocNft),
            data.tokenId,
            msg.sender,
            data.price,
            ListingFeeData(marketFee, starterFee, poolFee, data.projects, data.projectFeesBps)
        );
    }

    function _updateList(uint256 _tokenId, uint256 _listPrice) internal {
        (uint256 marketFee, uint256 starterFee, uint256 poolFee) = _getFees(_tokenId, msg.sender, _listPrice);

        FixedPriceListing memory listing = fixedPriceListings[_tokenId];
        listing.price = _listPrice;
        listing.marketFee = marketFee;
        listing.starterFee = starterFee;
        listing.poolFee = poolFee;
        fixedPriceListings[_tokenId] = listing;

        emit MktUpdatedFixedPrice(address(pocNft), _tokenId, msg.sender, _listPrice, marketFee, starterFee, poolFee);
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

    /**
     * @dev The initialization function required to init a new VCProject contract that VCStarter deploys using
     * Clones.sol (no constructor is invoked).
     *
     * @notice This function can be invoked at most once because uses the {initializer} modifier.
     *
     * @param starter The VCStarter contract address.
     * @param pool The VCPool contract address.
     * @param lab The address of the laboratory/researcher who owns this project.
     * @param poolFeeBps Pool fee in basis points. Any project/campaign donation is subject to a fee which is
     * transferred to VCPool.
     * @param currency The protocol {_currency} ERC20 contract address, which is used for all donations.
     * Donations in any other ERC20 currecy or of any other type are not allowed.
     */
    function init(
        address starter,
        address pool,
        address lab,
        uint256 poolFeeBps,
        IERC20 currency
    ) external;

    /**
     * @dev Allows to fund the project directly, i.e. the contribution received is not linked to any campaign.
     * The donation is made in the protocol ERC20 {_currency}, which is set at the time of deployment of the
     * VCProject contract.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @param _amount The amount of the donation.
     */
    function fundProject(uint256 _amount) external;

    /**
     * @dev Allows the lab owner to close the project. A closed project cannot start new campaigns nor receive
     * new contributions.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @notice Only VCProjects with a zero balance (the lab ownwer must have previously withdrawn all funds) and
     * non-active campaigns can be closed.
     */
    function closeProject() external;

    /**
     * @dev Allows the lab owner of the project to start a new campaign.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @param _target The maximum amount of ERC20 {_currency} expected to be raised.
     * @param _softTarget The minimum amount of ERC20 {_currency} expected to be raised.
     * @param _startTime The starting date of the campaign in seconds since the epoch.
     * @param _endTime The end date of the campaign in seconds since the epoch.
     * @param _backersDeadline The deadline date (in seconds since the epoch) for backers to withdraw funds
     * in case the campaign turns out to be NOT FUNDED. After that date, unclaimed funds can only be transferred
     * to VCPool and backers can mint a PoCNFT for their contributions.
     *
     * @return currentId The Id of the started campaign.
     */
    function startCampaign(
        uint256 _target,
        uint256 _softTarget,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _backersDeadline
    ) external returns (uint256 currentId);

    /**
     * @dev Allows the lab owner of the project to publish the results of their research achievements
     * related to their latest SUCCEEDED campaign.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @notice Lab owner must do this before starting a new campaign or closing the project.
     */
    function publishCampaignResults() external;

    /**
     * @dev Allows a user to fund the last running campaign, only when it is ACTIVE.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @param _user The address of the user who makes the dontation.
     * @param _amount The amount of ERC20 {_currency} donated by the user.
     */
    function fundCampaign(address _user, uint256 _amount) external;

    /**
     * @dev Checks if {_user} can mint a PoCNFT for their contribution to a given campaign, and also
     * registers the mintage to forbid a user from claiming multiple PoCNFTs for the same contribution.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the function {backerMintPoCNft} of
     * VCStarter.
     *
     * @notice Two PoCNFTs are minted: one for the contribution to the Project and the other one for
     * the contribution to VCPool (fee).
     *
     * @param _campaignId The campaign Id for which {_user} claims the PoCNFTs.
     * @param _user The address of the user who claims the PoCNFTs.
     *
     * @return poolAmount The amount of the donation corresponding to VCPool.
     * @return starterAmount The amount of the donation corresponding to the Project.
     */
    function validateMint(uint256 _campaignId, address _user)
        external
        returns (uint256 poolAmount, uint256 starterAmount);

    /**
     * @dev Allows a user to withdraw funds previously contributed to the last running campaign, only when NOT
     * FUNDED.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @param _user The address of the user who is withdrawing funds.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return backerBalance The amount of ERC20 {_currency} donated by the user.
     * @return statusDefeated It is set to true only when the campaign balance reaches zero, indicating that all
     * backers have already withdrawn their funds.
     */
    function backerWithdrawDefeated(address _user)
        external
        returns (
            uint256 currentCampaignId,
            uint256 backerBalance,
            bool statusDefeated
        );

    /**
     * @dev Allows the lab owner of the project to withdraw the raised funds of the last running campaign, only
     * when FUNDED.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return withdrawAmount The withdrawn amount (raised funds minus pool fee).
     * @return poolAmount The fee amount transferred to VCPool.
     */
    function labCampaignWithdraw()
        external
        returns (
            uint256 currentCampaignId,
            uint256 withdrawAmount,
            uint256 poolAmount
        );

    /**
     * @dev Allows the lab owner of the project to withdraw funds raised from direct contributions.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @return amountToWithdraw The amount withdrawn, which corresponds to the total available project balance
     * excluding the balance raised from campaigns.
     */
    function labProjectWithdraw() external returns (uint256 amountToWithdraw);

    /**
     * @dev Users can send any ERC20 asset to this contract simply by interacting with the 'transfer' method of
     * the corresponding ERC20 contract. The funds received in this way do not count for the Project balance,
     * and are allocated to VCPool. This function allows any user to transfer these funds to VCPool.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @param currency The ERC20 currency of the funds to be transferred to VCPool.
     *
     * @return amountAvailable The transferred amount of ERC20 {currency}.
     */
    function withdrawToPool(IERC20 currency) external returns (uint256 amountAvailable);

    /**
     * @dev Allows any user to transfer unclaimed campaign funds to VCPool after {_backersDeadline} date, only
     * when NOT FUNDED.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return amountToPool The amount of ERC20 {currency} transferred to VCPool.
     */
    function transferUnclaimedFunds() external returns (uint256 currentCampaignId, uint256 amountToPool);

    /**
     * @dev Returns the total number of campaigns created by this Project.
     *
     * @return numbOfCampaigns
     */
    function getNumberOfCampaigns() external view returns (uint256);

    /**
     * @dev Returns the current campaign status of any given campaign.
     *
     * @param _campaignId The campaign Id.
     *
     * @return currentStatus
     */
    function getCampaignStatus(uint256 _campaignId) external view returns (CampaignStatus currentStatus);

    /**
     * @dev Determines if the {_amount} contributed to the last running campaign exceeds the amount needed to
     * reach the campaign's target. In that case, the additional funds are allocated to VCPool.
     *
     * @notice Only VCStarter can invoke this function.
     *
     * @param _amount The amount of ERC20 {_currency} contributed by the backer.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return amountToCampaign The portion of the {_amount} contributed that is allocated to the campaign.
     * @return amountToPool The (possible) additional funds allocated to VCPool.
     * @return isFunded This boolean parameter is set to true only when the amount donated exceeds or equals the
     *  amount needed to reach the campaign's target, indicating that the campaign is now FUNDED.
     */
    function getFundingAmounts(uint256 _amount)
        external
        view
        returns (
            uint256 currentCampaignId,
            uint256 amountToCampaign,
            uint256 amountToPool,
            bool isFunded
        );

    /**
     * @dev Returns the project status.
     *
     * @return prjctStatus True = active, false = closed.
     */
    function projectStatus() external view returns (bool prjctStatus);

    /**
     * @dev Returns the balance of the last created campaign.
     *
     * @notice Previous campaigns allways have a zero balance, because a laboratory is not allowed to start a new
     * campaign before withdrawing the balance of the last executed campaign.
     *
     * @return lastCampaignBal
     */
    function lastCampaignBalance() external view returns (uint256 lastCampaignBal);

    /**
     * @dev Returns the portion of project balance corresponding to direct contributions not linked to any campaign.
     *
     * @return outsideCampaignsBal
     */
    function outsideCampaignsBalance() external view returns (uint256 outsideCampaignsBal);

    /**
     * @dev Gives the raised amount of ERC20 {_currency} in a given campaign.
     *
     * @param _campaignId The campaign Id.
     *
     * @return campaignRaisedAmnt
     */
    function campaignRaisedAmount(uint256 _campaignId) external view returns (uint256 campaignRaisedAmnt);

    /**
     * @dev Returns true only when the lab that owns the project has already published the results of their
     * research achievements related to a given campaign.
     *
     * @param _campaignId The campaign Id.
     *
     * @return campaignResultsPub
     */
    function campaignResultsPublished(uint256 _campaignId) external view returns (bool campaignResultsPub);
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

    /**
     * @dev Allows to set/change the admin of this contract.
     *
     * @notice Only the current {_admin} can invoke this function.
     *
     * @notice The VCAdmin smart contract is supposed to be the {_admin} of this contract.
     *
     * @param admin The address of the new admin.
     */
    function setAdmin(address admin) external;

    /**
     * @dev Allows to set/change the VCPool address for this contract.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Already deployed VCProject contracts will retain the former VCPool address.
     *
     * @param pool The address of the new VCPool contract.
     */
    function setPool(address pool) external;

    /**
     * @dev Allows to set/change the VCProject template contract address.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Newly created projects will clone the new VCProject template, while already deployed projects
     * will retain the former VCProject template.
     *
     * @param newProjectTemplate The address of the newly deployed VCProject contract.
     */
    function setProjectTemplate(address newProjectTemplate) external;

    /**
     * @dev Allows to set/change the Core-Team address. The Core-Team account has special roles in this contract,
     * like whitelist/blacklist a laboratory and appove/reject new projects.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param newCoreTeam The address of the new Core-Team account.
     */
    function setCoreTeam(address newCoreTeam) external;

    /**
     * @dev Allows to set/change the Tx-Validator address. The Tx-Validator is a special account, whose pk is
     * hardcoded in the VC Backend and is used to automate some project/campaign related processes: start a new
     * campaign, publish campaign results, and close project.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param newTxValidator The address of the new Tx-Validator account.
     */
    function setTxValidator(address newTxValidator) external;

    /**
     * @dev Allows to set/change the ERC20 {_currency} address for this contract.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Already deployed VCProject contracts will retain the former ERC20 {_currency} address.
     *
     * @param currency The address of the new ERC20 currency contract.
     */
    function setCurrency(IERC20 currency) external;

    /**
     * @dev Allows to set/change backers timeout.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice The amount of time backers have to withdraw their contribution if the campaign fails.
     *
     * @param newBackersTimeout The amount of time in seconds.
     */
    function setBackersTimeout(uint256 newBackersTimeout) external;

    /**
     * @dev Allows to set/change the VCPool fee. Any project/campaign donation is subject to a fee, which is
     * eventually transferred to VCPool.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Already deployed VCProject contracts will retain the former VCPool fee.
     *
     * @param newPoolFeeBps The VCPool fee in basis points.
     */
    function setPoolFeeBps(uint256 newPoolFeeBps) external;

    /**
     * @dev Allows to set an account (address) as a whitelisted lab.
     *
     * @notice Only {_coreTeam} can invoke this function.
     *
     * @notice Initially, all accounts are set as blacklisted.
     *
     * @param lab The lab to whitelist.
     */
    function whitelistLab(address lab) external;

    /**
     * @dev Allows to set an account (address) as a blacklisted lab.
     *
     * @notice Only {_coreTeam} can invoke this function.
     *
     * @notice Initially, all accounts are set as blacklisted.
     *
     * @param lab The lab to blacklist.
     */
    function blacklistLab(address lab) external;

    /**
     * @dev The are special accounts (e.g. VCPool, marketplaces) whose donations are not subject to any VCPool
     * fee. This function allows to mark addresses as 'no fee accounts'.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param accounts An array of account/contract addresses to be marked as 'no fee accounts'.
     */
    function addNoFeeAccounts(address[] memory accounts) external;

    /**
     * @dev Allows to set/change the minimum duration of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param minCampaignDuration The minimum duration of a campaign in seconds.
     */
    function setMinCampaignDuration(uint256 minCampaignDuration) external;

    /**
     * @dev Allows to set/change the maximum duration of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param maxCampaignDuration The maximum duration of a campaign in seconds.
     */
    function setMaxCampaignDuration(uint256 maxCampaignDuration) external;

    /**
     * @dev Allows to set/change the minimum target of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param minCampaignTarget The minimum target of a campaign in ERC20 {_currency}.
     */
    function setMinCampaignTarget(uint256 minCampaignTarget) external;

    /**
     * @dev Allows to set/change the maximum target of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param maxCampaignTarget The maximum target of a campaign in ERC20 {_currency}.
     */
    function setMaxCampaignTarget(uint256 maxCampaignTarget) external;

    /**
     * @dev Allows to set/change the soft target basis points. Then, the 'soft-target' of a campaign is computed
     * as target * {_softTargetBps}. The 'soft-target' is the minimum amount a campaign must raise in order to be
     * declared as FUNDED.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param softTargetBps The soft target percentage in basis points
     */
    function setSoftTargetBps(uint256 softTargetBps) external;

    /**
     * @dev Allows to set/change the VCPoCNft address for this contract.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param pocNft The address of the new VCPoCNft contract.
     */
    function setPoCNft(address pocNft) external;

    /**
     * @dev Allows the {_coreTeam} to approve or reject the creation of a new project. The (whitelisted) lab had
     * to previously request the creation of the project, using 'createProjectRequest'.
     *
     * @notice Only {_coreTeam} can invoke this function.
     *
     * @param lab The address of the lab who had requested the creation of a new project.
     * @param accepted True = accepted, false = rejected.
     *
     * @return newProject The address of the created (and deployed) project.
     */
    function createProject(address lab, bool accepted) external returns (address newProject);

    /**
     * @dev Allows a whitelist lab to request the creation of a project. The project will be effetively created
     * after the Core-Team accepts it.
     *
     * @notice Only whitelisted labs can invoke this function.
     */
    function createProjectRequest() external;

    /**
     * @dev Allows to fund a project directly, i.e. the contribution received is not linked to any of its
     * campaigns. The donation is made in the protocol ERC20 {_currency}. The donator recieves a PoCNFT for their
     * contribution.
     *
     * @param project The address of the project beneficiary of the donation.
     * @param amount The amount of the donation.
     */
    function fundProject(address project, uint256 amount) external;

    /**
     * @dev Allows to fund a project directly (the contribution received is not linked to any of its campaigns)
     * on behalf of another user/contract. The donation is made in the protocol ERC20 {_currency}. The donator
     * does not receive a PoCNFT for their contribution.
     *
     * @param user The address of the user on whose behalf the donation is made.
     * @param project The address of the project beneficiary of the donation.
     * @param amount The amount of the donation.
     */
    function fundProjectOnBehalf(address user, address project, uint256 amount) external;

    /**
     * @dev Allows the lab owner of a project to close it. A closed project cannot start new campaigns nor receive
     * new contributions. The Tx-Validator has to 'approve' this operation by providing a signed message.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @notice Only VCProjects with a zero balance (the lab owner must have previously withdrawn all funds) and
     * non-active campaigns can be closed.
     *
     * @param project The address of the project to be closed.
     * @param sig The ECDSA secp256k1 signature performed by the Tx-Validador.
     *
     * The signed message {_sig} can be constructed using ethers JSON by doing:
     *
     * const message = ethers.utils.solidityKeccak256(["address", "address"], [labAddress, projectAddress]);
     * _sig = await txValidator.signMessage(ethers.utils.arrayify(message));
     */
    function closeProject(address project, bytes memory sig) external;

    /**
     * @dev Allows the lab owner of a project to start a new campaign.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project.
     * @param target The amount of ERC20 {_currency} expected to be raised.
     * @param duration The duration of the campaign in seconds.
     * @param sig The ECDSA secp256k1 signature performed by the Tx-Validador.
     *
     * The signed message {_sig} can be constructed using ethers JSON by doing:
     *
     * const message = ethers.utils.solidityKeccak256( ["address","address","uint256","uint256","uint256"],
     *    [labAddress, projectAddress, numberOfCampaigns, target, duration]);
     * _sig = await txValidator.signMessage(ethers.utils.arrayify(message));
     */
    function startCampaign(
        address project,
        uint256 target,
        uint256 duration,
        bytes memory sig
    ) external returns (uint256 campaignId);

    /**
     * @dev Allows the lab owner of the project to publish the results of their research achievements
     * related to their latest SUCCEEDED campaign.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project.
     * @param sig The ECDSA secp256k1 signature performed by the Tx-Validador.
     *
     * The signed message {_sig} can be constructed using ethers JSON by doing:
     *
     * const message = ethers.utils.solidityKeccak256(["address","address","uint256"],
     *      [labAddress, projectAddress, campaignId]);
     * _sig = await txValidator.signMessage(ethers.utils.arrayify(message));
     */
    function publishCampaignResults(address project, bytes memory sig) external;

    /**
     * @dev Allows a user to fund the last running campaign, only when it is ACTIVE.
     *
     * @param project The address of the project.
     * @param amount The amount of ERC20 {_currency} donated by the user.
     */
    function fundCampaign(address project, uint256 amount) external;

    /**
     * @dev Allows a backer to mint a PoCO NFT in return for their contribution to a campaign. The campaign must
     * be FUNDED, or NOT_FUNDED and claming_time > {_backersDeadline} time.
     *
     * @param project The address of the project to which the campaign belongs.
     * @param campaignId The id of the campaign.
     */
    function backerMintPoCNft(address project, uint256 campaignId) external;

    /**
     * @dev Allows a user to withdraw funds previously contributed to the last running campaign, only when NOT
     * FUNDED.
     *
     * @param project The address of the project to which the campaign belongs.
     */
    function backerWithdrawDefeated(address project) external;

    /**
     * @dev Allows the lab owner of the project to withdraw the raised funds of the last running campaign, only
     * when FUNDED.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project to which the campaign belongs.
     */
    function labCampaignWithdraw(address project) external;

    /**
     * @dev Allows the lab owner of the project to withdraw funds raised from direct contributions.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project to which the campaign belongs.
     */
    function labProjectWithdraw(address project) external;

    /**
     * @dev Allows any user to transfer unclaimed campaign funds to VCPool after {_backersDeadline} date, only
     * when NOT FUNDED.
     *
     * @param _project The address of the project to which the campaign belongs.
     */
    function transferUnclaimedFunds(address _project) external;

    /**
     * @dev Users can send any ERC20 asset to this contract simply by interacting with the 'transfer' method of
     * the corresponding ERC20 contract. The funds received in this way do not count for the Project balance
     * and are allocated to VCPool. This function allows any user to transfer these funds to VCPool.
     *
     * @param project The address of the project.
     * @param currency The ERC20 currency of the funds to be transferred to VCPool.
     */
    function withdrawToPool(address project, IERC20 currency) external;

    /**
     * @dev Returns the Pool Fee in Basis Points
     */
    function poolFeeBps() external view returns (uint256);

    /**
     * @dev Returns Min Campaing duration in seconds.
     */
    function minCampaignDuration() external view returns (uint256);

    /**
     * @dev Returns Max Campaing duration in seconds.
     */
    function maxCampaignDuration() external view returns (uint256);

    /**
     * @dev Returns Min Campaign target in USD.
     */
    function minCampaignTarget() external view returns (uint256);

    /**
     * @dev Returns Max Campaign target is USD.
     */
    function maxCampaignTarget() external view returns (uint256);

    /**
     * @dev Returns Soft Target in basis points.
     */
    function softTargetBps() external view returns (uint256);

    /**
     * @dev Returns Fee Denominator in basis points.
     */
    function feeDenominator() external view returns (uint256);

    /**
     * @dev Returns the address of VCStarter {_admin}.
     *
     * @notice The admin of this contract is supposed to be the VCAdmin smart contract.
     */
    function getAdmin() external view returns (address);

    /**
     * @dev Returns the address of this contract ERC20 {_currency}.
     */
    function getCurrency() external view returns (address);

    /**
     * @dev Returns the campaign status of a given project.
     *
     * @param project The address of the project to which the campaign belongs.
     * @param campaignId The id of the campaign.
     *
     * @return currentStatus
     */
    function getCampaignStatus(
        address project,
        uint256 campaignId
    ) external view returns (IVCProject.CampaignStatus currentStatus);

    /**
     * @dev Checks if a given project (address) belongs to a given lab.
     *
     * @param lab The address of the lab.
     * @param project The address of the project.
     *
     * @return True if {_lab} is the owner of {_project}, false otherwise.
     */
    function isValidProject(address lab, address project) external view returns (bool);

    /**
     * @dev Checks if a certain laboratory (address) is whitelisted.
     *
     * @notice Only whitelisted labs can create projects and start new campaigns.
     *
     * @param lab The address of the lab.
     *
     * @return True if {_lab} is whitelisted, False otherwise.
     */
    function isWhitelistedLab(address lab) external view returns (bool);

    /**
     * @dev Checks if certain addresses correspond to active projects.
     *
     * @param projects An array of addresses.
     *
     * @return An array of booleans of the same length as {_projects}, where its ith position is set to true if
     * and only if {projects[i]} correspondes to an active project.
     */
    function areActiveProjects(address[] memory projects) external view returns (bool[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IVCPoCNft is IERC721 {
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

    /**
     * @dev Allows to set/change the admin of this contract.
     *
     * @notice Only the current {_admin} can invoke this function.
     *
     * @notice The VCAdmin smart contract is supposed to be the {_admin} of this contract.
     *
     * @param newAdmin The address of the new admin.
     */
    function setAdmin(address newAdmin) external;

    /**
     * @dev Allows to grant 'minter' role to a given contract/account.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param _address The address of the contract/account to which the 'minter' role is granted.
     */
    function grantMinterRole(address _address) external;

    /**
     * @dev Allows to revoke 'minter' role to a given contract/account.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param _address The address of the contract/account to which the 'minter' role is revoked.
     */
    function revokeMinterRole(address _address) external;

    /**
     * @dev Allows to grant 'approver' role to a given contract/account. An account having this role can call
     * setApprovalForAllCustom(address caller, address operator, bool approved), and thus approve that the
     * account {operator} is authorized to transfer the tokens of {caller}.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param _approver The address of the contract/account to which the 'approver' role is granted.
     */
    function grantApproverRole(address _approver) external;

    /**
     * @dev Allows to revoke 'approver' role to a given contract/account. An account having this role can call
     * setApprovalForAllCustom(address caller, address operator, bool approved), and thus approve that the
     * account {operator} is authorized to transfer the tokens of {caller}.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param _approver The address of the contract/account to which the 'approver' role is revoked.
     */
    function revokeApproverRole(address _approver) external;

    /**
     * @dev Allows to set/change the VCPool address for this contract.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param pool The address of the new VCPool contract.
     */
    function setPool(address pool) external;

    /**
     * @dev Allows to set/change the 'boost duration' of the PoCNFT's boost voting power. Any PoCNFT has a boost
     * voting power that decays linearly over time, from a maximum (= contribution amount) at minting time to
     * zero at minting time + 'boost duration'.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param newBoostDuration The new 'boost duration' in seconds.
     */
    function changeBoostDuration(uint256 newBoostDuration) external;

    /**
     * @dev Allows to set/change the ranges of the total contribution boost voting power. These ranges determine
     * a family of sloops that maps the total contribution in USDC of a user to a voting boost percentage
     * measured in basis points.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param newBoostRanges An array of Ranges. Each Range is a pair {maxDonation, maxBps}, where maxDonation is
     * the maximum donation in USDC of each range and maxBps is the maximum bps of each range. The Ranges must
     * satisfy newBoostRanges.maxDonation[i] > newBoostRanges.maxDonation[i-1] and
     * newBoostRanges.maxBps[i] > newBoostRanges.maxBps[i-1].
     */
    function changeBoostRanges(Range[] calldata newBoostRanges) external;

    /**
     * @dev Allows an user/contract having 'approver' role to authorize/unauthorize the {operator} to transfer
     * the {caller}'s PoCNFTs.
     *
     * @notice Only an account/contract with 'approver' role can invoke this function.
     *
     * @param caller The address of the user/contract to whom the PoCNFTs will be managed.
     * @param operator The address of the user/contract who will be authorized to manage the funds of the {caller}.
     * @param approved True means grant authorization, while false means revoke authorization.
     */
    function setApprovalForAllCustom(address caller, address operator, bool approved) external;

    //function supportsInterface(bytes4 interfaceId) external view override returns (bool);

    /**
     * @dev Returns true if the PoCNFT with id {tokenId} has been alredady minted, otherwise returns false.
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev Returns the voting power boost of a user, which is computed by considering all of their PoCNFTs.
     *
     * @param _user The user address.
     *
     * @return The voting power boost.
     */
    function votingPowerBoost(address _user) external view returns (uint256);

    /**
     * @dev The voting power boost of a user is measured as a ratio/percentage. This percentage has a base
     * 'denominator', which is hardcoded in this contract. This view function returns its value.
     *
     * @return The voting power boost denominator.
     */
    function denominator() external pure returns (uint256);

    /**
     * @dev Each PoCNFT is associated with a user's contribution to VC. Then, this contract records the amount and
     * timestamp of the contribution associated with each PoCNFT, which is stored in a 'Contribution' variable.
     * This view function returns the 'Contribution' associated with a given PoCNFT with id {tokenId}.
     *
     * @return The 'Contribution' which contains amount in USDC and timestamp in seconds from epoch.
     */
    function getContribution(uint256 tokenId) external view returns (Contribution memory);

    /**
     * @dev Allows a user/contract having 'minter' role to mint a PoCNFT with a given contribution {_amount} and
     * assign it to a given {_user}.
     *
     * @notice Only an account/contract with 'minter' role can invoke this function.
     *
     * @param _user The user who receives the PoCNFT.
     * @param _amount The contribution amount associated to the newly minted PoCNFT.
     * @param isPool True if the contribution is associated to a (direct or indirect) VCPool funding, false
     * otherwise.
     *
     * @notice The timestamp of the PoCNFT's contribution is set to block.timestamp.
     */
    function mint(address _user, uint256 _amount, bool isPool) external;

    /**
     * @dev Allows the msg.sender to transfer a PoCNFT in their possesion to a different user/account.
     *
     * @notice This function reverts if the msg.sender tries to transfer a certain PoCNFT that he does not own.
     *
     * @param to The destination address.
     * @param tokenId The id of the PoCNFT to be transferred.
     */
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