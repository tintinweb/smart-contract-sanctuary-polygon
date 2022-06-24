// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./INgageN.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract ProofOfX is AccessControl, ERC2771Context {
    bytes32 public constant CREATOR = keccak256("CREATOR");
    bytes32 public constant OPERATOR = keccak256("OPERATOR");
    INgageN public nftAddress;

    mapping(string => bool) public orderExists;

    /**
     * @dev Constructor for ProofOfX contract
     * @param _nftAddress address of the NFT contract
     * @param _forwarder CustomForwarder instance address for ERC2771Context constructor
     */
    constructor(INgageN _nftAddress, address _forwarder)
        ERC2771Context(address(_forwarder))
    {
        nftAddress = _nftAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     @dev modifier to check if the sender is the default admin of PoX contract
     * Revert if the sender is not the admin
     */
    modifier onlyPoXAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PoX: Only Admin");
        _;
    }

    /**
     @dev modifier to check if the sender is the trusted forwarder
     * Revert if the sender is not the trusted forwarder
     */
    modifier onlyTrustedForwarder() {
        require(isTrustedForwarder(msg.sender), "PoX: Only Trusted Forwarder");
        _;
    }

    /**
     @dev Overriding _msgSender function inherited from Context and ERC2771Context
     */
    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    /**
     @dev Overriding _msgData function inherited from Context and ERC2771Context
     */
    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    /**
     * @dev Public function to set NFT address for NgageN interface
     * Reverts if the caller is not admin
     * @param _nftAddress The address that will be set as new NFT address for NgageN interface
     */
    function setNFTAddress(address _nftAddress) public onlyPoXAdmin {
        require(_nftAddress != address(0), "PoX: Invalid address");
        nftAddress = INgageN(_nftAddress);
    }

    /**
     * @dev Public function to set Token URI of particular token id
     * Reverts if the caller is not admin
     * @param id The token id of token
     * @param _tokenUri new token uri of token to be set
     */
    function setTokenURI(uint256 id, string memory _tokenUri)
        public
        onlyPoXAdmin
    {
        nftAddress.setTokenURI(id, _tokenUri);
    }

    /**
     * @dev Public function to get URI for particular token
     * @param id The token id for which uri will be retrieved
     */
    function getTokenURI(uint256 id) public view returns (string memory) {
        return nftAddress.uri(id);
    }

    /**
     * @dev Public function to mint a single new token
     * Reverts if the caller is not trusted forwarder contract
     * @param to The address to which the newly minted tokens will be assigned.
     * Requirements -
     *   to cannot be a null address
     *   if to is a contract address then it must implement IERC1155Receiver.onERC1155Received and return the magic acceptance value
     * @param id The token id of tokens to be minted
     * @param amount The amount of tokens to be minted for this token id
     * @param data The data to be stored in the token
     * @param tokenUri The token metadata to be stored in the token
     */
    function mintNFT(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory tokenUri
    ) public onlyTrustedForwarder {
        require(
            hasRole(CREATOR, to) && (to == _msgSender()),
            "PoX: Only CREATOR with valid signature"
        );
        nftAddress.mintNFT(to, id, amount, data, tokenUri);
    }

    /**
     * @dev Public function to mint a single new token and approve PoX contract
     * Reverts if the caller is not trusted forwarder contract
     * @param to The address to which the newly minted tokens will be assigned.
     * Requirements -
     *   to cannot be a null address
     *   if to is a contract address then it must implement IERC1155Receiver.onERC1155Received and return the magic acceptance value
     * @param id The token id of tokens to be minted
     * @param amount The amount of tokens to be minted for this token id
     * @param data The data to be stored in the token
     * @param tokenUri The token metadata to be stored in the token
     */
    function mintAndApproveNFT(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory tokenUri
    ) public onlyTrustedForwarder {
        require(
            hasRole(CREATOR, to) && (to == _msgSender()),
            "PoX: Only CREATOR with valid signature"
        );
        nftAddress.mintNFT(to, id, amount, data, tokenUri);
        if (!nftAddress.isApprovedForToken(to, address(this), id)) {
            nftAddress.setApprovalForToken(to, address(this), id, true);
        }
    }

    /**
     * @dev Public function to burn existing tokens
     * Reverts if the caller is not PoX Admin
     * @param from The address from which the tokens will be burned.
     * Requirements -
     * from cannot be a null address
     * from must have at least amount tokens of token type id
     * @param id The token ids of tokens to be burned
     * @param amount The amount of tokens to be burned for mentioned token id
     */
    function burnNFT(
        address from,
        uint256 id,
        uint256 amount
    ) public onlyTrustedForwarder {
        require(
            from == _msgSender() && balanceOf(from, id) >= amount,
            "PoX: Only token owner with valid signature can burn his tokens"
        );
        nftAddress.burnNFT(from, id, amount);
    }

    /**
     * @dev Public function to transfer existing tokens of token type id from one account to another
     * Reverts if the caller is not trusted forwarder contract
     * @param from The address from which the tokens transfer will be occur.
     * @param to The address which will receive the tokens.
     * Requirements -
     *      to cannot be a null address
     *      from must have at least amount tokens of token type id
     *      if to is a contract address than it must implement IERC1155Receiver.onERC1155Received and returns the magic acceptance value
     * @param id The token id of tokens to be transferred
     * @param amount The amount of tokens to be transferred for mentioned token id
     * @param orderId The order id of the order to be transferred
     * @param isCreatorGiveaway A flag to indicate if the order is a giveaway
     * @param data The data to be stored in the token
     */
    function transferNFT(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        string memory orderId,
        bool isCreatorGiveaway,
        bytes memory data
    ) public onlyTrustedForwarder {
        require(
            hasRole(OPERATOR, _msgSender()),
            "PoX: Only OPERATOR with valid signature"
        );
        if (!isCreatorGiveaway) {
            require(!orderExists[orderId], "PoX: Repeated Order.");
        }
        nftAddress.safeTransferFrom(from, to, id, amount, data);
        if (!isCreatorGiveaway) {
            orderExists[orderId] = true;
        }
    }

    /**
     * @dev Public function to transfer existing tokens of token type id from one account to another via creator
     * Reverts if the caller is not trusted forwarder contract
     * @param from The address from which the tokens transfer will be occur.
     * @param to The address which will receive the tokens.
     * Requirements -
     *      to cannot be a null address
     *      from must have at least amount tokens of token type id
     *      if to is a contract address than it must implement IERC1155Receiver.onERC1155Received and returns the magic acceptance value
     * @param id The token id of tokens to be transferred
     * @param amount The amount of tokens to be transferred for mentioned token id
     * @param orderId The order id of the order to be transferred
     * @param isCreatorGiveaway A flag to indicate if the order is a giveaway
     * @param data The data to be stored in the token
     */
    function creatorTransferNFT(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        string memory orderId,
        bool isCreatorGiveaway,
        bytes memory data
    ) public onlyTrustedForwarder {
        require(
            hasRole(CREATOR, _msgSender()) && balanceOf(from, id) >= amount,
            "PoX: Only CREATOR with valid signature and sufficient balance"
        );
        if (!isCreatorGiveaway) {
            require(!orderExists[orderId], "PoX: Repeated Order.");
        }
        nftAddress.safeTransferFrom(from, to, id, amount, data);
        if (!isCreatorGiveaway) {
            orderExists[orderId] = true;
        }
    }

    /**
     * @dev Public function to approve & transfer existing tokens of token type id from one account to another
     * Reverts if the caller is not trusted forwarder contract
     * Reverts if the original msgSender() is not token owner
     * @param from The address from which the tokens transfer will be occur.
     * @param to The address which will receive the tokens.
     * Requirements -
     *      to cannot be a null address
     *      from must have at least amount tokens of token type id
     *      if to is a contract address than it must implement IERC1155Receiver.onERC1155Received and returns the magic acceptance value
     * @param id The token id of tokens to be transferred
     * @param amount The amount of tokens to be transferred for mentioned token id
     * @param data The data to be stored in the token
     */
    function approveAndTransferNFT(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyTrustedForwarder {
        require(
            from == _msgSender(),
            "PoX: Only token owner with valid signature"
        );
        if (!nftAddress.isApprovedForToken(from, address(this), id)) {
            nftAddress.setApprovalForToken(from, address(this), id, true);
        }
        nftAddress.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev Public function to mint new tokens in batches
     * Reverts if the caller is not trusted forwarder contract
     * Reverts if the length of ids and amounts is not equal
     * @param to The address to which the newly minted tokens will be assigned.
     * Requirements -
     *   to cannot be a null address
     *   if to is a contract address than it must implement IERC1155Receiver.onERC1155Received and returns the magic acceptance value
     * @param ids The token ids of tokens to be minted
     * @param amounts The amount of tokens to be minted for respective token id
     * @param data The data to be stored in the token
     * @param tokenUris The tokens metadata to be stored in the respective token
     */
    function mintNFTBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        string[] memory tokenUris
    ) public onlyTrustedForwarder {
        require(
            hasRole(CREATOR, to) && (to == _msgSender()),
            "PoX: Only CREATOR with valid signature"
        );
        nftAddress.mintNFTBatch(to, ids, amounts, data, tokenUris);
    }

    /**
     * @dev Public function to mint new tokens in batches and approve them to the PoX contract
     * Reverts if the caller is not trusted forwarder contract
     * Reverts if the length of ids and amounts is not equal
     * @param to The address to which the newly minted tokens will be assigned.
     * Requirements -
     *   to cannot be a null address
     *   if to is a contract address than it must implement IERC1155Receiver.onERC1155Received and returns the magic acceptance value
     * @param ids The token ids of tokens to be minted
     * @param amounts The amount of tokens to be minted for respective token id
     * @param data The data to be stored in the token
     * @param tokenUris The tokens metadata to be stored in the respective token
     */
    function mintAndApproveNFTBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        string[] memory tokenUris
    ) public onlyTrustedForwarder {
        require(
            hasRole(CREATOR, to) && (to == _msgSender()),
            "PoX: Only CREATOR with valid signature"
        );
        nftAddress.mintNFTBatch(to, ids, amounts, data, tokenUris);
        if (!nftAddress.isApprovedForTokens(to, address(this), ids)) {
            nftAddress.setApprovalForTokens(to, address(this), ids, true);
        }
    }

    /**
     * @dev Public function to burn existing tokens in batches
     * Reverts if the caller is not PoX Admin
     * Reverts if the length of ids and amounts is not equal
     * @param from The address from which the tokens will be burned.
     * Requirements -
     *      to cannot be a null address
     *      to must have at least amount tokens of token type id
     * @param ids The token ids of tokens to be burned
     * @param amounts The amount of tokens to be burned for respective token id
     */
    function burnNFTBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyTrustedForwarder {
        require(
            from == _msgSender(),
            "PoX: Only token owner with valid signature can burn his tokens"
        );
        // check if amounts is greater than balance
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                balanceOf(from, ids[i]) >= amounts[i],
                "PoX: Only token owner with sufficient balance can burn his tokens"
            );
        }
        nftAddress.burnNFTBatch(from, ids, amounts);
    }

    /**
     * @dev Public function to transfer existing tokens of token type ids from one account to another
     * Reverts if the caller is not trusted forwarder contract
     * Reverts if the length of ids and amounts is not equal
     * @param from The address from which the tokens transfer will be occur.
     * @param to The address which will receive the tokens.
     * Requirements -
     *       to cannot be a null address
     *       from must have at least amount tokens of token type id
     *       if to is a contract address than it must implement IERC1155Receiver.onERC1155Received and returns the magic acceptance value
     * @param ids The token ids of tokens to be transferred
     * @param amounts The amount of tokens to be transferred for respective token id
     * @param orderId The order id of the order to be transferred
     * @param isCreatorGiveaway A flag to indicate if the order is a giveaway
     */
    function transferNFTBatch(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string memory orderId,
        bool isCreatorGiveaway,
        bytes memory data
    ) public onlyTrustedForwarder {
        require(
            hasRole(OPERATOR, _msgSender()),
            "PoX: Only OPERATOR valid signature"
        );
        if (!isCreatorGiveaway) {
            require(!orderExists[orderId], "PoX: Repeated Order.");
        }
        nftAddress.safeBatchTransferFrom(from, to, ids, amounts, data);
        if (!isCreatorGiveaway) {
            orderExists[orderId] = true;
        }
    }

    /**
     * @dev Public function to transfer existing tokens of token type ids from one account to another via creator
     * Reverts if the caller is not trusted forwarder contract
     * Reverts if the length of ids and amounts is not equal
     * @param from The address from which the tokens transfer will be occur.
     * @param to The address which will receive the tokens.
     * Requirements -
     *       to cannot be a null address
     *       from must have at least amount tokens of token type id
     *       if to is a contract address than it must implement IERC1155Receiver.onERC1155Received and returns the magic acceptance value
     * @param ids The token ids of tokens to be transferred
     * @param amounts The amount of tokens to be transferred for respective token id
     * @param orderId The order id of the order to be transferred
     * @param isCreatorGiveaway A flag to indicate if the order is a giveaway
     */
    function creatorTransferNFTBatch(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string memory orderId,
        bool isCreatorGiveaway,
        bytes memory data
    ) public onlyTrustedForwarder {
        require(
            hasRole(CREATOR, _msgSender()),
            "PoX: Only CREATOR valid signature"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                balanceOf(from, ids[i]) >= amounts[i],
                "PoX: Creator does not have sufficient balance to transfer"
            );
        }
        if (!isCreatorGiveaway) {
            require(!orderExists[orderId], "PoX: Repeated Order.");
        }
        nftAddress.safeBatchTransferFrom(from, to, ids, amounts, data);
        if (!isCreatorGiveaway) {
            orderExists[orderId] = true;
        }
    }

    /**
     * @dev Public function to approve & transfer existing tokens of token type ids from one account to another
     * Reverts if the caller is not trusted forwarder contract
     * Reverts if the original msgSender() is not token owner
     * @param from The address from which the tokens transfer will be occur.
     * @param to The address which will receive the tokens.
     * Requirements -
     *       to cannot be a null address
     *       from must have at least amount tokens of token type id
     *       if to is a contract address than it must implement IERC1155Receiver.onERC1155Received and returns the magic acceptance value
     * @param ids The token ids of tokens to be transferred
     * @param amounts The amount of tokens to be transferred for respective token id
     */
    function approveAndTransferNFTBatch(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyTrustedForwarder {
        require(
            from == _msgSender(),
            "PoX: Only token owner with valid signature"
        );
        nftAddress.setApprovalForTokens(from, address(this), ids, true);
        nftAddress.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Public function to access the total balance for an address for an tokenId
     * @param account The address for which the total balance will be returned
     * @param id The tokenId for which the total balance will be returned
     * @return The total balance for the account and tokenId
     */
    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return nftAddress.balanceOf(account, id);
    }

    /**
     @dev Public function to access the total balances for an array of addresses for an array of tokenId's
     * @param accounts The array of addresses for which the total balances will be returned
     * @param ids The array of tokenId's for which the total balances will be returned
     * @return The array of total balances for each address for each tokenId
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        public
        view
        returns (uint256[] memory)
    {
        return nftAddress.balanceOfBatch(accounts, ids);
    }

    /**
     * @dev Public function to approve existing tokens of particular token id from account to operator
     * reverts if the caller is not trusted forwarder contract
     * also account must be the transaction signer and with creator access
     * @param account The address from which the tokens transfer will be occur.
     * @param operator The address which will receive the tokens.
     * @param id The token id of token to be approved.
     * @param approved The approval status.
     */
    function setApprovalForToken(
        address account,
        address operator,
        uint256 id,
        bool approved
    ) public onlyTrustedForwarder {
        require(
            account == _msgSender(),
            "PoX: Only token owner with valid signature"
        );
        nftAddress.setApprovalForToken(account, operator, id, approved);
    }

    /**
     * @dev Public function to return the status of tokens approved from account to operator
     * @param account The address from which the tokens transfer will be occur.
     * @param operator The address which will receive the tokens.
     * @param id The token id of token to be approved.
     */
    function isApprovedForToken(
        address account,
        address operator,
        uint256 id
    ) public view returns (bool) {
        return nftAddress.isApprovedForToken(account, operator, id);
    }

    /**
     * @dev Public function to approve existing tokens of multiple token ids from account to operator
     * reverts if the caller is not a trusted forwarder contract
     * also account must be the transaction signer and with creator access
     * @param account The address from which the tokens transfer will be occur.
     * @param operator The address which will receive the tokens.
     * @param ids The token id of tokens to be approved.
     * @param approved The approval status.
     */
    function setApprovalForTokens(
        address account,
        address operator,
        uint256[] memory ids,
        bool approved
    ) public onlyTrustedForwarder {
        require(
            account == _msgSender(),
            "PoX: Only token owner with valid signature"
        );
        nftAddress.setApprovalForTokens(account, operator, ids, approved);
    }

    /**
     * @dev Public function to return the status of tokens approved from account to operator
     * @param account The address from which the tokens transfer will be occur.
     * @param operator The address which will receive the tokens.
     * @param ids The token id of tokens to be approved.
     */
    function isApprovedForTokens(
        address account,
        address operator,
        uint256[] memory ids
    ) public view returns (bool) {
        return nftAddress.isApprovedForTokens(account, operator, ids);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address private _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface INgageN is IAccessControlUpgradeable, IERC1155Upgradeable {
    function NFT_OPERATOR_ROLE() external pure returns (bytes32);

    function mintNFT(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory _tokenUri
    ) external;

    function mintNFTBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        string[] memory _tokenUris
    ) external;

    function burnNFT(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function burnNFTBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function setApprovalForToken(
        address account,
        address operator,
        uint256 id,
        bool approved
    ) external;

    function isApprovedForToken(
        address account,
        address operator,
        uint256 id
    ) external view returns (bool);

    function setApprovalForTokens(
        address account,
        address operator,
        uint256[] memory ids,
        bool approved
    ) external;

    function isApprovedForTokens(
        address account,
        address operator,
        uint256[] memory ids
    ) external view returns (bool);

    function setTokenURI(uint256 _tokenId, string memory _tokenUri) external;

    function uri(uint256 _tokenId) external view returns (string memory);
}