//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

import "./ACLManager.sol";
import "./TheSpaceRegistry.sol";
import "./ITheSpaceRegistry.sol";
import "./ITheSpace.sol";

contract TheSpace is ITheSpace, ERC2771Recipient, Multicall, ReentrancyGuard, ACLManager {
    TheSpaceRegistry public registry;

    // token image shared by all tokens
    string public tokenImageURI = "ipfs://";

    constructor(
        address currencyAddress_,
        address registryAddress_,
        string memory tokenImageURI_,
        address aclManager_,
        address marketAdmin_,
        address treasuryAdmin_,
        address trustedForwarder_
    ) ACLManager(aclManager_, marketAdmin_, treasuryAdmin_) {
        // deploy logic contract only and upgrade later
        if (registryAddress_ != address(0)) {
            registry = TheSpaceRegistry(registryAddress_);
        }
        // deploy logic and registry contracts
        else {
            registry = new TheSpaceRegistry(
                "Planck", // property name
                "PLK", // property symbol
                1000000, // total supply
                12, // taxRate
                0, // treasuryShare
                1 * (10**uint256(ERC20(currencyAddress_).decimals())), // mintTax, 1 $SPACE
                currencyAddress_
            );
        }

        tokenImageURI = tokenImageURI_;

        _setTrustedForwarder(trustedForwarder_);
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId_) external view virtual returns (bool) {
        return interfaceId_ == type(ITheSpace).interfaceId;
    }

    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    /// @inheritdoc ITheSpace
    function upgradeTo(address newImplementation) external onlyRole(Role.aclManager) {
        registry.transferOwnership(newImplementation);
    }

    //////////////////////////////
    /// Configuration / Admin
    //////////////////////////////

    function setTotalSupply(uint256 totalSupply_) external onlyRole(Role.marketAdmin) {
        registry.setTotalSupply(totalSupply_);
    }

    /// @inheritdoc ITheSpace
    function setTaxConfig(ITheSpaceRegistry.ConfigOptions option_, uint256 value_) external onlyRole(Role.marketAdmin) {
        registry.setTaxConfig(option_, value_);
    }

    /// @inheritdoc ITheSpace
    function withdrawTreasury(address to_) external onlyRole(Role.treasuryAdmin) {
        (uint256 accumulatedUBI, uint256 accumulatedTreasury, uint256 treasuryWithdrawn) = registry.treasuryRecord();

        // calculate available amount and transfer
        uint256 amount = accumulatedTreasury - treasuryWithdrawn;
        registry.transferCurrency(to_, amount);
        registry.emitTreasury(to_, amount);

        // set `treasuryWithdrawn` to `accumulatedTreasury`
        registry.setTreasuryRecord(accumulatedUBI, accumulatedTreasury, accumulatedTreasury);
    }

    /// @inheritdoc ITheSpace
    function setTokenImageURI(string memory uri_) external onlyRole(Role.aclManager) {
        tokenImageURI = uri_;
    }

    /// @inheritdoc ITheSpace
    function setTrustedForwarder(address trustedForwarder_) external onlyRole(Role.aclManager) {
        _setTrustedForwarder(trustedForwarder_);
    }

    //////////////////////////////
    /// Pixel
    //////////////////////////////

    /// @inheritdoc ITheSpace
    function getPixel(uint256 tokenId_) external view returns (ITheSpaceRegistry.Pixel memory pixel) {
        return _getPixel(tokenId_);
    }

    function _getPixel(uint256 tokenId_) internal view returns (ITheSpaceRegistry.Pixel memory pixel) {
        (, uint256 lastTaxCollection, ) = registry.tokenRecord(tokenId_);

        pixel = ITheSpaceRegistry.Pixel(
            tokenId_,
            getPrice(tokenId_),
            lastTaxCollection,
            ubiAvailable(tokenId_),
            getOwner(tokenId_),
            registry.pixelColor(tokenId_)
        );
    }

    /// @inheritdoc ITheSpace
    function setPixel(
        uint256 tokenId_,
        uint256 bidPrice_,
        uint256 newPrice_,
        uint256 color_
    ) external {
        bid(tokenId_, bidPrice_);
        setPrice(tokenId_, newPrice_);
        _setColor(tokenId_, color_, _msgSender());
    }

    /// @inheritdoc ITheSpace
    function setColor(uint256 tokenId_, uint256 color_) public {
        if (!registry.isApprovedOrOwner(_msgSender(), tokenId_)) revert Unauthorized();

        _setColor(tokenId_, color_, registry.ownerOf(tokenId_));
    }

    function _setColor(
        uint256 tokenId_,
        uint256 color_,
        address owner_
    ) internal {
        if (registry.pixelColor(tokenId_) == color_) return;

        registry.setColor(tokenId_, color_, owner_);
    }

    /// @inheritdoc ITheSpace
    function getColor(uint256 tokenId) public view returns (uint256 color) {
        color = registry.pixelColor(tokenId);
    }

    /// @inheritdoc ITheSpace
    function getPixelsByOwner(
        address owner_,
        uint256 limit_,
        uint256 offset_
    )
        external
        view
        returns (
            uint256 total,
            uint256 limit,
            uint256 offset,
            ITheSpaceRegistry.Pixel[] memory pixels
        )
    {
        uint256 _total = registry.balanceOf(owner_);
        if (limit_ == 0) {
            return (_total, limit_, offset_, new ITheSpaceRegistry.Pixel[](0));
        }

        if (offset_ >= _total) {
            return (_total, limit_, offset_, new ITheSpaceRegistry.Pixel[](0));
        }
        uint256 left = _total - offset_;
        uint256 size = left > limit_ ? limit_ : left;

        ITheSpaceRegistry.Pixel[] memory _pixels = new ITheSpaceRegistry.Pixel[](size);

        for (uint256 i = 0; i < size; i++) {
            uint256 tokenId = registry.tokenOfOwnerByIndex(owner_, i + offset_);
            _pixels[i] = _getPixel(tokenId);
        }

        return (_total, limit_, offset_, _pixels);
    }

    //////////////////////////////
    /// Trading
    //////////////////////////////

    /// @inheritdoc ITheSpace
    function getPrice(uint256 tokenId_) public view returns (uint256 price) {
        return
            registry.exists(tokenId_)
                ? _getPrice(tokenId_)
                : registry.taxConfig(ITheSpaceRegistry.ConfigOptions.mintTax);
    }

    function _getPrice(uint256 tokenId_) internal view returns (uint256) {
        (uint256 price, , ) = registry.tokenRecord(tokenId_);
        return price;
    }

    /// @inheritdoc ITheSpace
    function setPrice(uint256 tokenId_, uint256 price_) public {
        if (!(registry.isApprovedOrOwner(_msgSender(), tokenId_))) revert Unauthorized();
        if (price_ == _getPrice(tokenId_)) return;

        bool success = settleTax(tokenId_);
        if (success) _setPrice(tokenId_, price_);
    }

    /**
     * @dev Internal function to set price without checking
     */
    function _setPrice(uint256 tokenId_, uint256 price_) private {
        _setPrice(tokenId_, price_, registry.ownerOf(tokenId_));
    }

    function _setPrice(
        uint256 tokenId_,
        uint256 price_,
        address operator_
    ) private {
        // max price to prevent overflow of `_getTax`
        uint256 maxPrice = registry.currency().totalSupply();
        if (price_ > maxPrice) revert PriceTooHigh(maxPrice);

        (, , uint256 ubiWithdrawn) = registry.tokenRecord(tokenId_);

        registry.setTokenRecord(tokenId_, price_, block.number, ubiWithdrawn);
        registry.emitPrice(tokenId_, price_, operator_);
    }

    /// @inheritdoc ITheSpace
    function getOwner(uint256 tokenId_) public view returns (address owner) {
        return registry.exists(tokenId_) ? registry.ownerOf(tokenId_) : address(0);
    }

    /// @inheritdoc ITheSpace
    function bid(uint256 tokenId_, uint256 price_) public nonReentrant {
        address owner = getOwner(tokenId_);
        uint256 askPrice = _getPrice(tokenId_);
        uint256 mintTax = registry.taxConfig(ITheSpaceRegistry.ConfigOptions.mintTax);

        // bid price and payee is calculated based on tax and token status
        uint256 bidPrice;

        if (registry.exists(tokenId_)) {
            // skip if already own
            if (owner == _msgSender()) return;

            // clear tax
            bool success = _collectTax(tokenId_);

            // proceed with transfer
            if (success) {
                // if tax fully paid, owner get paid normally
                bidPrice = askPrice;

                // revert if price too low
                if (price_ < bidPrice) revert PriceTooLow();

                // settle ERC20 token
                registry.transferCurrencyFrom(_msgSender(), owner, bidPrice);

                // settle ERC721 token
                registry.safeTransferByMarket(owner, _msgSender(), tokenId_);

                // emit deal event
                registry.emitDeal(tokenId_, owner, _msgSender(), bidPrice);

                return;
            } else {
                // if tax not fully paid, token is treated as defaulted and mint tax is collected and recorded
                registry.burn(tokenId_);
            }
        }

        // mint tax is collected and recorded
        bidPrice = mintTax;

        // revert if price too low
        if (price_ < bidPrice) revert PriceTooLow();

        // settle ERC20 token
        registry.transferCurrencyFrom(_msgSender(), address(registry), bidPrice);

        // record as tax income
        _recordTax(tokenId_, _msgSender(), mintTax);

        // settle ERC721 token
        registry.mint(_msgSender(), tokenId_);

        // emit deal event
        registry.emitDeal(tokenId_, address(0), _msgSender(), bidPrice);
    }

    //////////////////////////////
    /// Tax & UBI
    //////////////////////////////

    /// @inheritdoc ITheSpace
    function getTax(uint256 tokenId_) public view returns (uint256) {
        if (!registry.exists(tokenId_)) revert TokenNotExists();

        return _getTax(tokenId_);
    }

    function _getTax(uint256 tokenId_) internal view returns (uint256) {
        (uint256 price, uint256 lastTaxCollection, ) = registry.tokenRecord(tokenId_);

        if (price == 0) return 0;

        uint256 taxRate = registry.taxConfig(ITheSpaceRegistry.ConfigOptions.taxRate);

        // `1000` for every `1000` blocks, `10000` for conversion from bps
        return ((price * taxRate * (block.number - lastTaxCollection)) / (1000 * 10000));
    }

    /// @inheritdoc ITheSpace
    function evaluateOwnership(uint256 tokenId_) public view returns (uint256 collectable, bool shouldDefault) {
        uint256 tax = getTax(tokenId_);

        if (tax > 0) {
            // calculate collectable amount
            address taxpayer = registry.ownerOf(tokenId_);
            uint256 allowance = registry.currency().allowance(taxpayer, address(registry));
            uint256 balance = registry.currency().balanceOf(taxpayer);
            uint256 available = allowance < balance ? allowance : balance;

            if (available >= tax) {
                // can pay tax fully and do not need to be defaulted
                return (tax, false);
            } else {
                // cannot pay tax fully and need to be defaulted
                return (available, true);
            }
        } else {
            // not tax needed
            return (0, false);
        }
    }

    /**
     * @notice Collect outstanding tax for a given token, put token on tax sale if obligation not met.
     * @dev Emits a {Tax} event
     * @dev Emits a {Price} event (when properties are put on tax sale).
     */
    function _collectTax(uint256 tokenId_) private returns (bool success) {
        (uint256 collectable, bool shouldDefault) = evaluateOwnership(tokenId_);

        if (collectable > 0) {
            // collect and record tax
            address owner = registry.ownerOf(tokenId_);
            registry.transferCurrencyFrom(owner, address(registry), collectable);
            _recordTax(tokenId_, owner, collectable);
        }

        return !shouldDefault;
    }

    /**
     * @notice Update tax record and emit Tax event.
     */
    function _recordTax(
        uint256 tokenId_,
        address taxpayer_,
        uint256 amount_
    ) private {
        // calculate treasury change
        uint256 treasuryShare = registry.taxConfig(ITheSpaceRegistry.ConfigOptions.treasuryShare);
        uint256 treasuryAdded = (amount_ * treasuryShare) / 10000;

        // set treasury record
        (uint256 accumulatedUBI, uint256 accumulatedTreasury, uint256 treasuryWithdrawn) = registry.treasuryRecord();
        registry.setTreasuryRecord(
            accumulatedUBI + (amount_ - treasuryAdded),
            accumulatedTreasury + treasuryAdded,
            treasuryWithdrawn
        );

        // update lastTaxCollection and emit tax event
        (uint256 price, , uint256 ubiWithdrawn) = registry.tokenRecord(tokenId_);
        registry.setTokenRecord(tokenId_, price, block.number, ubiWithdrawn);
        registry.emitTax(tokenId_, taxpayer_, amount_);
    }

    /// @inheritdoc ITheSpace
    function settleTax(uint256 tokenId_) public returns (bool success) {
        success = _collectTax(tokenId_);
        if (!success) registry.burn(tokenId_);
    }

    /// @inheritdoc ITheSpace
    function ubiAvailable(uint256 tokenId_) public view returns (uint256) {
        (uint256 accumulatedUBI, , ) = registry.treasuryRecord();
        (, , uint256 ubiWithdrawn) = registry.tokenRecord(tokenId_);

        return accumulatedUBI / registry.totalSupply() - ubiWithdrawn;
    }

    /// @inheritdoc ITheSpace
    function withdrawUbi(uint256 tokenId_) external {
        uint256 amount = ubiAvailable(tokenId_);

        if (amount > 0) {
            // transfer
            address recipient = registry.ownerOf(tokenId_);
            registry.transferCurrency(recipient, amount);

            // record
            (uint256 price, uint256 lastTaxCollection, uint256 ubiWithdrawn) = registry.tokenRecord(tokenId_);
            registry.setTokenRecord(tokenId_, price, lastTaxCollection, ubiWithdrawn + amount);

            // emit event
            registry.emitUBI(tokenId_, recipient, amount);
        }
    }

    //////////////////////////////
    /// Registry backcall
    //////////////////////////////

    /// @inheritdoc ITheSpace
    function _beforeTransferByRegistry(uint256 tokenId_) external returns (bool success) {
        if (_msgSender() != address(registry)) revert Unauthorized();

        // clear tax or default
        settleTax(tokenId_);

        // proceed with transfer if tax settled
        if (registry.exists(tokenId_)) {
            // transfer is regarded as setting price to 0, then bid for free
            // this is to prevent transferring huge tax obligation as a form of attack
            _setPrice(tokenId_, 0);

            success = true;
        } else {
            success = false;
        }
    }

    /// @inheritdoc ITheSpace
    function _tokenURI(uint256 tokenId_) external view returns (string memory uri) {
        if (_msgSender() != address(registry)) revert Unauthorized();

        if (!registry.exists(tokenId_)) revert TokenNotExists();

        string memory tokenName = string(abi.encodePacked("Planck #", Strings.toString(tokenId_)));
        string memory description = "One of 1 million pixels traded under Harberger Tax and UBI.";

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        tokenName,
                        '", "description": "',
                        description,
                        '", "attributes": [',
                        '], "image": "',
                        tokenImageURI,
                        '"}'
                    )
                )
            )
        );

        uri = string(abi.encodePacked("data:application/json;base64,", json));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
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
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import "./IACLManager.sol";

