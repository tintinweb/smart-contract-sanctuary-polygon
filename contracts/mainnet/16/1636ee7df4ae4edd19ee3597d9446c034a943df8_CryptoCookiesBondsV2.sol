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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IOracleSimple} from "./interfaces/IOracleSimple.sol";

interface IERC20Burneable is IERC20 {
    function burn(uint256 amount) external;
}

interface IWETH {
    function deposit() external payable;
}

interface IBondManagerStrategy {
    function run() external;
}

/// @title Sugar Bonds
/// @notice Bonds mechanism to sell $CKIE at a fixed price for $WMATIC, and vested in vestingDays days
contract CryptoCookiesBondsV2 is Owned(msg.sender) {
    error errWrongDiscount();

    event BondTermsStart(uint128 indexed uid, Bond bond, string details);
    event BondTermsEnd(uint128 indexed uid, uint256 cookieRemains);

    event NoteAdded(address indexed owner, uint256 indexed noteId, uint256 amountMATIC, uint256 cookiesForUser);
    event NoteRedeem(address indexed owner, uint256 indexed noteId, uint256 redeemAmount);

    struct Bond {
        uint128 uid;
        uint40 bondStart;
        uint16 vestingDays;
        uint24 startDiscount;
        uint24 endDiscount;
        uint16 dailyDiscount;
        uint8 disabled;
        uint128 bondedCookies;
        uint128 cookiesToBond;
        address bondManagerStrategy;
    }

    struct Note {
        uint256 uid;
        uint128 uidBond;
        uint40 timestampStart;
        uint40 timestampLastRedeem;
        uint40 timestampEnd;
        uint128 paid;
        uint128 totalCookies;
        address owner;
    }

    /// @dev base percentage 1e6 = 100%
    uint256 constant BASE_PERC = 100_0000;

    uint256 constant BASE_ETH = 1 ether;

    uint128 private _totalBonds;
    uint256 private _noteIdCounter;

    ///@dev CKIE
    IERC20Burneable public immutable COOKIETOKEN;
    ///@dev WMATIC
    address public immutable WMATIC;
    ///@dev TWAP oracle for CKIE price against WMATIC
    IOracleSimple public immutable ORACLE;

    address public immutable GAME;

    mapping(uint128 => Bond) public bonds;
    mapping(uint128 => Note) public notes;
    mapping(address => uint128[]) public toNotes;

    ///@dev list of active bonds
    uint128[] public activeBonds;

    constructor(address _cookieToken, address _wmatic, address _oracleSimple, address _game) {
        COOKIETOKEN = IERC20Burneable(_cookieToken);
        WMATIC = _wmatic;
        ORACLE = IOracleSimple(_oracleSimple);
        GAME = _game;
    }

    /// @notice Withdraw a token or ether stuck in the contract
    /// @param token Address of the ERC20 to withdraw, use address 0 for MATIC
    /// @param amount amount of token to withdraw
    function withdraw(address token, uint256 amount) external onlyOwner {
        ///@dev cant withdraw CKIE
        if (token == address(COOKIETOKEN)) {
            revert();
        }

        if (token == address(0)) {
            SafeTransferLib.safeTransferETH(msg.sender, amount);
        } else {
            ///@dev no need for safeTransfer
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    /// @notice Explain to an end user what this does
    /// @param _vestingDays number of day for vesting the bond
    /// @param _startDiscount BPS discount start (recommend 0)
    /// @param _endDiscount BPS discount max
    /// @param _dailyDiscount daily BPS discount
    /// @param _cookiesToBond amount of CKIE to sell
    /// @param _bondManagerStrategy address of the contract that will manage the WMATIC
    /// @param details string details of the bond (for graphql)
    function startBondSell(
        uint16 _vestingDays,
        uint24 _startDiscount,
        uint24 _endDiscount,
        uint16 _dailyDiscount,
        uint128 _cookiesToBond,
        address _bondManagerStrategy,
        string memory details
    ) external onlyOwner {
        require(_cookiesToBond > 0, "No cookies to bond");
        if (_startDiscount > _endDiscount) {
            revert errWrongDiscount();
        }

        uint128 bondUid;
        // Sumo 101% del _cookiesToBond, ya que 1% es para devs
        (bool success,) = GAME.call(abi.encodeWithSignature("sugarBondMint(uint256)", (_cookiesToBond * 101) / 100));
        require(success, "Bond mint failed");

        unchecked {
            bondUid = ++_totalBonds;
        }

        activeBonds.push(bondUid);

        emit BondTermsStart(
            bondUid,
            bonds[bondUid] = Bond({
                uid: bondUid,
                bondStart: uint40(block.timestamp),
                vestingDays: _vestingDays,
                startDiscount: _startDiscount,
                endDiscount: _endDiscount,
                dailyDiscount: _dailyDiscount,
                disabled: 0,
                bondedCookies: 0,
                cookiesToBond: _cookiesToBond,
                bondManagerStrategy: _bondManagerStrategy
            }),
            details
            );
    }

    /// @notice end a bond sell
    /// @dev this function will end the bond and burn the remaining cookies
    /// @param uid bond uid
    function endBondSell(uint128 uid) external onlyOwner {
        _endBondSell(uid);
    }

    function _endBondSell(uint128 uid) private {
        Bond memory _bond = bonds[uid];
        require(_bond.disabled == 0, "Bond is terminated");
        uint256 cookieRemains = _bond.cookiesToBond - _bond.bondedCookies;
        if (cookieRemains > 0) {
            COOKIETOKEN.burn(cookieRemains);
        }
        bonds[uid].disabled = 1;

        uint128[] storage _activeBonds = activeBonds;
        uint256 len = _activeBonds.length;

        unchecked {
            uint256 pos;
            while (true) {
                if (_activeBonds[pos] == uid) {
                    break;
                }
                ++pos;
            }

            if (len - 1 != pos) {
                _activeBonds[pos] = _activeBonds[len - 1];
            }
        }

        _activeBonds.pop();

        emit BondTermsEnd(uid, cookieRemains);
    }

    function buyBond(uint128 uid) external payable {
        Bond storage _bond = bonds[uid];
        require(_bond.cookiesToBond > 0, "The bond was ended");
        require(_bond.disabled < 1, "Bond is terminated");

        // update oracle if needed
        ORACLE.update();

        uint128 value = uint128(msg.value);
        uint16 vestingDays = _bond.vestingDays;

        uint128 discountPrice = priceOfCookieWithDiscount(uid);
        uint128 cookiesForUser = (value * uint128(BASE_ETH)) / discountPrice;

        uint128 cookieRemains = _bond.cookiesToBond - _bond.bondedCookies;
        if (cookieRemains <= cookiesForUser) {
            cookiesForUser = cookieRemains;
            value = (cookieRemains * discountPrice) / uint128(BASE_ETH);
        }
        bonds[uid].bondedCookies += uint128(cookiesForUser);

        // @dev 100% / 100 = 1%, 1% for devs
        uint256 forDev = cookiesForUser / 100;
        COOKIETOKEN.transfer(owner, forDev);

        uint128 noteUid;
        unchecked {
            noteUid = uint128(++_noteIdCounter);

            notes[noteUid] = Note({
                uid: noteUid,
                uidBond: _bond.uid,
                timestampStart: uint40(block.timestamp),
                timestampLastRedeem: uint40(block.timestamp),
                timestampEnd: uint40(block.timestamp + vestingDays * 1 days),
                paid: 0,
                totalCookies: cookiesForUser,
                owner: msg.sender
            });
        }

        toNotes[msg.sender].push(noteUid);

        /// @dev wrap MATIC
        IWETH(WMATIC).deposit{value: value}();
        IERC20(WMATIC).transfer(_bond.bondManagerStrategy, value);

        // ignore return
        _bond.bondManagerStrategy.call(abi.encodeWithSignature("run()"));

        emit NoteAdded(msg.sender, noteUid, value, cookiesForUser);

        if (_bond.cookiesToBond == _bond.bondedCookies) {
            _endBondSell(uid);
        }

        if (value < msg.value) {
            unchecked {
                SafeTransferLib.safeTransferETH(msg.sender, msg.value - value);
            }
        }
    }

    /// @notice Redeem all bonds for msg.sender
    function redeemAll() external {
        uint128[] memory _notes = toNotes[msg.sender];
        uint256 len = _notes.length;
        unchecked {
            while (len > 0) {
                redeem(_notes[--len]);
            }
        }
    }

    function redeem(uint128 noteId) public returns (bool resize) {
        Note storage note = notes[noteId];
        require(note.owner == msg.sender, "!noteOwner");

        uint256 redeemAmount = _toRedeem(noteId);

        if (redeemAmount == 0) {
            revert();
        }

        note.timestampLastRedeem = uint40(block.timestamp);
        unchecked {
            note.paid += uint128(redeemAmount);
        }

        if (note.paid == note.totalCookies) {
            _deleteNote(msg.sender, noteId);
            resize = true;
        }

        COOKIETOKEN.transfer(msg.sender, redeemAmount);
        emit NoteRedeem(msg.sender, noteId, redeemAmount);
    }

    function getNote(address account, uint256 index) external view returns (Note memory) {
        return notes[toNotes[account][index]];
    }

    function getNotes(address account) external view returns (Note[] memory) {
        uint256 len = toNotes[account].length;
        Note[] memory ret = new Note[](len);
        for (uint256 i; i < len; ++i) {
            ret[i] = notes[toNotes[account][i]];
        }
        return ret;
    }

    function notesLength(address account) public view returns (uint256) {
        return toNotes[account].length;
    }

    function activeBondsLength() public view returns (uint256) {
        return activeBonds.length;
    }

    function currentDiscount(uint128 uid) public view returns (uint24 discount) {
        Bond memory _bond = bonds[uid];
        require(_bond.disabled == 0, "Bond is terminated");
        
        discount = uint24(
            uint256(_bond.startDiscount) + ((block.timestamp - uint256(_bond.bondStart)) * uint256(_bond.dailyDiscount)) / 1 days
        );

        if (discount > _bond.endDiscount) {
            discount = _bond.endDiscount;
        }

        if (discount > BASE_PERC) {
            discount = uint24(BASE_PERC);
        }
    }

    function priceOfCookieWithDiscount(uint128 uid) public view returns (uint128 discountPrice) {
        discountPrice = uint128(ORACLE.consult(address(COOKIETOKEN), uint256(BASE_ETH)));
        discountPrice = discountPrice * (uint128(BASE_PERC) - uint128(currentDiscount(uid))) / uint128(BASE_PERC);
    }

    function _toRedeem(uint128 _noteId) internal view returns (uint256 ret) {
        Note memory note = notes[_noteId];
        uint256 _timestampEnd = note.timestampEnd;
        uint256 _totalCookies = note.totalCookies;

        if (block.timestamp > _timestampEnd) {
            uint256 _paid = note.paid;
            assembly {
                ret := sub(_totalCookies, _paid)
            }
        } else {
            uint256 _timestampLastRedeem = note.timestampLastRedeem;
            uint256 _timestampStart = note.timestampStart;

            assembly {
                if lt(timestamp(), _timestampLastRedeem) { revert(0, 0) }
                let deltaY := sub(timestamp(), _timestampLastRedeem)
                let redeemPerc := div(mul(deltaY, BASE_ETH), sub(_timestampEnd, _timestampStart))
                ret := div(mul(_totalCookies, redeemPerc), BASE_ETH)
            }
        }
    }

    function toRedeem(address _account)
        external
        view
        returns (uint128[] memory notesIds, uint256[] memory pendingAmount)
    {
        notesIds = toNotes[_account];
        uint256 len = notesIds.length;
        pendingAmount = new uint256[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
                pendingAmount[i] = _toRedeem(uint128(notesIds[i]));
            }
        }
    }

    function totalToRedeem(address account) external view returns (uint256 pendingAmount) {
        uint128[] memory notesIds = toNotes[account];
        uint256 len = notesIds.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                pendingAmount = pendingAmount + _toRedeem(uint128(notesIds[i]));
            }
        }
    }

    function detailActiveBonds() external view returns (Bond[] memory ret) {
        uint256 len = activeBonds.length;
        ret = new Bond[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
                ret[i] = bonds[activeBonds[i]];
            }
        }
        return ret;
    }

    /// @dev assume that always noteUid is a note if that exist in the array userNotes
    function _deleteNote(address account, uint256 noteUid) internal {
        uint128[] storage userNotes = toNotes[account];
        uint256 len = userNotes.length;

        unchecked {
            uint256 pos;
            while (true) {
                if (userNotes[pos] == noteUid) {
                    break;
                }
                ++pos;
            }

            if (len - 1 != pos) {
                userNotes[pos] = userNotes[len - 1];
            }
        }

        userNotes.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracleSimple {
    function update() external;

    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);

    function token0() external view returns (address);

    function token1() external view returns (address);
}