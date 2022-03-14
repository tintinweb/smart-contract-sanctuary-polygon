// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract ERC721Token {
    function balanceOf(address owner) public view virtual returns (uint256);

    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function setApprovalForAll(address operator, bool _approved)
        external
        virtual;

    function isApprovedForAll(address owner, address operator)
        external
        view
        virtual
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual;
}

contract NftBatch is Context {
    constructor() {}

    function safeBatchTransferFrom(
        address _contractAddr,
        address[] memory accounts,
        uint256[] memory ids
    ) public virtual {
        ERC721Token nft = ERC721Token(_contractAddr);

        require(
            (accounts.length > 0) &&
                (ids.length > 0) &&
                (accounts.length == ids.length),
            "NftBatch: length of accounts must eq length of ids"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 id = ids[i];
            address to = accounts[0];

            require(id >= 0, "NftBatch: Token ID must >= 0");
            require(
                to != address(0),
                "NftBatch: account cannot be zero address"
            );

            nft.safeTransferFrom(_contractAddr, to, id);
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