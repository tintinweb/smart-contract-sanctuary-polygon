// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface ITokenConverter {
    function convertTwoUniversal(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) external view returns (uint256);
}

interface IERC721 {
    function getPrice(uint256 tokenId) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function burn(uint256 tokenId) external;
}

contract Multistaking is Ownable {
    address public BUSD;

    IERC20 public vodkaToken;
    IERC721 public cocktailNFT;
    ITokenConverter tokenConverter;

    uint256 constant MONTH = 30 days;

    uint256 constant ONE_DOLLAR = 1e18;

    uint256[4] public periods = [MONTH, 3 * MONTH, 6 * MONTH, 12 * MONTH];
    uint8[4] public rates = [5, 6, 9, 12];

    struct Stake {
        uint8 class_;
        uint256[] tokenIds;
        uint256 startTime;
        uint256 endTime;
        uint256 initialInBUSD;
        uint256 rewardBUSD;
        bool unstaked;
    }

    uint256 public MAX_STAKES = 5;

    Stake[] public stakes;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256[]) public stakesOf;

    event Staked(
        address sender,
        uint8 class_,
        uint256[] tokenIds,
        uint256 initialInBUSD,
        uint256 rewardBUSD
    );
    event Unstaked(
        address sender,
        uint8 class_,
        uint256[] tokenIds,
        uint256 totalRewardTokens
    );

    constructor(
        address vodkaToken_,
        address cocktailNFT_,
        address busdAddress,
        address tokenConverter_
    ) {
        vodkaToken = IERC20(vodkaToken_);
        cocktailNFT = IERC721(cocktailNFT_);
        tokenConverter = ITokenConverter(tokenConverter_);
        BUSD = busdAddress;
    }

    function stakesInfo(uint256 _from, uint256 _to)
        public
        view
        returns (Stake[] memory s)
    {
        s = new Stake[](_to - _from);
        for (uint256 i = _from; i <= _to; i++) s[i - _from] = stakes[i];
    }

    function stakesInfoAll() public view returns (Stake[] memory s) {
        s = new Stake[](stakes.length);
        for (uint256 i = 0; i < stakes.length; i++) s[i] = stakes[i];
    }

    function stakesLength() public view returns (uint256) {
        return stakes.length;
    }

    function myStakes(address _me)
        public
        view
        returns (Stake[] memory s, uint256[] memory indexes)
    {
        s = new Stake[](stakesOf[_me].length);
        indexes = new uint256[](stakesOf[_me].length);
        for (uint256 i = 0; i < stakesOf[_me].length; i++) {
            indexes[i] = stakesOf[_me][i];
            s[i] = stakes[indexes[i]];
        }
    }

    function myActiveStakesCount(address _me) public view returns (uint256 l) {
        uint256[] storage _s = stakesOf[_me];
        for (uint256 i = 0; i < _s.length; i++) if (!stakes[_s[i]].unstaked) l++;
    }

    function stake(uint8 class_, uint256[] memory tokenIds) public {
        require(class_ < periods.length, 'Wrong class_');
        require(
            myActiveStakesCount(msg.sender) < MAX_STAKES,
            'You exceed amount of stakings'
        );

        uint256 initialInBUSD = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            cocktailNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
            initialInBUSD += cocktailNFT.getPrice(tokenIds[i]) * ONE_DOLLAR;
        }

        uint256 rewardBUSD = (rates[class_] * periods[class_] * initialInBUSD) /
            (60 * 60 * 24 * 30 * 100);

        Stake memory stake_ = Stake({
            class_: class_,
            tokenIds: tokenIds,
            startTime: block.timestamp,
            endTime: block.timestamp + periods[class_],
            initialInBUSD: initialInBUSD,
            rewardBUSD: rewardBUSD,
            unstaked: false
        });

        uint256 index = stakes.length;

        stakes.push(stake_);
        ownerOf[index] = msg.sender;
        stakesOf[msg.sender].push(index);

        emit Staked(msg.sender, class_, tokenIds, initialInBUSD, rewardBUSD);
    }

    function unstake(uint256 index) public {
        require(msg.sender == ownerOf[index], 'You are not owner of this staking');

        Stake storage stake_ = stakes[index];

        require(stake_.startTime > 0, 'You dont have staking');
        require(stake_.endTime < block.timestamp, 'Period did not pass');
        require(!stake_.unstaked, 'You have already unstaked');

        uint256 totalRewardBUSD = stake_.rewardBUSD;
        uint256 _totalRewardTokens = tokenConverter.convertTwoUniversal(
            BUSD,
            address(vodkaToken),
            totalRewardBUSD
        );

        require(
            vodkaToken.balanceOf(address(this)) >= _totalRewardTokens,
            'Dont enough tokens on contract'
        );
        vodkaToken.transfer(msg.sender, _totalRewardTokens);

        for (uint256 i = 0; i < stake_.tokenIds.length; i++) {
            cocktailNFT.transferFrom(address(this), msg.sender, stake_.tokenIds[i]);
        }

        stake_.unstaked = true;

        emit Unstaked(msg.sender, stake_.class_, stake_.tokenIds, _totalRewardTokens);
    }

    function updateMax(uint256 _max) external onlyOwner {
        MAX_STAKES = _max;
    }

    function updateRates(uint8[4] memory rates_) external onlyOwner {
        rates = rates_;
    }

    function updatePeriods(uint256[4] memory periods_) external onlyOwner {
        periods = periods_;
    }

    function changeTokenConverter(address tokenConverter_) external onlyOwner {
        tokenConverter = ITokenConverter(tokenConverter_);
    }

    function withdraw(address token_, uint256 amount) external onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(msg.sender);
        if (amount > balance) IERC20(token_).transfer(msg.sender, balance);
        else IERC20(token_).transfer(msg.sender, amount);
    }
}