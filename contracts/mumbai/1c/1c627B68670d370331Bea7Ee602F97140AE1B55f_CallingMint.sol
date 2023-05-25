// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


import "./IERC721_NFT.sol";

contract CallingMint is Ownable, Pausable {

    // 0x8EBB2fBCfD38eFC47fC7498243E8D7E5479a4b3e
    /**
     * @dev Counter for maintaining contract address which we set in constructor
    */
    IERC721Token public erc721TokenContract;
    
    /**
     *  @dev Get Zero Address
    */
    address constant ZERO_ADDRESS = address(0);

    /**
     *  @dev Initialize token address 
    */
    constructor() {
        erc721TokenContract = IERC721Token(address(0x2CAef0dC840d7F5FfcB212e4dcB1F1b280602583));
        // setTokenAddress(tokenAddress);

    }

    /**
     * @dev callMintingFunction, function is used to call miniting function of contract which we set.
     * @param to, it is account address where you want to mint.
     * @param tokenUri, tokenUri is set corresponding to the mint tokenId.
    */
    function callMintingFunction(address to, string memory tokenUri) external onlyOwner whenNotPaused{
        require(to != ZERO_ADDRESS , "ERC721Token: Address Cannot be Zero Address");
        erc721TokenContract.safeMint(to, tokenUri);
    }

    /**
     * @dev setTokenAddress, function is used to set the contract address from which we want to call minting function.
     * @param _tokenAddress, it is account address which you set for calling minting.
    */
    function setTokenAddress(address _tokenAddress) external onlyOwner whenNotPaused{
        // require(_tokenAddress != IERC721Token(address(0)), "Contract address already set");
        erc721TokenContract = IERC721Token(_tokenAddress);

    }

    /**
     * @dev pause function is used to pause the contract
     * @dev only owner can pause the contract
    */
    function pause() public  onlyOwner {
        _pause();
    }

    /**
     * @dev unpause function is used to unpause the contract
     * @dev only owner can unpause the contract
    */
    function unpause() public  onlyOwner {
        _unpause();
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;


interface IERC721Token{
    /** 
     * @dev Event emitted when nft will airdrop
    */
    event AirdroppedNFT(uint256 tokenId);

    /** 
     * @dev Event emitted when nft is minted
    */
    event NewNFTMinted(uint256 tokenId);

    /** 
     * @dev Event emitted when token price is updated
    */
    event updatedNewTokenPrice(uint256 _tokenPrice);

    /**
     * @dev Event emitted when owner withdraw contract balance
    */
    event withdrawnEthers(address _to);

    /**
     * @dev Mint a new token 
    */
    function safeMint(address to, string memory tokenUri) external;

    /**
     * @dev Airdrop the Tokens to assigned address by the owner
    */
    function airDrop(address[] calldata account, string[] memory tokenUri) external;

    /**
     * @dev balanceOfContract return the balance of contract
    */
    function balanceOfContract() external view returns(uint256);

    /**
     * @dev Withdraw ethers which pay during the mint 
    */
    function withdraw() external;

    /**
     * @dev Update the Token Price 
    */
    function updateTokenPrice(uint256 _mintPrice) external;

    /**
     * @dev Added the account to blacklist
     */
    function addToBlackList(address[] memory _user) external returns (bool);

    /**
     * @dev Removes the account from blacklist
     */
    function removeFromBlackList(address[] memory _user) external returns (bool);

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
    */
    function pause() external;

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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