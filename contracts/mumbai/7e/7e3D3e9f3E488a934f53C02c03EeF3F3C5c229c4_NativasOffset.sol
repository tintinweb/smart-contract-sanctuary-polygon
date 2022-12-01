/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "Strings.sol";
import "Context.sol";
import "IERC1155Logger.sol";
import "Controllable.sol";

/**
 * @dev Offset Implementation
 */
contract NativasOffset is Context, Controllable, IERC1155Logger {

    /**
     * @dev Offset model
     */
    struct Offset {
        uint256 tokenId;
        uint256 value;
        uint256 date;
        string info;
    }

    // offset data
    mapping(address => Offset[]) private _offsets;
    mapping(address => uint256) private _offsetCount;

    /**
     * @dev Set Offset contract controller.
     */
    constructor() Controllable(_msgSender())  { }

    /**
     * @dev See {Controllable-_transferControl}.
     */
    function transferControl(address newController) public virtual {
        require(controller() == _msgSender(), "OFFSETE02");
        _transferControl(newController);
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
            uint256 value,
            uint256 date,
            string memory info
        ) {
        Offset memory data = _offsets[account][index];
        return (data.tokenId, data.value, data.date, data.info);
    }

    /**
     * @dev Get the amount of offsets by account
     */
    function getOffsetCount(address account)
        public
        view
        virtual
        returns (uint256) {
        return _offsetCount[account];
    }

    /**
     * @dev See {OffsetBook-_offset}
     *
     * Requirements:
     *
     * - the caller must be the controller.
     */
    function offset(
        address account,
        uint256 tokenId,
        uint256 value,
        string memory info
    ) public virtual override {
        require(controller() == _msgSender(), "OFFSETE02");
        _offset(account, tokenId, value, info);
    }

    /**
     * @dev
     */
    function _offset(
        address account,
        uint256 tokenId,
        uint256 value,
        string memory info
    ) internal virtual {
        _offsetCount[account]++;
        _offsets[account].push(Offset(tokenId, value, block.timestamp, info));
    }
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

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

/**
 * @title 
 */
interface IERC1155Logger {

    function offset(
        address account,
        uint256 tokenId,
        uint256 value,
        string memory info
    ) external;
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism.
 */
contract Controllable is Context {
    
    address internal _controller;
    
    event ControlTransferred(
        address indexed oldController, 
        address indexed newControllerr
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address controller_) {
        _transferControl(controller_);
    }

    /**
     * @dev Returns the address of the current accessor.
     */
    function controller() public view virtual returns (address) {
        return _controller;
    }

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the current controller.
     *
     * NOTE: Renouncing control will leave the contract without a controller,
     * thereby removing any functionality that is only available to the controller.
     */
    function _transferControl(address newController) internal virtual {
        address oldController = _controller;
        _controller = newController;
        emit ControlTransferred(oldController, newController);
    }
}