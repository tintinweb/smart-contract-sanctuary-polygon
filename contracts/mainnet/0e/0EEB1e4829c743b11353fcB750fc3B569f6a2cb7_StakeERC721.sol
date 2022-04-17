/**
 *Submitted for verification at polygonscan.com on 2022-04-17
*/

// File: contracts/utils/Owner.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// File: contracts/Stake.sol

pragma solidity ^0.8.0;

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

    function transfer(address to, uint256 tokenId) external;
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

contract StakeERC721 is Owner {
    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public feeAccount;
    address public deadAddress =
        address(0x000000000000000000000000000000000000dEaD);

    uint256 public inviteefee = 3;
    uint256 public fee = 2;

    address public pdToken;
    address public ngcToken;

    address public slaveToken;

    address[] public stakeNFTList;

    ITemplar public immutable templar;

    //Mapping of mouse to timestamp
    mapping(address => mapping(uint256 => uint256)) internal tokenIdToTimeStamp;

    //Mapping of mouse to staker
    mapping(address => mapping(uint256 => address)) internal tokenIdToStaker;

    //Mapping of staker to mice
    mapping(address => mapping(address => uint256[])) internal stakerToTokenIds;

    mapping(address => uint256) internal tokenAddressEmissionsRate;

    event Stake(
        address indexed account,
        address indexed tokenAddress,
        uint256 tokenId
    );
    event Unstake(
        address indexed account,
        address indexed tokenAddress,
        uint256 tokenId
    );

    function setTokenAddressEmissionsRate(
        address tokenAddress,
        uint256 EMISSIONS_RATE_
    ) public onlyOwner {
        tokenAddressEmissionsRate[tokenAddress] = EMISSIONS_RATE_;
    }

    function getTokenAddressEmissionsRate(address tokenAddress) public view returns (uint256) {
        return tokenAddressEmissionsRate[tokenAddress];
    }

    function setFeeAccount(address _account) external onlyOwner {
        feeAccount = _account;
    }

    function setInviteeFee(uint256 _fee) public onlyOwner {
        inviteefee = _fee;
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function setPdToken(address _pdToken) public onlyOwner {
        pdToken = _pdToken;
    }

    function setNgcToken(address _ngcToken) public onlyOwner {
        ngcToken = _ngcToken;
    }

    constructor(
        ITemplar templar_,
        address slaveToken_,
        address pdToken_,
        address ngcToken_,
        address[] memory stakeNFTList_
    ) Owner() {
        templar = templar_;
        slaveToken = slaveToken_;
        pdToken = pdToken_;
        ngcToken = ngcToken_;
        stakeNFTList = stakeNFTList_;
        feeAccount = msg.sender;

        setTokenAddressEmissionsRate(stakeNFTList_[0], 4.62962963 * 10 ** 14);
        setTokenAddressEmissionsRate(stakeNFTList_[1], 1.55092593 * 10 ** 15);
        setTokenAddressEmissionsRate(stakeNFTList_[2], 5.48611111 * 10 ** 15);
        setTokenAddressEmissionsRate(stakeNFTList_[3], 2.08333333 * 10 ** 16);
        setTokenAddressEmissionsRate(stakeNFTList_[4], 7.5 * 10 ** 16);
        setTokenAddressEmissionsRate(stakeNFTList_[5], 2.8125 * 10 ** 17);
        setTokenAddressEmissionsRate(stakeNFTList_[6], 9.375 * 10 ** 17);
    }

    function getTokensStaked(
        address staker,
        address tokenAddress,
        uint256 start,
        uint256 limit
    ) public view returns (uint256[] memory) {
        uint256 balance = stakerToTokenIds[staker][tokenAddress].length;
        uint256[] memory tokenIds;
        if (balance > start) {
            uint256 size = balance - start > limit ? limit : balance - start;
            tokenIds = new uint256[](size);
            for (uint256 i = 0; i < size; i++) {
                tokenIds[i] = stakerToTokenIds[staker][tokenAddress][start + i];
            }
        }
        return tokenIds;
    }

    function remove(
        address staker,
        address tokenAddress,
        uint256 index
    ) internal {
        if (index >= stakerToTokenIds[staker][tokenAddress].length) return;

        for (
            uint256 i = index;
            i < stakerToTokenIds[staker][tokenAddress].length - 1;
            i++
        ) {
            stakerToTokenIds[staker][tokenAddress][i] = stakerToTokenIds[
                staker
            ][tokenAddress][i + 1];
        }
        stakerToTokenIds[staker][tokenAddress].pop();
    }

    function removeTokenIdFromStaker(
        address staker,
        address tokenAddress,
        uint256 tokenId
    ) internal {
        for (
            uint256 i = 0;
            i < stakerToTokenIds[staker][tokenAddress].length;
            i++
        ) {
            if (stakerToTokenIds[staker][tokenAddress][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, tokenAddress, i);
            }
        }
    }

    function stakeByIds(address tokenAddress, uint256[] memory tokenIds)
        public
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(tokenAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenAddress][tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            IERC721(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToTokenIds[msg.sender][tokenAddress].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenAddress][tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenAddress][tokenIds[i]] = msg.sender;

            emit Stake(msg.sender, tokenAddress, tokenIds[i]);
        }
    }

    function unstakeAll(address tokenAddress) public {
        require(
            stakerToTokenIds[msg.sender][tokenAddress].length > 0,
            "Must have at least one token staked!"
        );
        uint256 totalRewards = 0;

        for (
            uint256 i = stakerToTokenIds[msg.sender][tokenAddress].length;
            i > 0;
            i--
        ) {
            uint256 tokenId = stakerToTokenIds[msg.sender][tokenAddress][i - 1];

            IERC721(tokenAddress).transfer(
                msg.sender,
                tokenId
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenAddress][tokenId]) *
                    tokenAddressEmissionsRate[tokenAddress]);

            removeTokenIdFromStaker(msg.sender, tokenAddress, tokenId);

            tokenIdToStaker[tokenAddress][tokenId] = nullAddress;

            emit Unstake(msg.sender, tokenAddress, tokenId);
        }

        (address inviter, , , ) = templar.getInvitation(msg.sender);

        uint256 rate = fee;
        if (
            inviter != address(0) && IERC721(slaveToken).balanceOf(inviter) > 0
        ) {
            uint256 fi = (totalRewards * inviteefee) / 100;
            IERC20(pdToken).transfer(inviter, (fi * 6) / 100);
            IERC20(ngcToken).transfer(inviter, (fi * 4) / 100);

            templar.setUserReward(msg.sender, (fi * 6) / 100, (fi * 4) / 100);

            rate += inviteefee;
        }

        uint256 ff = (totalRewards * rate) / 100;
        IERC20(pdToken).transfer(feeAccount, (ff * 6) / 100);
        IERC20(ngcToken).transfer(feeAccount, (ff * 4) / 100);

        uint256 fm = (totalRewards * (100 - inviteefee - fee)) / 100;
        IERC20(pdToken).transfer(msg.sender, (fm * 6) / 100);
        IERC20(ngcToken).transfer(msg.sender, (fm * 4) / 100);
    }

    function unstakeByIds(address tokenAddress, uint256[] memory tokenIds)
        public
    {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenAddress][tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(tokenAddress).transfer(
                msg.sender,
                tokenIds[i]
            );

            totalRewards =
                totalRewards +
                ((block.timestamp -
                    tokenIdToTimeStamp[tokenAddress][tokenIds[i]]) *
                    tokenAddressEmissionsRate[tokenAddress]);

            removeTokenIdFromStaker(msg.sender, tokenAddress, tokenIds[i]);

            tokenIdToStaker[tokenAddress][tokenIds[i]] = nullAddress;

            emit Unstake(msg.sender, tokenAddress, tokenIds[i]);
        }

        (address inviter, , , ) = templar.getInvitation(msg.sender);

        uint256 rate = fee;
        if (
            inviter != address(0) && IERC721(slaveToken).balanceOf(inviter) > 0
        ) {
            uint256 fi = (totalRewards * inviteefee) / 100;
            IERC20(pdToken).transfer(inviter, (fi * 6) / 100);
            IERC20(ngcToken).transfer(inviter, (fi * 4) / 100);

            templar.setUserReward(msg.sender, (fi * 6) / 100, (fi * 4) / 100);

            rate += inviteefee;
        }

        uint256 ff = (totalRewards * rate) / 100;
        IERC20(pdToken).transfer(feeAccount, (ff * 6) / 100);
        IERC20(ngcToken).transfer(feeAccount, (ff * 4) / 100);

        uint256 fm = (totalRewards * (100 - inviteefee - fee)) / 100;
        IERC20(pdToken).transfer(msg.sender, (fm * 6) / 100);
        IERC20(ngcToken).transfer(msg.sender, (fm * 4) / 100);
    }

    function claimByTokenId(address tokenAddress, uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenAddress][tokenId] == msg.sender,
            "Token is not claimable by you!"
        );

        uint256 totalRewards = ((block.timestamp -
            tokenIdToTimeStamp[tokenAddress][tokenId]) *
            tokenAddressEmissionsRate[tokenAddress]);

        tokenIdToTimeStamp[tokenAddress][tokenId] = block.timestamp;

        (address inviter, , , ) = templar.getInvitation(msg.sender);

        uint256 rate = fee;
        if (
            inviter != address(0) && IERC721(slaveToken).balanceOf(inviter) > 0
        ) {
            uint256 fi = (totalRewards * inviteefee) / 100;
            IERC20(pdToken).transfer(inviter, (fi * 6) / 100);
            IERC20(ngcToken).transfer(inviter, (fi * 4) / 100);

            templar.setUserReward(msg.sender, (fi * 6) / 100, (fi * 4) / 100);

            rate += inviteefee;
        }

        uint256 ff = (totalRewards * rate) / 100;
        IERC20(pdToken).transfer(feeAccount, (ff * 6) / 100);
        IERC20(ngcToken).transfer(feeAccount, (ff * 4) / 100);

        uint256 fm = (totalRewards * (100 - inviteefee - fee)) / 100;
        IERC20(pdToken).transfer(msg.sender, (fm * 6) / 100);
        IERC20(ngcToken).transfer(msg.sender, (fm * 4) / 100);
    }

    function claimAll(address tokenAddress) public {
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender][tokenAddress];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenAddress][tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );

            totalRewards =
                totalRewards +
                ((block.timestamp -
                    tokenIdToTimeStamp[tokenAddress][tokenIds[i]]) *
                    tokenAddressEmissionsRate[tokenAddress]);

            tokenIdToTimeStamp[tokenAddress][tokenIds[i]] = block.timestamp;
        }

        (address inviter, , , ) = templar.getInvitation(msg.sender);

        uint256 rate = fee;
        if (
            inviter != address(0) && IERC721(slaveToken).balanceOf(inviter) > 0
        ) {
            uint256 fi = (totalRewards * inviteefee) / 100;
            IERC20(pdToken).transfer(inviter, (fi * 6) / 100);
            IERC20(ngcToken).transfer(inviter, (fi * 4) / 100);

            templar.setUserReward(msg.sender, (fi * 6) / 100, (fi * 4) / 100);

            rate += inviteefee;
        }

        uint256 ff = (totalRewards * rate) / 100;
        IERC20(pdToken).transfer(feeAccount, (ff * 6) / 100);
        IERC20(ngcToken).transfer(feeAccount, (ff * 4) / 100);

        uint256 fm = (totalRewards * (100 - inviteefee - fee)) / 100;
        IERC20(pdToken).transfer(msg.sender, (fm * 6) / 100);
        IERC20(ngcToken).transfer(msg.sender, (fm * 4) / 100);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256 totalRewards = 0;
        for (uint256 ind = 0; ind < stakeNFTList.length; ind++) {
            uint256[] memory tokenIds = stakerToTokenIds[staker][
                stakeNFTList[ind]
            ];

            for (uint256 i = 0; i < tokenIds.length; i++) {
                totalRewards =
                    totalRewards +
                    ((block.timestamp -
                        tokenIdToTimeStamp[stakeNFTList[ind]][tokenIds[i]]) *
                        tokenAddressEmissionsRate[stakeNFTList[ind]]);
            }
        }
        return totalRewards;
    }

    function getRewardsByTokenId(address tokenAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            tokenIdToStaker[tokenAddress][tokenId] != nullAddress,
            "Token is not staked!"
        );

        uint256 secondsStaked = block.timestamp -
            tokenIdToTimeStamp[tokenAddress][tokenId];

        return secondsStaked * tokenAddressEmissionsRate[tokenAddress];
    }

    function getStaker(address tokenAddress, uint256 tokenId)
        public
        view
        returns (address)
    {
        return tokenIdToStaker[tokenAddress][tokenId];
    }

    function ownerAllWithdraw(address tokenAddress, address to) public onlyOwner {
        IERC20(tokenAddress).transfer(to, IERC20(tokenAddress).balanceOf(address(this)));
    }
}