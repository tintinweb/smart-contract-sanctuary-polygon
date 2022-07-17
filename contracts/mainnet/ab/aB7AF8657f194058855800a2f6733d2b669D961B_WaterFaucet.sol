// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./AdminControl.sol";

interface IPaperPot_faucet is IERC1155 {
    function adminMintPot(address _to, uint _amount) external;
    function adminDistributeWater(address _to, uint _amount) external;
    function adminDistributeFertilizer(address _to, uint _amount) external;
    function exists(uint256 id) external view returns (bool);
}

contract WaterFaucet is AdminControl {
    IPaperPot_faucet private _PAPER_POT;
    uint constant POTTED_PLANT_BASE_TOKENID = 10 ** 6;
    uint constant SHRUB_BASE_TOKENID = 2 * 10 ** 6;

    // tokenId => delegate => owner
//    mapping(uint => mapping(address => address)) private _delegations;

    // tokenId => timestamp
    mapping(uint => uint) private _lastClaims;

    struct CutoffTimes {
        uint24 startTime1;        // 3 bytes
        uint24 endTime1;        // 3 bytes
        uint24 startTime2;        // 3 bytes
        uint24 endTime2;        // 3 bytes
    }

    CutoffTimes cutoffTimes;

    event Claim(address account, uint24[] tokenIds);

    // Constructor
    constructor(
        address PAPER_POT_ADDRESS_
    ) {
        _PAPER_POT = IPaperPot_faucet(PAPER_POT_ADDRESS_);
    }

// Receive Function

    // Fallback Function

    // External Functions

    function claim(uint24[] calldata tokenIds_) external returns (uint) {
        for (uint i = 0; i < tokenIds_.length; i++) {
            require(_eligibleForClaim(tokenIds_[i]), "WaterFaucet: not eligible");
            _lastClaims[tokenIds_[i]] = block.timestamp;
        }
        _PAPER_POT.adminDistributeWater(_msgSender(), tokenIds_.length);
        emit Claim(_msgSender(), tokenIds_);
        return tokenIds_.length;
    }

//    function delegate(uint[] calldata tokenIds_, address account_) external {
//        for (uint i = 0; i < tokenIds_.length; i++) {
//            _validPottedPlant(tokenIds_[i]);
//            require(_PAPER_POT.balanceOf(account_, tokenIds_[i]) > 0, "WaterFaucet: account does not own token");
//            _delegations[tokenIds_[i]][account_] = _msgSender();
//        }
//    }

    // Admin methods
    function setCutoffTimes(CutoffTimes calldata cutoffTimes_) external adminOnly {
        require(cutoffTimes_.startTime1 < 86401, "WaterFaucet: invalid startTime1");
        require(cutoffTimes_.endTime1 < 86401, "WaterFaucet: invalid endTime1");
        require(cutoffTimes_.startTime2 < 86401, "WaterFaucet: invalid startTime2");
        require(cutoffTimes_.endTime2 < 86401, "WaterFaucet: invalid endTime2");
        cutoffTimes = cutoffTimes_;
    }

    // External View

    function getCutoffTimes() external view returns (CutoffTimes memory){
        return cutoffTimes;
    }

    // Internal Functions
//    function _ownerOrDelegate(uint tokenId_, address account_) internal view returns (bool) {
//        if (_PAPER_POT.balanceOf(account_, tokenId_) > 0) {
//            return true;
//        }
//        if (_PAPER_POT.balanceOf(_delegations[tokenId_][_msgSender()], tokenId_) > 0) {
//            return true;
//        }
//        return false;
//    }

    function _eligibleForClaim(uint24 tokenId_) internal view validPottedPlant(tokenId_) returns (bool) {
        // Ensure that token is either owned or delegated
//        require(_ownerOrDelegate(tokenId_, _msgSender()), "WaterFaucet: account not owner or delegate of token");
        require(_PAPER_POT.balanceOf(_msgSender(), tokenId_) > 0, "WaterFaucet: account not owner of token");
        // Check that timestamp is not from previous period
        if (
            _lastClaims[tokenId_] != 0 &&
            (block.timestamp - cutoffTimes.startTime1) / 1 days == (_lastClaims[tokenId_] - cutoffTimes.startTime1) / 1 days
        ) {
            return false;
        }
        uint time = block.timestamp % 1 days;
        if (
            !(time >= cutoffTimes.startTime1 && time < cutoffTimes.endTime1) &&
            !(time >= cutoffTimes.startTime2 && time < cutoffTimes.endTime2)
        ) {
            return false;
        }
        return true;
    }

    // Private Functions
//    function _validPottedPlant(uint tokenId_) private view validPottedPlant(tokenId_) {}


    /**
 * @dev Throws if not a valid tokenId for a pottedplant or does not exist.
     */
    modifier validPottedPlant(uint24 tokenId_) {
        require(
            tokenId_ > POTTED_PLANT_BASE_TOKENID && tokenId_ < SHRUB_BASE_TOKENID,
            "WaterFaucet: invalid potted plant tokenId"
        );
        require(_PAPER_POT.exists(tokenId_), "WaterFaucet: query for nonexistent token");
        _;
    }

    // Payment functions

    function p(
        address token,
        address recipient,
        uint amount
    ) external adminOnly {
        if (token == address(0)) {
            require(
                amount == 0 || address(this).balance >= amount,
                'invalid amount value'
            );
            (bool success, ) = recipient.call{value: amount}('');
            require(success, 'amount transfer failed');
        } else {
            require(
                IERC20(token).transfer(recipient, amount),
                'amount transfer failed'
            );
        }
    }

    receive() external payable {}
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
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract AdminControl is Context {
    // Contract admins.
    mapping(address => bool) private _admins;

    /**
 * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _admins[_msgSender()] = true;
    }

    function setAdmin(address addr, bool add) public adminOnly {
        if (add) {
            _admins[addr] = true;
        } else {
            delete _admins[addr];
        }
    }

    function isAdmin(address addr) public view returns (bool) {
        return true == _admins[addr];
    }

    modifier adminOnly() {
        require(isAdmin(msg.sender), "AdminControl: caller is not an admin");
        _;
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