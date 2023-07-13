// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./DefaultGovernanceUpgradeable.sol";

contract DefaultToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, DefaultGovernanceUpgradeable, UUPSUpgradeable {
    /**
     * @dev Variable to store number of decimal places to make deployment dynamic.
    */
    uint8 private _decimals;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializing parent contracts.
    */
    function initialize(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimal) initializer public {
        _decimals = tokenDecimal;

        __ERC20_init(tokenName, tokenSymbol);
        __ERC20Burnable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __DefaultGovernance_init();
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `to` cannot be on the denied list.
     * - The caller must have `MINTER_ROLE`.
    */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) verifyDeniedAddress(to) {
        _mint(to, amount);
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
     * - `spender` cannot be on the denied list.
     * - The caller cannot be on the denied list.
    */
    function approve(address spender, uint256 amount)
        public
        override
        verifyDeniedAddress(_msgSender())
        verifyDeniedAddress(spender)
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `to` cannot be on the denied list.
     * - The caller must have a balance of at least `amount`.
     * - The caller cannot be on the denied list.
    */
    function transfer(address to, uint256 amount) public override
        verifyDeniedAddress(to)
        verifyDeniedAddress(_msgSender())
        returns (bool)
    {
        return super.transfer(to, amount);
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
     * - `from` and `to` cannot be on the denied list.
     * - `from` must have a balance of at least `amount`.
     * - The caller must have allowance for ``from``'s tokens of at least `amount`.
     * - The caller cannot be on the denied list.
    */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public
      override
      verifyDeniedAddress(from)
      verifyDeniedAddress(to)
      verifyDeniedAddress(_msgSender())
      returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     *
     * Requirements:
     *
     *  - `from` cannot be on the denied list.
     *  - `to` cannot be on the denied list.
     *  - The contract must not be paused.
     *
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract.
    */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    /**
     * @dev Returns the number of decimals used to get its user representation.
    */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     *
     * * Requirements:
     *
     *  - The caller must have `BURNER_ROLE`.
     *  - The caller cannot be on the denied list.
    */
    function burn(uint256 amount) public override onlyRole(BURNER_ROLE) {
        super.burn(amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     *  - The caller must have allowance for ``accounts``'s tokens of at least `amount` or the `account` has denied.
     *  - The caller must have `BURNER_ROLE`.
     */
    function burnFrom(address account, uint256 amount) public override onlyRole(BURNER_ROLE) {
        if (hasDenied(account)) {
            _burn(account, amount);
            return;
        }
        super.burnFrom(account, amount);
    }

    /**
     * @dev Add account to denied list.
     *
     * Requirements:
     *
     * - The caller must have `DENIER_ROLE`.
     *
     * May emit a {AddressAddedToDeniedList} event.
    */
    function addToDeniedList(address account) public override onlyRole(DENIER_ROLE) {
        super.addToDeniedList(account);
    }

    /**
     * @dev Remove account to denied list.
     *
     * Requirements:
     *
     * - The caller must have `DENIER_ROLE`.
     *
     * May emit a {AddressRemovedFromDeniedList} event.
    */
    function removeFromDeniedList(address account) public override onlyRole(DENIER_ROLE) {
        super.removeFromDeniedList(account);
    }
}