/// SPDX-License-Identifier: MIT
/// @by: Nativas ClimaTech
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "Context.sol";
import "ERC165.sol";
import "IERC1155Logger.sol";
import "Controllable.sol";

/**
 * @dev Offset Implementation
 */
contract NativasOffset is ERC165, Context, Controllable, IERC1155Logger {
    /**
     * @dev Offset model
     */
    struct OffsetModel {
        uint256 tokenId;
        uint256 amount;
        uint256 date;
        string reason;
    }

    event PerformOffset(
        address indexed account,
        uint256 indexed tokenId,
        uint256 amount,
        string reason
    );

    // Mapping from token identifier to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    // offset data
    mapping(address => OffsetModel[]) private _offsets;
    // offset count
    mapping(address => uint256) private _offsetCount;

    /**
     * @dev Set Offset contract controller.
     */
    constructor() Controllable(_msgSender()) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool success)
    {
        return
            interfaceId == type(IERC1155Logger).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {Controllable-_transferControl}.
     */
    function transferControl(address controller_) public virtual {
        require(
            controller() == _msgSender(),
            "NativasOffset: caller is not the controller"
        );
        require(
            controller_ != address(0),
            "NativasOffset: new controller is the zero address"
        );
        _transferControl(controller_);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            account != address(0),
            "NativasOffset: caller is the zero address"
        );
        return _balances[tokenId][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` caller must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory tokenIds
    ) public view virtual returns (uint256[] memory) {
        require(
            accounts.length == tokenIds.length,
            "NativasOffset: accounts and token ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], tokenIds[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Get the amount of offsets by account
     */
    function getOffsetCount(address account)
        public
        view
        virtual
        returns (uint256)
    {
        return _offsetCount[account];
    }

    /**
     * @dev Get offset data from and account and an index.
     */
    function getOffsetValue(address account, uint256 index)
        public
        view
        virtual
        returns (
            uint256 tokenId,
            uint256 amount,
            uint256 date,
            string memory reason
        )
    {
        OffsetModel memory model = _offsets[account][index];
        return (model.tokenId, model.amount, model.date, model.reason);
    }

    /**
     * @dev See {IERC1155Logger-offset}
     *
     * Requirements:
     *
     * - the caller must be the controller.
     */
    function offset(
        address account,
        uint256 tokenId,
        uint256 amount,
        string memory reason
    ) public virtual override {
        require(
            controller() == _msgSender(),
            "NativasOffset: caller is not the controller"
        );
        _offset(account, tokenId, amount, reason);
    }

    /**
     * @dev internal implementantion
     */
    function _offset(
        address account,
        uint256 tokenId,
        uint256 amount,
        string memory reason
    ) internal virtual {
        _balances[tokenId][account] += amount;
        _offsetCount[account]++;
        _offsets[account].push(
            OffsetModel(tokenId, amount, block.timestamp, reason)
        );
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

/// SPDX-License-Identifier: MIT
/// @by: Nativas ClimaTech
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

/**
 * @title
 */
interface IERC1155Logger {
    function offset(
        address account,
        uint256 tokenId,
        uint256 amount,
        string memory reason
    ) external;
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas ClimaTech
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism.
 */
contract Controllable is Context {
    address private _controller;

    event ControlTransferred(
        address indexed oldController,
        address indexed newControllerr
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial controller.
     */
    constructor(address controller_) {
        _transferControl(controller_);
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view virtual returns (address) {
        return _controller;
    }

    /**
     * @dev Transfers control of the contract to a new account (`controller_`).
     * Can only be called by the current controller.
     *
     * NOTE: Renouncing control will leave the contract without a controller,
     * thereby removing any functionality that is only available to the controller.
     */
    function _transferControl(address controller_) internal virtual {
        address current = _controller;
        _controller = controller_;
        emit ControlTransferred(current, controller_);
    }
}