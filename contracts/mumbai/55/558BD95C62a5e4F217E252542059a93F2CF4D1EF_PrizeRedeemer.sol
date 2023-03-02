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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPrize{
   function transferFrom(address, address, uint256) external;
   function tokenIdToPrizeId(uint256) external view returns(uint256);
   function ownerOf(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IPrize.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";



contract PrizeRedeemer is Ownable, IERC721Receiver{
    IPrize public immutable prizeContract;
    address public projectSigner;
    mapping (uint256 => string) public tokenIdToMd5Hash;

    event PrizeClaimed(uint256 tokeId,uint256 prizeId,string md5Hash);

    constructor(address _prizeContractAddress, address _projectSigner){
        prizeContract = IPrize(_prizeContractAddress);
        projectSigner = _projectSigner;
    }

    function updateSigner(address _newProjectSigner) public onlyOwner(){
        projectSigner = _newProjectSigner;
    }

    function claimPrize(
        string memory _md5Hash,
        uint256 _tokenId,
        bytes memory _signature
    ) external {
        require(verify(_md5Hash,_tokenId,_signature), "Prize Redeemer: Verification failed.");
        prizeContract.transferFrom(msg.sender,address(this),_tokenId);
        tokenIdToMd5Hash[_tokenId]=_md5Hash;
        uint256 prizeId= prizeContract.tokenIdToPrizeId(_tokenId);
        emit PrizeClaimed(_tokenId,prizeId,_md5Hash);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }

    function verify(
        string memory _md5Hash,
        uint256 _tokenId,
        bytes memory _signature
    ) public view returns(bool){
        require(_signature.length == 65, "Verify: Invalid signature length");

        bytes memory encodedPayload = abi.encode(_md5Hash,_tokenId);
        bytes32 hash = keccak256(encodedPayload);

        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        assembly {
            sigR := mload(add(_signature, 0x20))
            sigS := mload(add(_signature, 0x40))
            sigV := byte(0, mload(add(_signature, 0x60)))
        }

        bytes32 data = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address recovered = ecrecover(data, sigV, sigR, sigS);
        return recovered == projectSigner;
    }
}