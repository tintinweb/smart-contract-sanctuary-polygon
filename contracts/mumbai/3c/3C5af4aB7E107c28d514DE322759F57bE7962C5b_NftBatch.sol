// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721Token {
    function balanceOf(address owner) public view virtual returns (uint256);

    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function approve(address to, uint256 tokenId) external virtual;

    function getApproved(uint256 tokenId)
        external
        view
        virtual
        returns (address operator);

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

contract NftBatch is Ownable {
    constructor() {}

    function safeBatchTransferFrom(
        address _token,
        address[] memory accounts,
        uint256[] memory ids
    ) public virtual onlyOwner {
        ERC721Token nft = ERC721Token(_token);

        require(
            (accounts.length > 0) &&
                (ids.length > 0) &&
                (accounts.length == ids.length),
            "NftBatch: length of accounts must eq length of ids"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            require(ids[i] >= 0, "NftBatch: Token ID must >= 0");
            address owner = nft.ownerOf(ids[i]);
            nft.safeTransferFrom(owner, accounts[i], ids[i]);
        }
    }

    function safeTransferFrom(
        address _token,
        address to,
        uint256 tokenId
    ) external virtual onlyOwner {
        ERC721Token nft = ERC721Token(_token);
        address owner = nft.ownerOf(tokenId);
        nft.safeTransferFrom(owner, to, tokenId);
    }

    function balanceOf(address _token, address owner)
        public
        view
        virtual
        returns (uint256)
    {
        ERC721Token nft = ERC721Token(_token);
        return nft.balanceOf(owner);
    }

    function approve(
        address _token,
        address to,
        uint256 tokenId
    ) external virtual {
        ERC721Token nft = ERC721Token(_token);
        nft.approve(to, tokenId);
    }

    function getApproved(address _token, uint256 tokenId)
        external
        view
        virtual
        returns (address operator)
    {
        ERC721Token nft = ERC721Token(_token);
        return nft.getApproved(tokenId);
    }

    function setApprovalForAll(
        address _token,
        address operator,
        bool _approved
    ) external virtual {
        ERC721Token nft = ERC721Token(_token);
        nft.setApprovalForAll(operator, _approved);
    }

    function isApprovedForAll(
        address _token,
        address owner,
        address operator
    ) external view virtual returns (bool) {
        ERC721Token nft = ERC721Token(_token);
        return nft.isApprovedForAll(owner, operator);
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