// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface NFTCollectible {
    function mint(address receiver) external payable;
}

contract CoinService {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIdCounter = Counters.Counter(0);

    address private _addressFactory;
    address private _addressRouter;
    address payable private _feeAddress;

    event CreatedContract(address tokenAddress, address tokenOwner);

    event PairCreated(
        address _liquidityOwner,
        address _pairAddress,
        uint256 _amoumntLiquidityTokens
    );

    event MultiTransfer(
        address indexed _from,
        uint256 indexed _value,
        address _to,
        uint256 _amount
    );

    event MultiERC20Transfer(
        address indexed _from,
        uint256 indexed _value,
        address _to,
        uint256 _amount,
        IERC20 _token
    );

    event ContractCreation(address contractAddress);

    event MultiERC721Transfer(
        address _from,
        address _to,
        uint256 _tokenId,
        IERC721 _token
    );

    event MultiERC1155Transfer(
        address _from,
        address _to,
        uint256[] _tokenIds,
        uint256[] _amounts,
        IERC1155 _token
    );

    constructor(
        address payable router,
        address payable facfory,
        address payable feeAddress
    ) {
        _addressRouter = router;
        _feeAddress = feeAddress;
        _addressFactory = facfory;
    }

    /**
     * @notice deploy contract using bytecode
     */
    function deployContract(bytes memory contractBytecode)
        public
        payable
        returns (address)
    {
        address newContract = _createContract(contractBytecode, msg.value);
        emit CreatedContract(newContract, msg.sender);
        return newContract;
    }

    function addLiquidity(
        uint256 feeAmount,
        address addressToken,
        uint256 amountToken
    ) external payable {
        _payFee(feeAmount);
        uint256 amountWETH = SafeMath.sub(msg.value, feeAmount);

        IERC20(addressToken).transferFrom(
            msg.sender,
            address(this),
            amountToken
        );
        IERC20(addressToken).approve(_addressRouter, amountToken);

        (, , uint256 liquidity) = IUniswapV2Router(_addressRouter)
            .addLiquidityETH{value: amountWETH}(
            addressToken,
            amountToken,
            amountToken,
            amountWETH,
            address(msg.sender),
            block.timestamp
        );

        address addressWETH = IUniswapV2Router(_addressRouter).WETH();

        address addressLiquidity = IUniswapV2Factory(_addressFactory).getPair(
            addressWETH,
            addressToken
        );

        emit PairCreated(msg.sender, addressLiquidity, liquidity);
    }

    function getLiquidityPairAddress(address _addressToken)
        external
        view
        returns (address)
    {
        address addressWETH = IUniswapV2Router(_addressRouter).WETH();

        address addressLiquidity = IUniswapV2Factory(_addressFactory).getPair(
            addressWETH,
            _addressToken
        );

        return addressLiquidity;
    }

    /**
     * @notice Send to multiple addresses using two arrays which
     * includes the address and the amount.
     * @param addresses Array of addresses to send to
     * @param amounts Array of amounts to send
     * @param feeAmount Amount of fee to collect
     */
    function multiTransfer(
        uint256 feeAmount,
        address[] memory addresses,
        uint256[] memory amounts
    ) public payable returns (bool) {
        _payFee(feeAmount);

        uint256 toReturn = SafeMath.sub(msg.value, feeAmount);
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeTransfer(addresses[i], amounts[i]);
            toReturn = SafeMath.sub(toReturn, amounts[i]);
            emit MultiTransfer(msg.sender, msg.value, addresses[i], amounts[i]);
        }
        _safeTransfer(msg.sender, toReturn);
        return true;
    }

    /**
     * @notice Send ERC20 tokens to multiple contracts
     * using two arrays which includes the address and the amount.
     * Ther is no fee param as fee is strictly msg.value.
     * @param token The token to send
     * @param addresses Array of addresses to send to
     * @param amounts Array of token amounts to send
     * Bytecode from deploy transaction is required if constructor has args.
     */
    function multiERC20Transfer(
        IERC20 token,
        address[] memory addresses,
        uint256[] memory amounts
    ) public payable {
        _payFee(msg.value);

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeERC20Transfer(token, addresses[i], amounts[i]);
            emit MultiERC20Transfer(
                msg.sender,
                msg.value,
                addresses[i],
                amounts[i],
                token
            );
        }
    }

    function multiERC721Transfer(
        IERC721 token,
        address[] memory addresses,
        uint256[] memory tokenIds
    ) public payable {
        _payFee(msg.value);
        for (uint256 i = 0; i < addresses.length; i++) {
            token.safeTransferFrom(msg.sender, addresses[i], tokenIds[i]);

            emit MultiERC721Transfer(
                msg.sender,
                addresses[i],
                tokenIds[i],
                token
            );
        }
    }

    struct BatchTransfer {
        address to;
        uint256[] tokenIds;
        uint256[] amounts;
    }

    function multiERC1155Transfer(
        IERC1155 token,
        address[] memory addresses,
        BatchTransfer[] memory transfers
    ) public payable {
        _payFee(msg.value);
        for (uint256 i = 0; i < addresses.length; i++) {
            token.safeBatchTransferFrom(
                msg.sender,
                addresses[i],
                transfers[i].tokenIds,
                transfers[i].amounts,
                ""
            );

            emit MultiERC1155Transfer(
                msg.sender,
                addresses[i],
                transfers[i].tokenIds,
                transfers[i].amounts,
                token
            );
        }
    }

    /**
     * @notice Method to mint nft
     * Message sender is required to pay fee.
     * Under the hood method is invoking mint on ERC721 contract
     * @param tokenAddress - address of NFT contract to mint tokens
     * @param feeAmount - amount of fee that message sender is required to cover
     */
    function mintNFT(address tokenAddress, uint256 feeAmount) public payable {
        _payFee(feeAmount);
        uint256 amountToPayForMint = SafeMath.sub(msg.value, feeAmount);

        NFTCollectible(tokenAddress).mint{value: amountToPayForMint}(
            msg.sender
        );
    }

    /**
     * @notice Pay service fee and send funds to fee address
     */
    function _payFee(uint256 amount) internal {
        require(amount > 0, "Insufficient WEI amount");
        _safeTransfer(_feeAddress, amount);
    }

    /**
     * @notice method which is used internally to transfer funds safely.
     */
    function _safeTransfer(address to, uint256 amount) internal {
        require(to != address(0x0));
        payable(to).transfer(amount);
    }

    /**
     * @notice method which is used internally to
     * transfer a quantity of ERC20 tokens safely.
     */
    function _safeERC20Transfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        require(to != address(0x0));
        require(token.transferFrom(msg.sender, to, amount));
    }

    /**
     * @notice Creation of the contract using bytecode.
     * @dev This uses create opcode to create contract using bytecode.
     * @param contractBytecode Bytecode from deploy transaction is required if constructor has args.
     */
    function _createContract(bytes memory contractBytecode, uint256 feeAmount)
        internal
        returns (address newContract)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create(
                feeAmount,
                add(contractBytecode, 0x20),
                mload(contractBytecode)
            )
        }
        require(newContract != address(0), "Could not deploy contract");
    }
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IERC1155 {
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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