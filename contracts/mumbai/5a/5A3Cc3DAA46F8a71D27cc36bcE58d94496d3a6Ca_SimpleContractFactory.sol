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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SimpleAccount {
    address public owner;
    address public entryPoint;
    address[] public guardians;
    bool[] public allowRecovery;
    bool public recoveryInitaited;
    string internal message;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of this account");
        _;
    }

    modifier notInRecovery() {
        require(
            recoveryInitaited == false,
            "Can't perform function when in recovery"
        );
        _;
    }

    // modifier refundGas {
    //     uint256 gasAtStart = gasleft();
    //     _;
    //     uint256 gasSpent = gasAtStart - gasleft() + 28925;
    //     payable(msg.sender).transfer(gasSpent * tx.gasprice);
    // }

    constructor(address _entryPoint) {
        owner = tx.origin;
        entryPoint = _entryPoint;
    }

    function setGuardians(address[] memory guardianAddress) public onlyOwner {
        for (uint256 i = 0; i < guardianAddress.length; i++) {
            guardians.push(guardianAddress[i]);
        }
    }

    function execute(
        address target,
        uint256 value,
        bytes memory data
    ) external {
        require(
            msg.sender == address(entryPoint) || msg.sender == owner,
            "account: not Owner or EntryPoint"
        );
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function initiateRecovery(string memory _message) external {
        require(guardians.length != 0, "Set guardians before you recover");
        require(recoveryInitaited == false, "Already in recovery");
        recoveryInitaited = true;
        message = _message;
    }

    function checkRecovery(bytes[] memory signatures) external {
        for (uint256 i = 0; i < signatures.length; i++) {
            bool response = verify(guardians[i], message, signatures[i]);
            allowRecovery.push(response);
        }
    }

    function changeOwner(address newOwner) external {
        require(
            checkAllowedRecovery() == true,
            "Need Guardians approval for recovery"
        );
        owner = newOwner;
    }

    function checkERC20Balances(
        address contractAddress
    ) external view returns (uint256) {
        return IERC20(contractAddress).balanceOf(address(this));
    }

    function checkERC721Balances(
        address contractAddress
    ) external view returns (uint256) {
        return IERC721(contractAddress).balanceOf(address(this));
    }

    function approveERC20(
        address contractAddress,
        address to,
        uint256 amount
    ) external returns (bool) {
        bool success = IERC20(contractAddress).approve(to, amount);
        return success;
    }

    function transferERC20(
        address contractAddress,
        address to,
        uint256 amount
    ) external returns (bool) {
        bool success = IERC20(contractAddress).transfer(to, amount);
        return success;
    }

    function transferERC721(
        address contractAddress,
        address to,
        uint256 tokenId
    ) external returns (bool) {
        IERC721(contractAddress).transferFrom(address(this), to, tokenId);
        return true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function addDeposit() external payable notInRecovery {
        payable(address(this)).call{value: msg.value};
    }

    function withdrawDeposit(
        uint256 amount
    ) public payable onlyOwner notInRecovery {
        payable(entryPoint).transfer(amount);
    }

    function checkAllowedRecovery() internal view returns (bool) {
        uint256 counter;
        for (uint256 i = 0; i < allowRecovery.length; i++) {
            if (allowRecovery[i] == true) {
                counter++;
            }
        }
        if (counter == guardians.length) {
            return true;
        } else {
            return false;
        }
    }

    function getMessageHash(
        string memory _message
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    function getETHSignedMessageHash(
        bytes32 _messageHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recover(
        bytes32 _getSignedMessageHash,
        bytes memory _sig
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        return ecrecover(_getSignedMessageHash, v, r, s);
    }

    function _split(
        bytes memory _sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_sig.length == 65, "Invalid signature length");
        assembly {
            //first 32 bytes is data
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96))) // bcoz we need only 1st byte
        }
        //does not require return bcoz solidity takes it implicitly
    }

    function verify(
        address _signer,
        string memory _message,
        bytes memory _sig
    ) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getETHSignedMessageHash(messageHash);

        return recover(ethSignedMessageHash, _sig) == _signer;
    }

    receive() external payable {}
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./SimpleAccount.sol";

contract SimpleContractFactory {
    mapping(address => address) internal accountDirectory;
    mapping(address => bool) internal deployedCheck;
    address public entryPoint;
    address public owner;
    uint256 public creationAmount;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    constructor(address _entryPoint) {
        entryPoint = _entryPoint;
        owner = msg.sender;
    }

    event Account(address accountAddress);

    function setCreationAmount(uint256 amount) external onlyOwner {
        creationAmount = amount;
    }

    // function updateDirectory(address _updateAddress) public {
    //     require(msg.sender == accountDirectory[msg.sender], "Only account can call this function");
    // }

    //calldata: 0x9dca362f4cc66df99e6c33abca5f0bd962479841a0ccb42165c3444f4d10e14c
    function createAccount() external payable {
        require(creationAmount != 0, "Set creation amount");
        require(
            deployedCheck[msg.sender] == false,
            "You already have a smart contract wallet"
        );
        require(creationAmount == msg.value, "Send complete creation amount");
        SimpleAccount account = new SimpleAccount(entryPoint);
        accountDirectory[msg.sender] = address(account);
        deployedCheck[msg.sender] = true;
        emit Account(address(account));
        payable(address(this)).call{value: creationAmount};
    }

    function getAddress(address) external view returns (address) {
        return accountDirectory[msg.sender];
    }
}