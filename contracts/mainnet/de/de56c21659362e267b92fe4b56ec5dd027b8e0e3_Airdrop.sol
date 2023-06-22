// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";
import "sismo-connect-solidity/SismoLib.sol"; // <--- add a Sismo Connect import

/*
 * @title Airdrop
 * @author Sismo
 * @dev Simple Airdrop contract that mints ERC20 tokens to a receiver
 * This contract is used for tutorial purposes only
 * It will be used to demonstrate how to integrate Sismo Connect
 */
contract Airdrop is ERC20, SismoConnect {
  using SismoConnectHelper for SismoConnectVerifiedResult;
  error UserNotEligibleForAirdrop();

  struct StoredClaim {
    bytes16 groupId;
    uint256 value;
    bool claimed;
  }

  mapping(uint256 user => mapping(bytes16 groupId => StoredClaim)) public userClaims;

  bytes16 public constant GITCOIN_PASSPORT_GROUP_ID = 0x1cde61966decb8600dfd0749bd371f12;
  bytes16 public constant SISMO_COMMUNITY_MEMBERS_GROUP_ID = 0xd630aa769278cacde879c5c0fe5d203c;
  bytes16 public constant SISMO_COMMUNITY_EARLY_MEMBERS = 0xe4c011331d91b79639df349a93157a1b;
  bytes16 public constant SISMO_FACTORY_USERS = 0x05629c9a54e30d8c8aea911a48cd9e30;
  uint256 public constant REWARD_BASE_VALUE = 100 * 10 ** 18;

  constructor(
    string memory name,
    string memory symbol,
    bytes16 appId,
    bool isImpersonationMode
  ) ERC20(name, symbol) SismoConnect(buildConfig(appId, isImpersonationMode)) {}

  function _getRewardAmount(
    SismoConnectVerifiedResult memory result,
    uint256 userId
  ) private returns (uint256) {
    uint256 airdropAmount = 0;

    // we iterate over the claims returned by the Sismo Connect 
    for (uint i = 0; i < result.claims.length; i++) {
      VerifiedClaim memory verifiedClaim = result.claims[i];
      bytes16 groupId = verifiedClaim.groupId;

      StoredClaim storage userClaim = userClaims[userId][groupId];
      userClaim.groupId = groupId;

      // we check if the user is eligible for the airdrop
      if (groupId == SISMO_COMMUNITY_MEMBERS_GROUP_ID) {
        bool isClaimable = verifiedClaim.value > userClaim.value;
        if (isClaimable) {
          // if the user is eligible, we store the claim and add the airdrop value
          // for SISMO_COMMUNITY_MEMBERS_GROUP_ID, the value is level in the community
          airdropAmount += (verifiedClaim.value - userClaim.value) * REWARD_BASE_VALUE;
          userClaim.claimed = true;
          userClaim.value = verifiedClaim.value;
          // store airdrop value
        }
      } else {
        if (!userClaim.claimed) {
          // if the user is eligible, we store the claim and add the airdrop value
          airdropAmount += REWARD_BASE_VALUE;
          userClaim.claimed = true;
          userClaim.value = verifiedClaim.value;
          // store airdrop value
        }
      }
    }
    return airdropAmount;
  }

  function claimWithSismo(address receiver, bytes memory response) public {
    // we want to verify 4 claims and 1 auth request

    // we are recreating the auth request made in the frontend to be sure that
    // the proofs provided in the response are valid with respect to this auth request
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = buildAuth({authType: AuthType.VAULT});


    // we want to verify 4 claims
    // we are recreating the claims made in the frontend to be sure that
    // the proofs provided in the response are valid with respect to these claims
    ClaimRequest[] memory claims = new ClaimRequest[](4);
    claims[0] = buildClaim({
      groupId: GITCOIN_PASSPORT_GROUP_ID,
      claimType: ClaimType.GTE,
      value: 15
    });
    claims[1] = buildClaim({
      groupId: SISMO_COMMUNITY_MEMBERS_GROUP_ID,
      isSelectableByUser: true,
      isOptional: false
    });
    claims[2] = buildClaim({
      groupId: SISMO_COMMUNITY_EARLY_MEMBERS,
      isSelectableByUser: false,
      isOptional: true
    });
    claims[3] = buildClaim({
      groupId: SISMO_FACTORY_USERS,
      isSelectableByUser: false,
      isOptional: true
    });

    // we verify the response
    SismoConnectVerifiedResult memory result = verify({
      responseBytes: response,
      // we want the user to prove that he owns a Sismo Vault
      auths: auths,
      claims: claims,
      // we also want to check if the signed message provided in the response is the signature of the user's address
      signature: buildSignature({message: abi.encode(receiver)})
    });

    // if the proofs and signed message are valid, we take the userId from the verified result
    // in this case the userId is the vaultId (since we used AuthType.VAULT in the auth request), the anonymous identifier of a user's vault for a specific app --> userId = hash(userVaultSecret, appId)
    uint256 userId = result.getUserId(AuthType.VAULT);

    //we get the airdrop amount from the verified result based on the number of claims and auths that were verified
    uint256 airdropAmount = _getRewardAmount(result, userId);

    if (airdropAmount == 0) revert UserNotEligibleForAirdrop();

    // we mint the tokens to the user
    _mint(receiver, airdropAmount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title SismoLib
 * @author Sismo
 * @notice This is the Sismo Library of the Sismo protocol
 * It is designed to be the only contract that needs to be imported to integrate Sismo in a smart contract.
 * Its aim is to provide a set of sub-libraries with high-level functions to interact with the Sismo protocol easily.
 */

import "sismo-connect-onchain-verifier/src/libs/sismo-connect/SismoConnectLib.sol";

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
pragma solidity ^0.8.17;

import {RequestBuilder, SismoConnectRequest, SismoConnectResponse, SismoConnectConfig} from "../utils/RequestBuilder.sol";
import {AuthRequestBuilder, AuthRequest, Auth, VerifiedAuth, AuthType} from "../utils/AuthRequestBuilder.sol";
import {ClaimRequestBuilder, ClaimRequest, Claim, VerifiedClaim, ClaimType} from "../utils/ClaimRequestBuilder.sol";
import {SignatureBuilder, SignatureRequest, Signature} from "../utils/SignatureBuilder.sol";
import {VaultConfig} from "../utils/Structs.sol";
import {ISismoConnectVerifier, SismoConnectVerifiedResult} from "../../interfaces/ISismoConnectVerifier.sol";
import {IAddressesProvider} from "../../periphery/interfaces/IAddressesProvider.sol";
import {SismoConnectHelper} from "../utils/SismoConnectHelper.sol";
import {IHydraS3Verifier} from "../../verifiers/IHydraS3Verifier.sol";

contract SismoConnect {
  uint256 public constant SISMO_CONNECT_LIB_VERSION = 2;

  IAddressesProvider public constant ADDRESSES_PROVIDER_V2 =
    IAddressesProvider(0x3Cd5334eB64ebBd4003b72022CC25465f1BFcEe6);

  ISismoConnectVerifier internal _sismoConnectVerifier;

  // external libraries
  AuthRequestBuilder internal _authRequestBuilder;
  ClaimRequestBuilder internal _claimRequestBuilder;
  SignatureBuilder internal _signatureBuilder;
  RequestBuilder internal _requestBuilder;

  SismoConnectConfig public config;

  constructor(SismoConnectConfig memory _config) {
    config = _config;
    _sismoConnectVerifier = ISismoConnectVerifier(
      ADDRESSES_PROVIDER_V2.get(string("sismoConnectVerifier-v1.1"))
    );
    // external libraries
    _authRequestBuilder = AuthRequestBuilder(
      ADDRESSES_PROVIDER_V2.get(string("authRequestBuilder-v1.1"))
    );
    _claimRequestBuilder = ClaimRequestBuilder(
      ADDRESSES_PROVIDER_V2.get(string("claimRequestBuilder-v1.1"))
    );
    _signatureBuilder = SignatureBuilder(
      ADDRESSES_PROVIDER_V2.get(string("signatureBuilder-v1.1"))
    );
    _requestBuilder = RequestBuilder(ADDRESSES_PROVIDER_V2.get(string("requestBuilder-v1.1")));
  }

  function buildConfig(bytes16 appId) internal pure returns (SismoConnectConfig memory) {
    return SismoConnectConfig({appId: appId, vault: buildVaultConfig()});
  }

  function buildConfig(
    bytes16 appId,
    bool isImpersonationMode
  ) internal pure returns (SismoConnectConfig memory) {
    return SismoConnectConfig({appId: appId, vault: buildVaultConfig(isImpersonationMode)});
  }

  function buildVaultConfig() internal pure returns (VaultConfig memory) {
    return VaultConfig({isImpersonationMode: false});
  }

  function buildVaultConfig(bool isImpersonationMode) internal pure returns (VaultConfig memory) {
    return VaultConfig({isImpersonationMode: isImpersonationMode});
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, signature);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, signature);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, signature);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    SismoConnectRequest memory request
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, namespace);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, signature);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, signature);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, signature);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims);
    return _sismoConnectVerifier.verify(response, request, config);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, claimType, extraData);
  }

  function buildClaim(bytes16 groupId) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp);
  }

  function buildClaim(bytes16 groupId, uint256 value) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value);
  }

  function buildClaim(
    bytes16 groupId,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, claimType, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, claimType, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, claimType, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, claimType, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return
      _claimRequestBuilder.build(groupId, groupTimestamp, value, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return
      _claimRequestBuilder.build(
        groupId,
        groupTimestamp,
        claimType,
        isOptional,
        isSelectableByUser
      );
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, claimType, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return
      _claimRequestBuilder.build(
        groupId,
        groupTimestamp,
        value,
        claimType,
        isOptional,
        isSelectableByUser
      );
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, userId, extraData);
  }

  function buildAuth(AuthType authType) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType);
  }

  function buildAuth(AuthType authType, bool isAnon) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon);
  }

  function buildAuth(AuthType authType, uint256 userId) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, userId);
  }

  function buildAuth(
    AuthType authType,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, extraData);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    uint256 userId
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, userId);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, extraData);
  }

  function buildAuth(
    AuthType authType,
    uint256 userId,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, userId, extraData);
  }

  function buildAuth(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isOptional, isSelectableByUser);
  }

  function buildAuth(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser,
    uint256 userId
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isOptional, isSelectableByUser, userId);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, isOptional, isSelectableByUser);
  }

  function buildAuth(
    AuthType authType,
    uint256 userId,
    bool isOptional
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, userId, isOptional);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, userId, isOptional);
  }

  function buildSignature(bytes memory message) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message);
  }

  function buildSignature(
    bytes memory message,
    bool isSelectableByUser
  ) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, isSelectableByUser);
  }

  function buildSignature(
    bytes memory message,
    bytes memory extraData
  ) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, extraData);
  }

  function buildSignature(
    bytes memory message,
    bool isSelectableByUser,
    bytes memory extraData
  ) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, isSelectableByUser, extraData);
  }

  function buildSignature(bool isSelectableByUser) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(isSelectableByUser);
  }

  function buildSignature(
    bool isSelectableByUser,
    bytes memory extraData
  ) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(isSelectableByUser, extraData);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, signature);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, signature);
  }

  function buildRequest(
    AuthRequest memory auth,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, signature);
  }

  function buildRequest(
    ClaimRequest memory claim
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest memory auth
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, signature, namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, signature, namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, signature, namespace);
  }

  function buildRequest(
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, signature);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, signature);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, signature);
  }

  function buildRequest(
    ClaimRequest[] memory claims
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest[] memory auths
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, signature, namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, signature, namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, signature, namespace);
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function _GET_EMPTY_SIGNATURE_REQUEST() internal view returns (SignatureRequest memory) {
    return _signatureBuilder.buildEmpty();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";
import {SignatureBuilder} from "./SignatureBuilder.sol";

contract RequestBuilder {
  // default value for namespace
  bytes16 public constant DEFAULT_NAMESPACE = bytes16(keccak256("main"));
  // default value for a signature request
  SignatureRequest DEFAULT_SIGNATURE_REQUEST =
    SignatureRequest({
      message: "MESSAGE_SELECTED_BY_USER",
      isSelectableByUser: false,
      extraData: ""
    });

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(AuthRequest memory auth) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(ClaimRequest memory claim) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  // build with arrays for auths and claims
  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims
  ) external view returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(AuthRequest[] memory auths) external view returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(ClaimRequest[] memory claims) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract AuthRequestBuilder {
  // default values for Auth Request
  bool public constant DEFAULT_AUTH_REQUEST_IS_ANON = false;
  uint256 public constant DEFAULT_AUTH_REQUEST_USER_ID = 0;
  bool public constant DEFAULT_AUTH_REQUEST_IS_OPTIONAL = false;
  bytes public constant DEFAULT_AUTH_REQUEST_EXTRA_DATA = "";

  error InvalidUserIdAndIsSelectableByUserAuthType();
  error InvalidUserIdAndAuthType();

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(AuthType authType) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(AuthType authType, bool isAnon) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(AuthType authType, uint256 userId) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    uint256 userId,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  // allow dev to choose for isOptional
  // the user is ask to choose isSelectableByUser to avoid the function signature collision
  // between build(AuthType authType, bool isOptional) and build(AuthType authType, bool isAnon)

  function build(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser,
    uint256 userId
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  // the user is ask to choose isSelectableByUser to avoid the function signature collision
  // between build(AuthType authType, bool isAnon, bool isOptional) and build(AuthType authType, bool isOptional, bool isSelectableByUser)

  function build(
    AuthType authType,
    bool isAnon,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    uint256 userId,
    bool isOptional
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: isOptional,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function _build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bytes memory extraData
  ) internal pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: _authIsSelectableDefaultValue(authType, userId),
        extraData: extraData
      });
  }

  function _build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bool isSelectableByUser,
    bytes memory extraData
  ) internal pure returns (AuthRequest memory) {
    // When `userId` is 0, it means the app does not require a specific auth account and the user needs
    // to choose the account they want to use for the app.
    // When `isSelectableByUser` is true, the user can select the account they want to use.
    // The combination of `userId = 0` and `isSelectableByUser = false` does not make sense and should not be used.
    // If this combination is detected, the function will revert with an error.
    if (authType != AuthType.VAULT && userId == 0 && isSelectableByUser == false) {
      revert InvalidUserIdAndIsSelectableByUserAuthType();
    }
    // When requesting an authType VAULT, the `userId` must be 0 and isSelectableByUser must be true.
    if (authType == AuthType.VAULT && userId != 0 && isSelectableByUser == false) {
      revert InvalidUserIdAndAuthType();
    }
    return
      AuthRequest({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function _authIsSelectableDefaultValue(
    AuthType authType,
    uint256 requestedUserId
  ) internal pure returns (bool) {
    // isSelectableByUser value should always be false in case of VAULT authType.
    // This is because the user can't select the account they want to use for the app.
    // the userId = Hash(VaultSecret, AppId) in the case of VAULT authType.
    if (authType == AuthType.VAULT) {
      return false;
    }
    // When `requestedUserId` is 0, it means no specific auth account is requested by the app,
    // so we want the default value for `isSelectableByUser` to be `true`.
    if (requestedUserId == 0) {
      return true;
    }
    // When `requestedUserId` is not 0, it means a specific auth account is requested by the app,
    // so we want the default value for `isSelectableByUser` to be `false`.
    else {
      return false;
    }
    // However, the dev can still override this default value by setting `isSelectableByUser` to `true`.
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract ClaimRequestBuilder {
  // default value for Claim Request
  bytes16 public constant DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP = bytes16("latest");
  uint256 public constant DEFAULT_CLAIM_REQUEST_VALUE = 1;
  ClaimType public constant DEFAULT_CLAIM_REQUEST_TYPE = ClaimType.GTE;
  bool public constant DEFAULT_CLAIM_REQUEST_IS_OPTIONAL = false;
  bool public constant DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER = true;
  bytes public constant DEFAULT_CLAIM_REQUEST_EXTRA_DATA = "";

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        claimType: claimType,
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        claimType: claimType,
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(bytes16 groupId) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(bytes16 groupId, uint256 value) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(bytes16 groupId, ClaimType claimType) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  // allow dev to choose for isOptional
  // we force to also set isSelectableByUser
  // otherwise function signatures would be colliding
  // between build(bytes16 groupId, bool isOptional) and build(bytes16 groupId, bool isSelectableByUser)
  // we keep this logic for all function signature combinations

  function build(
    bytes16 groupId,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract SignatureBuilder {
  // default values for Signature Request
  bytes public constant DEFAULT_SIGNATURE_REQUEST_MESSAGE = "MESSAGE_SELECTED_BY_USER";
  bool public constant DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER = false;
  bytes public constant DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA = "";

  function build(bytes memory message) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes memory message,
    bool isSelectableByUser
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes memory message,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes memory message,
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function build(bool isSelectableByUser) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function buildEmpty() external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct SismoConnectRequest {
  bytes16 namespace;
  AuthRequest[] auths;
  ClaimRequest[] claims;
  SignatureRequest signature;
}

struct SismoConnectConfig {
  bytes16 appId;
  VaultConfig vault;
}

struct VaultConfig {
  bool isImpersonationMode;
}

struct AuthRequest {
  AuthType authType;
  uint256 userId; // default: 0
  // flags
  bool isAnon; // default: false -> true not supported yet, need to throw if true
  bool isOptional; // default: false
  bool isSelectableByUser; // default: true
  //
  bytes extraData; // default: ""
}

struct ClaimRequest {
  ClaimType claimType; // default: GTE
  bytes16 groupId;
  bytes16 groupTimestamp; // default: bytes16("latest")
  uint256 value; // default: 1
  // flags
  bool isOptional; // default: false
  bool isSelectableByUser; // default: true
  //
  bytes extraData; // default: ""
}

struct SignatureRequest {
  bytes message; // default: "MESSAGE_SELECTED_BY_USER"
  bool isSelectableByUser; // default: false
  bytes extraData; // default: ""
}

enum AuthType {
  VAULT,
  GITHUB,
  TWITTER,
  EVM_ACCOUNT,
  TELEGRAM,
  DISCORD
}

enum ClaimType {
  GTE,
  GT,
  EQ,
  LT,
  LTE
}

struct Auth {
  AuthType authType;
  bool isAnon;
  bool isSelectableByUser;
  uint256 userId;
  bytes extraData;
}

struct Claim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  bool isSelectableByUser;
  uint256 value;
  bytes extraData;
}

struct Signature {
  bytes message;
  bytes extraData;
}

struct SismoConnectResponse {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  bytes signedMessage;
  SismoConnectProof[] proofs;
}

struct SismoConnectProof {
  Auth[] auths;
  Claim[] claims;
  bytes32 provingScheme;
  bytes proofData;
  bytes extraData;
}

struct SismoConnectVerifiedResult {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  VerifiedAuth[] auths;
  VerifiedClaim[] claims;
  bytes signedMessage;
}

struct VerifiedAuth {
  AuthType authType;
  bool isAnon;
  uint256 userId;
  bytes extraData;
  bytes proofData;
}

struct VerifiedClaim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  uint256 value;
  bytes extraData;
  uint256 proofId;
  bytes proofData;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libs/utils/Structs.sol";

interface ISismoConnectVerifier {
  event VerifierSet(bytes32, address);

  error AppIdMismatch(bytes16 receivedAppId, bytes16 expectedAppId);
  error NamespaceMismatch(bytes16 receivedNamespace, bytes16 expectedNamespace);
  error VersionMismatch(bytes32 requestVersion, bytes32 responseVersion);
  error SignatureMessageMismatch(bytes requestMessageSignature, bytes responseMessageSignature);

  function verify(
    SismoConnectResponse memory response,
    SismoConnectRequest memory request,
    SismoConnectConfig memory config
  ) external returns (SismoConnectVerifiedResult memory);

  function SISMO_CONNECT_VERSION() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAddressesProvider {
  /**
   * @dev Sets the address of a contract.
   * @param contractAddress Address of the contract.
   * @param contractName Name of the contract.
   */
  function set(address contractAddress, string memory contractName) external;

  /**
   * @dev Sets the address of multiple contracts.
   * @param contractAddresses Addresses of the contracts.
   * @param contractNames Names of the contracts.
   */
  function setBatch(address[] calldata contractAddresses, string[] calldata contractNames) external;

  /**
   * @dev Returns the address of a contract.
   * @param contractName Name of the contract (string).
   * @return Address of the contract.
   */
  function get(string memory contractName) external view returns (address);

  /**
   * @dev Returns the address of a contract.
   * @param contractNameHash Hash of the name of the contract (bytes32).
   * @return Address of the contract.
   */
  function get(bytes32 contractNameHash) external view returns (address);

  /**
   * @dev Returns the addresses of all contracts inputed.
   * @param contractNames Names of the contracts as strings.
   */
  function getBatch(string[] calldata contractNames) external view returns (address[] memory);

  /**
   * @dev Returns the addresses of all contracts inputed.
   * @param contractNamesHash Names of the contracts as strings.
   */
  function getBatch(bytes32[] calldata contractNamesHash) external view returns (address[] memory);

  /**
   * @dev Returns the addresses of all contracts in `_contractNames`
   * @return Names, Hashed Names and Addresses of all contracts.
   */
  function getAll() external view returns (string[] memory, bytes32[] memory, address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

library SismoConnectHelper {
  error AuthTypeNotFoundInVerifiedResult(AuthType authType);

  function getUserId(
    SismoConnectVerifiedResult memory result,
    AuthType authType
  ) internal pure returns (uint256) {
    // get the first userId that matches the authType
    for (uint256 i = 0; i < result.auths.length; i++) {
      if (result.auths[i].authType == authType) {
        return result.auths[i].userId;
      }
    }
    revert AuthTypeNotFoundInVerifiedResult(authType);
  }

  function getUserIds(
    SismoConnectVerifiedResult memory result,
    AuthType authType
  ) internal pure returns (uint256[] memory) {
    // get all userIds that match the authType
    uint256[] memory userIds = new uint256[](result.auths.length);
    for (uint256 i = 0; i < result.auths.length; i++) {
      if (result.auths[i].authType == authType) {
        userIds[i] = result.auths[i].userId;
      }
    }
    return userIds;
  }

  function getSignedMessage(
    SismoConnectVerifiedResult memory result
  ) internal pure returns (bytes memory) {
    return result.signedMessage;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract IHydraS3Verifier {
  error InvalidProof();
  error CallToVerifyProofFailed();
  error InvalidSismoIdentifier(bytes32 userId, uint8 authType);
  error OnlyOneAuthAndOneClaimIsSupported();

  error InvalidVersion(bytes32 version);
  error RegistryRootNotAvailable(uint256 inputRoot);
  error DestinationMismatch(address destinationFromProof, address expectedDestination);
  error CommitmentMapperPubKeyMismatch(
    bytes32 expectedX,
    bytes32 expectedY,
    bytes32 inputX,
    bytes32 inputY
  );

  error ClaimTypeMismatch(uint256 claimTypeFromProof, uint256 expectedClaimType);
  error RequestIdentifierMismatch(
    uint256 requestIdentifierFromProof,
    uint256 expectedRequestIdentifier
  );
  error InvalidExtraData(uint256 extraDataFromProof, uint256 expectedExtraData);
  error ClaimValueMismatch();
  error DestinationVerificationNotEnabled();
  error SourceVerificationNotEnabled();
  error AccountsTreeValueMismatch(
    uint256 accountsTreeValueFromProof,
    uint256 expectedAccountsTreeValue
  );
  error VaultNamespaceMismatch(uint256 vaultNamespaceFromProof, uint256 expectedVaultNamespace);
  error UserIdMismatch(uint256 userIdFromProof, uint256 expectedUserId);
}