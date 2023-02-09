// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IUCSCertificate is IERC721 {
    function issueCertificate(
        address to,
        string calldata _ipfsCID
    ) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IUCSToken is IERC20 {
    function burn(uint256 amount) external;

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUCSToken.sol";
import "./interfaces/IUCSCertificate.sol";

/**
 * @author  Emana Group.
 * @title   UCSMarket.
 * @dev     Stores UCS tokens, tracks users balances, and allows its burning.
 * @notice  This Smart Contract represents the primary market of UCS tokens.
 */
contract UCSMarket is Ownable {
    /**
     * @notice  A reference to the NFT Certificate smart contract.
     */
    IUCSCertificate public certicateSC;

    /**
     * @notice  A reference to the UCS smart contract.
     */
    IUCSToken public ucsToken;

    /**
     * @notice  The price of the UCS token in relation to the chain's base asset.
     * @dev     It's intended to be manually set by the owner.
     */
    uint256 public ucsBaseAssetPrice;

    /**
     * @notice  Tracks UCS balance of each address in the Primary Market.
     */
    mapping(address => uint256) public balances;

    /**
     * @notice  A switch that can be used to allow funds to be withdrawn from
     *          this primary market and potentially going to a secondary market.
     * @dev     Only the owner is allowed to switch it on.
     */
    bool public allowSecondaryMarket;

    event Deposit(address sender, uint256 amount);
    event Buy(address buyer, uint256 amount, uint256 price);
    event Transfer(address from, address to, uint256 amount);
    event Withdraw(address to, uint256 amount);
    event BurnUCS(address from, uint256 amount);
    event CertificateIssued(
        address to,
        uint256 ucsBurned,
        uint256 tokenId,
        string certificateCID
    );

    constructor(address _ucsToken, address _certificateSC) {
        ucsToken = IUCSToken(_ucsToken);
        certicateSC = IUCSCertificate(_certificateSC);
        allowSecondaryMarket = false;
    }

    /**
     * @notice  Allows UCS tokens to be deposited in this contract.
     * @param   amount  The amount of UCSs to be deposited.
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Must deposit a positive amount");

        // Requires this SC to have enough allowance to expend users balance
        require(
            ucsToken.allowance(msg.sender, address(this)) >= amount,
            "Approval failed"
        );

        // Make the deposit
        require(
            ucsToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        // Updates sender's balance
        balances[msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice  Allow UCSs held by this contract to be bought.
     * @param   amount  The amount of UCSs to be bought.
     */
    function buy(uint256 amount) external payable {
        require(amount > 0, "Trying to buy 0 tokens");
        require(balances[owner()] >= amount, "Not enough tokens in reserve");

        require(
            msg.value >=
                (amount * ucsBaseAssetPrice) / (10 ** ucsToken.decimals()),
            "Insuficient payment for amount"
        );

        // Adjusts balances
        balances[msg.sender] += amount;
        balances[owner()] -= amount;

        emit Buy(msg.sender, amount, ucsBaseAssetPrice);
    }

    /**
     * @notice  Transfers 'amount' of UCS tokens, in the Primary Market,
     *          from tx caller to 'to'.
     * @param   amount  The amount of UCS tokens to be transfered.
     * @param   to  The address of the recipiente of the tokens.
     */
    function transfer(uint256 amount, address to) external {
        require(balances[msg.sender] >= amount, "Insuficient balance");

        // Adjusts balances
        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    /**
     * @notice  Allows UCS withdrawals.
     * @dev     Normal users are allowed to withdraw if the "secondary market" is enabled,
     *          the "owner" is always allowed to withdraw an amount within his balance
     * @param   amount  The amount to be withdrawn.
     */
    function withdraw(uint256 amount) external {
        if (msg.sender != owner()) {
            // If the caller is not the owner, we check if secondary market is enabled
            require(
                allowSecondaryMarket,
                "You can't withdraw: Secondary market not allowed"
            );
        }
        // Checks if the caller has enough balance to withdraw
        require(
            balances[msg.sender] >= amount,
            "You don't have enough balance"
        );
        // Adjusts balance
        balances[msg.sender] -= amount;
        // Withdraw tokens
        ucsToken.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @notice  Burns UCS tokens held by this contract(primary market).
     * @param   from  The address of the owner of the UCSs to be burned.
     * @param   amount  The amount of UCSs to be burned.
     */
    function _burn(address from, uint256 amount) internal {
        require(balances[from] >= amount, "Not enough balance");
        // Ajusts balance of "from"
        balances[from] -= amount;
        // Burns "amount" of tokens held by this contract
        ucsToken.burn(amount);

        emit BurnUCS(from, amount);
    }

    /**
     * @notice  Issues a NFT certificate to "to" related to the burning of UCSs tokens.
     * @dev     Only the owner can call this function.
     * @param   to  The recipient of the certificate.
     * @param   ucsAmount  The amount of UCSs to be burned.
     * @param   certificateCID  The reference to the certificate metadata on IPFS.
     * @return  uint256  The id of certificate NFT.
     */
    function issueCertificate(
        address to,
        uint256 ucsAmount,
        string calldata certificateCID
    ) external onlyOwner returns (uint256) {
        // Burns the tokens held by this SC which belong to "to"
        _burn(to, ucsAmount);
        // Issues the certificate and transfers it to "to". NOTE.: Remember that
        // msg.sender for the following call will refer to the address of this SC,
        // so this SC will need to have MINTER_ROLE in the Certificate SC.
        uint256 tokenId = certicateSC.issueCertificate(to, certificateCID);

        emit CertificateIssued(to, ucsAmount, tokenId, certificateCID);
        return tokenId;
    }

    /**
     * @notice  Allows the owner to update the reference to the UCSToken contract.
     * @param   _ucsToken  The new address of the UCSToken contract.
     */
    function setUCSToken(address _ucsToken) public onlyOwner {
        ucsToken = IUCSToken(_ucsToken);
    }

    /**
     * @notice  Allows the owner to update the reference to the UCSCertificate contract.
     * @param   _ucsCertificate  The new address of the UCSCertificate contract.
     */
    function setUCSCertificate(address _ucsCertificate) public onlyOwner {
        certicateSC = IUCSCertificate(_ucsCertificate);
    }

    /**
     * @notice  Allows the owner to enble UCSs to be withdrawn from the primary market.
     * @dev     The owner can only enable but not disable this feature.
     */
    function enableSecondaryMarket() external onlyOwner {
        allowSecondaryMarket = true;
    }

    /**
     * @notice  Allows the owner to set the UCS price in relation to chain's base asset.
     * @param   _ucsBaseAssetPrice  The price of the UCS in terms of chain's base asset.
     */
    function setUCSBaseAssetPrice(uint256 _ucsBaseAssetPrice) public onlyOwner {
        ucsBaseAssetPrice = _ucsBaseAssetPrice;
    }
}