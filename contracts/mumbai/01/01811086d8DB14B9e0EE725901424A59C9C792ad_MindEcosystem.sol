// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Swap.sol";
import "./StakedNft.sol";
import "./StakedToken.sol";
// import "./timeLocked/TimeLockedWalletFactory.sol";
import "./helpers/Withdraw.sol";

contract MindEcosystem is StakedNft, StakedToken, Swap, Withdraw {
    // LINK: https://mumbai.polygonscan.com/address/0x326C977E6efc84E512bB9C30f76E30c160eD06FB#writeContract
    // JTEST TOKEN: https://mumbai.polygonscan.com/address/0x92A9279315aa3D43b081D046e2A02427D3654591#writeContract
    // JNFT NFT : https://mumbai.polygonscan.com/address/0x7e79ca0FcaBd24Ac9d9A7dC378643Ad8080A6711#code
    constructor() {}

    // Link | JTEST
    // Pair:  2000000000000000, 0x326C977E6efc84E512bB9C30f76E30c160eD06FB, 18, 0x92A9279315aa3D43b081D046e2A02427D3654591,18,833,0,false,0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada,10,true
    // Nft: 0x7e79ca0FcaBd24Ac9d9A7dC378643Ad8080A6711,0x92A9279315aa3D43b081D046e2A02427D3654591,1000000000000000000,2,true
    // 0, 1000000000000000000
    // This fallback/receive function
    // will keep all the Ether
    fallback() external payable {
        // Do nothing
    }

    receive() external payable {
        // Do nothing
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./security/ReEntrancyGuard.sol";
import "./helpers/Oracle.sol";
import "./factory/FactorySwap.sol";

contract Swap is ReEntrancyGuard, Context, Ownable, FactorySwap, Oracle {
    // @dev SafeMath library
    using SafeMath for uint256;

    // Event that log buy operation
    event BuyTokens(
        address buyer,
        uint256 amountSenderTokenA,
        uint256 amountSenderTokenB,
        uint256 indexed _pairId
    );

    event SellToken(
        address seller,
        uint256 amountSenderTokenA,
        uint256 amountSenderTokenB,
        uint256 indexed _pairId
    );

    constructor() {}

    // @dev BUY
    //  Token A => Token Enviado -> Mind Token 300
    //  Token B => Token que va a recibir el sender: usdt
    function BuyTokensFor(uint256 _pairId, uint256 _amountTokens)
        external
        noReentrant
        returns (bool)
    {
        require(
            _amountTokens > 0,
            "BuyTokensFor: Specify an amount of token greater than zero"
        );

        // @dev get the pair
        Pair storage pair = _PairstoSwap[_pairId];

        require(pair.active, "BuyTokensFor: Pair is not active");

        IERC20 tokenA = IERC20(address(pair.tokenA));

        IERC20 tokenB = IERC20(address(pair.tokenB));

        // @dev  Check that the user's token balance is enough to do the swap
        require(
            tokenA.balanceOf(_msgSender()) >= _amountTokens,
            "BuyTokensFor: Your balance is lower than the amount of tokens you want to sell"
        );

        // @dev allowonce to execute the swap
        require(
            tokenA.allowance(_msgSender(), address(this)) >= _amountTokens,
            "BuyTokensFor: You don't have enough tokens to buy"
        );

        // @dev Transfer token to the sender  =>  sc
        require(
            tokenA.transferFrom(_msgSender(), address(this), _amountTokens),
            "BuyTokensFor: Failed to transfer tokens from user to vendor"
        );

        // @dev calculate the amount of  fee services
        uint256 _amountfeeSwap = 0;
        if (pair.fee > 0) {
            _amountfeeSwap = calculateFee(_amountTokens, pair.fee);
            require(
                tokenA.transfer(owner(), _amountfeeSwap),
                "BuyTokensFor: Failed to transfer token to Swap"
            );
        }

        uint256 tokenAmountToBuy = 0;

        // @dev  is oracle active
        if (pair.activeOracle) {
            // @dev get the price
            uint256 latestPrice = getLatestPrice(
                pair.addressOracle,
                pair.addressDecimalOracle
            );

            // @dev tranformar el token enviado a 18 decimales
            uint256 tokenAmountTo18Decimals = transformAmountTo18Decimal(
                _amountTokens.sub(_amountfeeSwap),
                pair.decimalTokenA
            );

            // @dev calculate the amount of token to buy
            uint256 valueInUsd = tokenAmountTo18Decimals.mul(latestPrice);

            tokenAmountToBuy = valueInUsd.div(pair.price);
        } else {
            // @dev calculate the amount of tokens to buy
            tokenAmountToBuy = (_amountTokens.sub(_amountfeeSwap)).mul(
                pair.amountForTokens
            );
        }

        // transformar resultado a las decimales del tokenB
        uint256 amountTokenBuy = transformAmountToTokenDecimal(
            tokenAmountToBuy,
            pair.decimalTokenB
        );

        //  @dev  check if the Vendor Contract has enough amount of tokens for the transaction
        require(
            tokenB.balanceOf(address(this)) >= amountTokenBuy,
            "BuyTokensFor: Vendor contract has not enough tokens in its balance"
        );

        require(
            tokenB.transfer(_msgSender(), amountTokenBuy),
            "BuyTokensFor: Failed to transfer token to user"
        );

        emit BuyTokens(_msgSender(), _amountTokens, amountTokenBuy, _pairId);

        return true;
    }

    // @dev SELL
    // @dev Token B => Token Enviado
    // @dev Token A => Token Que Quiere recibir
    function SellTokensFor(uint256 _pairId, uint256 _amountTokens)
        external
        noReentrant
        returns (uint256 tokenAmount)
    {
        require(
            _amountTokens > 0,
            "Specify an amount of token greater than zero"
        );

        // @dev get the pair
        Pair storage pair = _PairstoSwap[_pairId];

        require(pair.active, "SellTokensFor: Pair is not active");

        IERC20 tokenA = IERC20(address(pair.tokenA));

        IERC20 tokenB = IERC20(address(pair.tokenB));

        // Check that the user's token balance is enough to do the swap
        require(
            tokenB.balanceOf(_msgSender()) >= _amountTokens,
            "SellTokensFor: Your balance is lower than the amount of tokens you want to sell"
        );

        // @dev allowonce to execute the swap
        require(
            tokenB.allowance(_msgSender(), address(this)) >= _amountTokens,
            "SellTokensFor: You don't have enough tokens to sell"
        );

        // Transfer token to the sender -> sc
        require(
            tokenB.transferFrom(_msgSender(), address(this), _amountTokens),
            "SellTokensFor: Failed to transfer tokens from user to vendor"
        );

        // @dev calculate the amount of  fee services
        uint256 _amountfeeSwap = 0;
        if (pair.fee > 0) {
            _amountfeeSwap = calculateFee(_amountTokens, pair.fee);
            require(
                tokenB.transfer(owner(), _amountfeeSwap),
                "SellTokensFor: Failed to transfer token to Swap"
            );
        }

        uint256 tokenAmountToSell = 0;

        // @dev  is oracle active
        if (pair.activeOracle) {
            // @dev get the price
            uint256 latestPrice = getLatestPrice(
                pair.addressOracle,
                pair.addressDecimalOracle
            );

            uint256 tokenAmountTo18Decimals = transformAmountTo18Decimal(
                _amountTokens.sub(_amountfeeSwap),
                pair.decimalTokenB
            );

            // @dev calculate the amount of tokens to buy
            tokenAmountToSell = (tokenAmountTo18Decimals.div(latestPrice)).mul(
                pair.price
            );
        } else {
            // @dev calculate the amount of tokens to buy
            tokenAmountToSell = _amountTokens.sub(_amountfeeSwap).div(
                pair.amountForTokens
            );
        }

        //  @dev  check if the Vendor Contract has enough amount of tokens for the transaction
        require(
            tokenA.balanceOf(address(this)) >= tokenAmountToSell,
            "SellTokensFor: Vendor contract has not enough tokens in its balance"
        );

        require(
            tokenA.transfer(_msgSender(), tokenAmountToSell),
            "SellTokensFor: Failed to transfer token to user"
        );

        emit BuyTokens(_msgSender(), _amountTokens, tokenAmountToSell, _pairId);

        return tokenAmountToSell;
    }

    // @dev transforma los montos a 18 decimales
    function transformAmountTo18Decimal(uint256 _amount, uint256 decimal)
        public
        pure
        returns (uint256)
    {
        if (decimal == 18) {
            return _amount;
        } else if (decimal == 8) {
            return _amount.mul(10**10);
        } else if (decimal == 6) {
            return _amount.mul(10**12);
        } else if (decimal == 3) {
            return _amount.mul(10**15);
        }

        return 0;
    }

    // @dev tranformas las decimales del token
    function transformAmountToTokenDecimal(uint256 _amount, uint256 decimal)
        public
        pure
        returns (uint256)
    {
        if (decimal == 18) {
            return _amount;
        } else if (decimal == 8) {
            return _amount.div(10**10);
        } else if (decimal == 6) {
            return _amount.div(10**12);
        } else if (decimal == 3) {
            return _amount.div(10**15);
        }

        return 0;
    }

    // @dev balanceOf will return the account balance for the given account
    function balanceOf(IERC20 _token, address _address)
        public
        view
        returns (uint256)
    {
        return _token.balanceOf(_address);
    }

    // @dev fee calculation for token
    function calculateFee(uint256 amount, uint256 _fee)
        public
        pure
        returns (uint256 fee)
    {
        return (amount.mul(_fee)).div(10000);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./security/ReEntrancyGuard.sol";
import "./factory/FactoryStakeNft.sol";
import "./helpers/StakeableNFT.sol";

contract StakedNft is ReEntrancyGuard, Context, FactoryStakeNft, StakeableNFT {
    // @dev  event
    event WithDrawNft(address _sender, uint256 _nftId, uint256 _reward);

    constructor() {}

    // @dev Add functionality like "burn" to the _stake afunction
    function stakeNft(uint256 _StakeId, uint256 _tokenId)
        external
        noReentrant
        returns (bool)
    {
        // @dev get the stake
        TypeStake storage stake = _Stake[_StakeId];

        // @dev check if the stake is active
        require(stake.status, "StakeNft: not available");

        IERC721 tokenA = IERC721(address(stake.addressNft));

        // @dev verifica si el sc puede operar todos los nft del sender
        require(
            tokenA.isApprovedForAll(_msgSender(), address(this)),
            "StakeNft: not approved"
        );

        // @dev is owner of the nft
        require(
            _msgSender() == tokenA.ownerOf(_tokenId),
            "StakeNft: Sender must be owner"
        );

        // @dev tranfer the token to the contract
        tokenA.transferFrom(_msgSender(), address(this), _tokenId);

        // @dev add the reward to the stake contract
        _stake(
            _tokenId,
            stake.addressNft,
            stake.addressTokenReward,
            getDays(stake.day),
            stake.rewardTotal
        );

        return true;
    }

    // /**
    //  * @notice
    //  * Withdraw NFT Sender
    //  * Required that sender, send a ID of array Stakeholder
    //  */
    function withdrawNFTStake(uint256 index)
        external
        noReentrant
        returns (bool)
    {
        // @dev get the stake
        (
            address addressNft,
            address addressTokenReward,
            uint256 reward,
            uint256 idNft
        ) = _withdrawStake(index);

        IERC721 tokenA = IERC721(addressNft);

        IERC20 tokenB = IERC20(addressTokenReward);

        // @dev transfer the token to the sender
        tokenA.transferFrom(address(this), _msgSender(), idNft);

        // @dev transfer the token to the sender
        tokenB.transfer(_msgSender(), reward);

        emit WithDrawNft(_msgSender(), idNft, reward);

        return true;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./security/ReEntrancyGuard.sol";
import "./helpers/StakeableToken.sol";
import "./factory/FactoryStakeToken.sol";

contract StakedToken is
    ReEntrancyGuard,
    Context,
    Ownable,
    FactoryStakeToken,
    StakeableToken
{
    // // ---------- STAKES ----------

    // @dev Add functionality like "burn" to the _stake a function
    function stakeToken(uint256 _amountTokens, uint256 _StakeId)
        external
        noReentrant
        returns (bool)
    {
        // @dev get the stake
        TypeStakeToken storage stake = _StakeToken[_StakeId];

        require(stake.status, "StakeToken: stake is not active");

        // @dev limit the amount of tokens to stake
        require(
            stake.minStaked >= _amountTokens,
            "StakeToken: minStaked is not enough"
        );

        IERC20 tokenA = IERC20(address(stake.addressToken));

        // @dev  Check that the user's token balance is enough to do the swap
        require(
            tokenA.balanceOf(_msgSender()) >= _amountTokens,
            "StakeToken: Your balance is lower than the amount of tokens you want to sell"
        );

        // @dev allowonce to execute send tokens
        require(
            tokenA.allowance(_msgSender(), address(this)) >= _amountTokens,
            "StakeToken: You don't have enough tokens to buy"
        );

        // @dev Transfer token to the sender  =>  sc
        require(
            tokenA.transferFrom(_msgSender(), address(this), _amountTokens),
            "StakeToken: Failed to transfer tokens from user to vendor"
        );

        //  @dev Add the stake to the stake array
        _stakeToken(
            stake.addressToken,
            _amountTokens,
            getDaysToken(stake.day),
            stake.rewardRate,
            stake.rewardPerMonth
        );

        return true;
    }

    // @dev  withdrawStake is used to withdraw stakes from the account holder
    function withdrawStake(uint256 _amount, uint256 _stake_index)
        external
        noReentrant
        returns (bool)
    {
        (uint256 amount, address tokenAddres) = _withdrawStakeToken(
            _amount,
            _stake_index
        );

        IERC20 tokenA = IERC20(address(tokenAddres));

        // Return staked tokens to user
        // Transfer token to the msg.sender
        require(
            tokenA.transfer(_msgSender(), amount),
            "Failed to transfer token to user"
        );
        return true;
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakesToken() external view returns (uint256) {
        return _totalStakesToken();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../security/ReEntrancyGuard.sol";

contract Withdraw is ReEntrancyGuard, Context, Ownable  {
    // event
    event WithdrawEvent(
        address indexed token,
        address indexed owner,
        uint256 amount
    );

    constructor() {}

    // @dev Withdrawal $MATIC ONLY ONWER
    // @dev Allow the owner of the contract to withdraw MATIC Owner
    function withdrawMaticOwner(uint256 amount)
        external
        payable
        onlyOwner
        noReentrant
    {
        require(
            payable(address(_msgSender())).send(amount),
            "Failed to transfer token to fee contract"
        );

        emit WithdrawEvent(address(0), _msgSender(), amount);
    }

    // @dev Withdrawal TOKEN $USDT, $USDC, $DLY, $WETH, $WBTC  ONLY ONWER
    // @dev Allow the owner of the contract to withdraw MATIC Owner
    function withdrawTokenOnwer(address _token, uint256 _amount)
        external
        onlyOwner
        noReentrant
    {
        require(
            IERC20(_token).transfer(_msgSender(), _amount),
            "Failed to transfer token to Onwer"
        );

        emit WithdrawEvent(_token, _msgSender(), _amount);
    }
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Oracle {
    // @dev Returns the latest price
    function getLatestPrice(address _oracle, uint256 _decimal)
        public
        view
        returns (uint256)
    {
        require(
            _oracle != address(0),
            "Oracle address must be the same as the contract address"
        );

        AggregatorV3Interface priceFeed = AggregatorV3Interface(_oracle);

        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 10**_decimal;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FactorySwap is Ownable {
    // @dev Event that log buy operation
    event EventPair(address tokenA, address tokenB);

    // 0x326C977E6efc84E512bB9C30f76E30c160eD06FB, 18, 0x92A9279315aa3D43b081D046e2A02427D3654591,18, 833, 0,false,0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada,0,true

    // @dev struct
    struct Pair {
        uint256 price; // precio en dolares
        address tokenA;
        uint256 decimalTokenA;
        address tokenB;
        uint256 decimalTokenB;
        uint256 amountForTokens;
        uint256 fee;
        bool activeOracle;
        address addressOracle;
        uint256 addressDecimalOracle;
        bool active;
    }

    // @dev mapping
    mapping(uint256 => Pair) _PairstoSwap;
    uint256 public pairCount;

    constructor() {
        pairCount = 0;
    }

    // @dev create a new pair
    function registerPair(
        uint256 _price,
        address _tokenA, // token que envia
        uint8 _decimalTokenA, // decimales del token
        address _tokenB, // token que recibe
        uint8 _decimalTokenB, // decimales del token
        uint256 _amountForTokens, // monto de token que se envian por ether cuando el oracle esta apagado
        uint256 _fee, // en que se cobra por transacion de este par
        bool _activeOracle, // activa o desactive el oracle
        address _addressOracle, // direccion de oraculo
        uint8 _addressDecimalOracle, //  los 0 que se le van a agregar al oraculo para elevarlo a la 18
        // por ejemplo: si el en 6 decimales este valor debe ser de 12 para elevarlo 18.
        bool _active // activa o descactiva el par
    ) external onlyOwner returns (bool) {
        require(
            _tokenA != _tokenB,
            "MindFactory: Token A and Token B cannot be the same"
        );

        // @dev  save the pair
        _PairstoSwap[pairCount] = Pair(
            _price, // type 1
            _tokenA, // type 2
            _decimalTokenA, // type 3
            _tokenB, // type 4
            _decimalTokenB, // type 5
            _amountForTokens, // type 6
            _fee, // type 7
            _activeOracle, // type 8
            _addressOracle, // type 9
            _addressDecimalOracle, // type 10
            _active // type 11
        );

        // @dev count the number of pairs
        pairCount++;

        // @dev Event that log buy operation
        emit EventPair(_tokenA, _tokenB);

        return true;
    }

    // @dev we return all pair registered
    function pairList() external view returns (Pair[] memory) {
        unchecked {
            Pair[] memory p = new Pair[](pairCount);
            for (uint256 i = 0; i < pairCount; i++) {
                Pair storage s = _PairstoSwap[i];
                p[i] = s;
            }
            return p;
        }
    }

    // @dev enabled oracle
    function pairChange(
        uint8 _type,
        uint8 _decimal,
        uint256 _id,
        bool _bool,
        address _address,
        uint256 _value
    ) public onlyOwner returns (bool success) {
        if (_type == 1) {
            _PairstoSwap[_id].price = _value;
        } else if (_type == 2) {
            _PairstoSwap[_id].tokenA = _address;
        } else if (_type == 3) {
            _PairstoSwap[_id].decimalTokenA = _decimal;
        } else if (_type == 4) {
            _PairstoSwap[_id].tokenB = _address;
        } else if (_type == 5) {
            _PairstoSwap[_id].decimalTokenB = _decimal;
        } else if (_type == 6) {
            _PairstoSwap[_id].amountForTokens = _value;
        } else if (_type == 7) {
            _PairstoSwap[_id].fee = _value;
        } else if (_type == 8) {
            _PairstoSwap[_id].activeOracle = _bool;
        } else if (_type == 9) {
            _PairstoSwap[_id].addressOracle = _address;
        } else if (_type == 10) {
            _PairstoSwap[_id].addressDecimalOracle = _decimal;
        } else if (_type == 11) {
            _PairstoSwap[_id].active = _bool;
        }

        return true;
    }   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract FactoryStakeNft is Context, Ownable {
    event NewNftStake(
        address _sender,
        uint256 _nftId,
        uint256 _unlockTime,
        uint256 _reward
    );

    struct TypeStake {
        string nameAddressNft;
        address addressNft;
        string  nameAddressTokenReward;
        address addressTokenReward;
        uint256 rewardTotal;
        uint256 day;
        bool status;
    }

    mapping(uint256 => TypeStake) _Stake;
    uint256 public _stakeCount;

    constructor() {
        _stakeCount = 0;
    }

    // @dev  register staking types
    function registerStake(
        string memory  _nameAddressNft,
        address _addressNft,
        string memory _nameAddressTokenReward,
        address _addressTokenReward,
        uint256 _rewardTotal,
        uint256 _day,
        bool _status
    ) external onlyOwner returns (bool success) {
        _Stake[_stakeCount] = TypeStake(
            _nameAddressNft,
            _addressNft,
            _nameAddressTokenReward,
            _addressTokenReward,
            _rewardTotal,
            _day,
            _status
        );
        _stakeCount++;

        emit NewNftStake(_msgSender(), _stakeCount, _day, _rewardTotal);

        return true;
    }

    // @dev we return all registered staking types
    function stakeList() external view returns (TypeStake[] memory) {
        unchecked {
            TypeStake[] memory stakes = new TypeStake[](_stakeCount);
            for (uint256 i = 0; i < _stakeCount; i++) {
                TypeStake storage s = _Stake[i];
                stakes[i] = s;
            }
            return stakes;
        }
    }

    // @dev we get the blocking days of a staking type
    function getDays(uint256 _day) public pure returns (uint256) {
        return _day * 1 days;
    }

    // @dev we get the stake of a staking type
    function getStake(uint256 _id) public view returns (TypeStake memory) {
        return _Stake[_id];
    }

    // @dev we deactivate establishment
    function activateStaked(uint256 _id, bool _active)
        external
        onlyOwner
        returns (bool success)
    {
        _Stake[_id].status = _active;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @notice Stakeable is a contract who is ment to be inherited by other contract that wants Staking capabilities
 */
contract StakeableNFT is Context, Ownable {
    using SafeMath for uint256;

    /**
     * @notice Constructor since this contract is not ment to be used without inheritance
     * push once to stakeholders for it to work proplerly
     */
    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        stakeholders.push();
    }

    /**
     * @notice
     * A stake struct is used to represent the way we store stakes,
     * A Stake will contain the users address, the amount staked and a timestamp,
     * Since which is when the stake was made
     */
    struct Stake {
        address user;
        uint256 idNft;
        address addressNft;
        address addressTokenReward;
        uint256 sinceBlock;
        uint256 untilBlock;
        uint256 rewardTotal;
        // This claimable field is new and used to tell how big of a reward is currently available
        uint256 claimable;
    }

    /**
     * @notice Stakeholder is a staker that has active stakes
     */
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }
    /**
     * @notice
     * StakingSummary is a struct that is used to contain all stakes performed by a certain account
     */
    struct StakingSummary {
        uint256 total_amount;
        Stake[] stakes;
    }

    /**
     * @notice
     *   This is a array where we store all Stakes that are performed on the Contract
     *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
     */
    Stakeholder[] internal stakeholders;
    /**
     * @notice
     * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakes;
    /**
     * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */

    event Staked(
        address indexed user,
        uint256 _idNft,
        address _addressNft,
        address _addressTokenReward,
        uint256 _untilBlock,
        uint256 indexed _rewardTotal
    );

    // ---------- STAKES ----------

    /**
     * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256) {
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex;
    }

    /**
     * @notice
     * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
     * StakeID
     */

    function _stake(
        uint256 _idNft,
        address _addressNft,
        address _addressTokenReward,
        uint256 _untilBlock,
        uint256 _rewardTotal
    ) internal {
        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[_msgSender()];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 sinceBlock = getTime();
        // See if the staker already has a staked index or if its the first time
        if (index == 0) {
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(_msgSender());
        }

        uint256 timeToDistribute = sinceBlock + _untilBlock;

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[index].address_stakes.push(
            Stake(
                _msgSender(),
                _idNft,
                _addressNft,
                _addressTokenReward,
                sinceBlock,
                timeToDistribute,
                _rewardTotal,
                0
            )
        );
        // Emit an event that the stake has occured
        emit Staked(
            _msgSender(),
            _idNft,
            _addressNft,
            _addressTokenReward,
            _untilBlock,
            _rewardTotal
        );
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function _totalStakes() internal view returns (uint256) {
        uint256 __totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            __totalStakes =
                __totalStakes +
                stakeholders[s].address_stakes.length;
        }

        return __totalStakes;
    }

    /**
     * @notice
     * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
     * Notice index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to MINT onto the acount
     * Will also calculateStakeReward and reset timer
     */
    function _withdrawStake(uint256 index)
        internal
        returns (
            address,
            address,
            uint256,
            uint256
        )
    {
        // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[_msgSender()];
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];

        // @dev time to distribute is the time the stake is valid until
        require(
            getTime() >= current_stake.untilBlock,
            "Staking: You cannot withdraw, it is still in its authorized blocking time"
        );

        // Calculate available Reward first before we start modifying data
        uint256 reward = current_stake.rewardTotal;

        // Remove by subtracting the money unstaked
        delete stakeholders[user_index].address_stakes[index];

        // return the amount to mint
        return (
            current_stake.addressNft,
            current_stake.addressTokenReward,
            reward,
            current_stake.idNft
        );
    }

    /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function hasStake(address _staker)
        public
        view
        returns (StakingSummary memory)
    {
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount;
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(
            0,
            stakeholders[stakes[_staker]].address_stakes
        );

        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = summary.stakes[s].rewardTotal;
            summary.stakes[s].claimable = availableReward;
            totalStakeAmount = totalStakeAmount + summary.stakes[s].rewardTotal;
        }
        // Assign calculate amount to summary
        summary.total_amount = totalStakeAmount;
        return summary;
    }

    // @dev timestamp of the current block in seconds since the epoch
    function getTime() public view returns (uint256 time) {
        return block.timestamp;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @notice Stakeable is a contract who is ment to be inherited by other contract that wants Staking capabilities
 */
contract StakeableToken is Context, Ownable {
    using SafeMath for uint256;

    /**
     * @notice Constructor since this contract is not ment to be used without inheritance
     * push once to stakeholders for it to work proplerly
     */
    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        stakeholdersToken.push();
    }

    /**
     * @notice
     * A stake struct is used to represent the way we store stakes,
     * A Stake will contain the users address, the amount staked and a timestamp,
     * Since which is when the stake was made
     */
    struct StakeToken {
        address addressToken;
        address user;
        uint256 amount;
        uint256 sinceBlock;
        uint256 untilBlock;
        uint256 rewardRate;
        uint256 rewardPerMonth;
        // This claimable field is new and used to tell how big of a reward is currently available
        uint256 claimable;
    }
    /**
     * @notice Stakeholder is a staker that has active stakes
     */
    struct StakeholderToken {
        address user;
        StakeToken[] address_stakes;
    }
    /**
     * @notice
     * StakingSummary is a struct that is used to contain all stakes performed by a certain account
     */
    struct StakingSummaryToken {
        uint256 total_amount;
        StakeToken[] stakes;
    }

    /**
     * @notice
     *   This is a array where we store all Stakes that are performed on the Contract
     *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
     */
    StakeholderToken[] internal stakeholdersToken;
    /**
     * @notice
     * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakesToken;
    /**
     * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
    event Staked(
        address addressToken,
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 sinceBlock,
        uint256 untilBlock,
        uint256 indexed rewardRate,
        uint256 indexed rewardPerMonth
    );

    // ---------- STAKES ----------

    /**
     * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholderToken(address staker) internal returns (uint256) {
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholdersToken.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholdersToken.length - 1;
        // Assign the address to the new index
        stakeholdersToken[userIndex].user = staker;
        // Add index to the stakeholdersToken
        stakesToken[staker] = userIndex;
        return userIndex;
    }

    /**
     * @notice
     * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
     * StakeID
     */
    function _stakeToken(
        address _tokenAddress,
        uint256 _amount,
        uint256 _untilBlock,
        uint256 _rewardRate,
        uint256 _rewardPerMonth
    ) internal {
        // Simple check so that user does not stake 0
        require(_amount > 0, "Cannot stake nothing");

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakesToken[_msgSender()];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 sinceBlock = getTimeToken();
        // See if the staker already has a staked index or if its the first time
        if (index == 0) {
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholderToken(_msgSender());
        }

        uint256 timeToDistribute = sinceBlock + _untilBlock;

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholdersToken[index].address_stakes.push(
            StakeToken(
                _tokenAddress,
                _msgSender(),
                _amount,
                sinceBlock,
                timeToDistribute,
                _rewardRate,
                _rewardPerMonth,
                0
            )
        );
        // Emit an event that the stake has occured
        emit Staked(
            _tokenAddress,
            _msgSender(),
            _amount,
            index,
            sinceBlock,
            timeToDistribute,
            _rewardRate,
            _rewardPerMonth
        );
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function _totalStakesToken() internal view returns (uint256) {
        uint256 __totalStakes = 0;
        for (uint256 s = 0; s < stakeholdersToken.length; s += 1) {
            __totalStakes =
                __totalStakes +
                stakeholdersToken[s].address_stakes.length;
        }

        return __totalStakes;
    }

    /**
     * @notice
     * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
     * and the duration the stake has been active
     */

    function calculateStakeRewardBlock(StakeToken memory _current_stake)
        internal
        pure
        returns (uint256)
    {
        // @dev take profit percentagee
        return
            (_current_stake.amount * _current_stake.rewardRate) /
            100000000000000000000;
    }

    /**
     * @notice
     * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
     * Notice index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to MINT onto the acount
     * Will also calculateStakeReward and reset timer
     */
    function _withdrawStakeToken(uint256 amount, uint256 index)
        internal
        returns (uint256, address)
    {
        // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakesToken[_msgSender()];
        StakeToken memory current_stake = stakeholdersToken[user_index]
            .address_stakes[index];

        require(
            getTimeToken() >= current_stake.untilBlock,
            "Staking: You cannot withdraw, it is still in its authorized blocking time"
        );

        require(
            current_stake.amount >= amount,
            "Staking: Cannot withdraw more than you have staked"
        );

        // Calculate available Reward first before we start modifying data
        uint256 reward = calculateStakeRewardBlock(current_stake);

        // Remove by subtracting the money unstaked
        current_stake.amount = current_stake.amount - amount;
        // If stake is empty, 0, then remove it from the array of stakes
        if (current_stake.amount == 0) {
            delete stakeholdersToken[user_index].address_stakes[index];
        } else {
            // If not empty then replace the value of it
            stakeholdersToken[user_index]
                .address_stakes[index]
                .amount = current_stake.amount;
            // Reset timer of stake
            stakeholdersToken[user_index]
                .address_stakes[index]
                .sinceBlock = getTimeToken();
        }

        return ((amount + reward), current_stake.addressToken);
    }

    /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function hasStakeToken(address _staker)
        public
        view
        returns (StakingSummaryToken memory)
    {
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount;
        // Keep a summary in memory since we need to calculate this
        StakingSummaryToken memory summary = StakingSummaryToken(
            0,
            stakeholdersToken[stakesToken[_staker]].address_stakes
        );

        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeRewardBlock(
                summary.stakes[s]
            );
            summary.stakes[s].claimable = availableReward;
            totalStakeAmount = totalStakeAmount + summary.stakes[s].amount;
        }
        // Assign calculate amount to summary
        summary.total_amount = totalStakeAmount;
        return summary;
    }

    // @dev timestamp of the current block in seconds since the epoch
    function getTimeToken() public view returns (uint256 time) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FactoryStakeToken is Context, Ownable {
    struct TypeStakeToken {
        string nameAddressToken;
        address addressToken;
        uint256 rewardRate;
        uint256 rewardPerMonth;
        uint256 day;
        uint256 minStaked;
        bool status;
    }
    // @dev minimum tokens for staking
    mapping(uint256 => TypeStakeToken) _StakeToken;
    uint256 public _stakeCountToken;

    constructor() {
        _stakeCountToken = 0;
    }

    // @dev  register staking types
    function registerStakeToken(
        string memory  _nameAddressToken,
        address _addressToken,
        uint256 _rewardRate,
        uint256 _rewardPerMonth,
        uint256 _day,
        uint256 _minStaked,
        bool _status
    ) external onlyOwner returns (bool success) {
        _StakeToken[_stakeCountToken] = TypeStakeToken(
            _nameAddressToken,
            _addressToken,
            _rewardRate,
            _rewardPerMonth,
            _day,
            _minStaked,
            _status
        );
        _stakeCountToken++;
        return true;
    }

    // @dev we return all registered staking types
    function stakeListTokenToken()
        external
        view
        returns (TypeStakeToken[] memory)
    {
        unchecked {
            TypeStakeToken[] memory stakes = new TypeStakeToken[](
                _stakeCountToken
            );
            for (uint256 i = 0; i < _stakeCountToken; i++) {
                TypeStakeToken storage s = _StakeToken[i];
                stakes[i] = s;
            }
            return stakes;
        }
    }

    // we deactivate establishment
    function activeStakeToken(uint256 _id, bool _status)
        external
        onlyOwner
        returns (bool success)
    {
        _StakeToken[_id].status = _status;
        return true;
    }

    // @dev we get the blocking days of a staking type
    function getDaysToken(uint256 _day) public pure returns (uint256) {
        return _day * 1 days;
    }
}