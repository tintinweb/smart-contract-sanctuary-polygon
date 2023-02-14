// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './OwnedByReserv.sol';

contract Custodian is IERC721Receiver, OwnedByReserv {
    error NFTWalletCannotTransfer();
    error WalletAlreadyAssociated();
    error WalletNotFound();

    event TokenWithdrawn(address indexed nft, uint256 indexed tokenId, uint key, address indexed receiver);
    event CoinWithdrawn(address indexed coin, uint256 indexed amount, uint key, address indexed receiver);
    event AddWallet( address indexed wallet, uint256 indexed key);
    event RemoveWallet(address indexed wallet, uint256 indexed key);

    mapping(address => uint) public walletToKey;
    mapping(address => mapping(uint => uint)) public nftTokenToKey;
    mapping(address => mapping(uint => uint)) public coinBalanceToKey;

    constructor(address reservOwnerContract) OwnedByReserv(reservOwnerContract) {}

    function removeElement(address[] memory arr, address remove) private pure returns (address[] memory) {
        address[] memory _arr = new address[](arr.length - 1);
        uint j = 0;
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] != remove) {
                _arr[j] = arr[i];
                j++;
            }
        }
        return _arr;
    }

    function updateWalletToKey(address wallet, uint key, bool add) public onlyReserv {
        require(key > 0, 'INVALID_KEY');

        if (add) {
            if(walletToKey[wallet] != 0) revert WalletAlreadyAssociated();
            walletToKey[wallet] = key;
            emit AddWallet(wallet, key);
        } else if (walletToKey[wallet] == key) {
            delete walletToKey[wallet];
            emit RemoveWallet(wallet, key);
        } else {
            revert WalletNotFound();
        }
    }

    function updateTokenKey(uint key, address nft, uint tokenId) public onlyReserv {
        nftTokenToKey[nft][tokenId] = key;
    }

    function updateCoinKeyBalance(uint key, address coin, uint balance) public onlyReserv {
        require(balance <= IERC20(coin).balanceOf(address(this)), 'INSUFFICIENT_CONTRACT_BALANCE');
        coinBalanceToKey[coin][key] = balance;
    }

    function canClaimToken(address nft, uint tokenId, address claimer) public view returns (bool) {
        return walletToKey[claimer] > 0 && walletToKey[claimer] == nftTokenToKey[nft][tokenId];
    }

    function withdrawToken(address nft, uint tokenId, uint key, address receiver) public onlyReserv {
        require(IERC721(nft).ownerOf(tokenId) == address(this), 'TOKEN_NOT_FOUND');
        delete nftTokenToKey[nft][tokenId];
        IERC721(nft).transferFrom(address(this), receiver, tokenId);
        emit TokenWithdrawn(nft, tokenId, key, receiver);
    }

    function withdrawCoin(address coin, uint amount, uint key, address receiver) public onlyReserv {
        require(IERC20(coin).balanceOf(address(this)) >= amount, 'INSUFFICIENT_CONTRACT_BALANCE');
        IERC20(coin).transfer(receiver, amount);
        emit CoinWithdrawn(coin, amount, key, receiver);
    }

    function claimToken(uint key, address nft, uint256 tokenId) external {
        require(key > 0, 'INVALID_KEY');
        require(walletToKey[msg.sender] == key, 'NOT_USER_WALLET');
        require(nftTokenToKey[nft][tokenId] == key, 'NOT_USER_TOKEN');
        withdrawToken(nft, tokenId, key, msg.sender);
    }

    function claimCoin(uint key, address coin) external {
        require(key > 0, 'INVALID_KEY');
        require(walletToKey[msg.sender] == key, 'NOT_USER_WALLET');
        require(coinBalanceToKey[coin][key] > 0, 'NO_USER_BALANCE');
        uint balance = coinBalanceToKey[coin][key];
        coinBalanceToKey[coin][key] = 0;
        withdrawCoin(coin, balance, key, msg.sender);
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address /** operator */,
        address /** from */,
        uint256 /** tokenId */,
        bytes calldata /** data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'));
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IReservOwner {

    error NotReserv();
    error NotSuperOwner();

    function transferSuperOwnership(address newSuperOwner) external;
    function addManager(address newManager) external;
    function removeManager(address manager) external;
    function setRepresentative(address newRepresentative) external;
    function setTreasury(address newTreasury) external;
    function addCardPayee(address newPayee) external;
    function removeCardPayee(address payee) external;
    function clearCardPayees() external;
    function clearManagers() external;

    function isManager(address manager) external view returns (bool);
    function isCardPayee(address payee) external view returns (bool);
    function isSuperOwner(address owner) external view returns (bool);

    function superOwner() external view returns (address);
    function representative() external view returns (address);
    function treasury() external view returns (address);
    function feeBasis() external view returns (uint256);
    function royaltyBasis() external view returns (uint256);
    function cardPayees() external view returns (address[] memory);
    function managers() external view returns (address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IReservOwner.sol";
import "./OwnedByReservAbstract.sol";

contract OwnedByReserv is OwnedByReservAbstract {
    constructor(address ownerContract_) {
        ownerContract = ownerContract_;
    }    
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./interfaces/IReservOwner.sol";

contract OwnedByReservAbstract  {
    error SenderIsNotReserv();
    error SenderIsNotReservSuperOwner();
    error SenderIsNotAuthorized();

    address public ownerContract;

    modifier onlyReservSuperOwner(){
        if(!IReservOwner(ownerContract).isSuperOwner(msg.sender)) revert SenderIsNotReservSuperOwner();
        _;
    }

    modifier onlyReserv() {
        if(!isReserv(msg.sender)) revert SenderIsNotReserv();
        _;
    }

    modifier onlyOwnerOrReserv() {
        if (!isOwnerOrReserv(msg.sender) ) revert SenderIsNotAuthorized();
        _;
    }


    function isOwnerOrReserv(address addr) public view returns (bool) {
        return addr == owner() || isReserv(addr) ;
    }

    function owner() public view returns(address) {
        return IReservOwner(ownerContract).representative();
    }
    
    function isReservSuperOwner(address addr) public view returns (bool) {
        return IReservOwner(ownerContract).isSuperOwner(addr);
    }

    function isReserv(address addr) public view returns (bool) {
        return IReservOwner(ownerContract).isManager(addr) || isReservSuperOwner(addr);
    }

    function isReservCardPayee(address addr) public view returns (bool) {
        return IReservOwner(ownerContract).isCardPayee(addr);
    }

    function reservTreasury() public view returns (address) {
        return IReservOwner(ownerContract).treasury();
    }

    function reservFeeBasis() public view returns (uint256) {
        return IReservOwner(ownerContract).feeBasis();
    }

    function reservRoyaltyBasis() public view returns (uint256) {
        return IReservOwner(ownerContract).royaltyBasis();
    }

    function reservOwnerContract() public view returns (address) {
        return ownerContract;
    }

}