// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract PreSale is Ownable {
    uint256 private _levelOne = 30;
    uint256 private _levelTwo = 20;
    uint256 USDTprice = 200000;
    uint256 totalSupply = 10000000;
    uint256 tokenSold;
    uint256 private _totalETHInvestment;
    uint256 private _totalUSDTInvestMent;
    AggregatorV3Interface internal priceFeed;
    address private specialAddress = 0x9784Ca49e40da05Ea7220EDE6FA235CF90eD53A4;
    IERC20 USDT = IERC20(0x350851007956a489A87E25Ca90c050881a618896);
    IERC20 SOLIDA = IERC20(0x5dbe501629cf5d328B6BDfd712340B6Ff104B0B5);

    struct refferalData {
        address userAddress;
        uint256 totalReffereals;
        uint256 usdtAmount;
        uint256 etherAmoount;
    }
    struct claimData {
        address userAddress;
        uint256 usdtAmount;
        uint256 etherAmoount;
        uint256 totalClaims;
    }
    mapping(address => refferalData) public Refferals;
    mapping(address => address[]) public myRefferals;
    event TransferUSDTev(
        address fromAddress,
        address toAddress,
        uint256 amount
    );
    event TransferSOLIDA(
        address fromAddress,
        address toAddress,
        uint256 amount
    );
    event Received(address, uint256);

    constructor() {
        Refferals[specialAddress] = refferalData(specialAddress, 0, 0, 0);
        priceFeed = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );
    }

    function buyTokenUSDT(uint256 quantity, address _refferalAddress) external {
        require(
            Refferals[_refferalAddress].userAddress != address(0),
            "Invalid referral address"
        );

        require(
            _refferalAddress != address(0),
            "Can't use Address 0 as refferal!"
        );
        require(quantity > 0, "Quantity should be more than 0");
        uint256 payment = (quantity * USDTprice);
        uint256 balance = USDT.balanceOf(msg.sender);
        require(balance >= payment, "Balance should be");
        uint256 allowance = USDT.allowance(msg.sender, address(this));
        require(allowance >= payment, "Allowance should equal to the amount");
        uint256 ethPrice = getValueInUSDT(1e18);
        if (_refferalAddress != address(0)) {
            if (Refferals[msg.sender].userAddress == address(0)) {
                Refferals[msg.sender] = refferalData(
                    msg.sender,
                    1,
                    payment * _levelOne / 100,
                    0
                );
                myRefferals[_refferalAddress].push(msg.sender);
            } else {
                Refferals[msg.sender].usdtAmount += (payment * _levelOne) / 100;
                Refferals[msg.sender].etherAmoount +=
                    (((payment / ethPrice) * 1e18) / _levelOne) /
                    100;
                Refferals[msg.sender].totalReffereals += 1;
                myRefferals[_refferalAddress].push(msg.sender);
            }
        }

        Refferals[specialAddress].etherAmoount +=
            (((payment / ethPrice) * 1e18) / _levelTwo) /
            100;
        Refferals[specialAddress].usdtAmount += ((payment * _levelTwo) / 100);
        bool _transferUSDT = USDT.transferFrom(
            msg.sender,
            address(this),
            payment
        );
        _totalUSDTInvestMent += payment;
        emit TransferUSDTev(msg.sender, address(this), payment);
        require(_transferUSDT, "USDT transfer failed.");
        bool transferSLD = SOLIDA.transfer(msg.sender, quantity * 10**9);
        emit TransferSOLIDA(msg.sender, address(this), quantity * 10**9);
        require(transferSLD, "Token transfer failed.");
    }

    function buyTokenETH(uint256 quantity, address _refferalAddress)
        external
        payable
    {
        require(
            Refferals[_refferalAddress].userAddress != address(0),
            "Invalid referral address"
        );
        require(
            _refferalAddress != address(0),
            "Can't use Address 0 as refferal!"
        );
        require(quantity > 0, "Quantity should be more than 0");
        uint256 usdAmount = getValueInUSDT(msg.value);
        uint256 solidaAmt = (usdAmount * USDTprice) ;

        if (_refferalAddress != address(0)) {
            if (Refferals[msg.sender].userAddress == address(0)) {
                Refferals[msg.sender] = refferalData(
                    msg.sender,
                    1,
                    (usdAmount * _levelOne) / 100,
                    (msg.value * _levelOne) / 100
                );
                myRefferals[_refferalAddress].push(msg.sender);
            } else {
                Refferals[msg.sender].usdtAmount +=
                    (usdAmount * _levelOne) /
                    100;
                Refferals[msg.sender].etherAmoount +=
                    (msg.value * _levelOne) /
                    100;
                Refferals[msg.sender].totalReffereals += 1;
                myRefferals[_refferalAddress].push(msg.sender);
            }
        }
        Refferals[specialAddress].etherAmoount += ((msg.value * _levelTwo) /
            100);
        Refferals[specialAddress].usdtAmount += ((usdAmount * _levelTwo) / 100);
        _totalETHInvestment += msg.value;
        bool transferSLD = SOLIDA.transfer(msg.sender, solidaAmt);

        emit TransferSOLIDA(msg.sender, address(this), solidaAmt);
        require(transferSLD, "Token transfer failed.");
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimal = getDecimals();
        return uint256(price) * 10**(18 - decimal);
    }

    function getValueInUSDT(uint256 _ethAmount) public view returns (uint256) {
        uint256 valuePrice = getLatestPrice();
        // uint decimals = getDecimals();
        uint256 Amount = ((valuePrice) * _ethAmount) / 1e30;
        return Amount;
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function changeLevelOneCommission(uint256 _howMuch) public {
        _levelOne = _howMuch;
    }

    function changeLevelTwoCommision(uint256 _howMuch) public {
        _levelTwo = _howMuch;
    }

    function tokenBalance() public view returns (uint256) {
        uint256 balance = SOLIDA.balanceOf(address(this));
        return balance;
    }

    function totalReferrals() public view returns (uint256) {
        uint256 referrals = Refferals[msg.sender].totalReffereals;
        return referrals;
    }

    function myEarningsInUSDT(address _userAddress)
        public
        view
        returns (uint256)
    {
        uint256 earning = Refferals[_userAddress].usdtAmount;
        return earning;
    }

    function myEarningsInETH(address _userAddress)
        public
        view
        returns (uint256)
    {
        uint256 earning = Refferals[_userAddress].usdtAmount;
        return earning;
    }

    function userData(address _userAddress)
        public
        view
        returns (refferalData memory)
    {
        return Refferals[_userAddress];
    }

    function claimCommissionUSDT() public {
        uint256 earnings = Refferals[msg.sender].usdtAmount;
        bool _tranx = USDT.transfer(msg.sender, earnings);
        require(
            _tranx,
            "insufficient funds for transfer, please wait till replenishment."
        );
        Refferals[msg.sender].usdtAmount = 0;
        Refferals[msg.sender].etherAmoount = 0;
    }

    function claimCommissionETH() public {
        uint256 earnings = Refferals[msg.sender].etherAmoount;
        bool _tranx = payable(msg.sender).send(earnings);
        require(
            _tranx,
            "insufficient funds for transfer, please wait till replenishment."
        );
        Refferals[msg.sender].usdtAmount = 0;
        Refferals[msg.sender].etherAmoount = 0;
    }

    function totalUsdInvestMent() public view onlyOwner returns (uint256) {
        return _totalUSDTInvestMent;
    }

    function totalETHInvestMent() public view onlyOwner returns (uint256) {
        return _totalETHInvestment;
    }

    // function referralClaimsStats() public view onlyOwner returns (claimData memory) {
    //     return claimData;
    // }

    function withdrawETH(address payable payee) public onlyOwner {
        require(address(this).balance > 0, "Insufficient contract balance!");
        payee.transfer(address(this).balance);
    }

    function withdrawUSDT(address payable payee) public onlyOwner {
        uint256 _USDbalance = USDT.balanceOf(address(this));
        require(_USDbalance > 0, "NO USDT balance in the Contract");
        USDT.transfer(payee, _USDbalance);
    }

    function withdrawSLD(address payable payee) public onlyOwner {
        uint256 _SLDbalance = SOLIDA.balanceOf(address(this));
        require(
            SOLIDA.balanceOf(address(this)) > 0,
            "NO SOLIDA balance in the Contract"
        );
        SOLIDA.transfer(payee, _SLDbalance);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}