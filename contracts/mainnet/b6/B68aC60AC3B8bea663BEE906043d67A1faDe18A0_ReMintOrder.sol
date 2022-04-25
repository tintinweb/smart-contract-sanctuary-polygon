/**
 *Submitted for verification at polygonscan.com on 2022-04-23
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-17
*/

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Owner {
    bool private _contractCallable = false;
    bool private _pause = false;
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);
    event SetContractCallable(bool indexed able, address indexed owner);

    constructor() {
        _owner = msg.sender;
    }

    // ownership
    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function setPendingOwner(address account) public onlyOwner {
        require(account != address(0), "zero address");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }

    function becomeOwner() external {
        require(msg.sender == _pendingOwner, "not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }

    modifier checkPaused() {
        require(!paused(), "paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _pause;
    }

    function setPaused(bool p) external onlyOwner {
        _pause = p;
    }

    modifier checkContractCall() {
        require(contractCallable() || notContract(msg.sender), "non contract");
        _;
    }

    function contractCallable() public view virtual returns (bool) {
        return _contractCallable;
    }

    function setContractCallable(bool able) external onlyOwner {
        _contractCallable = able;
        emit SetContractCallable(able, _owner);
    }

    function notContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size == 0;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface INFTcustom {
    function mint(address recipient_) external returns (uint256);
}

interface ITemplar {
    function setUserReward(
        address,
        uint256,
        uint256
    ) external;

    function getInvitation(address account)
        external
        view
        returns (
            address,
            address[] memory,
            uint256,
            uint256
        );
}

contract ReMintOrder is Owner {
    using SafeMath for uint256;

    uint256 public maxEnergy = 100;
    // uint256 public energyCD = 2 hours;
    uint256 public energyCD = 60;
    mapping(uint256 => uint256) public lastEnergyAt;

    uint256 public recoveryFee;

    address public pdToken;
    address public pdPair;
    address public ngcToken;

    address public platformAddress;

    ITemplar public immutable templar;

    address public slaveToken;

    address[] public orderNFTList;
    uint256[] public orderPriceList;

    address[] public compositeNFTList;

    address public destroyAddress =
        address(0x000000000000000000000000000000000000dEaD);

    event ReMint(address indexed tokenAddress, uint256 indexed tokenId);
    event Recovery(
        address indexed user,
        uint256 energy,
        uint256 indexed tokenId
    );
    event Composite(address indexed user, uint256 indexed tokenId);

    constructor(
        ITemplar templar_,
        address slaveToken_,
        address pdToken_,
        address pdPair_,
        address ngcToken_,
        address[] memory compositeNFTList_
    ) Owner() {
        templar = templar_;
        slaveToken = slaveToken_;
        pdToken = pdToken_;
        pdPair = pdPair_;
        ngcToken = ngcToken_;
        compositeNFTList = compositeNFTList_;

        platformAddress = msg.sender;
    }

    receive() external payable {}

    function setRecoveryFee(uint256 newRecoveryFee) public onlyOwner {
        recoveryFee = newRecoveryFee;
    }

    function setpdTokenInfo(address newpdToken, address newpdPair)
        public
        onlyOwner
    {
        pdToken = newpdToken;
        pdPair = newpdPair;
    }

    function setPlatformAddress(address _token) public onlyOwner {
        require(_token != address(0), "_token is empty");

        platformAddress = _token;
    }

    function setOrderSupply(
        address[] memory _addressList,
        uint256[] memory _priceList
    ) external onlyOwner {
        require(_addressList.length > 0, "_addressList is empty");
        require(
            _addressList.length == _priceList.length,
            "Inconsistent array length"
        );

        for (uint256 nIndex = 0; nIndex < _addressList.length; nIndex++) {
            require(_addressList[nIndex] != address(0), "NFT address is empty");
        }
        orderNFTList = _addressList;
        orderPriceList = _priceList;
    }

    function orderMint(address tokenAddress, uint256 nftAmount)
        external
        checkContractCall
        checkPaused
    {
        uint256 ind = queryTokenAddressIndex(tokenAddress);
        require(ind != 9999, "list can not find this token");

        uint256 fee = orderPriceList[ind].mul(nftAmount);
        (address inviter, , , ) = templar.getInvitation(msg.sender);

        uint256 rate = 3;
        IERC20(pdToken).transferFrom(msg.sender, pdPair, fee.mul(3).div(100));
        if (
            inviter != address(0) && IERC721(slaveToken).balanceOf(inviter) > 0
        ) {
            IERC20(pdToken).transferFrom(
                msg.sender,
                inviter,
                fee.mul(5).div(100)
            );
            templar.setUserReward(msg.sender, fee.mul(5).div(100), 0);

            rate += 5;
        }
        IERC20(pdToken).transferFrom(
            msg.sender,
            platformAddress,
            fee.mul(100 - rate).div(100)
        );

        for (uint256 index = 0; index < nftAmount; index++) {
            uint256 tid = INFTcustom(tokenAddress).mint(msg.sender);
            if (tokenAddress == slaveToken) lastEnergyAt[tid] = block.timestamp;
        }
    }

    function _getEnergy(address tokenAddress, uint256 tokenId)
        private
        view
        returns (uint256)
    {
        require(tokenAddress == slaveToken, "character error");

        uint256 r = (block.timestamp - lastEnergyAt[tokenId]) / energyCD;

        if (r >= maxEnergy) return 0;

        if (lastEnergyAt[tokenId] == 0) return maxEnergy;

        return maxEnergy.sub(r);
    }

    function getEnergy(address tokenAddress, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return _getEnergy(tokenAddress, tokenId);
    }

    function reMint(address tokenAddress, uint256[] memory tokenIds)
        external
        checkContractCall
        checkPaused
    {
        uint256 amount = 3;
        if (tokenAddress == slaveToken) amount = 10;

        uint256 resj = tokenIds.length / amount;
        uint256 res = tokenIds.length % amount;
        require(res == 0, "amount of errors");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(tokenAddress).ownerOf(tokenIds[i]) == msg.sender,
                "one nft is not belong to you"
            );
            IERC721(tokenAddress).transferFrom(
                msg.sender,
                destroyAddress,
                tokenIds[i]
            );
        }

        uint256 ind = queryTokenAddressIndex(tokenAddress);
        for (uint256 j = 0; j < resj; j++) {
            uint256 tokenid = INFTcustom(orderNFTList[ind + 1]).mint(
                msg.sender
            );
            emit ReMint(orderNFTList[ind + 1], tokenid);
        }
    }

    function composite(address[] memory addrs, uint256[] memory tokenIds)
        external
        checkContractCall
        checkPaused
    {
        require(
            compositeNFTList.length == addrs.length &&
                compositeNFTList.length == tokenIds.length,
            "invalid length"
        );

        for (uint256 i = 0; i < compositeNFTList.length; i++) {
            address nft = addrs[i];
            uint256 tokenId = tokenIds[i];
            require(nft == compositeNFTList[i], "invalid nft");
            require(
                IERC721(nft).ownerOf(tokenId) == msg.sender,
                "one nft is not belong to you"
            );
            IERC721(nft).transferFrom(msg.sender, destroyAddress, tokenId);
        }

        uint256 tokenid = INFTcustom(orderNFTList[1]).mint(msg.sender);
        emit Composite(msg.sender, tokenid);
    }

    function recovery(
        address tokenAddress,
        uint256 tokenId,
        uint256 energy,
        address payToken
    ) external checkContractCall checkPaused {
        require(tokenAddress == slaveToken, "character error");
        require(
            IERC721(tokenAddress).ownerOf(tokenId) == msg.sender,
            "not yours"
        );

        uint256 eng = _getEnergy(tokenAddress, tokenId);

        require(eng + energy <= maxEnergy, "over flaw");
        uint256 fee = recoveryFee * energy;
        if (payToken == ngcToken) fee = fee.mul(90).div(100);

        IERC20(payToken).transferFrom(msg.sender, platformAddress, fee);

        lastEnergyAt[tokenId] = block.timestamp;

        emit Recovery(msg.sender, energy, tokenId);
    }

    function queryTokenAddressIndex(address tokenAddress)
        private
        view
        returns (uint256)
    {
        for (uint256 ind = 0; ind < orderNFTList.length; ind++) {
            if (orderNFTList[ind] == tokenAddress) {
                return ind;
            }
        }
        return 9999;
    }
}