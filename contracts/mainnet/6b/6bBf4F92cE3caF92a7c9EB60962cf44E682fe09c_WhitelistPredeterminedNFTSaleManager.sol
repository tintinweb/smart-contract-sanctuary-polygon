// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../utils/MerkleProof.sol";
import "./OwnerWithdrawable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface INFTWithMintById {
    function mintTo(address to) external returns (uint256);
}

error InvalidProof();
error SaleIsNotActive();
error InvalidEtherAmount();
error TokenBalanceToLow();
error NotEnoughTokensAllowed();
error UnsupportedERC20TokenUsedAsPayment();
error PrepaidSaleCannotHavePaymentOptions();
error CannotPayForPrepaidSale();
error CannotClaimAboveMaxAllocation();
error CannotClaimAboveMaxSupplyForSale();

/**
 * @title WhitelistPredeterminedNFTSaleManager
 * @notice Contract for a selling and minting NFTs
 */
contract WhitelistPredeterminedNFTSaleManager is
    OwnerWithdrawable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    event SaleCreate(
        uint256 indexed saleId,
        address nftContract,
        address treasuryAddress,
        bytes32 merkleRoot,
        uint256 maxSupply,
        uint256 maxAllocationPerAccount,
        uint256 ethPrice,
        address[] erc20Addresses,
        uint256[] erc20Prices,
        bool prepaid
    );
    event SaleEnd(uint256 indexed saleId);
    event SaleSoldOut(uint256 indexed saleId);
    event NFTClaim(
        uint256 indexed saleId,
        address indexed account,
        uint256 tokenId,
        address erc20Address
    );

    struct Sale {
        mapping(address => uint256) erc20Prices;
        mapping(address => uint256[]) claimedTokens;
        bytes32 merkleRoot;
        uint256 maxSupply;
        uint256 totalMintedCount;
        uint256 maxAllocationPerAccount;
        uint256 ethPrice;
        //The NFT contract that will be used for minting
        INFTWithMintById nftContract;
        address treasuryAddress;
        bool active;
        bool prepaid;
    }

    mapping(uint256 => Sale) public sales;
    uint256 public saleCount;

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function createSale(
        INFTWithMintById nftContract,
        address treasuryAddress,
        bytes32 merkleRoot,
        uint256 maxSupply,
        uint256 maxAllocationPerAccount,
        uint256 ethPrice,
        address[] memory erc20Addresses,
        uint256[] memory erc20Prices,
        bool prepaid
    ) public onlyOwner {
        saleCount++;

        sales[saleCount].active = true;
        sales[saleCount].merkleRoot = merkleRoot;
        sales[saleCount].maxSupply = maxSupply;
        sales[saleCount].maxAllocationPerAccount = maxAllocationPerAccount;
        sales[saleCount].nftContract = nftContract;
        sales[saleCount].treasuryAddress = treasuryAddress;
        sales[saleCount].prepaid = prepaid;

        if (prepaid) {
            if (ethPrice != 0) {
                revert PrepaidSaleCannotHavePaymentOptions();
            }

            if (erc20Addresses.length != 0 || erc20Prices.length != 0) {
                revert PrepaidSaleCannotHavePaymentOptions();
            }
        } else {
            sales[saleCount].ethPrice = ethPrice;

            for (uint256 i = 0; i < erc20Addresses.length; i++) {
                sales[saleCount].erc20Prices[erc20Addresses[i]] = erc20Prices[
                    i
                ];
            }
        }

        emit SaleCreate(
            saleCount,
            address(nftContract),
            treasuryAddress,
            merkleRoot,
            maxSupply,
            maxAllocationPerAccount,
            ethPrice,
            erc20Addresses,
            erc20Prices,
            prepaid
        );
    }

    function endSale(uint256 saleId) public onlyOwner {
        sales[saleId].active = false;
        emit SaleEnd(saleId);
    }

    function erc20PricesForSale(uint256 saleId, address[] memory erc20Addresses)
        public
        view
        returns (uint256[] memory prices)
    {
        prices = new uint256[](erc20Addresses.length);

        for (uint256 i = 0; i < erc20Addresses.length; i++) {
            prices[i] = sales[saleId].erc20Prices[erc20Addresses[i]];
        }

        return prices;
    }

    function buy(
        uint256 saleId,
        bytes32[] memory merkleProof,
        address erc20Address
    ) public payable nonReentrant {
        _buy(saleId, 1, merkleProof, erc20Address);
    }

    function buyMultiple(
        uint256 saleId,
        uint256 tokenCount,
        bytes32[] memory merkleProof,
        address erc20Address
    ) public payable nonReentrant {
        _buy(saleId, tokenCount, merkleProof, erc20Address);
    }

    function claimedTokens(uint256 saleId, address account)
        public
        view
        returns (uint256[] memory)
    {
        Sale storage sale = sales[saleId];

        return sale.claimedTokens[account];
    }

    function _buy(
        uint256 saleId,
        uint256 tokenCount,
        bytes32[] memory merkleProof,
        address erc20Address
    ) private {
        address msgSender = _msgSender();

        Sale storage sale = sales[saleId];

        if (!sale.active) {
            revert SaleIsNotActive();
        }

        //Users have a maximum amount of tokens they can mint per sale
        //If maxAllocationPerAccount is 0 then there is no limit
        if (
            sale.maxAllocationPerAccount != 0 &&
            sale.claimedTokens[msgSender].length + tokenCount >
            sale.maxAllocationPerAccount
        ) {
            revert CannotClaimAboveMaxAllocation();
        }

        manageSaleTokenIssuence(saleId, sale, tokenCount);

        //If the sale does not have a merkle root, then it does not have a whitelist and no verification is needed
        if (sale.merkleRoot != 0x0) {
            verify(sale.merkleRoot, merkleProof, msgSender);
        }

        if (erc20Address == address(0)) {
            payWithETH(sale, tokenCount);
        } else {
            payWithERC20(erc20Address, sale, tokenCount);
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = mint(sale);
            emit NFTClaim(saleId, msgSender, tokenId, erc20Address);
        }
    }

    function mint(Sale storage sale) private returns (uint256) {
        address msgSender = _msgSender();

        uint256 tokenId = sale.nftContract.mintTo(msgSender);

        sale.claimedTokens[msgSender].push(tokenId);

        return tokenId;
    }

    function payWithETH(Sale storage sale, uint256 tokenCount) private {
        if (sale.prepaid) {
            if (msg.value != 0) {
                revert CannotPayForPrepaidSale();
            }

            return;
        }

        uint256 amount = sale.ethPrice * tokenCount;
        address paymentRecipient = sale.treasuryAddress;

        //If the treasury address is not specified, the payment is done to the contract itself
        if (paymentRecipient == address(0)) {
            paymentRecipient = address(this);
        }

        if (msg.value != amount) {
            revert InvalidEtherAmount();
        } else {
            //If the recipient is not the contract itself, then redirect the ETH to the recipient
            //Otherwise, it is kept with the contract
            if (paymentRecipient != address(this)) {
                (bool sent, ) = paymentRecipient.call{value: amount}("");

                if (!sent) {
                    revert FailedToSendEther();
                }
            }
        }
    }

    function payWithERC20(
        address erc20Address,
        Sale storage sale,
        uint256 tokenCount
    ) private {
        address msgSender = _msgSender();

        if (sale.prepaid) {
            if (erc20Address != address(0)) {
                revert CannotPayForPrepaidSale();
            }

            return;
        }

        address paymentRecipient = sale.treasuryAddress;

        //If the treasury address is not specified, the payment is done to the contract itself
        if (paymentRecipient == address(0)) {
            paymentRecipient = address(this);
        }

        //Check if the ERC20 token is allowed as payment
        if (sale.erc20Prices[erc20Address] == 0) {
            revert UnsupportedERC20TokenUsedAsPayment();
        }

        //Get the price of the NFT in the ERC20 token
        uint256 price = sale.erc20Prices[erc20Address];
        uint256 amount = price * tokenCount;

        //Get the ERC20 token used for payment
        IERC20 token = IERC20(erc20Address);

        //Check if the buyer has enough tokens
        uint256 tokenBalance = token.balanceOf(address(msgSender));
        if (tokenBalance < amount) {
            revert TokenBalanceToLow();
        }

        //Get the amount of tokens allowed to be spent
        uint256 allowance = token.allowance(msgSender, address(this));

        //Check if the buyer allowed enough tokens to be used for the payment
        if (allowance < amount) {
            revert NotEnoughTokensAllowed();
        }

        token.safeTransferFrom(msgSender, paymentRecipient, amount);
    }

    function verify(
        bytes32 merkleRoot,
        bytes32[] memory merkleProof,
        address account
    ) private pure {
        bytes32 node = keccak256(abi.encodePacked(account));

        bool isValid = MerkleProof.verify(merkleProof, merkleRoot, node);

        if (!isValid) {
            revert InvalidProof();
        }
    }

    /**
     * @dev Limits selling tokens to a certain amount (maxSupply)
     * If limit is reached then the sale ends (sale is no longer active)
     */
    function manageSaleTokenIssuence(
        uint256 saleId,
        Sale storage sale,
        uint256 tokenCount
    ) private {
        sale.totalMintedCount += tokenCount;

        if (sale.totalMintedCount > sale.maxSupply) {
            revert CannotClaimAboveMaxSupplyForSale();
        } else if (sale.totalMintedCount == sale.maxSupply) {
            sale.active = false;
            emit SaleSoldOut(saleId);
            emit SaleEnd(saleId);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
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
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error FailedToSendEther();
error AddressCannotBeZero();

/**
 * @title OwnerWithdrawable
 * @dev Contract where the owner can withdraw eth and erc20 tokens
 */
abstract contract OwnerWithdrawable is Ownable {
    event Withdrawal(
        address indexed receiver,
        uint256 ethAmount,
        address[] erc20Addresses,
        uint256[] erc20Amounts
    );

    using SafeERC20 for IERC20;

    function withdraw(
        address receiver,
        uint256 ethAmount,
        address[] memory erc20Addresses,
        uint256[] memory erc20Amounts
    ) external onlyOwner {
        if (receiver == address(0)) {
            revert AddressCannotBeZero();
        }

        //If eth amount to withdraw is not zero then withdraw it
        if (ethAmount != 0) {
            (bool sent, ) = receiver.call{value: ethAmount}("");

            if (!sent) {
                revert FailedToSendEther();
            }
        }

        for (uint256 i = 0; i < erc20Addresses.length; i++) {
            uint256 amount = erc20Amounts[i];

            IERC20 token = IERC20(erc20Addresses[i]);

            token.safeTransfer(receiver, amount);
        }

        emit Withdrawal(receiver, ethAmount, erc20Addresses, erc20Amounts);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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