contract ACLManager is IACLManager {
    mapping(Role => address) private _roles;

    constructor(
        address aclManager_,
        address marketAdmin_,
        address treasuryAdmin_
    ) {
        if (aclManager_ == address(0)) revert ZeroAddress();

        _transferRole(Role.aclManager, aclManager_);
        _transferRole(Role.marketAdmin, marketAdmin_);
        _transferRole(Role.treasuryAdmin, treasuryAdmin_);
    }

    /**
     * @dev Throws if called by any address other than the role address.
     */
    modifier onlyRole(Role role) {
        if (!_hasRole(role, msg.sender)) revert RoleRequired(role);
        _;
    }

    /// @inheritdoc IACLManager
    function hasRole(Role role, address account) public view returns (bool) {
        return _hasRole(role, account);
    }

    function _hasRole(Role role, address account) internal view returns (bool) {
        return _roles[role] == account;
    }

    /// @inheritdoc IACLManager
    function grantRole(Role role, address newAccount) public virtual onlyRole(Role.aclManager) {
        if (role == Role.aclManager) revert Forbidden();
        if (newAccount == address(0)) revert ZeroAddress();

        _transferRole(role, newAccount);
    }

    /// @inheritdoc IACLManager
    function transferRole(Role role, address newAccount) public virtual onlyRole(role) {
        if (newAccount == address(0)) revert ZeroAddress();

        _transferRole(role, newAccount);
    }

    /// @inheritdoc IACLManager
    function renounceRole(Role role) public virtual onlyRole(role) {
        if (role == Role.aclManager) revert Forbidden();

        _transferRole(role, address(0));
    }

    /**
     * @dev Transfers role to a new account (`newAccount`).
     * Internal function without access restriction.
     */
    function _transferRole(Role role, address newAccount) internal virtual {
        address oldAccount = _roles[role];
        _roles[role] = newAccount;
        emit RoleTransferred(role, oldAccount, newAccount);
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITheSpace.sol";
import "./ITheSpaceRegistry.sol";

contract TheSpaceRegistry is ITheSpaceRegistry, ERC721Enumerable, Ownable {
    /**
     * @dev Total possible number of ERC721 token
     */
    uint256 private _totalSupply;

    /**
     * @dev ERC20 token used as currency
     */
    ERC20 public immutable currency;

    /**
     * @dev Record for all tokens (tokenId => TokenRecord).
     */
    mapping(uint256 => TokenRecord) public tokenRecord;

    /**
     * @dev Color of each token.
     */
    mapping(uint256 => uint256) public pixelColor;

    /**
     * @dev Tax configuration of market.
     */
    mapping(ConfigOptions => uint256) public taxConfig;

    /**
     * @dev Global state of tax and treasury.
     */
    TreasuryRecord public treasuryRecord;

    /**
     * @dev Create Property contract, setup attached currency contract, setup tax rate.
     */
    constructor(
        string memory propertyName_,
        string memory propertySymbol_,
        uint256 totalSupply_,
        uint256 taxRate_,
        uint256 treasuryShare_,
        uint256 mintTax_,
        address currencyAddress_
    ) ERC721(propertyName_, propertySymbol_) {
        // initialize total supply
        _totalSupply = totalSupply_;

        // initialize currency contract
        currency = ERC20(currencyAddress_);

        // initialize tax config
        taxConfig[ConfigOptions.taxRate] = taxRate_;
        emit Config(ConfigOptions.taxRate, taxRate_);
        taxConfig[ConfigOptions.treasuryShare] = treasuryShare_;
        emit Config(ConfigOptions.treasuryShare, treasuryShare_);
        taxConfig[ConfigOptions.mintTax] = mintTax_;
        emit Config(ConfigOptions.mintTax, mintTax_);
    }

    //////////////////////////////
    /// Getters & Setters
    //////////////////////////////

    /**
     * @notice See {IERC20-totalSupply}.
     * @dev Always return total possible amount of supply, instead of current token in circulation.
     */
    function totalSupply() public view override(ERC721Enumerable, IERC721Enumerable) returns (uint256) {
        return _totalSupply;
    }

    //////////////////////////////
    /// Setters for global variables
    //////////////////////////////

    /// @inheritdoc ITheSpaceRegistry
    function setTotalSupply(uint256 totalSupply_) external onlyOwner {
        emit TotalSupply(_totalSupply, totalSupply_);

        _totalSupply = totalSupply_;
    }

    /// @inheritdoc ITheSpaceRegistry
    function setTaxConfig(ConfigOptions option_, uint256 value_) external onlyOwner {
        taxConfig[option_] = value_;

        emit Config(option_, value_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function setTreasuryRecord(
        uint256 accumulatedUBI_,
        uint256 accumulatedTreasury_,
        uint256 treasuryWithdrawn_
    ) external onlyOwner {
        treasuryRecord = TreasuryRecord(accumulatedUBI_, accumulatedTreasury_, treasuryWithdrawn_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function setTokenRecord(
        uint256 tokenId_,
        uint256 price_,
        uint256 lastTaxCollection_,
        uint256 ubiWithdrawn_
    ) external onlyOwner {
        tokenRecord[tokenId_] = TokenRecord(price_, lastTaxCollection_, ubiWithdrawn_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function setColor(
        uint256 tokenId_,
        uint256 color_,
        address owner_
    ) external onlyOwner {
        pixelColor[tokenId_] = color_;
        emit Color(tokenId_, color_, owner_);
    }

    //////////////////////////////
    /// Event emission
    //////////////////////////////

    /// @inheritdoc ITheSpaceRegistry
    function emitTax(
        uint256 tokenId_,
        address taxpayer_,
        uint256 amount_
    ) external onlyOwner {
        emit Tax(tokenId_, taxpayer_, amount_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function emitPrice(
        uint256 tokenId_,
        uint256 price_,
        address operator_
    ) external onlyOwner {
        emit Price(tokenId_, price_, operator_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function emitUBI(
        uint256 tokenId_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        emit UBI(tokenId_, recipient_, amount_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function emitTreasury(address recipient_, uint256 amount_) external onlyOwner {
        emit Treasury(recipient_, amount_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function emitDeal(
        uint256 tokenId_,
        address from_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        emit Deal(tokenId_, from_, to_, amount_);
    }

    //////////////////////////////
    /// ERC721 property related
    //////////////////////////////

    /// @inheritdoc ITheSpaceRegistry
    function mint(address to_, uint256 tokenId_) external onlyOwner {
        if (tokenId_ > _totalSupply || tokenId_ < 1) revert InvalidTokenId(1, _totalSupply);
        _safeMint(to_, tokenId_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function burn(uint256 tokenId_) external onlyOwner {
        _burn(tokenId_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function safeTransferByMarket(
        address from_,
        address to_,
        uint256 tokenId_
    ) external onlyOwner {
        _safeTransfer(from_, to_, tokenId_, "");
    }

    /// @inheritdoc ITheSpaceRegistry
    function exists(uint256 tokenId_) external view returns (bool) {
        return _exists(tokenId_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function isApprovedOrOwner(address spender_, uint256 tokenId_) external view returns (bool) {
        return _isApprovedOrOwner(spender_, tokenId_);
    }

    /**
     * @notice See {IERC721-transferFrom}.
     * @dev Override to collect tax and set price before transfer.
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override(ERC721, IERC721) {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    /**
     * @notice See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public override(ERC721, IERC721) {
        // solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721: transfer caller is not owner nor approved");

        ITheSpace market = ITheSpace(owner());

        bool success = market._beforeTransferByRegistry(tokenId_);

        if (success) {
            _safeTransfer(from_, to_, tokenId_, data_);
        }
    }

    /**
     * @notice See {IERC721-tokenURI}.
     */
    function tokenURI(uint256 tokenId_) public view override returns (string memory uri) {
        ITheSpace market = ITheSpace(owner());

        uri = market._tokenURI(tokenId_);
    }

    //////////////////////////////
    /// ERC20 currency related
    //////////////////////////////

    /// @inheritdoc ITheSpaceRegistry
    function transferCurrency(address to_, uint256 amount_) external onlyOwner {
        currency.transfer(to_, amount_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function transferCurrencyFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        currency.transferFrom(from_, to_, amount_);
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title The interface for `TheSpaceRegistry` contract.
 * @notice Storage contract for `TheSpace` contract.
 * @dev It stores all states related to the market, and is owned by the TheSpace contract.
 * @dev The market contract can be upgraded by changing the owner of this contract to the new implementation contract.
 */
interface ITheSpaceRegistry is IERC721Enumerable {
    //////////////////////////////
    /// Error types
    //////////////////////////////

    /**
     * @notice Token id is out of range.
     * @param min Lower range of possible token id.
     * @param max Higher range of possible token id.
     */
    error InvalidTokenId(uint256 min, uint256 max);

    //////////////////////////////
    /// Event types
    //////////////////////////////

    /**
     * @notice A token updated price.
     * @param tokenId Id of token that updated price.
     * @param price New price after update.
     * @param owner Token owner during price update.
     */
    event Price(uint256 indexed tokenId, uint256 price, address indexed owner);

    /**
     * @notice Global configuration is updated.
     * @param option Field of config been updated.
     * @param value New value after update.
     */
    event Config(ConfigOptions indexed option, uint256 value);

    /**
     * @notice Total is updated.
     * @param previousSupply Total supply amount before update.
     * @param newSupply New supply amount after update.
     */
    event TotalSupply(uint256 previousSupply, uint256 newSupply);

    /**
     * @notice Tax is collected for a token.
     * @param tokenId Id of token that has been taxed.
     * @param taxpayer user address who has paid the tax.
     * @param amount Amount of tax been collected.
     */
    event Tax(uint256 indexed tokenId, address indexed taxpayer, uint256 amount);

    /**
     * @notice UBI (universal basic income) is withdrawn for a token.
     * @param tokenId Id of token that UBI has been withdrawn for.
     * @param recipient user address who got this withdrawn UBI.
     * @param amount Amount of UBI withdrawn.
     */
    event UBI(uint256 indexed tokenId, address indexed recipient, uint256 amount);

    /**
     * @notice Treasury is withdrawn.
     * @param recipient address who got this withdrawn treasury.
     * @param amount Amount of withdrawn.
     */
    event Treasury(address indexed recipient, uint256 amount);

    /**
     * @notice A token has been succefully bid.
     * @param tokenId Id of token that has been bid.
     * @param from Original owner before bid.
     * @param to New owner after bid.
     * @param amount Amount of currency used for bidding.
     */
    event Deal(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);

    /**
     * @notice Emitted when the color of a pixel is updated.
     * @param tokenId Id of token that has been bid.
     * @param color Color index defined by client.
     * @param owner Token owner.
     */
    event Color(uint256 indexed tokenId, uint256 indexed color, address indexed owner);

    //////////////////////////////
    /// Data structure
    //////////////////////////////

    /**
     * @notice Options for global tax configuration.
     * @param taxRate: Tax rate in bps every 1000 blocks
     * @param treasuryShare: Share to treasury in bps.
     * @param mintTax: Tax to mint a token. It should be non-zero to prevent attacker constantly mint, default and mint token again.
     */
    enum ConfigOptions {
        taxRate,
        treasuryShare,
        mintTax
    }

    /**
     * @notice Record of each token.
     * @param price Current price.
     * @param lastTaxCollection Block number of last tax collection.
     * @param ubiWithdrawn Amount of UBI been withdrawn.
     */
    struct TokenRecord {
        uint256 price;
        uint256 lastTaxCollection;
        uint256 ubiWithdrawn;
    }

    /**
     * @notice Global state of tax and treasury.
     * @param accumulatedUBI Total amount of currency allocated for UBI.
     * @param accumulatedTreasury Total amount of currency allocated for treasury.
     * @param treasuryWithdrawn Total amount of treasury been withdrawn.
     */
    struct TreasuryRecord {
        uint256 accumulatedUBI;
        uint256 accumulatedTreasury;
        uint256 treasuryWithdrawn;
    }

    /**
     * @dev Packed pixel info.
     */
    struct Pixel {
        uint256 tokenId;
        uint256 price;
        uint256 lastTaxCollection;
        uint256 ubi;
        address owner;
        uint256 color;
    }

    //////////////////////////////
    /// Getters & Setters
    //////////////////////////////

    /**
     * @notice Update total supply of ERC721 token.
     * @param totalSupply_ New amount of total supply.
     */
    function setTotalSupply(uint256 totalSupply_) external;

    /**
     * @notice Update global tax settings.
     * @param option_ Tax config options, see {ConfigOptions} for detail.
     * @param value_ New value for tax setting.
     */
    function setTaxConfig(ConfigOptions option_, uint256 value_) external;

    /**
     * @notice Update UBI and treasury.
     * @param accumulatedUBI_ Total amount of currency allocated for UBI.
     * @param accumulatedTreasury_ Total amount of currency allocated for treasury.
     * @param treasuryWithdrawn_ Total amount of treasury been withdrawn.
     */
    function setTreasuryRecord(
        uint256 accumulatedUBI_,
        uint256 accumulatedTreasury_,
        uint256 treasuryWithdrawn_
    ) external;

    /**
     * @notice Set record for a given token.
     * @param tokenId_ Id of token to be set.
     * @param price_ Current price.
     * @param lastTaxCollection_ Block number of last tax collection.
     * @param ubiWithdrawn_ Amount of UBI been withdrawn.
     */
    function setTokenRecord(
        uint256 tokenId_,
        uint256 price_,
        uint256 lastTaxCollection_,
        uint256 ubiWithdrawn_
    ) external;

    /**
     * @notice Set color for a given token.
     * @param tokenId_ Token id to be set.
     * @param color_ Color Id.
     * @param owner_ Token owner.
     */
    function setColor(
        uint256 tokenId_,
        uint256 color_,
        address owner_
    ) external;

    //////////////////////////////
    /// Event emission
    //////////////////////////////

    /**
     * @dev Emit {Tax} event
     */
    function emitTax(
        uint256 tokenId_,
        address taxpayer_,
        uint256 amount_
    ) external;

    /**
     * @dev Emit {Price} event
     */
    function emitPrice(
        uint256 tokenId_,
        uint256 price_,
        address operator_
    ) external;

    /**
     * @dev Emit {UBI} event
     */
    function emitUBI(
        uint256 tokenId_,
        address recipient_,
        uint256 amount_
    ) external;

    /**
     * @dev Emit {Treasury} event
     */
    function emitTreasury(address recipient_, uint256 amount_) external;

    /**
     * @dev Emit {Deal} event
     */
    function emitDeal(
        uint256 tokenId_,
        address from_,
        address to_,
        uint256 amount_
    ) external;

    //////////////////////////////
    /// ERC721 property related
    //////////////////////////////

    /**
     * @dev Mint an ERC721 token.
     */
    function mint(address to_, uint256 tokenId_) external;

    /**
     * @dev Burn an ERC721 token.
     */
    function burn(uint256 tokenId_) external;

    /**
     * @dev Perform ERC721 token transfer by market contract.
     */
    function safeTransferByMarket(
        address from_,
        address to_,
        uint256 tokenId_
    ) external;

    /**
     * @dev If an ERC721 token has been minted.
     */
    function exists(uint256 tokenId_) external view returns (bool);

    /**
     * @dev If an address is allowed to transfer an ERC721 token.
     */
    function isApprovedOrOwner(address spender_, uint256 tokenId_) external view returns (bool);

    //////////////////////////////
    /// ERC20 currency related
    //////////////////////////////

    /**
     * @dev Perform ERC20 token transfer by market contract.
     */
    function transferCurrency(address to_, uint256 amount_) external;

    /**
     * @dev Perform ERC20 token transferFrom by market contract.
     */
    function transferCurrencyFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external;
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITheSpaceRegistry.sol";

/**
 * @title The interface for `TheSpace` contract
 * @notice _The Space_ is a pixel space owned by a decentralized autonomous organization (DAO), where members can tokenize, own, trade and color pixels.
 *
 * Pixels are tokenized as ERC721 tokens and traded under Harberger tax, while members receive dividend based on the share of pixels they own.
 *
 * #### Trading
 * - User needs to call `approve` on currency contract before starting. If there is not sufficient allowance for taxing, the corresponding assets are defaulted.
 * - User buy pixel: call [`bid` function](./ITheSpace.md).
 * - User set pixel price: call [`setPrice` function](./ITheSpace.md).
 *
 * @dev This contract holds the logic of market place, while read from and write into {TheSpaceRegistry}, which is the storage contact.
 * @dev This contract owns a {TheSpaceRegistry} contract for storage, and can be updated by transfering ownership to a new implementation contract.
 */

interface ITheSpace {
    //////////////////////////////
    /// Error types
    //////////////////////////////

    /**
     * @dev Price too low to bid the given token.
     */
    error PriceTooLow();

    /**
     * @dev Price too high to set.
     */
    error PriceTooHigh(uint256 maxPrice);

    /**
     * @dev Sender is not authorized for given operation.
     */
    error Unauthorized();

    /**
     * @dev The give token does not exist and needs to be minted first via bidding.
     */
    error TokenNotExists();

    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    /**
     * @notice Switch logic contract to another one.
     *
     * @dev Access: only `Role.aclManager`.
     * @dev Throws: `RoleRequired` error.
     *
     * @param newImplementation address of new logic contract.
     */
    function upgradeTo(address newImplementation) external;

    //////////////////////////////
    /// Configuration / Admin
    //////////////////////////////

    /**
     * @notice Update total supply of ERC721 token.
     *
     * @dev Access: only `Role.marketAdmin`.
     * @dev Throws: `RoleRequired` error.
     *
     * @param totalSupply_ New amount of total supply.
     */
    function setTotalSupply(uint256 totalSupply_) external;

    /**
     * @notice Update current tax configuration.
     *
     * @dev Access: only `Role.marketAdmin`.
     * @dev Emits: `Config` event.
     * @dev Throws: `RoleRequired` error.
     *
     * @param option_ Field of config been updated.
     * @param value_ New value after update.
     */
    function setTaxConfig(ITheSpaceRegistry.ConfigOptions option_, uint256 value_) external;

    /**
     * @notice Withdraw all available treasury.
     *
     * @dev Access: only `Role.treasuryAdmin`.
     * @dev Throws: `RoleRequired` error.
     *
     * @param to_ address of DAO treasury.
     */
    function withdrawTreasury(address to_) external;

    /**
     * @notice Set token image URI.
     *
     * @dev Access: only `Role.aclManager`.
     * @dev Throws: `RoleRequired` error.
     *
     * @param uri_ new URI
     */
    function setTokenImageURI(string memory uri_) external;

    /**
     * @notice Change the trusted forwarder.
     *
     * @dev Access: only `Role.aclManager`.
     * @dev Throws: `RoleRequired` error.
     *
     * @param trustedForwarder_ new address
     */
    function setTrustedForwarder(address trustedForwarder_) external;

    //////////////////////////////
    /// Pixel
    //////////////////////////////

    /**
     * @notice Get pixel info.
     * @param tokenId_ Token id to be queried.
     * @return pixel Packed pixel info.
     */
    function getPixel(uint256 tokenId_) external view returns (ITheSpaceRegistry.Pixel memory pixel);

    /**
     * @notice Bid pixel, then set price and color.
     *
     * @dev Throws: inherits from `bid` and `setPrice`.
     *
     * @param tokenId_ Token id to be bid and set.
     * @param bidPrice_ Bid price.
     * @param newPrice_ New price to be set.
     * @param color_ Color to be set.
     */
    function setPixel(
        uint256 tokenId_,
        uint256 bidPrice_,
        uint256 newPrice_,
        uint256 color_
    ) external;

    /**
     * @notice Set color for a pixel.
     *
     * @dev Access: only token owner or approved operator.
     * @dev Throws: `Unauthorized` or `ERC721: operator query for nonexistent token` error.
     * @dev Emits: `Color` event.
     *
     * @param tokenId_ Token id to be set.
     * @param color_ Color to be set.
     */
    function setColor(uint256 tokenId_, uint256 color_) external;

    /**
     * @notice Get color for a pixel.
     * @param tokenId_ Token id to be queried.
     * @return color Color.
     */
    function getColor(uint256 tokenId_) external view returns (uint256 color);

    /**
     * @notice Get pixels owned by a given address.
     * @param owner_ Owner address.
     * @param limit_ Limit of returned pixels.
     * @param offset_ Offset of returned pixels.
     * @return total Total number of pixels.
     * @return limit Limit of returned pixels.
     * @return offset Offset of returned pixels.
     * @return pixels Packed pixels.
     * @dev offset-based pagination
     */
    function getPixelsByOwner(
        address owner_,
        uint256 limit_,
        uint256 offset_
    )
        external
        view
        returns (
            uint256 total,
            uint256 limit,
            uint256 offset,
            ITheSpaceRegistry.Pixel[] memory pixels
        );

    //////////////////////////////
    /// Trading
    //////////////////////////////

    /**
     * @notice Returns the current price of a token by id.
     * @param tokenId_ Token id to be queried.
     * @return price Current price.
     */
    function getPrice(uint256 tokenId_) external view returns (uint256 price);

    /**
     * @notice Set the current price of a token with id. Triggers tax settle first, price is succefully updated after tax is successfully collected.
     *
     * @dev Access: only token owner or approved operator.
     * @dev Throws: `Unauthorized` or `ERC721: operator query for nonexistent token` error.
     * @dev Emits: `Price` event.
     *
     * @param tokenId_ Id of token been updated.
     * @param price_ New price to be updated.
     */
    function setPrice(uint256 tokenId_, uint256 price_) external;

    /**
     * @notice Returns the current owner of an Harberger property with token id.
     * @dev If token does not exisit, return zero address and user can bid the token as usual.
     * @param tokenId_ Token id to be queried.
     * @return owner Current owner address.
     */
    function getOwner(uint256 tokenId_) external view returns (address owner);

    /**
     * @notice Purchase property with bid higher than current price.
     * If bid price is higher than ask price, only ask price will be deducted.
     * @dev Clear tax for owner before transfer.
     *
     * @dev Throws: `PriceTooLow` or `InvalidTokenId` error.
     * @dev Emits: `Deal`, `Tax` events.
     *
     * @param tokenId_ Id of token been bid.
     * @param price_ Bid price.
     */
    function bid(uint256 tokenId_, uint256 price_) external;

    //////////////////////////////
    /// Tax & UBI
    //////////////////////////////

    /**
     * @notice Calculate outstanding tax for a token.
     * @param tokenId_ Token id to be queried.
     * @return amount Current amount of tax that needs to be paid.
     */
    function getTax(uint256 tokenId_) external view returns (uint256 amount);

    /**
     * @notice Calculate amount of tax that can be collected, and determine if token should be defaulted.
     * @param tokenId_ Token id to be queried.
     * @return collectable Amount of currency that can be collected, considering balance and allowance.
     * @return shouldDefault Whether current token should be defaulted.
     */
    function evaluateOwnership(uint256 tokenId_) external view returns (uint256 collectable, bool shouldDefault);

    /**
     * @notice Collect outstanding tax of a token and default it if needed.
     * @dev Anyone can trigger this function. It could be desirable for the developer team to trigger it once a while to make sure all tokens meet their tax obligation.
     *
     * @dev Throws: `PriceTooLow` or `InvalidTokenId` error.
     * @dev Emits: `Tax` events.
     *
     * @param tokenId_ Id of token been settled.
     * @return success Whether tax is fully collected without token been defaulted.
     */
    function settleTax(uint256 tokenId_) external returns (bool success);

    /**
     * @notice Amount of UBI available for withdraw on given token.
     * @param tokenId_ Token id to be queried.
     * @param amount Amount of UBI available to be collected
     */
    function ubiAvailable(uint256 tokenId_) external view returns (uint256 amount);

    /**
     * @notice Withdraw all UBI on given token.
     *
     * @dev Emits: `UBI` event.
     *
     * @param tokenId_ Id of token been withdrawn.
     */
    function withdrawUbi(uint256 tokenId_) external;

    //////////////////////////////
    /// Registry backcall
    //////////////////////////////

    /**
     * @notice Perform before `safeTransfer` and `safeTransferFrom` by registry contract.
     * @dev Collect tax and set price.
     *
     * @dev Access: only registry.
     * @dev Throws: `Unauthorized` error.
     *
     * @param tokenId_ Token id to be transferred.
     * @return success Whether tax is fully collected without token been defaulted.
     */
    function _beforeTransferByRegistry(uint256 tokenId_) external returns (bool success);

    /**
     * @notice Get token URI by registry contract.
     *
     * @dev Access: only registry.
     * @dev Throws: `Unauthorized` or `TokenNotExists` error.
     *
     * @param tokenId_ Token id to be transferred.
     * @return uri Base64 encoded URI.
     */
    function _tokenURI(uint256 tokenId_) external view returns (string memory uri);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/**
 * @title The interface for `ACLManager` contract to manage _The Space_ market.
 * @notice Access Control List Manager is a role-based access control mechanism.
 * @dev Each role can be granted to an address.
 * @dev All available roles are defined in `Role` enum.
 */
interface IACLManager {
    //////////////////////////////
    /// Error types
    //////////////////////////////

    /**
     * @dev Given operation is requires a given role.
     */
    error RoleRequired(Role role);

    /**
     * @dev Given operation is forbidden.
     */
    error Forbidden();

    /**
     * @dev Given a zero address.
     */
    error ZeroAddress();

    //////////////////////////////
    /// Eevent types
    //////////////////////////////

    /**
     * @notice Role is transferred to a new address.
     * @param role Role transferred.
     * @param prevAccount Old address.
     * @param newAccount New address.
     */
    event RoleTransferred(Role indexed role, address indexed prevAccount, address indexed newAccount);

    /**
     * @notice Available roles.
     * @param aclManager: responsible for assigning and revoking roles of other addresses
     * @param marketAdmin: responsible for updating configuration, e.g. tax rate or treasury rate.
     * @param treasuryAdmin: responsible for withdrawing treasury from contract.
     */
    enum Role {
        aclManager,
        marketAdmin,
        treasuryAdmin
    }

    /**
     * @notice Returns `true` if `account` has been granted `role`.
     */
    function hasRole(Role role, address account) external returns (bool);

    /**
     * @notice Grant role to a account (`newAccount`).
     * @dev Cannot grant `Role.aclManager`.
     *
     * @dev Access: only `Role.aclManager`.
     * @dev Throws: `RoleRequired`, `Forbidden` or `ZeroAddress` error.
     */
    function grantRole(Role role, address newAccount) external;

    /**
     * @notice Transfers role to a new account (`newAccount`).
     * @dev Acces: only current role address.
     * @dev Throws: `RoleRequired`, or `ZeroAddress` error.
     */
    function transferRole(Role role, address newAccount) external;

    /**
     * @notice Revokes role from the role address.
     * @dev `Role.aclManager` can not be revoked.
     *
     * @dev Access: only current role address.
     * @dev Throws: `RoleRequired` or `Forbidden` error.
     */
    function renounceRole(Role role) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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