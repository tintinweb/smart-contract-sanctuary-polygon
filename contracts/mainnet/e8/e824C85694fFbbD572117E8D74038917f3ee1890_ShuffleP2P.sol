// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./VerifyLibrary.sol";
import "./SimpleLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ShuffleP2P is ERC20 {
    using SimpleLibrary for *;
    using VerifyLibrary for *;

    struct ShuffleInfo {
        uint256 activePlayers;
        uint256 totalPlayers;
        uint256 totalBuyinsAtPlay;
        uint256 supplyInCirculation;
        uint256 adAuctionClosingTime;
    }

    ShuffleInfo public shuffleInfo;

    struct Player {
        address sigAddress;
        address currentOpponent;
        uint256 buyinAmount;
        bool isActive;
    }
    mapping(address => Player) players;

    struct Advertiser {
        address ethAddr;
        bytes32 ipfsCid;
        uint256 bidAmount;
        uint256 bidTimestamp;
    }

    bytes32 public currentAdvertisement;
    Advertiser public adHighestBidder;

    event GameCreated(
        address indexed _creator,
        address indexed _opponent,
        uint256 _buyin
    );
    event GameStarted(
        address indexed _creator,
        address indexed _opponent,
        uint256 _buyin
    );
    event GameConceded(
        address indexed _winner,
        address indexed _loser,
        uint256 _buyin
    );

    uint256 constant _initial_supply = 1000 * (10**18);

    constructor() ERC20("ShuffleP2P", "SHFL") {
        _mint(address(this), _initial_supply);
        shuffleInfo.adAuctionClosingTime = block.timestamp + 4 weeks;
    }

    receive() external payable {}

    function buyin(
        address _sigAddress,
        address _opponent,
        uint256 _buyinAmount
    ) external payable {
        uint256 _buyin;
        require(!players[msg.sender].isActive, "already active");
        if (players[_opponent].isActive) {
            require(players[_opponent].currentOpponent == msg.sender);
            _buyin = players[_opponent].buyinAmount;
        } else {
            _buyin = _buyinAmount;
        }
        require(msg.value >= ((_buyin * 12) / 10), "insufficient deposit");
        Player memory player = Player(_sigAddress, _opponent, _buyin, true);
        players[msg.sender] = player;
        if (players[_opponent].currentOpponent == msg.sender) {
            emit GameStarted(_opponent, msg.sender, msg.value);
        } else {
            emit GameCreated(msg.sender, _opponent, msg.value);
        }
        shuffleInfo.totalPlayers++;
        shuffleInfo.activePlayers++;
    }

    function concedeAll() external {
        require(players[msg.sender].isActive);

        // declare variables for final transfer
        address _opponent = players[msg.sender].currentOpponent;
        uint256 _buyin = players[msg.sender].buyinAmount;
        uint256 _remainder = (_buyin * 12) / 10 - _buyin;
        uint256 _transferAmount = _buyin * 2 + _remainder;

        // transfer winnings to winner and deposit amount back to conceding player
        payable(_opponent).transfer(_transferAmount);
        payable(msg.sender).transfer(_remainder);

        // reset player accounts to 0
        players[_opponent] = Player(address(0), address(0), 0, false);
        players[msg.sender] = Player(address(0), address(0), 0, false);
        shuffleInfo.activePlayers -= 2;
        // emit final event announcing the game as completed
        emit GameConceded(_opponent, msg.sender, _buyin);
    }

    function submitAdBid(bytes32 _ipfsCid) external payable {
        require(msg.value > adHighestBidder.bidAmount, "bid too low!");
        require(
            block.timestamp < shuffleInfo.adAuctionClosingTime,
            "too late!"
        );
        if (adHighestBidder.ethAddr != address(0)) {
            payable(adHighestBidder.ethAddr).transfer(
                adHighestBidder.bidAmount
            );
        }
        adHighestBidder = Advertiser(
            msg.sender,
            _ipfsCid,
            msg.value,
            block.timestamp
        );
    }

    function pushAdPurchase() external {
        require(players[msg.sender].isActive);
        require(block.timestamp > shuffleInfo.adAuctionClosingTime);
        currentAdvertisement = adHighestBidder.ipfsCid;
        adHighestBidder = Advertiser(address(0), 0, 0, 0);
        shuffleInfo.adAuctionClosingTime = block.timestamp + 4 weeks;
    }

    function getSigKey(address _userAddress)
        public
        view
        returns (address _sigAddress)
    {
        require(players[msg.sender].isActive);
        _sigAddress = players[_userAddress].sigAddress;
    }

    // this is defined here to encourage fair play and concedes. should not have to be used much as loser will usually want their 20% deposit back.
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library SimpleLibrary {
    // only necessary within this library -- used in parseAllCards()
    function parseCardValue(uint8 _cardValue)
        internal
        pure
        returns (uint8 _value)
    {
        uint8 _cardSuit = _cardValue % 4;
        if (_cardSuit == 0) {
            _cardSuit = 4;
        }
        _value = (_cardValue - _cardSuit) / 4 + 1;
    }

    // only necessary within this library
    function parseBothCardValues(uint8[2] memory _cards)
        internal
        pure
        returns (uint8, uint8)
    {
        uint8 _cardVal = parseCardValue(_cards[0]);
        uint8 _oppCardVal = parseCardValue(_cards[1]);

        return (_cardVal, _oppCardVal);
    }

    function parseInt(string memory _string) internal pure returns (uint256) {
        bytes memory _bytes = bytes(_string);
        uint256 result = 0;
        for (uint8 i = 0; i < _bytes.length; i++) {
            result = result * 10 + (uint8(_bytes[i]) - 48);
        }
        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library VerifyLibrary {
    function prepHashForSig(string memory _message)
        internal
        pure
        returns (bytes32 _ethHash)
    {
        // message header --- fill in length later
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length := mload(_message)
            lengthOffset := add(header, 57)
        }
        require(length <= 999999);
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            // non-zero digit or non-leading zero digit
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;

            // convert the digit to its asciii representation (man ascii)
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        // null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        _ethHash = keccak256(abi.encodePacked(header, _message));
    }

    function verifyHash(
        bytes32 _hash,
        string memory _message,
        string memory _salt
    ) internal pure returns (bool _verified) {
        _verified = keccak256(abi.encodePacked(_message, _salt)) == _hash;
    }

    function verifyProof(
        bytes32 _leaf,
        bytes32[] memory _proof,
        uint256[] memory _position,
        bytes32 _root
    ) internal pure returns (bool _verified) {
        bytes32 _data = _leaf;
        for (uint256 i = 0; i < _proof.length; i++) {
            if (_position[i] == 0) {
                _data = keccak256(abi.encodePacked(_data, _proof[i]));
            } else {
                _data = keccak256(abi.encodePacked(_proof[i], _data));
            }
        }
        _verified = (_data == _root);
    }

    function proveIncHash(
        address _oppSigKey,
        bytes32 _incHash,
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes32 _merkleRoot,
        bytes32[] memory _proof,
        uint256[] memory _proofPosition
    ) internal pure returns (bool _proven) {
        require(
            _oppSigKey == ecrecover(_merkleRoot, _sigV, _sigR, _sigS),
            "unable to validate signature"
        );
        require(
            verifyProof(_incHash, _proof, _proofPosition, _merkleRoot),
            "unable to verify merkle proof"
        );
        _proven = true;
    }

    function proveIncString(
        address _oppSigKey,
        string memory _incString,
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes32 _merkleRoot,
        bytes32[] memory _proof,
        uint256[] memory _proofPosition
    ) internal pure returns (bool _proven) {
        bytes32 _ethHash = prepHashForSig(_incString);
        require(
            _oppSigKey == ecrecover(_ethHash, _sigV, _sigR, _sigS),
            "unable to verify signature"
        );
        require(
            verifyProof(_ethHash, _proof, _proofPosition, _merkleRoot),
            "unable to verify merkle proof"
        );
        _proven = true;
    }

    function proveHiddenString(
        address _oppSigKey,
        string memory _hiddenString,
        string memory _salt,
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes32 _merkleRoot,
        bytes32[] memory _proof,
        uint256[] memory _proofPosition
    ) internal pure returns (bool _proven) {
        string memory _fullString = string.concat(_hiddenString, _salt);
        _proven = proveIncString(
            _oppSigKey,
            _fullString,
            _sigV,
            _sigR,
            _sigS,
            _merkleRoot,
            _proof,
            _proofPosition
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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