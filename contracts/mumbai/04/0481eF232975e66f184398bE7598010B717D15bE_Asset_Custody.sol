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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9; 

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


interface IDelegator{

    function OnMint(address _contract, address _to, string memory token_uri) external;
    function OnSetText(uint256 creator_addr, string memory newstr) external;

}


contract Asset_Custody is Ownable, IERC721Receiver{

    //key:contract  value: tokenId-->realowner
    mapping (address => mapping (uint => address) ) _collections;

    //creator address to contract address
    mapping (address => address) _address;
    IDelegator private delegator;

    address public s;
    address public a;

    function SetDelegator(address new_addr) public onlyOwner{
        delegator = IDelegator(new_addr);
    }

    function GetDelegator() public view returns (IDelegator){
        return delegator;
    }

    function GetContractAddress(address _creatorAddr) public view returns (address) {
        return _address[_creatorAddr];
    }

    function SetContractAddress(address _creatorAddr, address _contractAddress) public onlyOwner{
        _address[_creatorAddr] = _contractAddress;
    }
 
    function SetRealOwner(address _contract, address buyer_addr, uint256 _tokenId) public onlyOwner returns (uint256){
        _collections[_contract][_tokenId] = buyer_addr;
    }

    function GetRealOwner(address _contract, uint256 _tokenId) public view returns (address) {
        return _collections[_contract][_tokenId];
    }

    function nftMint(address _contract, string memory token_uri) public onlyOwner returns (uint256){
        GetDelegator().OnMint(_contract, address(this), token_uri);
        s = address(this);
        a = msg.sender;
    }

    function nftMint2(address _contract, string memory token_uri) public onlyOwner returns (uint256){
        delegator.OnMint(_contract, address(this), token_uri);
        s = address(this);
        a = msg.sender;
    }

    function nftMint3(address _contract, string memory token_uri) public onlyOwner returns (uint256){
        IDelegator d = IDelegator(0x056A712b8FFDF13ab764976A71563655F8A98F60);

        d.OnMint(_contract, address(this), token_uri);
        s = address(this);
        a = msg.sender;
    }

    function nftMint4(address _contract, string memory token_uri) public onlyOwner returns (uint256){

        s = address(this);
        a = msg.sender;
    }

    function nftTransfer(address _contract, uint256 _tokenId, address from_addr, address to_addr) public onlyOwner {
        address cur_owner = _collections[_contract][_tokenId];
        require(from_addr == cur_owner);
        _collections[_contract][_tokenId] = to_addr;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}