// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ItemPool.sol";
import "./Initializable.sol";

interface INFTConfig{
    function blindboxMint(address toAddress) external returns (uint256);
}

contract BlindBox is Ownable, Initializable, ItemPool {
    IERC20 public token_n;
    IERC20 public token_s;
    INFTConfig public nft;

    uint256 constant public price = 0.001 ether;
    uint256 constant public max_count_4_user = 5;
    uint256 constant public all_count = 1000;

    mapping(address => uint) public balance;
    uint256 public valid_count = all_count;

    event eventBlindboxMint(address indexed toAddress, uint256 indexed tokenId, uint256 indexed tokenType);
    event eventOpenResult(uint256 indexed itemType, uint256 indexed itemAmount);

    function initialize(IERC20 _n, IERC20 _s, INFTConfig _nft) public initializer {

        require(_n != IERC20(address(0)), "_n error");
        require(_s != IERC20(address(0)), "_s error");
        require(_nft != INFTConfig(address(0)), "_nft error");

        initItemPool();

        token_n = _n;
        token_s = _s;
        nft = _nft;
    }

    function random() public view returns (uint256)
    {
        uint256 randomNum = uint256(
            keccak256(abi.encode(tx.gasprice,
            tx.origin,
            block.number,
            block.timestamp,
            block.difficulty,
            blockhash(block.number - 1),
            address(this),
            total_weight))
        );
        return randomNum % total_weight;
    }

    function buyBox(uint amount) public payable {

        require(msg.value >= price * amount, "value error");
        require(_msgSender() == tx.origin, "sender error");
        require(valid_count >= amount, "amount error");

        for (uint i = 0; i < amount; i++)
        {
            uint random_val = random();
            uint256 tmp_sum = 0;
            for (uint j = 0; j < item_pool.length; j++)
            {
                if (item_pool[j].total_times == 0)
                    continue;

                tmp_sum += item_pool[j].item_weight;
                if (random_val >= tmp_sum)
                    continue;

                sendReward(item_pool[j]);

                item_pool[j].total_times -= 1;
                if (item_pool[j].total_times == 0)
                    total_weight -= item_pool[j].item_weight;

                break;
            }
        }
        valid_count -= amount;
    }

    function sendReward(ITEM_POOL memory _reward_item) internal {
        if (_reward_item.item_type == ITEM_TYPE_1){
            //ERC20 N
            token_n.transfer(_msgSender(), _reward_item.item_amount);
        }else if(_reward_item.item_type == ITEM_TYPE_2) {
            //ERC20 S
            token_s.transfer(_msgSender(), _reward_item.item_amount);
        }else{
            //ERC721
            uint256 tokenId = nft.blindboxMint(_msgSender());
            emit eventBlindboxMint(_msgSender(), tokenId, _reward_item.item_type);
        }

        emit eventOpenResult(_reward_item.item_type, _reward_item.item_amount);
    }
}

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ItemPool is Ownable {

    // n-token
    uint constant internal ITEM_TYPE_1 = 1;
    // s-token
    uint constant internal ITEM_TYPE_2 = 2;

    struct ITEM_POOL
    {
        uint item_type; //类型
        uint total_times; //次数 可获得奖励的次数
        uint item_amount; //数量 奖励获得数量
        uint item_weight; //权重 中奖概率
    }

    ITEM_POOL[] public item_pool;
    uint public total_weight;

    function initItemPool() internal onlyOwner {

        delete item_pool;
        item_pool.push(ITEM_POOL(1, 40, 100, 5000));
        item_pool.push(ITEM_POOL(1, 40, 200, 3500));
        item_pool.push(ITEM_POOL(1, 40, 500, 1200));
        item_pool.push(ITEM_POOL(2, 50, 100, 250));
        item_pool.push(ITEM_POOL(2, 50, 200, 250));
        item_pool.push(ITEM_POOL(2, 40, 500, 50));
        item_pool.push(ITEM_POOL(20, 40, 1, 5000));
        item_pool.push(ITEM_POOL(21, 50, 1, 3500));
        item_pool.push(ITEM_POOL(22, 50, 1, 1200));
        item_pool.push(ITEM_POOL(23, 50, 1, 250));
        item_pool.push(ITEM_POOL(24, 50, 1, 50));
        item_pool.push(ITEM_POOL(1, 40, 100, 1000));
        item_pool.push(ITEM_POOL(1, 40, 200, 500));
        item_pool.push(ITEM_POOL(1, 40, 500, 100));
        item_pool.push(ITEM_POOL(2, 50, 100, 1000));
        item_pool.push(ITEM_POOL(2, 50, 200, 500));
        item_pool.push(ITEM_POOL(2, 40, 500, 100));
        item_pool.push(ITEM_POOL(10, 40, 1, 5000));
        item_pool.push(ITEM_POOL(11, 50, 1, 3500));
        item_pool.push(ITEM_POOL(12, 50, 1, 1200));
        item_pool.push(ITEM_POOL(13, 50, 1, 250));
        item_pool.push(ITEM_POOL(14, 50, 1, 50));

        for (uint i = 0; i != item_pool.length; i++)
        {
            total_weight += item_pool[i].item_weight;
        }
    }

     function updateItemPool(ITEM_POOL[] memory _itemPool) external onlyOwner {

         delete item_pool;
         uint tmp_weight = 0;

         for (uint i=0; i!= _itemPool.length; i++)
         {
             item_pool.push(_itemPool[i]);

             tmp_weight += _itemPool[i].item_weight;
         }
         total_weight = tmp_weight;
     }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Initializable {
    bool inited;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

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