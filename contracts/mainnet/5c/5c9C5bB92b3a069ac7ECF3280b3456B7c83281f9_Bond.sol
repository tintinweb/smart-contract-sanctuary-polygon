/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function holdDeposit(
        address sender,
        uint256 amount,
        uint256 id
    ) external;

    function addRevenue(uint256 addAmount) external;

    function mint(uint256 amount) external;

    function bondMint(uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
        _previousOwner = msgSender;
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _previousOwner = _owner;
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract Bond is Ownable {
    using SafeMath for uint256;
    uint256 public vsqRate_;
    uint256 public fee_;
    uint256 public maxBond_;
    uint256 totalBondAmount_ = 0;

    address public lockerAddress_;
    address public vsqAddress_;
    address public revenueAddress_;
    address public safeAddress_;
    address public admin;

    mapping(address => uint256) public rate_;
    mapping(address => bool) public CoinState_;

    event TokensPurchased(address tokenAddress, uint256 amount, uint256 time);

    constructor(
        uint256 fee,
        uint256 vsqRate,
        uint256 maxBond,
        address lockerAddress,
        address revenueAddress,
        address vsqAddress,
        address safeAddress,
        address crypto
    ) {
        fee_ = fee;
        vsqRate_ = vsqRate;
        maxBond_ = maxBond;
        lockerAddress_ = lockerAddress;
        vsqAddress_ = vsqAddress;
        revenueAddress_ = revenueAddress;
        safeAddress_ = safeAddress;
        admin = msg.sender;
        CoinState_[crypto] = true;
        rate_[crypto] = 10;
    }

    function buyWithMatic(uint256 id) external payable {
        require(msg.value > 0, "Bond: weiAmount is 0");
        uint256 vsqAmount = (msg.value * 100) / vsqRate_;
        uint256 bondAmount = totalBondAmount_ + vsqAmount;
        require(bondAmount < maxBond_, "Invalid Amount");
        totalBondAmount_ = bondAmount;
        payable(safeAddress_).transfer(msg.value);
        IERC20(vsqAddress_).bondMint(vsqAmount / 1e9);
        IERC20(vsqAddress_).approve(
            lockerAddress_,
            ((vsqAmount / 1e9) * (1e5 - fee_)) / 1e5
        );
        IERC20(vsqAddress_).approve(
            revenueAddress_,
            ((vsqAmount / 1e9) * fee_) / 1e5
        );
        IERC20(lockerAddress_).holdDeposit(
            msg.sender,
            ((vsqAmount / 1e9) * (1e5 - fee_)) / 1e5,
            id
        );
        IERC20(lockerAddress_).transfer(
            msg.sender,
            ((vsqAmount / 1e9) * (1e5 - fee_)) / 1e5
        );
        IERC20(revenueAddress_).addRevenue(((vsqAmount / 1e9) * fee_) / 1e5);
    }

    function buyWithCrypto(
        uint256 amount,
        address crypto,
        uint256 id
    ) external {
        require(amount > 0, "Bond: weiAmount is 0");
        require(CoinState_[crypto] == true, "not enabled coin");
        IERC20(crypto).transferFrom(msg.sender, admin, amount * 1e18);
        uint256 tokenAmount = amount.mul(rate_[crypto]) * 1e9;
        IERC20(vsqAddress_).bondMint(tokenAmount);
        IERC20(vsqAddress_).approve(lockerAddress_, tokenAmount);
        IERC20(lockerAddress_).holdDeposit(msg.sender, tokenAmount, id);
    }

    function setVsqRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "Zero Rate");
        vsqRate_ = _rate;
    }

    function setCryptoState(address crypto, bool state) external onlyOwner {
        CoinState_[crypto] = state;
    }

    function setCryptoRate(address crypto, uint256 _rate) external onlyOwner {
        require(_rate > 0, "Zero Rate");
        rate_[crypto] = _rate;
    }

    function setLockerAddress(address _lockerAddress) external onlyOwner {
        lockerAddress_ = _lockerAddress;
    }

    function setVsqAddress(address _vsqAddress) external onlyOwner {
        vsqAddress_ = _vsqAddress;
    }

    function setRevenueAddress(address _revenueAddress) external onlyOwner {
        revenueAddress_ = _revenueAddress;
    }

    function setMaxBond(uint256 _maxBond) external onlyOwner {
        maxBond_ = _maxBond;
    }

    function setFee(uint256 fee) external onlyOwner {
        fee_ = fee;
    }

    function setSafeAddress(address safeAddress) external onlyOwner {
        safeAddress_ = safeAddress;
    }
}