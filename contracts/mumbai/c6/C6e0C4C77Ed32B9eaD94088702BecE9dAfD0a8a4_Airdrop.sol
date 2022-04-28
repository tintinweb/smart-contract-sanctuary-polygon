// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

pragma solidity ^0.8.0;


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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

//pragma solidity ^0.6.2;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


pragma solidity 0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity 0.8.7;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


pragma solidity 0.8.7;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {    

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(Address.isContract(address(token)), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.8.7;

interface IERC20Permit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}



pragma solidity ^0.8.0;

// interface IERC20 {
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
//     function balanceOf(address account) external view returns (uint256);
//     function allowance(address owner, address spender) external view returns (uint256);

// }

// interface IERC721 {
//     function safeTransferFrom(address from, address to, uint256 tokenId) external;
//     function balanceOf(address owner) external view returns (uint256 balance);
// }

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract Airdrop {

    address public _owner;
    //uint256 x = 10;     //maximale AirdropPower
    uint256 nftIdCounter = 0;
    address[] whitelist;
    mapping(address => bool) public processedAirdrops;
    bool public pause = false;
    bool public onlyHolder;

    //address _nftCollection = 0x3594098afFaCD1C85E01894a94F0E688c965b75a;  // neon prism nft contract when airdropping other nfts
    //IERC721 public nftContract = IERC721(_nftCollection);
    IERC721Enumerable public nftContract;

    constructor(address nftCollection, address[] memory whitelisted, bool _onlyHolder) {
        nftContract = IERC721Enumerable(nftCollection);
        whitelist = whitelisted;
        onlyHolder = _onlyHolder;
        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender());
        _owner = msg.sender;

    }

    function claimAirdropForNFTHolder() public {
        require(pause == false, "Contract paused");
        require(processedAirdrops[msg.sender] == false, 'airdrop already processed');
        if (whitelist.length > 0){
            require(isWhitelisted(msg.sender) == true, "Not whitelisted");
        }
        require(nftContract.balanceOf(msg.sender) >= 1,"You are not Holder of Neon Prisma NFT");
        uint256[] memory nftIds = totalUnclaimedNFTIds();
        require(nftIds.length > 0, "No NFTs left to airdrop");
        nftContract.safeTransferFrom(address(this), msg.sender, nftIds[nftIds.length - 1]);
        //nftIdCounter += 1;
        processedAirdrops[msg.sender] = true;
    }

    function claimAirdropForWhitelisted() public {
        require(pause == false, 'Contract paused');
        require(onlyHolder == false, 'airdrop only for NFT holder');
        require(processedAirdrops[msg.sender] == false, 'airdrop already processed');
        if (whitelist.length > 0){
            require(isWhitelisted(msg.sender) == true, 'Not whitelisted');
        }
        uint256[] memory nftIds = totalUnclaimedNFTIds();
        require(nftIds.length > 0, 'No NFTs left to airdrop');
        nftContract.safeTransferFrom(address(this), msg.sender, nftIds[nftIds.length - 1]);
        //nftIdCounter += 1;
        processedAirdrops[msg.sender] = true;
    }

    function isWhitelisted(address user) public view returns (bool) {
        bool containUser = false;
        for (uint256 i = 0; i < whitelist.length; i++){
            if (whitelist[i] == user){
                containUser = true;
            }
        }
        return containUser;
    }

    function totalUnclaimedNFTIds() public view returns (uint256[] memory){
        uint256 ownerTokenCount = nftContract.balanceOf(address(this));
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = nftContract.tokenOfOwnerByIndex(address(this), i);
        }
        return tokenIds;
    }

    // function AirdropERC20(IERC20 _token, address[] calldata _to, uint256[] calldata _value, uint256[] calldata _airdropPower) public {
    //     require(_to.length == _value.length, "Receivers and amounts are different length");
    //     for (uint256 i=0; i<_to.length; i++) {
    //         require(_airdropPower[i] >= x, "airdropPower higher then expexted");
    //         require(_token.transferFrom(_owner, _to[i], _value[i] * _airdropPower[i]));
    //     }
    // }

    // function AirdropERC712(IERC721 _token, address[] calldata _to, uint256[] calldata _id, uint256[] calldata _airdropPower) public {
        
    //     require(_to.length == _id.length, "Receivers and IDs are different length");
    //     for(uint256 i = 0; i < _to.length; i++) {
    //         require(_airdropPower[i] >= x, "airdropPower higher then expexted");
    //         _token.safeTransferFrom(_owner, _to[i], _id[i]);
    //     }
    // }

    // function AirdropERC1155(IERC1155 _token, address[] calldata _to, uint256[] calldata _id, uint256[] calldata _amount, uint256[] calldata _airdropPower) public {
        
    //     require(_to.length == _id.length, "Receivers and IDs are different length");
    //     for(uint256 i = 0; i < _to.length; i++) {
    //         require(_airdropPower[i] >= x, "airdropPower higher then expexted");
    //         _token.safeTransferFrom(_owner, _to[i], _id[i], _amount[i] * _airdropPower[i], "");     // _amount[i] * _airdropPower[i] dürfen keine kommazahlen ergeben
    //     }
    // }

    function withdrawRemaining() public {
        require(msg.sender == _owner, "You are not the owner of this contract");
        uint256[] memory nftIds = totalUnclaimedNFTIds();
        for (uint256 i = 0; i < nftIds.length; i++){
            nftContract.safeTransferFrom(address(this), msg.sender, nftIds[i]);
        }
    }

    function setWhitelist(address[] memory addresses) public {
        require(msg.sender == _owner, 'only admin');
        whitelist = addresses;
    }

    function addToWhitelist(address participant) public {
        require(msg.sender == _owner, 'only admin');
        whitelist.push(participant);
    }

    function removeFromWhitelist(address participant) public {
        require(msg.sender == _owner, 'only admin');
        for(uint256 i = 0; i < whitelist.length; i++){
            if (whitelist[i] == participant){
                delete whitelist[i];
            }
        }
    }

    function clearWhitelist() public {
        require(msg.sender == _owner, 'only admin');
        delete whitelist;
    }

    function setPause(bool state) public {
        require(msg.sender == _owner, 'only admin');
        pause = state;
    }

    function setOnlyHolder(bool state) public {
        require(msg.sender == _owner, 'only admin');
        onlyHolder = state;
    }

    function updateAdmin(address newAdmin) external {
        require(msg.sender == _owner, 'only admin');
        _owner = newAdmin;
    }

}