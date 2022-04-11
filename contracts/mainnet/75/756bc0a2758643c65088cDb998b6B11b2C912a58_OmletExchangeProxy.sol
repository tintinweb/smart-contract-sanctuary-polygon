// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../omlet_auth/IOmletNftAuth.sol";
import "./IOmletExchangeProxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC1155 {
    function count() external view returns (uint);
    function increment() external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract OmletExchangeProxy is IOmletExchangeProxy {
    address public immutable _omAuth;

    constructor(address omAuth_) {
        _omAuth = omAuth_;
    }

    modifier onlyTrusted() {
        if (_isTrusted() == false) {
            revert(
                OM_ERROR_FACTORY(
                    "INVALID_OPERATOR",
                    "reason",
                    Strings.toHexString(uint256(uint160(msg.sender))),
                    ""
                )
            );
        }
        _;
    }

    function _isTrusted() internal view returns (bool) {
        if (_omAuth != address(0)) {
            return IOmletNftAuth(_omAuth).isTrusted(msg.sender);
        }
        return false;
    }

    function safeTransferFrom1155(address contractAddress, address from, address to, uint256 id, uint256 amount) external override onlyTrusted {
        IERC1155(contractAddress).safeTransferFrom(from, to, id, amount, "");
    }

    function safeBatchTransferFrom1155(address contractAddress, address from, address to, uint256[] memory ids, uint256[] memory amounts) external override onlyTrusted {
        IERC1155(contractAddress).safeBatchTransferFrom(from, to, ids, amounts, "");
    }

    function safeTransferFrom721(address contractAddress, address from, address to, uint256 tokenId) external override onlyTrusted {
        IERC721(contractAddress).safeTransferFrom(from, to, tokenId);
    }

    function OM_ERROR_FACTORY(
        string memory reason,
        string memory subReason,
        string memory value1,
        string memory value2
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "OM_ERROR_FACTORY_V1",
                    ",",
                    reason,
                    ",",
                    subReason,
                    ",",
                    value1,
                    ",",
                    value2
                )
            );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmletNftAuth {
    /*
     *  admin can be treated as operator,
     */
    function isTrusted(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmletExchangeProxy {
    function safeTransferFrom1155(address contractAddress, address from, address to, uint256 id, uint256 amount) external;

    function safeBatchTransferFrom1155(address account, address from, address to, uint256[] memory ids, uint256[] memory amounts) external;

    function safeTransferFrom721(address contractAddress, address from, address to, uint256 tokenId) external;
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