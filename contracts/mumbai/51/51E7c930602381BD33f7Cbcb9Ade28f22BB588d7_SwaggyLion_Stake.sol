// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ISwaggyLionsClub {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

pragma solidity ^0.8.4;

interface ISwaggyLionToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.4;

contract SwaggyLion_Stake is Ownable {
    uint256 public constant REWARD_RATE = 20;
    address public constant SwaggyLionsClub_ADDRESS =
        0xCC169831968BE40311E792e1b063585DB7fb1734;
    address public constant SwaggyLionToken_ADDRESS =
        0x267da4daC21Abebc72f5383092F26028e467A9db;

    mapping(uint256 => uint256) internal swaggyLionTimeStaked;
    mapping(uint256 => address) internal swaggyLionStaker;
    mapping(address => uint256[]) internal stakerToSwaggyLions;

    ISwaggyLionsClub private constant _SwaggyLionsClubContract =
        ISwaggyLionsClub(SwaggyLionsClub_ADDRESS);
    ISwaggyLionToken private constant _SwaggyLionToken =
        ISwaggyLionToken(SwaggyLionToken_ADDRESS);

    bool public live = true;

    modifier stakingEnabled() {
        require(live, "NOT_LIVE");
        _;
    }

    function getStakedSwaggyLions(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToSwaggyLions[staker];
    }

    function getStakedAmount(address staker) public view returns (uint256) {
        return stakerToSwaggyLions[staker].length;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return swaggyLionStaker[tokenId];
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256 totalRewards = 0;
        uint256[] memory swaggyLionTokens = stakerToSwaggyLions[staker];
        for (uint256 i = 0; i < swaggyLionTokens.length; i++) {
            totalRewards += getReward(swaggyLionTokens[i]);
        }
        return totalRewards;
    }

    function stakeSwaggyLionById(uint256[] calldata tokenIds)
        external
        stakingEnabled
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(
                _SwaggyLionsClubContract.ownerOf(id) == msg.sender,
                "NO_SWEEPING"
            );
            _SwaggyLionsClubContract.transferFrom(
                msg.sender,
                address(this),
                id
            );
            stakerToSwaggyLions[msg.sender].push(id);
            swaggyLionTimeStaked[id] = block.timestamp;
            swaggyLionStaker[id] = msg.sender;
        }
    }

    function unstakeSwaggyLionByIds(uint256[] calldata tokenIds) external {
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(swaggyLionStaker[id] == msg.sender, "NEEDS_TO_BE_OWNER");
            _SwaggyLionsClubContract.transferFrom(
                address(this),
                msg.sender,
                id
            );
            totalRewards += getReward(id);
            removeTokenIdFromArray(stakerToSwaggyLions[msg.sender], id);
            swaggyLionStaker[id] = address(0);
        }
        uint256 remaining = _SwaggyLionToken.balanceOf(address(this));
        uint256 reward = totalRewards > remaining ? remaining : totalRewards;
        if (reward > 0) {
            _SwaggyLionToken.transfer(msg.sender, reward);
        }
    }

    function unstakeAll() external {
        require(getStakedAmount(msg.sender) > 0, "NONE_STAKED");
        uint256 totalRewards = 0;
        for (uint256 i = stakerToSwaggyLions[msg.sender].length; i > 0; i--) {
            uint256 id = stakerToSwaggyLions[msg.sender][i - 1];
            _SwaggyLionsClubContract.transferFrom(
                address(this),
                msg.sender,
                id
            );
            totalRewards += getReward(id);
            stakerToSwaggyLions[msg.sender].pop();
            swaggyLionStaker[id] = address(0);
        }
        uint256 remaining = _SwaggyLionToken.balanceOf(address(this));
        uint256 reward = totalRewards > remaining ? remaining : totalRewards;
        if (reward > 0) {
            _SwaggyLionToken.transfer(msg.sender, reward);
        }
    }

    function claimAll() external {
        uint256 totalRewards = 0;
        uint256[] memory swaggyLionTokens = stakerToSwaggyLions[msg.sender];
        for (uint256 i = 0; i < swaggyLionTokens.length; i++) {
            uint256 id = swaggyLionTokens[i];
            totalRewards += getReward(id);
            swaggyLionTimeStaked[id] = block.timestamp;
        }
        uint256 remaining = _SwaggyLionToken.balanceOf(address(this));
        _SwaggyLionToken.transfer(
            msg.sender,
            totalRewards > remaining ? remaining : totalRewards
        );
    }

    function getReward(uint256 tokenId) internal view returns (uint256) {
        return
            (((block.timestamp - swaggyLionTimeStaked[tokenId]) * REWARD_RATE) /
                86400) * 1 ether;
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId)
        internal
    {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == tokenId) {
                length--;
                if (i < length) {
                    array[i] = array[length];
                }
                array.pop();
                break;
            }
        }
    }

    function toggle() external onlyOwner {
        live = !live;
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