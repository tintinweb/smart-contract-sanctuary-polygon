// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Nft {
    function mint(address sender, address[] memory _to, string memory _metadata)
        external
        returns (uint256);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function burn(address _from, uint256 _tokenCounter)
        external
        returns (uint256);

    function mintSingle(address _to, string memory _metadata)
        external
        returns (uint256);
}

contract Messaging is ReentrancyGuard, Ownable {
    Nft private nft;

    struct TokenDetails {
        bool exists;
        address tokenAddress;
        uint256[] AdminNFTsID;
    }

    mapping(address => TokenDetails) public allTokens;

    event TokenAdded(
        uint256 tokenCounter,
        address tokenAddress,
        address deployerAddress
    );
    event TokenRemoved(address tokenAddress);
    event TeamMemeberAdded(
        uint256 tokenCounter,
        address tokenAddress,
        address teamMember
    );
    event TeamMemberRemoved(address tokenAddress, address memberAddress);
    event messageSent(uint256 tokenId, address tokenAddress, string metadata);

    modifier onlyAdmin(address _tokenAddress) {
        uint256 flag = 0;
        for (
            uint256 i = 0;
            i < allTokens[_tokenAddress].AdminNFTsID.length;
            i++
        ) {
            if (
                nft.balanceOf(
                    msg.sender,
                    allTokens[_tokenAddress].AdminNFTsID[i]
                ) > 0
            ) {
                flag = 1;
            }
        }
        require(flag > 0, "Only Admin can call.");
        _;
    }

    constructor(address _nft) {
        nft = Nft(_nft);
    }

    /**
        @notice Adds a token address to the platform and mints an Admin NFT to the deployer. Only the owner of the contract can add a new token.
        @param _tokenAddress the token address 
        @param _deployerAddress the deployer address.
        @param _metadata metadata for the ADMIN NFT.
     */

    function addToken(
        address _tokenAddress,
        address _deployerAddress,
        string memory _metadata
    ) external nonReentrant onlyOwner {
        require(_tokenAddress != address(0), "Token address cannot be Zero.");
        require(
            _deployerAddress != address(0),
            "Deployer address cannot be zero."
        );
        require(!allTokens[_tokenAddress].exists, "Token already exists.");
        uint256 tokenCounter = nft.mintSingle(_deployerAddress, _metadata);

        allTokens[_tokenAddress].exists = true;
        allTokens[_tokenAddress].tokenAddress = _tokenAddress;
        allTokens[_tokenAddress].AdminNFTsID.push(tokenCounter);
        emit TokenAdded(tokenCounter, _tokenAddress, _deployerAddress);
    }

    /**
        @notice Removes a token from the platform and burns all the Roles NFTs for that particular token. Only the owner of the contract can remove a token.
        @param _tokenAddress the token address 
        @param _admin the address of Admin NFT holder.
     */

    function removeToken(address _tokenAddress, address[] memory _admin)
        external
        nonReentrant
        onlyOwner
    {
        require(_tokenAddress != address(0), "Token address cannot be zero.");
        require(allTokens[_tokenAddress].exists, "Token doesn't exist.");
        require(
            _admin.length == allTokens[_tokenAddress].AdminNFTsID.length,
            "Admin NFTs and Admin Addresses must be equal."
        );
        for (uint256 i = 0; i < _admin.length; i++) {
            nft.burn(_admin[i], allTokens[_tokenAddress].AdminNFTsID[i]);
        }
        delete allTokens[_tokenAddress];
        emit TokenRemoved(_tokenAddress);
    }

    /**
        @notice Adds a team member address to a token and mints a Role(EDITOR or VIEWER) NFT to the team member. Only the admin of the token can add a team member.
        @param _tokenAddress the token address 
        @param _address the team member address.
        @param _metadata metadata for the Role NFT.
     */

    function addTeamMember(
        address _tokenAddress,
        address _address,
        string memory _metadata
    ) public nonReentrant onlyAdmin(_tokenAddress) {
        require(_address != address(0), "Address cannot be zero");
        uint256 tokenCounter = nft.mintSingle(_address, _metadata);
        allTokens[_tokenAddress].AdminNFTsID.push(tokenCounter);
        emit TeamMemeberAdded(tokenCounter, _tokenAddress, _address);
    }

    /**
        @notice Removes a team member address from a token and burns the Role(Editor or Viewer) NFT from the team member. Only the admin of the token can remove a team member.
        @param _tokenAddress the token address 
        @param _teamMember the team member address.
        @param _index the index at which the desired NFT ID is at in the list. Can be calculated using getEditorNFTsID()/getViewerNFTsID()
     */

    function removeTeamMember(
        address _tokenAddress,
        address _teamMember,
        uint256 _index
    ) public nonReentrant onlyAdmin(_tokenAddress) {
        nft.burn(_teamMember, allTokens[_tokenAddress].AdminNFTsID[_index]);
        uint256 length = allTokens[_tokenAddress].AdminNFTsID.length;
        allTokens[_tokenAddress].AdminNFTsID[_index] = allTokens[_tokenAddress]
            .AdminNFTsID[length - 1];
        allTokens[_tokenAddress].AdminNFTsID.pop();
        emit TeamMemberRemoved(_tokenAddress, _teamMember);
    }

    /**
        @notice Sends Message as an NFT to the Token holders of a particular token. Only the Admin or the Editor of the token can send message to the Token Holders.
        @param _tokenAddress the token address 
        @param _metadata contains the message in the form of metadata.
        @param _to list of token holder address that the message needs to be sent to.
     */

    function sendMessage(
        address _tokenAddress,
        string memory _metadata,
        address[] memory _to
    ) external nonReentrant onlyAdmin(_tokenAddress) {
        require(
            allTokens[_tokenAddress].exists == true,
            "Token doesn't exists"
        );
        require(_to.length > 0, "Address list cannot be empty");
        uint256 tokenCounter = nft.mint(msg.sender,_to, _metadata);
        emit messageSent(tokenCounter, _tokenAddress, _metadata);
    }

    // --------------------- VIEW FUNCTIONS ---------------------

    /**
        @notice Sends Message as an NFT to the Token holders of a particular token. Only the Admin or the Editor of the token can send message to the Token Holders.
        @param _tokenAddress the token address 
        @return the list of Editor NFTs ID for a particular token address.
     */

    function getAdminNFTsID(address _tokenAddress)
        external
        view
        returns (uint256[] memory)
    {
        require(_tokenAddress != address(0x0), "Token address cannot be zero.");
        require(allTokens[_tokenAddress].exists, "Token doesn't exists.");
        return allTokens[_tokenAddress].AdminNFTsID;
    }
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