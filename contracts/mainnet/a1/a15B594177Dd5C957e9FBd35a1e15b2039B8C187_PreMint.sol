/**
 *Submitted for verification at polygonscan.com on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
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
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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

pragma solidity ^0.8.0;

contract PreMint is Ownable {
    IERC20 public wEthContract;
    using SafeMath for uint256;
    using Strings for uint256;
    uint256 public publicCost = 0.2644 ether;
    uint256 public whiteCost = 0.2252 ether;
    uint256 public bronzeCost = 0.2119 ether;
    uint256 public goldCost = 0.1854 ether;
    uint256 public platinumCost = 0.1537 ether;
    uint256 public whiteWallet = 350;
    uint256 public bronzeWallet = 240;
    uint256 public goldWallet = 80;
    uint256 public platinumWallet = 40;
    uint256 public maxPreMinted = 7800;
    uint256 public totalPreList;
    bool public pricePaused = false;
    bool public preMintPaused = true;
    mapping(address => uint256) public addressPreMintedBalance;
    mapping(address => uint256) public addressTier;
    uint256 public platinumListLength;
    uint256 public goldListLength;
    uint256 public bronzeListLength;
    uint256 public whiteListLength;
    event tierChange(address _address);

    constructor(address _tokenAddress) {
        wEthContract = IERC20(_tokenAddress);
    }

    function preMint(uint256 _mintAmount) public {
        uint256 total = 0;
        require(!preMintPaused, "Pre-Reserve is Paused");
        require(_mintAmount > 0, "Need to Pre-Reserve at Least 1 NFT");
        require(
            totalPreList + _mintAmount <= maxPreMinted,
            "Maximum NFT's Pre-Reserved"
        );
        if (!pricePaused) {
            total = calculateCost(_mintAmount);
        }
        require(
            wEthContract.allowance(msg.sender, address(this)) >= total,
            "Approve Failed"
        );
        bool success = wEthContract.transferFrom(
            msg.sender,
            address(this),
            total
        );
        require(success, "Transfer Failed");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            listRefresh();
            totalPreList++;
            addressPreMintedBalance[msg.sender]++;
            emit tierChange(msg.sender);
        }
    }

    function calculateCost(uint256 _mintAmount) public view returns (uint256) {
        uint256 total = 0;
        uint256 tempBalance = addressPreMintedBalance[msg.sender];
        for (uint256 i = 1; i <= _mintAmount; i++) {
            total = total.add(mintCost(tempBalance));
            tempBalance++;
        }
        return total;
    }

    function listRefresh() internal {
        if (
            bronzeListLength < bronzeWallet &&
            addressPreMintedBalance[msg.sender] < 10 &&
            addressPreMintedBalance[msg.sender] >= 4
        ) {
            if (addressTier[msg.sender] != 2) {
                if (addressTier[msg.sender] != 0) {
                    whiteListLength = whiteListLength.sub(1);
                }
                bronzeListLength++;
                addressTier[msg.sender] = 2;
            }
        }
        if (
            goldListLength < goldWallet &&
            addressPreMintedBalance[msg.sender] < 25 &&
            addressPreMintedBalance[msg.sender] >= 10
        ) {
            if (addressTier[msg.sender] != 3) {
                if (addressTier[msg.sender] == 1) {
                    whiteListLength = whiteListLength.sub(1);
                }
                if (addressTier[msg.sender] == 2) {
                    bronzeListLength = bronzeListLength.sub(1);
                }
                goldListLength++;
                addressTier[msg.sender] = 3;
            }
        }
        if (
            platinumListLength < platinumWallet &&
            addressPreMintedBalance[msg.sender] < 50 &&
            addressPreMintedBalance[msg.sender] >= 25
        ) {
            if (addressTier[msg.sender] != 4) {
                if (addressTier[msg.sender] == 1) {
                    whiteListLength = whiteListLength.sub(1);
                }
                if (addressTier[msg.sender] == 2) {
                    bronzeListLength = bronzeListLength.sub(1);
                }
                if (addressTier[msg.sender] == 3) {
                    goldListLength = goldListLength.sub(1);
                }
                platinumListLength++;
                addressTier[msg.sender] = 4;
            }
        }
    }

    function mintCost(uint256 tempBalance) internal view returns (uint256) {
        if (addressTier[msg.sender] == 1 && tempBalance < 4) {
            return whiteCost;
        }
        if (
            addressTier[msg.sender] == 2 && tempBalance < 10 && tempBalance >= 4
        ) {
            return bronzeCost;
        }
        if (
            bronzeListLength < bronzeWallet &&
            tempBalance < 10 &&
            tempBalance >= 4
        ) {
            return bronzeCost;
        }
        if (
            addressTier[msg.sender] == 3 &&
            tempBalance < 25 &&
            tempBalance >= 10
        ) {
            return goldCost;
        }
        if (
            goldListLength < goldWallet && tempBalance < 25 && tempBalance >= 10
        ) {
            return goldCost;
        }
        if (
            addressTier[msg.sender] == 4 &&
            tempBalance < 50 &&
            tempBalance >= 25
        ) {
            return platinumCost;
        }
        if (
            platinumListLength < platinumWallet &&
            tempBalance < 50 &&
            tempBalance >= 25
        ) {
            return platinumCost;
        }

        return publicCost;
    }

    //only owner

    function collectionDetailChange(uint256[] calldata details)
        public
        onlyOwner
    {
        publicCost = details[0];
        whiteCost = details[1];
        bronzeCost = details[2];
        goldCost = details[3];
        platinumCost = details[4];
        whiteWallet = details[5];
        bronzeWallet = details[6];
        goldWallet = details[7];
        platinumWallet = details[8];
        maxPreMinted = details[9];
    }

    function preMintPause(bool _state) public onlyOwner {
        preMintPaused = _state;
    }

    function pricePause(bool _state) public onlyOwner {
        pricePaused = _state;
    }

    function addWhiteList(address[] calldata _addresses) public onlyOwner {
        require(whiteListLength < whiteListLength + _addresses.length);

        for (uint256 i = 0; i < _addresses.length; i++) {
            addressTier[_addresses[i]] = 1;
            whiteListLength++;
        }
    }



    function withdraw(uint256 _amount) public payable onlyOwner {
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        wEthContract.transfer(msg.sender, _amount);

        require(os);
        // =============================================================================
    }
}