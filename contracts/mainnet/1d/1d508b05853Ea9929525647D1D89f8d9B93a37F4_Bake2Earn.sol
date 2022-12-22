// File: CookiesFactory/contracts/libs/Context.sol

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: CookiesFactory/contracts/libs/Ownable.sol

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: CookiesFactory/contracts/libs/ReentrancyGuard.sol

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
     * by making the `nonReentrant` function external, and make it call a
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

// File: CookiesFactory/contracts/interfaces/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// File: CookiesFactory/contracts/interfaces/IERC165.sol

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

// File: CookiesFactory/contracts/interfaces/IERC1155.sol

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: CookiesFactory/contracts/interfaces/IERC1155Receiver.sol

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: CookiesFactory/contracts/CookiesFactory.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bake2Earn is Ownable, IERC1155Receiver, ReentrancyGuard {
    bool private isInitialized = false;
    bool private suspended = false;

    ItReward private itReward;

    // The staked token
    IERC20 public stakedToken;
    // The reward token
    IERC20 public rewardToken;
    // Reward start / end time
    uint256 public rewardStartBlock;
    uint256 public rewardEndBlock;

    uint256 public totalLockedUpRewards;

    uint16 public withdrawFee = 1500; // 100x multied, 15% default
    uint16 public harvestFee = 1500; // 100x multied, 15% default

    uint256 public PRECISION_FACTOR; // The precision factor

    // Fee received address
    address public feeReceiveWallet;

    // uint256 public rewardPerSecond; // reward distributed per sec.
    uint256 public lastRewardBlock; // Last timestamp that reward distribution occurs
    uint256 public accRewardPerShare; // Accumlated rewards per share

    uint256 public totalStakings; // Total staking tokens

    // Fee Exemption NFT info
    // mapping(contract_address => mapping (token_id => exemption percentage))
    // denominator: 10000 (ex. set 10000, redemption 100%)
    mapping(address => mapping(uint256 => FeeExemption))
        private feeExemptionList;
    address[] public nftContractAddressList;
    mapping(address => uint256[]) public nftTokenIdList;

    // Stakers
    address[] public userList;
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt.
        bool registered; // it will add user in address list on first deposit
        address addr; //address of user
        uint256 lockupReward; // Reward locked up.
        uint256 lastHarvestedAt; // Last harvested block
        uint256 lastDepositedAt; // Last withdrawn block
        address nftAddress;
        uint256 nftTokenId;
        uint256 rewardReceived; // total received reward
    }

    /// @notice Max 50 rewards can be stored
    uint256 public MAX_REWARD_COUNT = 50;
    // reward will be distrubuted in 30 days
    uint256 public rewardingPeriod;

    mapping(address => bool) public addRewardWhiteList;

    struct FeeExemption {
        bool registered;
        address nftAddress;
        uint256 nftTokenId;
        uint256 exemptionPercentage;
    }
    struct UserDebt {
        // reward debt
        uint256 debt;
        // lockup reward
        uint256 lockupReward;
    }
    struct ItReward {
        // start time => amount
        // reward per block
        mapping(uint256 => uint256) rewards;
        // start time => index
        mapping(uint256 => uint256) indexs;
        // start time => accumlated reward per share
        mapping(uint256 => uint256) accRewardPerShares;
        // array of reward start block
        uint256[] rewardStartBlocks;
        // user reward debt & lockup reward
        mapping(address => mapping(uint256 => UserDebt)) rewardDebts;
    }

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);
    event EmergencyRewardWithdrawn(address indexed account, uint256 amount);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event NftDeposited(
        address indexed account,
        address nftAddress,
        uint256 nftTokenId
    );
    event NftWithdrawn(
        address indexed account,
        address nftAddress,
        uint256 nftTokenId
    );
    event UserRewarded(address indexed account, uint256 amount, uint256 fee);

    event Log(string message);

    function getRewardList(address _account)
        external
        view
        returns (UserDebt[] memory debt)
    {
        uint256 len = itReward.rewardStartBlocks.length;
        debt = new UserDebt[](len);
        for (uint256 i = 0; i < len; i++) {
            debt[i] = itReward.rewardDebts[_account][
                itReward.rewardStartBlocks[i]
            ];
        }
    }

    function getRewardList()
        external
        view
        returns (
            uint256[] memory _rewardStartBlocks,
            uint256[] memory _rewards,
            uint256[] memory _accRewardPerShares
        )
    {
        uint256 len = itReward.rewardStartBlocks.length;
        _rewards = new uint256[](len);
        _accRewardPerShares = new uint256[](len);
        _rewardStartBlocks = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            _rewardStartBlocks[i] = itReward.rewardStartBlocks[i];
            _rewards[i] = itReward.rewards[_rewardStartBlocks[i]];
            _accRewardPerShares[i] = itReward.accRewardPerShares[
                _rewardStartBlocks[i]
            ];
        }
    }

    function updateAddRewardWhiteList(address _account, bool _permission)
        external
        onlyOwner
    {
        require(addRewardWhiteList[_account] != _permission, "not changed");
        addRewardWhiteList[_account] = _permission;
    }

    function addReward(uint256 _amount) external {
        require(addRewardWhiteList[_msgSender()], "you don't have permission");
        require(
            rewardToken.allowance(_msgSender(), address(this)) >= _amount,
            "not approved yet"
        );
        uint256 _rewardStartBlock = block.number;
        if (lastRewardBlock > _rewardStartBlock) {
            _rewardStartBlock = lastRewardBlock;
        }

        uint256 keyIndex = itReward.indexs[_rewardStartBlock];
        itReward.rewards[_rewardStartBlock] += _amount / rewardingPeriod;

        rewardToken.transferFrom(_msgSender(), address(this), _amount);

        updatePool();

        if (keyIndex > 0) return;
        // When the key not exists, add it
        itReward.indexs[_rewardStartBlock] =
            itReward.rewardStartBlocks.length +
            1;
        itReward.rewardStartBlocks.push(_rewardStartBlock);
        require(
            itReward.rewardStartBlocks.length <= MAX_REWARD_COUNT,
            "Too many rewards"
        );
    }

    function initialize(
        IERC20 _stakedToken,
        IERC20 _rewardToken,
        uint256 _rewardStartBlock,
        uint256 _rewardEndBlock,
        uint256 _rewardingPeriod,
        address _admin
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");
        require(
            block.number < _rewardStartBlock &&
                _rewardStartBlock <= _rewardEndBlock,
            "Invalid blocks"
        );
        require(
            _rewardingPeriod > 0,
            "rewarding period must be greater than 0"
        );

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardStartBlock = _rewardStartBlock;
        rewardEndBlock = _rewardEndBlock;
        rewardingPeriod = _rewardingPeriod;
        feeReceiveWallet = _admin;

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30) - decimalsRewardToken));

        lastRewardBlock = _rewardStartBlock; // Set the last reward block as the start block

        addRewardWhiteList[_admin] = true;
    }

    function updateRewardEndBlock(uint256 _rewardEndBlock) external onlyOwner {
        require(_rewardEndBlock > block.number, "you should set after now");
        rewardEndBlock = _rewardEndBlock;
    }

    function updateMaxRewardCount(uint256 _maxRewardCount) external onlyOwner {
        require(
            MAX_REWARD_COUNT < _maxRewardCount,
            "you should set greater than current one"
        );
        MAX_REWARD_COUNT = _maxRewardCount;
    }

    function balanceOf(address _account) external view returns (uint256) {
        UserInfo storage user = userInfo[_account];
        return user.amount;
    }

    function getNftList(address nftAddress)
        external
        view
        returns (uint256[] memory)
    {
        return nftTokenIdList[nftAddress];
    }

    function suspend(bool _suspended) external onlyOwner {
        require(_suspended != suspended, "not changed");
        suspended = _suspended;
    }

    function updateFeeExemptionNft(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _exemptionPercentage
    ) external onlyOwner {
        require(
            feeExemptionList[_nftAddress][_nftTokenId].exemptionPercentage !=
                _exemptionPercentage,
            "not changed"
        );
        feeExemptionList[_nftAddress][_nftTokenId]
            .exemptionPercentage = _exemptionPercentage;

        // add nftContractAddress array
        if (feeExemptionList[_nftAddress][_nftTokenId].registered == false) {
            nftContractAddressList.push(_nftAddress);
            feeExemptionList[_nftAddress][_nftTokenId].registered = true;
            feeExemptionList[_nftAddress][_nftTokenId].nftAddress = _nftAddress;
            feeExemptionList[_nftAddress][_nftTokenId].nftTokenId = _nftTokenId;
        }

        uint256[] storage _nftTokenIdList = nftTokenIdList[_nftAddress];
        bool found = false;
        for (uint256 i = 0; i < _nftTokenIdList.length; i++) {
            if (_nftTokenId == _nftTokenIdList[i]) {
                found = true;
                break;
            }
        }
        if (found == false) {
            _nftTokenIdList.push(_nftTokenId);
        }
    }

    function getFeeExemptionNftList()
        public
        view
        returns (FeeExemption[] memory _feeExemptionList)
    {
        uint256 _length = 0;
        for (uint256 i = 0; i < nftContractAddressList.length; i++) {
            _length += nftTokenIdList[nftContractAddressList[i]].length;
        }

        _feeExemptionList = new FeeExemption[](_length);

        uint256 _index = 0;
        for (uint256 i = 0; i < nftContractAddressList.length; i++) {
            uint256[] memory _tokenIdList = nftTokenIdList[
                nftContractAddressList[i]
            ];
            for (uint256 j = 0; j < _tokenIdList.length; j++) {
                _feeExemptionList[_index] = feeExemptionList[
                    nftContractAddressList[i]
                ][_tokenIdList[j]];
                _index++;
            }
        }
    }

    function updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalStakings == 0 || getRewardedAmount() == 0) {
            lastRewardBlock = block.number;
            return;
        }

        for (uint256 i = 0; i < itReward.rewardStartBlocks.length; i++) {
            uint256 multipilier = getMultipilier(
                lastRewardBlock,
                block.number,
                itReward.rewardStartBlocks[i] + rewardingPeriod
            );
            uint256 key = itReward.rewardStartBlocks[i];
            uint256 rewardAccum = itReward.rewards[key] * multipilier;

            itReward.accRewardPerShares[key] =
                itReward.accRewardPerShares[key] +
                ((rewardAccum * PRECISION_FACTOR) / totalStakings);
        }
        lastRewardBlock = block.number;
    }

    function lockupReward() internal {
        UserInfo storage user = userInfo[_msgSender()];
        uint256 _reward = 0;
        for (uint256 i = 0; i < itReward.rewardStartBlocks.length; i++) {
            uint256 key = itReward.rewardStartBlocks[i];

            itReward
            .rewardDebts[_msgSender()][key].lockupReward = pendingReward(
                _msgSender(),
                i
            );
            _reward += itReward.rewardDebts[_msgSender()][key].lockupReward;
        }
        emit LockupReward(_msgSender(), _reward, user.lockupReward);
        totalLockedUpRewards += _reward - user.lockupReward;
        user.lockupReward = _reward;
    }

    event LockupReward(
        address _account,
        uint256 _reward,
        uint256 _rewardLocked
    );

    function updateRewardDebt() internal {
        UserInfo storage user = userInfo[_msgSender()];
        user.rewardDebt = 0;
        for (uint256 i = 0; i < itReward.rewardStartBlocks.length; i++) {
            uint256 key = itReward.rewardStartBlocks[i];
            itReward.rewardDebts[_msgSender()][key].debt =
                (user.amount * itReward.accRewardPerShares[key]) /
                PRECISION_FACTOR;

            user.rewardDebt += itReward.rewardDebts[_msgSender()][key].debt;
        }
    }

    function pendingReward(address _account, uint256 _index)
        internal
        view
        returns (uint256 reward)
    {
        if (_index >= itReward.rewardStartBlocks.length) {
            return 0;
        }
        UserInfo memory user = userInfo[_account];

        uint256 multipilier = getMultipilier(
            lastRewardBlock,
            block.number,
            itReward.rewardStartBlocks[_index] + rewardingPeriod
        );
        uint256 key = itReward.rewardStartBlocks[_index];
        uint256 adjustedTokenPerShare = itReward.accRewardPerShares[key];
        if (totalStakings > 0) {
            uint256 rewardAccum = itReward.rewards[key] * multipilier;

            adjustedTokenPerShare =
                adjustedTokenPerShare +
                ((rewardAccum * PRECISION_FACTOR) / totalStakings);
        }
        reward = (user.amount * adjustedTokenPerShare) / PRECISION_FACTOR;
        if (reward > itReward.rewardDebts[_account][key].debt) {
            reward = reward - itReward.rewardDebts[_account][key].debt;
        } else {
            reward = 0;
        }
        reward = reward + itReward.rewardDebts[_account][key].lockupReward;
    }

    function pendingReward(address _account)
        public
        view
        returns (uint256 reward)
    {
        reward = 0;
        for (uint256 i = 0; i < itReward.rewardStartBlocks.length; i++) {
            reward += pendingReward(_account, i);
        }
    }

    /**
     * @param _from: from
     * @param _to: to
     * @param _end: reward end time
     */
    function getMultipilier(
        uint256 _from,
        uint256 _to,
        uint256 _end
    ) internal pure returns (uint256) {
        if (_to >= _end) {
            _to = _end;
        }
        if (_to <= _from) {
            return 0;
        } else {
            return _to - _from;
        }
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        require(suspended == false, "suspended");
        require(_msgSender() == tx.origin, "Invalid Access");

        UserInfo storage user = userInfo[_msgSender()];
        updatePool();
        lockupReward();

        if (user.amount == 0 && user.registered == false) {
            userList.push(msg.sender);
            user.registered = true;
            user.addr = address(msg.sender);
        }

        if (_amount > 0) {
            // Every time when there is a new deposit, reset last withdrawn block
            user.lastDepositedAt = block.number;

            uint256 balanceBefore = stakedToken.balanceOf(address(this));
            stakedToken.transferFrom(
                address(_msgSender()),
                address(this),
                _amount
            );
            _amount = stakedToken.balanceOf(address(this)) - balanceBefore;

            user.amount = user.amount + _amount;
            totalStakings = totalStakings + _amount;

            emit Deposited(msg.sender, _amount);
        }

        updateRewardDebt();
    }

    /*
     * @notice Withdraw staked tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        require(suspended == false, "suspended");
        require(_amount > 0, "zero amount");
        UserInfo storage user = userInfo[_msgSender()];
        require(user.amount >= _amount, "Amount to withdraw too high");
        require(totalStakings >= _amount, "Exceed total staking amount");

        updatePool();
        lockupReward();

        (bool withdrawAvailable, uint256 feeAmount) = canWithdraw(
            _msgSender(),
            _amount
        );
        require(withdrawAvailable, "Cannot withdraw");
        if (withdrawAvailable) {
            user.amount = user.amount - _amount;
            totalStakings = totalStakings - _amount;

            if (feeAmount > 0 && feeReceiveWallet != address(0)) {
                stakedToken.transfer(feeReceiveWallet, feeAmount);
                _amount = _amount - feeAmount;
            }

            if (_amount > 0) {
                stakedToken.transfer(_msgSender(), _amount);
            }

            emit Withdrawn(_msgSender(), _amount);
        }

        updateRewardDebt();
    }

    /**
     * @notice View function to see if user can withdraw.
     */
    function canWithdraw(address _user, uint256 _amount)
        public
        view
        returns (bool _available, uint256 _feeAmount)
    {
        UserInfo memory user = userInfo[_user];
        _available = user.amount >= _amount && suspended == false;

        uint256 feePercentage = withdrawFee;
        if (
            feeExemptionList[user.nftAddress][user.nftTokenId]
                .exemptionPercentage > 0
        ) {
            feePercentage =
                feePercentage -
                ((feePercentage *
                    feeExemptionList[user.nftAddress][user.nftTokenId]
                        .exemptionPercentage) / 10000);
        }
        _feeAmount = (_amount * feePercentage) / 10000;
    }

    function claim() external {
        require(suspended == false, "suspended");
        UserInfo storage user = userInfo[_msgSender()];

        uint256 pending = pendingReward(_msgSender());

        (bool _available, uint256 _fee) = canHarvest(_msgSender(), pending);
        require(_available, "cannot claim");

        updatePool();
        lockupReward();

        uint256 reward = 0;
        for (uint256 i = 0; i < itReward.rewardStartBlocks.length; i++) {
            uint256 key = itReward.rewardStartBlocks[i];
            reward += itReward.rewardDebts[_msgSender()][key].lockupReward;
            itReward.rewardDebts[_msgSender()][key].lockupReward = 0;
        }
        require(pending == reward, "something went wrong");

        rewardToken.transfer(_msgSender(), reward - _fee);

        user.rewardReceived += reward - _fee;
        if (_fee > 0 && feeReceiveWallet != address(0)) {
            rewardToken.transfer(feeReceiveWallet, _fee);
        }

        user.lastHarvestedAt = block.number;
        if (totalLockedUpRewards >= reward) {
            totalLockedUpRewards -= reward;
        } else {
            totalLockedUpRewards = 0;
        }
        user.lockupReward = 0;
        updateRewardDebt();

        emit UserRewarded(_msgSender(), reward, _fee);
    }

    event CanHarvest(bool available, uint256 fee, uint256 reward);

    /**
     * @notice View function to see if user can harvest.
     */
    function canHarvest(address _user, uint256 _amount)
        public
        view
        returns (bool _canHarvest, uint256 _feeAmount)
    {
        UserInfo memory user = userInfo[_user];

        uint256 reward = pendingReward(_user);
        _canHarvest = reward >= _amount && suspended == false;

        uint256 feePercentage = harvestFee;
        if (
            feeExemptionList[user.nftAddress][user.nftTokenId]
                .exemptionPercentage > 0
        ) {
            feePercentage =
                feePercentage -
                ((feePercentage *
                    feeExemptionList[user.nftAddress][user.nftTokenId]
                        .exemptionPercentage) / 10000);
        }
        _feeAmount = (reward * feePercentage) / 10000;
    }

    /**
     * @notice Deposit nft, then the staked token amount will be boosted
     */
    function depositNft(address _nftAddress, uint256 _nftTokenId)
        external
        nonReentrant
    {
        require(
            feeExemptionList[_nftAddress][_nftTokenId].exemptionPercentage > 0,
            "not eligible NFT"
        );

        UserInfo storage user = userInfo[_msgSender()];
        require(user.nftAddress == address(0), "Another NFT staked already");

        require(
            IERC1155(_nftAddress).isApprovedForAll(_msgSender(), address(this)),
            "NFT not approved for the staking contract"
        );
        IERC1155(_nftAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            _nftTokenId,
            1,
            ""
        );

        user.nftAddress = _nftAddress;
        user.nftTokenId = _nftTokenId;

        emit NftDeposited(_msgSender(), _nftAddress, _nftTokenId);
    }

    function withdrawNft() external nonReentrant {
        // require(!isFrozen(), "Frozen...");
        // withdraw all sub NFT first
        // withdrawSubNftAll();

        UserInfo storage user = userInfo[_msgSender()];
        require(user.nftAddress != address(0), "No nft staked yet");

        IERC1155(user.nftAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            user.nftTokenId,
            1,
            ""
        );

        emit NftWithdrawn(_msgSender(), user.nftAddress, user.nftTokenId);

        user.nftAddress = address(0);
        user.nftTokenId = 0;
        user.rewardDebt = (user.amount * accRewardPerShare) / PRECISION_FACTOR;
    }

    function getRewardedAmount() public view returns (uint256 rewarded) {
        rewarded = 0;
        for (uint256 i = 0; i < itReward.rewardStartBlocks.length; i++) {
            uint256 multipilier = getMultipilier(
                itReward.rewardStartBlocks[i],
                block.number,
                itReward.rewardStartBlocks[i] + rewardingPeriod
            );
            rewarded +=
                multipilier *
                itReward.rewards[itReward.rewardStartBlocks[i]];
        }
    }

    /*
     * @notice return length of user addresses
     */
    function getUserListLength() external view returns (uint256) {
        return userList.length;
    }

    /*
     * @notice View function to get users.
     * @param _offset: offset for paging
     * @param _limit: limit for paging
     * @return get users, next offset and total users
     */
    function getUsersPaging(uint256 _offset, uint256 _limit)
        public
        view
        returns (
            UserInfo[] memory users,
            uint256 nextOffset,
            uint256 total
        )
    {
        total = userList.length;
        if (_limit == 0) {
            _limit = 1;
        }

        if (_limit > total - _offset) {
            _limit = total - _offset;
        }
        nextOffset = _offset + _limit;

        users = new UserInfo[](_limit);
        for (uint256 i = 0; i < _limit; i++) {
            users[i] = userInfo[userList[_offset + i]];
        }
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(stakedToken) &&
                _tokenAddress != address(rewardToken),
            "Cannot be staked token"
        );

        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        uint256 availableRewardAmount = rewardToken.balanceOf(address(this));
        // when staked token and reward token same, it should not occupy the staked amount
        if (address(stakedToken) == address(rewardToken)) {
            availableRewardAmount = availableRewardAmount - totalStakings;
        }
        require(availableRewardAmount >= _amount, "Too much amount");

        rewardToken.transfer(_msgSender(), _amount);
        emit EmergencyRewardWithdrawn(_msgSender(), _amount);
    }

    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 /*interfaceId*/
    ) public view virtual override returns (bool) {
        return false;
    }
}