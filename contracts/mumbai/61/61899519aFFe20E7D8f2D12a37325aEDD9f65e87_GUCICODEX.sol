// Owner of this software is Nikola Radošević PR Innolab Solutions Serbia. All rights reserved.
// SPDX-License-Identifier: UNLICENSED

import "./AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./GUCDEXLib.sol";

pragma solidity ^0.8.0;

contract GUCICODEX {
    address gucAddress = 0xF8F13Eddc174fD23BBaD65f6dc721D29b18bE8a2;
    address desktopAddress = 0xaf5e0Ea82A1a5110eeE147Efc8659c45526E9eB4;

    ERC20 usdt = ERC20(address(0x349E807BEB299BF317268eA292862d2f456bBbC8));
    ERC20 guc = ERC20(gucAddress);
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
    
    uint public swapCount;
    uint public totalCoinsSold;
    uint public totalETHexchanged;
    uint public totalBTCexchanged;
    uint public totalUSDTexchanged;
    uint public numberOfUsedVouchers;
    uint public activePresale;
    uint public numberOfPresales;

    mapping(bytes => bool) public usedVouchers;
    mapping(uint => GUCDEXLib.Presale) public presales;

    event SwappedBTCforGUC(uint indexed presale, uint indexed amountIn, uint indexed amountOut);
    event SwappedETHforGUC(uint indexed presale, uint indexed amountIn, uint indexed amountOut);
    event SwappedUSDTforGUC(uint indexed presale, uint indexed amountIn, uint indexed amountOut);
    event ActivePresaleChanged(uint indexed id);

    modifier onlyWhitelist {
        require(msg.sender == desktopAddress, "You are not whitelisted.");
        _;
    }

    function getLatestPrice() public view returns (int) {
        (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
        return price;
    }
    
    function addPresale(GUCDEXLib.TypeOfSale typeOfSale, uint usdToGucFixedRate, uint maxCoinsPerVoucher, string calldata name) external onlyWhitelist
    {
        GUCDEXLib.Presale memory newPresale = GUCDEXLib.Presale(typeOfSale, usdToGucFixedRate, maxCoinsPerVoucher, 0, 0, 0, 0, name);
        presales[++numberOfPresales]=newPresale;
        changeActivePresale(numberOfPresales);
    }
    
    function statistics() external view returns (uint, uint, uint, uint, uint, uint, uint){
        return (totalCoinsSold, totalETHexchanged, totalBTCexchanged, totalUSDTexchanged, numberOfUsedVouchers, numberOfPresales, swapCount);
    }
    
    function changeActivePresale(uint presaleNo) public onlyWhitelist
    {
        activePresale=presaleNo;
        emit ActivePresaleChanged(presaleNo);
    }
    
    function swapETHforGUC(uint discount, uint presaleNo, uint nonce, bytes calldata voucherCode) external payable
    {
        if (!GUCDEXLib.voucherIsEmpty(voucherCode))
        {
            require(presaleNo==activePresale,"Presale has ended");
        }
        
        if (!GUCDEXLib.voucherIsEmpty(voucherCode) || presales[activePresale].typeOfSale==GUCDEXLib.TypeOfSale.Private)
        {
            require(usedVouchers[voucherCode]==false,"Voucher has already been used");
            require(verify(desktopAddress, discount, presaleNo, nonce, voucherCode),"Voucher is invalid");
        }
        
        uint ETHtoUSD=uint(getLatestPrice());
        
        uint finalExchangeRate;
        
        if (!GUCDEXLib.voucherIsEmpty(voucherCode) || presales[activePresale].typeOfSale==GUCDEXLib.TypeOfSale.Private)
        {
            finalExchangeRate=(presales[presaleNo].usdToGucFixedRate * (100 + discount)) / 100;
        }
        else 
        {
            finalExchangeRate=presales[presaleNo].usdToGucFixedRate;
        }

        uint numOfTokensToTransfer = msg.value * ETHtoUSD / finalExchangeRate;
        
        require(presales[presaleNo].maxCoinsPerVoucher>numOfTokensToTransfer, "Can not buy that many tokens with this voucher.");
    
        require(guc.balanceOf(address(this))>=numOfTokensToTransfer,"Not enough tokens in cashbox");
        
        require(guc.transfer(msg.sender, numOfTokensToTransfer),"Transfer of GUC failed");

        totalETHexchanged+=msg.value;
        totalCoinsSold+=numOfTokensToTransfer;
            
        if (!GUCDEXLib.voucherIsEmpty(voucherCode))
        {
            usedVouchers[voucherCode]=true;
            numberOfUsedVouchers++;
        }

        presales[activePresale].coinsSold+=numOfTokensToTransfer;
        presales[activePresale].totalETH+=msg.value;
        swapCount++;

        emit SwappedETHforGUC(presaleNo, msg.value, numOfTokensToTransfer);
    }
    
    function swapUSDTforGUC(uint usdtToTransfer, uint discount, uint presaleNo, uint nonce, bytes calldata voucherCode) external
    {
        if (!GUCDEXLib.voucherIsEmpty(voucherCode))
        {
            require(presaleNo==activePresale,"Presale has ended");
        }
        
        if (!GUCDEXLib.voucherIsEmpty(voucherCode) || presales[activePresale].typeOfSale==GUCDEXLib.TypeOfSale.Private)
        {
            require(usedVouchers[voucherCode]==false,"Voucher has already been used");
            require(verify(desktopAddress, discount, presaleNo, nonce, voucherCode),"Voucher is invalid");
        }
        
        uint finalExchangeRate;
        
        if (!GUCDEXLib.voucherIsEmpty(voucherCode))
        {
            finalExchangeRate = (presales[presaleNo].usdToGucFixedRate * (100 + discount)) / 100;
        }
        else 
        {
            finalExchangeRate = presales[presaleNo].usdToGucFixedRate;
        }

        uint numOfTokensToTransfer= (usdtToTransfer * 10**20) / finalExchangeRate;
        
        require(presales[presaleNo].maxCoinsPerVoucher>numOfTokensToTransfer, "Can not buy that many tokens with this voucher.");
    
        require(guc.balanceOf(address(this))>=numOfTokensToTransfer,"Not enough tokens in cashbox");
        
        require(usdt.transferFrom(msg.sender,desktopAddress, usdtToTransfer),"Transfer of USDT failed.");
        
        require(guc.transfer(msg.sender, numOfTokensToTransfer),"Transfer of GUC failed");
        
        totalUSDTexchanged+=usdtToTransfer;
        totalCoinsSold+=numOfTokensToTransfer;
                
        if (!GUCDEXLib.voucherIsEmpty(voucherCode))
        {
            usedVouchers[voucherCode]=true;
            numberOfUsedVouchers++;   
        }

        presales[activePresale].coinsSold+=numOfTokensToTransfer;
        presales[activePresale].totalUSDT+=usdtToTransfer;
        swapCount++;

        emit SwappedUSDTforGUC(presaleNo, usdtToTransfer, numOfTokensToTransfer);
    }
    
    function swapUSDTforGUC(bytes memory voucherCode, uint presaleNo, uint GUCamount, uint USDTAmount, address destinationAddress) external onlyWhitelist
    {
        require(guc.balanceOf(address(this))>=GUCamount,"Not enough tokens in cashbox");

        if (!GUCDEXLib.voucherIsEmpty(voucherCode))
        {
            require(presaleNo==activePresale,"Presale has ended");
            require(usedVouchers[voucherCode]==false,"Voucher has already been used");
        }

        require (guc.transfer(destinationAddress, GUCamount), "Transfer of GUC failed");
        totalCoinsSold+=GUCamount;
        totalUSDTexchanged+=USDTAmount;
            
        if (!GUCDEXLib.voucherIsEmpty(voucherCode))
        {
            usedVouchers[voucherCode]=true;
            numberOfUsedVouchers++;
        }       

        presales[activePresale].coinsSold+=GUCamount;
        presales[activePresale].totalUSDT+=USDTAmount;
        swapCount++;

        emit SwappedUSDTforGUC(presaleNo, USDTAmount, GUCamount);
    }
    
    function swapBTCforGUC(bytes memory voucherCode, uint presaleNo, uint GUCamount, uint BTCAmount, address destinationAddress) external onlyWhitelist
    {
        require(guc.balanceOf(address(this))>=GUCamount,"Not enough tokens in cashbox");

        if (!GUCDEXLib.voucherIsEmpty(voucherCode))
        {
            require(presaleNo==activePresale,"Presale has ended");
            require(usedVouchers[voucherCode]==false,"Voucher has already been used");
        }

        require(guc.transfer(destinationAddress, GUCamount), "Transfer failed");
        totalCoinsSold+=GUCamount;
        totalBTCexchanged+=BTCAmount;
            
        if (!GUCDEXLib.voucherIsEmpty(voucherCode))
        {
            usedVouchers[voucherCode]=true;
            numberOfUsedVouchers++;
        } 

        presales[activePresale].coinsSold+=GUCamount;
        presales[activePresale].totalBTC+=BTCAmount;
        swapCount++;

        emit SwappedBTCforGUC(presaleNo, BTCAmount, GUCamount);
    }
    
    function swapETHforGUC(bytes memory voucherCode, uint presaleNo, uint GUCamount, uint ETHAmount, address destinationAddress) external onlyWhitelist
    {
        require(guc.balanceOf(address(this))>=GUCamount,"Not enough tokens in cashbox");
        
        if (!GUCDEXLib.voucherIsEmpty(voucherCode))
        {
            require(presaleNo==activePresale,"Presale has ended");
            require(usedVouchers[voucherCode]==false,"Voucher has already been used");
        }

        require(guc.transfer(destinationAddress, GUCamount), "Transfer failed");
        totalCoinsSold+=GUCamount;
        totalETHexchanged+=ETHAmount;
            
        if (!GUCDEXLib.voucherIsEmpty(voucherCode))
        {
            usedVouchers[voucherCode]=true;
            numberOfUsedVouchers++;
        }

        presales[activePresale].coinsSold+=GUCamount;
        presales[activePresale].totalETH+=ETHAmount;
        swapCount++;

        emit SwappedETHforGUC(presaleNo, ETHAmount, GUCamount);
    }
    
    function verify(address _signer, uint discount, uint presaleNo, uint nonce, bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(discount,presaleNo,nonce);
        bytes32 ethSignedMessageHash = GUCDEXLib.getEthSignedMessageHash(messageHash);

        return GUCDEXLib.recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
    
    function getMessageHash(uint discount, uint presaleNo, uint nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(discount, presaleNo, nonce));
    }
}

// Owner of this software is Nikola Radošević PR Innolab Solutions Serbia. All rights reserved.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library GUCDEXLib{
    
    enum TypeOfSale {Private, Public}
   
    struct Presale {
        TypeOfSale typeOfSale;
        uint usdToGucFixedRate; 
        uint maxCoinsPerVoucher;
        uint coinsSold;
        uint totalETH;
        uint totalUSDT;
        uint totalBTC;
        string name;
    }
    
    function voucherIsEmpty(bytes memory voucherCode) public pure returns (bool)
    {
        return keccak256(voucherCode)==keccak256(hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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